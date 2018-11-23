require("serial")
local smspdu = require("smspdu")

local log = _ENV.log
if log == nil then
  log = require("log")
  log.level = "info"
end

local _port = {}
local _response = {}
local _stopEventLoop = false
local _nextCommandReady = true
local _resultFunc = nil
local _context = nil

local msgSelectReceiveStorageCommands = {}
local msgReceiveCommands = {}
local msgDeleteReceivedCommands = {}
local msgSelectSendStorageCommands = {}
local msgStorePduCommands = {}
local msgSendCommands = {}
local msgDeleteSentCommands = {}
local shutdownCommands = {}
local inMessages = {}
local outMessages = {}

local function send(cmd)
  log.debug(string.format("-> %s", cmd))
  _nextCommandReady = false
  local sentBytes = _port:write(cmd)
  _port:drainTX()
  if sentBytes ~= #cmd then
    log.fatal("Failed to write all serial data!")
  end
end

local function shutdown()
  if _port.opened ~= nil and _port.opened then
    _port:close()
    _port = {}
  end
end

local function initialize(serialPort, baudRate)
  local sp = io.Serial{
    port = serialPort,
    baud = baudRate,
    bits = 8,
    stops = 0,
    parity = 'n'
  }
  if sp == nil then
    log.fatal(string.format("Failed to open serial port: %s", serialPort))
    error("open")
  else
    log.info(string.format("Opened serial port: %s", serialPort))
  end
  return sp
end

local _maxTimeout = 5000
local function setTimeout(timeout)
  _maxTimeout = timeout
end

local function onUnsolicitedMsg()
  send(string.char(0x1B))
  _stopEventLoop = true
  return false
end

local function run(serialPort, baudrate, onData, onIdle)
  _port = initialize(serialPort, baudrate)
  local data = {}
  local gtSeen = false
  local spaceSeen = false
  local timeoutMax = _maxTimeout
  local timeoutCount = 0
  local timeoutReceive = 10
  while not _stopEventLoop do
    local timeout = _port:waitRX(1, timeoutReceive)
    if timeout ~= 0 then
      timeoutCount = 0
      local frag = _port:read()
      for i = 1, #frag, 1 do
        local char = string.sub(frag, i, i)
        if char == ">" then
          gtSeen = true
        end
        if char == " " and gtSeen and #data == 1 then
          spaceSeen = true
          table.insert(data, ' ')
        end
        if char == '\r' or char == nil then
          goto skip
        elseif char == '\n' or spaceSeen then
          _nextCommandReady = onData(table.concat(data), _resultFunc)
          data = {}
          gtSeen = false
          spaceSeen = false
        else
          table.insert(data, char)
        end
      ::skip::
      end
    else
      timeoutCount = timeoutCount + timeoutReceive
      if timeoutCount >= timeoutMax then
        log.error(string.format("Timeout: '%s'", table.concat(_response, "\n")))
        timeoutCount = 0
        data = {}
        gtSeen = false
        spaceSeen = false
        _response = {}
        onUnsolicitedMsg()
        error("timeout")
      end
      onIdle()
    end
    ::shutdown::
  end
end

local function onData(payload, resultCallback)
  if #payload > 0 then
    table.insert(_response, payload)
  end
  
  if payload == "> " or string.find(payload, "OK") ~= nil or string.find(payload, "ERROR") ~= nil or string.find(payload, "NOT SUPPORT") ~= nil then
    if resultCallback then
      resultCallback(_response, _context)
    end
    _response = {}
    return true
  end
  
  if string.find(payload, "^RSSI") ~= nil or string.find(payload, "^LTERSRP") ~= nil then
    return onUnsolicitedMsg()
  end

  return false
end

local function dump(response) 
  log.debug(string.format("<- %s", table.concat(response, "\n")))
end

--local function onManufacturerInfo(response, context)
--  dump(response, context)
--end

local function onSetErrorCode(response, context)
  dump(response, context)
end

local function onSetNetworkRegistration(response, context)
  dump(response, context)
end

local function onSignalQuality(response, context)
  dump(response, context)
  -- RSSI (dBm) = (-113) + (2 * CSQ)
end

local function onNetworkRegistered(response, context)
  dump(response, context)
end

local function onSetSmsMsgFormat(response, context)
  dump(response, context)
end

local function onDevNull(response, context)
  local _, _ = context, response
end

local function onDeleteSmsMsg(response, context)
  dump(response, context)
end

local function deleteSmsMsg(commandTable, msgLocation)
  local cmd = string.format("at+cmgd=%s", msgLocation)
  table.insert(commandTable, {cmd, onDeleteSmsMsg, msgLocation})
