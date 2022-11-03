local Util          = require("talk.game._util")

return {
  {
    id  = "OnPokerGamePlayerAction",
    content = function(shiori, ref)
      if ref[3] then
        return string.format([=[\C\![raise,OnPokerAction,%s,%s,%s,%s]]=], Util.VERSION, "user", ref[2], ref[3]) ..
          [=[\![raise,OnPokerGameActionResultInternal]]=]
      end
      return string.format([=[\C\![raise,OnPokerAction,%s,%s,%s]]=], Util.VERSION, "user", ref[2]) ..
        [=[\![raise,OnPokerGameActionResultInternal]]=]
    end,
  },
  {
    id  = "OnPokerGamePlayerBetInput",
    content = function(shiori, ref)
      local __  = shiori.var
      if __("_PlayerTurn") and tonumber(ref[0]) then
        return string.format([=[\C\![raise,OnPokerGamePlayerAction,%s,player,bet,%s]]=], Util.VERSION, ref[0])
      end
    end,
  },
  {
    id  = "OnPokerGamePlayerRaiseInput",
    content = function(shiori, ref)
      local __  = shiori.var
      if __("_PlayerTurn") and tonumber(ref[0]) then
        return string.format([=[\C\![raise,OnPokerGamePlayerAction,%s,player,raise,%s]]=], Util.VERSION, ref[0])
      end
    end,
  },
  {
    id  = "b_Key",
    content = function(shiori, ref)
      local __  = shiori.var
      if __("_PlayerTurn") then
        return [=[\C\![open,inputbox,OnPokerGamePlayerBetInput]]=]
      end
    end,
  },
  {
    id  = "r_Key",
    content = function(shiori, ref)
      local __  = shiori.var
      if __("_PlayerTurn") then
        return [=[\C\![open,inputbox,OnPokerGamePlayerRaiseInput]]=]
      end
    end,
  },
  {
    id  = "a_Key",
    content = function(shiori, ref)
      local __  = shiori.var
      if __("_PlayerTurn") then
        __("_PlayerTurn", false)
        return string.format([=[\C\![raise,OnPokerGamePlayerAction,%s,player,allin]]=], Util.VERSION)
      end
    end,
  },
  {
    id  = "c_Key",
    content = function(shiori, ref)
      local __  = shiori.var
      if __("_PlayerTurn") then
        __("_PlayerTurn", false)
        local board = __("_Board")
        local index = __("_Index")
        local player  = board:getPlayers()[index]
        local bet = board:getCurrentBet()
        local actions = player:availableAction(bet)
        local is_call = false
        for _, v in ipairs(actions) do
          if v == "call" then
            is_call = true
            break
          end
        end
        if is_call then
          return string.format([=[\C\![raise,OnPokerGamePlayerAction,%s,player,call]]=], Util.VERSION)
        else
          return string.format([=[\C\![raise,OnPokerGamePlayerAction,%s,player,check]]=], Util.VERSION)
        end
      end
    end,
  },
  {
    id  = "f_Key",
    content = function(shiori, ref)
      local __  = shiori.var
      if __("_PlayerTurn") then
        __("_PlayerTurn", false)
        return string.format([=[\C\![raise,OnPokerGamePlayerAction,%s,player,fold]]=], Util.VERSION)
      end
    end,
  },
}
