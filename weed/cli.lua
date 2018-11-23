local socket = require("socket")
local config = require("config")

local function send(arg)
  print("cmd: " .. arg[1])
  local cfg = config.getConfig("./config/config.toml")
  local cli = 0
  local err = ""
  cli, err = socket.connect(cfg.shell.bind, cfg.shell.port)
  if cli ~= nil then
    cli:send(arg[1] .. "\n")
    local resp = cli:receive("*a")
    if resp ~= nil then
      print("response:\n" .. resp)
    else
      print("no response\n")
    end
    cli:shutdown()
    cli:close()
  end
end

send(arg)
