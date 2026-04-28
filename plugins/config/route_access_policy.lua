local ROUTE_ACCESS_POLICY = {

    -- * Authentication microservice (Create users)

    ["/api/auth/user"] = {
        POST = {
            HR = true,
            CEO = true
        }
    },

    -- * Internal users management microservice

    -- * User
    ["/api/internal-users/user/submit/"] = {
        POST = {
            EMPLOYEE = true,
            MANAGER = true,
            TECHNICAL = true
        }
    },

    ["/api/internal-users/user"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        }
    },

    -- * Bank Information
    ["/api/internal-users/bank-informations/submit/"] = {
        POST = {
            EMPLOYEE = true,
            MANAGER = true,
            TECHNICAL = true
        }
    },

    ["/api/internal-users/bank-informations/"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        }
    },

    -- * Education
    ["/api/internal-users/educations/submit/"] = {
        POST = {
            EMPLOYEE = true,
            MANAGER = true,
            TECHNICAL = true
        }
    },

    ["/api/internal-users/educations/"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        }
    },

    -- * Professional Experiences
    ["/api/internal-users/professional-experiences/submit/"] = {
        POST = {
            EMPLOYEE = true,
            MANAGER = true,
            TECHNICAL = true
        }
    },

    ["/api/internal-users/professional-experiences/"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        }
    },

    -- * Profile update requests
    ["/api/internal-users/profile-update-requests"] = {
        GET = {
            HR = true,
            CEO = true
        },
        PATCH = {
            HR = true,
            CEO = true
        }
    },

    -- * Departments
    ["/api/internal-users/departments"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        },
        GET = {
            HR = true,
            CEO = true
        }
    },

    -- * Posts
    ["/api/internal-users/posts"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        },
        GET = {
            HR = true,
            CEO = true
        }
    },

    -- * Promotions
    ["/api/internal-users/promotions"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        },
        GET = {
            HR = true,
            CEO = true
        }
    },

    -- * Resignations
    ["/api/internal-users/resignations"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        },
        GET = {
            HR = true,
            CEO = true
        }
    },

    -- * Holidays
    ["/api/internal-users/holidays"] = {
        POST = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        },
        GET = {
            HR = true,
            CEO = true
        }
    },

    -- * Settings Management microservice

    -- * Absence justifications
    ["/api/settings/absence-justifications"] = {
        GET = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        }
    },

    -- * Alert thresholds
    ["/api/settings/alert-thresholds"] = {
        GET = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        }

    },

    -- * Annual leaves
    ["/api/settings/annual-leaves"] = {
        GET = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        }
    },

    -- * Document templates
    ["/api/settings/document-templates"] = {
        POST = {
            HR = true,
            CEO = true
        }
    },

    ["/api/settings/document-templates/"] = {
        GET = {
            HR = true,
            CEO = true
        },
        DELETE = {
            HR = true,
            CEO = true
        }
    },

    -- * Exceptional leaves
    ["/api/settings/exceptional-leaves"] = {
        GET = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        }
    },

    -- * Recruitment sites
    ["/api/settings/recruitment-sites"] = {
        PUT = {
            HR = true,
            CEO = true
        }
    },

    -- * Work schedules
    ["/api/settings/work-schedules"] = {
        GET = {
            HR = true,
            CEO = true
        },
        PUT = {
            HR = true,
            CEO = true
        }
    },

    -- * Logging system microservice

    -- * Audits
    ["/api/v1/audits"] = {
        GET = {
            CEO = true
        }
    }
}

return ROUTE_ACCESS_POLICY
