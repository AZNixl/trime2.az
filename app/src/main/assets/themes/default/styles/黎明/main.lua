name = "春芽初醒"
author = "AZNixl"

---------------------------------------------------------------------
-- 全局开关 true=显示 / false=隐藏
---------------------------------------------------------------------
local show_hints = true              -- 符号开关
local show_composition = false         -- 悬浮窗开关
local show_key_preview = false        -- 按键预览开关
local show_schema_switches = false     -- 候选栏方案菜单开关

---------------------------------------------------------------------
-- 全局背景与键盘基础参数
---------------------------------------------------------------------
-- 键盘整体背景色
background = 0xffe9eaee
-- 键盘面板基础设置
keyboard = {
    height = 200,                      -- 键盘高度
    background = 0x00dddddd,           -- 键盘背景色
    font= "Gineso.ttf",                -- 字体
    --font={ "a.ttf", "b.ttf" }        -- 多字体示例
}

---------------------------------------------------------------------
-- 默认按键基础样式
---------------------------------------------------------------------
key = {
    text_color = 0xb91a1a1a,        -- 文字颜色
    text_size = 20,                 -- 文字大小
    background = 0xfffdfdff,        -- 按键背景
    elevation = 1,                  -- 阴影凸起
    corner_radius = 4,              -- 按键圆角
    shadow_color = 0xff000000,      -- 阴影颜色
    long_click_time = 180,          -- 长按触发时间
    repeat_click_time = 100,        -- 重复点击间隔
    vibration_enabled = true,       -- 点击震动
    vibration_effect = {
           {100},                   -- 震动时长
             {255}                  -- 震动强度
    },
    --font = "a.ttf"
}

---------------------------------------------------------------------
-- 按键间距
---------------------------------------------------------------------
key.margins = {
    left = 2,                       -- 左间距
    top = 2,                        -- 上间距
    right = 1,                      -- 右间距
    bottom = 2                      -- 下间距
}

---------------------------------------------------------------------
-- 按键符号样式
---------------------------------------------------------------------
key.hint = {
    show = show_hints,              -- 是否显示符号
    text_color = 0xffa0aec8,        -- 符号文字颜色
    text_size = 7                   -- 符号文字大小
}
key.hint.up = {
    show = show_hints,              -- 上方向符号开关
    text_color = 0xffa0aec8,        -- 上方向符号颜色
    text_size = 7                   -- 上方向符号大小
}
key.hint.down = {
    show = show_hints,              -- 下方向符号开关
    text_color = 0xffa0aec8,        -- 下方向符号颜色
    text_size = 7                   -- 下方向符号大小
}
key.hint.left = {
    show = show_hints,              -- 左方向符号开关
    text_color = 0xffa0aec8,        -- 左方向符号颜色
    text_size = 7                   -- 左方向符号大小
}
key.hint.right = {
    show = show_hints,              -- 右方向符号开关
    text_color = 0xffa0aec8,        -- 右方向符号颜色
    text_size = 7                   -- 右方向符号大小
}

---------------------------------------------------------------------
-- 按键长按提示样式
---------------------------------------------------------------------
key.long_click = {
    show = show_hints,              -- 是否显示长按提示
    text_color = 0xffa0aec8,        -- 长按提示文字颜色
    text_size = 6,                  -- 长按提示文字大小
    vibration_enabled = true,       -- 长按震动开关
    --gravity = "right",               -- 长按符号位置
    offset_x = 8,                  -- 符号位置偏移
    offset_y = 11
}

---------------------------------------------------------------------
-- 按键按下状态样式
---------------------------------------------------------------------
key.pressed = {
    scale_x = 0.9,                  -- 按下水平缩放
    scale_y = 0.9,                  -- 按下垂直缩放
    translation_z = 8,              -- 按下Z轴偏移
    translation_x = 0,              -- 按下X轴偏移
    translation_y = 0,              -- 按下Y轴偏移
    shadow_color = 0xff00ffff,      -- 按下阴影颜色
    background = 0xff888888,        -- 按下背景色
    text_color = 0xffffffff,        -- 按下文字颜色
    hint = { text_color = 0xff444444 }, -- 按下符号颜色
    long_click = { text_color = 0xff444444 } -- 按下长按提示颜色
}

---------------------------------------------------------------------
-- 按键预览弹窗
---------------------------------------------------------------------
if show_key_preview then
  key.preview = {
    scale_x = 1.2,                  -- 宽度缩放
    scale_y = 1.2,                  -- 高度缩放
    text_color = 0xff2d3748,        -- 预览文字颜色
    text_size = 22,                 -- 预览文字大小
    background = 0x7ff5f5f7,        -- 预览背景色
    elevation = 16,                 -- 预览阴影凸起
    corner_radius = 16,             -- 预览圆角
    stroke_color = 0x88dddddd,      -- 边框颜色
    stroke_width = 1,               -- 边框宽度
    shadow_color = 0xffff0000       -- 预览阴影颜色
}
else
   key.preview = nil                -- 关闭按键预览
