-- Lua time library


-- daySuffix: return the English suffix for a date
--   n: number of the day
-- returns
--   s: suffix
function daySuffix (n)
  local d = imod (n, 10)
  if d == 1 and n ~= 11 then
    return "st"
  elseif d == 2 and n ~= 12 then
    return "nd"
  elseif d == 3 and n ~= 13 then
    return "rd"
  else
    return "th"
  end
end
