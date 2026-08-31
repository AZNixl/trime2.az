local About = [[
【功能列表】
• 本版新功能 增加白名单 只显示需要的功能 搜索白名单设置perset_keys
• 脚本适配暗色模式，支持手动切换，系统切换暗色模式
• 长按任意功能键 方向设置
• 脚本管理器配备黑名单，可排除不需要管理的脚本

【注意事项】
• 当前脚本仅支持 0.7.3+版
• 方向配置 =  left right top bottom

【使用方法】
1. 路径：rime/themes/你的主题/keyboards/menu.lua
2. 主题main.lua 添加
   keyboard_menu { label = "菜单", send = "Eisu_toggle", select = "menu" },

3. 按键中:click = "keyboard_menu"

【关于脚本】

    Copyright © 2026 zums | AZNixl Kimi K3修改
]]

import "android.view.*"
import "android.widget.*"
import "android.text.TextUtils"
import "android.app.AlertDialog"
import "com.androlua.LuaDialog"
import "com.androlua.LuaEditor"
import "android.graphics.Typeface"
import "android.graphics.drawable.GradientDrawable"
import "android.content.res.ColorStateList"
import "android.graphics.drawable.RippleDrawable"
import "android.os.VibrationEffect"

import "com.osfans.trime.Config"
import "com.osfans.trime.theme.ThemeManager"
import "androidx.core.widget.NestedScrollView"
import "androidx.appcompat.widget.ButtonBarLayout"

--右侧功能键部分
local gns = {
    {text = "返回", tag = "Keyboard_default"},
    {text = "输入法", tag = "IME_switch"},
    {text = "设置", tag = "Settings"},
    {text = "配色", tag = "Color_switch"},
    {text = "主题", tag = "Theme_settings"},
    {text = "脚本", tag = "__script_mgr"},  -- 脚本管理器（独立脚本开关）
}

local dir = Config.getKeyboardDir()
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local _, _, currentScriptDir, pureScriptName = scriptPath:find("(.*/)(.-)$")
local preset_keys = ThemeManager.getPresetKeys()

-- 配置文件路径 - 使用更安全的方式
local configPath
if currentScriptDir and currentScriptDir ~= "" then
    configPath = dir .. "/" .. currentScriptDir .. "menu_config.json"
else
    -- 如果无法获取目录，直接放在 keyboards 目录下
    configPath = dir .. "/menu_config.json"
end

import "org.json.JSONArray"
import "org.json.JSONObject"
import "java.io.File"
import "java.io.FileOutputStream"
import "java.io.OutputStreamWriter"
import "java.io.FileInputStream"
import "java.io.InputStreamReader"
import "java.io.BufferedReader"
import "java.io.BufferedWriter"
import "java.lang.StringBuilder"

-- ========== 按键震动功能 ==========
local function keyVibrate()
    pcall(function()
        local VEffect = VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE)
        ThemeManager.vibrate(VEffect)
    end)
end

-- 通用文件读写
local function readFile(filePath)
    if not filePath then return nil end
    local file = File(filePath)
    if not file.exists() then return nil end
    local stream = FileInputStream(file)
    local reader = BufferedReader(InputStreamReader(stream, "UTF-8"))
    local stringBuilder = StringBuilder()

    local ok = pcall(function()
        local line
        while true do
            line = reader.readLine()
            if line == nil then break end
            stringBuilder.append(line)
        end
    end)

    reader.close()
    stream.close()

    if not ok then return nil end
    return stringBuilder.toString()
end

local function saveFile(filePath, content)
    if not filePath then return end
    local ok = pcall(function()
        local file = File(filePath)
        local parent = file.getParentFile()
        if parent and not parent.exists() then
            parent.mkdirs()
        end
        local stream = FileOutputStream(file)
        local writer = BufferedWriter(OutputStreamWriter(stream, "UTF-8"))
        writer.write(content)
        writer.close()
        stream.close()
    end)
    if not ok then
        -- 保存失败时不静默：可按需替换为 this.sendMsg("配置保存失败")
    end
end

-- 通用保存：把整个 table 保存为 JSON
local function saveConfig(config)
    if not configPath then return end
    local json = JSONObject()
    for key, value in pairs(config) do
        if type(value) == "table" then
            local jsonArr = JSONArray()
            for _, item in ipairs(value) do
                jsonArr.put(item)
            end
            json.put(key, jsonArr)
        else
            json.put(key, value)
        end
    end
    saveFile(configPath, json.toString(4))
end

-- 通用加载：从文件加载 JSON 到 table
local function loadConfig()
    if not configPath then return {} end
    local content = readFile(configPath)
    if not content or content == "" then
        return {}
    end

    local success, json = pcall(function()
        return JSONObject(content)
    end)

    if not success then
        return {}
    end

    local config = {}
    local keys = json.keys()
    while keys.hasNext() do
        local key = keys.next()
        local value = json.get(key)

        local arr = json.optJSONArray(key)
        if arr then
            local list = {}
            for i = 0, arr.length() - 1 do
                table.insert(list, arr.getString(i))
            end
            config[key] = list
        else
            config[key] = tostring(value)
        end
    end
    return config
