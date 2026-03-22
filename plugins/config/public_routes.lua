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
    }
}

return PUBLIC_ROUTES
