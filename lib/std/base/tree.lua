--[[--
 Base implementations of functions exported by `std.tree`.

 These functions are required by implementations of exported functions
 in other stdlib modules.  We keep them here to avoid bloating std.base,
 which is loaded by *every* stdlib module.

 @module std.base.tree
]]


local function leaves (it, tr)
  local function visit (n)
    if type (n) == "table" then
      for _, v in it (n) do
        visit (v)
      end
    else
      coroutine.yield (n)
    end
  end
  return coroutine.wrap (visit), tr
end


return {
  leaves = leaves,
}
