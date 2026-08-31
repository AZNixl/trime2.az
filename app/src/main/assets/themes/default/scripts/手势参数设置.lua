------------------------------------------------------------------
-- 手势参数设置（命令脚本 · trime2 ）
   AZNixl | Kimi K3
------------------------------------------------------------------
-- 【功能】一个弹窗管理内置手势的可调参数：
--   · 退格键滑动删除：每字步距、接管阈值
--   · 空格滑动移动光标：水平/垂直灵敏度、接管阈值、左右滑动选区
--
-- 【原理】手势行为已内置到源码（KeyGestures），参数存
--   SharedPreferences，保存后立即生效，无需重载主题。
--
-- 【绑定】move_set = { label = "手势参数", command = "手势参数设置.lua" }
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

------------------------------------------------------------------
-- 参数存储：手势行为已内置到源码，参数存 SharedPreferences
------------------------------------------------------------------
local PreferenceManager = luajava.bindClass("android.preference.PreferenceManager")
local prefs = PreferenceManager.getDefaultSharedPreferences(this)

local SCRIPTS = {
    {
        name = "退格键滑动删除（内置）",
        params = {
            { key = "gesture_bs_step",      label = "每字步距",  min = 16, max = 80, def = 51 },
            { key = "gesture_bs_threshold", label = "接管阈值",  min = 5,  max = 60, def = 60 },
        },
    },
    {
        name = "空格滑动移动光标（内置）",
        params = {
            { key = "gesture_space_hs",        label = "水平灵敏度", min = 10, max = 80, def = 70 },
            { key = "gesture_space_vs",        label = "垂直灵敏度", min = 5,  max = 60, def = 46 },
            { key = "gesture_space_threshold", label = "接管阈值",   min = 5,  max = 50, def = 15 },
        },
        selectKeys = { "gesture_space_select_edge" },  -- 左右滑动选区（开=0.4 边缘，关=0）
    },
}

-- 加载当前值 → work[脚本索引][param索引] = 数值
local work, scriptPaths = {}, {}
local function loadAll()
    for si, sc in ipairs(SCRIPTS) do
        scriptPaths[si] = true  -- 内置功能始终可用
        work[si] = {}
        for pi, p in ipairs(sc.params) do
            work[si][pi] = prefs.getInt(p.key, p.def)
        end
        if sc.selectKeys then
            work[si].selectOn = prefs.getFloat(sc.selectKeys[1], 0) > 0
        end
    end
end

-- 保存：写入 SharedPreferences，立即生效；返回字段数与缺失列表（恒空）
local function saveAll()
    local total = 0
    local e = prefs.edit()
    for si, sc in ipairs(SCRIPTS) do
        for pi, p in ipairs(sc.params) do
            e.putInt(p.key, math.floor(work[si][pi] + 0.5))
            total = total + 1
        end
        if sc.selectKeys then
            e.putFloat(sc.selectKeys[1], work[si].selectOn and 0.4 or 0)
            total = total + 1
        end
    end
    e.apply()
    return total, {}
end

------------------------------------------------------------------
-- jqb 同款配色（与 menu.lua 一致；分隔线灰，滚动条/按钮跟随回车）
------------------------------------------------------------------
local ThemeManager = luajava.bindClass("com.osfans.trime.theme.ThemeManager")
local Config = luajava.bindClass("com.osfans.trime.Config")

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

local function dp2px(dp)
    return math.floor(dp * this.getResources().getDisplayMetrics().density + 0.5)
end

local function gdDrawable(color, radius)
    local shape = GradientDrawable()
    shape.setShape(GradientDrawable.RECTANGLE)
    shape.setCornerRadius(radius or dp2px(14))
    shape.setColor(color or CS.btn)
    shape.setStroke(0, 0x00000000)
    return shape
end

local function createRipple(color, radius)
    return RippleDrawable(ColorStateList.valueOf(0xFF69E4AD), gdDrawable(color, radius), gdDrawable(color, radius))
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
-- 界面
------------------------------------------------------------------
loadAll()

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

