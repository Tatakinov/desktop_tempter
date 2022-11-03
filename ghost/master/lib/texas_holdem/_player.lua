local Class = require("class")
local Const = require("texas_holdem._const")

local M = Class()
M.__index = M

function M:_init(board)
  assert(board)
  self._stack = Const.STACK
  self._board = board
  self:initRound()
end

function M:initBet()
  assert(self._stack >= 0)
  self._state = Const.STATE.NONE
  if self._stack == 0 then
    self._state = Const.STATE.DROPOUT
  end
  self._bet   = 0
  self._total_bet = 0
  self:setCards({})
end

function M:initRound()
  self:initBet()
end

function M:initFlip()
  if self:isPlayable() and self._state ~= Const.STATE.ALLIN then
    self._state = Const.STATE.NONE
  end
  self._stack = self._stack - self._bet
  self._bet   = 0
end

function M:setName(ghost_name, name)
  self._ghost_name  = ghost_name
  self._name  = name
end

function M:getGhostName()
  return self._ghost_name
end

function M:getName()
  return self._name
end

function M:blindBet(is_bb)
  if not(is_bb) then
    self:action(math.floor(self._board:getBlind() / 2))
  else
    self._state = Const.STATE.BLIND_BET
    self:action(self._board:getBlind())
  end
end

function M:getBet()
  return self._bet
end

function M:getTotalBet()
  return self._total_bet
end

function M:getStack()
  return self._stack
end

function M:addStack(stack)
  self._stack  = self._stack + stack
end

function M:getState()
  return self._state
end

function M:isAllIn()
  return self._bet == self._stack
end

function M:isPlayable()
  return self._state ~= Const.STATE.FOLD and
      self._state ~= Const.STATE.DROPOUT
end

function M:isBetJoinable(bet)
  assert(self._bet <= bet)
  if not(self:isPlayable()) then
    return false
  end
  if self._state == Const.STATE.ALLIN then
    return false
  end
  if self._bet == bet then
    if self:getState() == Const.STATE.NONE or
        self:getState() == Const.STATE.BLIND_BET then
      return true
    end
    return false
  end
  return true
end

function M:availableAction(bet)
  assert(self._bet <= bet)
  if not(self:isPlayable()) then
    return {}
  end
  if self._bet == bet then
    if self._state == Const.STATE.NONE then
      return {Const.STATE.BET, Const.STATE.ALLIN, Const.STATE.CHECK, Const.STATE.FOLD}
    -- オプション
    elseif self._state == Const.STATE.BLIND_BET then
      return {Const.STATE.RAISE, Const.STATE.ALLIN, Const.STATE.CHECK, Const.STATE.FOLD}
    end
    return {}
  end
  if bet >= self._stack then
    return {Const.STATE.ALLIN, Const.STATE.FOLD}
  end
  return {Const.STATE.RAISE, Const.STATE.ALLIN, Const.STATE.CALL, Const.STATE.FOLD}
end

function M:setCards(cards)
  self._cards = cards
end

function M:getCards()
  return self._cards
end

function M:action(bet)
  self._total_bet = self._total_bet + bet - self._bet
  self._bet = bet
  if self._bet > self._stack then
    self:allin()
  end
end

function M:bet(bet)
  self._state = Const.STATE.BET
  self:action(bet)
end

function M:raise(bet)
  self._state = Const.STATE.RAISE
  self:action(bet)
end

function M:allin()
  self._state = Const.STATE.ALLIN
  self._total_bet = self._total_bet + self._stack - self._bet
  self._bet   = self._stack
end

function M:call(bet)
  self._state = Const.STATE.CALL
  self:action(bet)
end

function M:check()
  self._state = Const.STATE.CHECK
end

function M:fold()
  self._state = Const.STATE.FOLD
end

return M
