name = "数字键盘"
author = "酷安@M_Stone | AZNixl移植"
key_width = 20
key_height = 22

rows = {
    -- 第一行
    {
        keys = {
            { click = "+", style = "functional", width = 10 },
            { click = "-", style = "functional", width = 10 },
            { click = "1", style = "style_E" },
            { click = "2", style = "style_R" },
            { click = "3", style = "style_T" },
            { click = "BackSpace", style = "functional" },
        }
    },
    -- 第二行
    {
        keys = {
            { click = "*", style = "functional", width = 10  },
            { click = "/", style = "functional", width = 10  },
            { click = "4", style = "style_E" },
            { click = "5", style = "style_R" },
            { click = "6", style = "style_T" },
            { click = "space1", style = "functional" },
        }
    },
    -- 第三行
    {
        keys = {
            { click = "Keyboard_symbols_en", label = "英符", style = "functional" },
            { click = "7", style = "style_W" },
            { click = "8", style = "style_E" },
            { click = "9", style = "style_R" },
            { click = "Keyboard_editor", label = "</>", style = "functional" },
        }
    },
    -- 第四行
    {
        keys = {
            { click = "Keyboard_default", style = "functional" },
            { click = "=", style = "style_W" },
            { click = "0", style = "style_E" },
            { click = ".", style = "style_R" },
            { click = "Return1", style = "functional" },
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
