------------------------------------------------------------------
-- 全局开关.lua v3（震动 + 长按触发时间设置）
-- 作者: AZNixl
-- 把样式 main.lua 顶部的全局开关（show_hints 等）做成弹窗快速切换，
-- 并新增震动与长按设置：按键震动 / 长按震动开关，
--   震动时长 / 震动强度 / 长按触发时间（50~1000ms）滚动条。
-- 原理：开关是样式文件里的变量/字段，运行期改不了内存，
--   只能改写文件中对应行 + 重载主题，效果与手动改文件完全等同。
--   写盘前做语法验证，坏了不写。
--   注意：key 块与 key.long_click 块各有 vibration_enabled 字段，
--   脚本按作用域分别定位修改，互不干扰。
-- 安装：本文件放 rime/scripts/，在 preset_keys 里配置触发
--   （与「悬浮窗设置」同款接法，执行本脚本即弹出开关面板）
------------------------------------------------------------------

import "android.widget.*"
import "android.view.*"
import "android.graphics.drawable.ColorDrawable"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.drawable.RippleDrawable"
import "android.graphics.Color"
import "android.content.res.ColorStateList"
import "com.androlua.LuaDialog"

local this = rawget(_G, "this") or luajava.bindClass("com.osfans.trime.TrimeService").getInstance()
local ThemeManager = luajava.bindClass("com.osfans.trime.theme.ThemeManager")
local Config = luajava.bindClass("com.osfans.trime.Config")

-- 要管的开关：变量名（须与样式 main.lua 顶部一致）+ 显示名
local SWITCHES = {
    { var = "show_hints",           label = "符号（含长按符号）" },
    { var = "show_composition",     label = "悬浮窗" },
    { var = "show_key_preview",     label = "按键预览" },
    { var = "show_schema_switches", label = "候选栏方案菜单" },
}

------------------------------------------------------------------
-- 样式文件读写
------------------------------------------------------------------
local function stylePath()
    local p = "/storage/emulated/0/Documents/rime/themes/"
        .. tostring(Config.getTheme()) .. "/styles/"
        .. tostring(Config.getStyle()) .. "/main.lua"
    local f = io.open(p, "r")
    if f then f:close() return p end
    return nil
end

