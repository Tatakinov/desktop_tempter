local utf8  = require("lua-utf8")
local StringBuffer  = require("string_buffer")

local M = {}

local width   = 9
local height  = 18

local function wmax(t)
  local max = 0
  for _, v in ipairs(t) do
    local w = 0
    if type(v) == "table" then
      w = utf8.width(v.raw)
    else
      w = utf8.width(tostring(v))
    end
    if max < w then
      max = w
    end
  end
  return max * width
end

local function hmax(t)
  return #t * height
end

function M.print(x, y, t)
  local str = StringBuffer()
  str:append([[\0]])
  str:append(string.format([=[\_l[,%s]]=], y))
  for _, v in ipairs(t) do
    if type(v) == "table" then
      str:append(string.format([=[\_l[%s,]%s\n]=], x, v.str))
    else
      str:append(string.format([=[\_l[%s,]%s\n]=], x, tostring(v)))
    end
  end
  return str:tostring()
end

function M.center(t)
  if type(t) == "string" then
    t = {t}
  end
  local w = wmax(t)
  local h = hmax(t)
  return M.print(math.floor(300 - w / 2), math.floor(300 - h / 2), t)
end

function M.circle(index, size, t)
  if type(t) == "string" then
    t = {t}
  end
  local w = wmax(t)
  local h = hmax(t)
  return M.print(
    math.floor(300 - (w / 2) + 200 * math.sin(2 * math.pi * index / size)),
    math.floor(300 - (h / 2) - 200 * math.cos(2 * math.pi * index / size)),
    t
  )
end

return M
