local Class   = require("class")
local Const   = require("texas_holdem._const")
local Player  = require("texas_holdem._player")
local Pool    = require("texas_holdem._pool")

local M = Class()
M.__index = M

local function nextPlayer(index, size)
  return index % size + 1
end

local function prevPlayer(index, size)
  return (index + (size - 2)) % size + 1
end

function M:initialize()
  self._players = {}
  self._blind   = Const.BLIND
  self._pool    = Pool()
  self:initRound()
end

function M:initRound()
  self._pot = 0
  self._flip_bet  = 0
  for _, v in ipairs(self:getPlayers()) do
    v:initRound()
  end
  self:initCards()
  self._pool:initialize()
  self:initFlip()
end

function M:nextRound(blind_level)
  repeat
    self._dealer  = nextPlayer(self._dealer, #self._players)
  until self._players[self._dealer]:getStack() > 0
  if blind_level then
    self._blind = math.ceil(self._blind / 10 * 1.3) * 10
  end
end

function M:initFlip()
  for _, v in ipairs(self:getPlayers()) do
    self._pot = self._pot + v:getBet()
    v:initFlip()
  end
end

function M:blindBet()
  local sb = self._dealer
  repeat
    sb  = nextPlayer(sb, #self._players)
  until self._players[sb]:getState() ~= Const.STATE.DROPOUT
  local sb_player = self._players[sb]
  sb_player:blindBet(false)
  local bb = sb
  repeat
    bb  = nextPlayer(bb, #self._players)
  until self._players[bb]:getState() ~= Const.STATE.DROPOUT
  local bb_player = self._players[bb]
  bb_player:blindBet(true)
end

function M:addPlayer(player)
  table.insert(self._players, player)
end

function M:shufflePlayers()
  -- shuffle
  for i = 1, #self._players do
    local j = math.random(i)
    self._players[i], self._players[j]  = self._players[j], self._players[i]
  end
  self._dealer  = math.random(#self._players)
end

function M:createPlayer(ghost_name, name)
  local player  = Player(self)
  player:setName(ghost_name, name)
  table.insert(self._players, player)
  return player
end

function M:getPlayers()
  return self._players
end

function M:getJoinablePlayers()
  local t = {}
  for _, v in ipairs(self:enumeratePlayersStartAt()) do
    if v:getState() ~= Const.STATE.FOLD and
        v:getState() ~= Const.STATE.DROPOUT then
      table.insert(t, v)
    end
  end
  return t
end

function M:getPlayablePlayers()
  local t = {}
  for _, v in ipairs(self:getPlayers()) do
    if v:isPlayable() then
      table.insert(t, v)
    end
  end
  return t
end

function M:enumeratePlayersStartAt(index)
  assert(self._dealer)
  index = index or self._dealer
  local t = {}
  local i = index
  repeat
    table.insert(t, self._players[i])
    i = nextPlayer(i, #self._players)
  until i == index
  return t
end

function M:distributeCards()
  self._pool:initialize()
  for _, v in ipairs(self:getJoinablePlayers()) do
    if v:isPlayable() then
      v:setCards({self._pool:discharge(), self._pool:discharge()})
    end
  end
end

function M:initCards()
  self._cards = {}
end

function M:flipCard()
  table.insert(self._cards, self._pool:discharge())
end

function M:getCards()
  return self._cards
end

function M:getBlind()
  return self._blind
end

function M:getPot()
  --[[
  local sum = 0
  for _, v in ipairs(self:getPlayers()) do
    sum = sum + v:getBet()
  end
  return sum
  --]]
  return self._pot
end

function M:getCurrentBet()
  local bet = 0
  for _, v in ipairs(self:getPlayers()) do
    if bet < v:getBet() then
      bet = v:getBet()
    end
  end
  return bet
end

function M:next(is_pre_flop, index)
  if not(index) then
    index = self._dealer
    if is_pre_flop then
      local sb = self._dealer
      repeat
        sb  = nextPlayer(sb, #self._players)
      until self._players[sb]:getState() ~= Const.STATE.DROPOUT
      index = sb
      repeat
        index = nextPlayer(index, #self._players)
      until self._players[index]:getState() ~= Const.STATE.DROPOUT
    end
  end
  local last_index  = index
  local bet = self:getCurrentBet()
  while true do
    index = nextPlayer(index, #self._players)
    local player  = self._players[index]
    if player:isBetJoinable(bet) then
      return index, player
    else
      if index == last_index then
        return nil
      end
    end
  end
end

function M:makePot()
  local t = {}
  for _, v in ipairs(self:getPlayers()) do
    table.insert(t, {
      playable  = v:isPlayable(),
      state     = v:getState(),
      name      = v:getGhostName(),
      size      = v:getTotalBet(),
    })
  end
  table.sort(t, function(a, b)
    if a.size == b.size then
      return a.state < b.state
    end
    return a.size < b.size
  end)
  local list  = {}
  -- SidePotの作成
  local pot = {
    sum  = 0, max  = 0, player = {},
  }
  for _, v in ipairs(t) do
    if v.playable then
      table.insert(pot.player, v.name)
    end
    local size  = v.size
    for _, pot in ipairs(list) do
      pot.sum = pot.sum + pot.max
      size  = size - pot.max
      table.insert(pot.player, v.name)
    end
    pot.sum = pot.sum + size
    pot.max = size
    if size > 0 and v.state == Const.STATE.ALLIN then
      table.insert(list, pot)
      pot = {
        sum  = 0, max  = 0, player = {},
      }
    end
  end
  if #list == 0 or list[#list].max ~= pot.max then
    table.insert(list, pot)
  end

  return list
end

return M
