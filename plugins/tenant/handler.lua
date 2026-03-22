local TenantPlugin = {}

TenantPlugin.PRIORITY = 1000
TenantPlugin.VERSION = "1.0"

function TenantPlugin:access(conf)

    local host = kong.request.get_header("Host")

    if not host then
        return kong.response.exit(400, {
            message = "Host header missing"
        })
    end

    host = host:gsub(":%d+$", "")

    if kong.request.get_method() == "OPTIONS" then
        return
    end

    local subdomain

    if host == "localhost" or host == "127.0.0.1" then
        subdomain = "dev-local"
    else

        local parts = {}

        for part in host:gmatch("[^%.]+") do
            table.insert(parts, part)
        end

        if #parts < 3 then
            return kong.response.exit(400, {
                message = "Missing subdomain. Expected tenant.woridge.com"
            })
        end

        subdomain = parts[1]

    end

    kong.service.request.set_header("X-Subdomain", subdomain)

end

return TenantPlugin
