--中文输入法同文无障碍群【938020953】
--本皮肤为中文输入法2的皮肤
--上下左右符号为正向放置，长按符号显示在右滑符号上方
--1.AXCV长按——全选复制粘贴剪切（A=全选，X=剪切，C=复制，V=粘贴）
--2.Shift键上滑——切换方案，下滑——部署
--3.删除键左滑——清除，上滑——候选栏开关，下滑——助记开关
--4.G键长按——编辑键盘，滑动——光标移动脚本
--5.K键长按——常用括号（{}〈〉()《》[]【】），上滑切换键盘布局
--6.R键右滑——重复输入
--7.数字键长按——AI键
--8.回车键上滑——切换配色，回车键下滑——切换主题，回车键长按——换行
--9.空格键长按——切换中英，空格键滑动——移动光标
--10.底部左键emoji，右键语音

name = "26键"
author = "AZNixl"
key_width = 9.8
key_height = 22
lock = true
-- rows行键盘，宽度和高度为键盘总宽度的百分比
rows = {
    -- 第一行
    {
        keys = {
            { width = 1 },
            { click = "q", swipe_down = "1", long_click = "1", label = "Q", style = "style_Q" },
            { click = "w", swipe_down = "2", long_click = "2", label = "W", style = "style_W" },
            { click = "e", swipe_down = "3", long_click = "3", label = "E", style = "style_E" },
            { click = "r", swipe_down = "4", long_click = "4", swipe_right = "RepeatCommit", label = "R", style = "style_R" },
            { click = "t", swipe_down = "5", long_click = "5", label = "T", style = "style_T" },
            { click = "y", swipe_down = "6", long_click = "6", label = "Y", style = "style_Y" },
            { click = "u", swipe_down = "7", long_click = "7", label = "U", style = "style_U" },
            { click = "i", swipe_down = "8", long_click = "8", label = "I", style = "style_I" },
            { click = "o", swipe_down = "9", long_click = "9", label = "O", style = "style_O" },
            { click = "p", swipe_down = "0", long_click = "0", label = "P", style = "style_P" },
            { width = 1 }
        }
    },
    -- 第二行
    {
        keys = {
            { width = 5 },
            { click = "a", long_click = "select_all", label = "A", style = "style_A" },
            { click = "s", swipe_up = "ChineseDate", long_click = "-", label = "S", style = "style_S" },
            { click = "d", swipe_up = "Date", long_click = "@", label = "D", style = "style_D" },
            { click = "f", swipe_up = "Time", long_click = "#", label = "F", style = "style_F" },
            { click = "g", long_click = "Keyboard_editor", label = "G", style = "style_G" },
            { click = "h", long_click = "_", label = "H", style = "style_H" },
            { click = "j", long_click = "+", label = "J", style = "style_J" },
            { click = "k", long_click = "括号", swipe_up = "Keyboard_settings", label = "K", popup = {"{}{Left}", "〈〉{Left}", "(){Left}", "《》{Left}", "[]{Left}", "【】{Left}"}, style = "style_K" },
            { click = "l", long_click = "=", label = "L", style = "style_L" }
        }
    },
    -- 第三行
    {
        keys = {
            { width = 1 },
            { click = "Shift_L", width = 13.7, composing = "Escape", swipe_up = "Schema_settings", swipe_down = "Deploy", style = "style_off" },
            {width = 1},
            { click = "z", long_click = "`", label = "Z", style = "style_Z" },
            { click = "x", long_click = "cut", label = "X", style = "style_X" },
            { click = "c", long_click = "copy", label = "C", style = "style_C" },
            { click = "v", long_click = "paste", label = "V", style = "style_V" },
            { click = "b", long_click = "{", label = "B", style = "style_B" },
            { click = "n", long_click = "}", label = "N", style = "style_N" },
            { click = "m", long_click = ":", label = "M", swipe_up = "Keyboard_menu", style = "style_M" },
            {width = 1},
            { click = "BackSpace", width = 13.7, style = "style_Back" },
        { width = 1 },
        }
    },
    -- 第四行
    {
        keys = {
            { width = 1 },
            { click = "Keyboard_number", swipe_up = "Keyboard_symbols_en", long_click = "AI", popup = {"gpt1", "gpt2", "gpt5", "gpt3", "gpt4" }, width = 15, composing = "select_3", style = "style_Sym" },
            { click = ",", long_click = "!", width = 12, style = "style_Comma" },
            {
                click = "space1",
                width = 42,
                style = "style_Space",
                long_click = "Mode_switch",
                ascii = {
                    click = "space1",
                    label = "             Aa",
                    long_click = "Mode_switch",
                }
            },
            { click = ".", composing = "select_2", long_click = "?", width = 12, style = "style_Period" },
            { click = "Return1", width = 17, long_click = "\n", swipe_up = "Color_settings", swipe_down = "Theme_settings", style = "style_Enter" },
            { width = 1 }
        }
    },
    -- 第五行
    {
        height = 17,
        keys = {
            { click = "emoji", width = 25, style = "transparent_num" },
            { width = 50 },
            { click = "VOICE_ASSIST",  width = 25, style = "transparent_num" },
        }
    }
}
