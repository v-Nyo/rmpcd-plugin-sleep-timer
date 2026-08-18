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
```