local function readFileText(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- 读各开关当前值：匹配 `local 变量名 = true/false`
local function readSwitches(text)
    local r = {}
    for _, s in ipairs(SWITCHES) do
        local v = text:match("local%s+" .. s.var .. "%s*=%s*(%a+)")
        if v then r[s.var] = (v == "true") end
    end
    return r
end

------------------------------------------------------------------
-- 震动配置读写（作用域定位，key 块 / long_click 块分开处理）
------------------------------------------------------------------
-- 样式里两处 vibration_enabled = true：
--   key = { ... vibration_enabled, vibration_effect = { {时长}, {强度} } ... }
--   key.long_click = { ... vibration_enabled ... }
-- 定位策略：key 块 = [行首"key = {"  → "key.margins = {"）
--           long_click 块 = ["key.long_click = {" → 其后第一个 "key.pressed = {"）

-- 读取：返回 {enabled, long_click, duration, strength, long_click_time}（找不到为 nil）
local function readVibration(text)
    local r = { enabled = nil, long_click = nil, duration = nil, strength = nil, long_click_time = nil }
    -- key 块
    local ks = text:find("\nkey%s*=%s*{") or text:find("^key%s*=%s*{")
    local ke = text:find("key%.margins%s*=%s*{")
    if ks and ke and ke > ks then
        local seg = text:sub(ks, ke)
        local v = seg:match("vibration_enabled%s*=%s*(%a+)")
        if v then r.enabled = (v == "true") end
        local t = seg:match("long_click_time%s*=%s*(%d+)")
        if t then r.long_click_time = tonumber(t) end
        local es = seg:find("vibration_effect%s*=%s*{")
        if es then
            local d, s = seg:sub(es):match("{%s*(%d+)%s*}.-{%s*(%d+)%s*}")
            if d then r.duration = tonumber(d) end
            if s then r.strength = tonumber(s) end
        end
    end
    -- long_click 块
    local ls = text:find("key%.long_click%s*=%s*{")
    if ls then
        local le = text:find("key%.pressed%s*=%s*{", ls)
        if le and le > ls then
            local v = text:sub(ls, le):match("vibration_enabled%s*=%s*(%a+)")
            if v then r.long_click = (v == "true") end
        end
    end
    return r
end

-- 在 key 块内改写 vibration_enabled / vibration_effect / long_click_time（返回新文本、修改数）
local function patchKeyBlock(text, vib)
    local ks = text:find("\nkey%s*=%s*{") or text:find("^key%s*=%s*{")
    local ke = text:find("key%.margins%s*=%s*{")
    if not (ks and ke and ke > ks) then return text, 0 end
    local seg = text:sub(ks, ke)
    local total = 0
    -- 震动开关
    if vib.enabled ~= nil then
        seg, total = seg:gsub("(vibration_enabled%s*=%s*)%a+", "%1" .. tostring(vib.enabled), 1)
    end
    -- 长按触发时间（整数毫秒）
    if vib.long_click_time ~= nil then
        seg, total = seg:gsub("(long_click_time%s*=%s*)%d+", "%1" .. tostring(vib.long_click_time), 1)
    end
    -- 震动时长/强度（vibration_effect 表里第 1/2 个 {数字}）
    if vib.duration ~= nil or vib.strength ~= nil then
        local es = seg:find("vibration_effect%s*=%s*{")
        if es then
            local head = seg:sub(1, es - 1)
            local tail = seg:sub(es)
            local targets = {}
            if vib.duration ~= nil then targets[1] = vib.duration end
            if vib.strength ~= nil then targets[2] = vib.strength end
            local count = 0
            tail = tail:gsub("({%s*)(%d+)(%s*})", function(a, b, c)
                count = count + 1
                if targets[count] then
                    total = total + 1
                    return a .. tostring(targets[count]) .. c
                end
                return a .. b .. c
            end)
            seg = head .. tail
        end
    end
    if total > 0 then
        return text:sub(1, ks - 1) .. seg .. text:sub(ke + 1), total
    end
    return text, 0
end

-- 在 long_click 块内改写 vibration_enabled（返回新文本、修改数）
local function patchLongClickBlock(text, vib)
    if vib.long_click == nil then return text, 0 end
    local ls = text:find("key%.long_click%s*=%s*{")
    if not ls then return text, 0 end
    local le = text:find("key%.pressed%s*=%s*{", ls)
    if not (le and le > ls) then return text, 0 end
    local seg = text:sub(ls, le)
    local ns, n = seg:gsub("(vibration_enabled%s*=%s*)%a+", "%1" .. tostring(vib.long_click), 1)
    if n > 0 then
        return text:sub(1, ls - 1) .. ns .. text:sub(le + 1), n
    end
    return text, 0
end

-- 合并所有修改，返回新文本（不写盘）
local function buildText(text, state, vib)
    for _, s in ipairs(SWITCHES) do
        if state[s.var] ~= nil then
            text = text:gsub("(local%s+" .. s.var .. "%s*=%s*)%a+",
                "%1" .. tostring(state[s.var]), 1)
        end
    end
    text = patchKeyBlock(text, vib)
    text = patchLongClickBlock(text, vib)
    return text
end

------------------------------------------------------------------
-- jqb 同款配色与控件辅助（与 悬浮窗设置/menu 一致）
------------------------------------------------------------------
local function dp2px(dp)
    return math.floor(dp * this.getResources().getDisplayMetrics().density + 0.5)
end

local DARK_STYLES = { ["迟暮"] = true, ["暗夜"] = true }
local LIGHT_STYLES = { ["尘白"] = true, ["黎明"] = true }

local cs = {
    light = { btn = 0xFFF4F4F4, text = 0xFF1E2638, sub = 0xFF7A8090, dlg = 0xFFE3E4E9, line = 0xFFC9CCD2 },
    night = { btn = 0xCC232323, text = 0xff9C9FA7, sub = 0xFF6A7079, dlg = 0xFF181A1A, line = 0xFF3A3D3F },
}

local function getEnterBgColor()
    local SENTINEL = 0x01020304
    local ok, result = pcall(function()
        local style = ThemeManager.getStyle()
        if not style then return nil end
        local v = style.get("enter")
        if type(v) == "table" then
            local bg = rawget(v, "background")
            if type(bg) == "number" then
                bg = math.floor(bg)
                if bg > 0x7FFFFFFF then bg = bg - 0x100000000 end
                return bg
            end
            return nil
        elseif type(v) == "userdata" then
            local ks = style.getKeyStyle("enter", style.getKeyStyle())
            if not ks then return nil end
            local c = ks.getColor("background", SENTINEL)
            if c == nil or c == SENTINEL then return nil end
            return c
        end
        return nil
    end)
    return ok and result or nil
end

local function getColors()
    local style = Config.getStyle()
    local base
    if DARK_STYLES[style] then base = cs.night
    elseif LIGHT_STYLES[style] then base = cs.light
    else
        local c = this.getResources().getConfiguration()
        if c.uiMode and c.uiMode > 30 then base = cs.night else base = cs.light end
    end
    local t = {}
    for k, v in pairs(base) do t[k] = v end
    t.accent = getEnterBgColor()
    return t
end

local CS = getColors()
local ACCENT = CS.accent or 0xFF30C190

local function gdDrawable(color, radius)
    local shape = GradientDrawable()
    shape.setShape(GradientDrawable.RECTANGLE)
    shape.setCornerRadius(radius or dp2px(14))
    shape.setColor(color or CS.btn)
    shape.setStroke(0, 0x00000000)
    return shape
end

local function createRipple(color, radius)
    local content = gdDrawable(color, radius)
    local mask = gdDrawable(color, radius)
    return RippleDrawable(ColorStateList.valueOf(0xFF69E4AD), content, mask)
end

local function tintSwitch(sw)
    if not CS.accent then return end
    pcall(function()
        local PorterDuff = luajava.bindClass("android.graphics.PorterDuff")
        if sw.isChecked() then
            sw.getThumbDrawable().setColorFilter(CS.accent, PorterDuff.Mode.SRC_IN)
            sw.getTrackDrawable().setColorFilter((CS.accent % 0x1000000) + 0x66000000, PorterDuff.Mode.SRC_IN)
        else
            sw.getThumbDrawable().clearColorFilter()
            sw.getTrackDrawable().clearColorFilter()
        end
    end)
end

local function tintSeek(seek)
    pcall(function()
        local PorterDuff = luajava.bindClass("android.graphics.PorterDuff")
        seek.getProgressDrawable().setColorFilter(ACCENT, PorterDuff.Mode.SRC_IN)
        seek.getThumb().setColorFilter(ACCENT, PorterDuff.Mode.SRC_IN)
    end)
end

------------------------------------------------------------------
-- 弹窗
------------------------------------------------------------------
local path = stylePath()
if not path then
    print("全局开关：找不到样式文件 main.lua")
    return
end
local text = readFileText(path)
if not text then
    print("全局开关：样式文件读取失败")
    return
end
local state = readSwitches(text)
local vib = readVibration(text)

local dlg = LuaDialog(this)

local function tv(text, size, color, bold)
    local t = TextView(this)
    t.setText(text)
    t.setTextSize(size)
    t.setTextColor(color)
    if bold then t.getPaint().setFakeBoldText(true) end
    return t
end

local function divider()
    local v = View(this)
    v.setBackgroundColor(CS.line)
    local lp = LinearLayout.LayoutParams(-1, dp2px(1))
    lp.setMargins(dp2px(4), dp2px(10), dp2px(4), dp2px(10))
    v.setLayoutParams(lp)
    return v
end

local function switchRow(label, checked, onChange)
    local row = LinearLayout(this)
    row.setOrientation(LinearLayout.HORIZONTAL)
    row.setGravity(Gravity.CENTER_VERTICAL)
    row.setPadding(dp2px(12), dp2px(2), dp2px(12), dp2px(2))
    row.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(14)))
    row.addView(tv(label, 14, CS.text), LinearLayout.LayoutParams(0, -2, 1))
    local sw = Switch(this)
    sw.setChecked(checked)
    tintSwitch(sw)
    sw.setOnCheckedChangeListener(luajava.createProxy("android.widget.CompoundButton$OnCheckedChangeListener", {
        onCheckedChanged = function(_, c) onChange(c) tintSwitch(sw) end,
    }))
    row.addView(sw)
    return row
end

local function seekRow(parent, label, min, max, getVal, setVal)
    local row = LinearLayout(this)
    row.setOrientation(LinearLayout.HORIZONTAL)
    row.setGravity(Gravity.CENTER_VERTICAL)
    row.addView(tv(label, 13, CS.text), LinearLayout.LayoutParams(dp2px(72), -2))
    local valTv = tv(tostring(getVal()), 13, CS.sub)
    valTv.setGravity(Gravity.CENTER)
    local seek = SeekBar(this)
    seek.setMax(max - min)
    seek.setProgress(math.max(0, math.min(max - min, (getVal() or min) - min)))
    tintSeek(seek)
    seek.setOnSeekBarChangeListener(luajava.createProxy("android.widget.SeekBar$OnSeekBarChangeListener", {
        onProgressChanged = function(_, progress, _)
            local v = min + progress
            setVal(v)
            valTv.setText(tostring(v))
        end,
        onStartTrackingTouch = function() end,
        onStopTrackingTouch = function() end,
    }))
    row.addView(seek, LinearLayout.LayoutParams(0, -2, 1))
    row.addView(valTv, LinearLayout.LayoutParams(dp2px(44), -2))
    parent.addView(row)
end

local root = LinearLayout(this)
root.setOrientation(LinearLayout.VERTICAL)
root.setPadding(dp2px(16), dp2px(14), dp2px(16), dp2px(10))
root.setBackgroundDrawable(gdDrawable(CS.dlg, dp2px(16)))

local title = tv("全局开关", 17, CS.text, true)
title.setPadding(dp2px(4), 0, 0, dp2px(10))
root.addView(title)

-- 中间可滚动区（内容多时防超高）
local scroll = ScrollView(this)
scroll.setVerticalScrollBarEnabled(false)
local col = LinearLayout(this)
col.setOrientation(LinearLayout.VERTICAL)
scroll.addView(col)
root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1))

