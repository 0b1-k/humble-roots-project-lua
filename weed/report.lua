local states = {}

local function update(nodeName, valueName, value, stateName, state)
  local stateObj = states[nodeName]
  if stateObj == nil then
    stateObj = {}
  end
  if stateName ~= nil and state ~= nil then
    stateObj[valueName] = state
  else
    stateObj[valueName] = value
  end
  states[nodeName] = stateObj
end

local function getCount(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

local function report(cfg)
  local report = {}
  local empty = true
  for nodeName, stateObj in pairs(states) do
    table.insert(report, #report + 1, nodeName .. "(")
    local count = 0
    local sep = ","
    local items = getCount(stateObj)
    for k, v in pairs(stateObj) do
      count = count + 1
      if count == items then
        sep = ""
      end
      table.insert(report, #report + 1, string.format("%s:%s%s", k, v, sep))
      empty = false
    end
    table.insert(report, #report + 1, ")\n")
  end
  local rptMsg = table.concat(report, "")
  if empty then
    rptMsg = cfg.report.noData
  end
  return rptMsg
end

local export = {}
export.update = update
export.report = report
return export
