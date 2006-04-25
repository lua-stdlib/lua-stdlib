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

-- @func io.exists: Finds whether a file exists
--   @param f: file name
-- @returns
--   @param r: non-nil if f exists, nil otherwise
function io.exists (f)
  if posix then
    return posix.stat (f) ~= nil
  else
    local h = io.open (f)
    if h then
      h:close ()
    end
    return h ~= nil
  end
end

-- @func io.dirname: POSIX dirname
--   @param p: path
-- @returns
--   @param q: path with trailing /component removed, or . if none
function io.dirname (p)
  if not (string.find (p, "/")) then
    return "."
  else
    local q = string.gsub (p, "/[^/]*/?$", "")
    if q == "" then
      q = "/"
    end
    return q
  end
end

-- @func readDir: Make a list of a directory's contents
--   @param d: directory
-- @returns
--   @param l: list of files
-- TODO: rewrite to be POSIX
function io.readDir (d)
  local l = string.split ("\n",
                          string.chomp (shell ("ls -aU " .. d ..
                                               " 2>/dev/null")))
  table.remove (l, 1) -- remove . and ..
  table.remove (l, 1)
  return l
end
