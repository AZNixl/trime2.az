-- 主题颜色调整 for trime2（v1.0）
-- 路径：rime/tools/主题颜色调整/main.lua（同目录需有 init.lua）
-- 功能：选定主题+配色后，直接调整六组颜色：
--       ① 字母键+空格 ② 功能键 ③ 退格键 ④ 回车键 ⑤ 候选栏背景 ⑥ 键盘背景
--       色盘（HSV）或手填 hex 色值，确定即写入样式文件并立即重载，无键盘预览。
--       UI 风格参考 jqb.lua（CS 明暗配色 + 圆角卡片）。

import "android.view.*"
import "android.widget.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "com.androlua.LuaDialog"
import "com.androlua.LuaAdapter"

local Config = luajava.bindClass("com.osfans.trime.Config")
local OsHandler = luajava.bindClass("android.os.Handler")
local uiHandler = OsHandler()

local dm = activity.getResources().getDisplayMetrics()
local function dp(n) return math.floor(n * dm.density + 0.5) end

local function toast(msg)
    Toast.makeText(activity, msg, Toast.LENGTH_SHORT).show()
end

-- Java 对象安全转字符串（个别机型 tostring(javaObj) 会抛错）
local function J(o)
    local ok, s = pcall(tostring, o)
    return ok and s or ""
end

-- 弹窗标题改黑字（默认是白字，浅底上看不见）
local function setDlgTitle(dlg, text)
    local ok = pcall(function()
        local tv = TextView(activity)
        tv.setText(text)
        tv.setTextColor(0xFF000000)
        tv.setTextSize(18)
        tv.setPadding(dp(16), dp(14), dp(16), dp(6))
        dlg.setCustomTitle(tv)
    end)
    if not ok then dlg.setTitle(text) end
end

-- 弹窗整体浅色化：白底 + 按钮深色字
local function styleDlg(dlg)
    pcall(function()
        local ColorDrawable = luajava.bindClass("android.graphics.drawable.ColorDrawable")
        dlg.getWindow().setBackgroundDrawable(ColorDrawable(0xFFF7F7F9))
    end)
    pcall(function()
        local b1 = dlg.getButton(-1) if b1 then b1.setTextColor(0xFF000000) end
        local b2 = dlg.getButton(-2) if b2 then b2.setTextColor(0xFF000000) end
        local b3 = dlg.getButton(-3) if b3 then b3.setTextColor(0xFF000000) end
    end)
end