end

local function onSmsMsgSend(response, context)
  for _, line in ipairs(response) do
    local marker, msgId = string.match(line, "(%g+) (%d+)")
    msgId = tonumber(msgId)
    if marker == "+CMSS:" and (msgId >= 0 and msgId <= 255) then
      log.trace(string.format("Message @ location %s sent (Msg Id: %s)", context[3], msgId))
      deleteSmsMsg(msgDeleteSentCommands, context[3])
      return
    end
  end
  log.error(string.format("Failed to send message @ location %s!", context[3]))
  dump(response)
end

local function queueUnsentSmsMsg(msgLocation)
  local cmd = string.format("at+cmss=%s", msgLocation)
  table.insert(msgSendCommands, {cmd, onSmsMsgSend, msgLocation})
end

local function onSmsMsgStoreLocation(response, context)
  dump(response, context)
  for _, line in ipairs(response) do
    local marker, location = string.match(line, "(%g+) (%d+)")
    if marker == "+CMGW:" then
      queueUnsentSmsMsg(tonumber(location))
      local msg = context
      table.remove(outMessages, msg.outMessagesIndex)
      return
    end
  end
end

--local function onSmsMsgStoreToMemory(response, context)
--  dump(response, context)
--  local msg = context[3]
--  local cmd = string.format("%s%s", msg.pdu, string.char(0x1A))
--  table.insert(msgStorePduCommands, {cmd, onSmsMsgStoreLocation, msg})
--end

local function queueMessage(phoneNumber, text)
  local pdu = smspdu.encodePdu(phoneNumber, text, "7bit")
  for _, pduPart in ipairs(pdu) do
    local msg = {}
    msg.pdu = pduPart.buffer
    table.insert(outMessages, msg)
    msg.outMessagesIndex = #outMessages
    local cmd = string.format("at+cmgw=%s\r", pduPart.size)
    table.insert(msgStorePduCommands, {cmd, onDevNull, msg})
    cmd = string.format("%s%s", msg.pdu, string.char(0x1A))
    table.insert(msgStorePduCommands, {cmd, onSmsMsgStoreLocation, msg})
  end
end

local function onSmsMsgRead(response, context)
  for index, line in ipairs(response) do
    if string.find(line, "ERROR:") and index == 1 then
      dump(response, context)
      return
    end
    
    local marker, storageIndex, msgStatus, _ = string.match(line, "(%g+) (%d+),(%d+),,(%d+)")
    if marker == "+CMGL:" then
      if msgStatus == "0" or msgStatus == "1" then
        local msg = {}
        if index+1 < #response then
          msg = smspdu.decodePdu(response[index+1])
        end
        msg.status = msgStatus
        table.insert(inMessages, msg)
        deleteSmsMsg(msgDeleteReceivedCommands, storageIndex)
      elseif msgStatus == "2" then
        queueUnsentSmsMsg(storageIndex)
      elseif msgStatus == "3" then
        deleteSmsMsg(msgDeleteSentCommands, storageIndex)
      end
    end
  end
end

local function onSetMsgStorage(response, context)
  dump(response, context)
  table.insert(msgReceiveCommands, {"at+cmgl=4", onSmsMsgRead, 0})
end

local function onPurgeAllSmsMsg(response, context)
  dump(response, context)
end

local function onPurgeSendStorage(response, context)
  local _, _ = response, context
  table.insert(msgSelectSendStorageCommands, {"at+cmgd=,4", onPurgeAllSmsMsg, 0})
end

local function onQueryMsgStorage(response, context)
  dump(response, context)
  for _, line in ipairs(response) do
    local marker, sendStore, rcvStore = string.match(line, "(%g+) %(\"(%a+)\",\"(%a+)\"%)")
    if marker == "+CPMS:" then
      local cmd = string.format("at+cpms=\"%s\"", rcvStore)
      table.insert(msgSelectReceiveStorageCommands, {cmd, onSetMsgStorage, 0})
      cmd = string.format("at+cpms=\"%s\"", sendStore)
      table.insert(msgSelectSendStorageCommands, {cmd, onPurgeSendStorage, 0})
      return
    end
  end
end

local function onSetCharacterSet(response, context)
  dump(response, context)
end

