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

**Validation:** `username` must be `minLength: 1, maxLength: 30`.

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

The server closes the socket after sending `not_found`.

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
  createdBy: string         // uid
  createdAt: string         // ISO 8601
  updatedAt: string         // ISO 8601
  status: RoomStatus
  player1: string | null    // uid
  player2: string | null    // uid
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
