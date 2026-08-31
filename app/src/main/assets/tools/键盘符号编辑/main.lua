-- 键盘符号编辑 for trime2（v1.0）
-- 路径：rime/tools/键盘符号编辑/main.lua（同目录需有 init.lua）
-- 功能：选择主题 → 选择键盘 lua → 列出全部按键（按 click 选取），
--       只编辑五个字段：swipe_up / swipe_down / swipe_left / swipe_right / long_click，
--       手动填写符号（留空 = 删除该字段），无键盘预览，保存后立即重载。
--       仅支持「一行一个键表」的键盘文件；跨行键条目会列出但标记不可编辑。
--       UI 风格参考 jqb.lua（CS 明暗配色 + 圆角卡片）。

import "android.view.*"
import "android.widget.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "com.androlua.LuaDialog"
import "com.androlua.LuaAdapter"

local Config = luajava.bindClass("com.osfans.trime.Config")

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
    },
    night = {
        BgColor   = 0xFF181A1A,
        TextColor = 0xb9DDEBE1,
        SubColor  = 0xFFB0C4BC,
        CardColor = 0xCC232323,
        BtnColor  = 0xCC232323,
        BtnText   = 0xb9FFFFFF,
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

-- ========== 主题/键盘定位 ==========
local triedRoots = {}  -- 诊断：记录尝试过的路径

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
    local ok, dir = pcall(function() return Config.getThemeDir() end)
    if ok and dir then
        dir = J(dir):gsub("/+$", "")
        local parent = dir:gsub("/[^/]+$", "")
        table.insert(cands, dir)
        table.insert(cands, parent)
        table.insert(cands, dir .. "/themes")
    end
    local okD, dataDir = pcall(function() return Config.getDataDir() end)
    if okD and dataDir then
        dataDir = J(dataDir):gsub("/+$", "")
        local parentD = dataDir:gsub("/[^/]+$", "")
        table.insert(cands, dataDir .. "/themes")
        table.insert(cands, parentD .. "/themes")
    end
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

-- 键盘 lua 列表：keyboards/ 目录 + 主题根目录的其它 lua（排除 main.lua）
local function listKeyboards(themeName)
    local out = {}
    local themeDir0 = getThemesRoot() .. "/" .. themeName
    local kd = themeDir0 .. "/keyboards"
    if isDir(kd) then
        for _, name in ipairs(listDir(kd)) do
            if name:match("%.lua$") then table.insert(out, "keyboards/" .. name) end
        end
    end
    for _, name in ipairs(listDir(themeDir0)) do
        if name:match("%.lua$") and name ~= "main.lua" then
            table.insert(out, name)
        end
    end
    return out
end

local currentTheme, themeDir = nil, nil
local currentKbdRel, kbdFile = nil, nil

-- ========== 键盘行解析（定位 rows 内每个键条目；移植自主题编辑器 v4.0） ==========
local function splitLines(s)
    local t = {}
    s = s:gsub("\r\n", "\n")
    for line in (s .. "\n"):gmatch("(.-)\n") do table.insert(t, line) end
    if t[#t] == "" then table.remove(t) end
    return t
end

-- 返回 keys 列表：{{line=行号, multiline=bool, click=字符串或nil}, ...}
local function parseKeyboardKeys(lines)
    local keys = {}
    local inRows, depth, inKeys = false, 0, false
    local skipping = false
    for i, line in ipairs(lines) do
        local code = line:gsub('"[^"]*"', '""'):gsub("'[^']*'", "''"):gsub("%-%-.*$", "")
        if not inRows then
            -- 兼容 rows / rows_port / rows_land / local rows_xxx 等命名
            if code:match("^%s*local%s+[%w_]*rows[%w_]*%s*=%s*{%s*$")
                or code:match("^%s*[%w_]*rows[%w_]*%s*=%s*{%s*$") then
                inRows, depth = true, 1
            end
        else
            local opens = select(2, code:gsub("{", ""))
            local closes = select(2, code:gsub("}", ""))
            if skipping then
                depth = depth + opens - closes
                if depth <= 3 then skipping = false end
            else
                if depth == 2 and code:match("keys%s*=%s*{") then inKeys = true end
                if inKeys and depth == 3 and opens > 0 then
                    local multiline = (opens ~= closes)
                    local click = line:match('click%s*=%s*"([^"]*)"')
                        or line:match("click%s*=%s*'([^']*)'")
                        or line:match("click%s*=%s*([^,}%s]+)")
                    table.insert(keys, { line = i, multiline = multiline, click = click })
                    if multiline then skipping = true end
                end
                depth = depth + opens - closes
                if depth <= 2 then inKeys = false end
                if depth <= 0 then inRows = false end
            end
        end
    end
    return keys
end

-- 从键行读取字段值（字符串）
local function getKeyField(line, field)
    return line:match(field .. '%s*=%s*"([^"]*)"')
        or line:match(field .. "%s*=%s*'([^']*)'")
        or line:match(field .. "%s*=%s*([^,}%s]+)")
end

-- 在单行键表内替换/插入字段（移植自主题编辑器）
local function editKeyLine(line, field, value)
    local head, inner, tail = line:match("^(%s*{)(.*)(}%s*,?.*)$")
    if not head then return nil end
    local ser = '"' .. value:gsub('"', '\\"') .. '"'
    local function tryReplace(pat)
        local n = 0
        local s = inner:gsub(pat, function(pre) n = n + 1 return pre .. ser end, 1)
        if n > 0 then return s end
        return nil
    end
    local newInner = tryReplace("(" .. field .. "%s*=%s*)\"[^\"]*\"")
        or tryReplace("(" .. field .. "%s*=%s*)'[^']*'")
        or tryReplace("(" .. field .. "%s*=%s*)[^,}%s]+")
    if newInner then return head .. newInner .. tail end
    local trimmed = inner:gsub("%s*$", "")
    if trimmed ~= "" and not trimmed:match(",$") then trimmed = trimmed .. "," end
    return head .. trimmed .. " " .. field .. " = " .. ser .. " " .. tail
end

-- 从单行键表内删除字段（移植自主题编辑器）
local function unsetKeyLine(line, field)
    local head, inner, tail = line:match("^(%s*{)(.*)(}%s*,?.*)$")
    if not head then return nil end
    local function stripOne(pats)
        for _, p in ipairs(pats) do
            local n = 0
            inner = inner:gsub(p, function() n = n + 1 return "" end, 1)
            if n > 0 then return true end
        end
        return false
    end
    local ok = stripOne({
        ",%s*" .. field .. "%s*=%s*\"[^\"]*\"",
        ",%s*" .. field .. "%s*=%s*'[^']*'",
        ",%s*" .. field .. "%s*=%s*[^,}%s]+",
    })
    if not ok then
        ok = stripOne({
            "^(%s*)" .. field .. "%s*=%s*\"[^\"]*\"%s*,%s*",
            "^(%s*)" .. field .. "%s*=%s*'[^']*'%s*,%s*",
            "^(%s*)" .. field .. "%s*=%s*[^,}%s]+%s*,%s*",
        })
    end
    if not ok then
        ok = stripOne({
            "^(%s*)" .. field .. "%s*=%s*\"[^\"]*\"%s*$",
            "^(%s*)" .. field .. "%s*=%s*'[^']*'%s*$",
            "^(%s*)" .. field .. "%s*=%s*[^,}%s]+%s*$",
        })
    end
    if not ok then return nil end
    inner = inner:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return head .. inner .. tail
end

-- 语法校验
local function syntaxOk(src)
    if load then
        local ok, res = pcall(load, src, "@kbd", "t")
        if ok and res then return true end
    end
    if loadstring then
        if loadstring(src) then return true end
    end
    return false
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
        cb(items[p + 1], p + 1)
    end
    dlg.setView(lv)
    dlg.show()
    styleDlg(dlg)
end

-- ========== 符号编辑对话框（五项手填） ==========
local FIELDS = {
    { field = "swipe_up",    label = "上滑" },
    { field = "swipe_down",  label = "下滑" },
    { field = "swipe_left",  label = "左滑" },
    { field = "swipe_right", label = "右滑" },
    { field = "long_click",  label = "长按" },
}

local function editKeyDialog(keyInfo)
    local src = readFile(kbdFile)
    if not src then toast("读取键盘文件失败") return end
    local lines = splitLines(src)
    local line = lines[keyInfo.line]
    if not line then toast("键行定位失败") return end

    local lay = LinearLayout(activity)
    lay.setOrientation(LinearLayout.VERTICAL)
    lay.setPadding(dp(14), dp(8), dp(14), dp(4))

    local edits = {}
    for _, f in ipairs(FIELDS) do
        local row = LinearLayout(activity)
        row.setOrientation(LinearLayout.HORIZONTAL)
        row.setGravity(Gravity.CENTER_VERTICAL)
        lay.addView(row)
        local tv = TextView(activity)
        tv.setText(f.label)
        tv.setTextSize(14)
        tv.setTextColor(C.TextColor)
        tv.setLayoutParams(LinearLayout.LayoutParams(dp(56), -2))
        row.addView(tv)
        local et = EditText(activity)
        et.setSingleLine(true)
        local cur = getKeyField(line, f.field)
        if cur then et.setText(cur) end
        et.setHint("留空 = 删除")
        et.setTextColor(C.TextColor)
        et.setHintTextColor(C.SubColor)
        et.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
        row.addView(et)
        edits[f.field] = et
    end

    local tip = TextView(activity)
    tip.setText("只改动这五个字段，其余字段原样保留。")
    tip.setTextSize(12)
    tip.setTextColor(C.SubColor)
    lay.addView(tip)

    lay.setBackgroundColor(0xFFF7F7F9)  -- 固定白底黑字
    local dlg = LuaDialog(activity)
    setDlgTitle(dlg, "按键 " .. (keyInfo.click or "?"))
    dlg.setView(lay)
    dlg.setButton("保存", function()
        local newLine = line
        for _, f in ipairs(FIELDS) do
            local v = J(edits[f.field].getText()):gsub("^%s+", ""):gsub("%s+$", "")
            if v == "" then
                newLine = unsetKeyLine(newLine, f.field) or newLine
            else
                newLine = editKeyLine(newLine, f.field, v) or newLine
            end
        end
        if newLine == line then dlg.dismiss() return end
        lines[keyInfo.line] = newLine
        local newSrc = table.concat(lines, "\n")
        if not syntaxOk(newSrc) then
            toast("改写后语法校验失败，未写入")
            return
        end
        writeFile(kbdFile .. ".bak", src)  -- 改前自动备份
        local ok, err = writeFile(kbdFile, newSrc .. "\n")
        dlg.dismiss()
        if not ok then toast("写入失败：" .. tostring(err)) return end
        -- 立即重载（trime2 有键盘视图缓存，必须 setTheme 重建）
        pcall(function()
            local TrimeService = luajava.bindClass("com.osfans.trime.TrimeService")
            local ts = TrimeService.getInstance()
            if ts then ts.setTheme(currentTheme) end
        end)
        toast("已保存并重载")
    end)
    dlg.setButton2("取消", function() dlg.dismiss() end)
    dlg.show()
    styleDlg(dlg)
end

-- ========== 按键列表 ==========
local keyInfos = {}

local function refreshKeyList()
    keyListLayout.removeAllViews()
    if not kbdFile then return end
    local src = readFile(kbdFile)
    if not src then toast("读取键盘文件失败") return end
    local lines = splitLines(src)
    keyInfos = parseKeyboardKeys(lines)
    local editable = 0
    for _, k in ipairs(keyInfos) do if not k.multiline then editable = editable + 1 end end
    tipTv.setText("共 " .. #keyInfos .. " 键，可编辑 " .. editable .. " 个"
        .. (editable < #keyInfos and "（跨行键不可编辑）" or ""))

    for idx, k in ipairs(keyInfos) do
        local card = LinearLayout(activity)
        card.setOrientation(LinearLayout.HORIZONTAL)
        card.setGravity(Gravity.CENTER_VERTICAL)
        card.setPadding(dp(14), dp(10), dp(14), dp(10))
        card.setBackgroundDrawable(RadiuButton(C.CardColor, dp(12)))
        local lp = LinearLayout.LayoutParams(-1, -2)
        lp.setMargins(0, dp(5), 0, 0)
        card.setLayoutParams(lp)
        keyListLayout.addView(card)

        local tv = TextView(activity)
        local line = lines[k.line] or ""
        local cur = {}
        for _, f in ipairs(FIELDS) do
            local v = getKeyField(line, f.field)
            if v then table.insert(cur, f.label .. ":" .. v) end
        end
        local name = k.click or ("行" .. k.line)
        tv.setText(name .. (k.multiline and "（跨行，不可编辑）" or "")
            .. (#cur > 0 and ("\n" .. table.concat(cur, "  ")) or ""))
        tv.setTextSize(14)
        tv.setTextColor(k.multiline and C.SubColor or C.TextColor)
        tv.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
        card.addView(tv)

        if not k.multiline and k.click then
            card.onClick = function() editKeyDialog(k) end
        end
    end
end

-- ========== 主界面 ==========
mainLayout = LinearLayout(activity)
mainLayout.setOrientation(LinearLayout.VERTICAL)
mainLayout.setBackgroundColor(C.BgColor)
mainLayout.setPadding(dp(12), dp(12), dp(12), dp(12))

local topRow = LinearLayout(activity)
topRow.setOrientation(LinearLayout.HORIZONTAL)
topRow.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
mainLayout.addView(topRow)

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
local btnKbd = topBtn("选择键盘")

-- 测试输入框：改完符号直接在这里试滑动/长按
local testRow = LinearLayout(activity)
testRow.setOrientation(LinearLayout.HORIZONTAL)
local testLp = LinearLayout.LayoutParams(-1, -2)
testLp.setMargins(0, dp(6), 0, 0)
testRow.setLayoutParams(testLp)
testRow.setPadding(dp(4), 0, dp(4), 0)
testRow.setBackgroundDrawable(RadiuButton(C.CardColor, dp(12)))
mainLayout.addView(testRow)

local testEdit = EditText(activity)
testEdit.setHint("测试输入框：改完符号在这里试滑动/长按")
testEdit.setSingleLine(true)
testEdit.setTextSize(15)
testEdit.setTextColor(C.TextColor)
testEdit.setHintTextColor(C.SubColor)
testEdit.setBackgroundColor(0x00000000)
testEdit.setPadding(dp(10), dp(6), dp(10), dp(6))
testEdit.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
testRow.addView(testEdit)

tipTv = TextView(activity)
tipTv.setText("请先选择主题和键盘")
tipTv.setTextSize(12)
tipTv.setTextColor(C.SubColor)
mainLayout.addView(tipTv)

local scroll = ScrollView(activity)
scroll.setLayoutParams(LinearLayout.LayoutParams(-1, -1))
mainLayout.addView(scroll)

keyListLayout = LinearLayout(activity)
keyListLayout.setOrientation(LinearLayout.VERTICAL)
keyListLayout.setLayoutParams(LinearLayout.LayoutParams(-1, -2))
scroll.addView(keyListLayout)

-- ========== 加载流程 ==========
local function loadKeyboard(rel)
    if not themeDir then return end
    currentKbdRel = rel
    kbdFile = themeDir .. "/" .. rel
    btnKbd.setText("键盘：" .. rel:gsub("%.lua$", ""):gsub("keyboards/", ""))
    refreshKeyList()
end

local function loadTheme(name)
    currentTheme = name
    themeDir = getThemesRoot() .. "/" .. name
    btnTheme.setText("主题：" .. name)
    local kbds = listKeyboards(name)
    if #kbds > 0 then
        -- 默认选中当前方案实际在用的键盘
        local active = nil
        local okK, activeId = pcall(function() return Config.getKeyboard() end)
        if okK and activeId then
            local want = J(activeId) .. ".lua"
            for _, f in ipairs(kbds) do
                if f:gsub("keyboards/", "") == want then active = f end
            end
        end
        loadKeyboard(active or kbds[1])
    else
        kbdFile = nil
        btnKbd.setText("选择键盘")
        keyListLayout.removeAllViews()
        tipTv.setText("该主题没有键盘 lua 文件")
    end
end

btnTheme.onClick = function()
    local themes = listThemes()
    if #themes == 0 then
        listDialog("未找到主题，已尝试以下路径", (#triedRoots > 0 and triedRoots or {"（Config 未返回任何路径）"}), function() end)
        return
    end
    listDialog("选择主题", themes, function(name) loadTheme(name) end)
end

btnKbd.onClick = function()
    if not currentTheme then
        toast("请先选择主题")
        return
    end
    local kbds = listKeyboards(currentTheme)
    if #kbds == 0 then
        toast("该主题没有键盘 lua 文件")
        return
    end
    listDialog("选择键盘", kbds, function(f) loadKeyboard(f) end)
end

-- 启动时默认载入当前主题
local okCur, cur = pcall(function() return Config.getTheme() end)
if okCur and cur then
    local name = J(cur)
    for _, t in ipairs(listThemes()) do
        if t == name then loadTheme(name) break end
    end
end

activity.setContentView(mainLayout)
