local 脚本说明 = [[
[ 02-26 18:26:18.834 23136:23136 I/@zums  ]

交流群：461685506

修改中文原版LogCat
适配脚本键盘
稍做美化
功能与原版相近，去除搜索功能

增加日志级别高亮
增加长按复制(时间信息)

增加深色配色(跟随手机深色模式切换)
增加强制模式：主题模式 = "自动", --自动/亮色/暗色
修改整体高度 最大800
去除候选栏隐藏
增加说明显示
--

使用提示：
   当某个脚本出现错误或print
   进入本脚本查看相关信息
   点击复制(去除时间部分)信息
   长按上屏
]]
import "android.widget.*"
import "android.view.*"
import "java.io.*"
import "com.osfans.trime.*"
import "android.graphics.Typeface"
import "android.content.ClipData"
import "android.os.Debug"
import "android.widget.Toast"
import "com.androlua.LuaAdapter"
import "java.lang.Error"
import "android.graphics.drawable.ColorDrawable"
import "android.text.Spannable"
import "android.text.SpannableString"
import "android.text.style.BackgroundColorSpan"
import "android.text.style.ForegroundColorSpan"
import "android.text.style.TypefaceSpan"
import "java.lang.String"
import "android.graphics.Color"

import "com.osfans.trime.TrimeApplication"
local activity = TrimeApplication.getInstance()

-- ========== 按键震动 ==========
local function keyVibrate()
    import "android.os.VibrationEffect"
    import "com.osfans.trime.theme.ThemeManager"
    local VEffect = VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE)
    ThemeManager.vibrate(VEffect)
end

onEvent = function(str)
    if this and str then
        local Event = luajava.bindClass("com.osfans.trime.Event")
        local event = Event(str)
        this.onEvent(event)
    end
end

local 主题模式 = "自动" -- 模式变量：自动/明亮/深色

local 元内边距 = "2dp"
local 内容内边距 = "10dp"
local 文字大小 = "14sp"

local 颜色表 = {
    -- 背景色
    bg = { day = "#FAFAFA", night = "#303030" }, -- 主背景
    topBg = { day = "#1A237E", night = "#006064" }, -- 顶部背景
    btnBg = { day = "#FFB300", night = "#9A7923" }, -- 按钮背景
    spinnerBg= { day = "#FFFFFF", night = "#A5A1A1" }, -- 下拉框背景
    metaBg = { day = "#E0F2F1", night = "#424242" }, -- 元背景
    popupBg = { day = "#A0D3EA", night = "#006064" }, -- 弹窗背景--只支持字符串
    -- 文字色
    text = { day = "#FFFFFF", night = "#E0E0E0" }, -- 按钮文字
    title = { day = "#FF1A237E", night = "#81D4FA" }, -- 标题
    meta = { day = "#FF004D40", night = "#80CBC4" }, -- 元信息
    content = { day = "#FF212121", night = "#EEEEEE" }, -- 正文
    divider = { day = "#FFBDBDBD", night = "#616161" }, -- 分割线

}

-- 暗色样式名列表
local DARK_STYLES = {
    ["迟暮"] = true,
    ["暗夜"] = true,
    -- 新增暗色样式在这里加
}

local LIGHT_STYLES = {
    ["禁区"] = true,
    ["黎明"] = true,
    -- 新增浅色样式在这里加
}

local function 深色模式状态()
    -- 优先判断样式名（手动切换）
    local style = Config.getStyle()
    if DARK_STYLES[style] then return true end
    if LIGHT_STYLES[style] then return false end
    -- 样式名不在名单里，才看系统UI
    local configuration = service.getResources().getConfiguration()
    return configuration.uiMode == 33
end

local function 获取颜色(name)
    if 主题模式 == "自动" then
        return 颜色表[name][深色模式状态() and "night" or "day"]
      elseif 主题模式 == "明亮" then
        return 颜色表[name].day
      elseif 主题模式 == "深色" then
        return 颜色表[name].night
      else
        error("无效的颜色模式: "..tostring(主题模式))
    end
end

local 主背景色 = 获取颜色("bg") -- 浅灰色背景
local 顶栏背景色 = 获取颜色("topBg")
local 返回背景色 = 获取颜色("btnBg") --"#FFFFB300" -- 橙色按钮
local 返回文字色 = 获取颜色("text") --"#FFFFFF"
local 选择器背景色 = 获取颜色("spinnerBg") --"#FFFFFF"
local 选择器弹窗背景色 = 获取颜色("popupBg") -- "#FFA0D3EA"  --只接受字符串

local 标题文字色 = 获取颜色("title") --"#FF1A237E" -- 深蓝色
local 元背景色 = 获取颜色("metaBg") --"#E0F2F1"
local 元文字色 = 获取颜色("meta") --"#FF004D40" -- 深青色
local 内容文字色 = 获取颜色("content") --"#FF212121" -- 深灰色
local 分割线色 = 获取颜色("divider") --"#FFBDBDBD" -- 浅灰色