end

local cinf = {
    方向配置 = "right", -- left right top bottom
}

-- 加载已有配置
local loaded = loadConfig()
if next(loaded) then
    for key, value in pairs(loaded) do
        cinf[key] = value
    end
end

function setDirection(name)
    cinf["方向配置"] = name
    saveConfig(cinf)
end

local 布局设置 = cinf["方向配置"]
-- 配置值校验：旧配置/损坏配置可能存了非法值（会导致 switch 落到 default 报"布局错误"）
if 布局设置 ~= "left" and 布局设置 ~= "right" and 布局设置 ~= "top" and 布局设置 ~= "bottom" then
    布局设置 = "right"
end
--手动切换适配暗色主题，更改或增加样式文件夹名
--所有浅色样式名
local DARK_STYLES = {
    ["迟暮"] = true,
    ["暗夜"] = true,
}

local LIGHT_STYLES = {
    ["尘白"] = true,
    ["黎明"] = true,
}

local cs = {
    light = {
        btn = 0xFFF4F4F4,      -- 胶囊按钮（jqb 同款平板色）
        title = 0xFF30C190,    -- 分隔条（图片样式回退色；实际渲染时会加磨砂透明度）
        text = 0xFF1E2638,
        dlg = 0xFFE3E4E9,      -- 弹窗底板（jqb ClipBColor 浅色）
    },
    night = {
        btn = 0xCC232323,
        title = 0xFF30C190,
        text = 0xff9C9FA7,
        dlg = 0xFF181A1A,      -- 弹窗底板（jqb ClipBColor 深色）
    }
}

local dp2px  -- 前置声明（定义在下方）

-- 读取当前样式里 enter 键的 background 颜色
-- 走 trime2 自己的样式解析 API（ThemeManager.getStyle()），不解析文本：
--   background 是数字颜色 → 返回该颜色（Java int，luajava 自动带符号）
--   background 是图片文件名（字符串）→ getColor 的 optint 落到哨兵值 → 返回 nil（用默认色）
-- 读取失败 / 样式里没有 enter 表 → 返回 nil
local function getEnterBgColor()
    local SENTINEL = 0x01020304  -- 哨兵值：一个正常配色不会用的颜色
    local ok, result = pcall(function()
        local style = ThemeManager.getStyle()
        if not style then return nil, "getStyle()=nil" end
        local v = style.get("enter")
        if type(v) == "table" then
            -- trime2 的 Lua 环境是 luaj：样式表到脚本侧就是原生 Lua 表，直接读字段
            local bg = rawget(v, "background")
            if type(bg) == "number" then
                bg = math.floor(bg)
                if bg > 0x7FFFFFFF then bg = bg - 0x100000000 end -- 转 Java 有符号 int
                return bg, string.format("抓到 enter.background = 0x%08X", bg % 0x100000000)
            elseif type(bg) == "string" then
                return nil, "enter.background 是图片: " .. bg
            else
                return nil, "enter.background 未定义"
            end
        elseif type(v) == "userdata" then
            -- 备选：Java Style/KeyStyle 代理，走 getColor + 哨兵
            local ks = style.getKeyStyle("enter", style.getKeyStyle())
            if not ks then return nil, "enter KeyStyle 创建失败" end
            local c = ks.getColor("background", SENTINEL)
            if c == nil or c == SENTINEL then
                return nil, "enter.background 是图片或未定义"
            end
            return c, string.format("抓到 enter.background = 0x%08X", c % 0x100000000)
        else
            return nil, "样式里没有 enter 键样式"
        end
    end)
    local color, msg = result, nil
    if not ok then
        color, msg = nil, "异常: " .. tostring(result)
    end
    return color
end

local function getColors()
    local style = Config.getStyle()

    local base
    -- 样式名优先判断
    if DARK_STYLES[style] then base = cs.night
    elseif LIGHT_STYLES[style] then base = cs.light
    else
        -- 样式名不在名单里，才看系统UI
        local config = service.getResources().getConfiguration()
        if config.uiMode and config.uiMode > 30 then base = cs.night
        else base = cs.light end
    end

    -- 回车键颜色存 accent：给开关染色用（图片样式=nil，开关保持系统默认蓝）
    local t = {}
    for k, v in pairs(base) do t[k] = v end
    t.accent = getEnterBgColor()
    -- 分隔条=跟随回车键色 + 磨砂效果：只降不透明度，透出底色呈玻璃质感
    -- FROST_ALPHA 0x00(全透)-0xFF(不透)，越小越"磨砂"；回车键色自带透明度的直接保留
    local FROST_ALPHA = 0xBF  -- 75% 不透明，可调
    local barColor = t.accent or base.title
    local rgb = barColor % 0x1000000
    local srcAlpha = math.floor((barColor % 0x100000000) / 0x1000000)
    if srcAlpha >= 0xFF then  -- 只有纯色才加磨砂；原色自带透明度的尊重原色
        t.title = rgb + FROST_ALPHA * 0x1000000
    else
        t.title = barColor
    end
    return t
