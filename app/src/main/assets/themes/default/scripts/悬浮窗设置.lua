------------------------------------------------------------------
-- 悬浮窗设置（命令脚本 · trime2 ）
-- AZNixl | Kimi K3
------------------------------------------------------------------
-- 【功能】
--   · 跟随光标开关（顶部）
--   · 悬浮窗图片选择（扫描 主题/images/悬浮窗/）
--   · 候选文本：字号 / 次选颜色 / 首选颜色（色盘选取）
--   · 候选序号：字号 / 颜色（色盘选取）
--   · 竖屏/横屏：图片左右、图片上下、文字左右、文字上下
--   · 保存并自动重载主题
--
-- 【原理】
--   坐标/图片 → rime/悬浮窗设置.cfg（主脚本读取）
--   文本与序号的颜色字号 → 自动扫描主题目录，就地改写
--     candidate / candidate.pressed / composition.key.hint 里的
--     text_size、text_color 字段（兼容 Lua 表和 YAML 写法）
--
-- 【绑定】hover_set = { label = "悬浮窗", command = "悬浮窗设置.lua" }
------------------------------------------------------------------

import "android.widget.*"
import "android.view.*"
import "android.graphics.drawable.ColorDrawable"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.drawable.RippleDrawable"
import "android.graphics.Color"
import "android.content.res.ColorStateList"
import "java.util.ArrayList"
import "android.widget.ArrayAdapter"
import "com.androlua.LuaDialog"

local this = rawget(_G, "this") or luajava.bindClass("com.osfans.trime.TrimeService").getInstance()

local CONFIG_PATH = "/storage/emulated/0/Documents/rime/悬浮窗设置.cfg"
local DEFAULT_CFG = {
    follow = false,
    follow_dx = 0, follow_dy = 0,   -- 跟随光标时的微调偏移（像素）
    portrait  = { left = 250, top = -120, padL = 100, padT = 175 },
    landscape = { left = 400, top = 150,  padL = 100, padT = 190 },
}

local function loadCfg()
    local ok, t = pcall(function()
        local f = loadfile(CONFIG_PATH)
        return f and f() or nil
    end)
    if not ok or type(t) ~= "table" then t = DEFAULT_CFG end
    local function num(v, d) return tonumber(v) or d end
    local p, l = t.portrait or {}, t.landscape or {}
    return {
        follow = (t.follow == true),
        follow_dx = num(t.follow_dx, 0),
        follow_dy = num(t.follow_dy, 0),
        image = (type(t.image) == "string" and t.image ~= "") and t.image or nil,
        portrait  = { left = num(p.left, 250), top = num(p.top, -120), padL = num(p.padL, 100), padT = num(p.padT, 175) },
        landscape = { left = num(l.left, 400), top = num(l.top, 150),  padL = num(l.padL, 100), padT = num(l.padT, 190) },
    }
end

local function saveCfg(c)
    local s = string.format(
        "return {\n    follow = %s,\n    follow_dx = %d,\n    follow_dy = %d,\n    image = %s,\n    portrait = { left = %d, top = %d, padL = %d, padT = %d },\n    landscape = { left = %d, top = %d, padL = %d, padT = %d },\n}\n",
        tostring(c.follow),
        tonumber(c.follow_dx) or 0, tonumber(c.follow_dy) or 0,
        c.image and string.format("%q", c.image) or "nil",
        c.portrait.left, c.portrait.top, c.portrait.padL, c.portrait.padT,
        c.landscape.left, c.landscape.top, c.landscape.padL, c.landscape.padT)
    local f = io.open(CONFIG_PATH, "w")
    if not f then return false end
    f:write(s)
    f:close()
    return true
end

local IMAGE_DIR = "/storage/emulated/0/Documents/rime/themes/"
    .. tostring(luajava.bindClass("com.osfans.trime.Config").getTheme()) .. "/images/悬浮窗/"