-- ========== 文件工具 ==========
local function readFile(p)
    local f = io.open(p, "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local function writeFile(p, s)
    local f, err = io.open(p, "w")
    if not f then return false, err end
    f:write(s)
    f:close()
    return true
end

local function fileExists(p)
    local f = io.open(p, "r")
    if f then f:close() return true end
    return false
end

local File = luajava.bindClass("java.io.File")

local function isDir(p)
    local ok, r = pcall(function() return File(p).isDirectory() end)
    return ok and r or false
end

local function listDir(p)
    local out = {}
    pcall(function()
        local arr = File(p).list()
        if arr then
            for i = 0, #arr - 1 do table.insert(out, J(arr[i])) end
        end
    end)
    table.sort(out)
    return out
end

-- ========== jqb 风格 UI 配色 ==========
local cs = {
    light = {
        BgColor   = 0xFFE3E4E9,
        TextColor = 0xFF000000,
        SubColor  = 0xFF5D5D5D,
        CardColor = 0xFFF7F7F9,
        BtnColor  = 0xFFF4F4F4,
        BtnText   = 0xFF000000,
        Active    = 0xFF30C190,
    },
    night = {
        BgColor   = 0xFF181A1A,
        TextColor = 0xb9DDEBE1,
        SubColor  = 0xFFB0C4BC,
        CardColor = 0xCC232323,
        BtnColor  = 0xCC232323,
        BtnText   = 0xb9FFFFFF,
        Active    = 0xFF30C190,
    }
}
local DARK_STYLES = { ["迟暮"] = true, ["暗夜"] = true }
local LIGHT_STYLES = { ["尘白"] = true, ["黎明"] = true }

local function getColors()
    return cs.light  -- 工具脚本固定浅色系，不跟随日夜/样式切换
end

local C = getColors()

local function RadiuButton(color, radius)
    local shape = GradientDrawable()
    shape.setShape(GradientDrawable.RECTANGLE)
    shape.setCornerRadii({radius, radius, radius, radius, radius, radius, radius, radius})
    shape.setColor(color)
    shape.setStroke(0, 0x00000000)
    return shape
end

-- ========== 主题/配色定位 ==========
local triedRoots = {}  -- 诊断：记录尝试过的路径

-- 候选根目录里是否有至少一个主题（含 main.lua 的子目录）
local function looksLikeThemesRoot(dir)
    if not dir or not isDir(dir) then return false end
    for _, name in ipairs(listDir(dir)) do
        if fileExists(dir .. "/" .. name .. "/main.lua") then return true end
    end
    return false
end

local function getThemesRoot()
    triedRoots = {}
    local cands = {}
    -- 1) Config.getThemeDir() 及其父目录、子 themes
    local ok, dir = pcall(function() return Config.getThemeDir() end)
    if ok and dir then
        dir = J(dir):gsub("/+$", "")
        local parent = dir:gsub("/[^/]+$", "")
        table.insert(cands, dir)
        table.insert(cands, parent)                            -- 父目录
        table.insert(cands, dir .. "/themes")                  -- 子 themes
    end
    -- 2) Config.getDataDir()/../themes
    local okD, dataDir = pcall(function() return Config.getDataDir() end)
    if okD and dataDir then
        dataDir = J(dataDir):gsub("/+$", "")
        local parentD = dataDir:gsub("/[^/]+$", "")
        table.insert(cands, dataDir .. "/themes")
        table.insert(cands, parentD .. "/themes")
    end
    -- 3) 常见绝对路径兜底
    table.insert(cands, "/storage/emulated/0/Documents/rime/themes")
    table.insert(cands, "/sdcard/Documents/rime/themes")
    table.insert(cands, "/storage/emulated/0/Android/data/com.osfans.trime/files/rime/themes")
    for _, c in ipairs(cands) do
        local dup = false
        for _, t in ipairs(triedRoots) do if t == c then dup = true end end
        if not dup then
            table.insert(triedRoots, c)
            if looksLikeThemesRoot(c) then return c end
        end
    end
    return nil
end

local function listThemes()
    local root = getThemesRoot()
    local out = {}
    if not root then return out end
    for _, name in ipairs(listDir(root)) do
        if fileExists(root .. "/" .. name .. "/main.lua") then
            table.insert(out, name)
        end
    end
    return out
end

local function listVariants(themeName)
    local out = {}
    local sd = getThemesRoot() .. "/" .. themeName .. "/styles"
    if isDir(sd) then
        for _, name in ipairs(listDir(sd)) do
            if fileExists(sd .. "/" .. name .. "/main.lua") then
                table.insert(out, name)
            end
        end
    end
    return out
end

local currentTheme, themeDir = nil, nil
local currentVariant, styleFile = nil, nil  -- styleFile = 实际写入的样式文件路径

-- ========== 颜色分组定义 ==========
-- paths：按优先级尝试的字段路径（点分）；只改文件里实际存在的字面量行
local GROUPS = {
    { key = "letter", label = "字母键",
      paths = { "key.background" },
      scanLetterStyles = true },  -- 额外扫描 style_X.background（X 为单个字母）
    { key = "space", label = "空格键",
      paths = { "space.background", "style_Space.background" } },
    { key = "functional", label = "功能键",
      paths = { "functional.background", "period.background",
                "style_off.background", "style_Sym.background",
                "style_Comma.background", "style_Period.background" } },
    { key = "back", label = "退格键",
      paths = { "style_Back.background", "back.background", "Back.background" } },
    { key = "enter", label = "回车键",
      paths = { "enter.background", "enter2.background", "style_Enter.background" } },
    { key = "candidate", label = "候选栏背景",
      paths = { "candidate.background" } },
    { key = "candidate_key", label = "候选栏按键",
      paths = { "candidate.key.background", "candidate.expanded.key.background" } },
    { key = "keyboard", label = "键盘背景",
      paths = { "keyboard.background", "background" } },
}

