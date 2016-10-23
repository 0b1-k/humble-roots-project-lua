local socket = require("socket")
local log = _ENV.log

local server = 0
local count = 0
local lastLine = ""

local function initialize(bind, portNum)
  local err = 0
  server, err = socket.bind(bind, portNum)
  if server == nil then
    log.error(string.format("Failed to bind: %s", err))
    return
  end
  server:settimeout(0.01)
  local ip, port = server:getsockname()
  log.info(string.format("Shell listening @ %s:%s", ip, tostring(port)))
end

local function receive(onShellMsg)
  if server == nil then
    return nil
  end
  local client = server:accept()
  local line = ""
  if client ~= nil then
    client:settimeout(0.100)
    local line, err = client:receive()
    if not err then
      if line ~= lastLine then
        count = count + 1
        lastLine = line
        local resp = onShellMsg(line)
        if resp ~= nil then
          client:send(resp)
        end
      end
    end
    client:close()
  end
  return line
end

local function shutdown()
  if server ~= nil then
    server:close()
  end
end

local export = {}
export.initialize = initialize
export.receive = receive
export.shutdown = shutdown
return export