local function scanImages()
    local File = luajava.bindClass("java.io.File")
    local out = {}
    local files = File(IMAGE_DIR).listFiles()
    if files then
        for i = 0, files.length - 1 do
            local n = tostring(files[i].getName())
            if files[i].isFile() and (n:lower():match("%.png$") or n:lower():match("%.jpe?g$")) then
                out[#out + 1] = n
            end
        end
    end
    table.sort(out)
    return out
end

local function dp2px(dp)
    return math.floor(dp * this.getResources().getDisplayMetrics().density + 0.5)
end

------------------------------------------------------------------
-- jqb 同款配色（与 menu.lua 一致；分隔线按需求用灰色，不跟随回车）
------------------------------------------------------------------
local ThemeManager = luajava.bindClass("com.osfans.trime.theme.ThemeManager")
local Config = luajava.bindClass("com.osfans.trime.Config")

local DARK_STYLES = { ["迟暮"] = true, ["暗夜"] = true }
local LIGHT_STYLES = { ["尘白"] = true, ["黎明"] = true }

local cs = {
    light = {
        btn = 0xFFF4F4F4,
        text = 0xFF1E2638,
        sub = 0xFF7A8090,
        dlg = 0xFFE3E4E9,
        line = 0xFFC9CCD2,   -- 分隔线：灰
    },
    night = {
        btn = 0xCC232323,
        text = 0xff9C9FA7,
        sub = 0xFF6A7079,
        dlg = 0xFF181A1A,
        line = 0xFF3A3D3F,
    }
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
local ACCENT = CS.accent or 0xFF30C190   -- 滚动条/保存键跟随色

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

-- 滚动条染色：进度与滑块跟随回车键色
local function tintSeek(seek)
    pcall(function()
        local PorterDuff = luajava.bindClass("android.graphics.PorterDuff")
        seek.getProgressDrawable().setColorFilter(ACCENT, PorterDuff.Mode.SRC_IN)
        seek.getThumb().setColorFilter(ACCENT, PorterDuff.Mode.SRC_IN)
    end)
end

------------------------------------------------------------------
-- 主题样式文件：自动定位 + 读写 candidate / composition.key.hint
------------------------------------------------------------------
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- 样式文件精确定位：themes/<主题>/styles/<当前样式>/main.lua
-- （兜底：styles/ 下扫描含 candidate 定义的 main.lua；不扫 scripts/ 防止误中本脚本）
local function findStyleFile()
    local File = luajava.bindClass("java.io.File")
    local theme = tostring(Config.getTheme())
    local style = tostring(Config.getStyle())
    local base = "/storage/emulated/0/Documents/rime/themes/" .. theme .. "/styles/"
    -- 优先：当前样式目录的 main.lua
    local direct = base .. style .. "/main.lua"
    local fh = io.open(direct, "r")
    if fh then fh:close() return direct end
    -- 兜底：styles/ 下两层内找含 candidate + text_color 的文件
    local function scan(p, depth)
        local files = File(p).listFiles()
        if not files then return nil end
        for i = 0, files.length - 1 do
            local f = files[i]
            local n = tostring(f.getName())
            if f.isFile() and (n:match("%.lua$") or n:match("%.yaml$")) then
                local c = readFile(tostring(f.getAbsolutePath()))
                if c and c:find("candidate") and c:find("text_color") then
                    return tostring(f.getAbsolutePath())
                end
            end
        end
        if depth > 0 then
            for i = 0, files.length - 1 do
                local f = files[i]
                if f.isDirectory() then
                    local r = scan(tostring(f.getAbsolutePath()), depth - 1)
                    if r then return r end
                end
            end
        end
        return nil
    end
    return scan(base, 2)
end

local function colorToNum(s)
    return s and tonumber(s) or nil
end

-- 解析当前样式值（兼容 key = 0x.. 和 key: 0x..，可带引号）
local function parseStyle(text)
    local r = {}
    local function segVal(seg, key, pat)
        local v = seg:match(key .. "%s*[=:]%s*\"?(" .. pat .. ")\"?")
        return v
    end
    local cpos = text:find("candidate%s*=%s*{") or text:find("candidate%s*:%s*{")
    local ppos = text:find("candidate%.pressed%s*=%s*{") or text:find("candidate%.pressed%s*:%s*{")
    if cpos then
        local seg = text:sub(cpos, ppos and (ppos - 1) or (cpos + 2000))
        r.candSize = tonumber(segVal(seg, "text_size", "[%d%.]+"))
        r.candColor = colorToNum(segVal(seg, "text_color", "0x%x+"))
    end
    if ppos then
        local seg = text:sub(ppos, ppos + 800)
        r.pressedColor = colorToNum(segVal(seg, "text_color", "0x%x+"))
    end
    local kpos = text:find("composition%.key")
    local hpos = kpos and (text:find("hint%s*=%s*{", kpos) or text:find("hint%s*:%s*{", kpos))
    if hpos then
        local seg = text:sub(hpos, hpos + 600)
        r.hintSize = tonumber(segVal(seg, "text_size", "[%d%.]+"))
        r.hintColor = colorToNum(segVal(seg, "text_color", "0x%x+"))
    end
    -- 悬浮窗跟随光标位置：composition 块里的 position（字符串值）
    local mpos = text:find("composition%s*=%s*{") or text:find("composition%s*:%s*{")
    if mpos then
        local seg = text:sub(mpos, math.min(#text, mpos + 1200))
        r.position = seg:match("position%s*[=:]%s*\"([%w_]+)\"")
            or seg:match("position%s*[=:]%s*'([%w_]+)'")
        r.maxEntries = tonumber(seg:match("max_entries%s*[=:]%s*(%d+)"))
    end
    return r
end

-- 在 [startPos, endPos) 段内替换 key 的值（保留分隔符和引号风格），返回新文本与替换数
local function patchSeg(text, s, e, key, newval)
    local seg = text:sub(s, e)
    local ns, n = seg:gsub("(" .. key .. "%s*[=:]%s*[\"']?)0x%x+", "%1" .. newval, 1)
    if n == 0 then
        ns, n = seg:gsub("(" .. key .. "%s*[=:]%s*)[%d%.]+", "%1" .. newval, 1)
    end
    if n > 0 then
        return text:sub(1, s - 1) .. ns .. text:sub(e + 1), n
    end
    return text, 0
end

-- 把 cand/hint/position/maxEntries 设置写回样式文件，返回替换的总字段数
local function patchStyleFile(path, cand, hint, position, maxEntries)
    local text = readFile(path)
    if not text then return 0 end
    local total = 0
    -- 悬浮窗词条数（composition.max_entries，数字值）
    if maxEntries then
        local mpos = text:find("composition%s*=%s*{") or text:find("composition%s*:%s*{")
        if mpos then
            local seg = text:sub(mpos, math.min(#text, mpos + 1200))
            local ns, n = seg:gsub("(max_entries%s*[=:]%s*)%d+", "%1" .. tostring(maxEntries), 1)
            if n > 0 then
                text = text:sub(1, mpos - 1) .. ns .. text:sub(math.min(#text, mpos + 1200) + 1)
                total = total + n
            end
        end
    end
    -- 悬浮窗位置（composition.position，字符串值，保留原引号风格）
    if position then
        local mpos = text:find("composition%s*=%s*{") or text:find("composition%s*:%s*{")
        if mpos then
            local seg = text:sub(mpos, math.min(#text, mpos + 1200))
            local ns, n = seg:gsub("(position%s*[=:]%s*\")[%w_]+(\")", "%1" .. position .. "%2", 1)
            if n == 0 then
                ns, n = seg:gsub("(position%s*[=:]%s*')[%w_]+(')", "%1" .. position .. "%2", 1)
            end
            if n > 0 then
                text = text:sub(1, mpos - 1) .. ns .. text:sub(math.min(#text, mpos + 1200) + 1)
                total = total + n
            end
        end
    end
    local cpos = text:find("candidate%s*=%s*{") or text:find("candidate%s*:%s*{")
    local ppos = text:find("candidate%.pressed%s*=%s*{") or text:find("candidate%.pressed%s*:%s*{")
    if cpos then
        local e = (ppos and (ppos - 1) or #text)
        local n
        if cand.size then text, n = patchSeg(text, cpos, e, "text_size", tostring(cand.size)) total = total + n end
        if cand.color then
            -- 位置可能因上次替换微移，重新定位
            cpos = text:find("candidate%s*=%s*{") or text:find("candidate%s*:%s*{")
            ppos = text:find("candidate%.pressed%s*=%s*{") or text:find("candidate%.pressed%s*:%s*{")
            e = (ppos and (ppos - 1) or #text)
            text, n = patchSeg(text, cpos, e, "text_color", string.format("0x%08x", cand.color))
            total = total + n
        end
    end
    if cand.pressed then
        ppos = text:find("candidate%.pressed%s*=%s*{") or text:find("candidate%.pressed%s*:%s*{")
        if ppos then
            local n
            text, n = patchSeg(text, ppos, math.min(#text, ppos + 800), "text_color", string.format("0x%08x", cand.pressed))
            total = total + n
        end
    end
    local kpos = text:find("composition%.key")
    local hpos = kpos and (text:find("hint%s*=%s*{", kpos) or text:find("hint%s*:%s*{", kpos))
    if hpos then
        local e = math.min(#text, hpos + 600)
        local n
        if hint.size then text, n = patchSeg(text, hpos, e, "text_size", tostring(hint.size)) total = total + n end
        if hint.color then
            hpos = text:find("hint%s*=%s*{", kpos) or text:find("hint%s*:%s*{", kpos)
            text, n = patchSeg(text, hpos, math.min(#text, hpos + 600), "text_color", string.format("0x%08x", hint.color))
            total = total + n
        end
    end
    if total > 0 then
        local f = io.open(path, "w")
        if f then f:write(text) f:close() end
    end
    return total
end

------------------------------------------------------------------
-- HSV 色盘取色器（自绘：SV 面板 + 色相条 + 透明度滑条）
------------------------------------------------------------------
local function toSigned(c)
    c = c % 0x100000000
    if c > 0x7FFFFFFF then c = c - 0x100000000 end
    return c
end

local function hsv2rgb(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return math.floor((r + m) * 255 + 0.5), math.floor((g + m) * 255 + 0.5), math.floor((b + m) * 255 + 0.5)
end

local function rgb2hsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local d = mx - mn
    local h = 0
    if d > 0 then
        if mx == r then h = 60 * (((g - b) / d) % 6)
        elseif mx == g then h = 60 * ((b - r) / d + 2)
        else h = 60 * ((r - g) / d + 4) end
    end
    local s = (mx == 0) and 0 or (d / mx)
    return h, s, mx
end

local Orientation = luajava.bindClass("android.graphics.drawable.GradientDrawable$Orientation")

-- openColorPicker(initUnsigned, onOk(unsigned))
local function openColorPicker(init, onOk)
    local a = math.floor((init % 0x100000000) / 0x1000000)
    local r = math.floor(init / 0x10000) % 256
    local g = math.floor(init / 0x100) % 256
    local b = init % 256
    local h, s, v = rgb2hsv(r, g, b)

    local d2 = LuaDialog(this)
    local root = LinearLayout(this)
    root.setOrientation(LinearLayout.VERTICAL)
    root.setPadding(dp2px(16), dp2px(14), dp2px(16), dp2px(10))
    root.setBackgroundDrawable(gdDrawable(CS.dlg, dp2px(16)))

    local function ctv(text, size, color, bold)
        local t = TextView(this)
        t.setText(text)
        t.setTextSize(size)
        t.setTextColor(color)
        if bold then t.getPaint().setFakeBoldText(true) end
        return t
    end

    local title = ctv("选择颜色", 16, CS.text, true)
    title.setPadding(dp2px(4), 0, 0, dp2px(10))
    root.addView(title)

    -- SV 面板（两层渐变叠加：左白→右纯色，上透明→下黑）
    local baseG, shadeG
    local function makeBase()
        local hr, hg, hb = hsv2rgb(h, 1, 1)
        baseG = GradientDrawable()
        baseG.setOrientation(Orientation.LEFT_RIGHT)
        baseG.setColors({ -1, toSigned(0xFF000000 + hr * 0x10000 + hg * 0x100 + hb) })
        return baseG
    end
    shadeG = GradientDrawable()
    shadeG.setOrientation(Orientation.TOP_BOTTOM)
    shadeG.setColors({ 0x00000000, 0xFF000000 })

    local svFrame = FrameLayout(this)
    local svBase = View(this)
    svBase.setBackgroundDrawable(makeBase())
    local svShade = View(this)
    svShade.setBackgroundDrawable(shadeG)
    svFrame.addView(svBase, FrameLayout.LayoutParams(-1, -1))
    svFrame.addView(svShade, FrameLayout.LayoutParams(-1, -1))
    root.addView(svFrame, LinearLayout.LayoutParams(-1, dp2px(180)))

    -- 色相条
    local hueG = GradientDrawable()
    hueG.setOrientation(Orientation.LEFT_RIGHT)
    hueG.setColors({ 0xFFFF0000, 0xFFFFFF00, 0xFF00FF00, 0xFF00FFFF, 0xFF0000FF, 0xFFFF00FF, 0xFFFF0000 })
    local hueView = View(this)
    hueView.setBackgroundDrawable(hueG)
    local hueLp = LinearLayout.LayoutParams(-1, dp2px(22))
    hueLp.setMargins(0, dp2px(12), 0, 0)
    root.addView(hueView, hueLp)

    -- 预览 + 十六进制
    local prevRow = LinearLayout(this)
    prevRow.setOrientation(LinearLayout.HORIZONTAL)
    prevRow.setGravity(Gravity.CENTER_VERTICAL)
    prevRow.setPadding(0, dp2px(12), 0, 0)
    local prev = View(this)
    prevRow.addView(prev, LinearLayout.LayoutParams(dp2px(48), dp2px(30)))
    local hexTv = ctv("", 14, CS.text)
    hexTv.setPadding(dp2px(12), 0, 0, 0)
    prevRow.addView(hexTv, LinearLayout.LayoutParams(0, -2, 1))
    root.addView(prevRow)

    local function refresh()
        r, g, b = hsv2rgb(h, s, v)
        local unsigned = a * 0x1000000 + r * 0x10000 + g * 0x100 + b
        prev.setBackgroundDrawable(gdDrawable(toSigned(unsigned), dp2px(8)))
        hexTv.setText(string.format("#%08X  A:%d", unsigned, a))
    end

    -- SV 触摸
    svFrame.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(_, ev)
            local w, hh = svFrame.getWidth(), svFrame.getHeight()
            if w > 0 and hh > 0 then
                s = math.min(1, math.max(0, ev.getX() / w))
                v = 1 - math.min(1, math.max(0, ev.getY() / hh))
                refresh()
            end
            return true
        end,
    }))

    -- 色相触摸
    hueView.setOnTouchListener(luajava.createProxy("android.view.View$OnTouchListener", {
        onTouch = function(_, ev)
            local w = hueView.getWidth()
            if w > 0 then
                h = math.min(359.9, math.max(0, ev.getX() / w * 360))
                svBase.setBackgroundDrawable(makeBase())
                refresh()
            end
            return true
        end,
    }))

    -- 透明度
    local aRow = LinearLayout(this)
    aRow.setOrientation(LinearLayout.HORIZONTAL)
    aRow.setGravity(Gravity.CENTER_VERTICAL)
    aRow.setPadding(0, dp2px(8), 0, 0)
    aRow.addView(ctv("透明度", 13, CS.text), LinearLayout.LayoutParams(dp2px(56), -2))
    local aSeek = SeekBar(this)
    aSeek.setMax(255)
    aSeek.setProgress(a)
    tintSeek(aSeek)
    aSeek.setOnSeekBarChangeListener(luajava.createProxy("android.widget.SeekBar$OnSeekBarChangeListener", {
        onProgressChanged = function(_, p, _) a = p refresh() end,
        onStartTrackingTouch = function() end,
        onStopTrackingTouch = function() end,
    }))
    aRow.addView(aSeek, LinearLayout.LayoutParams(0, -2, 1))
    root.addView(aRow)

    refresh()

    -- 按钮
    local btnRow = LinearLayout(this)
    btnRow.setOrientation(LinearLayout.HORIZONTAL)
    btnRow.setPadding(0, dp2px(12), 0, dp2px(4))
    local function mkBtn(text, bg, tc)
        local bt = Button(this)
        bt.setText(text)
        bt.setTextColor(tc)
        bt.setTextSize(14)
        bt.setBackgroundDrawable(createRipple(bg, dp2px(14)))
        return bt
    end
    local btnOk = mkBtn("确定", ACCENT, 0xFFFFFFFF)
    btnOk.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function()
            local unsigned = a * 0x1000000 + r * 0x10000 + g * 0x100 + b
            pcall(onOk, unsigned)
            d2.dismiss()
        end,
    }))
    btnRow.addView(btnOk, LinearLayout.LayoutParams(0, -2, 1))
    local sp = View(this)
    btnRow.addView(sp, LinearLayout.LayoutParams(dp2px(10), 1))
    local btnNo = mkBtn("取消", CS.btn, CS.text)
    btnNo.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
        onClick = function() d2.dismiss() end,
    }))
    btnRow.addView(btnNo, LinearLayout.LayoutParams(0, -2, 1))
    root.addView(btnRow)

    d2.setView(root)
    d2.show()
    pcall(function()
        local win = d2.getWindow()
        if win then
            win.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            win.setLayout(dp2px(300), -2)
        end
    end)
end

------------------------------------------------------------------
-- 参数与当前值
------------------------------------------------------------------
local RANGES = {
    left = { -100, 900 },
    top  = { -500, 500 },
    padL = { 0, 500 },
    padT = { 0, 500 },
    candSize = { 10, 40 },
    hintSize = { 8, 30 },
}
local LABELS = { left = "图片左右", top = "图片上下", padL = "文字左右", padT = "文字上下" }
local KEYS = { "left", "top", "padL", "padT" }

local work = loadCfg()

-- 样式文件：定位并解析当前值（真源）
local styleFile = findStyleFile()
local styleVals = styleFile and parseStyle(readFile(styleFile) or "") or {}
work.cand = {
    size = styleVals.candSize or 18,
    color = styleVals.candColor or 0xFF000000,
    pressed = styleVals.pressedColor or 0xFF000000,
}
work.hint = {
    size = styleVals.hintSize or 15,
    color = styleVals.hintColor or 0xFFFFFFFF,
}

------------------------------------------------------------------
-- 主界面（布局顺序：跟随光标→图片→候选文本→候选序号→竖屏→横屏）
------------------------------------------------------------------
local dlg = LuaDialog(this)

local function tv(text, size, color, bold)
    local t = TextView(this)
    t.setText(text)
    t.setTextSize(size)
    t.setTextColor(color)
    if bold then t.getPaint().setFakeBoldText(true) end
    return t
end

-- 灰色分隔线（不跟随回车色）
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

local title = tv("悬浮窗显示优化设置", 17, CS.text, true)
title.setPadding(dp2px(4), 0, 0, dp2px(10))
root.addView(title)

-- ① 跟随光标（最顶部）
local swCard = LinearLayout(this)
swCard.setOrientation(LinearLayout.HORIZONTAL)
swCard.setGravity(Gravity.CENTER_VERTICAL)
swCard.setPadding(dp2px(12), dp2px(2), dp2px(12), dp2px(2))
swCard.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(14)))
swCard.addView(tv("跟随光标（关闭则用固定坐标）", 14, CS.text), LinearLayout.LayoutParams(0, -2, 1))
local sw = Switch(this)
sw.setChecked(work.follow)
tintSwitch(sw)
sw.setOnCheckedChangeListener(luajava.createProxy("android.widget.CompoundButton$OnCheckedChangeListener", {
    onCheckedChanged = function(_, checked)
        work.follow = checked
        tintSwitch(sw)
    end,
}))
swCard.addView(sw)
root.addView(swCard)

-- ①.5 跟随光标位置（写样式 composition.position）+ 跟随微调偏移（写 cfg）
local POSITIONS = {
    "fixed", "left", "right", "left_up", "right_up",
    "bottom_left", "bottom_right", "top_left", "top_right",
}
work.position = styleVals.position or "fixed"
local fwCard = LinearLayout(this)
fwCard.setOrientation(LinearLayout.VERTICAL)
fwCard.setPadding(dp2px(12), dp2px(6), dp2px(12), dp2px(6))
fwCard.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(14)))
local fwLp = LinearLayout.LayoutParams(-1, -2)
fwLp.setMargins(0, dp2px(6), 0, 0)
root.addView(fwCard, fwLp)

local posRow = LinearLayout(this)
posRow.setOrientation(LinearLayout.HORIZONTAL)
posRow.setGravity(Gravity.CENTER_VERTICAL)
posRow.addView(tv("光标位置", 13, CS.text), LinearLayout.LayoutParams(dp2px(64), -2))
local posList = ArrayList()
for _, p in ipairs(POSITIONS) do posList.add(p) end
local Rlayout = luajava.bindClass("android.R$layout")
local posAdapter = ArrayAdapter(this, Rlayout.simple_spinner_item, posList)
posAdapter.setDropDownViewResource(Rlayout.simple_spinner_dropdown_item)
local posSpinner = Spinner(this)
posSpinner.setAdapter(posAdapter)
local posIdx = 0
for i, p in ipairs(POSITIONS) do
    if p == work.position then posIdx = i - 1 break end
end
posSpinner.setSelection(posIdx)
work.position = POSITIONS[posIdx + 1]
posSpinner.setOnItemSelectedListener(luajava.createProxy("android.widget.AdapterView$OnItemSelectedListener", {
    onItemSelected = function(_, _, pos, _) work.position = POSITIONS[pos + 1] end,
    onNothingSelected = function() end,
}))
posRow.addView(posSpinner, LinearLayout.LayoutParams(0, -2, 1))
fwCard.addView(posRow)

root.addView(divider())

local scroll = ScrollView(this)
local col = LinearLayout(this)
col.setOrientation(LinearLayout.VERTICAL)
scroll.addView(col)
root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1))

-- 章节标题（恢复未跟随回车色前的灰色设定）
local function section(name)
    local h = tv(name, 13, CS.sub, true)
    h.setPadding(dp2px(4), dp2px(6), 0, dp2px(6))
    col.addView(h)
end

local function card()
    local c = LinearLayout(this)
    c.setOrientation(LinearLayout.VERTICAL)
    c.setPadding(dp2px(12), dp2px(6), dp2px(12), dp2px(6))
    c.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(14)))
    col.addView(c)
    return c
end

-- 通用滚动条行
local function seekRow(parent, label, rng, getVal, setVal)
    local row = LinearLayout(this)
    row.setOrientation(LinearLayout.HORIZONTAL)
    row.setGravity(Gravity.CENTER_VERTICAL)
    row.addView(tv(label, 13, CS.text), LinearLayout.LayoutParams(dp2px(64), -2))
    local valTv = tv(tostring(getVal()), 13, CS.sub)
    valTv.setGravity(Gravity.CENTER)
    local seek = SeekBar(this)
    seek.setMax(rng[2] - rng[1])
    seek.setProgress(getVal() - rng[1])
    tintSeek(seek)
    seek.setOnSeekBarChangeListener(luajava.createProxy("android.widget.SeekBar$OnSeekBarChangeListener", {
        onProgressChanged = function(_, progress, _)
            local v = rng[1] + progress
            setVal(v)
            valTv.setText(tostring(v))
        end,
        onStartTrackingTouch = function() end,
        onStopTrackingTouch = function() end,
    }))
    row.addView(seek, LinearLayout.LayoutParams(0, -2, 1))
    row.addView(valTv, LinearLayout.LayoutParams(dp2px(48), -2))
    parent.addView(row)
end

-- 跟随光标的微调偏移（ fwCard 在上方已创建，这里补两条滚动条）
seekRow(fwCard, "横向微调", { -200, 200 },
    function() return work.follow_dx end,
    function(v) work.follow_dx = v end)
seekRow(fwCard, "纵向微调", { -200, 200 },
    function() return work.follow_dy end,
    function(v) work.follow_dy = v end)

-- 颜色选择行（色块 + 名称，点击开色盘）
local function colorRow(parent, label, getColor, setColor)
    local row = LinearLayout(this)
    row.setOrientation(LinearLayout.HORIZONTAL)
    row.setGravity(Gravity.CENTER_VERTICAL)
    row.setPadding(0, dp2px(4), 0, dp2px(4))
    row.addView(tv(label, 13, CS.text), LinearLayout.LayoutParams(0, -2, 1))
    local hexTv = tv(string.format("#%08X", getColor() % 0x100000000), 12, CS.sub)
    row.addView(hexTv)
    local sw2 = View(this)
    local function paint()
        sw2.setBackgroundDrawable(gdDrawable(toSigned(getColor()), dp2px(8)))
    end
    paint()
    local lp = LinearLayout.LayoutParams(dp2px(44), dp2px(28))
    lp.setMargins(dp2px(10), 0, 0, 0)
    row.addView(sw2, lp)
    local function open()
        openColorPicker(getColor(), function(c)
            setColor(c)
            paint()
            hexTv.setText(string.format("#%08X", c % 0x100000000))
        end)
    end
    local clickProxy = luajava.createProxy("android.view.View$OnClickListener", { onClick = open })
    sw2.setOnClickListener(clickProxy)
    row.setOnClickListener(clickProxy)
    parent.addView(row)
end

-- ② 悬浮窗图片
section("悬浮窗图片")
local imgCard = LinearLayout(this)
imgCard.setOrientation(LinearLayout.HORIZONTAL)
imgCard.setGravity(Gravity.CENTER_VERTICAL)
imgCard.setPadding(dp2px(12), dp2px(2), dp2px(12), dp2px(2))
imgCard.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(14)))
col.addView(imgCard)
local imgs = scanImages()
if #imgs == 0 then
    imgCard.addView(tv("images/悬浮窗/ 下没有图片", 13, CS.text))
else
    local cur = work.image or "蜡笔小新.png"
    local selIdx, found = 0, false
    for i, n in ipairs(imgs) do
        if n == cur then selIdx = i - 1 found = true break end
    end
    if not found then table.insert(imgs, 1, cur) selIdx = 0 end
    local Rlayout = luajava.bindClass("android.R$layout")
    local list = ArrayList()
    for _, n in ipairs(imgs) do list.add(n) end
    local adapter = ArrayAdapter(this, Rlayout.simple_spinner_item, list)
    adapter.setDropDownViewResource(Rlayout.simple_spinner_dropdown_item)
    local spinner = Spinner(this)
    spinner.setAdapter(adapter)
    spinner.setSelection(selIdx)
    work.image = imgs[selIdx + 1]
    spinner.setOnItemSelectedListener(luajava.createProxy("android.widget.AdapterView$OnItemSelectedListener", {
        onItemSelected = function(_, _, pos, _) work.image = imgs[pos + 1] end,
        onNothingSelected = function() end,
    }))
    imgCard.addView(spinner, LinearLayout.LayoutParams(0, -2, 1))
end

-- ②.5 悬浮窗词条数（composition.max_entries，1~9 下拉）
work.maxEntries = styleVals.maxEntries or 3
if work.maxEntries < 1 then work.maxEntries = 1 end
if work.maxEntries > 9 then work.maxEntries = 9 end
local meCard = LinearLayout(this)
meCard.setOrientation(LinearLayout.HORIZONTAL)
meCard.setGravity(Gravity.CENTER_VERTICAL)
meCard.setPadding(dp2px(12), dp2px(2), dp2px(12), dp2px(2))
meCard.setBackgroundDrawable(gdDrawable(CS.btn, dp2px(14)))
local meLp = LinearLayout.LayoutParams(-1, -2)
meLp.setMargins(0, dp2px(6), 0, 0)
col.addView(meCard, meLp)
meCard.addView(tv("词条数", 13, CS.text), LinearLayout.LayoutParams(dp2px(64), -2))
do
    local meList = ArrayList()
    for i = 1, 9 do meList.add(tostring(i)) end
    local Rlayout2 = luajava.bindClass("android.R$layout")
    local meAdapter = ArrayAdapter(this, Rlayout2.simple_spinner_item, meList)
    meAdapter.setDropDownViewResource(Rlayout2.simple_spinner_dropdown_item)
    local meSpinner = Spinner(this)
    meSpinner.setAdapter(meAdapter)
    meSpinner.setSelection(work.maxEntries - 1)
    meSpinner.setOnItemSelectedListener(luajava.createProxy("android.widget.AdapterView$OnItemSelectedListener", {
        onItemSelected = function(_, _, pos, _) work.maxEntries = pos + 1 end,
        onNothingSelected = function() end,
    }))
    meCard.addView(meSpinner, LinearLayout.LayoutParams(0, -2, 1))
end
col.addView(divider())

-- ③ 候选文本（次选颜色 = candidate.text_color；首选颜色 = candidate.pressed.text_color；字号共用）
section("候选文本")
local candCard = card()
seekRow(candCard, "文本大小", RANGES.candSize,
    function() return work.cand.size end,
    function(v) work.cand.size = v end)
-- 首选/次选合并：一个颜色设置，保存时 candidate 和 candidate.pressed 两处同写
colorRow(candCard, "文本颜色",
    function() return work.cand.color end,
    function(c) work.cand.color = c work.cand.pressed = c end)
col.addView(divider())

-- ④ 候选序号
section("候选序号")
local hintCard = card()
seekRow(hintCard, "序号大小", RANGES.hintSize,
    function() return work.hint.size end,
    function(v) work.hint.size = v end)
colorRow(hintCard, "序号文本颜色",
    function() return work.hint.color end,
    function(c) work.hint.color = c end)
col.addView(divider())

-- ⑤ 竖屏位置
section("竖屏位置 数值：左小右大 上小下大")
local pCard = card()
for _, key in ipairs(KEYS) do
    seekRow(pCard, LABELS[key], RANGES[key],
        function() return work.portrait[key] end,
        function(v) work.portrait[key] = v end)
end
col.addView(divider())

-- ⑥ 横屏位置
section("横屏位置")
local lCard = card()
for _, key in ipairs(KEYS) do
    seekRow(lCard, LABELS[key], RANGES[key],
        function() return work.landscape[key] end,
        function(v) work.landscape[key] = v end)
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
        if not saveCfg(work) then
            print("保存失败：无法写入配置文件")
            return
        end
        -- 样式字段写回主题文件
        local patched = 0
        if styleFile then
            local okP, n = pcall(patchStyleFile, styleFile, work.cand, work.hint, work.position, work.maxEntries)
            if okP then patched = n end
        end
        if not styleFile then
            print("提示：未找到主题样式文件，文本/序号颜色字号未写入（坐标与图片已保存）")
        elseif patched == 0 then
            print("提示：样式字段未匹配到（坐标与图片已保存），样式文件=" .. styleFile)
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
