--[[--
 Base implementations of functions exported by `std.list`.

 These functions are required by implementations of exported functions
 in other stdlib modules.  We keep them here to ensure argument checking
 error messages report the correct module ('std.list') after "%.base"
 has been stripped from `debug.getinfo (fn, "S").source`.

 @module std.base.list
]]


local function compare (l, m)
  for i = 1, math.min (#l, #m) do
    local li, mi = tonumber (l[i]), tonumber (m[i])
    if li == nil or mi == nil then
      li, mi = l[i], m[i]
    end
    if li < mi then
      return -1
    elseif li > mi then
      return 1
    end
  end
  if #l < #m then
    return -1
  elseif #l > #m then
    return 1
  end
  return 0
end


return {
  compare = compare,
}
