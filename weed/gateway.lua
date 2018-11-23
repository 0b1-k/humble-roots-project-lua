local log = _ENV.log
local _ = require("serial")
local rules = require("rules")

local port = {}
local retryQueue = {}
local retryMax = 2
local stopEventLoop = false

local function getRetryObj()
  local obj = {
    ["retries"] = retryMax
  }
  return obj
end

local function send(cmdFinal, retryObj)  
  local sentBytes = port:write(cmdFinal .. "\n")
  port:drainTX()
  if sentBytes ~= #cmdFinal + #"\n" then
    local errorMsg = string.format("Failed serial write(%s). Sent bytes: %s ~= %s", cmdFinal, sentBytes, #cmdFinal)
    log.fatal(errorMsg)
    error(errorMsg)
  end
  if retryObj == nil then
    retryQueue[cmdFinal] = getRetryObj()
  end
  log.trace(string.format("Sent: %s", cmdFinal))
  --_ENV.io.Serial.del_us(1000 * 10)
end

local function retry(msg)
  local ackReceived = false
  if msg.tx == "ack" then
    ackReceived = true
  end
  msg["tx"] = nil
  local cmdFinal = rules.encode(msg)
  if ackReceived then
    retryQueue[cmdFinal] = nil
    return
  end
  local retryObj = retryQueue[cmdFinal]
  if retryObj ~= nil then
    retryObj.retries = retryObj.retries - 1
    if retryObj.retries > 0 then
      send(cmdFinal, retryObj)
      log.debug(string.format("Retry: %s (#%s)", cmdFinal, retryObj.retries))
    else
      log.info(string.format("Retries exceeded: %s", cmdFinal))
      retryQueue[cmdFinal] = nil
    end
  else
    log.error(string.format("Anomaly! Missing retry obj for nak'ed cmd: %s!", cmdFinal))
    for cmdFinal, retryObj in pairs(retryQueue) do
      log.error(string.format(">>> cmd: %s, retries: %s", cmdFinal, retryObj.retries))
    end
  end
end

local function shutdown()
  if port.opened ~= nil and port.opened then
    port:close()
    port = {}
  end
end

local function initialize(serialPort, baudRate)
  stopEventLoop = false
  retryQueue = {}
  local sp = io.Serial{
    port = serialPort,
    baud = baudRate,
    bits = 8,
    stops = 0,
    parity = 'n'
  }
  assert(sp ~= nil, string.format("Failed to open serial port: %s", serialPort))
  return sp
end

local function isStopped()
  return stopEventLoop
end

local function stop()
  stopEventLoop = true
  shutdown()
end

local function resetStopEvent()
  stopEventLoop = false
end

local function run(serialPort, baudrate, onData, onIdle)
  port = initialize(serialPort, baudrate)
  local data = {}
  while not stopEventLoop do
    local timeout = port:waitRX(1, 10)
    if timeout ~= 0 then
      local frag = port:read()
      for i = 1, #frag, 1 do
        local char = string.sub(frag, i, i)
        if char == '\r' or char == nil then
          goto skipCR
        elseif char == '\n' then
          local payload = table.concat(data)
          onData(payload)
          data = {}
        else
          table.insert(data, char)
        end
      ::skipCR::
      end
    else
      onIdle()
    end
  end
end

local export = {}
export.run = run
export.send = send
export.retry = retry
export.stop = stop
export.isStopped = isStopped
export.resetStopEvent = resetStopEvent
return export
