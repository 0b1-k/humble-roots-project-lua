local lfs = require("lfs")
local log = _ENV.log

local count = 0

local function send(cfg, msg)
  if not cfg.sms.enabled then
    return
  end
  count = count + 1
  local filename = string.format("%s/%s.%s.txt", cfg.sms.outgoing, tostring(os.time()), tostring(count))
  local file, errMsg, errNum = io.open(filename, "w")
  if file == nil then
    log.error(string.format("Failed to open: %s, %s.", errMsg, tostring(errNum)))
    return
  end
  file:write(string.format("To: %s\n\n%s\n", cfg.sms.dest, msg))
  file:close()
  log.info(string.format("[SMS OUT] To:%s, %s", cfg.sms.dest, msg))
end

local function parse(fullPath, acceptFrom, onSmsMsg)
  local file, errMsg, errNum = io.open(fullPath, "r")
  if file == nil then
    log.error(string.format("Failed to open: %s, %s.", errMsg, tostring(errNum)))
    return
  end
  local data = {}
  while true do
    local line = file:read()
    if line == nil then
      break
    end
    table.insert(data, line)
  end
  file:close()
  
  local valid = false
  local bodyStart = false
  local body = {}
  for _, line in ipairs(data) do
    if bodyStart then
      table.insert(body, line)
    end
    if valid and not bodyStart then
      if #line == 0 then
        bodyStart = true
      end
    end
    if not valid and string.find(line, "From: ") ~= nil then
      if string.find(line, acceptFrom) ~= nil then
        valid = true
      else
        return
      end
    end
  end
  
  if bodyStart then
    local msg = table.concat(body)
    log.info(string.format("[SMS IN] %s, %s", acceptFrom, msg))
    onSmsMsg(acceptFrom, msg)
    local result, errMsg, errNum = os.remove(fullPath)
    if result == nil then
      log.error(string.format("Failed to remove %s, %s.", errMsg, tostring(errNum)))
    end
  end
end

local function getNextTime()
  return os.time() + 5
end

local nextTime = getNextTime()

local function receive(cfg, onSmsMsg)
  if not cfg.sms.enabled or os.time() < nextTime then
    return
  end
  for file in lfs.dir(cfg.sms.incoming) do
    if file ~= "." and file ~= ".." then
      local fullPath = string.format("%s/%s", cfg.sms.incoming, file)
      local attr = lfs.attributes(fullPath)
      if type(attr) == "table" and attr.mode == "file" then
        parse(fullPath, cfg.sms.accept, onSmsMsg)
      end
    end
  end
  nextTime = getNextTime()
end

local export = {}
export.send = send
export.receive = receive
return export