local ids, layout = {}, {
    LinearLayout;
    gravity="center";
    orientation="vertical";
    layout_width="fill";
    layout_height="fill";
    background=主背景色;
    {
        LinearLayout;
        gravity="center|right";
        layout_width="fill";
        orientation="horizontal";
        padding="5dp";
        background=顶栏背景色;
        {
            Spinner;
            layout_weight="1";
            id="spinner";
            layout_margin="5dp";
            background=选择器背景色;
        };
        {
            Button;
            text="返回";
            layout_height="25dp";
            background= 返回背景色;
            textColor=返回文字色;
            textSize = "12sp";
            padding="0";
            id="back";
        };
    };
    {
        ListView;
        id="listView";
        layout_width="fill";
        layout_height="fill";
        dividerHeight=0; -- 移除默认分割线
    };
};

layout = loadlayout(layout, ids)

local blank_log = "<运行应用程序以查看其日志输出>"
local items={"全部","Lua","tag","rime", "trime", "错误","警告","信息","调试","详述","说明","清空"}

function 设置选择器视图(spinner, int)
    local adap = ArrayAdapter(activity, android.R.layout.simple_spinner_item, items)
    adap.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    spinner.setAdapter(adap)

    spinner.onItemSelected = function(_,v)
        local filter = v.Text
        -- v.setText("LogCat - "..filter)
        if 函数表[filter] then
            函数表[filter]()
        end
    end
    spinner.setPopupBackgroundDrawable(ColorDrawable(Color.parseColor(选择器弹窗背景色)))
    spinner.setSelection(int)
end

function 提示(s)
    return s
end

function 清除日志()
    p=io.popen("logcat -c")
    local s=p:read("*a")
    p:close()
    if #s==0 then
        s=blank_log
    end
    return s
end

local 日志等级颜色表 = {
    V = 0xFF000000,
    D = 0xff2196f3,
    I = 0xff4caf50,
    W = 0xffff9800,
    E = 0xfff44336
}

function 生成日志级别样式文本(原始日志行)
    local 时间部分 = 原始日志行:match("(.-)/")
    local 标题首行 = 原始日志行:match("(.-)\n")

    local 日期, 时间, 进程ID, 线程ID, 日志类型, 日志标签 = 标题首行:match(
    "^%[ *(%d+%-%d+) *(%d+:%d+:%d+%.%d+) *(%d+): *(%d+) *(%a)/([^ ]+) *%]$")

    local 标题前缀 = string.format("[%s %s %s:%s %s ", 日期, 时间, 进程ID, 线程ID, 日志类型)

    local 组合标题 = string.format("%s/%s]" , 标题前缀, 日志标签)

    local 前缀长度 = utf8.len(标题前缀)

    local 样式文本 = SpannableString(组合标题)

    -- 设置背景色块
    样式文本.setSpan(
    BackgroundColorSpan(日志等级颜色表[日志类型] or 0xff9e9e9e),
    前缀长度 - 3, 前缀长度,
    Spannable.SPAN_INCLUSIVE_INCLUSIVE
    )

    -- 设置前景色
    样式文本.setSpan(
    ForegroundColorSpan(0xFFFFFFFF),
    前缀长度 - 3, 前缀长度,
    Spannable.SPAN_INCLUSIVE_INCLUSIVE
    )

    -- 设置等宽字体
    样式文本.setSpan(
    TypefaceSpan("monospace"),
    前缀长度 - 3, 前缀长度,
    Spannable.SPAN_INCLUSIVE_INCLUSIVE
    )

    return 样式文本
end

local 日志头正则规则 = "%[ *%d+%-%d+ *%d+:%d+:%d+%.%d+ *%d+: *%d+ *%a/[^ ]+ *%]"

local items = {
    LinearLayout;
    orientation="vertical";
    layout_width="fill";
    layout_height="fill";
    gravity="bottom";
    -- background='#F8F9FF';

    {
        LinearLayout;
        orientation="vertical";
        layout_width="fill";
        background=元背景色; -- 浅青色背景
        padding=元内边距;
        {
            TextView;
            id="meta";
            textSize=文字大小;
            textColor=标题文字色;
            layout_width="fill";
            Typeface=Typeface.MONOSPACE; -- 等宽字体
        };
    };
    { -- 内容布局
        LinearLayout;
        orientation="vertical";
        layout_width="fill";
        padding=内容内边距;
        -- {
        -- TextView;
        -- id="title";
        -- textSize=文字大小;
        -- textColor=标题文字色;
        -- layout_width="fill";
        -- Typeface=Typeface.MONOSPACE; -- 等宽字体
        -- };
        {
            TextView;
            id="content";
            textSize=文字大小;
            textColor=内容文字色;
            layout_width="fill";
            Typeface=Typeface.MONOSPACE;
        };
    };
    -- { -- 分割线
    -- View;
    -- layout_width="fill";
    -- layout_height="5px";
    -- background=分割线色;
    -- };
}
local data = {}
local adapter = LuaAdapter(activity, data, items)

