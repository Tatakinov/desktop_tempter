local StringBuffer  = require("string_buffer")
local Event         = require("talk.game._event")

local function max(a, b)
  return a > b and a or b
end

local function join(t)
  local tmp = {}
  for _, v in ipairs(t) do
    if v:getGhostName() ~= "user" then
      table.insert(tmp, v:getGhostName())
    end
  end
  return table.concat(tmp, string.char(0x01))
end

local function RaiseOther(event, name)
  name  = name or "__SYSTEM_ALL_GHOST__"
  local Util          = require("talk.game._util")
  return string.format([=[\![raiseother,%s,%s,%s,]=], name, event, Util.VERSION)
end

local function RaiseOtherWithResponse(event, id, name)
  name  = name or "__SYSTEM_ALL_GHOST__"
  local Util          = require("talk.game._util")
  return string.format([=[\![raiseother,%s,%s,%s,%s,%s,%s]=], name, event, Util.VERSION, Util.SENDER, Event.Response[id] ,id)
end

return {
  {
    id  = "OnPokerSayHelloSend",
    content = function(shiori, ref)
      return RaiseOtherWithResponse(Event.RESPONSE, Event.HELLO) .. "]"
    end,
  },
  {
    id  = "OnPokerStartSend",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local players = board:getPlayers()
      local str = StringBuffer()
      str:append([[\C]])
      str:append(RaiseOther(Event.NOTIFY))
      str:append(Event.GAME_START)
      for _, v in ipairs(players) do
        str:append(","):append(v:getGhostName())
      end
      str:append("]")
      return str
    end,
  },
  {
    id  = "OnPokerGameRoundStartSend",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local players = board:getPlayers()
      local str = StringBuffer()
      str:append(RaiseOther(Event.NOTIFY, join(players)))
      str:append(Event.ROUND_START)
      str:append(","):append(board:getBlind())
      for _, v in ipairs(board:enumeratePlayersStartAt()) do
        if v:isPlayable() then
          str:append(","):append(v:getGhostName())
              :append(string.char(0x01)):append(v:getStack())
        end
      end
      str:append("]")
      return str
    end,
  },
  {
    id  = "OnPokerGameHandSend",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local str = StringBuffer()
      for _, v in ipairs(board:enumeratePlayersStartAt()) do
        if v:getGhostName() ~= "user" and v:isPlayable() then
          str:append(RaiseOther(Event.NOTIFY, v:getGhostName()))
          str:append(Event.HAND)
          for _, v in ipairs(v:getCards()) do
            str:append(","):append(v.suit .. v.number)
          end
          str:append("]")
        end
      end
      __("_Index", nil)
      str:append([=[\![raise,OnPokerGamePreFlopInternal]]=])
      return str
    end,
  },
  {
    id  = "OnPokerGameBlindBetSend",
    content = function(shiori, ref)
      local __  = shiori.var

      local board = __("_Board")
      local players = board:getPlayers()
      local player  = nil
      local str = StringBuffer()
      str:append([[\C]])
      local t = {}
      for _, v in ipairs(board:enumeratePlayersStartAt()) do
        if v:isPlayable() then
          table.insert(t, v)
        end
        if v:getGhostName() ~= "user" and v:getBet() > 0 then
          str:append(RaiseOther(Event.NOTIFY, v:getGhostName()))
          str:append(Event.BLIND_BET)
          str:append(","):append(v:getBet())
          str:append("]")
        end
      end
      assert(#t >= 2)
      if #t == 2 then
        player  = t[1]
      else
        player  = t[3]
      end
      local sum = 0
      for _, v in ipairs(board:getPlayers()) do
        sum = sum + v:getBet()
      end
      str:append(RaiseOther(Event.NOTIFY, join(players)))
      str:append(Event.BET)
      str:append(","):append(sum)
      str:append(","):append(board:getCurrentBet())
      str:append(","):append(player:getGhostName())
      if player:getState() == "allin" then
        str:append(","):append("allin")
      else
        str:append(","):append("bet")
      end
      str:append("]")
      return str
    end,
  },
  {
    id  = "OnPokerGameFlipSend",
    content = function(shiori, ref)
      local __  = shiori.var

      local board = __("_Board")
      local players = board:getPlayers()
      local str = StringBuffer()
      str:append([[\C]])
      str:append(RaiseOther(Event.NOTIFY, join(players)))
      str:append(Event.FLIP)
      str:append(","):append(board:getPot())
      for _, v in ipairs(board:getCards()) do
        str:append(","):append(v.suit .. v.number)
      end
      str:append("]")
      return str
    end,
  },
  {
    id  = "OnPokerGameActionSend",
    content = function(shiori, ref)
      local __  = shiori.var

      local board = __("_Board")
      local index = __("_Index")
      local is_preflop  = __("_IsPreFlop")
      local str = StringBuffer()
      local bet = max(board:getCurrentBet(), board:getBlind())

      if index then
        local player  = board:getPlayers()[index]
        if player:getGhostName() ~= "user" then
          str:append(RaiseOtherWithResponse(Event.RESPONSE, Event.ACTION, player:getGhostName()))
          for _, v in ipairs(player:availableAction(bet)) do
            str:append(","):append(v)
          end
          str:append("]")
          __("_CallbackTimer", {
            start = os.time(),
            time  = 1,
            func  = function()
              return [=[\C\![raise,OnPokerGameActionResultInternal]]=]
            end,
          })
        else
          str:append([=[\C\![raise,OnPokerGamePlayerActionInternal]]=])
        end
      else
        str:append([=[\C\![raise,OnPokerGameFlipInternal]]=])
      end
      return str
    end,
  },
  {
    id  = "OnPokerGameBetSend",
    content = function(shiori, ref)
      local __  = shiori.var
      local board   = __("_Board")
      local index   = __("_Index")
      local action  = __("_Received")
      local players = board:getPlayers()
      local player  = players[index]
      local str = StringBuffer()
      local sum = 0
      for _, v in ipairs(board:getPlayers()) do
        sum = sum + v:getBet()
      end
      str:append(RaiseOther(Event.NOTIFY, join(players)))
      str:append(Event.BET)
      str:append(","):append(sum)
      str:append(","):append(board:getCurrentBet())
      str:append(","):append(player:getGhostName())
      str:append(","):append(action.action)
      str:append("]")
      return str
    end,
  },
  {
    id  = "OnPokerGameShowDownSend",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local players = board:getPlayers()
      local t = {}
      local str = StringBuffer()
      str:append(RaiseOther(Event.NOTIFY, join(players)))
      str:append(Event.SHOW_DOWN)
      for _, v in ipairs(players) do
        if v:isPlayable() then
          str:append(","):append(v:getGhostName())
          for _, v in ipairs(v:getCards()) do
            str:append(string.char(0x01)):append(v.suit .. tostring(v.number))
          end
        end
      end
      str:append("]")
      return str
    end,
  },
  {
    id  = "OnPokerGameRoundResultSend",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local winner  = __("_Winner")
      local t = {}
      local rank  = winner[1].rank
      for _, v in ipairs(winner) do
        if rank == v.rank then
          table.insert(t, v.name)
        else
          break
        end
      end
      local str = StringBuffer()
      str:append(RaiseOther(Event.NOTIFY, join(board:getPlayers())))
      str:append(Event.ROUND_RESULT)
      str:append(","):append(table.concat(t, string.char(0x01)))
      for _, v in ipairs(board:enumeratePlayersStartAt()) do
        if v:isPlayable() then
          str:append(","):append(v:getGhostName())
              :append(string.char(0x01)):append(v:getStack())
        end
      end
      str:append("]")
      return str
    end,
  },
  {
    id  = "OnPokerGameResultSend",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local players = board:getPlayers()
      local player  = board:getPlayablePlayers()[1]
      local str = StringBuffer()
      str:append([[\C]])
      str:append(RaiseOther(Event.NOTIFY, join(players)))
      str:append(Event.GAME_RESULT)
      str:append(","):append(player:getGhostName())
      str:append("]")
      return str
    end,
  },
}
