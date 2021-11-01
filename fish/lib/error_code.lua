local util = require "util"

local error_code = util.create_enum {
    "ok",
    "room_full",
    "room_not_exist",
    "unknown_error",
    "login_conflict",
    "low_activity",
    "reset_agent",
    "disconnect",
    "session_error",
}

return error_code