end

local CS = getColors()

local function gdDrawable(color, radius)
    local shape = GradientDrawable()
    shape.setShape(GradientDrawable.RECTANGLE)
    shape.setCornerRadius(radius or dp2px(14))  -- jqb 同款胶囊圆角
    if type(color) == "table" then
        shape.setColors(color)
    else
        shape.setColor(color or CS.btn)
    end
    shape.setStroke(0, 0x00000000)  -- 无描边（jqb 风格）
    return shape
end

-- 波纹效果
local function createRipple(colors, radius)
    local content = gdDrawable(colors, radius)
    local mask = gdDrawable(colors, radius)
    local rippleColor = ColorStateList.valueOf(0xFF69E4AD)
    return RippleDrawable(rippleColor, content, mask)
end

dp2px = function(dp)
    local metrics = this.getResources().getDisplayMetrics()
    return math.floor(dp * metrics.density + 0.5)
end

local ids, layout = {}, {
    LinearLayout;
    orientation="horizontal";
    layout_width = "fill";
    layout_height = "fill";
    id="container";
    {
        LinearLayout;
        orientation="vertical";
        layout_width = "fill";
        layout_height = "fill";
        gravity="center";
        id = "keys_container";
        {
            NestedScrollView;
            id="scrollView";
            layout_width = "fill";
            layout_height = "fill";
            {
                GridLayout;
                id = "gridLayout";
                layout_height = "fill";
                layout_width = "fill";
                alignmentMode = GridLayout.ALIGN_BOUNDS;
                orientation = GridLayout.HORIZONTAL;
                columnOrderPreserved = false;
                useDefaultMargins = true;
                rowCount = 4;
                columnCount = 4;

            };
        };
    };
}
layout = loadlayout(layout, ids)

local function params(width, height, weight)
    if weight then
        return LinearLayout.LayoutParams(width, height, weight)
    else
        return LinearLayout.LayoutParams(width, height)
    end
end

-- ============ 安全的类型检查函数 ============
local function safeGetField(value, field)
    if type(value) == "table" then
        return value[field]
    end
    return nil
end

local function safeGetSend(value)
    local send = safeGetField(value, "send")
    if type(send) == "string" then
        return send
    end
    return nil
end

local function safeGetCommand(value)
    local command = safeGetField(value, "command")
    if type(command) == "string" then
        return command
    end
    return nil
end
-------------------------------------------------------------------------------
-- 白名单设置---------------------------------------------------
---------------------------------------------------
local function make_set(list)
    local set = {}
    for _, key in ipairs(list) do
        set[key] = true
    end
    return set
end

-- 写入所需perset_keys
local menu_whitelist = make_set({
    "Schema_settings",
    "Schema_group",
    "Comment_switch",
    "Hint_switch",
    "Deploy",
    "ToolsManager",
    "Zdic",
    "Charset_switch",
    "Henkan",
    "chaifen_switch",
    "pinyin_switch",
    "logcat",
    "photocut",
    "restheme",
    "auto_land",
    "hover_set",
    "move_set",
    "all_switch",
})


local function safeGetToggle(value)
    local toggle = safeGetField(value, "toggle")
    if type(toggle) == "string" then
        return toggle
    end
    return nil
end

local function safeGetSelect(value)
    local select = safeGetField(value, "select")
    if type(select) == "string" then
        return select
    end
    return nil
end

local function safeGetText(value)
    local text = safeGetField(value, "text")
    if type(text) == "string" then
        return text
    end
    return nil
end

local function safeGetShiftLock(value)
    local shift_lock = safeGetField(value, "shift_lock")
    return shift_lock
end

local function safeGetCommit(value)
    local commit = safeGetField(value, "commit")
    if type(commit) == "string" then
        return commit
    end
    return nil
end

