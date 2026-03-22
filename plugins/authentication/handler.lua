local cjson = require "cjson"
local http = require "resty.http"
local sha256 = require "resty.sha256"
local bit = require "bit"

local PUBLIC_ROUTES = require "kong.plugins.config.public_routes"

-- * Load secret key and auth service URL from environment variables
local JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
local AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL")
local INTERNAL_SECRET_KEY = os.getenv("INTERNAL_SECRET_KEY")

local AuthenticationPlugin = {
    PRIORITY = 900,
    VERSION = "1.0"
}

-- * Base64url decode
local function base64url_decode(input)

    input = input:gsub("-", "+"):gsub("_", "/")
    local pad = #input % 4
    if pad == 2 then
        input = input .. "=="
    elseif pad == 3 then
        input = input .. "="
    end
    return ngx.decode_base64(input)
end

-- * Base64url encode
local function base64url_encode(input)

    return ngx.encode_base64(input):gsub("+", "-"):gsub("/", "_"):gsub("=", "")
end

-- * HMAC-SHA256 using resty.sha256 + LuaJIT bit library
local function hmac_sha256(secret, message)

    local BLOCK_SIZE = 64

    -- If key longer than block size, hash it
    if #secret > BLOCK_SIZE then
        local h = sha256:new()
        h:update(secret)
        secret = h:final()
    end

    -- Pad key to block size with zeros
    while #secret < BLOCK_SIZE do
        secret = secret .. "\0"
    end

    -- Build ipad and opad
    local ipad = {}
    local opad = {}
    for i = 1, BLOCK_SIZE do
        local b = secret:byte(i)
        ipad[i] = string.char(bit.bxor(b, 0x36))
        opad[i] = string.char(bit.bxor(b, 0x5c))
    end
    ipad = table.concat(ipad)
    opad = table.concat(opad)

    -- Inner hash: SHA256(ipad || message)
    local inner = sha256:new()
    inner:update(ipad)
    inner:update(message)
    local inner_result = inner:final()

    -- Outer hash: SHA256(opad || inner)
    local outer = sha256:new()
    outer:update(opad)
    outer:update(inner_result)
    return outer:final()
end

-- * Parse and verify JWT
local function parse_jwt(token, secret)

    local parts = {}
    for part in token:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    if #parts ~= 3 then
        return nil, "malformed token: expected 3 parts, got " .. #parts
    end

    -- Recompute signature and compare
    local signing_input = parts[1] .. "." .. parts[2]
    local expected_sig = base64url_encode(hmac_sha256(secret, signing_input))

    if expected_sig ~= parts[3] then
        return nil, "invalid signature"
    end

    -- Decode payload
    local payload_json = base64url_decode(parts[2])
    if not payload_json then
        return nil, "failed to base64url decode payload"
    end

    local ok, payload = pcall(cjson.decode, payload_json)
    if not ok then
        return nil, "failed to JSON decode payload"
    end

    return payload, nil
end

function AuthenticationPlugin:access(conf)

    -- * Check if route is public
    local path = kong.request.get_path()

    local route = PUBLIC_ROUTES[path]
    if route then
        local method = kong.request.get_method()
        if method == route.method then
            kong.log.notice("Public route : " .. method .. " " .. path)
            return
        end

        -- * Wrong verb on a public path
        return kong.response.exit(405, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Method not allowed"
        })
    end

    -- * Check Authorization header
    local auth_header = kong.request.get_header("Authorization")

    if not auth_header then
        return kong.response.exit(401, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Authorization header missing"
        })
    end

    local token = auth_header:match("Bearer%s+(.+)")

    if not token then
        return kong.response.exit(401, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Invalid token format"
        })
    end

    -- * Verify JWT signature and decode payload
    if not JWT_SECRET_KEY then
        return kong.response.exit(503, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Gateway is not properly configured"
        })
    end

    local payload, err = parse_jwt(token, JWT_SECRET_KEY)

    if not payload then
        return kong.response.exit(401, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Invalid token signature"
        })
    end

    -- * Check expiration
    if payload.exp and payload.exp < ngx.time() then
        return kong.response.exit(401, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Token expired"
        })
    end

    -- * Extract claims — must match exactly what C# puts in the token
    local CIN = payload.sub
    local role = payload.role
    local tokenVersion = payload.tokenVersion

    if not CIN or not role or not tokenVersion then
        return kong.response.exit(401, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Invalid token payload"
        })
    end

    -- * Call auth microservice to verify token version
    local httpc = http.new()
    local res, req_err = httpc:request_uri(AUTH_SERVICE_URL .. "/api/auth/validate-token", {
        method = "POST",
        body = cjson.encode({
            CIN = CIN,
            tokenVersion = tonumber(tokenVersion)
        }),
        headers = {
            ["Content-Type"] = "application/json"
        }
    })

    if not res then
        return kong.response.exit(503, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Authentication service unavailable"
        })
    end

    if res.status ~= 200 then
        return kong.response.exit(401, {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", ngx.time()),
            message = "Invalid token"
        })
    end

    -- * Forward identity to downstream microservices
    kong.service.request.set_header("X-User-CIN", CIN)
    kong.service.request.set_header("X-User-Role", role)
    kong.service.request.set_header("X-Internal-Secret-Key", INTERNAL_SECRET_KEY)
end

return AuthenticationPlugin
