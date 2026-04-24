# Monsnatch API Reference

**Base URL:** `{baseUrl}`
**WebSocket Base:** `{wsBaseUrl}` (same host as `{baseUrl}` with `https` → `wss`)

> Replace `{baseUrl}` with the actual host — e.g. `https://your-tunnel.trycloudflare.com` in production, or `http://localhost:4001` in local dev. The WebSocket base uses the same host with the protocol swapped to `wss://` (or `ws://` for localhost).

---

## Authentication

All endpoints except `GET /health` and `POST /register` require a **Firebase ID token**.

For HTTP requests, pass the token via the `Authorization` header:

```
Authorization: Bearer <id_token>
Content-Type: application/json
```

For **WebSocket** connections (browsers cannot set custom headers on the WS upgrade), pass the token as a `?token=` query-string parameter instead:

```
{wsBaseUrl}/rooms/XYZ789/ws?token=<id_token>
```

Get the ID token from the response of `POST /register`. It is short-lived (~1 hour) and cannot be refreshed — once it expires, the client must re-register to get a new one.

**Error responses from auth:**
- `401 { "error": "Missing credentials" }`
- `401 { "error": "Invalid or expired token" }`

---

## Health

### `GET /health`

| | |
|---|---|
| **Auth** | — |
| **Body** | — |

**Response `200`**
```json
{ "status": "ok" }
```

---

## Users

### `POST /register` — Register a new user

| | |
|---|---|
| **Auth** | ❌ Public |
| **URL** | `{baseUrl}/register` |

Creates a new Firebase Auth user (via Admin SDK) and a matching Firestore user doc with the given username. Returns an `idToken` ready to use as `Authorization: Bearer <idToken>` on subsequent requests.

**Body**
```json
{ "username": "Alice" }
```

**Validation:** `username` must be `minLength: 1, maxLength: 30`, and **must be unique** (case-insensitive).

**Response `201`**
```json
{
  "uid": "abc123",
  "username": "Alice",
  "createdAt": "2026-04-21T10:00:00.000Z",
  "updatedAt": "2026-04-21T10:00:00.000Z",
  "idToken": "eyJhbGci..."
}
```

**Error responses**
- `400` — validation failed (username length)
- `409` — `{ "error": "Username taken" }` — case-insensitive match against an existing username
- `500` — token exchange with Identity Toolkit failed (check `FIREBASE_WEB_API_KEY` env)

---