-- 分类配置表
local categoryConfig = {
    scripts = {
        displayName = "🧩 脚本.lua",
        order = 1,
        matcher = function(name, value)
            local cmd = safeGetCommand(value)
            return cmd and string.find(cmd, "%.lua") ~= nil
        end
    },
    rime_state = {
        displayName = "🔄 RIME状态切换",
        order = 2,
        matcher = function(name, value)
            local toggle = safeGetToggle(value)
            return toggle ~= nil
        end
    },
    keyboard_switch = {
        displayName = "⌨️ 键盘切换",
        order = 3,
        matcher = function(name, value)
            local select = safeGetSelect(value)
            local send = safeGetSend(value)
            return select ~= nil and send == "Eisu_toggle"
        end
    },
    trime_ai = {
        displayName = "AI",
        order = 4,
        matcher = function(name, value)
            local send = safeGetSend(value)
            local cmd = safeGetCommand(value)
            return send == "function" and cmd == "gpt"
        end
    },
    trime_setting = {
        displayName = "⚙️ 同文设置",
        order = 5,
        matcher = function(name, value)
            local settingSends = {
                ["LANGUAGE_SWITCH"] = true,
                ["PROG_RED"] = true,
                ["Menu"] = true,
                ["SETTINGS"] = true,
                ["Control+Shift+1"] = true
            }
            local send = safeGetSend(value)
            return send ~= nil and settingSends[send] == true
        end
    },
    rime_combo = {
        displayName = "🔣 RIME组合键",
        order = 6,
        matcher = function(name, value)
            local comboSends = {
                ["F4"] = true,
                ["Control+BackSpace"] = true,
                ["Control+Return"] = true,
                ["Shift+Return"] = true,
                ["Control+Shift+Return"] = true,
                ["Control+Delete"] = true
            }
            local send = safeGetSend(value)
            local text = safeGetText(value)
            return (send ~= nil and comboSends[send] == true) or (text ~= nil and text == "'")
        end
    },
    edit = {
        displayName = "✏️ 编辑功能",
        order = 7,
        matcher = function(name, value)
            local editSends = {
                ["BackSpace"] = true, ["space"] = true, ["Escape"] = true,
                ["Home"] = true, ["Insert"] = true, ["Delete"] = true,
                ["End"] = true, ["Page_Up"] = true, ["Page_Down"] = true,
                ["Left"] = true, ["Right"] = true, ["Up"] = true,
                ["Down"] = true, ["Return"] = true, ["BACK"] = true
            }

            local send = safeGetSend(value)
            local text = safeGetText(value)
            local shift_lock = safeGetShiftLock(value)
            local hasEditSend = send ~= nil and editSends[send] == true
            local hasControlPattern = send ~= nil and (
                string.find(send, "Control") or
                string.find(send, "Shift") or
                string.find(send, "Alt")
            )
            local hasLowerCase = send ~= nil and string.match(send, "^[a-z]+$")

            return text ~= nil or
                shift_lock ~= nil or
                hasEditSend or
                hasControlPattern or
                hasLowerCase
        end
    },
    trime_command = {
        displayName = "🛠️ 同文命令",
        order = 8,
        matcher = function(name, value)
            local cmd = safeGetCommand(value)
            local commit = safeGetCommit(value)
            return (cmd ~= nil or commit ~= nil) and
                not (cmd and string.find(cmd, "%.lua"))
        end
    },
    android = {
        displayName = "📱 安卓系统功能",
        order = 9,
        matcher = function(name, value)
            local send = safeGetSend(value)
            return (send ~= nil and
                type(name) == "string" and
                string.match(name, "^[A-Z_]+$") and
                string.match(send, "^[A-Z_]+$")) or
                send == "Find"
        end
    },
    other = {
        displayName = "📦 其他",
        order = 10,
        matcher = function(name, value)
            return true
        end
    }
}

function valueFormatter(value)
    if type(value) == "table" then
        local items = {}
        for _, val in ipairs(value) do
            table.insert(items, '"' .. tostring(val):gsub('"', '\\"') .. '"')
        end
        return "{ " .. table.concat(items, ", ") .. " }"
    else
        return '"' .. tostring(value):gsub('"', '\\"') .. '"'
    end
end

function tableFormatter(name, value)
    local parts = {}
    for key, val in pairs(value) do
        local formattedVal = valueFormatter(val)
        table.insert(parts, string.format('%s = %s', key, formattedVal))
    end
    return ("    %s = {%s}\n"):format(name, table.concat(parts, ", "))
end

-- 创建分类标题按钮
local function createCategoryTitle(title, int)
    local textView = TextView(this)
    local params = GridLayout.LayoutParams()
    params.width = 0
    params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 4, 1) -- 占4列
    params.rowSpec = GridLayout.spec(GridLayout.UNDEFINED)
    textView.setLayoutParams(params)
    textView.setText(title .. "(" .. tostring(int) .. ")")
    textView.setTextSize(16)
    textView.setTextColor(CS.text)
    textView.setGravity(Gravity.CENTER)
    textView.setPadding(dp2px(8), dp2px(8), dp2px(8), dp2px(8))

    -- 设置背景
    local bg = GradientDrawable()
    bg.setShape(GradientDrawable.RECTANGLE)
    bg.setCornerRadius(dp2px(14))  -- jqb 同款胶囊圆角
    bg.setColor(CS.title)
    textView.setBackgroundDrawable(bg)

    return textView
end

