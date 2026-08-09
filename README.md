# rmpcd-plugin-sleep-timer


## init.lua
``` lua
rmpcd.install("plugins.sleep"):setup({
 enabled = true
})
```

## Keybindings
``` ron
"ts":         ExternalCommand(command: ["rmpc", "sendmessage", "rmpcd.sleep", "{}"]),
"tk":         ExternalCommand(command: ["rmpc", "sendmessage", "rmpcd.sleep", "cancel"]),
```
