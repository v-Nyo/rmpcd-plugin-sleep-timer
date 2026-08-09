---@class SleepPlugin : RmpcdPlugin<{}>
---@field stop_on_song_change boolean
---@field timeout_handle TimeoutHandle | nil

---@type SleepPlugin
local M = {
    stop_on_song_change = false,
}

M.subscribed_channels = { "rmpcd.sleep" }

-- Parse duration: "10"=10s, "10m"=10min, "1h"=1hour, "i10m"=immediate stop after 10min
-- Returns: (milliseconds, is_immediate)
local function parse_duration(input)
    if not input then return nil, false end
    
    input = string.gsub(input, "%s+", "")
    local immediate = false
    
    if input:sub(1, 1):lower() == "i" then
        immediate = true
        input = input:sub(2)
    end
    
    if input == "" then return immediate and 0 or nil, immediate end
    
    local num, suffix = input:match("^([%d%.]+)([smhd]?)$")
    if not num then return nil, immediate end
    
    local value = tonumber(num)
    if not value then return nil, immediate end
    
    local mult = ({s=1, m=60, h=3600, d=86400})[suffix] or 1
    return value * mult * 1000, immediate
end

-- Helper to format ms into "Xm", "Xh", "Xs"
local function format_duration(ms)
    local s = ms / 1000
    if s >= 3600 then
        local h = math.floor(s / 3600)
        local m = math.floor((s % 3600) / 60)
        return string.format("%dh %dm", h, m)
    elseif s >= 60 then
        return string.format("%dm", math.floor(s / 60))
    else
        return string.format("%ds", math.floor(s))
    end
end

M.message = function(self, _channel, message)
    if message == "cancel" then
        self.stop_on_song_change = false
        if self.timeout_handle then
            self.timeout_handle:cancel()
            self.timeout_handle = nil
        end
        process.spawn({ "rmpc", "remote", "status", "Cancelled playback sleep" })
        return
    end

    local delay_ms, immediate = parse_duration(message)
    
    if not delay_ms then
        process.spawn({ "rmpc", "remote", "status", "Invalid format. Try: 10, 10m, 1h, i10m" })
        return
    end

    if self.timeout_handle then
        self.timeout_handle:cancel()
        self.timeout_handle = nil 
    end

    local display = format_duration(delay_ms)
    local mode_text = immediate and " (immediate stop)" or ""

    self.timeout_handle = sync.set_timeout(delay_ms, function()
        if immediate then
            mpd.stop()
            process.spawn({ "rmpc", "remote", "status", "Playback stopped" })
        else
            self.stop_on_song_change = true
            process.spawn({ "rmpc", "remote", "status", "Will stop after song finishes" })
        end
        self.timeout_handle = nil
    end)

    process.spawn({ "rmpc", "remote", "status", string.format("Sleep timer set for %s%s", display, mode_text) })
end

M.song_change = function(self, _old, _new)
    if self.stop_on_song_change then
        self.stop_on_song_change = false
        mpd.stop()
        process.spawn({ "rmpc", "remote", "status", "Stopped (sleep timer)" })
    end
end

return M
