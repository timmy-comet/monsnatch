# Monsnatch — Client Integration Guide

A guide for building a new client (Flutter / iOS / Android / Unity / whatever) that talks to the Monsnatch backend to play the game. Written to be framework-agnostic — this describes **what the client must do**, not React code.

> The backend is the authority on everything (rules, captures, scores, timer, teams, hand draws). The client is purely **render + forward user actions**.

---

## 1. Quick overview

- 2-player card game on a **4×4** grid (16 cells)
- One player is assigned **Star** (randomly at match start), the other is **Moon**. Star moves first.
- Each player starts with **10 random unique cards** drawn from a 12-card catalog. The two players may or may not overlap.
- 30-second turn timer — if it expires, the server auto-plays a random card for that player.
- Placing a card may "flip" neighboring tokens (star ↔ moon) based on power + element.
- Match ends when the 16 cells fill up → whoever owns more tokens wins; 8-8 is a draw.
- When a match ends, **both players** can click **Play Again**; when both have voted, a new match starts in the same room (history is kept). Either player can click **Leave**, which permanently ends the room.

---

## 2. What the client implements — 8 responsibilities

1. **Register** — obtain an ID token
2. **Create/Join room** — obtain a room code
3. **Start first match** (host only) — present a Start Game UI on the room page
4. **Subscribe to room state** — open a WebSocket and re-render on every update
5. **Render game state** — board, hands (with used cards grayed out), scores, timer, tokens
6. **Handle user actions** — tap card → tap cell → send play request
7. **End-of-match UI** — show final score with **Play Again** + **Leave** buttons; reflect the opponent's vote / leave state
8. **Leave flow** — user taps Leave → server marks room as done → client navigates to lobby

**You do NOT** implement capture logic, element rules, turn timer, team assignment, hand draws, adjacency validation, or score tallying (the server handles all of these).

---

## 3. Authentication

**Once, at registration:**
```
POST /register
Body: { "username": "alice" }
Response: { "uid": "...", "username": "...", "idToken": "eyJ...", "createdAt": "...", "updatedAt": "..." }
```

Store `idToken` in session storage / secure storage.

**Use the token in two places:**
- HTTP requests: `Authorization: Bearer <idToken>` header
- WebSocket: `?token=<idToken>` query parameter

Token TTL is **~1 hour**; no refresh mechanism. On expiry, re-register.

---

## 4. REST API endpoints the client calls

In the order you'll encounter them.

### 4.1 `POST /register` (no auth)
**When:** user enters a username
**Body:** `{ username }`
**Response:** `{ uid, username, createdAt, updatedAt, idToken }`

### 4.2 `POST /rooms` (auth)
**When:** user taps "Create Room"
**Response:** `RoomPublic` — contains `code`

### 4.3 `GET /rooms/:code` (auth)
**When:** user taps "Join Room" to pre-check
**Response:** `RoomPublic`

### 4.4 `POST /rooms/:code/join` (auth)
**When:** user joins via a room code
**Response:** `RoomPublic`

### 4.5 `POST /rooms/:code/start` (auth) — dual-purpose
**When:**
- (a) Host taps "Start Game" on the pre-match room page (first match)
- (b) Either player taps "Play Again" after a match ends (restart vote)

**Body:** `{}` (empty)
**Response:** `RoomPublic`

