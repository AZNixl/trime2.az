name = "编辑"
author = "酷安@M_Stone | AZNixl移植"
key_width = 20
key_height = 22

rows = {
    -- 第一行
    {
        keys = {
            { click = ",", style = "functional" },
            { click = "Home", style = "style_W" },
            { click = "Up", style = "style_E" },
            { click = "End", style = "style_R" },
            { click = "BackSpace", style = "functional" },
        }
    },
    -- 第二行
    {
        keys = {
            { click = ".", style = "functional" },
            { click = "Left", style = "style_W" },
            { click = "Shift1", style = "style_E" },
            { click = "Right", style = "style_R" },
            { click = "space1", style = "functional" },
        }
    },
    -- 第三行
    {
        keys = {
            { click = "Keyboard_number", label = "数字", style = "functional" },
            { click = "Tab", style = "style_W" },
            { click = "Down", style = "style_E" },
            { click = "select_H", style = "style_R" },
            { click = "Keyboard_symbols_en", label = "英符", style = "functional" },
        }
    },
    -- 第四行
    {
        keys = {
            { click = "Keyboard_default", style = "functional" },
            { click = "redo", style = "style_W" },
            { click = "Clear", style = "style_E" },
            { click = "undo", style = "style_R" },
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
