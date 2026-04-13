local ROUTE_ACCESS_POLICY = {

    -- * Authentication microservice (Create users)
    ["/api/auth/user"] = {
        HR = true,
        CEO = true
    },

    -- * Internal users management microservice
    ["/api/internal-users/departments"] = {
        HR = true,
        CEO = true
    },

    ["/api/internal-users/posts"] = {
        HR = true,
        CEO = true
    },

    ["/api/internal-users/promotions"] = {
        HR = true,
        CEO = true
    },

    ["/api/internal-users/resignations"] = {
        HR = true,
        CEO = true
    },

    ["/api/internal-users/holidays"] = {
        HR = true,
        CEO = true
    },
    ["/api/v1/audits/"] = {
        CEO=true,
    }
}

return ROUTE_ACCESS_POLICY
