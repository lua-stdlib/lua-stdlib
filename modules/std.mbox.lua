-- mbox parser
-- based on code by Diego Nahab

mbox = {}

local function headers (header_s)
  local header = {}
  header_s = "\n" .. header_s .. "$$$:\n"
  local i, j = 1, 1
  while true do
    j = string.find (header_s, "\n%S-:", i + 1)
    if not j then
      break
    end
    local _, _, name, value = string.find (string.sub (header_s,
                                                       i + 1, j - 1),
                                           "(%S-):(.*)")
    value = string.gsub (value or "", "\r\n", "\n")
    value = string.gsub (value, "\n%s*", " ")
    name = string.lower (name)
    if header[name] then
      header[name] = header[name] .. ", " ..  value
    else
      header[name] = value
    end
    i, j = j, i
  end
  header["$$$"] = nil
  return header
end

local function message (message_s)
  message_s = string.gsub (message_s, "^.-\n", "")
  local _, header_s, body
  _, _, header_s, body = string.find(message_s, "^(.-\n)\n(.*)")
  return {header = headers (header_s or ""), body = body or ""}
end

function mbox.parse (mbox_s)
  local mbox = {}
  mbox_s = "\n" .. mbox_s .. "\nFrom "
  local i, j = 1, 1
  while true do
    j = string.find (mbox_s, "\nFrom ", i + 1)
    if not j then
      break
    end
    table.insert (mbox, message (string.sub (mbox_s, i + 1, j - 1)))
    i, j = j, i
  end
  return mbox
end