### `GET /users/:uid` — Fetch user by uid

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/users/{uid}` |

**Response `200`**
```json
{
  "uid": "abc123",
  "username": "Alice",
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Response `404`**
```json
{ "error": "User not found" }
```

---

## Rooms

### `POST /rooms` — Create a new room

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/rooms` |
| **Body** | `{}` |

The authenticated user automatically becomes `player1`. A unique 6-char code `[A-Z0-9]{6}` is generated server-side (up to 5 collision retries via `create()`).

**Response `201`**
```json
{
  "code": "XYZ789",
  "createdBy": "abc123",
  "createdAt": "...",
  "updatedAt": "...",
  "status": "available",
  "player1": "abc123",
  "player2": null
}
```

**Response `500`** — `Failed to allocate a unique room code after 5 attempts` (extremely rare)

---

### `GET /rooms/:code` — Fetch room by code

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/rooms/{CODE}` |

> Code is case-insensitive — backend uppercases it internally.

**Response `200`** — same shape as `POST /rooms`

**Response `404`**
```json
{ "error": "Room not found" }
```

---

### `POST /rooms/:code/join` — Join as player2

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/rooms/{CODE}/join` |
| **Body** | `{}` |

Atomic via Firestore transaction: sets `player2`, flips `status` to `unavailable`.

**Response `200`** — updated room object

**Error responses**
- `404` — `{ "error": "Room not found" }`
- `409` — `{ "error": "Room is unavailable" }` (already has player2 or status is `unavailable`)
- `410` — `{ "error": "Room is done" }`

---

### `GET /rooms/:code/ws` — Live room updates (WebSocket)

| | |
|---|---|
| **Auth** | ✅ Bearer (via `?token=` query param) |
| **URL** | `{wsBaseUrl}/rooms/{CODE}/ws?token=<id_token>` |

Subscribes to Firestore snapshot updates for the room. The token must be URL-encoded.

**Server → Client messages**
```json
{ "type": "room_update", "room": { ...RoomObject } }
```
```json
{ "type": "not_found" }
```

Once a match has been started via `POST /rooms/:code/start`, each `room_update` payload also includes a `game` field — an **array** of `GameStatePublic` (the last element is the current match; earlier entries are completed matches kept as history).

The server closes the socket after sending `not_found`.

---

### `POST /rooms/:code/start` — Start a match (first match or play again)

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/rooms/{CODE}/start` |
| **Body** | `{}` |

Dual-purpose endpoint:
- **First match** (when `game` is absent or empty): only the room creator (host) may call. A new match is created immediately. Star team is **randomly assigned** (50/50 between player1 and player2); Star plays first.
- **Play again** (when the last match is `done`): **either player** may call. The server records a vote into `playAgainVotes`. When **both** players have voted, the server appends a new match to `game[]`, clears the votes, and flips `status` back to `'unavailable'`. Star is re-randomized for each new match.

Every new match: a fresh 4×4 board, each player gets **10 random unique cards** drawn from the 12-card catalog, and the 30-second turn timer starts.

**Response `200`** — updated room. On a first-vote (play-again with only one voter so far), the response reflects just the vote addition (`playAgainVotes` updated). On match-creation, `game[]` length increases by one and `playAgainVotes` is cleared.

**Error responses**
- `400` — schema validation (e.g. `body must NOT have additional properties`)
- `403` — `{ "error": "Only the room creator can start the first match" }` (only on first match)
- `403` — `{ "error": "Not a player in this room" }`
- `404` — `{ "error": "Room not found" }`
- `409` — `{ "error": "Waiting for second player" }`
- `409` — `{ "error": "Match already in progress" }`
- `409` — `{ "error": "Opponent has left the room" }` (room has `leftBy` set)

---

### `POST /rooms/:code/leave` — Leave the room

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/rooms/{CODE}/leave` |
| **Body** | `{}` |

Either player can leave the room permanently (intended use: the "Leave" button on the end-of-match overlay). The server:
- Sets `status: 'done'` (no further matches allowed)
- Sets `leftBy` to the caller's uid
- Clears any pending `playAgainVotes`
- Cancels any in-flight turn timer

The remaining player sees the update via WebSocket and can no longer call `/start` — the end overlay displays an "opponent left" message.

Idempotent: calling `/leave` on a room that already has `leftBy` set still returns success, letting the leaver navigate away cleanly.

**Response `200`** — updated room object (`status='done'`, `leftBy=<caller>`)

**Error responses**
- `400` — schema validation
- `403` — `{ "error": "Not a player in this room" }`
- `404` — `{ "error": "Room not found" }`

---

### `POST /rooms/:code/play` — Play a card

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/rooms/{CODE}/play` |

**Body**
```json
{ "cellIndex": 5, "cardId": 3 }
```

- `cellIndex` — integer 0..15 (row-major on the 4x4 grid, `row * 4 + col`, row 0 = top).
- `cardId` — integer 1..12 (must be in the caller's hand).

**Rules enforced server-side:**
- Must be the caller's turn.
- Target cell must be empty.
- `cardId` must be in the caller's current hand **and not yet used** (each card can be played at most once per match — played cards stay in `hands` with `used: true`, they are not removed).
- **After the first move** (`turnNumber > 0`), the target cell must be 8-way adjacent (including diagonals) to at least one already-placed card.

**Placement effect:** for each of the placed card's own `directions`, we look at the immediate neighbor; if it holds an opposing card, we capture it iff
`placed.power > defender.power` **OR** `placed.element` beats `defender.element` (see `ELEMENT_BEATS` below). Captured cards flip their `ownerUid` — but they do NOT trigger further captures (no chain captures).

When the board fills (16 placements total), the room's `status` flips to `'done'` and `game.winner` is set to the uid with more owned cells (or `null` for an 8-8 tie).

**Response `200`** — updated room object including the refreshed `game` block. `game.lastMove` is populated with `{ cellIndex, cardId, placedBy, captures }` where `captures` is the list of cell indices captured by *this* move only.

**Error responses**
- `400` — schema validation failure (non-integer, out-of-range, missing field, extra field)
- `403` — `{ "error": "Not your turn" }`
- `404` — `{ "error": "Room not found" }`
- `409` — `{ "error": "Match not started" }`
- `409` — `{ "error": "Invalid cell index" }`
- `409` — `{ "error": "Cell occupied" }`
- `409` — `{ "error": "Card not in hand or already used" }`
- `409` — `{ "error": "Cell must be adjacent to an existing card" }`
- `410` — `{ "error": "Match is over" }`

**Turn timer (30 s).** When you receive a `room_update` with a new turn, `game.turnDeadline` is an ISO timestamp ~30 s ahead. If a player misses that deadline, the backend auto-plays a random legal move for them (random empty cell that respects the adjacency rule, random card from that player's remaining hand) and the state advances normally. Auto-play appears in `lastMove` the same as a human move.

> **Note.** Turn timers are in-memory and process-local. On a backend restart, any in-flight turn timer is lost and the match will stall until a player moves manually.

---

## Cards

### `GET /cards` — Catalog of all 12 cards

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/cards` |

Returns the full catalog of 12 cards as an array (sorted by `id`). The catalog is static and preloaded into server memory on first access; if you re-seed Firestore you must restart the server to see changes.

**Response `200`**
```json
[
  {
    "id": 1,
    "name": "POOPLE",
    "element": "earth",
    "power": 7,
    "directions": ["tr", "r"]
  }
]
```

---

### `GET /cards/:id` — Single card

| | |
|---|---|
| **Auth** | ✅ Bearer |
| **URL** | `{baseUrl}/cards/{id}` |

**Response `200`** — single `CardPublic`.

**Response `404`** — `{ "error": "Card not found" }` if `id` is not 1..12 or is otherwise unknown.

---

## Data Shapes

### `RoomStatus`
```
'available' | 'unavailable' | 'done'
```

### `RoomPublic`
```ts
{
  code: string              // 6-char A-Z0-9, primary key
  createdBy: string         // uid of room creator (host)
  createdAt: string         // ISO 8601
  updatedAt: string         // ISO 8601
  status: RoomStatus
  player1: string | null    // uid — NOT necessarily the Star team (Star is random per match)
  player2: string | null    // uid
  game?: GameStatePublic[]  // array; the LAST element is the current/just-finished match, earlier entries are history
  playAgainVotes?: string[] // uids who voted to start the next match since the last one ended; cleared on new match or leave
  leftBy?: string | null    // present when a player explicitly left; room is permanently done
}
```

> The "current match" is always `game[game.length - 1]`. Use `.at(-1)` or equivalent in your language.

### `GameStatePublic`
```ts
{
  board: (GameCell | null)[]          // length 16, row-major (row * 4 + col), row 0 = top
  hands: Record<string, HandCard[]>   // uid → 10-card hand; played cards remain with used=true
  turn: string                        // uid whose turn it is
  turnNumber: number                  // 0 = first move of this match
  turnStartedAt: string               // ISO 8601 — when the current turn began
  turnDeadline: string                // ISO 8601 — when auto-play triggers (~30s after turnStartedAt)
  startedAt: string                   // ISO 8601 — when THIS match started
  starUid: string                     // uid of the Star team player (random per match; Star plays first)
  score: Record<string, number>       // uid → count of owned cells in THIS match
  winner: string | null               // winner uid once done; null for 8-8 tie OR match still in progress
  lastMove: {
    cellIndex: number                 // 0..15
    cardId: number                    // 1..12
    placedBy: string                  // uid that played the card
    captures: number[]                // cell indices captured by this move (this move only, not historical)
  } | null
}
```

### `HandCard`
```ts
{
  cardId: number    // 1..12, references cards/{id}
  used: boolean     // true once the card has been played this match; stays in the array
}
```

Each player begins a match with 10 unique cards (drawn independently from the 12-card catalog, so the two players' sets may overlap). Played cards are not removed — they stay in the hand with `used: true`, which lets clients render them as a grayed-out "discard" pile inline.

### `GameCell`
```ts
{
  cardId: number     // 1..12, references cards/{id}
  ownerUid: string   // current owner — flips on capture; drives token (star/moon) rendering
  placedBy: string   // immutable — the uid that originally placed this card
}
```

> The star/moon team of a cell is derived as `ownerUid === starUid ? 'star' : 'moon'`. **Do not** assume `ownerUid === createdBy` means Star — that relation broke once Star became random per match.

### `CardPublic`
```ts
{
  id: number                          // 1..12
  name: string
  element: Element
  power: number
  directions: Direction[]
}
```

### `Element`
```
'earth' | 'water' | 'wind' | 'fire' | 'lightning' | 'ice'
| 'plant' | 'poison' | 'steel' | 'ghost' | 'light' | 'dark'
```

### `Direction`
```
't' | 'tr' | 'r' | 'br' | 'b' | 'bl' | 'l' | 'tl'
```

(`t` = top / row−1, `tr` = top-right / row−1 col+1, clockwise from there. `tl` = top-left closes the loop.)

### `ELEMENT_BEATS`

An attacker captures a defender (in the attacker's own attack direction only) when `attacker.element` appears in the defender's entry here — OR when `attacker.power > defender.power`. No chain captures.

```ts
{
  earth:     ['wind', 'fire', 'lightning'],
  water:     ['fire', 'poison', 'ghost'],
  wind:      ['water', 'ghost', 'dark'],
  fire:      ['plant', 'ice', 'steel'],
  lightning: ['water', 'ghost', 'light'],
  ice:       ['earth', 'wind', 'steel'],
  plant:     ['earth', 'water', 'light'],
  poison:    ['plant', 'ice', 'light'],
  steel:     ['wind', 'lightning', 'poison'],
  ghost:     ['earth', 'ice', 'dark'],
  light:     ['fire', 'steel', 'dark'],
  dark:      ['plant', 'lightning', 'poison'],
}
```

### `UserPublic`
```ts
{
  uid: string               // Firebase Auth uid, primary key
  username: string
  createdAt: string         // ISO 8601
  updatedAt: string         // ISO 8601
}
```
