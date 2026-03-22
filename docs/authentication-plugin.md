# Authentication Plugin

## Overview

The Authentication Plugin is a custom Kong Gateway plugin responsible for validating incoming requests before they reach downstream microservices. It verifies the identity of the caller by validating the JWT token, checking its expiration, and confirming the token version with the authentication microservice.

---

## Responsibilities

- Identifies whether the requested route is public or private
- Validates the presence and format of the `Authorization` header
- Verifies the JWT signature using HMAC-SHA256
- Checks the token expiration
- Extracts claims (`CIN`, `role`, `tokenVersion`) from the token payload
- Calls the authentication microservice to verify the token version
- Injects identity headers into the forwarded request for downstream microservices

---

## Request Flow

```
Incoming Request
       │
       ▼
┌─────────────────────────────┐
│  Is the route public?       │──── YES ──► Check HTTP method
└─────────────────────────────┘                   │
       │ NO                              ┌─────────┴──────────┐
       ▼                                 │ Method matches?    │
┌─────────────────────────────┐          └─────────┬──────────┘
│  Authorization header       │             YES    │    NO
│  present?                   │              │     ▼
└─────────────────────────────┘              │   405 Method Not Allowed
       │ NO         │ YES                    │
       ▼            ▼                        ▼
  401 Missing   Extract Bearer          Pass through
               token                   (no auth check)
                   │
                   ▼
        ┌──────────────────────┐
        │  Verify JWT          │
        │  signature           │
        │  (HMAC-SHA256)       │
        └──────────────────────┘
                   │ INVALID        │ VALID
                   ▼                ▼
              401 Invalid    Check expiration
                                   │ EXPIRED    │ VALID
                                   ▼             ▼
                              401 Expired   Extract claims
                                            CIN, role,
                                            tokenVersion
                                                │
                                                ▼
                                   ┌────────────────────────┐
                                   │  POST /api/auth/        │
                                   │  validate-token         │
                                   │  (auth microservice)    │
                                   └────────────────────────┘
                                        │ 200 OK  │ ERROR
                                        ▼         ▼
                                   Inject      401 Invalid
                                   headers     token
                                   to request
                                        │
                                        ▼
                                   Downstream
                                   Microservice
```

---

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `JWT_SECRET_KEY` | Shared secret key used to verify the JWT signature. Must match the key used by the authentication microservice to sign tokens | ✅ Yes |
| `AUTH_SERVICE_URL` | Base URL of the authentication microservice | ✅ Yes |
| `INTERNAL_SECRET_KEY` | Internal secret injected into every forwarded request to prove the request passed through the gateway | ✅ Yes |

### Plugin Configuration

| Field | Value |
|---|---|
| `PRIORITY` | `900` |
| `VERSION` | `1.0` |

Priority `900` ensures this plugin runs **after** the tenant (`1000`) and subscription (`950`) plugins, and **before** the authorization plugin (`850`).

---

## Public Routes

Public routes are defined in `plugins/config/public_routes.lua`. Each public route specifies the allowed HTTP method. Requests to public routes bypass JWT verification entirely.

```lua
local PUBLIC_ROUTES = {
    ["/api/auth"]         = { method = "POST" },  -- Login
    ["/api/auth/request"] = { method = "POST" },  -- Forgot password
    ["/api/auth/verify"]  = { method = "POST" },  -- Verify OTP
    ["/api/auth/reset"]   = { method = "POST" },  -- Reset password
}
```

If a request hits a public route with the **wrong HTTP method**, the plugin returns `405 Method Not Allowed`.

---

## JWT Verification

Tokens are signed using `HMAC-SHA256`. The plugin implements the HMAC-SHA256 algorithm manually using the `resty.sha256` library and LuaJIT's `bit` library — no external JWT library is required.

### Token Structure

```
header.payload.signature
```

The plugin:
1. Splits the token into three parts
2. Recomputes the expected signature from `header.payload` using the secret key
3. Compares the expected signature with the provided signature

### Claims Expected in Payload

| Claim | Description |
|---|---|
| `sub` | The user's CIN (national identity number) |
| `role` | The user's role (e.g. `CEO`, `HR`, `EMPLOYEE`) |
| `tokenVersion` | The current version of the token, used to detect logouts |
| `exp` | Token expiration timestamp (Unix time) |

---

## Token Validation via Authentication Microservice

After verifying the JWT signature and expiration locally, the plugin makes a call to the authentication microservice to perform a full server-side token validation. This is the final and most critical verification step. It performs four checks in order:

1. **User existence** — verifies the CIN exists in the database. If the user is not found, the token is rejected even if the signature is valid
2. **Token version** — verifies the token version in the payload matches the version stored in the database. When a user logs out, the token version is incremented in the database, making all previously issued tokens invalid
3. **Account enabled** — verifies `IsEnable` is `true`. Disabled accounts cannot access the system regardless of token validity
4. **Account not locked** — verifies `IsLocked` is `false`. Locked accounts cannot access the system regardless of token validity

If any of these checks fail, the authentication microservice returns a non-200 response and the gateway immediately rejects the request.

### Request to Auth Microservice

```
POST {AUTH_SERVICE_URL}/api/auth/validate-token

Body:
{
    "CIN": "f1234567",
    "tokenVersion": 1
}
```

### Validation Checks and Responses

| Check | Failure Response | Condition |
|---|---|---|
| User existence | `404 Not Found` | CIN does not exist in the database |
| Token version | `401 Unauthorized` | Token version in payload does not match database |
| Account enabled | `403 Forbidden` | `IsEnable` is `false` |
| Account not locked | `403 Forbidden` | `IsLocked` is `true` |
| All checks pass | `200 OK` | Token is fully valid |

## Injected Headers

On successful validation, the plugin injects the following headers into the forwarded request:

| Header | Value | Purpose |
|---|---|---|
| `X-User-CIN` | User's CIN extracted from JWT | Identifies the user in downstream microservices |
| `X-User-Role` | User's role extracted from JWT | Used by the authorization plugin and microservices |
| `X-Internal-Secret-Key` | Value of `INTERNAL_SECRET_KEY` | Proves the request passed through the gateway |

---

## Error Responses

All error responses follow this format:

```json
{
    "timestamp": "2026-03-19T02:13:00Z",
    "message": "Human readable error message"
}
```

| Status Code | Condition |
|---|---|
| `401` | Missing Authorization header |
| `401` | Invalid token format |
| `401` | Invalid token signature |
| `401` | Token expired |
| `401` | Missing or invalid claims in payload |
| `401` | Token version mismatch or account disabled/locked |
| `403` | Wrong HTTP method on a public route |
| `405` | Wrong HTTP method on a public route |
| `503` | `JWT_SECRET_KEY` not configured |
| `503` | Authentication microservice unreachable |

---

## File Location

```
plugins/
└── authentication/
    ├── handler.lua    ← Plugin logic
    └── schema.lua     ← Plugin schema definition
```