local initCommands = {
  {"at^curc=0", onDevNull, 0},
  {"ate0", onDevNull, 0},
--  {"ati", onManufacturerInfo, 0},
  {"at+cscs=\"IRA\"", onSetCharacterSet, 0},
  {"at+cmee=1", onSetErrorCode, 0},
  {"at+creg=2", onSetNetworkRegistration, 0},
  {"at+csq", onSignalQuality, 0},
  {"at+creg?", onNetworkRegistered, 0},
  {"at+cmgf=0", onSetSmsMsgFormat, 0},
  {"at+cpms=?", onQueryMsgStorage, 0}
}

local phaseName = {
  "Init",
  "Select Receive Storage",
  "Receive",
  "Delete Received",
  "Select Send Storage",
  "Store PDU",
  "Send",
  "Delete Sent",
  "Shutdown"
  }

local _phaseInit = 1
local _phaseSelectReceiveStorage = 2
local _phaseReceive = 3
local _phaseDeleteReceived = 4
local _phaseSelectSendStorage = 5
local _phaseStore = 6
local _phaseSend = 7
local _phaseDeleteSent = 8
local _phaseShutdown = 9
local _lastPhase = 0
local _phase = _phaseInit
local _commands = initCommands
local _cmdIndex = 1

local function displayPhase()
  if _phase ~= _lastPhase then
    _lastPhase = _phase
    log.debug(string.format("[Phase: %s]", phaseName[_phase]))
  end
end

local function reset()
  _lastPhase = 0
  _stopEventLoop = false
  _nextCommandReady = true
  _phase = _phaseInit
  _commands = initCommands
  _cmdIndex = 1

  msgSelectReceiveStorageCommands = {}
  msgReceiveCommands = {}
  msgDeleteReceivedCommands = {}
  msgSelectSendStorageCommands = {}
  msgStorePduCommands = {}
  msgSendCommands = {}
  msgDeleteSentCommands = {}
  inMessages = {}
end

local function onIdle()    
    if _cmdIndex > #_commands then
      _cmdIndex = 1
      _phase = _phase + 1
      if _phase > _phaseShutdown then
        _stopEventLoop = true
        _phase = _phaseInit
        _commands = initCommands
        return
      end
    end

  if _nextCommandReady then
    if _phase == _phaseInit then
      _commands = initCommands
    elseif _phase == _phaseSelectReceiveStorage then
      _commands = msgSelectReceiveStorageCommands
    elseif _phase == _phaseReceive then
      _commands = msgReceiveCommands
    elseif _phase == _phaseDeleteReceived then
      _commands = msgDeleteReceivedCommands
    elseif _phase == _phaseSelectSendStorage then
      _commands = msgSelectSendStorageCommands
    elseif _phase == _phaseStore then
      _commands = msgStorePduCommands
    elseif _phase == _phaseSend then
      _commands = msgSendCommands
    elseif _phase == _phaseDeleteSent then
      _commands = msgDeleteSentCommands
    elseif _phase == _phaseShutdown then
      _commands = shutdownCommands
    end
    
    displayPhase()
    
    local cmd = _commands[_cmdIndex]
    
    if cmd ~= nil then
      _resultFunc = cmd[2]
      _context = cmd
      send(cmd[1] .. "\r")
    end
    
    _cmdIndex = _cmdIndex + 1
  end
end

local _lastKnownGoodPort = 0

local function processMessages(port, portRangeMin, portRangeMax, baudRate)
  local portIndex = portRangeMin
  if _lastKnownGoodPort > 0 then
    portIndex = _lastKnownGoodPort
  end
  while portIndex <= portRangeMax do
    local portFinal = string.format("%s%s", port, portIndex)
    local result, reason = pcall(run, portFinal, baudRate, onData, onIdle)
    if not result and reason == "open" then
      portIndex = portIndex + 1
    elseif not result and reason == "timeout" then
      break
    else
      _lastKnownGoodPort = portIndex
      break
    end
  end
  shutdown()
  return inMessages
end

--[[
local sock = require("socket")

local function dumpMsg(msgList)
  log.debug("[Received Messages]")
  for _, msg in ipairs(msgList) do
    local strMsg = string.format("Status:%s, addr:%s, msg:%s", msg.status, msg.address, msg.message)
    log.debug(strMsg)
  end
end

local function main(port)
  while true do
    reset()
    queueMessage("+14255551212", "Testing testing testing...")
    queueMessage("+14255551212", "Foo, bar, baz...")
    queueMessage("+14255551212", "1234567890()-=!@#$%^&*")
    dumpMsg(processMessages(port, 0, 1, 115200))
    sock.sleep(5)
  end
end

main("/dev/ttyUSB")
--]]

local exports = {}
exports.reset = reset
exports.setTimeout = setTimeout
exports.queueMessage = queueMessage
exports.processMessages = processMessages
return exports