end

---------------------------------------------------------------------
--弹出键盘
---------------------------------------------------------------------
popup = {
    elevation = 8,                 -- 弹出键盘阴影凸起
    corner_radius = 4,              -- 弹出键盘圆角
    background = 0xb938383a,        -- 键盘背景颜色或图片
    stroke_color = 0xb438383a,      -- 边框颜色
    stroke_width = 5,               -- 边框宽度
    shadow_color = 0xb9000000       -- 弹出键盘阴影颜色
}
popup.key=table.clone(key)          -- 克隆基础按键样式
popup.key.text_size = 13            -- 弹出按键文字大小
popup.key.width = 10                -- 弹出按键宽度
popup.key.height = 15               -- 弹出按键高度
popup.key.preview=nil               -- 关闭弹出按键预览



---------------------------------------------------------------------
-- 符号面板样式
---------------------------------------------------------------------
symbol = {
    background = 0xffdddddd,        -- 符号面板背景
    text_size = 22,                 -- 符号面板文字大小
    text_color = 0xff000000,        -- 符号面板文字颜色
    indicator_color = 0xFF0055FF    -- 指示器颜色
}
symbol.text = table.clone(key)      -- 符号文本按键样式
symbol.key = {
    text_color = 0xff000000,        -- 符号按键文字颜色
    text_size = 18,                 -- 符号按键文字大小
    background = 0xffeeeeee,        -- 符号按键背景
    elevation = 2,                  -- 符号按键阴影
    corner_radius = 8,              -- 符号按键圆角
    shadow_color = 0x800000ff       -- 符号按键阴影颜色
}
symbol.key.pressed = {
    scale_x = 0.9,                  -- 符号按键按下水平缩放
    scale_y = 0.9,                  -- 符号按键按下垂直缩放
    translation_z = -1,             -- 符号按键按下Z轴偏移
    translation_x = 0,              -- 符号按键按下X轴偏移
    translation_y = 0,              -- 符号按键按下Y轴偏移
    shadow_color = 0xff00ffff,      -- 符号按键按下阴影颜色
    background = 0xffaaaaaa,        -- 符号按键按下背景色
}

---------------------------------------------------------------------
-- 候选栏基础样式
---------------------------------------------------------------------
candidate = {
    height = 40,                    --候选栏高度
    background = 0xffe9eaee,        --候栏背景色
    text_size = 18,                 --候选栏字号及悬浮窗字号(不含字母)
    text_color = 0xff000000,        --候选次选文本颜色
    elevation = 0,                  --候选栏阴影凸起
    shadow_color = 0x00000000,      --阴影
    --font = "a.ttf"                --候选栏及悬浮窗字体
}
candidate.pressed = {
    background = 0x00888888,        --候选首选背景
    text_color = 0xff000000,       --候选首选文本颜色
    corner_radius = 0,              --候选首选圆角
}
candidate.comment = {
    text_size = 15,                 --候选栏注释字号
    text_color = 0xff444444         --候选栏注释颜色
}
candidate.comment.pressed = {
    text_size = 15,                 --候选栏注释按下时字号
    text_color = 0xff444444         --候选栏注释按下时文本颜色
}

---------------------------------------------------------------------
-- 候选栏功能按键
---------------------------------------------------------------------
candidate.key = {
    text="end2",                    --候选栏隐藏显示文本
    text_color = 0xb4000000,        --候选栏工具文本颜色
    text_size = 15,                 --候选栏工具字号
    background = 0xffe9eaee,        --候选栏工具背景
    elevation = 0,                  --候选栏工具阴影
    corner_radius = 8,              --候选栏工具圆角
    shadow_color = 0x00000000,      --候选栏工具阴影颜色
    send = "Schema_switch"          --发送指令
}
candidate.key.pressed = {
    scale_x = 0.9,                  --候选栏工具按下水平缩放
    scale_y = 0.9,                  --候选栏工具按下垂直缩放
    translation_z = 2,              --候选栏工具按下Z轴偏移
    shadow_color = 0xff00ffff,      --候选栏工具按下阴影颜色
    background = 0xffaaaaaa,        --候选栏工具按下背景
}