-- ========== 样式源码扫描/改写引擎（就地改行，失败回落受管块） ==========
local BLOCK_BEGIN = "-- >>>> 主题颜色调整 受管块 >>>>"
local BLOCK_END   = "-- <<<< 主题颜色调整 受管块 <<<<"

local function splitLines(s)
    local t = {}
    s = s:gsub("\r\n", "\n")
    for line in (s .. "\n"):gmatch("(.-)\n") do table.insert(t, line) end
    if t[#t] == "" then table.remove(t) end
    return t
end

local function parsePath(path)
    local segs = {}
    for seg in path:gmatch("[^%.]+") do table.insert(segs, seg) end
    return segs
end

local function luaPath(path)
    return path  -- 本工具的路径均为纯字段名，无需下标转换
end

-- 扫描源码：返回 { [完整路径] = {line=行号, value=数值或nil} }（仅字面量值）
local function scanAssigns(src)
    local lines = splitLines(src)
    local scopes = {}
    local found = {}
    for i, line in ipairs(lines) do
        local openSeg = line:match("^%s*([%w_%.]+)%s*=%s*{%s*$")
        if openSeg then
            if openSeg:find(".", 1, true) then
                table.insert(scopes, openSeg)
            elseif #scopes > 0 then
                table.insert(scopes, scopes[#scopes] .. "." .. openSeg)
            else
                table.insert(scopes, openSeg)
            end
        elseif line:match("^%s*}") then
            table.remove(scopes)
        else
            -- 剥掉注释和字符串内容再扫（防注释里的示例赋值被误中）
            local code = line:gsub('"[^"]*"', '""'):gsub("'[^']*'", "''"):gsub("%-%-.*$", "")
            -- 一行可能有多个赋值（如 style_Back = table.clone(f) style_Back.background = 0x...）
            for seg, vend in code:gmatch("([%w_%.]+)%s*=%s*()") do
                local val = code:match("^[^,%s}]+", vend)
                if val then
                    local full
                    if seg:find(".", 1, true) then full = seg
                    elseif #scopes > 0 then full = scopes[#scopes] .. "." .. seg
                    else full = seg end
                    if found[full] == nil then
                        local n = tonumber(val)
                        found[full] = { line = i, seg = seg, value = n,
                                        literal = (n ~= nil) }
                    end
                end
            end
        end
    end
    return lines, found
end

-- 收集某组实际存在且为字面量的目标路径
local function groupTargets(group, found)
    local targets = {}
    for _, p in ipairs(group.paths) do
        local rec = found[p]
        if rec and rec.literal then table.insert(targets, p) end
    end
    if group.scanLetterStyles then
        for full, rec in pairs(found) do
            if rec.literal and full:match("^style_%a%.background$") then
                table.insert(targets, full)
            end
        end
        table.sort(targets)
    end
    return targets
end

local function toHex(n)
    n = math.floor(n) % 0x100000000
    return string.format("0x%08x", n)
end

-- 就地改写：edits = { [路径] = 数值 }，返回 newSrc, changed数, missed表
local function applyEdits(src, edits)
    -- 先剥旧受管块
    local b1, b2 = src:find(BLOCK_BEGIN, 1, true)
    if b1 then
        local e1, e2 = src:find(BLOCK_END, b2, true)
        if e1 then src = src:sub(1, b1 - 1) .. src:sub(e2 + 1) end
    end
    local lines, found = scanAssigns(src)
    local done = {}
    for path, v in pairs(edits) do
        local rec = found[path]
        if rec and rec.literal then
            -- 按具体 seg 定位改写（同一行可能有多个赋值）
            local segPat = rec.seg:gsub("%.", "%%.")
            local line = lines[rec.line]
            local n = 0
            local newLine = line:gsub("(" .. segPat .. "%s*=%s*)([^,%s}]+)", function(pre, old)
                if n == 0 and tonumber(old) then
                    n = n + 1
                    return pre .. toHex(v)
                end
                return nil
            end, 1)
            if n > 0 then
                lines[rec.line] = newLine
                done[path] = true
            end
        end
    end
    local missed = {}
    for path, v in pairs(edits) do
        if not done[path] then table.insert(missed, path) end
    end
    local newSrc = table.concat(lines, "\n"):gsub("%s+$", "")
    if #missed > 0 then
        -- 受管块兜底：路径前缀或不存在时，附加在文件尾（运行期后赋值覆盖）
        table.sort(missed)
        local extra = { "", BLOCK_BEGIN }
        local guarded = {}
        for _, path in ipairs(missed) do
            local segs = parsePath(path)
            local prefix = {}
            for i = 1, #segs - 1 do
                table.insert(prefix, segs[i])
                local p = table.concat(prefix, ".")
                if not guarded[p] then
                    table.insert(extra, p .. " = " .. p .. " or {}")
                    guarded[p] = true
                end
            end
            table.insert(extra, path .. " = " .. toHex(edits[path]))
        end
        table.insert(extra, BLOCK_END)
        newSrc = newSrc .. "\n" .. table.concat(extra, "\n")
    end
    local changed = 0
    for _ in pairs(done) do changed = changed + 1 end
    return newSrc, changed, missed
end

-- 语法校验（load / loadstring 兼容）
local function syntaxOk(src)
    local f
    if load then
        local ok, res = pcall(load, src, "@style", "t")
        if ok and res then return true end
        f = res
    end
    if not f and loadstring then
        local res = loadstring(src)
        if res then return true end
    end
    return false
end

-- 保存 + 重载
local function saveAndReload(edits, label)
    if not styleFile then
        toast("请先选择主题和配色")
        return
    end
    local src = readFile(styleFile)
    if not src then toast("读取样式文件失败") return end
    writeFile(styleFile .. ".bak", src)  -- 改前自动备份
    local newSrc, changed, missed = applyEdits(src, edits)
    if not syntaxOk(newSrc) then
        toast("改写后语法校验失败，未写入")
        return
    end
    local ok, err = writeFile(styleFile, newSrc .. "\n")
    if not ok then toast("写入失败：" .. tostring(err)) return end
    -- 立即重载（trime2 有视图缓存，必须 setTheme 重建）
    pcall(function()
        local TrimeService = luajava.bindClass("com.osfans.trime.TrimeService")
        local ts = TrimeService.getInstance()
        if ts then ts.setTheme(currentTheme) end
    end)
    local msg = label .. " 已应用（改 " .. changed .. " 处"
    if #missed > 0 then msg = msg .. "，追加 " .. #missed .. " 处" end
    toast(msg .. "）")
end

-- ========== HSV 取色盘（移植自主题编辑器，含透明度 + hex 手填） ==========
local function rgbToHsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local d = max - min
    local h = 0
    if d > 0 then
        if max == r then h = ((g - b) / d) % 6
        elseif max == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h * 60
    end
    local s = max == 0 and 0 or d / max
    return h, s, max
end

local function hsvToRgb(h, s, v)
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

local function composeColor(a, h, s, v)
    local r, g, b = hsvToRgb(h, s, v)
    return math.floor(a * 255 + 0.5) * 0x1000000 + r * 0x10000 + g * 0x100 + b
end

-- colorDialog(当前色数值或nil, 标题, onPick(数值))
local function colorDialog(curNum, label, onPick)
    curNum = (type(curNum) == "number") and curNum or 0xFF000000
    curNum = math.floor(curNum) % 0x100000000
    local a = math.floor(curNum / 0x1000000) % 0x100 / 255
    local r = math.floor(curNum / 0x10000) % 0x100
    local g = math.floor(curNum / 0x100) % 0x100
    local b = curNum % 0x100
    local h, s, v = rgbToHsv(r, g, b)

    local lay = LinearLayout(activity)
    lay.setOrientation(LinearLayout.VERTICAL)
    lay.setPadding(dp(12), dp(8), dp(12), dp(4))

    local midRow = LinearLayout(activity)
    midRow.setOrientation(LinearLayout.HORIZONTAL)
    lay.addView(midRow)

    local SV_H = dp(220)

    local svBox = FrameLayout(activity)
    svBox.setLayoutParams(LinearLayout.LayoutParams(0, SV_H, 1))
    midRow.addView(svBox)

    local svImg = ImageView(activity)
    svImg.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
    svImg.setScaleType(ImageView.ScaleType.FIT_XY)
    svBox.addView(svImg)

    local ring = View(activity)
    local RING = dp(16)
    ring.setLayoutParams(FrameLayout.LayoutParams(RING, RING))
    local ringGd = GradientDrawable()
    ringGd.setShape(GradientDrawable.OVAL)
    ringGd.setStroke(dp(2), 0xFFFFFFFF)
    ringGd.setColor(0x00000000)
    ring.setBackgroundDrawable(ringGd)
    svBox.addView(ring)

    local hueBox = FrameLayout(activity)
    local hueLp = LinearLayout.LayoutParams(dp(24), SV_H)
    hueLp.setMargins(dp(10), 0, 0, 0)
    hueBox.setLayoutParams(hueLp)
    midRow.addView(hueBox)

    local hueImg = ImageView(activity)
    hueImg.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
    hueImg.setScaleType(ImageView.ScaleType.FIT_XY)
    hueBox.addView(hueImg)

    local hueLine = View(activity)
    hueLine.setLayoutParams(FrameLayout.LayoutParams(-1, dp(2)))
    hueLine.setBackgroundColor(0xFFFFFFFF)
    hueBox.addView(hueLine)

    local SV_N = 96
    local function buildSvBitmap()
        local ok, bmp = pcall(function()
            local b0 = Bitmap.createBitmap(SV_N, SV_N, Bitmap.Config.ARGB_8888)
            for y = 0, SV_N - 1 do
                local vv = 1 - y / (SV_N - 1)
                for x = 0, SV_N - 1 do
                    local ss = x / (SV_N - 1)
                    local rr, gg, bb = hsvToRgb(h, ss, vv)
                    b0.setPixel(x, y, 0xFF000000 + rr * 0x10000 + gg * 0x100 + bb)
                end
            end
            return b0
        end)
        if ok then return bmp end
        return nil
    end

    local function buildHueBitmap()
        local HN = 180
        local ok, bmp = pcall(function()
            local b0 = Bitmap.createBitmap(12, HN, Bitmap.Config.ARGB_8888)
            for y = 0, HN - 1 do
                local rr, gg, bb = hsvToRgb(y / (HN - 1) * 360, 1, 1)
                local c = 0xFF000000 + rr * 0x10000 + gg * 0x100 + bb
                for x = 0, 11 do b0.setPixel(x, y, c) end
            end
            return b0
        end)
        if ok then return bmp end
        return nil
    end

    local hueBmp = buildHueBitmap()
    if hueBmp then hueImg.setImageBitmap(hueBmp) end

    local function currentColor()
        return composeColor(a, h, s, v)
    end

    local hexTv = TextView(activity)
    hexTv.setLayoutParams(LinearLayout.LayoutParams(-1, dp(40)))
    hexTv.setGravity(Gravity.CENTER)
    hexTv.setTextSize(15)
    lay.addView(hexTv)

    local function refreshAll(rebuildSv)
        if rebuildSv ~= false then
            local bmp = buildSvBitmap()
            if bmp then svImg.setImageBitmap(bmp) end
        end
        local bw = svBox.getWidth()
        local bh = svBox.getHeight()
        if bw > 0 and bh > 0 then
            ring.setX(s * bw - RING / 2)
            ring.setY((1 - v) * bh - RING / 2)
            hueLine.setY(h / 360 * bh)
        end
        local c = currentColor()
        pcall(function() hexTv.setBackgroundColor(c) end)
        hexTv.setText("#" .. string.format("%08X", c))
        local cr = math.floor(c / 0x10000) % 0x100
        local cg = math.floor(c / 0x100) % 0x100
        local cb = c % 0x100
        local lum = (cr * 299 + cg * 587 + cb * 114) / 1000
        hexTv.setTextColor(lum > 128 and 0xFF000000 or 0xFFFFFFFF)
    end

    svBox.setOnTouchListener(function(view, event)
        local act = event.getAction()
        if act == 0 or act == 2 then
            local w = view.getWidth()
            local hh = view.getHeight()
            s = math.min(1, math.max(0, event.getX() / w))
            v = math.min(1, math.max(0, 1 - event.getY() / hh))
            refreshAll(false)
        end
        return true
    end)
    hueBox.setOnTouchListener(function(view, event)
        local act = event.getAction()
        if act == 0 or act == 2 then
            local hh = view.getHeight()
            h = math.min(360, math.max(0, event.getY() / hh * 360))
            refreshAll(true)
        end
        return true
    end)

    -- 透明度滑块
    local aRow = LinearLayout(activity)
    aRow.setOrientation(LinearLayout.HORIZONTAL)
    aRow.setGravity(Gravity.CENTER_VERTICAL)
    lay.addView(aRow)
    local aTv = TextView(activity)
    aTv.setText("透明度")
    aTv.setTextSize(13)
    aTv.setTextColor(C.TextColor)
    aTv.setLayoutParams(LinearLayout.LayoutParams(dp(52), -2))
    aRow.addView(aTv)
    local aSb = SeekBar(activity)
    aSb.setMax(100)
    aSb.setProgress(math.floor(a * 100 + 0.5))
    aSb.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
    pcall(function()  -- 滑块改深色，白底上可读
        local PorterDuff = luajava.bindClass("android.graphics.PorterDuff")
        aSb.getProgressDrawable().setColorFilter(0xFF555555, PorterDuff.Mode.SRC_IN)
        aSb.getThumb().setColorFilter(0xFF555555, PorterDuff.Mode.SRC_IN)
    end)
    aRow.addView(aSb)
    aSb.setOnSeekBarChangeListener({
        onProgressChanged = function(view, progress, fromUser)
            if fromUser then a = progress / 100 refreshAll() end
        end,
        onStartTrackingTouch = function() end,
        onStopTrackingTouch = function() end,
    })

    -- hex 直输
    local hexRow = LinearLayout(activity)
    hexRow.setOrientation(LinearLayout.HORIZONTAL)
    hexRow.setGravity(Gravity.CENTER_VERTICAL)
    lay.addView(hexRow)
    local hexEdit = EditText(activity)
    hexEdit.setSingleLine(true)
    hexEdit.setHint("手填色值，如 FFD4DFD7")
    hexEdit.setTextColor(C.TextColor)
    hexEdit.setHintTextColor(C.SubColor)
    hexEdit.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
    hexRow.addView(hexEdit)
    local btnHex = Button(activity)
    btnHex.setText("取色")
    btnHex.setAllCaps(false)
    btnHex.setTextColor(0xFF000000)
    btnHex.setLayoutParams(LinearLayout.LayoutParams(-2, -2))
    hexRow.addView(btnHex)

    refreshAll()

    btnHex.onClick = function()
        local s0 = J(hexEdit.getText()):gsub("#", ""):gsub("0x", ""):gsub("0X", "")
        local n = tonumber(s0, 16)
        if n then
            if #s0 <= 6 then n = n + 0xFF000000 end
            onPick(n)
        else
            toast("hex 无效")
        end
    end

    lay.setBackgroundColor(0xFFF7F7F9)  -- 固定浅色底，黑字可读
    local dlg = LuaDialog(activity)
    setDlgTitle(dlg, label)
    dlg.setView(lay)
    dlg.setButton("确定", function()
        onPick(currentColor())
        dlg.dismiss()
    end)
    dlg.setButton2("取消", function() dlg.dismiss() end)
    dlg.show()
    styleDlg(dlg)
    uiHandler.postDelayed(function() pcall(function() refreshAll(false) end) end, 150)
    return dlg
end

-- ========== 通用列表对话框 ==========
local function listDialog(title, items, cb)
    local dlg = LuaDialog(activity)
    setDlgTitle(dlg, title)
    local lv = ListView(activity)
    lv.setBackgroundColor(0xFFF7F7F9)  -- 固定浅色底
    local item = {
        LinearLayout;
        layout_width = "fill";
        layout_height = "wrap";
        padding = "14dp";
        {
            TextView;
            id = "tv";
            textSize = "15sp";
            textColor = "#FF000000";
            layout_width = "fill";
            layout_height = "wrap";
        };
    }
    local adapter = LuaAdapter(activity, item)
    lv.setAdapter(adapter)
    for _, s in ipairs(items) do adapter.add({tv = {text = s}}) end
    lv.onItemClick = function(l, v, p, i)
        dlg.dismiss()
        cb(items[p + 1])
    end
    dlg.setView(lv)
    dlg.show()
    styleDlg(dlg)
end

-- ========== 主界面（jqb 风格圆角卡片） ==========
local mainLayout = LinearLayout(activity)
mainLayout.setOrientation(LinearLayout.VERTICAL)
mainLayout.setBackgroundColor(C.BgColor)
mainLayout.setPadding(dp(12), dp(12), dp(12), dp(12))

local scroll = ScrollView(activity)
scroll.setLayoutParams(LinearLayout.LayoutParams(-1, -1))
mainLayout.addView(scroll)

local body = LinearLayout(activity)
body.setOrientation(LinearLayout.VERTICAL)
body.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
scroll.addView(body)

-- 顶部：主题/配色选择按钮行
local topRow = LinearLayout(activity)
topRow.setOrientation(LinearLayout.HORIZONTAL)
topRow.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
body.addView(topRow)

local function topBtn(text)
    local b = Button(activity)
    b.setText(text)
    b.setAllCaps(false)
    b.setTextColor(C.BtnText)
    b.setBackgroundDrawable(RadiuButton(C.BtnColor, dp(12)))
    local lp = LinearLayout.LayoutParams(0, -2, 1)
    lp.setMargins(dp(4), dp(4), dp(4), dp(4))
    b.setLayoutParams(lp)
    topRow.addView(b)
    return b
end

local btnTheme = topBtn("选择主题")
local btnVariant = topBtn("选择配色")

-- 测试输入框：改完颜色直接在这里打字看效果
local testRow = LinearLayout(activity)
testRow.setOrientation(LinearLayout.HORIZONTAL)
local testLp = LinearLayout.LayoutParams(-1, -2)
testLp.setMargins(0, dp(6), 0, 0)
testRow.setLayoutParams(testLp)
testRow.setPadding(dp(4), 0, dp(4), 0)
testRow.setBackgroundDrawable(RadiuButton(C.CardColor, dp(12)))
body.addView(testRow)

local testEdit = EditText(activity)
testEdit.setHint("测试输入框：调完颜色在这里打字看效果")
testEdit.setSingleLine(true)
testEdit.setTextSize(15)
testEdit.setTextColor(C.TextColor)
testEdit.setHintTextColor(C.SubColor)
testEdit.setBackgroundColor(0x00000000)
testEdit.setPadding(dp(10), dp(6), dp(10), dp(6))
testEdit.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
testRow.addView(testEdit)

local groupCards = {}  -- key -> {swatch, tv}

-- 读取某组当前颜色（第一个命中的字面量）
local function groupCurrentColor(group)
    if not styleFile then return nil, {} end
    local src = readFile(styleFile)
    if not src then return nil, {} end
    local _, found = scanAssigns(src)
    local targets = groupTargets(group, found)
    for _, p in ipairs(targets) do
        if found[p] and found[p].value then return found[p].value, targets end
    end
    return nil, targets
end

local function refreshSwatches()
    for _, g in ipairs(GROUPS) do
        local card = groupCards[g.key]
        if card then
            local color, targets = groupCurrentColor(g)
            if color then
                card.swatch.setBackgroundDrawable(RadiuButton(math.floor(color), dp(8)))
                card.tv.setText(g.label .. "\n#" .. string.format("%08X", math.floor(color) % 0x100000000)
                    .. "（" .. #targets .. " 个字段）")
            else
                card.swatch.setBackgroundDrawable(RadiuButton(C.BtnColor, dp(8)))
                card.tv.setText(g.label .. "\n" .. (styleFile and "未找到字面量字段" or "未选择配色"))
            end
        end
    end
end

for _, g in ipairs(GROUPS) do
    local card = LinearLayout(activity)
    card.setOrientation(LinearLayout.HORIZONTAL)
    card.setGravity(Gravity.CENTER_VERTICAL)
    card.setPadding(dp(14), dp(12), dp(14), dp(12))
    card.setBackgroundDrawable(RadiuButton(C.CardColor, dp(12)))
    local lp = LinearLayout.LayoutParams(-1, -2)
    lp.setMargins(0, dp(6), 0, 0)
    card.setLayoutParams(lp)
    body.addView(card)

    local swatch = View(activity)
    swatch.setLayoutParams(LinearLayout.LayoutParams(dp(44), dp(44)))
    swatch.setBackgroundDrawable(RadiuButton(C.BtnColor, dp(8)))
    card.addView(swatch)

    local tv = TextView(activity)
    tv.setText(g.label)
    tv.setTextSize(15)
    tv.setTextColor(C.TextColor)
    local tvLp = LinearLayout.LayoutParams(0, -2, 1)
    tvLp.setMargins(dp(14), 0, 0, 0)
    tv.setLayoutParams(tvLp)
    card.addView(tv)

    groupCards[g.key] = { swatch = swatch, tv = tv }

    card.onClick = function()
        if not styleFile then
            toast("请先选择主题和配色")
            return
        end
        local cur = groupCurrentColor(g)
        colorDialog(cur, g.label, function(n)
            -- 重新扫描，收集目标
            local src = readFile(styleFile)
            if not src then toast("读取样式文件失败") return end
            local _, found = scanAssigns(src)
            local targets = groupTargets(g, found)
            local edits = {}
            if #targets == 0 then
                -- 文件里没有字面量行：只对首选路径追加受管块
                edits[g.paths[1]] = n
            else
                for _, p in ipairs(targets) do edits[p] = n end
            end
            saveAndReload(edits, g.label)
            refreshSwatches()
        end)
    end
end

-- ========== 加载流程 ==========
local function loadVariant(variant)
    if not themeDir then return end
    currentVariant = variant
    if variant == "（主题 main.lua 内嵌样式）" then
        styleFile = themeDir .. "/main.lua"
    else
        styleFile = themeDir .. "/styles/" .. variant .. "/main.lua"
    end
    btnVariant.setText("配色：" .. variant)
    refreshSwatches()
end

local function loadTheme(name)
    currentTheme = name
    themeDir = getThemesRoot() .. "/" .. name
    btnTheme.setText("主题：" .. name)
    local variants = listVariants(name)
    local chosen = nil
    if #variants > 0 then
        -- 默认选当前 Config 记录的风格
        local okS, curStyle = pcall(function() return Config.getStyle() end)
        if okS and curStyle then
            for _, v0 in ipairs(variants) do
                if v0 == J(curStyle) then chosen = v0 end
            end
        end
        chosen = chosen or variants[1]
    else
        chosen = "（主题 main.lua 内嵌样式）"
    end
    loadVariant(chosen)
end

btnTheme.onClick = function()
    local themes = listThemes()
    if #themes == 0 then
        listDialog("未找到主题，已尝试以下路径", (#triedRoots > 0 and triedRoots or {"（Config 未返回任何路径）"}), function() end)
        return
    end
    listDialog("选择主题", themes, function(name) loadTheme(name) end)
end

btnVariant.onClick = function()
    if not currentTheme then
        toast("请先选择主题")
        return
    end
    local variants = listVariants(currentTheme)
    if #variants == 0 then variants = { "（主题 main.lua 内嵌样式）" } end
    listDialog("选择配色", variants, function(v0) loadVariant(v0) end)
end

-- 启动时默认载入当前主题
local okCur, cur = pcall(function() return Config.getTheme() end)
if okCur and cur then
    local name = J(cur)
    local themes = listThemes()
    for _, t in ipairs(themes) do
        if t == name then loadTheme(name) break end
    end
end

activity.setContentView(mainLayout)
