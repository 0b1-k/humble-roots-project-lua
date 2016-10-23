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

local exports = {}
exports.splitString = splitString
return exports
