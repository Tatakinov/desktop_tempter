local Render        = require("talk.game._render")

return {
  {
    id  = "0Poke",
    content = function(shiori, ref)
      return [[\_q]] .. Render.center({
        "Sキー: ゲーム開始",
        "Bキー: ベット(インプットボックスにベット額を入力)",
        "Rキー: レイズ(インプットボックスにベット額を入力)",
        "Aキー: オールイン",
        "Cキー: チェック/コール",
        "Fキー: フォールド",
      }) .. [[\_q]]
    end,
  },
  {
    -- start game
    id  = "s_Key",
    content = function(shiori, ref)
      return [=[\![raise,OnPokerStartInternal]]=]
    end,
  },
  {
    id  = "OnSecondChange",
    content = function(shiori, ref)
      local __  = shiori.var
      local t = __("_CallbackTimer")
      if t and os.time() > t.start + t.time then
        __("_CallbackTimer", nil)
        return t.func()
      end
    end,
  },
  {
    id  = "OnMinuteChange",
    content = function(shiori, ref)
      local __  = shiori.var
      local m   = __("_MinuteCounter") or 0
      m = m + 1
      if m >= 3 then
        __("_MinuteCounter", 0)
        __("_BlindLevel", true)
      else
        __("_MinuteCounter", m)
      end
    end,
  },
}