**Behavior:**
- If no matches have been played yet → only the host (room creator) may call; creates match 1 immediately.
- If the last match is `done` → either player may call; records their vote in `playAgainVotes`. When **both** players have voted, the server appends a new match to `game[]` and clears the votes. If only one has voted, the response still succeeds but nothing else changes (the other party's client sees the vote via WS).

**Errors:**
- `403` — not a player / not the host (on first match)
- `409` — waiting for player 2 / match already in progress / opponent has left the room (`leftBy` set)

### 4.6 `POST /rooms/:code/leave` (auth) — new
**When:** user taps "Leave" on the end-of-match overlay (or anywhere you want to abandon the room).
**Body:** `{}`
**Response:** `RoomPublic` with `status='done'`, `leftBy=<caller uid>`, `playAgainVotes=[]`
**Effect:** the remaining player sees an "opponent left" notice and the Play Again button becomes disabled.

### 4.7 `POST /rooms/:code/play` (auth)
**When:** user has a card selected and taps a valid empty cell
**Body:** `{ "cellIndex": 0-15, "cardId": 1-12 }`
**Response:** `RoomPublic` with updated current match

**Errors:**
- `403` — not your turn
- `409` — invalid move (cell occupied, not adjacent after first move, card not in hand **or already used**)
- `410` — match is over

### 4.8 `GET /cards` (auth)
**When:** once per battle-screen mount
**Response:** `CardPublic[]` — all 12 cards

### 4.9 `GET /users/:uid` (auth)
**When:** to display the opponent's username
**Response:** `{ uid, username, createdAt, updatedAt }`

---

## 5. WebSocket — source of truth for room state

### Connect
```
wss://<host>/rooms/:code/ws?token=<idToken>
```

### Messages (server → client)
```json
{ "type": "room_update", "room": { ...RoomPublic } }
{ "type": "not_found" }
```

### Behavior
- Open the WS on the room and battle screens
- On every `room_update` → **replace local room state with the new `room` in its entirety** (no merging; there is no diff)
- On `not_found` → server closes the socket; show error and bounce back
- Close the socket when leaving the screen

### Important
The client **never sends over WebSocket** — it's strictly server → client. All user actions use REST POST.

---

## 6. Game state shape

### `RoomPublic`
```ts
{
  code: "XYZ789",
  createdBy: "uid_of_host",
  status: "available" | "unavailable" | "done",
  player1: "uid" | null,
  player2: "uid" | null,
  createdAt, updatedAt,                 // ISO strings
  game?: GameStatePublic[],              // array of matches (newest = last); absent until first /start
  playAgainVotes?: string[],             // uids who voted to restart since the last match ended
  leftBy?: string | null                 // if set, a player explicitly left the room — no more play
}
```

### The "current match"
Always the **last element** of `game[]`. The earlier entries are finished match history.
```
currentMatch = room.game[room.game.length - 1]   // or equivalent for your language
```
If `room.game` is undefined or empty → no match has started; show the lobby screen instead.

### `GameStatePublic` (each entry in `game[]`)
```ts
{
  board: (GameCell | null)[16],          // row-major: index = row*4 + col
  hands: { [uid]: HandCard[] },           // 10 cards each, including cards already played (used=true)
  turn: "uid",                             // whose turn it is
  turnNumber: 0,                           // 0-based; 0 = first move of this match
  turnStartedAt: "ISO",
  turnDeadline: "ISO",                     // = turnStartedAt + 30s
  startedAt: "ISO",
  starUid: "uid",                          // the Star team player (random per match, not always host)
  score: { [uid]: 0 },                     // cells currently owned
  winner: "uid" | null,                    // null until the match's status='done'; null also = draw
  lastMove: {
    cellIndex: number,
    cardId: number,
    placedBy: "uid",
    captures: number[]                     // indices flipped by the last move
  } | null
}
```

### `HandCard`
```ts
{ cardId: number, used: boolean }
```
A played card **stays** in the hand list with `used: true` — do not remove it. Render used cards grayed out / disabled. Only unused cards can be selected.

### `GameCell` (per placed cell)
```ts
{
  cardId: number,                          // look up the catalog for name/art/element
  ownerUid: string,                        // ★ drives which token renders (star/moon)
  placedBy: string                         // immutable after placement (for "card faces placer" visual)
}
```

### `CardPublic` (from `/cards`)
```ts
{
  id: 1..12,
  name: "POOPLE",
  element: "earth"|"water"|"wind"|"fire"|"lightning"|"ice"|"plant"|"poison"|"steel"|"ghost"|"light"|"dark",
  power: 4..7,
  directions: ("t"|"tr"|"r"|"br"|"b"|"bl"|"l"|"tl")[]
}
```

---

## 7. Board coordinates (4×4)

Index 0-15, row-major (row 0 = top in absolute terms):

```
  col: 0   1   2   3
row 0: 0   1   2   3
row 1: 4   5   6   7
row 2: 8   9  10  11
row 3: 12 13  14  15
```

- `index = row * 4 + col`
- `row = floor(index / 4)`, `col = index % 4`

---

## 8. Screens and flow

```
┌──────────────┐  register   ┌──────────────┐
│   /register  │ ──────────► │    /lobby    │
└──────────────┘             └──────┬───────┘
                                    │
               create / join        │
               ┌───────────────────┘
               ▼
     ┌───────────────┐  host taps Start    ┌───────────────┐
     │  /room/:code  │ ──────────────────► │ /battle/:code │
     │ (pre-match)   │ ◄─── WS: game set ──│  (gameplay)   │
     └───────────────┘                     └───────┬───────┘
                                                   │
                                  status == 'done' │
                                                   ▼
                                 ┌──────────────────────────────────┐
                                 │  End overlay (final score):      │
                                 │   - Play Again (both must vote)  │
                                 │   - Leave (ends room)            │
                                 └────┬──────────┬──────────────────┘
                                      │          │
                     both voted Play  │          │  user tapped Leave
                     Again → new match│          └──► /lobby
                                      ▼
                              (overlay closes, match N+1 starts)
```

### `/room/:code` (pre-match lobby)
- Show room code + two player avatars (usernames fetched via `/users/:uid`)
- If `game[]` becomes non-empty → redirect to `/battle/:code`
- If caller is host AND player2 has joined AND no game yet → show "Start Game" button → `/start`
- Non-host: "Waiting for host to start..."

### `/battle/:code`
See section 9.

---

## 9. Battle screen — what to render

### 9.1 Header
- Room code
- Turn indicator: "Your turn" or "{opponent}'s turn"
- Countdown in seconds from `currentMatch.turnDeadline - now()` (tick ~500ms; red below 5s)
- Status: `room.status`

### 9.2 Opponent strip (top)
- Star/moon token (derived from `currentMatch.starUid`: opponent is the one that isn't star)
- Username
- **Cards in hand** = count of **unused** cards = `hands[oppUid].filter(c => !c.used).length`
- Score
- Face-down placeholders for each unused card

### 9.3 Board (4×4)
For each cell `i`:
- **Empty**: show "+"; clickable only when the cell is "valid" (see section 10)
- **Placed**: render card art + token
  - Token source: `ownerUid === room.createdBy` ? star : moon *(NO — this is the naive rule, see note below!)*
  - **Correct rule**: `team of ownerUid == (ownerUid === currentMatch.starUid ? 'star' : 'moon')` — star is now dynamic per match
  - Optional visual: amber ring on `currentMatch.lastMove.cellIndex`, pink ring on each cell in `lastMove.captures`

### 9.4 My status row
- My token (star/moon from `starUid`)
- Username + team label
- My score

### 9.5 My hand
- Iterate `hands[my_uid]` (which is `HandCard[]`, not `number[]`)
- **Used cards remain visible but grayed out** (e.g. `opacity:30, grayscale, cursor:not-allowed`) and cannot be selected
- Unused cards are tappable — tapping sets `selected = cardId`
- Selected card shows a highlight border

### 9.6 End overlay — shown when `room.status === 'done'`
Multiple states, all driven by three signals: `playAgainVotes`, `leftBy`, and the local "my click" flag.

| State | How to detect | UI |
|---|---|---|
| Fresh end | `playAgainVotes` empty, `!leftBy` | Title, score, both buttons enabled |
| I voted, waiting | `playAgainVotes` contains my uid | "Play Again" becomes "Waiting..." (disabled); status line: "Waiting for {opponent} to play again..." |
| Opponent voted, I haven't | `playAgainVotes` contains opponent's uid only | Status line: "{opponent} wants to play again." — Play Again still enabled |
| Opponent left | `leftBy` equals opponent's uid | Status line: "{opponent} left the room." — Play Again disabled |
| I left | (you've already navigated away) | n/a |

Buttons:
- **Play Again** → `POST /rooms/:code/start`. Backend records a vote or (if both voted) creates a new match. WS delivers the new state.
- **Leave** → `POST /rooms/:code/leave` then navigate to `/lobby`.

When a new match starts, the WS will push `status='unavailable'` and a new entry in `game[]`. Close the overlay and render the fresh match.

---

## 10. Client-side validation (UX only — server re-checks everything)

Before sending `POST /play`:

```
canPlay(cellIndex) =
  game.turn === my_uid                  // my turn
  AND not currently submitting
  AND selected_card_id != null
  AND hands[my_uid][selected] is not used
  AND board[cellIndex] === null
  AND (turnNumber === 0 OR isAdjacentToPlaced(cellIndex))
```

`isAdjacentToPlaced(cellIndex)`:
```
for (dr, dc) in 8-way offsets:
  r = floor(cellIndex/4) + dr
  c = cellIndex%4 + dc
  if 0 ≤ r ≤ 3 and 0 ≤ c ≤ 3 and board[r*4+c] != null:
    return true
return false
```

Before enabling Play Again: `!opponentLeft AND !iAlreadyVoted`.

---

## 11. User interactions

### 11.1 Tap card in hand
```
on_tap(cardId, used):
  if used: return
  selected_card_id = (selected_card_id === cardId) ? null : cardId
```
Pure local state. No network.

### 11.2 Tap empty cell
```
on_tap(cellIndex):
  if !canPlay(cellIndex): return
  submitting = true
  try:
    POST /rooms/:code/play { cellIndex, cardId: selected_card_id }
    # WS push delivers new state — don't touch local state
  catch:
    show error; submitting = false
```

### 11.3 Tap Play Again (end overlay)
```
on_tap():
  if hasVotedPlayAgain or opponentLeft: return
  playing_again = true
  try:
    POST /rooms/:code/start
  catch:
    show error
  # WS push either gives us vote_recorded (I'm now in playAgainVotes)
  # or the new match (votes cleared, game[] grew by 1). Either way, re-render.
```

### 11.4 Tap Leave (end overlay)
```
on_tap():
  try:
    POST /rooms/:code/leave
  finally:
    navigate('/lobby')
```

---

## 12. "Token flipping" — server-side; client just re-renders

The client never computes captures. When a card is played:
1. Server iterates the placed card's `directions` (rotated 180° if placer is Player 2 — see section 13)
2. For each neighbor cell with a card: `capture iff placed.power > defender.power OR element.beats(placed, defender)`
3. Captured cells have their `ownerUid` flipped to the placer's uid

The result arrives via WS. The client **re-renders each cell from `ownerUid`** and the token image changes automatically — there is no separate "flip" event. `lastMove.captures` is a list of freshly-flipped cell indices provided only for optional highlight / animation.

---

## 13. "Visual flip" for Player 2 (optional polish)

If you want each player to feel like they sit on their own side of the table:

### Star viewer
- No transform. Render everything in absolute coordinates.

### Moon viewer
1. **Rotate the board container by 180°.** Absolute cell 0 ends up at the visual bottom-right.
2. **Rotate cards placed by Player 2 (= `placedBy === moonUid`) by 180° at the cell level.** Combined with the board rotation, Moon's own cards render upright while the opponent's appear upside-down from Moon's perspective — matching a physical TCG across a table.
3. Hand cards stay un-rotated (preserving catalog orientation).
4. Clicks still map to the same absolute cell index — no translation needed.

### Direction semantics
The server automatically rotates a card's `directions` 180° when Player 2 places it. The client doesn't touch it. Note: **Star is not always Player 1** — it's `currentMatch.starUid`. The direction-rotation trigger is `placerUid === room.player2`, independent of who is Star.

---

## 14. Error handling

| Case | How to handle |
|---|---|
| WS connection fails | Fullscreen error; close socket |
| WS `not_found` | Fullscreen error; bounce to `/lobby` |
| REST 401 (token expired) | Clear session; bounce to `/register` |
| REST 403 on `/play` | "Not your turn" — unlock UI |
| REST 409 on `/play` | Cell / card / adjacency / used — unlock UI; show message |
| REST 410 on `/play` | Match is over — already handled by WS pushing status='done' |
| REST 409 on `/start` "Opponent has left" | Disable Play Again; show "opponent left" |
| WS pushes `leftBy = opponent` | Same — Play Again disabled, overlay shows "opponent left the room" |

Server error bodies: `{ "error": "human-readable" }`. Surface directly.

---

## 15. Client responsibility checklist

- [ ] Store idToken after register
- [ ] Attach `Authorization: Bearer` to every HTTP call
- [ ] Open WebSocket with `?token=` on room / battle screens
- [ ] On `room_update`: replace local state (do not merge)
- [ ] On `not_found`: error + bounce
- [ ] Load the 12-card catalog via `/cards` once per battle mount
- [ ] Load opponent username via `/users/:uid`
- [ ] Compute countdown from `currentMatch.turnDeadline`
- [ ] Derive Star/Moon team via `currentMatch.starUid` (NOT `room.createdBy`)
- [ ] Compute `validEmptyCells` (empty + adjacency for non-first moves)
- [ ] Treat `hands[uid]` as `HandCard[]` — show used cards grayed out, only unused are selectable
- [ ] On /play: wait for WS echo before clearing submit state
- [ ] On match end (`status==='done'`): show overlay with Play Again + Leave
- [ ] Reflect vote state: `playAgainVotes` contains me → "waiting"; contains opponent → "they want to play again"
- [ ] Reflect `leftBy`: if opponent left, disable Play Again and show notice
- [ ] On Play Again: call `/start`, wait for WS
- [ ] On Leave: call `/leave`, then navigate to `/lobby`
- [ ] When a new match starts (game[] grew): close overlay, reset selected/submit, show fresh board
- [ ] Close WebSocket on screen exit

---

## 16. Things the client does NOT do

- ❌ Capture / token flip calculations
- ❌ Element advantage rules
- ❌ Direction rotation for Player 2
- ❌ Team assignment (random Star — server decides)
- ❌ Hand card draws (server shuffles & deals)
- ❌ Score tallying
- ❌ Winner determination
- ❌ Match history storage (it's in the room doc, keyed as `game[]`)
- ❌ Turn timer enforcement (server auto-plays on timeout)
- ❌ Adjacency enforcement (client only uses it to disable UI)
- ❌ Vote bookkeeping for Play Again (server tracks `playAgainVotes`)
- ❌ Marking a card as "used" (server does it on `/play`)

---

## 17. Further reading

- `backend/API.md` — full REST endpoint spec with bodies / responses / error codes
- `backend/GAME.md` — backend internals (capture logic, timer, transactions, vote flow) — not required for client work
- `backend/SCHEMA.md` — DBML-style data-model reference (users / rooms / cards / game)