-- 对按键进行分类（包含白名单拦截）
local function categorizeKeys()
    local categories = {}

    -- 准备分类规则
    local sortedCats = {}
    for catName, catConfig in pairs(categoryConfig) do
        if catName ~= "other" then
            table.insert(sortedCats, {name = catName, config = catConfig})
        end
    end
    table.sort(sortedCats, function(a, b)
        return a.config.order < b.config.order
    end)

    -- 遍历并处理按键
    for name, keys in pairs(preset_keys) do
        if type(name) == "string" then
            -- 🛡️ 白名单拦截：只有在 menu_whitelist 中的键才会被处理
            if menu_whitelist[name] then
                local categorized = false

                -- 尝试匹配分类
                for _, cat in ipairs(sortedCats) do
                    if cat.config.matcher and cat.config.matcher(name, keys) then
                        if not categories[cat.name] then
                            categories[cat.name] = {}
                        end
                        table.insert(categories[cat.name], {name = name, data = keys})
                        categorized = true
                        break
                    end
                end

                -- 没匹配到具体分类，则放入"其他"
                if not categorized then
                    if not categories.other then
                        categories.other = {}
                    end
                    table.insert(categories.other, {name = name, data = keys})
                end
            end
        end
    end

    return categories
end

function updateRimeState(keyData)
    if not keyData.toggle then return end

    local isOption = this.getRime().getRimeOption(keyData.toggle)
    local states = keyData.states
    if states then
        if keyData.toggle == "ascii_mode" then
            return (isOption and states[2] or states[1])
        elseif keyData.toggle == "simplification" then
            return (isOption and states[1] or states[2])
        else
            return (isOption and states[2] or states[1])
        end
        return nil
    end
end


-- 开关染色：选中态跟随回车键颜色（CS.accent），未选中保持系统默认
-- accent=nil（图片样式）时不染色
local function tintSwitch(sw)
    local accent = CS.accent
    if not accent then return end
    local function apply()
        pcall(function()
            local PorterDuff = luajava.bindClass("android.graphics.PorterDuff")
            if sw.isChecked() then
                sw.getThumbDrawable().setColorFilter(accent, PorterDuff.Mode.SRC_IN)
                -- 轨道用同色 40% 透明
                local trackColor = (accent % 0x1000000) + 0x66000000
                sw.getTrackDrawable().setColorFilter(trackColor, PorterDuff.Mode.SRC_IN)
            else
                sw.getThumbDrawable().clearColorFilter()
                sw.getTrackDrawable().clearColorFilter()
            end
        end)
    end
    apply()
end

function createKeySwitch()
    local self = {}
    local layout = loadlayout({
        LinearLayout;
        layout_height = "fill";
        orientation = "vertical";
        layout_width = "fill";
        gravity = "center";
        padding="2dp";
        {
            Switch;
            id = "mswitch";
            singleLine = true;
            textSize = 10;
        };
        {
            CheckedTextView;
            id = "states";
            text = "有助记";
            singleLine = true;
            textSize = 10;
            gravity = "center";
        };
        {
            TextView;
            id = "toggle";
            text = "_hide_candidate";
            singleLine = true;
            textSize = 10;
            gravity = "center";
        };
    },self)

    self.getView = function()
        return layout
    end

    self.setText = function(str)
        self.mswitch.setText(str)
    end

    self.setStatesText = function(str)
        self.states.setText(str)
        self.states.setTextColor(CS.text)
        self.mswitch.setSwitchMinWidth(150)
        self.mswitch.setSwitchPadding(0)
    end

    self.setToggleText = function(str)
        self.toggle.setText(str)
    end

    self.setChecked = function(checked)
        self.mswitch.setChecked(checked)
        self.states.setChecked(checked)
    end

    self.isChecked = function()
        return self.mswitch.isChecked()
    end

    -- 使用标志位防止循环触发
    local isUpdating = false

    self.mswitch.setOnCheckedChangeListener(function(buttonView, isChecked)
        keyVibrate()  -- ⭐ 添加震动
        tintSwitch(self.mswitch)  -- 开关染色（跟随回车键色）
        if not isUpdating and self.onCheckedChanged then
            isUpdating = true
            self.onCheckedChanged(isChecked)
            isUpdating = false
        end
    end)
    tintSwitch(self.mswitch)  -- 初始染色

    layout.setOnClickListener(function(view)
        keyVibrate()  -- ⭐ 添加震动
        if not isUpdating then
            isUpdating = true
            local newState = not self.mswitch.isChecked()
            self.setChecked(newState)
            if self.onCheckedChanged then
                self.onCheckedChanged(newState)
            end
            isUpdating = false
        end
    end)

    return self
end

function keyboardBack()
    this.setKeyboard(com.osfans.trime.Config.getKeyboard())
    this.updateInputViewShown()
end

