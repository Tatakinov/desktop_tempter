local M = {
  HELLO           = "hello",
  GAME_START      = "game_start",
  ROUND_START     = "round_start",
  ROUND_RESULT    = "round_result",
  BLIND_BET       = "blind_bet",
  HAND            = "hand",
  FLIP            = "flip",
  BET             = "bet",
  ACTION          = "action",
  SHOW_DOWN       = "show_down",
  GAME_RESULT     = "game_result",
  --
  RESPONSE  = "OnPoker",
  NOTIFY    = "OnPokerNotify",
}

M.Response  = {
  [M.HELLO]   = "OnPokerSayHello",
  [M.ACTION]  = "OnPokerAction",
}

return M
