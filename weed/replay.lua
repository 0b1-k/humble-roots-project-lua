local log = _ENV.log

local function load(path)
  local data = {}
  local file = io.open(path, "r")
  if file ~= nil then
    for line in file.lines(file) do
      if string.find(line, "&rssi=") ~= nil then
        table.insert(data, line)
      end
    end
    file:close()
  end
  log.trace(string.format("Replay data lines: %s", tostring(#data)))
  return data, 1
end

local replayDataPath = "./replay.txt"
local replayData, replayDataIndex = load(replayDataPath)
local nextReplayDataTime = os.time() + 1

local function getNext()
  if os.time() >= nextReplayDataTime then
    local data = replayData[replayDataIndex]
    replayDataIndex = replayDataIndex + 1
    if replayDataIndex > #replayData then
      replayDataIndex = 1
    end
    nextReplayDataTime = os.time() + 1
    return data
  else
    return nil
  end
end

local stopRecordTime = os.time()

local function setRecordDuration(seconds)
  stopRecordTime = os.time() + seconds
end

local function record(line)
  if os.time() <= stopRecordTime then
    local file = io.open(replayDataPath, "a")
    file:write(line .. "\n")
    file:close()
  end
end

local export = {}
export.getNext = getNext
export.setRecordDuration = setRecordDuration
export.record = record
return export
