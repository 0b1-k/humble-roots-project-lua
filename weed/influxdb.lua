local http = require("socket.http")
local ltn12 = require("ltn12")
local log = _ENV.log

local function getServerUrl(address, port, db)
    return string.format("http://%s:%s/write?db=%s", address, tostring(port), db)
end

local body = {}

local function push(data, valueId)
  if valueId == nil then
    return
  end
  local scratch = {}
  local valueData = 0
  for n, v in pairs(data) do
      if n ~= valueId then
          table.insert(scratch, string.format("%s=%s", tostring(n), tostring(v)))
      else
          valueData = tostring(v)
      end
  end
  local line = string.format("%s,%s value=%s\n", valueId, table.concat(scratch, ","), tostring(valueData))
  table.insert(body, line)
end

local function pushSingleValue(measurement, tag, value)
  local line = string.format("%s,tag=%s value=%s\n", measurement, tag, tostring(value))
  table.insert(body, line)
end

local function pushEvent(measurement, level, tag, text)
  local line = string.format("%s,level=%s,tag=%s level=\"%s\",text=\"%s\"\n", measurement, level, tag, level, tostring(text))
  table.insert(body, line)
end

local function post(address, port, db)
    local reqbody = table.concat(body, "\n")
    body = {}
    local respbody = {}
    local result, respcode, _, respstatus = http.request {
        method = "POST",
        url = getServerUrl(address, port, db),
        source = ltn12.source.string(reqbody),
        headers = {
            ["content-type"] = "text/plain",
            ["content-length"] = tostring(#reqbody)
        },
        sink = ltn12.sink.table(respbody)
    }
    if result ~= nil and result == 1 then
      if respcode ~= 200 and respcode ~= 204 then
        print(string.format("InfluxDB response %s", respstatus))
      end
    else
      print("InfluxDB write failure!")
    end
    return respbody
end

local export = {}
export.push = push
export.pushSingleValue = pushSingleValue
export.pushEvent = pushEvent
export.post = post
return export
