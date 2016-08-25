local function get(filename)
  local file = io.open(filename, "r")
  local logo = file:read("*all")
  file:close()
  return logo
end

export = {}
export.get = get
return export