---------------------------------------------------------------------
-- 候选栏工具样式
---------------------------------------------------------------------
toolbar = table.clone(candidate)              --候选栏基础样式
toolbar.schema_switches = show_schema_switches--方案菜单
toolbar.hide = table.clone(candidate.key)     --隐藏按钮样式
--候选栏工具按键
toolbar.keys = {
                "Keyboard_menu",
                "/",
                "undo",
                "Keyboard_editor",
                "redo",
                "jtb",
                "logcat"
                }
toolbar.key.text_size = 23                    --候选栏工具文本大小
--候选栏工具边距调整
toolbar.key.padding = {
                      left=5,
                      top=5,
                      right=8,
                      bottom=0
                      }

---------------------------------------------------------------------
-- 展开候选面板样式
---------------------------------------------------------------------
candidate.expanded = {
    background = 0xffdddddd,        --展开候选面板背景
    text_size = 22,                 --展开候选面板字号
    text_color = 0xff000000,        --展开候选面板文字颜色
}
candidate.expanded.pressed = {
    background = 0xffffffff,        --展开候选面板按下背景
    ripple_color = 0x40000000,      --展开候选面板波纹颜色
}
candidate.expanded.comment = {
    text_size = 15,                 --展开候选面板注释字号
    text_color = 0xff444444         --展开候选面板注释颜色
}
candidate.expanded.key = table.clone(symbol.key)        --展开候选面板按键样式
candidate.expanded.key.pressed = table.clone(symbol.key.pressed) --展开候选面板按键按下样式

---------------------------------------------------------------------
-- 剪贴板面板样式
---------------------------------------------------------------------
clipboard = table.clone(candidate.expanded)  --克隆展开候选样式
clipboard.item = table.clone(key)            --剪贴板条目样式
clipboard.item.text_size = 14                --剪贴板条目字号
clipboard.item.padding = { left=4, top=4, right=4, bottom=4 } --剪贴板条目内边距
clipboard.tool_bar = {
    gravity = "right", --left,top,right,bottom  --工具栏位置
    keys = { "hide", "page_up", "page_down", "undo" } --工具栏按钮
}

---------------------------------------------------------------------
-- 悬浮窗样式
---------------------------------------------------------------------
preedit = {
    text_size = 0,                 --预编辑字号
    text_color = 0xff000000,        --预编辑文字颜色
    round_corner = 9,               --预编辑圆角
    background = 0xfff2f3f5,        --预编辑背景x
    inline="input" --嵌入式编辑 input输入码,composition编码,preview首选项,none无
}
if show_composition then
  composition = {
    text_color = 0xff000000,        --悬浮窗插入字符颜色(小箭头)
    text_size = 16,      --悬浮窗输入字母字号
    background = 0xff000000,      --悬浮窗背景
    position = "fixed", -- 默认：fixed，位置：left|right|left_up|right_up|fixed|bottom_left|bottom_right|top_left|top_right(left、right需要>=Android5.0)
    min_length = 1, -- 最小词长,超过字数的显示在悬浮窗
    max_length = 60, -- 超过字数则换行
    sticky_lines = 0, -- 固顶行数（0则横排显示）
    max_entries = 5, -- 最大词条数,-1表示显示全部
    all_phrases = false, -- 所有满足条件的词语都显示在窗口
    border = 5, -- 边框宽度
    max_width = 720, -- 最大宽度，超过则自动换行
    max_height = 10, -- 最大高度
    min_width = 70, -- 最小宽度
    min_height = 0, -- 最小高度
    padding = {
        left = 2,                   --左内边距
        top = 2,                    --上内边距
        right = 2,                  --右内边距
        bottom = 2                  --下内边距
    },
    line_spacing = 1, -- 候选词的行间距(px)
    line_spacing_multiplier = 1, -- 候选词的行间距(倍数)
    spacing = 5, -- 与预编辑或边缘的距离
    round_corner = 8, -- 窗口圆角
    elevation = 5, -- 阴影
    background = 0x2affffff, --悬浮窗编码背景色（小箭头）
    movable = "false", -- 是否可移动窗口，或仅移动一次 true|false|once


    pressed = {
        text_color = 0xff000000,    --悬浮窗输入字母字体颜色
        background = 0xfff2f3f5     --悬浮窗输入字母背景色
    },
    window = {
        -- 悬浮窗口组件
        {
            start = "",
            move = " ",
            ["end"] = ""
        },
        {
            start = "",
            composition = "%s",
            ["end"] = "",
            letter_spacing = 0
        },
        {
            start = "\n",
            label = "%s.",
            candidate = "%s",
            comment = " %s",
            ["end"] = "",
            sep = " "
        }
    }
}


