-- I/O

require "base-ext"


-- @func io.readLines: Read a file into a list of lines and close it
--   @param [h]: file handle or name [io.input ()]
-- @returns
--   @param l: list of lines
function io.readLines (h)
  if h == nil then
    h = io.input ()
  elseif type (h) == "string" then
    h = io.open (h)
  end
  local l = {}
  for line in h:lines () do
    table.insert (l, line)
  end
  h:close ()
  return l
end

-- @func io.writeLine: Write values adding a newline after each
--   @param [h]: file handle [io.output ()]
--   @param ...: values to write (as for write)
function io.writeLine (h, ...)
  if io.type (h) ~= "file" then
    table.insert (arg, 1, h)
    h = io.output ()
  end
  for _, v in ipairs (arg) do
    h:write (v, "\n")
  end
end

-- @func io.changeSuffix: Change the suffix of a filename
--   @param from: suffix to change (".-" for any suffix)
--   @param to: suffix to replace with
--   @param name: file name to change
-- @returns
--   @param name_: file name with new suffix
function io.changeSuffix (from, to, name)
  return string.gsub (name, "%." .. from .. "$", "") .. "." .. to
end

-- @func io.addSuffix: Add a suffix to a filename if not already present
--   @param suff: suffix to add
--   @param name: file name to change
-- @returns
--   @param name_: file name with new suffix
function io.addSuffix (suff, name)
  return io.changeSuffix (suff, suff, name)
end
