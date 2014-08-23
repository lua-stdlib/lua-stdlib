--[[--
 Base implementations of functions exported by `std.string`.

 These functions are required by implementations of exported functions
 in other stdlib modules.  We keep them here to ensure argument checking
 error messages report the correct module ('std.string') after "%.base"
 has been stripped from `debug.getinfo (fn, "S").short_src`.

 @module std.base.string
]]


--- Make a shallow copy of a table.
-- @tparam table t source table
-- @treturn table shallow copy of *t*
local function copy (t)
  local new = {}
  for k, v in pairs (t) do new[k] = v end
  return new
end



local function render (x, open, close, elem, pair, sep, roots)
  local function stop_roots (x)
    return roots[x] or render (x, open, close, elem, pair, sep, copy (roots))
  end
  roots = roots or {}
  if type (x) ~= "table" or type ((getmetatable (x) or {}).__tostring) == "function" then
    return elem (x)
  else
    local s = {}
    s[#s + 1] =  open (x)
    roots[x] = elem (x)

    -- create a sorted list of keys
    local ord = {}
    for k, _ in pairs (x) do ord[#ord + 1] = k end
    table.sort (ord, function (a, b) return tostring (a) < tostring (b) end)

    -- render x elements in order
    local i, v = nil, nil
    for _, j in ipairs (ord) do
      local w = x[j]
      s[#s + 1] = sep (x, i, v, j, w) .. pair (x, j, w, stop_roots (j), stop_roots (w))
      i, v = j, w
    end
    s[#s + 1] = sep (x, i, v, nil, nil) .. close (x)
    return table.concat (s)
  end
end


local function split (s, sep)
  sep = sep or "%s+"
  local b, len, t, patt = 0, #s, {}, "(.-)" .. sep
  if sep == "" then patt = "(.)"; t[#t + 1] = "" end
  while b <= len do
    local e, n, m = string.find (s, patt, b + 1)
    t[#t + 1] = m or s:sub (b + 1, len)
    b = n or len + 1
  end
  return t
end


return {
  copy   = copy,
  render = render,
  split  = split,
}
