local csv = require("csv")
local log = require("log")

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
end

local function toOsTime(date, time)
  if date == nil or time == nil or type(date) ~= "string" or type(time) ~= "string" then return nil end
  local _month, _day, _year = string.match(date, "(%d+)/(%d+)/(%d+)")
  local _hour, _min, _sec = string.match(time, "(%d+):(%d+):(%d+)")
  if _month ~= nil and _day ~= nil and _year ~= nil and _hour ~= nil and _min ~= nil and _sec ~= nil then
    return os.time({year = _year, month = _month, day = _day, hour = _hour, min = _min, sec = _sec})
  end
  return nil
end

local function onData(lineNumber, data)
  if lineNumber > 1 then
    local ts = toOsTime(data[1], data[2])
    if ts ~= nil then
      print(string.format("%s: %s", tostring(ts), data[3]))
    end
  end
end

readCsvFile("./recipe/ak48.csv", onData)
