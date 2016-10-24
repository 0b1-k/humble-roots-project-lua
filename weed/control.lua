local log = require("log")
_ENV.log = log

local gateway = require("gateway")
local config = require("config")
local db = require("influxdb")
local rules = require("rules")
local replay = require("replay")
local heartbeat = require("heartbeat")
local sms = require("sms")
local report = require("report")
local listen = require("listener")
local shell = require("shell")
local logo = require("logo")

local listening = false
local manualMode = false

local cfgFilePath = "./config/config.json"
local cfg = config.getConfig(cfgFilePath)

local function writeMsgToDB(msgResolved, valueId)
  if cfg.influxDB.enabled then
    if cfg.fixup[valueId] ~= nil then
      local values = cfg.fixup[valueId]
      local fixedValue = values[msgResolved[valueId]]
      msgResolved[valueId] = fixedValue
    end
    db.push(msgResolved, valueId)
    db.post(cfg.influxDB.host, cfg.influxDB.port, cfg.influxDB.db)
  end
end

local function writeSingleValueToDB(measurement, tag, value)
  if cfg.influxDB.enabled then
    db.pushSingleValue(measurement, tag, value)
    db.post(cfg.influxDB.host, cfg.influxDB.port, cfg.influxDB.db)
  end
end

local function onData(data)
  log.trace(string.format("rx: %s", data))
  
  if not cfg.serial.enabled and not cfg.replay.enabled then
    log.debug(string.format("Ignoring: %s", data))
    return
  end
  if not listening and data == "Listening" then
    log.info(data)
    listening = true
    return
  end
  
  if cfg.replay.record then
    replay.record(data)
  end
  local msg = rules.decode(data)
  local msgResolved = rules.resolve(msg, cfg)
  if msg.node ~= nil and msg.tx == nil and msg.t ~= nil then
    -- sensor data was received...
    log.info(string.format("Sensor: %s", data))
    heartbeat.pulse(msgResolved.node)
    local devRules = cfg.control[msg.t]
    if devRules ~= nil then
      log.trace(string.format("Rule type: %s", msg.t))
      local commandSent = false
      local defaultCommand = devRules["default"]
      for _, rule in pairs(devRules) do
        if not manualMode then
          if defaultCommand ~= nil then
            rule.defaultCmd = defaultCommand.cmd
          end
          if rules.eval(rule, msg, gateway, cfg) then
            commandSent = true
          end
        end
        
        local value = tonumber(msg[rule.value])
        local _ = tonumber(msg[rule.state])
        local nodeName = cfg.node[msg.node]
        
        if nodeName ~= nil and value ~= nil then
          if rule.state ~= nil then
            writeMsgToDB(msgResolved, rule.state)
            report.update(nodeName, rule.value, msgResolved[rule.value], rule.state, msgResolved[rule.state])
          else
            writeMsgToDB(msgResolved, rule.value)
            report.update(nodeName, rule.value, value)
          end
        end    
      end
      if not commandSent and defaultCommand ~= nil then
        log.trace(string.format("Default Cmd: %s", defaultCommand.cmd))
        rules.sendCommand(defaultCommand.cmd, gateway, cfg)
      end
    end
    if cfg.control.signal ~= nil then
      log.trace("Rule type: signal")
      for _, rule in pairs(cfg.control.signal) do
        if not manualMode then
          rules.eval(rule, msg, gateway, cfg)
        end
        writeMsgToDB(msgResolved, rule.value)
      end
    end
  elseif msg.node ~= nil and msg.tx ~= nil and msg.t == nil then
    -- a command ack/nak was received...
    gateway.retry(msg)
    writeSingleValueToDB("tx", msgResolved.node, msgResolved.tx)
  else
    log.warn(string.format("Discarded: %s", data))
  end
end

local function onShellMsg(line)
  line = string.lower(line)
  log.info(string.format("Shell: %s", line))
  if line == "reset" then
    return nil
  end
  local opts = shell.parse(line)
  if opts.q ~= nil and opts.q == "report" then
    return report.report(cfg)
  end
  if opts.m ~= nil then
    if opts.m == "manual" then
      manualMode = true
    else
      manualMode = false
    end
    log.info(string.format("Switched to '%s' mode", opts.m))
  else
    local cmdFinal = rules.sendCommand(line, gateway, cfg)
    if cmdFinal ~= nil then
      log.info(string.format("Sent shell command: %s", cmdFinal))
    else
      local err = string.format("Invalid shell command: %s", line)
      log.error(err)
      return err
    end
  end
  return "ok"
end

local function onSmsMsg(from, body)
  local _ = from
  local reply = onShellMsg(body)
  if reply ~= nil then
    sms.send(cfg, reply)
  end
end

local function getNextTime()
  return os.time() + cfg.control.tick.freqSec
end

local nextTime = getNextTime()

local function onIdle()
  if config.isChanged() then
    cfg = config.getConfig(cfgFilePath)
    gateway.stop()
    return
  end
  sms.receive(cfg, onSmsMsg)
  if cfg.shell.enabled then
    listen.receive(onShellMsg)
  end
  if os.time() >= nextTime then
    log.info(string.format("Tick: %s", tostring(cfg.control.tick.freqSec)))
    if listening and cfg.control.timers ~= nil then
      if not manualMode then
        heartbeat.elapseTime(cfg.control.tick.freqSec)
      end
      for _, rule in pairs(cfg.control.timers) do
        if not manualMode then
          rules.eval(rule, {ts=os.time()}, gateway, cfg)
        end
      end
    end
    nextTime = getNextTime()
  elseif listening and cfg.replay.enabled then
    local data = replay.getNext()
    if data ~= nil then
      log.debug(string.format("Replay %s", data))
      onData(data)
    end
  end
end

log.info("The Humble Roots Project")
log.info(logo.get("./ascii_lf.drg"))
log.info("Copyright (c) 2016 Fabien Royer")

while true do
  listening = false
  _ENV.log.level = cfg.log.level
  if cfg.log.file ~= nil then
    _ENV.log.outfile = cfg.log.file
  end
  log.info("Gateway started")
  heartbeat.initialize(cfg)
  listen.initialize(cfg.shell.bind, cfg.shell.port)
  if cfg.replay.record then
    replay.setRecordDuration(cfg.replay.recordDuration)
  end
  if cfg.serial.enabled then
    local result, errorDetails = pcall(gateway.run, cfg.serial.port, cfg.serial.baudrate, onData, onIdle)
    if not result then
      log.fatal(errorDetails)
      _ENV.io.Serial.del_us(1000000)
    end
  else
    listening = true
    while not gateway.isStopped() do
      onIdle()
      _ENV.io.Serial.del_us(10)
    end
  end
  
  listen.shutdown()
  log.info("Gateway stopped")
end
