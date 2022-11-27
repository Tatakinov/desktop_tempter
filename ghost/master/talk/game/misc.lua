local Render        = require("talk.game._render")

return {
  {
    id  = "0Poke",
    content = function(shiori, ref)
      return [[\_q]] .. Render.center({
        "Sキー: ゲーム開始(ユーザーあり)",
        "Uキー: ゲーム開始(ユーザーなし)",
        "Bキー: ベット(インプットボックスにベット額を入力)",
        "Rキー: レイズ(インプットボックスにベット額を入力)",
        "Aキー: オールイン",
        "Cキー: チェック/コール",
        "Fキー: フォールド",
        "Pキー: 設定",
      }) .. [[\_q]]
    end,
  },
  {
    id  = "OnNotifySelfInfo",
    content = function(shiori, ref)
      local __  = shiori.var
      __("_ShellName", ref[3])
    end,
  },
  {
    id  = "OnShellChanged",
    content = function(shiori, ref)
      local __  = shiori.var
      __("_ShellName", ref[0])
    end,
  },
  {
    -- start game
    id  = "u_Key",
    content = function(shiori, ref)
      return [=[\![raise,OnPokerStartInternal,true]]=]
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
  {
    id  = "p_Key",
    content = [[
\0
\![raise,OnPreference]
]],
  },
  {
    id  = "OnPreference",
    content = function(shiori, ref)
      local __  = shiori.var
      local stack = __("StackBegin") or 2000
      local stack_raw = string.format("Stack %d 【変更】", stack)
      local stack_str = string.format("Stack %d 【\\q[変更,OnPreferenceInputStack]】", stack)
      local blind = __("BlindBegin") or 20
      local blind_raw = string.format("Blind %d 【変更】", blind)
      local blind_str = string.format("Blind %d 【\\q[変更,OnPreferenceInputBlind]】", blind)
      return [[\_q]] .. Render.center({
        {
          raw = stack_raw,
          str = stack_str,
        },
        {
          raw = blind_raw,
          str = blind_str,
        },
      }) .. [[\_q]]
    end,
  },
  {
    id  = "OnPreferenceInputStack",
    content = [[
\C\![open,inputbox,OnPreferenceChangeStack]
]],
  },
  {
    id  = "OnPreferenceChangeStack",
    content = function(shiori, ref)
      local __  = shiori.var
      local n = tonumber(ref[0]) or 0
      if n > 0 then
        __("StackBegin", n)
      end
      return "\\![raise,OnPreference]"
    end,
  },
  {
    id  = "OnPreferenceInputBlind",
    content = [[
\C\![open,inputbox,OnPreferenceChangeBlind]
]],
  },
  {
    id  = "OnPreferenceChangeBlind",
    content = function(shiori, ref)
      local __  = shiori.var
      local n = tonumber(ref[0]) or 0
      if n > 0 then
        __("BlindBegin", n)
      end
      return "\\![raise,OnPreference]"
    end,
  },
}
