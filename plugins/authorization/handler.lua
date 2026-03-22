local ROUTE_ACCESS_POLICY = require "kong.plugins.config.route_access_policy"

local AuthorizationPlugin = {}

AuthorizationPlugin.PRIORITY = 850
AuthorizationPlugin.VERSION = "1.0"

-- * Helper function to check if a string starts with a given prefix
local function starts_with(str, prefix)

    return str:sub(1, #prefix) == prefix
end

function AuthorizationPlugin:access(conf)

    local role = kong.request.get_header("X-User-Role")
    local path = kong.request.get_path()

    -- * Check user role against allowed roles for the requested route
    for route, allowed_roles in pairs(ROUTE_ACCESS_POLICY) do

        if starts_with(path, route) then
            if not allowed_roles[role] then
                return kong.response.exit(403, {
                    timestamp = ngx.time(),
                    message = "You don't have permission to access this resource"
                })
            end

            break
        end
    end

end

return AuthorizationPlugin