-- ① 显示开关区
local found = 0
for _, s in ipairs(SWITCHES) do
    if state[s.var] ~= nil then
        found = found + 1
        local row = switchRow(s.label, state[s.var], function(c) state[s.var] = c end)
        local lp = LinearLayout.LayoutParams(-1, -2)
        lp.setMargins(0, dp2px(3), 0, dp2px(3))
        col.addView(row, lp)
    end
end
if found == 0 then
    col.addView(tv("样式 main.lua 里没匹配到任何开关变量", 13, CS.text))
end

-- ② 震动与长按设置区
col.addView(divider())
local vibTitle = tv("震动与长按", 13, CS.sub, true)
vibTitle.setPadding(dp2px(4), dp2px(2), 0, dp2px(6))
col.addView(vibTitle)

if vib.enabled == nil and vib.long_click == nil and vib.long_click_time == nil then
    col.addView(tv("样式 key 块未找到震动/长按字段", 13, CS.text))
else
    local lp = LinearLayout.LayoutParams(-1, -2)
    lp.setMargins(0, dp2px(3), 0, dp2px(3))
    if vib.enabled ~= nil then
        col.addView(switchRow("按键震动", vib.enabled, function(c) vib.enabled = c end), lp)
    end
    if vib.long_click ~= nil then
        col.addView(switchRow("长按震动", vib.long_click, function(c) vib.long_click = c end), lp)
    end
    local seekCard = LinearLayout(this)
    seekCard.setOrientation(LinearLayout.VERTICAL)
    seekCard.setPadding(dp2px(12), dp2px(6), dp2px(12), dp2px(6))
    seekCard.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(14)))
    local seekLp = LinearLayout.LayoutParams(-1, -2)
    seekLp.setMargins(0, dp2px(3), 0, dp2px(3))
    col.addView(seekCard, seekLp)
    if vib.long_click_time ~= nil then
        seekRow(seekCard, "长按触发时间(ms)", 50, 1000,
            function() return vib.long_click_time end,
            function(v) vib.long_click_time = v end)
    end
    if vib.duration ~= nil then
        seekRow(seekCard, "震动时长(ms)", 1, 300,
            function() return vib.duration end,
            function(v) vib.duration = v end)
    end
    if vib.strength ~= nil then
        seekRow(seekCard, "震动强度", 1, 255,
            function() return vib.strength end,
            function(v) vib.strength = v end)
    end
