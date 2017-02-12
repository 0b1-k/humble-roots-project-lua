local lfs = require("lfs")

local function getFileChangeInfoObj(path)
  local attr = lfs.attributes(path)
  if attr == nil then
    print(string.format("Config file %s not found!", path))
  end
  local t = {
    ["lastModTime"] = attr.modification,
    ["path"] = path
  }
  return t
end

local function isFileChanged(fileChangeInfo)
  local temp = getFileChangeInfoObj(fileChangeInfo.path)
  if temp.lastModTime ~= fileChangeInfo.lastModTime then
    fileChangeInfo.lastModTime = temp.lastModTime
    return true
  end
  return false
end

local cfgFileInfo = nil

local function getConfig(path)
  cfgFileInfo = getFileChangeInfoObj(path)
  local cfgFile = io.open(path, "r")
  local rawJson = cfgFile:read("*a")
  cfgFile:close()
  local json = require("dkjson")
  local cfg, _, err = json.decode(rawJson, 1, nil)
  rawJson = nil
  json = nil
  collectgarbage()
  if err then
    error(string.format("Invalid JSON: %s", err))
    os.exit()
  end
  return cfg
end

local function getNextTime()
  return os.time() + 5
end

local nextTime = getNextTime()

local function isChanged()
  if os.time() < nextTime then
    return false
  end
  local result = isFileChanged(cfgFileInfo)
  nextTime = getNextTime()
  return result
end

local export = {}
export.getConfig = getConfig
export.isChanged = isChanged
return export
