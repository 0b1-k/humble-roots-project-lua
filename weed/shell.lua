local utils = require("utils")
local opts = require("getopt_alt")

local function parse(line, options)
  local args = utils.splitString(line)
  local opts = opts.getOpt(args, options or "mnqrvsw")
  return opts
end

local export = {}
export.parse = parse
return export
