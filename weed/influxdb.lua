local http = require("socket.http")
local socket = require("socket")
local ltn12 = require("ltn12")

local body = {}
local sock = {}
local precision = ""

local function setPrecision(p)
  if p == nil then
    precision = ""
    return
  end
  local start, stop = string.find("n,u,ms,s,m,h", p)
  if start ~= nil and stop ~= nil then
    precision = p
  else
    error(string.format("Invalid time precision: %s", p))
  end
end

local function initialize()
  local err = ""
  sock, err = socket.udp()
  if sock == nil then
    error(string.format("Failed to create UDP socket, error: %s", err))
  end
end

local function shutdown()
  sock:close()
  sock = {}
end

local function getServerUrl(address, port, db)
  if #precision > 0 then
    return string.format("http://%s:%s/write?db=%s&precision=%s", address, port, db, precision)
  else
    return string.format("http://%s:%s/write?db=%s", address, port, db)
  end
end

local function appendTimeStamp(timestamp)
  if timestamp ~= nil then
    return string.format(" %s", timestamp)
  else
    return ""
  end
end

local function push(data, valueId, timestamp)
  if valueId == nil then
    return
  end
  local scratch = {}
  local valueData = 0
  for n, v in pairs(data) do
      if n ~= valueId then
          table.insert(scratch, string.format("%s=%s", n, v))
      else
          valueData = tostring(v)
      end
  end
  local line = string.format("%s,%s value=%s%s", valueId, table.concat(scratch, ","), valueData, appendTimeStamp(timestamp))
  table.insert(body, line)
end

local function pushSingleValue(measurement, tag, value, timestamp)
  local line = string.format("%s,tag=%s value=%s%s", measurement, tag, value, appendTimeStamp(timestamp))
  table.insert(body, line)
end

local function pushEvent(measurement, level, tag, text, timestamp)
  local line = string.format("%s,level=%s,tag=%s level=\"%s\",text=\"%s\"%s", measurement, level, tag, level, text, appendTimeStamp(timestamp))
  table.insert(body, line)
end

local function getMessageBody()
    local msg = table.concat(body, "\n")
    body = {}
    return msg
end

-- https://github.com/influxdata/influxdb/blob/master/services/udp/README.md
-- See the config snippet in ./config/influxdb-udp.conf to update the [[udp]] section of /etc/influxdb/influxdb.conf
local function postUDP(address, port)
  local reqbody = getMessageBody()
  local result, err = sock:setpeername(address or "127.0.0.1", port or 8089)
  if result == nil then
    print(string.format("Failed to set UDP socket peer name, error: %s", err))
  end
  result, err = sock:send(reqbody)
  if result == nil then
    print(string.format("UDP socket error: %s, msg: %s, len: %s", err, reqbody, #reqbody))
  end
end

local function post(address, port, db)
    local reqbody = getMessageBody()
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
        local json = require("dkjson")
        local errorInfo, _, err = json.decode(respbody[1], 1, nil)
        print(string.format("InfluxDB response %s, error: %s", respstatus, errorInfo.error))
      else
        return true
      end
    else
      print("InfluxDB write failure!")
    end
    return false
end

local export = {}
export.push = push
export.pushSingleValue = pushSingleValue
export.pushEvent = pushEvent
export.post = post
export.postUDP = postUDP
export.initialize = initialize
export.shutdown = shutdown
export.setPrecision = setPrecision
return export
