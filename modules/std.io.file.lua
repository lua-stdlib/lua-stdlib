-- File

require "std.assert"


-- lenFile: Find the length of a file
--   f: file name
-- returns
--   len: length of file
function lenFile (f)
  local h, len
  h = io.open (f, "rb")
  len = h:seek ("end")
  if len == nil then
    die ("couldn't find length of file")
  end
  h:close ()
  return len
end

-- existsFile: Finds whether a file exists
--   f: file name
-- returns
--   r: non-nil if f exists, nil otherwise
function existsFile (f)
  local h = io.open (f, "r")
  if h then
    h:close ()
    return 1
  end
  return nil
end
