local utf8          = require("lua-utf8")
local StringBuffer  = require("string_buffer")
local TexasHoldem   = require("texas_holdem")
local Render        = require("talk.game._render")
local HandUtil      = require("talk.game._hand_util")

local function min(a, b)
  return a < b and a or b
end

local function find(array, elem)
  for i, v in ipairs(array) do
    if v == elem then
      return i
    end
  end
  return nil
end

local function isWinner(i, t)
  local tbl = {}
  local rank  = t[1].rank
  for _, v in ipairs(t) do
    if rank == v.rank then
      table.insert(tbl, v)
    else
      break
    end
  end
  for _, v in ipairs(tbl) do
    if v.index == i then
      return true
    end
  end
  return false
end

local function card2str(suit, num, style)
  local suit2suit  = {
    S = "♠",
    H = "♥",
    C = "♣",
    D = "♦",
  }
  local num2num = {
    "A", "2", "3", "4",
    "5", "6", "7", "8",
    "9", "10", "J", "Q",
    "K",
  }
  local suit2color = {
    S = "#7fafff",
    H = "#bfbf00",
    C = "#00cf00",
    D = "#ff7f00",
  }
  if style then
    return string.format([=[\f[bold,true]\f[color,%s]%s\f[color,default]\f[bold,false]]=], suit2color[suit], card2str(suit, num, false))
  else
    return suit2suit[suit] .. num2num[num]
  end
end