function createKeyButton(keyInfo)
    local name, keyData = keyInfo.name, keyInfo.data
    local button = nil
    local text = nil
    if keyData.states then
        local KeySwitch = createKeySwitch()
        button = KeySwitch.getView()

        local statesText = updateRimeState(keyData)
        local isOption = this.getRime().getRimeOption(keyData.toggle)
        KeySwitch.setChecked(isOption)
        KeySwitch.setStatesText(statesText)
        KeySwitch.setToggleText(keyData.toggle)

        KeySwitch.onCheckedChanged = function(isChecked)
            this.sendEvent(name)
            local statesText = updateRimeState(keyData)
            KeySwitch.setStatesText(statesText)
        end
    else
        button = Button(this)
        local text = keyData.label or name
        button.setText(text)
        button.setTextSize(12)
        button.setSingleLine(true)
        button.setPadding(0, 0, 0, 0)
        button.setEllipsize(TextUtils.TruncateAt.END)
        button.setTextColor(CS.text)
        button.onClick = function(view)
            keyVibrate()  -- ⭐ 添加震动
            this.sendEvent(name)
            processAll()
        end
    end
    button.setTag(name)

    local params = GridLayout.LayoutParams()
    params.width = 0
    params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1, 1)
    params.rowSpec = GridLayout.spec(GridLayout.UNDEFINED)
    button.setLayoutParams(params)
    button.setBackgroundDrawable(createRipple())
    -- 开关键是普通 LinearLayout，没有 Button 自带的 elevation：
    -- 补上与其他按钮一致的阴影，视觉统一
    pcall(function() button.setElevation(dp2px(2)) end)

    button.onCreateContextMenu = function(menu, view, menuInfo)
        menu.setHeaderTitle("选择操作")
        menu.add("表")
        for k, v in pairs(keyData) do
            if type(v) == "table" then
                v = valueFormatter(v)
            else
                v = string.format('"%s"', v)
            end
            local str = string.format("%s = %s", k, v)
            menu.add(str)
        end

        menu.setCallback({
            onMenuItemSelected=function(menu,item)
                local title = item.getTitle()
                switch title
                case "表"
                    local valueStr = tableFormatter(name, keyData)
                    this.commitText(valueStr)
                default
                    this.commitText(title)
                end
            end
        })
    end

    return button
end

