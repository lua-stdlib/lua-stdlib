-- File

require "std.base"


-- @func io.length: Find the length of a file
--   @param f: file name
-- @returns
--   @param len: length of file
function io.length (f)
  local h, len
  h = io.open (f, "rb")
  len = h:seek ("end")
  if len == nil then
    die ("couldn't find length of file")
  end
  h:close ()
  return len
end

-- @func io.exists: Finds whether a file exists
--   @param f: file name
-- @returns
--   @param r: non-nil if f exists, nil otherwise
function io.exists (f)
  local h = io.open (f, "r")
  if h then
    h:close ()
  end
  return h ~= nil
end
