local PUBLIC_ROUTES = {
    ["/api/auth"] = {
        method = "POST" -- * Login
    },
    ["/api/auth/request"] = {
        method = "POST" -- * Forgot password
    },
    ["/api/auth/verify"] = {
        method = "POST" -- * Verify OTP
    },
    ["/api/auth/reset"] = {
        method = "POST" -- * Reset password
    },

    -- * Recruitment site
    ["/api/settings/recruitment-sites"] = {
        method = "GET"
    },
    ["/api/settings/recruitment-sites/logo"] = {
        method = "GET"
    }
}

return PUBLIC_ROUTES
