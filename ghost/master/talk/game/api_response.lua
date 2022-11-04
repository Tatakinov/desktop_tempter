local Util  = require("talk.game._util")

local function max(a, b)
  return a > b and a or b
end

local function find(array, elem)
  for i, v in ipairs(array) do
    if v == elem then
      return i
    end
  end
end

return {
  {
    id  = "OnPokerSayHello",
    content = function(shiori, ref)
      local __  = shiori.var
      local t = __("_GhostList")
      if #t < 10 and ref[1] ~= Util.SENDER then
        table.insert(t, ref[1])
      end
    end,
  },
  {
    id  = "OnPokerAction",
    content = function(shiori, ref)
      local __  = shiori.var
      local board = __("_Board")
      local index = __("_Index")
      local player  = board:getPlayers()[index]
      if ref[0] and ref[1] == player:getGhostName() then
        local bet = max(board:getCurrentBet(), board:getBlind())
        local raise = tonumber(ref[3]) or 0
        local actions = player:availableAction(bet)
        local valid = false
        for _, v in ipairs(actions) do
          if v == "bet" and ref[2] == "raise" then
            ref[2]  = "bet"
          elseif v == "raise" and ref[2] == "bet" then
            ref[2]  = "raise"
          elseif v == "call" and ref[2] == "check" then
            ref[2]  = "call"
          elseif v == "check" and ref[2] == "call" then
            ref[2]  = "check"
          elseif not(find(actions, "check")) and not(find(actions, "call")) and (ref[2] == "call" or ref[2] == "check") then
            ref[2]  = "allin"
          elseif not(find(actions, "raise")) and ref[2] == "raise" then
            ref[2]  = "allin"
          end
          if v == ref[2] then
            valid = true
            break
          end
        end
        if valid then
          if ref[2] == "bet" or ref[2] == "raise" then
            -- 賭け金が正しいか確認
            if raise <= bet and bet > 0 then
              player:call(bet)
              __("_Received", {action = "call"})
            elseif raise <= bet and bet == 0 then
              player:check()
              __("_Received", {action = "check"})
            elseif raise >= player:getStack() then
              player:allin()
              __("_Received", {action = "allin"})
            else
              if ref[2] == "bet" then
                player:bet(raise)
              else
                player:raise(raise)
              end
              __("_Received", {action = ref[2], bet = raise})
            end
          elseif ref[2] == "allin" then
            player:allin()
            __("_Received", {action = "allin"})
          elseif ref[2] == "call" then
            player:call(bet)
            __("_Received", {action = "call"})
          elseif ref[2] == "check" then
            player:check()
            __("_Received", {action = "check"})
          elseif ref[2] == "fold" then
            player:fold()
            __("_Received", {action = "fold"})
          end
        else
          print("invalid action", ref[2])
          player:fold()
          __("_Received", {action = "fold"})
        end
      else
        print("invalid user response", ref[1], player:getGhostName())
      end
    end,
  },
}
