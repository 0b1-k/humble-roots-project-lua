local csv = require("csv")
local db = require("influxdb")
local config = require("config")

local cfgFilePath = "./config/config.json"
local cfg = config.getConfig(cfgFilePath)

local function readCsvFile(filename, onCsvLine)
  local f, err = io.open(filename, "r")
  if err then
    print(string.format("Failed to open %s, error: %s", filename, err))
    return
  end
  local lineNumber = 0
  while true do
    local line = f:read()
    if line == nil then break end
    lineNumber = lineNumber + 1
    local data = csv.parse(line)
    if onCsvLine ~= nil then
      onCsvLine(lineNumber, data)
    end
  end
  f:close()
  return lineNumber
end

local function toOsTime(date, time)
  if date == nil or time == nil or type(date) ~= "string" or type(time) ~= "string" then return nil end
  local _month, _day, _year = string.match(date, "(%d+)/(%d+)/(%d+)")
  local _hour, _min, _sec = string.match(time, "(%d+):(%d+):(%d+)")
  if _month ~= nil and _day ~= nil and _year ~= nil and _hour ~= nil and _min ~= nil and _sec ~= nil then
    return os.time({year = 2000 + tonumber(_year), month = _month, day = _day, hour = _hour, min = _min, sec = _sec})
  end
  return nil
end

local function onData(lineNumber, data)
  if lineNumber > 1 then
    local ts = toOsTime(data[1], data[2])
    if ts ~= nil then
      db.pushEvent("event", "LOG", "recipe", data[3], ts)
    end
  end
end

local function main(csvFile)
  if csvFile == nil then
    error("Usage: csv2log.lua <path to .csv file>")
  end
  if cfg.influxDB.enabled then
    db.setPrecision("s")
    local linesRead = readCsvFile(csvFile, onData)
    if linesRead > 1 then
      local result = db.post(cfg.influxDB.host, cfg.influxDB.port, cfg.influxDB.events)
      if result then
        print(string.format("Wrote %s lines to InfluxDB", tostring(linesRead)))
      else
        print("Failed to write data to InfluxDB. See error for details.")
      end
    else
      print("No data was written to InfluxDB. Check that %s is a valid .csv file", tostring(linesRead), csvFile)
    end
  else
    error(string.format("Cannot write %s to db because InfluxDB is not enabled in %s", csvFile, cfgFilePath))
  end
end

main(arg[1])