--悬浮窗候选序号定义
composition.key=table.clone(key)
composition.key.hint={
   text_size = 15,                --悬浮窗候选序号文本大小
   text_color = 0xff000000       --悬浮窗候选序号文本颜色
}
composition.key.pressed = {}      --首选序号触发开关

else
  composition = nil                  --关闭悬浮窗
end

---------------------------------------------------------------------
-- 通用按键模板
---------------------------------------------------------------------
-- 空格键基础样式
space = table.clone(key)
space.text_size = 18                 --空格字号

-- 回车键基础样式
enter = table.clone(key)
enter.text_size = 20                 --回车字号
enter.background = 0xb907c160        --回车背景
enter.text_color = 0xb9ffffff       --回车文字颜色
enter.pressed.background = 0xff1565C0 --回车按下背景
enter.pressed.text_color = 0xffffffff --回车按下文字颜色
enter.preview = nil                  --关闭回车预览

-- 大圆角回车备用
enter2 = table.clone(enter)
enter2.corner_radius = 32            --大圆角
enter2.preview = nil                 --关闭预览

-- 功能键通用模板（Shift、删除、符号）
functional = table.clone(key)
functional.text_size = 18            --功能键字号
functional.background = 0x2ea0aec8   --功能键背景
functional.pressed.background = 0xff888888 --功能键按下背景
functional.pressed.text_color = 0xff1a1a1a --功能键按下文字颜色
functional.preview = nil             --关闭功能键预览

-- 标点键模板（逗号、句号）
period = table.clone(key)
period.text_size = 18                --标点键字号
period.background = 0x2ea0aec8       --标点键背景
period.pressed.background = 0xff888888 --标点键按下背景
period.pressed.text_color = 0xff1a1a1a --标点键按下文字颜色
period.preview = nil                 --关闭标点键预览

---------------------------------------------------------------------
-- 透明数字键样式，文本显示按键隐藏
---------------------------------------------------------------------
transparent_num = table.clone(key)
transparent_num.background = 0x00000000      --透明背景
transparent_num.stroke_color = 0x00000000    --透明边框
transparent_num.elevation = 0                --无阴影
transparent_num.shadow_color = 0x00000000    --无阴影颜色
transparent_num.text_size = 22               --数字字号
transparent_num.text_color = 0xb91a1a1a      --数字文字颜色
transparent_num.pressed = {
    scale_x = 0.95,                 --按下水平缩放
    scale_y = 0.95,                 --按下垂直缩放
    background = 0x00000000,        --按下透明背景
    stroke_color = 0x00000000,      --按下透明边框
    text_color = 0xffffffff,        --按下文字颜色
    hint = {text_color = 0xffffffff} --按下符号颜色
}
transparent_num.preview = nil        --关闭预览

---------------------------------------------------------------------
-- 完全隐藏按键样式（剪贴板、语音）
---------------------------------------------------------------------
hide_key = table.clone(key)
hide_key.background = 0x00000000     --完全透明背景
hide_key.stroke_color = 0x00000000   --完全透明边框
hide_key.text_color = 0x00000000     --完全透明文字
hide_key.elevation = 0               --无阴影
hide_key.shadow_color = 0x00000000   --无阴影颜色
hide_key.pressed = table.clone(hide_key) --按下状态相同
hide_key.preview = nil               --关闭预览

---------------------------------------------------------------------
-- 按键独立定义
---------------------------------------------------------------------
-- 继承基础样式
local function inherit(base)
    return setmetatable({}, {__index = base})
end

-- 定义26个字母按键
local letter_keys = {"Q","W","E","R","T","Y","U","I","O","P","A","S","D","F","G","H","J","K","L","Z","X","C","V","B","N","M"}
for _, key_name in ipairs(letter_keys) do
    _G["style_" .. key_name] = table.clone(key)
end

-- 26字母按键单独定义示例
--style_X.font = "LOGO字体.ttf"    --文本字体
--style_X.text_size = 24           --文本大小
--style_X.text_color = 0xff333333  --文本颜色
--style_X.background = 0xff       -- 按键背景色

---------------------------------------------------------------------
-- 功能键
---------------------------------------------------------------------
style_off   = table.clone(functional)   --关闭键样式
style_Back  = table.clone(functional)   --退格键样式
style_Sym   = table.clone(functional)   --符号键样式
style_Comma = table.clone(period)       --逗号键样式
style_Period = table.clone(period)      --句号键样式
style_Space = table.clone(space)        --空格键样式
style_Enter = table.clone(enter)        --回车键样式

---------------------------------------------------------------------
-- 键盘整体总高度
---------------------------------------------------------------------
height = keyboard.height + candidate.height  --键盘总高度 = 键盘高度 + 候选栏高度
