local modem = require("modem")
local log = _ENV.log

local messageQueue = {}

local function send(cfg, text)
  if not cfg.sms.enabled then
    return
  end
  local msg = {}
  msg.phoneNumber = cfg.sms.dest
  msg.text = text
  table.insert(messageQueue, msg)
  log.warn(string.format("[SMS QUEUED]\nTo:%s, %s", cfg.sms.dest, text))
end

local function getNextTime()
  return os.time() + 5
end

local nextTime = getNextTime()

local function receive(cfg, onSmsMsg)
  if not cfg.sms.enabled or os.time() < nextTime then
    return
  end
  
  modem.reset()
  
  for _, msg in ipairs(messageQueue) do
    modem.queueMessage(msg.phoneNumber, msg.text)
  end
  
  messageQueue = {}
  
  log.trace("Running...")
  
  local msgList = modem.processMessages(cfg.sms.port, cfg.sms.port_range_min, cfg.sms.port_range_max, cfg.sms.baudrate)
  
  for _, msg in ipairs(msgList) do
    if msg.address == cfg.sms.accept then
      log.warn(string.format("[SMS IN] status:%s, from:%s, msg:%s", msg.status, msg.address, msg.message))
      onSmsMsg(msg.address, msg.message)
    else
      log.error(string.format("[SMS REJECT] status:%s, from:%s, msg:%s", msg.status, msg.address, msg.message))
    end
  end
  
  log.trace("Done!")
  
  nextTime = getNextTime()
end

local export = {}
export.send = send
export.receive = receive
return export
