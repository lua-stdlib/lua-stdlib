-- Logic

require "std.data.global"


local n, b = 1, 0
while n < n + 1 do
  n = n * 2
  b = b + 1
end
_INTEGER_BITS = newConstant (b)


-- Don't overwrite bitlib routines if they exist
if band == nil then

  function band (a, b)
    local r = 0
    for i = 0, _INTEGER_BITS - 1 do
      local x, y = a / 2, b / 2
      a, b = floor (x), floor (y)
      if a ~= x and b ~= y then
        r = r + 2 ^ i
      end
    end
    return r
  end

  function bor (a, b)
    local r = 0
    for i = 0, _INTEGER_BITS - 1 do
      local x, y = a / 2, b / 2
      a, b = floor (x), floor (y)
      if a ~= x or b ~= y then
        r = r + 2 ^ i
      end
    end
    return r
  end

  function bxor (a, b)
    return a + b - 2 * band (a, b)
  end

  function bnot (a)
    return bxor (a, -1)
  end

end
