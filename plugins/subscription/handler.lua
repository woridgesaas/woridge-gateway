local tenants = require "kong.plugins.config.tenants"

local SubscriptionPlugin = {}

SubscriptionPlugin.PRIORITY = 950
SubscriptionPlugin.VERSION = "1.0"

function SubscriptionPlugin:access(conf)
    local data = kong.ctx.shared.tenant_data
    local subdomain = kong.request.get_header("X-Subdomain")

    local status = tenants[subdomain]

    if not status then
        return kong.response.exit(403, {
            message = "Unknown tenant"
        })
    end

    if status ~= "ACTIVE" then
        return kong.response.exit(403, {
            message = "Subscription inactive or expired"
        })
    end

    if not data or not data.isAccessGranted then
        return kong.response.exit(403, { 
            message = "Subscription inactive",
            status = data and data.status or "UNKNOWN"
        })
    end
    kong.service.request.set_header("X-Tenant-Status", data.status)

end

return SubscriptionPlugin