local function printInfo(board, opt)
  opt = opt or {open  = {}}
  local Util  = require("talk.game._util")
  local players = board:getPlayers()
  local str = StringBuffer()
  str:append([[\C\_q\![set,balloontimeout,-1]\c]])
  for i, v in ipairs(players) do
    local t = {}
    if opt.winner and isWinner(i, opt.winner) then
      table.insert(t, {
        raw = v:getName(),
        str = string.format([=[\f[color,yellow]%s\f[color,default]]=], v:getName())
      })
    elseif opt.index and i == opt.index then
      table.insert(t, {
        raw = v:getName(),
        str = string.format([=[\f[color,cyan]%s\f[color,default]]=], v:getName())
      })
    elseif not(v:isPlayable()) then
      table.insert(t, {
        raw = v:getName(),
        str = string.format([=[\f[color,black]%s\f[color,default]]=], v:getName())
      })
    else
      table.insert(t, v:getName())
    end
    if v:isPlayable() then
      if v:getState() ~= "none" and v:getState() ~= "blind_bet" then
        table.insert(t, v:getState())
      else
        table.insert(t, "")
      end
      table.insert(t, "Bet    " .. tostring(v:getBet()))
      table.insert(t, "Stack  " .. tostring(v:getStack()))
      if opt.show_down then
        local num2hand  = {
          "Straight Flush",
          "Four Of A Kind",
          "Full House",
          "Flush",
          "Straight",
          "Three Of A Kind",
          "Two Pair",
          "One Pair",
          "High Card",
        }
        local cards = {}
        for _, v in ipairs(v:getCards()) do
          table.insert(cards, v)
        end
        for _, v in ipairs(board:getCards()) do
          table.insert(cards, v)
        end
        local hand  = HandUtil.evaluateAll(cards)
        table.insert(t, num2hand[hand.main])
      end
    else
      if v:getState() ~= "none" and v:getState() ~= "blind_bet" then
        table.insert(t, {
          raw = v:getState(),
          str = string.format([=[\f[color,black]%s\f[color,default]]=], v:getState())
        })
      else
        table.insert(t, "")
      end
      table.insert(t, {
        raw = "Bet    " .. tostring(v:getBet()),
        str = string.format([=[\f[color,black]%s\f[color,default]]=], "Bet   " .. tostring(v:getBet()))
      })
      table.insert(t, {
        raw = "Stack  " .. tostring(v:getStack()),
        str = string.format([=[\f[color,black]%s\f[color,default]]=], "Stack " .. tostring(v:getStack()))
      })
    end
    if v:isPlayable() and
        opt.open[v:getGhostName()] then
      local t1  = {}
      local t2  = {}
      for _, v in ipairs(v:getCards()) do
        table.insert(t1, card2str(v.suit, v.number, false))
        table.insert(t2, card2str(v.suit, v.number, true))
      end
      if #t1 > 0 then
        table.insert(t, {
          raw = table.concat(t1, " "),
          str = table.concat(t2, " "),
        })
      end
    end
    str:append(Render.circle(i, #players, t))
  end
  local t = {
    "Pot   " .. tostring(board:getPot()),
    "Blind " .. tostring(math.floor(board:getBlind() / 2)) .. "/" .. tostring(board:getBlind()),
  }
  local t1  = {}
  local t2  = {}
  for _, v in ipairs(board:getCards()) do
    table.insert(t1, card2str(v.suit, v.number, false))
    table.insert(t2, card2str(v.suit, v.number, true))
  end
  if #t1 > 0 then
    table.insert(t, {
      raw = table.concat(t1, " "),
      str = table.concat(t2, " "),
    })
  end
  str:append(Render.center(t))
  str:append([[\_q]])
  return str:tostring()
end

return {
  {
    id  = "OnPokerStartInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      shiori:talk("OnPokerInitializeInternal")

      __("_CallbackTimer", {
        start = os.time(),
        time  = 1,
        func  = function()
          return [=[\C\![raise,OnPokerGhostNameToSakuraNameInternal]]=]
        end,
      })

      return Render.center("参加者募集中…") .. shiori:talk("OnPokerSayHelloSend")
    end,
  },
  {
    id  = "OnPokerInitializeInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = TexasHoldem()
      board:initialize()
      __("_Board", board)
      board:createPlayer("user", "あなた")
      __("_GhostList", {})
      __("_Rank", {})
      __("_MinuteCounter", 0)
    end,
  },
  {
    id  = "OnPokerGhostNameToSakuraNameInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local list  = __("_GhostList")
      if #list == 0 then
        return Render.center([[プレイヤーが集まらなかったようだ…]])
      end
      local str = StringBuffer()
      str:append([=[\![get,property,OnPokerGhostNameToSakuraNameResultInternal,]=])
      for i, v in ipairs(list) do
        str:append("activeghostlist(" .. v .. ").sakuraname")
        if i < #list then
          str:append(",")
        end
      end
      str:append("]")
      return str
    end,
  },
  {
    id  = "OnPokerGhostNameToSakuraNameResultInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local list  = __("_GhostList")
      if not(ref[0]) then
        return Render.center([[プレイヤー名の取得に失敗]])
      end
      local board = __("_Board")
      for i = 1, #list do
        board:createPlayer(list[i], ref[i - 1])
      end
      return [=[\![raise,OnPokerGameInitializeInternal]]=]
    end,
  },
  {
    id  = "OnPokerGameInitializeInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      board:shufflePlayers()

      __("_CallbackTimer", {
        start = os.time(),
        time  = 2,
        func  = function()
          return [=[\C\![raise,OnPokerGameRoundStartInternal]]=]
        end,
      })

      local t = {"〜参加者〜", ""}
      for _, v in ipairs(board:getPlayers()) do
        table.insert(t, v:getName())
      end

      return [[\_q]] .. Render.center(t) .. [=[\_q\![raise,OnPokerStartSend]]=]
    end,
  },
  {
    id  = "OnPokerGameRoundStartInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      board:initRound()
      __("_IsFullOpen", false)

      if #board:getPlayablePlayers() <= 1 then
        return [=[\C\![raise,OnPokerGameResultInternal]]=]
      end

      __("_CallbackTimer", {
        start = os.time(),
        time  = 1,
        func  = function()
          return [=[\C\![raise,OnPokerGameHandInternal]]=]
        end,
      })
      local t = {
        user  = true,
      }
      __("_HandOpenPlayer", t)
      return printInfo(board, {open = __("_HandOpenPlayer")}) ..
          shiori:talk("OnPokerGameRoundStartSend")
    end,
  },
  {
    id  = "OnPokerGameHandInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      board:distributeCards()
      local t = __("_HandOpenPlayer")
      for _, v in ipairs(board:getPlayers()) do
        if v:getState() == "allin" then
          t[v:getGhostName()]  = true
        end
      end
      return printInfo(board, {open  = t}) ..
      shiori:talk("OnPokerGameHandSend")
    end,
  },
  {
    id  = "OnPokerGameActionInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")

      local players = board:getPlayablePlayers()
      assert(#players > 0)
      if #players == 1 then
        return [=[\C\![raise,OnPokerGameRoundResultInternal]]=]
      end

      local index = __("_Index")
      if __("_IsFullOpen") then
        index = nil
      else
        index = board:next(__("_IsPreFlop"), index)
      end
      __("_Index", index)
      __("_Received", nil)
      return printInfo(board, {index = index, open = __("_HandOpenPlayer")}) ..
          shiori:talk("OnPokerGameActionSend")
    end,
  },
  {
    id  = "OnPokerGamePlayerActionInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      __("_PlayerTurn", true)
      return nil
    end,
  },
  {
    id  = "OnPokerGameActionResultInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local index = __("_Index")
      local player  = board:getPlayers()[index]
      if not(__("_Received")) then
        print("bet timeout", player:getGhostName())
        player:fold()
        __("_Received", {action = "fold"})
      end
      --
      local str = shiori:talk("OnPokerGameBetSend")
      __("_Received", nil)
      return [[\C]] ..
          str ..
          [=[\![raise,OnPokerGameActionInternal]]=]
    end,
  },
  {
    id  = "OnPokerGamePreFlopInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      __("_Index", nil)
      __("_IsPreFlop", true)
      board:initFlip()
      board:blindBet()
      __("_HandOpenPlayer", {user  = true})
      return shiori:talk("OnPokerGameFlipSend") ..
          shiori:talk("OnPokerGameBlindBetSend") ..
          [=[\![raise,OnPokerGameActionInternal]]=]
    end,
  },
  {
    id  = "OnPokerGameFlipInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      __("_Index", nil)
      __("_IsPreFlop", false)
      local t = __("_HandOpenPlayer")
      local n_players = #board:getPlayablePlayers()
      for _, v in ipairs(board:getPlayers()) do
        if v:getState() == "allin" then
          t[v:getGhostName()]  = true
          n_players = n_players - 1
        end
      end
      assert(n_players >= 0)
      if n_players <= 1 then
        __("_IsFullOpen", true)
        for _, v in ipairs(board:getPlayablePlayers()) do
          t[v:getGhostName()]  = true
        end
      end
      __("_HandOpenPlayer", t)
      local str = printInfo(board, {open = __("_HandOpenPlayer")})
      board:initFlip()
      if #board:getCards() < 3 then
        __("_CallbackTimer", {
          start = os.time(),
          time  = 1,
          func  = function()
            return [=[\C\![raise,OnPokerGameActionInternal]]=]
          end,
        })
        board:flipCard()
        board:flipCard()
        board:flipCard()
        return str ..
            shiori:talk("OnPokerGameFlipSend")
      elseif #board:getCards() < 5 then
        __("_CallbackTimer", {
          start = os.time(),
          time  = 1,
          func  = function()
            return [=[\C\![raise,OnPokerGameActionInternal]]=]
          end,
        })
        board:flipCard()
        return str ..
            shiori:talk("OnPokerGameFlipSend")
      else
        return printInfo(board, {open = __("_HandOpenPlayer")}) .. [=[\![raise,OnPokerGameShowDownInternal]]=]
      end
    end,
  },
  {
    id  = "OnPokerGameShowDownInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")

      __("_CallbackTimer", {
        start = os.time(),
        time  = 1,
        func  = function()
          return [=[\C\![raise,OnPokerGameRoundResultInternal]]=]
        end,
      })

      local t = __("_HandOpenPlayer")
      for _, v in ipairs(board:getPlayablePlayers()) do
        t[v:getGhostName()] = true
      end
      __("_HandOpenPlayer", t)

      return printInfo(board, {open = __("_HandOpenPlayer"), show_down = true}) ..
          shiori:talk("OnPokerGameShowDownSend")
    end,
  },
  {
    id  = "OnPokerGameRoundResultInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")

      __("_CallbackTimer", {
        start = os.time(),
        time  = 3,
        func  = function()
          return [=[\C\![raise,OnPokerGameAwardPotInternal]]=]
        end,
      })

      local function getIndex(player)
        for i, v in ipairs(board:getPlayers()) do
          if player:getGhostName() == v:getGhostName() then
            return i
          end
        end
        return nil
      end

      local players = board:getPlayablePlayers()
      if #players == 1 then
        local index = getIndex(players[1])
        assert(index)
        __("_Winner", {
          {
            rank    = 0,
            index   = index,
            name    = players[1]:getGhostName(),
          },
        })
        return printInfo(board, {
          winner = __("_Winner"),
          open  = {user = true},
        })
      else
        local max = {}
        for i, v in ipairs(players) do
          local t = {}
          for _, v in ipairs(board:getCards()) do
            table.insert(t, v)
          end
          for _, v in ipairs(v:getCards()) do
            table.insert(t, v)
          end
          local hand  = HandUtil.evaluateAll(t)
          if #max == 0 then
            table.insert(max, {
              index   = getIndex(v),
              rank    = 0,
              name    = v:getGhostName(),
              hand    = hand,
            })
          else
            local size  = #max
            for i, w in ipairs(max) do
              if HandUtil.equal(w.hand, hand) then
                table.insert(max, {
                  index   = getIndex(v),
                  rank    = w.rank,
                  name    = v:getGhostName(),
                  hand    = hand,
                })
                break
              elseif HandUtil.lessThan(w.hand, hand) then
                table.insert(max, {
                  index   = getIndex(v),
                  rank    = w.rank - 1,
                  name    = v:getGhostName(),
                  hand    = hand,
                })
                break
              else
                w.rank  = w.rank - 1
              end
            end
            if size == #max then
              table.insert(max, {
                index   = getIndex(v),
                rank    = max[#max].rank + 1,
                name    = v:getGhostName(),
                hand    = hand,
              })
            end
            table.sort(max, function(a, b)
              return a.rank < b.rank
            end)
          end
        end
        __("_Winner", max)

        local t = __("_HandOpenPlayer")
        for _, v in ipairs(board:getPlayablePlayers()) do
          t[v:getGhostName()] = true
        end
        __("_HandOpenPlayer", t)

        return printInfo(board, {winner = max, open = __("_HandOpenPlayer"), show_down = true})
      end
    end,
  },
  {
    id  = "OnPokerGameAwardPotInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local winner  = __("_Winner")
      local players = board:getPlayers()
      assert(winner and #winner > 0)
      local pots  = board:makePot()
      -- potに入っていないbetを引く
      for _, v in ipairs(players) do
        v:addStack( - v:getBet())
      end
      for _, pot in ipairs(pots) do
        -- ポット毎の勝者を取得
        local t = {}
        local rank
        for _, w in ipairs(winner) do
          if rank and rank ~= w.rank then
            break
          elseif not(rank) and find(pot.player, w.name) then
            rank  = w.rank
          end
          if rank and find(pot.player, w.name) then
            table.insert(t, w.index)
          end
        end
        --
        local award = math.floor(pot.sum / #t)
        local extra = pot.sum - award * #t
        for _, v in ipairs(t) do
          players[v]:addStack(award)
        end
        if extra > 0 then
          local index
          for i, p in ipairs(board:enumeratePlayersStartAt()) do
            for _, v in ipairs(t) do
              if i == v then
                index = i
                break
              end
            end
            if index then
              break
            end
          end
          players[index]:addStack(extra)
        end
      end
      return [[\C]] .. shiori:talk("OnPokerGameRoundResultSend") ..
          [=[\C\![raise,OnPokerGameNextRoundInternal]]=]
    end,
  },
  {
    id  = "OnPokerGameNextRoundInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      board:nextRound(__("_BlindLevel"))
      __("_BlindLevel", false)
      return [=[\C\![raise,OnPokerGameRoundStartInternal]]=]
    end,
  },
  {
    id  = "OnPokerGameResultInternal",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local player  = board:getPlayablePlayers()[1]
      local name  = player:getName()
      local len = utf8.width(name)
      local w = math.floor(len / 2)

      local t = {}
      table.insert(t, "＿" .. string.rep("人", w + 2) .. "＿")
      table.insert(t, "＞　" .. name .. "　＜")
      table.insert(t, "￣" .. string.rep("Y^", w + 2) .. "￣")

      return [[\C\_q\c]] .. Render.center(t) .. [=[\_q\![raise,OnPokerGameResultSend]]=]
    end,
  },
}
