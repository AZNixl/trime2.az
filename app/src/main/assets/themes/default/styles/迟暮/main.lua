name = "牛仔暮色"
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
background = 0xff000000
-- 键盘面板基础设置
keyboard = {
    height = 200,                      -- 键盘高度
    background = 0xff000000,           -- 键盘背景色
    font= "Gineso.ttf",                -- 字体
    --font={ "a.ttf", "b.ttf" }        -- 多字体示例
}

---------------------------------------------------------------------
-- 默认按键基础样式
---------------------------------------------------------------------
key = {
    text_color = 0xb9bcbcbc,        -- 文字颜色
    text_size = 20,                 -- 文字大小
    background = 0x7f3F51B5,        -- 按键背景
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
    bottom = 3                      -- 下间距
}

---------------------------------------------------------------------
-- 按键符号样式
---------------------------------------------------------------------
key.hint = {
    show = show_hints,              -- 是否显示符号
    text_color = 0xffbcbcbc,        -- 符号文字颜色
    text_size = 7                   -- 符号文字大小
}
key.hint.up = {
    show = show_hints,              -- 上方向符号开关
    text_color = 0xffbcbcbc,        -- 上方向符号颜色
    text_size = 7                   -- 上方向符号大小
}
key.hint.down = {
    show = show_hints,              -- 下方向符号开关
    text_color = 0xffbcbcbc,        -- 下方向符号颜色
    text_size = 7                   -- 下方向符号大小
}
key.hint.left = {
    show = show_hints,              -- 左方向符号开关
    text_color = 0xffbcbcbc,        -- 左方向符号颜色
    text_size = 7                   -- 左方向符号大小
}
key.hint.right = {
    show = show_hints,              -- 右方向符号开关
    text_color = 0xffbcbcbc,        -- 右方向符号颜色
    text_size = 7                   -- 右方向符号大小
}

---------------------------------------------------------------------
-- 按键长按提示样式
---------------------------------------------------------------------
key.long_click = {
    show = show_hints,              -- 是否显示长按提示
    text_color = 0xffbcbcbc,        -- 长按提示文字颜色
    text_size = 6,                  -- 长按提示文字大小
    vibration_enabled = true,        -- 长按震动开关
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
    background = 0xe73F51B5,        -- 按下背景色
    text_color = 0xffffffff,        -- 按下文字颜色
    hint = { text_color = 0xffbcbcbc }, -- 按下符号颜色
    long_click = { text_color = 0xffbcbcbc } -- 按下长按提示颜色
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
    background = 0x7f3F51B5,        -- 预览背景色
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
    background = 0xff3F51B5,        -- 键盘背景颜色或图片
    stroke_color = 0xb43F51B5,      -- 边框颜色
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
    background = 0xff000000,        -- 符号面板背景
    text_size = 22,                 -- 符号面板文字大小
    text_color = 0xffbcbcbc,        -- 符号面板文字颜色
    indicator_color = 0xFF3F51B5    -- 指示器颜色
}
symbol.text = table.clone(key)      -- 符号文本按键样式
symbol.key = {
    text_color = 0xffbcbcbc,        -- 符号按键文字颜色
    text_size = 18,                 -- 符号按键文字大小
    background = 0x7f3F51B5,        -- 符号按键背景
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
    background = 0xe73F51B5         -- 符号按键按下背景色
}

---------------------------------------------------------------------
-- 候选栏基础样式
---------------------------------------------------------------------
candidate = {
    height = 40,                    --候选栏高度
    background = 0xff000000,        --候栏背景色
    text_size = 18,                 --候选栏字号及悬浮窗字号(不含字母)
    text_color = 0xffbcbcbc,        --候选次选文本颜色
    elevation = 0,                  --候选栏阴影凸起
    shadow_color = 0x00000000,      --阴影
    --font = "a.ttf"                --候选栏及悬浮窗字体
}
candidate.pressed = {
    background = 0x003F51B5,        --候选首选背景
    text_color = 0xffffffff,       --候选首选文本颜色
    corner_radius = 0               --候选首选圆角
}
candidate.comment = {
    text_size = 15,                 --候选栏注释字号
    text_color = 0xffbcbcbc         --候选栏注释颜色
}
candidate.comment.pressed = {
    text_size = 15,                 --候选栏注释按下时字号
    text_color = 0xff444444         --候选栏注释按下时文本颜色
}

