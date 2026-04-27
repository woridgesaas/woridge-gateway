local ROUTE_ACCESS_POLICY = require "kong.plugins.config.route_access_policy"

local AuthorizationPlugin = {}

AuthorizationPlugin.PRIORITY = 850
AuthorizationPlugin.VERSION = "1.0"

local function starts_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

local sorted_routes = {}
for route, methods in pairs(ROUTE_ACCESS_POLICY) do
    table.insert(sorted_routes, {
        route = route,
        methods = methods
    })
end
table.sort(sorted_routes, function(a, b)
    return #a.route > #b.route
end)

function AuthorizationPlugin:access(conf)

    local role = kong.request.get_header("X-User-Role")
    local path = kong.request.get_path()
    local method = kong.request.get_method()

    for _, entry in ipairs(sorted_routes) do

        if starts_with(path, entry.route) then

            local allowed_roles = entry.methods[method]

            if allowed_roles == nil then
                break
            end

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
