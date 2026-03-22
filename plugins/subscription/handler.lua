local tenants = require "kong.plugins.config.tenants"

local SubscriptionPlugin = {}

SubscriptionPlugin.PRIORITY = 950
SubscriptionPlugin.VERSION = "1.0"

function SubscriptionPlugin:access(conf)

    local subdomain = kong.request.get_header("X-Subdomain")

    if not subdomain then
        return kong.response.exit(400, {
            message = "Tenant not found"
        })
    end

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

    kong.service.request.set_header("X-Tenant-Status", status)

end

return SubscriptionPlugin
