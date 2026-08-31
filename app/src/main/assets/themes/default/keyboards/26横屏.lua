--中文输入法同文无障碍群【938020953】
--该布局为“横屏自动悬浮或横屏键盘”，使用横屏键盘时调用的键盘布局。更为适配平板或折叠屏。

name = "26横屏"
author = "AZNixl"
key_width = 7
key_height = 23
lock = true

rows = {
    -- 横屏第一行
    {
        keys = {
            { width = 1 },
            { click = "q", swipe_down = "1", long_click = "1", label = "Q", style = "style_Q" },
            { click = "w", swipe_down = "2", long_click = "2", label = "W", style = "style_W" },
            { click = "e", swipe_down = "3", long_click = "3", label = "E", style = "style_E" },
            { click = "r", swipe_down = "4", long_click = "4", swipe_right = "RepeatCommit", label = "R", style = "style_R" },
            { click = "t", swipe_down = "5", long_click = "5", label = "T", style = "style_T" },
            { width = 3.5 },
            { click = 1, style = "style_Q" },
            { click = 2, style = "style_Q" },
            { click = 3, style = "style_Q" },
            { width = 3.5 },
            { click = "y", swipe_down = "6", long_click = "6", label = "Y", style = "style_Y" },
            { click = "u", swipe_down = "7", long_click = "7", label = "U", style = "style_U" },
            { click = "i", swipe_down = "8", long_click = "8", label = "I", style = "style_I" },
            { click = "o", swipe_down = "9", long_click = "9", label = "O", style = "style_O" },
            { click = "p", swipe_down = "0", long_click = "0", label = "P", style = "style_P" },
            { width = 1 }
        }
    },
    -- 横屏第二行
    {
        keys = {
            { width = 1 },
            { click = "a", long_click = "select_all", label = "A", style = "style_A" },
            { click = "s", swipe_up = "ChineseDate", long_click = "-", label = "S", style = "style_S" },
            { click = "d", swipe_up = "Date", long_click = "@", label = "D", style = "style_D" },
            { click = "f", swipe_up = "Time", long_click = "#", label = "F", style = "style_F" },
            { click = "g", long_click = "Keyboard_editor", label = "G", style = "style_G" },
            { width = 3.5 },
            { click = 4, style = "style_Q" },
            { click = 5, style = "style_Q" },
            { click = 6, style = "style_Q" },
            { width = 3.5 },
            { click = "h", long_click = "_", label = "H", style = "style_H" },
            { click = "j", long_click = "+", label = "J", style = "style_J" },
            { click = "k", long_click = "括号", swipe_up = "Keyboard_settings", label = "K", style = "style_K", popup = {"{}{Left}", "〈〉{Left}", "(){Left}", "《》{Left}", "[]{Left}", "【】{Left}"} },
            { click = "l", long_click = "=", label = "L", style = "style_L" },
            { click = "/", style = "style_L" }
        }
    },
    -- 横屏第三行
    {
        keys = {
            {width = 1},
            { click = "Shift_L", composing = "Escape", swipe_up = "Schema_settings", swipe_down = "Deploy", style = "style_off" },
            { click = "z", long_click = "`", label = "Z", swipe_up = "Keyboard_Preedit", style = "style_Z" },
            { click = "x", long_click = "cut", label = "X", style = "style_X" },
            { click = "c", long_click = "copy", label = "C", style = "style_C" },
            { click = "v", long_click = "paste", label = "V", style = "style_V" },
            { width = 3.5 },
            { click = 7, style = "style_Q" },
            { click = 8, style = "style_Q" },
            { click = 9, style = "style_Q" },
            { width = 3.5 },
            { click = "b", long_click = "{", label = "B", style = "style_B" },
            { click = "n", long_click = "}", label = "N", style = "style_N" },
            { click = "m", long_click = ":", label = "M", style = "style_M" },
            { click = "BackSpace", width = 14, style = "style_Back" },
        }
    },
    -- 横屏第四行
    {
        keys = {
            {width = 1},
            { click = "Keyboard_number", swipe_up = "Keyboard_symbols_en", long_click = "AI", popup = {"gpt1", "gpt2", "gpt5", "gpt3", "gpt4" }, width = 9, composing = "select_3", style = "style_Sym" },
            { click = ",", long_click = "!", swipe_up = "/", width = 6, style = "style_Comma" },
            {
                click = "space1",
                width = 20,
                style = "style_Space",
                long_click = "Mode_switch",
                ascii = {
                    click = "space1",
                    label = "             Aa",
                    long_click = "Mode_switch",
                }
            },
            { width = 3.5 },
            { click = "Keyboard_clipboard", label = "Cilp", style = "style_Q" },
            { click = 0, style = "style_Q" },
            { click = "VOICE_ASSIST", label ="Voice", style = "style_Q" },
            { width = 3.5 },
            {
                click = "space1",
                width = 20,
                style = "style_Space",
                long_click = "Mode_switch",
                ascii = {
                    click = "space1",
                    label = "             Aa",
                    long_click = "Mode_switch",
                }
            },
            { click = ".", composing = "select_2", long_click = "?", width = 6, style = "style_Period" },
            { click = "Return1", width = 9, long_click = "\n", swipe_up = "Color_settings", swipe_down = "Theme_settings", style = "style_Enter" },
            { width = 1 }
        }
    }
}
