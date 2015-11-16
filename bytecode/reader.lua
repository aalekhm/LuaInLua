local bit = require "bit"
local utils = require "common.utils"

local function int(str, i, n)
  if not n then n = 4 end
  if n == 1 then
    return str:byte(i), i + 1
  end
  local k = str:byte(i)
  local m, i = int(str, i + 1, n-1)

  return bit.lshift(m, 8) + k, i
end

local function sizet(str, i)
  error "Not implemented"
end

local function short(str, i)
  return int(str, i, 2)
end

local function byte(str, i)
  return str:byte(i), i+1
end

local function string(str, i)
  local size, i = int(str, i)
  if size == 0 then
    return nil, i
  end
  local str = str:sub(i, i+size-2)
  return str, i+size
end

local function double(str, i)
  local lo, i = int(str, i)
  local hi, i = int(str, i)
  -- 1 11 52
  -- hi:63    - sign
  -- hi:62-52 - exp
  -- hilo - 0 - man
  -- exp_mask = 0b01111111111100000000000000000000
  local e = 2^(bit.rshift(bit.band(hi,0x7ff00000),20)-1023)
  --print(bit.tohex(hi),bit.tohex(lo), e)
  local m = 1
  for i=1,52 do
    local c = 0
    local n, j = lo, i-1
    if j >= 32 then
      n, j = hi, j-32
    end
    local msk = 2^j
    if bit.rshift(bit.band(n, msk), j) ~= 0 then
      -- add (1/msk)/2 to m
      m = m + (1/(2^(53-i)))
    end
  end
  return m*e, i
end

local function contexualize(f)
  return function(ctx, ...)
    local str, i = unpack(ctx)
    local r, i = f(str, i, ...)
    ctx[2] = i
    return r
  end
end

local reader = {int=contexualize(int), short=contexualize(short), byte=contexualize(byte), string=contexualize(string), double=contexualize(double), contexualize = contexualize}

function reader:configure(sizet)
  self.sizet = sizet
end

local function new_reader(str)
  return setmetatable({str, 1}, {__index=utils.copy(reader)})
end

reader.new_reader = new_reader

return reader