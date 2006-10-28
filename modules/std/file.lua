-- File

module ("std.file", package.seeall)


-- @func io.length: Find the length of a file
--   @param f: file name
-- @returns
--   @param len: length of file, or nil on error
function io.length (f)
  local h, len
  h = io.open (f, "rb")
  if h then
    len = h:seek ("end")
    h:close ()
  end
  return len
end
