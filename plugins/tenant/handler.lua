local TenantPlugin = {}
local http = require "resty.http"
local cjson = require "cjson"
local internal_secret = os.getenv("INTERNAL_SECRET_KEY")
local tenant_check_host = os.getenv("TENANT_CHECK_HOST")
TenantPlugin.PRIORITY = 1000
TenantPlugin.VERSION = "1.0"

function TenantPlugin:access(conf)
    kong.log.err("local vars : " , hosts)
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
        kong.ctx.shared.tenant_data = {
            status = "ACTIVE",
            isAccessGranted = true,
            subdomain = subdomain
        }
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
        --Call external service
        local client = http.new()
        local res, err = client:request_uri(tenant_check_host .. subdomain, {
            method = "GET",
            headers = { ["X-Internal-Secret"] = internal_secret ,["Accept"] = "application/json"}
        })

        if not res then
                kong.log.err("Tenant check service unrecheable ")
                return kong.response.exit(503, { message = "Tenant service unavailable" })
        end

        if res.status ~= 200 then
            return kong.response.exit(404, { message = "Tenant non reconnu" })
        end
        local data = cjson.decode(res.body)
        kong.log.err("fullobject : ", cjson.encode(data))

        kong.ctx.shared.tenant_data = data --cache the result to use it in subscription plugin
    end

    kong.service.request.set_header("X-Subdomain", subdomain)

end

return TenantPlugin
