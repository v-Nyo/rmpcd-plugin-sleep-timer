# rmpcd-plugin-sleep-timer

## Installation

Put the following inside your `init.lua` to install using the integrated package manager.

```lua
rmpcd.install({ url = "https://github.com/v-Nyo/rmpcd-plugin-sleep-timer" })
```

Or clone the repository and copy `sleep.lua` into your `$HOME/.config/rmpcd/plugins/` directory and
add the following to your `init.lua`

```lua
rmpcd.install("plugins.sleep"):setup({
    enabled = true
})
```

## Keybindings
``` ron
"ts":         ExternalCommand(command: ["rmpc", "sendmessage", "rmpcd.sleep", "{}"]),
"tk":         ExternalCommand(command: ["rmpc", "sendmessage", "rmpcd.sleep", "cancel"]),
"tr":         ExternalCommand(command: ["rmpc", "sendmessage", "rmpcd.sleep", "status"]),
```

## Example input

| Command | Description |
|---------|-------------|
| `10`    | Timer for 10 seconds, then stops when the current song ends |
| `10s`   | Same as above (10 seconds) |
| `10m`   | Same as above, but with 10 minutes |
| `10h`   | 10 hours, then stops after the current song |
| `i10s`  | Timer for 10 seconds, then stops immediately (does not wait for song to finish) |
| `i10d`  | Same as above, but with 10 days|