---------------------------------------------------------------------
-- 候选栏功能按键
---------------------------------------------------------------------
candidate.key = {
    text = "end2",                  --候选栏隐藏显示文本
    text_color = 0xb9bcbcbc,        --候选栏工具文本颜色
    text_size = 15,                 --候选栏工具字号
    background = 0xff000000,        --候选栏工具背景
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
    background = 0xe73F51B5         --候选栏工具按下背景
}

---------------------------------------------------------------------
-- 候选栏工具样式
---------------------------------------------------------------------
toolbar = table.clone(candidate)    --候选栏基础样式
toolbar.schema_switches = show_schema_switches --方案菜单
toolbar.hide = table.clone(candidate.key)  --隐藏按钮样式
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
toolbar.key.text_size = 23                --候选栏工具文本大小
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
    background = 0xff000000,        --展开候选面板背景
    text_size = 22,                 --展开候选面板字号
    text_color = 0xffbcbcbc         --展开候选面板文字颜色
}
candidate.expanded.pressed = {
    background = 0x7f3F51B5,        --展开候选面板按下背景
    ripple_color = 0x403F51B5       --展开候选面板波纹颜色
}
candidate.expanded.comment = {
    text_size = 15,                 --展开候选面板注释字号
    text_color = 0xffbcbcbc         --展开候选面板注释颜色
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
    text_color = 0xb9bcbcbc,        --预编辑文字颜色
    round_corner = 9,               --预编辑圆角
    background = 0xff000000,        --预编辑背景
    inline="input" --嵌入式编辑 input输入码,composition编码,preview首选项,none无
}
if show_composition then
  composition = {
    text_color = 0xb9ffffff,        --悬浮窗插入字符颜色(小箭头)
    text_size = 16,      --悬浮窗输入字母字号
    background = 0xff000000,      --悬浮窗背景
    position = "fixed", -- 默认：fixed，位置：left|right|left_up|right_up|fixed|bottom_left|bottom_right|top_left|top_right(left、right需要>=Android5.0)
    min_length = 1, -- 最小词长,超过字数的显示在悬浮窗
    max_length = 30, -- 超过字数则换行
    sticky_lines = 0, -- 固顶行数（0则横排显示）
    max_entries = 5, -- 最大词条数,-1表示显示全部
    all_phrases = false, -- 所有满足条件的词语都显示在窗口
    border = 0, -- 边框宽度
    max_width = 720, -- 最大宽度，超过则自动换行
    max_height = 10, -- 最大高度
    min_width = 60, -- 最小宽度
    min_height = 0, -- 最小高度
    padding = {
        left = 2,                   --左内边距
        top = 2,                    --上内边距
        right = 2,                  --右内边距
        bottom = 2                  --下内边距
    },
    line_spacing = 0, -- 候选词的行间距(px)
    line_spacing_multiplier = 1, -- 候选词的行间距(倍数)
    spacing = 5, -- 与预编辑或边缘的距离
    round_corner = 8, -- 窗口圆角
    elevation = 5, -- 阴影
    background = 0x2a000000, --悬浮窗编码背景色
    movable = "false", -- 是否可移动窗口，或仅移动一次 true|false|once


    pressed = {
        text_color = 0xb9bcbcbc,    --悬浮窗输入字母字体颜色
        background = 0xff000000     --悬浮窗输入字母背景色
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
   text_color = 0xffffffff       --悬浮窗候选序号文本颜色
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
enter.background = 0xa23F51B5        --回车背景
enter.text_color = 0xb9bcbcbc        --回车文字颜色
enter.pressed.background = 0xe73F51B5 --回车按下背景
enter.pressed.text_color = 0xffffffff --回车按下文字颜色
enter.preview = nil                  --关闭回车预览

-- 大圆角回车备用
enter2 = table.clone(enter)
enter2.corner_radius = 32            --大圆角
enter2.preview = nil                 --关闭预览

-- 功能键通用模板（Shift、删除、符号）
functional = table.clone(key)
functional.text_size = 18            --功能键字号
functional.background = 0x0f3F51B5   --功能键背景
functional.pressed.background = 0xe73F51B5 --功能键按下背景
functional.pressed.text_color = 0xff000000 --功能键按下文字颜色
functional.preview = nil             --关闭功能键预览

-- 标点键模板（逗号、句号）
period = table.clone(key)
period.text_size = 18                --标点键字号
period.background = 0x173F51B5       --标点键背景
period.pressed.background = 0xe73F51B5 --标点键按下背景
period.pressed.text_color = 0xff000000 --标点键按下文字颜色
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
transparent_num.text_color = 0xb9bcbcbc      --数字文字颜色
transparent_num.pressed = {
    scale_x = 0.95,                 --按下水平缩放
    scale_y = 0.95,                 --按下垂直缩放
    background = 0x00000000,        --按下透明背景
    stroke_color = 0x00000000,      --按下透明边框
    text_color = 0xffffffff,        --按下文字颜色
    hint = { text_color = 0xffffffff } --按下符号颜色
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
-- 26字母按键样式（按键背景色渐变）
---------------------------------------------------------------------
-- 继承基础样式并覆盖特定属性
local function inherit(base, overrides)
    return setmetatable(overrides or {}, { __index = base })
end
--设定渐变百分比
local bg_gradient = {0x17, 0x2e, 0x45, 0x5c, 0x73, 0x8b, 0xa2, 0xb9, 0xd0, 0xe7}

-- 生成字母按键样式表
local function make_letter_styles(letters, start_idx)
    local result = {}
    for i, ch in ipairs(letters) do
        local bg_val = bg_gradient[start_idx + i - 1]
        local bg_color = (bg_val << 24) + 0x3F51B5   --按键颜色
        local s = table.clone(key)
          s.background = bg_color
        result["style_" .. ch] = s
    end
    return result
end

--定义三排字母
local row1 = {"Q","W","E","R","T","Y","U","I","O","P"}  --第一排字母
local row2 = {"A","S","D","F","G","H","J","K","L"}      --第二排字母
local row3 = {"Z","X","C","V","B","N","M"}              --第三排字母
-- 生成样式表
local s1 = make_letter_styles(row1, 1)
local s2 = make_letter_styles(row2, 1)
local s3 = make_letter_styles(row3, 1)
-- 注入全局
for k, v in pairs(s1) do _G[k] = v end
for k, v in pairs(s2) do _G[k] = v end
for k, v in pairs(s3) do _G[k] = v end

-- 26字母按键单独定义示例
--style_X.font = "LOGO字体.ttf"    --文本字体
--style_X.text_size = 24           --文本大小
--style_X.text_color = 0xff333333  --文本颜色
--style_X.background = 0xff       -- 按键背景色

---------------------------------------------------------------------
--功能键颜色单独定义（带渐变）
---------------------------------------------------------------------
style_off = table.clone(functional) style_off.background = 0x0f3F51B5   --关闭键背景
style_Back = table.clone(functional) style_Back.background = 0xd03F51B5 --退格键背景
style_Sym = table.clone(functional) style_Sym.background = 0x0a3F51B5   --符号键背景
style_Comma = table.clone(period) style_Comma.background = 0x173F51B5   --逗号键背景
style_Space = table.clone(space) style_Space.background = 0x453F51B5    --空格键背景
style_Period = table.clone(period) style_Period.background = 0x733F51B5 --句号键背景
style_Enter = table.clone(enter) style_Enter.background = 0xa23F51B5    --回车键背景

---------------------------------------------------------------------
-- 键盘整体总高度
---------------------------------------------------------------------
height = keyboard.height + candidate.height  --键盘总高度 = 键盘高度 + 候选栏高度
