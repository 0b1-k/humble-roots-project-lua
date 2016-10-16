local md5 = require("md5")
local sms = require("sms")
local log = _ENV.log

local alerts = {}

local function getAlertObj()
  local now = os.time()
  local obj = {
    ["created"] = now,
    ["modified"] = now
  }
  return obj
end

--https://stackoverflow.com/questions/1426954/split-string-in-lua
local function splitString(input, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  local i = 1
  for str in string.gmatch(input, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end

local function decode(data)
  local andTable = splitString(data, '&')
  local t = {}
  for i = 1, #andTable, 1 do
    local kvPair = andTable[i]
    local values = splitString(kvPair, '=')
    if #values == 2 then
      t[values[1]] = values[2]
    end
  end
  return t
end

local function isTimeWithinRange(timeNow, fromTime, toTime)
  if fromTime > toTime then
    if timeNow >= fromTime or timeNow <= toTime then
      return true
    end
  elseif fromTime < toTime then
    if timeNow >= fromTime and timeNow <= toTime then
      return true
    end
  elseif fromTime == toTime then
    if timeNow == fromTime then
      return true
    end
  end
  return false
end

local function evalCondition(value, condition)
  if condition.from ~= nil and condition.to ~= nil then
    local from = splitString(condition.from, ':')
    local to = splitString(condition.to, ':')
    local date = os.date("*t", os.time())
    local fromTime = os.date("*t", os.time())
    local toTime = os.date("*t", os.time())
    fromTime.hour = tonumber(from[1])
    fromTime.min = tonumber(from[2])
    fromTime.sec = 0
    toTime.hour = tonumber(to[1])
    toTime.min = tonumber(to[2])
    toTime.sec = 0
    return isTimeWithinRange(os.time(date), os.time(fromTime), os.time(toTime))
  elseif condition.op ~= nil and condition.setpoint ~= nil then
    local setPoint = tonumber(condition.setpoint)
    if condition.op == "==" and value == setPoint then
      return true
    elseif condition.op == ">=" and value >= setPoint then
      return true
    elseif condition.op == "<=" and value <= setPoint then
      return true
    elseif condition.op == ">" and value > setPoint then
      return true
    elseif condition.op == "<" and value < setPoint then
      return true
    elseif condition.op == "!=" and value ~= setPoint then
      return true
    end
  elseif condition.op == nil and condition.cmd ~= nil then
    return true
  else
    return false
  end
end

local function resolve(cmdTable, cfg)
  local resolved = {}
  for key, value in pairs(cmdTable) do
    local cfgItem = cfg[key]
    if cfgItem ~= nil then
      resolved[key] = cfgItem[value]
    else
      resolved[key] = value
    end
  end
  return resolved
end

local function encode(cmdTable)
  local node = {}
  local other = {}
  for key, value in pairs(cmdTable) do
    if key == "node" then
      table.insert(node, string.format("%s=%s", key, value))
    else
      table.insert(other, string.format("%s=%s", key, value))
    end
  end
  table.sort(node)
  table.sort(other)
  return string.format("%s&%s", table.concat(node, "&"), table.concat(other, "&"))
end

local function composeAlert(value, rule, nodeName, clear)
  local clearMark = "|CLEARED|"
  if clear == nil or not clear then
    clearMark = "|RAISED|"
  end
  local msg = string.format(
    "[%s] %s %s %s %s %s @ %s",
    nodeName,
    rule.alert.title,
    clearMark,
    tostring(value),
    rule.alert.op,
    tostring(rule.alert.setpoint),
    os.date("%c", os.time())
  )
  return msg
end

local function getRuleHash(rule, nodeName)
  return md5.sum(string.format("%s%s", nodeName, tostring(rule)))
end

local function sendAlert(cfg, value, rule, nodeName)
  local hash = getRuleHash(rule, nodeName)
  if alerts[hash] == nil then
    alerts[hash] = getAlertObj()
    local alertMsg = composeAlert(value, rule, nodeName)
    sms.send(cfg, alertMsg)
    log.warn(alertMsg)
  else
    local obj = alerts[hash]
    obj.modified = os.time()
  end
end

local function clearAlert(cfg, value, rule, nodeName)
  local hash = getRuleHash(rule, nodeName)
  if alerts[hash] ~= nil then
    alerts[hash] = nil
    local alertMsg = composeAlert(value, rule, nodeName, true)
    sms.send(cfg, alertMsg)
    log.info(alertMsg)
  end
end

local function sendCommand(cmd, gateway, cfg)
  local cmdDecoded = decode(cmd)
  local cmdTable = resolve(cmdDecoded, cfg)
  local cmdFinal = encode(cmdTable)
  gateway.send(cmdFinal, nil)
end

local function eval(rule, msg, gateway, cfg)
  if not rule.enabled then
    return
  end
  
  local value = tonumber(msg[rule.value])
  if value == nil then
    return
  end
  
  local nodeName = cfg.node[msg.node]
  
  if nodeName ~= rule.node then
    return
  end

  if rule.alert ~= nil and rule.node ~= nil and msg.node ~= nil and nodeName == rule.node then
    if evalCondition(value, rule.alert, msg) then
      sendAlert(cfg, value, rule, nodeName)
    else
      clearAlert(cfg, value, rule, nodeName)
    end
  end

  if rule.time ~= nil and rule.off ~= nil and not evalCondition(value, rule.time, msg) then
    sendCommand(rule.off.cmd, gateway, cfg)
    return
  end
  
  if rule.on ~= nil and evalCondition(value, rule.on, msg) then
    sendCommand(rule.on.cmd, gateway, cfg)
  elseif rule.off ~= nil and evalCondition(value, rule.off, msg) == true then
    sendCommand(rule.off.cmd, gateway, cfg)
  end
end

local export = {}
export.eval = eval
export.decode = decode
export.encode = encode
export.resolve = resolve
return export