local function filterLog(str)
    if str:find("onRimeKey") and
        (str:find("onRimeKey: true") or str:find("onRimeKey: false")) then
      else
        return str
    end
end


function 渲染日志视图(s)

    local l=1
    local 日志正文
    local 样式化文本

    adapter.clear()

    for i in s:gfind(日志头正则规则) do
        if l~=1 then
            local str = s:sub(l,i-1)
            日志正文 = str:match("\n(.+)")
            样式化文本 =生成日志级别样式文本(str)
            adapter.add{
                meta = 样式化文本,
                content = String(日志正文).trim()
            }
        end
        l=i
    end
    if s == blank_log then
        adapter.add{meta = String(s:sub(l)).trim() }
      elseif utf8.len(s) < 18 then
        adapter.add{meta = blank_log }
      else
        local str = s:sub(l)
        日志正文 = str:match("\n(.+)")

        样式化文本 =生成日志级别样式文本(str)

        adapter.add{ meta = 样式化文本, content = String(日志正文).trim() }
    end


    adapter.notifyDataSetChanged()
    ids.listView.Adapter = adapter

    ids.listView.onItemClick = function(_,v)
        keyVibrate()
        -- if v.Tag.meta then
            -- local str = v.Tag.meta.Text
        if v.Tag.content then
            local str = v.Tag.content.Text
            if str:find("交流群") then
                复制(str:match("交流群：(%d+)\n"))
              else
                复制(str)
            end
        end
    end

    ids.listView.onItemLongClick = function(_,v)
        keyVibrate()
        if v.Tag.content then
            -- 复制(v.Tag.meta.Text)
            this.commitText(v.Tag.content.Text)
        end
        return true
    end

end

-- 自定义定义task函数
function task(func, ...)
    local args = {...}
    ids.listView.postDelayed(function()
        func(table.unpack(args))
    end, 100)
end


function 读取日志(filter)
    local p = io.popen("logcat -d -v long " .. filter)
    local s = p:read("*a")
    p:close()

    s = s:gsub("%-+ beginning of[^\n]*\n", "")

    if #filter == 0 then
        s = blank_log
    end
    return s
end

函数表 = {
    全部 = function()
        task(function()
            local log = 读取日志("*:V")
            渲染日志视图(log)
        end)
    end,

    Lua = function()
        task(function()
            --   lua:* *:S
            -- local log = 读取日志("-s lua")
            local log = 读取日志("-s TrimeService")
            渲染日志视图(log)
        end)
    end,

    tag = function()
        task(function()
            local log = 读取日志("-s TAG")
            渲染日志视图(log)
        end)
    end,

    rime = function()
        task(function()
            local log = 读取日志("-s rime")
            渲染日志视图(log)
        end)
    end,
    trime = function()
        task(function()
            local log = 读取日志("-s rime.trime")
            渲染日志视图(log)
        end)
    end,
    错误 = function()
        task(function()
            local log = 读取日志("*:E")
            渲染日志视图(log)
        end)
    end,

    警告 = function()
        task(function()
            local log = 读取日志("*:W")
            渲染日志视图(log)
        end)
    end,

    信息 = function()
        task(function()
            local log = 读取日志("*:I")
            渲染日志视图(log)
        end)
    end,

    调试 = function()
        task(function()
            local log = 读取日志("*:D")
            渲染日志视图(log)
        end)
    end,

    详述 = function()
        task(function()
            local log = 读取日志("*:V")
            渲染日志视图(log)
        end)
    end,

    说明 = function()
        task( 渲染日志视图(脚本说明))
    end,

    清空 = function()
        task(清除日志)
        task(渲染日志视图, blank_log)
    end
}



import "android.content.Context"

import "android.content.*"
local cm = activity.getSystemService(activity.CLIPBOARD_SERVICE)
function 复制(text)
    local cd = ClipData.newPlainText("log", text)
    cm.setPrimaryClip(cd)
    Toast.makeText(activity, "已复制到剪贴板", Toast.LENGTH_SHORT).show()
end

渲染日志视图(blank_log)
函数表.Lua()


设置选择器视图(ids.spinner, 1)

ids.back.onClick=function(v)
    keyVibrate()
    函数表.清空()
    ids, layout = nil, nil
    函数表 = nil
    v.postDelayed(function()
        onEvent("Keyboard_default")
    end, 100)
end

-- 适配新版 Trime：改用 this.showCustomView 显示自定义视图
this.showCustomView(layout)