function processAll()
    if not preset_keys then return end

    CS = getColors()  -- 每次重建界面时重新取配色，避免菜单开着时切换深浅色模式后颜色不刷新
    ids.gridLayout.removeAllViews()

    -- 对按键进行分类
    local categories = categorizeKeys()

    -- 获取排序后的分类列表
    local sortedCategories = {}
    for catName, catData in pairs(categories) do
        table.insert(sortedCategories, {
            name = catName,
            data = catData,
            order = categoryConfig[catName] and categoryConfig[catName].order or 999
        })
    end

    -- 按order排序
    table.sort(sortedCategories, function(a, b)
        return a.order < b.order
    end)

    -- 渲染每个分类
    for _, catInfo in ipairs(sortedCategories) do
        local displayName = categoryConfig[catInfo.name] and
        categoryConfig[catInfo.name].displayName or
        catInfo.name

        -- 添加分类标题
        ids.gridLayout.addView(createCategoryTitle(displayName, #catInfo.data))

        -- 添加该分类下的按键
        for _, keyInfo in ipairs(catInfo.data) do
            ids.gridLayout.addView(createKeyButton(keyInfo))
        end
    end
end

processAll()

local function openSettingsManager()
    local Intent = luajava.bindClass("android.content.Intent")
    local intent = Intent()

    intent.setClassName("com.nirenr.trime", "com.osfans.trime.PrefLauncher")
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    service.startActivity(intent)
end


local finishDialog  -- 前置声明（定义在下方）

-- ========== 脚本管理器：独立脚本开关（改后重载主题生效） ==========
-- 配置 rime/scripts_disabled.json：反向记录，只存【被关闭】的脚本文件名；
-- 不在清单里 = 开（默认全开，符合直觉）
local RIME_DIR = "/storage/emulated/0/Documents/rime/"
local SCRIPTS_CFG = RIME_DIR .. "scripts_disabled.json"

-- 脚本管理器黑名单，不列入管理器的文件，按需补充
local SM_EXCLUDE = {
    ["rime.lua"] = true,
    ["nongli.lua"] = true,
    ["工具箱.lua"] = true,
}

-- 扫描目录：rime/scripts + 当前主题 themes/<主题>/scripts（其他主题不读）
local function smScriptDirs()
    local dirs = { RIME_DIR .. "scripts/AZ" }
    pcall(function()
        local sp = PreferenceManager.getDefaultSharedPreferences(this)
        local theme = sp.getString("theme", "")
        if theme ~= "" then
            table.insert(dirs, RIME_DIR .. "themes/" .. theme .. "/scripts/")
        end
    end)
    return dirs
end

local function smListScripts()
    local seen, names = {}, {}
    local File = luajava.bindClass("java.io.File")
    for _, dir in ipairs(smScriptDirs()) do
        pcall(function()
            local files = File(dir).listFiles()
            if files then
                for i = 0, files.length - 1 do
                    local n = tostring(files[i].getName())
                    if n:match("%.lua$") and not SM_EXCLUDE[n] and not seen[n] then
                        seen[n] = true
                        table.insert(names, n)
                    end
                end
            end
        end)
    end
    table.sort(names)
    return names
end

local function smLoadDisabled()
    local disabled = {}
    pcall(function()
        local f = luajava.newInstance("java.io.File", SCRIPTS_CFG)
        if f.exists() then
            local JsonUtil = luajava.bindClass("com.osfans.trime.JsonUtil")
            local list = JsonUtil.load(f)
            if list then
                for i = 0, list.size() - 1 do disabled[tostring(list.get(i))] = true end
            end
        end
    end)
    return disabled
end

local function smSaveDisabled(disabled)
    pcall(function()
        local JsonUtil = luajava.bindClass("com.osfans.trime.JsonUtil")
        local list = luajava.newInstance("java.util.ArrayList")
        for n, off in pairs(disabled) do
            if off then list.add(n) end
        end
        JsonUtil.save(luajava.newInstance("java.io.File", SCRIPTS_CFG), list)
    end)
end

function showScriptManager()
    local names = smListScripts()
    if #names == 0 then
        pcall(function() this.sendMsg("scripts 目录里没有 .lua 脚本") end)
        return
    end
    local disabled = smLoadDisabled()
    local function isOn(n) return not disabled[n] end  -- 默认全开

    local dlg = LuaDialog(this)
    -- 不用系统标题栏，标题放进卡片里（与方向弹窗统一）

    local root = LinearLayout(this)
    root.setOrientation(1)
    root.setPadding(dp2px(16), dp2px(12), dp2px(16), dp2px(12))
    root.setBackgroundDrawable(gdDrawable(CS.dlg, dp2px(16)))  -- 弹窗底板（jqb 风格）

    local titleTv = TextView(this)
    titleTv.setText("脚本管理（重载生效）")
    titleTv.setTextSize(16)
    titleTv.setTextColor(CS.text)
    titleTv.setGravity(17)
    root.addView(titleTv, LinearLayout.LayoutParams(-1, dp2px(32)))

    local scroll = ScrollView(this)
    local box = LinearLayout(this)
    box.setOrientation(1)
    scroll.addView(box)
    root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1))

    for _, n in ipairs(names) do
        local row = LinearLayout(this)
        row.setOrientation(0)
        row.setGravity(16)
        local tv = TextView(this)
        tv.setText(n)
        tv.setTextSize(14)
        tv.setTextColor(CS.text)
        row.addView(tv, LinearLayout.LayoutParams(0, -2, 1))
        local sw = Switch(this)
        sw.setChecked(isOn(n))
        sw.setOnCheckedChangeListener(function(v, checked)
            if checked then disabled[n] = nil else disabled[n] = true end
            smSaveDisabled(disabled)
            tintSwitch(sw)  -- 开关染色（跟随回车键色）
        end)
        tintSwitch(sw)  -- 初始染色
        row.addView(sw)
        row.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(12)))  -- 开关行=胶囊卡片
        row.setPadding(dp2px(10), 0, dp2px(10), 0)
        local rowLp = LinearLayout.LayoutParams(-1, dp2px(44))
        rowLp.setMargins(0, dp2px(3), 0, dp2px(3))
        box.addView(row, rowLp)
    end

    -- 底部按钮行
    local btnRow = LinearLayout(this)
    btnRow.setOrientation(0)
    btnRow.setGravity(17)
    local function mkBtn(text, weight)
        local b = Button(this)
        b.setText(text)
        b.setTextSize(14)
        b.setTextColor(CS.text)
        b.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(12)))
        local lp = LinearLayout.LayoutParams(0, dp2px(42), weight)
        lp.setMargins(dp2px(4), dp2px(8), dp2px(4), dp2px(4))
        b.setLayoutParams(lp)
        return b
    end
    local btnReload = mkBtn("重载主题", 1)
    btnReload.onClick = function()
        keyVibrate()
        -- 主题名用 Config.getTheme()（官方主题对话框同款来源）；
        -- this.setTheme() 同时重跑入口 main.lua + 重建键盘 UI
        pcall(function() this.setTheme(tostring(Config.getTheme())) end)
        pcall(function() dlg.hide() end)
    end
    local btnClose = mkBtn("关闭", 1)
    btnClose.onClick = function() pcall(function() dlg.hide() end) end
    btnRow.addView(btnReload)
    btnRow.addView(btnClose)
    root.addView(btnRow)

    dlg.setView(root)
    dlg.show()
    finishDialog(dlg, 320)
end


-- ========== 方向选择弹窗（jqb 风格，与脚本管理器统一） ==========
-- 弹窗统一收尾：窗口背景透明（圆角生效）+ 宽度收敛（默认撑满屏太宽）
finishDialog = function(dlg, widthDp)
    pcall(function()
        local win = dlg.getWindow()
        local ColorDrawable = luajava.bindClass("android.graphics.drawable.ColorDrawable")
        win.setBackgroundDrawable(ColorDrawable(0x00000000))
        win.setLayout(dp2px(widthDp or 300), -2)  -- 高 wrap_content
    end)
end

