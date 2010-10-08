-- POSIX

module ("posix", package.seeall)


-- @func system
--   @param file: filename of program to run
--   @param ...: arguments to the program
-- @returns
--   @param status: exit code, or nil if fork or wait fails
--   [@param reason]: error message, or exit type if wait succeeds
function system (file, ...)
  local pid = posix.fork ()
  if pid == 0 then
    return posix.execp (file, ...)
  else
    local pid, reason, status = posix.wait (pid)
    return status, reason -- If wait failed, status is nil & reason is error
  end
end
