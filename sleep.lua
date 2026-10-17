---@class SleepPlugin : RmpcdPlugin<{}>
---@field stop_on_song_change boolean
---@field timeout_handle TimeoutHandle | nil
---@field timer_end_ms number | nil
---@field timer_immediate boolean

---@type SleepPlugin
local M = {
  stop_on_song_change = false,
  timer_end_ms = nil,
  timer_immediate = false,
}

M.subscribed_channels = { "rmpcd.sleep" }

-- Action taken when the timer (or song-change) fires.
-- Change with: stop_action = mpd.pause   
local stop_action = mpd.stop

local function status(msg)
  process.spawn({ "rmpc", "remote", "status", msg })
end

-- "10"=10s, "10m", "1h", "2d"; "i" prefix = immediate (no song-finish wait)
-- Returns: (milliseconds, is_immediate)
local function parse_duration(input)
  if not input then
    return nil, false
  end

  local immediate = input:sub(1, 1):lower() == "i"
  if immediate then
    input = input:sub(2)
  end

  input = input:match("^%s*(.-)%s*$") or ""
  if input == "" then
    return immediate and 0 or nil, immediate
  end

  local num, suffix = input:match("^([%d%.]+)([smhd]?)$")
  if not num then
    return nil, immediate
  end

  local mult = ({ s = 1, m = 60, h = 3600, d = 86400 })[suffix] or 1
  return tonumber(num) * mult * 1000, immediate
end

-- Format ms as "2d 3h", "1h 5m", "10m 30s", "45s"
local function format_duration(ms)
  local s = math.max(0, ms) / 1000
  local d = math.floor(s / 86400)
  local h = math.floor(s / 3600) % 24
  local m = math.floor(s / 60) % 60
  local sec = math.floor(s) % 60

  local parts = {}
  if d > 0 then parts[#parts + 1] = d .. "d" end
  if h > 0 then parts[#parts + 1] = h .. "h" end
  if m > 0 then parts[#parts + 1] = m .. "m" end
  if sec > 0 or #parts == 0 then parts[#parts + 1] = sec .. "s" end
  return table.concat(parts, " ")
end

local function now_ms()
  return os.time() * 1000
end

local function stop_timer(self)
  if self.timeout_handle then
    self.timeout_handle:cancel()
  end
  self.timeout_handle = nil
  self.stop_on_song_change = false
  self.timer_end_ms = nil
  self.timer_immediate = false
end

-- Run the current stop action via the table so swappable function works
local function do_stop()
  stop_action()
end

M.message = function(self, _channel, message)
  if message == "status" then
    if self.stop_on_song_change then
      status("Sleep timer: stopping after current song")
    elseif self.timer_end_ms then
      -- Round up to the next whole second so "10m" never shows "9m 59s"
      local remaining = math.ceil((self.timer_end_ms - now_ms()) / 1000) * 1000
      local mode = self.timer_immediate
          and " (immediate stop)"
          or " (after song finishes)"
      status(string.format("Sleep timer: %s remaining%s",
        format_duration(remaining), mode))
    else
      status("Sleep timer: not set")
    end
  elseif message == "cancel" then
    stop_timer(self)
    status("Cancelled playback sleep")
  else
    local delay_ms, immediate = parse_duration(message)
    if not delay_ms then
      status("Invalid format. Try: 10, 10m, 1h, 2d, i10m")
      return
    end

    stop_timer(self)
    self.timer_end_ms = now_ms() + delay_ms
    self.timer_immediate = immediate

    self.timeout_handle = sync.set_timeout(delay_ms, function()
      self.timeout_handle = nil
      self.timer_end_ms = nil
      self.timer_immediate = false
      if immediate then
        do_stop()
        status("Playback stopped")
      else
        -- Deadline passed while song still playing: wait for song end
        self.stop_on_song_change = true
        status("Will stop after song finishes")
      end
    end)

    status(string.format("Sleep timer set for %s%s",
      format_duration(delay_ms), immediate and " (immediate stop)" or ""))
  end
end

M.song_change = function(self, _old, _new)
  if self.stop_on_song_change then
    self.stop_on_song_change = false
    do_stop()
    status("Stopped (sleep timer)")
  end
end

return M
