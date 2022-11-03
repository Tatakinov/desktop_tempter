local M = {}

M.HAND  = {
  STRAIGHT_FLUSH  = 1,
  FOUR_OF_A_KIND  = 2,
  FULL_HOUSE      = 3,
  FLUSH           = 4,
  STRAIGHT        = 5,
  THREE_OF_A_KIND = 6,
  TWO_PAIR        = 7,
  ONE_PAIR        = 8,
  HIGH_CARD       = 9,
}

local function num(hand)
  local t = {}
  for _, v in ipairs(hand) do
    table.insert(t, v.number)
  end
  return t
end

local function isFlush(t)
  local suit  = t[1].suit
  for _, v in ipairs(t) do
    if suit ~= v.suit then
      return false
    end
  end
  return true
end

local function isStraight(t)
  t = num(t)
  if t[1] == 1 then
    if t[2] == 10 and
        t[3] == 11 and
        t[4] == 12 and
        t[5] == 13 then
      return 14
    end
  end
  local diff  = t[1] - 1
  for i, v in ipairs(t) do
    if diff ~= v - i then
      return false
    end
  end
  return t[5]
end

function M.equal(h1, h2)
  if h1.main ~= h2.main then
    return false
  end
  for i, _ in ipairs(h1.sub) do
    if h1.sub[i] ~= h2.sub[i] then
      return false
    end
  end
  return true
end

function M.lessThan(h1, h2)
  if h1.main > h2.main then
    return true
  elseif h1.main < h2.main then
    return false
  end
  for i, _ in ipairs(h1.sub) do
    if h1.sub[i] < h2.sub[i] then
      return true
    elseif h1.sub[i] > h2.sub[i] then
      return false
    end
  end
  -- equal
  return false
end

function M.evaluate(hand)
  local t = {}
  local result  = {
    sub = {}
  }
  for _, v in ipairs(hand) do
    table.insert(t, v)
  end
  table.sort(t, function(a, b)
    return a.number < b.number
  end)
  if isFlush(t) then
    result.main = M.HAND.FLUSH
    local tmp = num(t)
    if tmp[1] == 1 then
      tmp[1]  = 14
    end
    table.sort(tmp, function(a, b)
      return a > b
    end)
    result.sub  = tmp
  end
  local n = isStraight(t)
  if n then
    if result.main == M.HAND.FLUSH then
      result.main = M.HAND.STRAIGHT_FLUSH
    else
      result.main = M.HAND.STRAIGHT
    end
    result.sub  = {n}
  end
  if result.main then
    return result
  end
  local tmp = num(t)
  for i, _ in ipairs(tmp) do
    if tmp[i] == 1 then
      tmp[i]  = 14
    end
  end
  table.sort(tmp, function(a, b)
    return a > b
  end)
  local map = {}
  for i = 1, 14 do
    table.insert(map, 0)
  end
  for _, v in ipairs(tmp) do
    map[v] = map[v] + 1
  end
  for i, v in ipairs(map) do
    if v == 4 then
      result.main = M.HAND.FOUR_OF_A_KIND
      table.insert(result.sub, i)
    elseif v == 3 then
      result.main = M.HAND.THREE_OF_A_KIND
      table.insert(result.sub, i)
    end
  end
  for i = #map, 1, -1 do
    if map[i] == 2 then
      if result.main == M.HAND.THREE_OF_A_KIND then
        result.main = M.HAND.FULL_HOUSE
      elseif result.main == M.HAND.ONE_PAIR then
        result.main = M.HAND.TWO_PAIR
      else
        result.main = M.HAND.ONE_PAIR
      end
      table.insert(result.sub, i)
    end
  end
  if not(result.main) then
    result.main = M.HAND.HIGH_CARD
  end
  for i = #map, 1, -1 do
    if map[i] == 1 then
      table.insert(result.sub, i)
    end
  end
  return result
end

function M.evaluateAll(t)
  local max = {}
  for i1 = 1, #t do
    for i2 = i1 + 1, #t do
      for i3 = i2 + 1, #t do
        for i4 = i3 + 1, #t do
          for i5 = i4 + 1, #t do
            local hand  = M.evaluate({t[i1], t[i2], t[i3], t[i4], t[i5]})
            if #max == 0 then
              table.insert(max, hand)
            else
              if M.equal(max[1], hand) then
                table.insert(max, hand)
              elseif M.lessThan(max[1], hand) then
                max = {hand}
              end
            end
          end
        end
      end
    end
  end
  assert(#max > 0)
  return max[1]
end

return M
