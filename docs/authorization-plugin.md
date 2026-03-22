# Authorization Plugin

## Overview

The Authorization Plugin is a custom Kong Gateway plugin responsible for enforcing role-based access control (RBAC) on incoming requests. It runs after the Authentication Plugin and uses the role injected in the `X-User-Role` header to decide whether the user is allowed to access the requested route.

---

## Responsibilities

- Reads the user's role from the `X-User-Role` header (injected by the Authentication Plugin)
- Checks the requested path against the route access policy
- Blocks access with `403 Forbidden` if the user's role is not allowed
- Passes through any route not defined in the policy (accessible by any authenticated user)

---

## Request Flow

```
Incoming Request
(already authenticated)
       │
       ▼
┌──────────────────────────────────┐
│  Read X-User-Role header         │
│  Read request path               │
└──────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│  Iterate over ROUTE_ACCESS_POLICY│
│  Find a route that matches       │
│  the request path (starts_with)  │
└──────────────────────────────────┘
       │                    │
  MATCH FOUND          NO MATCH FOUND
       │                    │
       ▼                    ▼
┌─────────────────┐    Pass through
│ Is user role    │    (any authenticated
│ in allowed_roles│     user allowed)
└─────────────────┘
       │           │
   YES (allowed)  NO (blocked)
       │           │
       ▼           ▼
  Pass through   403 Forbidden
  to microservice
```

---

## Configuration

### Plugin Configuration

| Field | Value |
|---|---|
| `PRIORITY` | `850` |
| `VERSION` | `1.0` |

Priority `850` ensures this plugin runs **after** the authentication plugin (`900`), which means the `X-User-Role` header is already available when this plugin executes.

---

## Route Access Policy

The access policy is defined in `plugins/config/route_access_policy.lua`. Each entry maps a route prefix to a set of roles that are allowed to access it.

### Structure

```lua
local ROUTE_ACCESS_POLICY = {
    ["/api/some-route"] = {
        ROLE_NAME = true,
        OTHER_ROLE = true
    }
}
```

### Route Matching

The plugin uses a **prefix match** strategy. A route entry matches if the request path **starts with** the defined route prefix.

**Examples:**

| Request Path | Route Prefix | Match |
|---|---|---|
| `/api/internal-users/departments` | `/api/internal-users/departments` | ✅ |
| `/api/internal-users/departments/some-id` | `/api/internal-users/departments` | ✅ |
| `/api/internal-users/users` | `/api/internal-users/departments` | ❌ |

### Unrestricted Routes

Any route **not defined** in the policy is accessible by **any authenticated user** regardless of role. This means you only need to add routes that have role restrictions — not every route in the system.

```
Route in policy     → role check enforced
Route NOT in policy → any authenticated user can access
```

---

## Current Access Policy

```
┌─────────────────────────────────────────┬───────────────────┐
│ Route                                   │ Allowed Roles     │
├─────────────────────────────────────────┼───────────────────┤
│ /api/auth/user                          │ HR, CEO           │
│ /api/internal-users/departments         │ HR, CEO           │
│ /api/internal-users/posts               │ HR, CEO           │
│ /api/internal-users/promotions          │ HR, CEO           │
│ /api/internal-users/resignations        │ HR, CEO           │
│ /api/internal-users/holidays            │ HR, CEO           │
│ /api/settings                           │ CEO               │
└─────────────────────────────────────────┴───────────────────┘
```

Routes not in this table (e.g. `/api/notification`, `/api/auth/logout`) are accessible by any authenticated user.

---

## Available Roles

| Role | Description |
|---|---|
| `CEO` | Full access to all restricted routes |
| `HR` | Access to HR management routes |
| `EMPLOYEE` | Access to employee self-service routes |
| `MANAGER` | Access to manager routes |
| `TECHNICAL` | Access to technical routes |

---

## Error Response

When access is denied, the plugin returns:

```json
{
    "timestamp": "2026-03-19T02:13:00Z",
    "message": "You don't have permission to access this resource"
}
```

| Status Code | Condition |
|---|---|
| `403 Forbidden` | User's role is not in the allowed roles for the matched route |

---

## How to Add a New Restricted Route

Open `plugins/config/route_access_policy.lua` and add a new entry:

```lua
["/api/new-microservice/resource"] = {
    HR  = true,
    CEO = true
}
```

No code change is needed in the plugin itself — only the policy file needs to be updated.

---

## Plugin Execution Order

```
Priority 1000 → Tenant Plugin         (extract subdomain)
Priority 950  → Subscription Plugin   (verify subscription)
Priority 900  → Authentication Plugin (verify JWT, inject headers)
Priority 850  → Authorization Plugin  (verify role)  ← this plugin
```

---

## File Location

```
plugins/
└── authorization/
    ├── handler.lua    ← Plugin logic
    └── schema.lua     ← Plugin schema definition

plugins/
└── config/
    └── route_access_policy.lua  ← Role-based access rules
```