local sms = require("sms")
local log = _ENV.log

local nodes = {}
local cfg = {}

local function initialize(config)
  nodes = {}
  cfg = config
  for k, _ in pairs(cfg.node) do
    local isNodeId = tonumber(k)
    if isNodeId == nil then -- got a node name
      local timeoutObj = {}
      timeoutObj.nodeTimeout = cfg.control.nodeTimeout.freqSec
      timeoutObj.rebootTimeout = cfg.control.nodeTimeout.rebootAfter
      nodes[k] = timeoutObj
    end
  end
end

local function elapseTime(seconds)
  for node, _ in pairs(nodes) do
    local timeoutObj = nodes[node]
    if timeoutObj.nodeTimeout > 0 then
      timeoutObj.nodeTimeout = timeoutObj.nodeTimeout - seconds
      if timeoutObj.nodeTimeout <= 0 then
        timeoutObj.rebootTimeout = (cfg.control.nodeTimeout.rebootAfter - cfg.control.nodeTimeout.freqSec)
        local alertMsg = string.format("%s: %s @ %s", cfg.control.nodeTimeout.title, node, os.date("%c", os.time()))
        sms.send(cfg, alertMsg)
        log.warn(alertMsg)
      end
    else
      if timeoutObj.rebootTimeout <= 0 then
        local alertMsg = string.format("%s @ %s", cfg.control.nodeTimeout.rebootMsg, os.date("%c", os.time()))
        sms.send(cfg, alertMsg)
        log.fatal(alertMsg)
        os.execute("reboot")
      else
        timeoutObj.rebootTimeout = timeoutObj.rebootTimeout - seconds
      end
    end
    nodes[node] = timeoutObj
  end
end

local function pulse(node)
  local timeoutObj = nodes[node]
  if timeoutObj ~= nil then
    if timeoutObj.nodeTimeout <= 0 then
      local alertMsg = string.format("%s cleared: %s @ %s", cfg.control.nodeTimeout.title, node, os.date("%c", os.time()))
      sms.send(cfg, alertMsg)
      log.info(alertMsg)
    end
    timeoutObj.nodeTimeout = cfg.control.nodeTimeout.freqSec
    timeoutObj.rebootTimeout = cfg.control.nodeTimeout.rebootAfter
    nodes[node] = timeoutObj
  end
end

local export = {}
export.initialize = initialize
export.elapseTime = elapseTime
export.pulse = pulse
return export
