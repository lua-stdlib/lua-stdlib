-- File

require "std.assert"


-- lenFile: Find the length of a file
--   f: file name
-- returns
--   len: length of file
function lenFile (f)
  local h, len
  h = openfile (f, "rb")
  len = seek (h, "end")
  closefile (h)
  return len
end

-- existsFile: Finds whether a file exists
--   f: file name
-- returns
--   r: non-nil if f exists, nil otherwise
function existsFile (f)
  local h = openfile (f, "r")
  if h then
    closefile (h)
    return 1
  end
  return nil
end

-- readfrom: Guarded readfrom
--   [f]: file name
-- returns
--   h: handle
local _readfrom = readfrom
function readfrom (f)
  local h, err
  if f ~= nil then
    h, err = %_readfrom (f)
  else
    h, err = %_readfrom ()
  end
  assert (h, "can't read from %s: %s", f or "stdin", err or "")
  return h
end

-- writeto: Guarded writeto
--   [f]: file name
-- returns
--   h: handle
local _writeto = writeto
function writeto (f)
  local h, err
  if f ~= nil then
    h, err = %_writeto (f)
  else
    h, err = %_writeto ()
  end
  assert (h, "can't write to %s: %s", f or "stdout", err or "")
  return h
end

-- dofile: Guarded dofile
--   f: file name
-- returns
--   r: result of dofile
local _dofile = dofile
function dofile (f)
  local r = %_dofile (f)
  assert (r, "error while executing %s", f)
  return r
end

-- seek: Guarded seek
--   f: file handle
--   w: whence to seek
--   o: offset
local _seek = seek
function seek (f, w, o)
  local ok, err
  if o ~= nil then
    ok, err = %_seek (f, w, o)
  elseif w ~= nil then
    ok, err = %_seek (f, w)
  else
    ok, err = %_seek (f)
  end
  assert (ok, "can't seek on %s: %s", tostring (f), err or "")
  return ok
end
