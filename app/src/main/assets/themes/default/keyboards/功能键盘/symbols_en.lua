name = "英文符号"
author = "酷安@M_Stone | AZNixl移植"
key_width = 10
ascii_mode = true
key_height = 22

rows = {
    -- 第一行
    {
        keys = {
            { click = "Keyboard_symbols_cn", ascii = { click = "Keyboard_symbols_cn",label = "中符" }, style = "functional", width = 20 },
            { click = ",", style = "style_W" },
            { click = ".", style = "style_E" },
            { click = "?", style = "style_R" },
            { click = "!", style = "style_T" },
            { click = "\\", style = "style_Y" },
            { click = "/", style = "style_U" },
            { click = "BackSpace", style = "functional", width = 20 },
        }
    },
    -- 第二行
    {
        keys = {
            { click = "Keyboard_symbols_en", ascii = { click = "Keyboard_symbols_en",label = "英符" }, style = "functional", width = 20 },
            { click = "\"", style = "style_W" },
            { click = "'", style = "style_E" },
            { click = "%", style = "style_R" },
            { click = "&", style = "style_T" },
            { click = "#", style = "style_Y" },
            { click = "*", style = "style_U" },
            { click = "space1", style = "functional", width = 20 },
        }
    },
    -- 第三行
    {
        keys = {
            { click = "Keyboard_number", label = "数字", ascii = { click = "Keyboard_number", label = "数字" }, style = "functional", width = 20 },
            { click = "@", style = "style_W" },
            { click = "$", style = "style_E" },
            { click = ";", style = "style_R" },
            { click = "``", style = "style_T" },
            { click = "_", style = "style_Y" },
            { click = "-", style = "style_U" },
            { click = "Keyboard_editor", ascii = { click = "Keyboard_editor",label = "</>" }, style = "functional", width = 20 },
        }
    },
    -- 第四行
    {
        keys = {
            { click = "Keyboard_default", style = "functional", width = 20 },
            { click = "+", style = "style_W" },
            { click = "=", style = "style_E" },
            { click = "{}{Left}", style = "style_R" },
            { click = "<>{Left}", style = "style_T" },
            { click = "(){Left}", style = "style_Y" },
            { click = "[]{Left}", style = "style_U" },
            { click = "Return1", style = "functional", width = 20 },
        }
    },
   -- 第五行
    {
        height = 17,
        keys = {
            { click = "emoji", width = 25, style = "transparent_num", long_click = "jtb" },
            { width = 50 },
            { click = "VOICE_ASSIST",  width = 25, style = "transparent_num" },
        }
    }
}