end

-- 按钮行
local btnRow = LinearLayout(this)
btnRow.setOrientation(LinearLayout.HORIZONTAL)
btnRow.setPadding(0, dp2px(10), 0, dp2px(4))

local function makeBtn(text, bg, tc)
    local b = Button(this)
    b.setText(text)
    b.setTextColor(tc)
    b.setTextSize(14)
    b.setBackgroundDrawable(createRipple(bg, dp2px(14)))
    return b
end

local btnSave = makeBtn("保存并重载", ACCENT, 0xFFFFFFFF)
btnSave.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
    onClick = function()
        local newText = buildText(text, state, vib)
        local loader = loadstring or load
        local ok = pcall(function() assert(loader(newText, "@style_main")) end)
        if not ok then
            print("全局开关：保存失败（语法验证未通过，未写入）")
            return
        end
        local wf = io.open(path, "w")
        if not wf then
            print("全局开关：保存失败（无法写入文件）")
            return
        end
        wf:write(newText)
        wf:close()
        dlg.dismiss()
        pcall(function()
            this.setTheme(tostring(Config.getTheme()))
        end)
    end,
}))
btnRow.addView(btnSave, LinearLayout.LayoutParams(0, -2, 1))

local spacer = View(this)
btnRow.addView(spacer, LinearLayout.LayoutParams(dp2px(10), 1))

local btnCancel = makeBtn("取消", CS.btn, CS.text)
btnCancel.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
    onClick = function() dlg.dismiss() end,
}))
btnRow.addView(btnCancel, LinearLayout.LayoutParams(0, -2, 1))

root.addView(btnRow)

dlg.setView(root)
dlg.show()
pcall(function()
    local win = dlg.getWindow()
    if win then
        win.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        -- 高度取屏幕 72%，中间区可滚动，避免内容超高溢出
        local h = math.floor(this.getResources().getDisplayMetrics().heightPixels * 0.72)
        win.setLayout(dp2px(320), h)
    end
end)
