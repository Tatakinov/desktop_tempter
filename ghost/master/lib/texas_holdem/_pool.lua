local Class = require("class")

local M = Class()
M.__index = M

function M:initialize()
  local cards = {}
  --for _, v in ipairs({"♠", "♥", "♣", "◆"}) do
  for _, v in ipairs({"S", "H", "C", "D"}) do
    for i = 1, 13 do
      table.insert(cards, {suit = v, number = i})
    end
  end
  self._cards = cards
  self:shuffle()
end

function M:shuffle()
  for i = 1, #self._cards do
    local j = math.random(i)
    self._cards[i], self._cards[j]  = self._cards[j], self._cards[i]
  end
end

function M:discharge()
  assert(#self._cards > 0)
  return table.remove(self._cards)
end

return M