local root = LinearLayout(this)
root.setOrientation(LinearLayout.VERTICAL)
root.setPadding(dp2px(16), dp2px(14), dp2px(16), dp2px(10))
root.setBackgroundDrawable(gdDrawable(CS.dlg, dp2px(16)))

local title = tv("手势参数设置", 17, CS.text, true)
title.setPadding(dp2px(4), 0, 0, dp2px(6))
root.addView(title)

local scroll = ScrollView(this)
local col = LinearLayout(this)
col.setOrientation(LinearLayout.VERTICAL)
scroll.addView(col)
root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1))

-- 三个脚本分区
for si, sc in ipairs(SCRIPTS) do
    if si > 1 then col.addView(divider()) end

    local h = tv(sc.name, 13, CS.sub, true)
    h.setPadding(dp2px(4), dp2px(6), 0, dp2px(6))
    col.addView(h)

    local cardView = LinearLayout(this)
    cardView.setOrientation(LinearLayout.VERTICAL)
    cardView.setPadding(dp2px(12), dp2px(6), dp2px(12), dp2px(6))
    cardView.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(14)))
    col.addView(cardView)

    if not scriptPaths[si] then
        cardView.addView(tv("未找到 " .. sc.file .. "（本区设置不会生效）", 13, CS.text))
    else
        -- 左右滑动选区开关（有 selectKeys 的分区才有）
        if sc.selectKeys then
            local swRow = LinearLayout(this)
            swRow.setOrientation(LinearLayout.HORIZONTAL)
            swRow.setGravity(Gravity.CENTER_VERTICAL)
            swRow.setPadding(0, dp2px(2), 0, dp2px(2))
            swRow.addView(tv("左右滑动选区", 13, CS.text), LinearLayout.LayoutParams(0, -2, 1))
            local sw = Switch(this)
            sw.setChecked(work[si].selectOn)
            tintSwitch(sw)
            sw.setOnCheckedChangeListener(luajava.createProxy("android.widget.CompoundButton$OnCheckedChangeListener", {
                onCheckedChanged = function(_, checked)
                    work[si].selectOn = checked
                    tintSwitch(sw)
                end,
            }))
            swRow.addView(sw)
            cardView.addView(swRow)
        end

        for pi, p in ipairs(sc.params) do
            local row = LinearLayout(this)
            row.setOrientation(LinearLayout.HORIZONTAL)
            row.setGravity(Gravity.CENTER_VERTICAL)
            row.addView(tv(p.label, 13, CS.text), LinearLayout.LayoutParams(dp2px(88), -2))

            local valTv = tv(tostring(work[si][pi]), 13, CS.sub)
            valTv.setGravity(Gravity.CENTER)

            local seek = SeekBar(this)
            seek.setMax(p.max - p.min)
            seek.setProgress(work[si][pi] - p.min)
            tintSeek(seek)
            seek.setOnSeekBarChangeListener(luajava.createProxy("android.widget.SeekBar$OnSeekBarChangeListener", {
                onProgressChanged = function(_, progress, _)
                    local v = p.min + progress
                    work[si][pi] = v
                    valTv.setText(tostring(v))
                end,
                onStartTrackingTouch = function() end,
                onStopTrackingTouch = function() end,
            }))
            row.addView(seek, LinearLayout.LayoutParams(0, -2, 1))
            row.addView(valTv, LinearLayout.LayoutParams(dp2px(44), -2))
            cardView.addView(row)
        end
    end
end

root.addView(divider())

-- 按钮行
local btnRow = LinearLayout(this)
btnRow.setOrientation(LinearLayout.HORIZONTAL)
btnRow.setPadding(0, dp2px(4), 0, dp2px(4))

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
        local total, missing = saveAll()
        if #missing > 0 then
            print("提示：" .. table.concat(missing, "、") .. " 的脚本文件未找到，其余已保存")
        elseif total == 0 then
            print("提示：没有字段被改写（参数名可能不匹配）")
        end
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
        win.setLayout(dp2px(320), -2)
    end
end)