function showDirectionPicker()
    local dlg = LuaDialog(this)
    -- 不用系统标题栏（默认样式和卡片不统一），标题放进卡片里

    local root = LinearLayout(this)
    root.setOrientation(1)
    root.setPadding(dp2px(16), dp2px(12), dp2px(16), dp2px(12))
    root.setBackgroundDrawable(gdDrawable(CS.dlg, dp2px(16)))

    local titleTv = TextView(this)
    titleTv.setText("选择方向")
    titleTv.setTextSize(16)
    titleTv.setTextColor(CS.text)
    titleTv.setGravity(17)
    root.addView(titleTv, LinearLayout.LayoutParams(-1, dp2px(32)))

    -- 当前方向高亮用标题绿
    local dirs = {
        { label = "左侧", value = "left" },
        { label = "右侧", value = "right" },
        { label = "顶部", value = "top" },
        { label = "底部", value = "bottom" },
    }
    for i, d in ipairs(dirs) do
        local b = Button(this)
        b.setText(d.label)
        b.setTextSize(15)
        local cur = (布局设置 == d.value)
        b.setTextColor(cur and 0xFFFFFFFF or CS.text)
        b.setBackgroundDrawable(gdDrawable(cur and CS.title or CS.btn, dp2px(12)))
        local lp = LinearLayout.LayoutParams(-1, dp2px(44))
        lp.setMargins(0, dp2px(4), 0, dp2px(4))
        b.setLayoutParams(lp)
        b.onClick = function()
            keyVibrate()
            setDirection(d.value)
            布局设置 = d.value
            FunctionButtonBuilder()
            pcall(function() dlg.hide() end)
        end
        root.addView(b)
    end

    dlg.setView(root)
    dlg.show()
    finishDialog(dlg, 280)
end

function addBtn(bar, h, isVertical)
    for i, t in ipairs(gns) do
        local btn = Button(this)

        local btnParams
        if isVertical then
            -- 垂直模式（top/bottom）：按钮宽度权重1，高度固定
            btnParams = LinearLayout.LayoutParams(0, h or dp2px(40), 1)
        else
            -- 水平模式（left/right）：按钮宽度固定，高度权重1
            btnParams = LinearLayout.LayoutParams(dp2px(55), 0, 1)
        end
        btnParams.setMargins(dp2px(2), dp2px(2), dp2px(2), dp2px(2))
        btn.setLayoutParams(btnParams)
        btn.setPadding(0, 0, 0, 0)
        btn.setText(t.text)
        btn.setTextSize(11)
        btn.setTextColor(CS.text)
        btn.setBackgroundDrawable(createRipple())
        btn.setSingleLine(true)
        btn.setGravity(Gravity.CENTER)

        btn.onClick = function()
            keyVibrate()  -- ⭐ 添加震动
            if t.tag == "Settings" then
                openSettingsManager()
            elseif t.tag == "__script_mgr" then
                showScriptManager()
            else
                this.sendEvent(t.tag)
            end
        end
        -- 长按弹出方向选择（jqb 风格弹窗，与脚本管理器统一）
        btn.onLongClick = function()
            keyVibrate()
            showDirectionPicker()
            return true
        end
        bar.addView(btn)
    end
end

-- 功能按钮构建
function FunctionButtonBuilder()
    CS = getColors()  -- 同步刷新配色
    local childCount = ids.container.getChildCount()
    for i = 0, childCount - 1 do
        local child = ids.container.getChildAt(i)
        if child ~= ids.keys_container then
            ids.container.removeView(child)
        end
    end

    local bar = LinearLayout(this)
    bar.setOrientation(LinearLayout.VERTICAL)  -- 左右模式时垂直排列

    switch 布局设置
    case "left"
        ids.container.setOrientation(LinearLayout.HORIZONTAL)
        ids.keys_container.setLayoutParams(LinearLayout.LayoutParams(0, -1, 1))
        bar.setLayoutParams(LinearLayout.LayoutParams(-2, -1))  -- wrap_content, match_parent
        ids.container.addView(bar, 0)
        addBtn(bar, -1, false)
    case "right"
        ids.container.setOrientation(LinearLayout.HORIZONTAL)
        ids.keys_container.setLayoutParams(LinearLayout.LayoutParams(0, -1, 1))
        bar.setLayoutParams(LinearLayout.LayoutParams(-2, -1))
        ids.container.addView(bar)
        addBtn(bar, -1, false)
    case "top"
        ids.container.setOrientation(LinearLayout.VERTICAL)
        ids.keys_container.setLayoutParams(LinearLayout.LayoutParams(-1, 0, 1))
        bar.setOrientation(LinearLayout.HORIZONTAL)  -- 上下模式时水平排列
        bar.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
        ids.container.addView(bar, 0)
        addBtn(bar, dp2px(44), true)
    case "bottom"
        ids.container.setOrientation(LinearLayout.VERTICAL)
        ids.keys_container.setLayoutParams(LinearLayout.LayoutParams(-1, 0, 1))
        bar.setOrientation(LinearLayout.HORIZONTAL)
        bar.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
        ids.container.addView(bar)
        addBtn(bar, dp2px(44), true)
    default
        print("menu:", "布局错误")
    end

    ids.container.requestLayout()
    ids.container.invalidate()
end

FunctionButtonBuilder()

return layout
