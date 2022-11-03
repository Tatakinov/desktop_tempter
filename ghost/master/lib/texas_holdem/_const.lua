local M = {
  STACK = 2000,
  BLIND = 20,
  STATE = {
    NONE        = "none",
    BLIND_BET   = "blind_bet",
    BET         = "bet",
    CALL        = "call",
    RAISE       = "raise",
    ALLIN       = "allin",
    CHECK       = "check",
    FOLD        = "fold",
    DROPOUT     = "dropout",
  },
}

return M
