--[[
 中文输入法2 emoji脚本
 AZNixl | Kimi K3
========================================================================
  · 顶部：分类标签条（可横滑），点击跳到该分类；滚动时自动高亮当前分类
  · 「最近」分栏：自动记录最近使用的表情（排最前，去重，上限 CONFIG.RECENT_MAX），
    持久化在 rime/emoji_recent.json；本分栏内新点的表情下次打开键盘时入列
  · 进度条按分栏独立计算：滑到哪个分栏就显示哪个分栏的进度，
    进入新分栏进度归零重滑
  · 中间：四行横向滚动表情流，左右划动查找
  · 网格下方：细分段进度条指示滚动位置
  · 底部：迷你键行——返回键 + 空格 + 退格键
  · 配色跟随样式明暗（迟暮/暗夜→深色，尘白/黎明→浅色，其余跟系统）

【安装】
  1. 本文件放到 rime/theme/你的主题/scripts/ 目录
  2. 主题 main.lua 的 preset_keys 里加：
       emoji { label = "表情", command = "emoji.lua" },
  3. 某个按键里绑 :click = "emoji"

【可调参数】（下面 CONFIG）
  ROWS       行数，默认 3
  CELL_DP    每格边长 dp，默认 46
  EMOJI_SP   表情字号，默认 20
========================================================================]]

import "android.widget.*"
import "android.view.View"
import "android.view.Gravity"
import "android.view.KeyEvent"
import "android.os.Handler"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.Typeface"
import "android.os.VibrationEffect"
import "com.osfans.trime.theme.ThemeManager"
import "com.osfans.trime.Config"
import "android.preference.PreferenceManager"
import "com.osfans.trime.JsonUtil"
import "java.io.File"
import "java.util.ArrayList"

local this = rawget(_G, "this") or luajava.bindClass("com.osfans.trime.TrimeService").getInstance()
local service = rawget(_G, "service") or this
local handler = Handler()

local CONFIG = {
    ROWS = 4,        -- 表情流行数
    CELL_DP = 46,    -- 每格边长（dp）
    EMOJI_SP = 20,   -- 表情字号（sp）
    RECENT_MAX = 20, -- 最近使用表情记录上限
    RECENT_SHOW = 30, -- 最近分栏只显示最近使用的 N 个
}

local function dp2px(dp)
    local density = service.getResources().getDisplayMetrics().density
    return math.floor(dp * density + 0.5)
end

-- ========== 配色 ==========
local cs = {
    light = {
        ClipBColor      = 0xFFE3E4E9,  -- 底板
        TextColor       = 0xFF000000,
        CardBColor      = 0xFFF7F7F9,  -- 卡片
        ButtonColor     = 0xFFF4F4F4,  -- 胶囊按钮
        ButtonTextColor = 0xFF000000,
        ActiveColor     = 0xFF30C190,  -- 强调绿（滑块/选中标签）
        TabTrackColor   = 0xFFD7D8DD,  -- 滑块轨道
    },
    night = {
        ClipBColor      = 0xFF181A1A,
        TextColor       = 0xb9DDEBE1,
        CardBColor      = 0xCC232323,
        ButtonColor     = 0xCC232323,
        ButtonTextColor = 0xb9FFFFFF,
        ActiveColor     = 0xFF30C190,
        TabTrackColor   = 0xFF2E302E,
    }
}
local DARK_STYLES = { ["迟暮"] = true, ["暗夜"] = true }
local LIGHT_STYLES = { ["尘白"] = true, ["黎明"] = true }

-- 读取当前样式 enter 键的 background 颜色（luaj 原生表直读；图片/失败返回 nil）
local function getEnterBgColor()
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
            local c = ks.getColor("background", 0x01020304)
            if c == nil or c == 0x01020304 then return nil end
            return c
        end
        return nil
    end)
    if ok then return result end
    return nil
end

local function getColors()
    local style = nil
    pcall(function() style = Config.getStyle() end)
    if style and DARK_STYLES[style] then return cs.night end
    if style and LIGHT_STYLES[style] then return cs.light end
    local config = service.getResources().getConfiguration()
    if config.uiMode and config.uiMode > 30 then return cs.night end
    return cs.light
end

local C = getColors()
local ActiveColor = getEnterBgColor() or C.ActiveColor

local function RadiuButton(color, radius)
    local shape = GradientDrawable()
    shape.setShape(GradientDrawable.RECTANGLE)
    shape.setCornerRadius(radius)
    shape.setColor(color)
    shape.setStroke(0, 0x00000000)
    return shape
end

local function keyVibrate()
    pcall(function()
        local ve = VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE)
        ThemeManager.vibrate(ve)
    end)
end


-- 已打开则关闭（再点一次按键=收起）
if _G.__emoji_panel_shown then
    _G.__emoji_panel_shown = false
    pcall(function() this.showCustomView(nil) end)
    return
end

local function closePanel()
    _G.__emoji_panel_shown = false
    pcall(function() this.showCustomView(nil) end)
end
local key_maps = {
    -- 1. 社交最常用 (Social & Emotion)
    {
        name = "表情",
        keys = { "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "🫠", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "☺", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🫢", "🫣", "🤫", "🤔", "🫡", "🤐", "🤨", "😐", "😑", "😶", "🫥", "😏", "😒", "🙄", "😬", "🤥", "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕", "🤢", "🤮", "🤧", "🥵", "🥶", "🥴", "😵", "🤯", "🤠", "🥳", "🥸", "😎", "🤓", "🧐", "😕", "🫤", "😟", "🙁", "☹", "😮", "😯", "😲", "😳", "🥺", "🥹", "😦", "😧", "😨", "😰", "😥", "😢", "😭", "😱", "😖", "😣", "😞", "😓", "😩", "😫", "🥱", "😤", "😡", "😠", "🤬", "😈", "👿", "💀", "☠️", "💩", "🤡", "👹", "👺", "👻", "👽", "👾", "🤖" }
    },
    {
        name = "爱心",
        keys = { "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "💌", "💋", "💏", "👩‍❤️‍💋‍👨", "💑", "👩‍❤️‍👨" }
    },
    {
        name = "手势",
        keys = { "👋", "🤚", "🖐", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🫰", "🤟", "🤘", "🤙", "👈", "👉", "👆", "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛", "🤜", "👏", "🙌", "🫶", "👐", "🤲", "🤝", "🙏", "✍️", "💅", "🤳", "💪", "🦾" }
    },

    -- 2. 人物与职场 (People & Work)
    {
        name = "人物",
        keys = { "👶", "👧", "🧒", "👦", "👩", "🧑", "👨", "👩‍🦱", "🧑‍🦱", "👨‍🦱", "👩‍🦰", "🧑‍🦰", "👨‍🦰", "👱‍♀️", "👱", "👱‍♂️", "👩‍🦳", "🧑‍🦳", "👨‍🦳", "👩‍🦲", "🧑‍🦲", "👨‍🦲", "👵", "🧓", "👴", "👲", "🧕", "🤵", "👰", "🤰", "🤱", "👼" }
    },
    {
        name = "职业",
        keys = { "🧑‍🏫", "🧑‍🎓", "🧑‍💻", "🧑‍⚖️", "🧑‍🎨", "🧑‍🍳", "🧑‍🔧", "🧑‍🏭", "🧑‍🔬", "🧑‍🚀", "🧑‍🚒", "👮", "🕵️", "💂", "👷", "🤴", "👸", "🎅", "🧙", "🧚", "🧛", "🧜", "🧝", "🧞", "🧟" }
    },

    -- 3. 动植物与气象 (Nature & Weather)
    {
        name = "动物",
        keys = { "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐻‍❄️", "🐨", "🐯", "🦁", "🐮", "🐷", "🐽", "🐸", "🐵", "🐒", "🦍", "🦧", "🐔", "🐧", "🐦", "🐤", "🐣", "🐥", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", "🐞", "🐜", "🦟", "🦗", "🕷️", "🦂", "🐢", "🐍", "🦎", "🦖", "🦕", "🐙", "🦑", "🦐", "🦞", "🦀", "🐡", "🐠", "🐟", "🐬", "🐳", "🐋", "🦈", "🦭" }
    },
    {
        name = "植物",
        keys = { "🌵", "🎄", "🌲", "🌳", "🌴", "🌱", "🌿", "☘️", "🍀", "🎍", "🎋", "🍃", "🍂", "🍁", "🍄", "🌾", "💐", "🌷", "🌹", "🥀", "🌺", "🌸", "🌼", "🌻" }
    },
    {
        name = "气象",
        keys = { "☀️", "🌤️", "⛅", "🌥️", "☁️", "🌦️", "🌧️", "⛈️", "🌩️", "❄️", "☃️", "⛄", "🌬️", "💨", "🌪️", "🌫️", "🌈", "🌊", "💧", "💦", "☔", "⚡", "☄️", "🔥", "💥", "🌙", "🌚", "🌕", "⭐", "🪐", "🌍" }
    },

    -- 4. 生活方式 (Lifestyle)
    {
        name = "食物",
        keys = { "🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒", "🌶️", "🫑", "🌽", "🥕", "🫒", "🧄", "🧅", "🥔", "🍠", "🥐", "🥯", "🍞", "🥖", "🥨", "🧀", "🥚", "🍳", "🧈", "🥞", "🧇", "🥓", "🥩", "🍗", "🍖", "🌭", "🍔", "🍟", "🍕", "🥪", "🌮", "🌯", "🥙", "🍝", "🍜", "🍲", "🍛", "🍣", "🍱", "🥟", "🍤", "🍙", "🍚", "🍘", "🍢", "🍡", "🍧", "🍨", "🍦", "🥧", "🍰", "🎂", "🍮", "🍭", "🍬", "🍫", "🍿", "🍩", "🍪" }
    },
    {
        name = "饮品",
        keys = { "🍼", "🥛", "☕", "🍵", "🧃", "🥤", "🧋", "🍶", "🍺", "🍻", "🥂", "🍷", "🥃", "🍸", "🍹", "🧉", "🍾", "🧊" }
    },
    {
        name = "运动",
        keys = { "⚽", "🏀", "🏈", "⚾", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🏹", "⛳", "🪁", "🛹", "🛼", "⛸️", "🎿", "🏂", "🪂", "🏋️", "🤼", "🤸", "⛹️", "🤺", "🤾", "🏌️", "🏇", "🧘" }
    },

    -- 5. 交通与建筑 (Travel & Buildings)
    {
        name = "建筑",
        keys = { "🏠", "🏡", "🏢", "🏣", "🏤", "🏥", "🏦", "🏨", "🏩", "🏪", "🏫", "🏬", "🏭", "🏯", "🏰", "💒", "🗼", "🗽", "🏛️", "⛪", "🕌", "⛩️", "🕍", "🏗️", "🏘️", "🏚️" }
    },
    {
        name = "交通",
        keys = { "🚂", "🚄", "🚅", "🚆", "🚇", "🚝", "🚋", "🚌", "🚐", "🚑", "🚒", "🚓", "🚕", "🚗", "🚙", "🚚", "🚜", "🚲", "🛴", "🏍️", "🛺", "🛸", "🚀", "🚁", "✈️", "🛫", "🛬", "🚢", "🛥️", "⛵", "⚓", "🛶" }
    },

    -- 6. 物品与办公 (Objects & Tools)
    {
        name = "办公",
        keys = { "📁", "📂", "📄", "📃", "📑", "📇", "📈", "📉", "📊", "📋", "📌", "📍", "📎", "🖇️", "📏", "📐", "✂️", "📒", "📓", "📔", "📕", "📖", "📗", "📘", "📙", "📱", "💻", "⌨️", "🖱️", "🖲️", "🕹️", "🎮", "💽", "💾", "💿", "📀", "📷", "📸", "📹", "🎥", "📽️", "🎞️", "📞", "☎️", "📠", "📺", "📻", "🎙️", "🎚️", "🎛️", "🧭" }
    },
    {
        name = "工具",
        keys = { "⚖️", "🔧", "🔨", "⚒️", "🛠️", "⛏️", "🪚", "🔩", "⚙️", "🪜", "🧰", "🧲", "🧪", "🧫", "🧬", "🔬", "💉", "🩸", "💊", "🩹", "🩺", "🛡️", "🏹", "🗡️", "⚔️", "🔫", "💣" }
    },
    {
        name = "家居",
        keys = { "💡", "🔦", "🕯️", "🏮", "🧱", "💸", "💵", "💴", "💶", "💷", "💰", "💳", "💎", "🎁", "🎈", "🎊", "🎉", "🎎", "🎐", "🧧", "✉️", "📩", "📦", "🏷️", "🛀", "🛌", "🛋️", "🪑", "🚽", "🚿", "🧼", "🪥", "🧽", "🧹", "🧺", "🧻", "🚬", "⚰️", "🏺" }
    },

    -- 7. 符号与指示 (Symbols & Indicators)
    {
        name = "标志",
        keys = { "☮️", "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️", "☦️", "🛐", "⛎", "♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓", "🆔", "⚛️", "☢️", "☣️", "📴", "📳", "🈶", "🈚", "🈸", "🈺", "🈷️", "✴️", "🆚", "💮", "🉐", "㊙️", "㊗️", "🈴", "🈵", "🈹", "🈲", "🅰️", "🅱️", "🆎", "🆑", "🅾️", "🆘", "❌", "⭕", "🛑", "⛔", "📛", "🚫", "💯", "💢", "♨️" }
    },
    {
        name = "指示",
        keys = { "❗", "❕", "❓", "❔", "‼️", "⁉️", "🔅", "🔆", "〽️", "⚠️", "🚸", "🔱", "⚜️", "🔰", "♻️", "✅", "🈯", "💹", "❇️", "✳️", "❎", "🌐", "💠", "Ⓜ️", "🌀", "💤", "🏧", "🚾", "♿", "🅿️", "🈳", "🈂️", "🛂", "🛃", "🛄", "🛅", "🚹", "🚺", "🚼", "⚧️", "🚻", "📶", "🎦" }
    },
    {
        name = "媒体",
        keys = { "🔼", "🔽", "◀️", "▶️", "⏭️", "⏮️", "⏯️", "⏹️", "⏺️", "⏏️", "🎦", "🔅", "🔆", "📶", "📳", "📴", "🔄", "🔃", "🎵", "🎶", "➕", "➖", "✖️", "➗", "♾️", "💲", "💱" }
    },
    {
        name = "数字",
        keys = { "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟", "🔢", "🔣", "🔤", "🔡", "🔠" }
    },
    {
        name = "几何",
        keys = { "🔴", "🟠", "🟡", "🟢", "🔵", "🟣", "🟤", "⚫", "⚪", "🟥", "🟧", "🟨", "🟩", "🟦", "🟪", "🟫", "⬛", "⬜", "🔶", "🔷", "🔸", "🔹", "🔺", "🔻", "💠", "🔘", "🔳", "🔲" }
    },
    {
        name = "旗帜",
        keys = { "🏁", "🚩", "🎌", "🏴", "🏳️", "🏳️‍🌈", "🏳️‍⚧️", "🏴‍☠️", "🇨🇳", "🇭🇰", "🇲🇴", "🇯🇵", "🇰🇷", "🇺🇸", "🇬🇧", "🇫🇷", "🇩🇪", "🇮🇹", "🇷🇺", "🇨🇦", "🇦🇺", "🇸🇬" }
    },
    {
        name = "时间",
        keys = {
            "🕛", "🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚",
            "🕧", "🕜", "🕝", "🕞", "🕟", "🕠", "🕡", "🕢", "🕣", "🕤", "🕥", "🕦",
            "📅", "📆", "🗓️", "🗒️", "⌛", "⏳", "⌚", "⏰", "⏱️", "⏲️", "🕰️",
            "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘", "🌙", "☀️", "🌅", "🌇", "🌃", "🔜", "🔙", "🆕"
        }
    },

    {
        name = "数学",
        keys = { "±", "×", "÷", "∧", "∨", "∑", "∏", "√", "∫", "∬", "∭", "∂", "∆", "∝", "∞", "＝", "≠", "≈", "≌", "≡", "≤", "≥", "∈", "∉", "∩", "∪", "⊆", "⊇", "⊂", "⊃", "⊕", "⊗", "∀", "∃", "∴", "∵", "∷", "∠", "⊥", "∥", "⌒", "⊙", "§" }
    },
    {
        name = "特殊",
        keys = {
            "★", "☆", "✦", "✧", "✨", "🌟", "✪", "❂", "✫", "✬", "✭", "✮", "✯", "☪",
            "☀", "☼", "☽", "☾", "◑", "◐", "☄", "🌡", "☁", "☂", "☃",
            "♪", "♫", "♬", "♩", "♭", "♯", "♮", "🎹", "🎸", "🎻", "🎺",
            "☎", "☏", "📠", "✉", "⌨", "🖱", "🖨",
            "✂", "✁", "✎", "📝", "✒", "✍", "🎨", "🎬", "📢", "📣",
            "♀", "♂", "⚧", "⚥", "⚢", "⚣", "♾", "♿", "♻", "♲", "☠", "☭", "☮", "☯", "卍", "卐",
            "§", "¶", "†", "‡", "№", "™", "®", "©", "℗", "㏇", "℡",
            "◎", "¤", "۞", "◈", "❖", "⚜", "🔱", "🔰", "💠", "🔘",
            "☜", "☞", "☝", "☟", "☚", "☛", "✌", "🗑", "🛒", "🛍",
        }
    },
    {
        name = "单位",
        keys = { "℃", "℉", "°", "％", "‰", "‱", "￥", "¥", "$", "€", "£", "₠", "฿", "￠", "㎡", "㎕", "㎖", "㎗", "ℓ", "㎝", "㎞", "㎏", "㏔", "㏗", "㏄", "℅" }
    },
    {
        name = "列表",
        keys = { "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩", "⒈", "⒉", "⒊", "⒋", "⒌", "⒍", "⒎", "⒏", "⒐", "⒑", "⒒", "⒓", "⒔", "⒕", "⒖", "⒗", "⒘", "⒙", "⒚", "⒛", "⑴", "⑵", "⑶", "⑷", "⑸", "⑹", "⑺", "⑻", "⑼", "⑽", "⑾", "⑿", "⒀", "⒁", "⒂", "⒃", "⒄", "⒅", "⒆", "⒇", "㈠", "㈡", "㈢", "㈣", "㈤", "㈥", "㈦", "㈧", "㈨", "㈩", "➊", "➋", "➌", "➍", "➎", "➏", "➐", "➑", "➒", "➓", "㊀", "㊁", "㊂", "㊃", "㊄", "㊅", "㊆", "㊇", "㊈", "㊉", "ⅰ", "ⅱ", "ⅲ", "ⅳ", "ⅴ", "ⅵ", "ⅶ", "ⅷ", "ⅸ", "ⅹ", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ", "Ⅹ" }
    },
    {
        name = "箭头",
        keys = {
            -- 基础方向
            "↑", "↓", "←", "→", "↖", "↗", "↘", "↙", "↔", "↕",
            -- 粗体与加重
            "➔", "➤", "➥", "➦", "➧", "➨", "➚", "➘", "➙", "➛", "➜", "➝", "➞",
            -- 装饰与手写感
            "➸", "➲", "➳", "➵", "➴", "➶", "➷", "➹",
            -- 指示与双线
            "⇦", "⇨", "⇧", "⇩", "⇐", "⇒", "⇔", "⇕", "⇖", "⇗", "⇘", "⇙",
            -- 循环与翻转
            "↩", "↪", "↫", "↬", "🔃", "🔄", "🔁", "🔙", "🔚"
        }
    },
    {
        name = "角标",
        keys = { "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹", "⁺", "⁻", "⁼", "⁽", "⁾", "ⁿ", "ˣ", "ʸ", "ⁱ", "₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉", "₊", "₋", "₌", "₍", "₎", "ₙ", "ₑ", "ₓ", "ᵧ", "ᵢ" }
    },
    {
        name = "制表",
        keys = { "─", "━", "│", "┃", "┄", "┅", "┆", "┇", "┈", "┉", "┊", "┋", "┌", "┍", "┎", "┏", "┐", "┑", "┒", "┓", "└", "┕", "┖", "┗", "┘", "┙", "┚", "┛", "├", "┝", "┞", "┟", "┠", "┡", "┢", "┣", "┤", "┥", "┦", "┧", "┨", "┩", "┪", "┫", "┬", "┭", "┮", "┯", "┰", "┱", "┲", "┳", "┴", "┵", "┶", "┷", "┸", "┹", "┺", "┻", "┼", "┽", "┾", "┿", "╀", "╁", "╂", "╃", "╄", "╅", "╆", "╇", "╈", "╉", "╊", "╋" }
    },
    {
        name = "拼音",
        keys = { "ā", "á", "ǎ", "à", "ō", "ó", "ē", "é", "ě", "è", "ǒ", "ò", "ī", "í", "ǐ", "ì", "ū", "ú", "ǖ", "ǘ", "ǚ", "ǜ", "ǔ", "ù", "ê", "ḿ", "ü", "ń", "ň", "ǹ", "ㄚ", "ㄛ", "ㄜ", "ㄧ", "ㄨ", "ㄩ", "ㄝ", "ㄞ", "ㄟ", "ㄠ", "ㄡ", "ㄢ", "ㄣ", "ㄤ", "ㄥ", "ㄦ", "ㄅ", "ㄆ", "ㄇ", "ㄈ", "ㄉ", "ㄊ", "ㄋ", "ㄌ", "ㄍ", "ㄎ", "ㄏ", "ㄐ", "ㄑ", "ㄒ", "ㄓ", "ㄔ", "ㄕ", "ㄖ", "ㄗ", "ㄘ", "ㄙ" }
    },
    {
        name = "𝒶𝒜",
        keys = { "𝒶", "𝒷", "𝒸", "𝒹", "ℯ", "𝒻", "ℊ", "𝒽", "𝒾", "𝒿", "𝓀", "𝓁", "𝓂", "𝓃", "ℴ", "𝓅", "𝓆", "𝓇", "𝓈", "𝓉", "𝓊", "𝓋", "𝓌", "𝓍", "𝓎", "𝓏", "𝒜", "ℬ", "𝒞", "𝒟", "ℰ", "ℱ", "𝒢", "ℋ", "ℐ", "𝒥", "𝒦", "ℒ", "ℳ", "𝒩", "𝒪", "𝒫", "𝒬", "ℛ", "𝒮", "𝒯", "𝒰", "𝒱", "𝒲", "𝒳", "𝒴", "𝒵" }
    },
    {
        name = "希腊",
        keys = { "Α", "Β", "Γ", "Δ", "Ε", "Ζ", "Η", "Θ", "Ι", "Κ", "Λ", "Μ", "Ν", "Ξ", "Ο", "Π", "Ρ", "Σ", "Τ", "Υ", "Φ", "Χ", "Ψ", "Ω", "α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ", "ν", "ξ", "ο", "π", "ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω" }
    },
    {
        name = "俄语",
        keys = { "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я", "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я" }
    },
    {
        name = "拉丁",
        keys = { "À", "Á", "Â", "Ã", "Ä", "Å", "Æ", "Ç", "È", "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï", "Ð", "Ñ", "Ò", "Ó", "Ô", "Õ", "Ö", "Ø", "Ù", "Ú", "Û", "Ü", "Ý", "Þ", "Š", "Ÿ", "Œ", "à", "á", "â", "ã", "ä", "å", "æ", "ç", "è", "é", "ê", "ë", "ì", "í", "î", "ï", "ð", "ñ", "ò", "ó", "õ", "ô", "ö", "ø", "ù", "ú", "û", "ü", "ý", "þ", "š", "ÿ", "œ" }
    },
    {
        name = "韩文",
        keys = { "ㅏ", "ㅑ", "ㅓ", "ㅕ", "ㅗ", "ㅛ", "ㅜ", "ㅠ", "ㅡ", "ㅣ", "ㅐ", "ㅒ", "ㅔ", "ㅖ", "ㅘ", "ㅙ", "ㅚ", "ㅝ", "ㅞ", "ㅟ", "ㅢ", "ㄱ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ", "ㅅ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ", "ㄲ", "ㄸ", "ㅆ", "ㅉ", "㉠", "㉡", "㉢", "㉣", "㉤", "㉥", "㉦", "㉧", "㉨", "㉩", "㉪", "㉫", "㉬", "㉭", "㉮", "㉯", "㉰", "㉱", "㉲", "㉳", "㉴", "㉵", "㉶", "㉷", "㉸", "㉹", "㉺", "㉻" }
    },
    {
        name = "假名",
        keys = { "あ", "い", "う", "え", "お", "か", "が", "き", "ぎ", "く", "ぐ", "け", "げ", "こ", "ご", "さ", "ざ", "し", "じ", "す", "ず", "せ", "ぜ", "そ", "ぞ", "た", "だ", "ち", "ぢ", "つ", "づ", "て", "で", "と", "ど", "な", "に", "ぬ", "ね", "の", "は", "ば", "ぱ", "ひ", "び", "ぴ", "ふ", "ぶ", "ぷ", "へ", "べ", "ぺ", "ほ", "ぼ", "ぽ", "ま", "み", "む", "め", "も", "ゃ", "や", "ゅ", "ゆ", "ょ", "よ", "ら", "り", "る", "れ", "ろ", "わ", "を", "ん", "ア", "イ", "ウ", "エ", "オ", "カ", "ガ", "キ", "ギ", "ク", "グ", "ケ", "ゲ", "コ", "ゴ", "サ", "ザ", "シ", "ジ", "ス", "ズ", "セ", "ゼ", "ソ", "ゾ", "タ", "ダ", "チ", "ヂ", "ツ", "ヅ", "テ", "デ", "ト", "ド", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "バ", "パ", "ヒ", "ビ", "ピ", "フ", "ブ", "プ", "ヘ", "ベ", "ペ", "ホ", "ボ", "ポ", "マ", "ミ", "ム", "メ", "モ", "ャ", "ヤ", "ュ", "ユ", "ョ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ワ", "ヲ", "ン" }
    },
    {
        name = "音标",
        -- 保持不变（已经是列表），音标如 "a:" 视为一个项
        keys = { "a:", "ɔ:", "ɜː", "i:", "u:", "ʌ", "ɒ", "ə", "ɪ", "ʊ", "e", "æ", "eɪ", "aɪ", "ɔɪ", "ɪə", "eə", "ʊə", "əʊ", "aʊ", "p", "t", "k", "f", "θ", "s", "b", "d", "g", "v", "ð", "z", "ʃ", "h", "ts", "tʃ", "j", "tr", "ʒ", "r", "dz", "dʒ", "dr", "w", "m", "n", "ŋ", "l" }
    },
    {
        name = "颜文字",
        keys = { "(=^･ω･^=)", "(๑•̀ㅂ•́)و✧", "(*^▽^*)", "(｡･ω･｡)", "ヘ( ^o^)ノ", "╮(￣▽￣)╭", "_(：3 」∠)_", "QAQ", "o(╥﹏╥)o", "( ͡° ͜ʖ ͡°)", "Hi~ o(*￣▽￣*)ブ", "m(_ _)m", "(๑′ᴗ‵๑)Ｉ Lᵒᵛᵉᵧₒᵤ♥", "∑(っ°Д°;)っ", "(￣▽￣\")" }
    },
    {
        name = "IDS",
        keys = { "⿰", "⿱", "⿲", "⿳", "⿴", "⿵", "⿶", "⿷", "⿸", "⿹", "⿺", "⿻", "↷", "↔" }
    }
}-- ========== 最近使用（持久化 rime/emoji_recent.json） ==========
local recentFile = File("/storage/emulated/0/Documents/rime", "emoji_recent.json")
local function loadRecents()
    local t = {}
    if not recentFile.exists() then return t end
    pcall(function()
        local list = JsonUtil.load(recentFile)
        if list then for i = 0, list.size() - 1 do table.insert(t, list.get(i)) end end
    end)
    return t
end
local function saveRecents(t)
    pcall(function()
        local list = luajava.newInstance("java.util.ArrayList")
        for _, v in ipairs(t) do list.add(v) end
        JsonUtil.save(recentFile, list)
    end)
end
local recents = loadRecents()
local function addRecent(emoji)
    for i, v in ipairs(recents) do
        if v == emoji then table.remove(recents, i) break end
    end
    table.insert(recents, 1, emoji)
    while #recents > CONFIG.RECENT_MAX do table.remove(recents) end
    saveRecents(recents)  -- 立即持久化；界面上的「最近」栏下次打开键盘时更新
end

-- ========== 展平数据：最近使用在最前 + 记录每个分栏的像素边界 ==========
local catTables = {}
-- 「最近」分栏始终显示（空也要看得见）；空分栏进度条自动顶满
local shownRecents = {}
for i = 1, math.min(#recents, CONFIG.RECENT_SHOW) do
    table.insert(shownRecents, recents[i])
end
table.insert(catTables, { name = "最近", keys = shownRecents })
for _, cat in ipairs(key_maps) do
    table.insert(catTables, cat)
end

local flat = {}
local catStart = {}   -- 各分栏起始序号(1基)
local catNames = {}
for _, cat in ipairs(catTables) do
    table.insert(catNames, cat.name)
    table.insert(catStart, #flat + 1)
    for _, e in ipairs(cat.keys or {}) do
        table.insert(flat, e)
    end
end

local ROWS = CONFIG.ROWS
local CELL = dp2px(CONFIG.CELL_DP)
local totalCols = math.ceil(#flat / ROWS)

-- ========== 根布局 ==========
local mainContainer = LinearLayout(service)
mainContainer.setOrientation(1)
mainContainer.setBackgroundColor(C.ClipBColor)

-- ========== 顶部：分类标签条 ==========
local tabScroll = HorizontalScrollView(service)
tabScroll.setHorizontalScrollBarEnabled(false)
tabScroll.setLayoutParams(LinearLayout.LayoutParams(-1, dp2px(40)))
local tabBar = LinearLayout(service)
tabBar.setOrientation(0)
tabBar.setGravity(16)
tabBar.setPadding(dp2px(6), 0, dp2px(6), 0)
tabScroll.addView(tabBar)

local tabViews = {}
local selectedTab = -1
local function selectTab(i, fromScroll)
    if selectedTab == i then return end
    selectedTab = i
    for j, tv in ipairs(tabViews) do
        if j == i then
            tv.setBackgroundDrawable(RadiuButton(ActiveColor, dp2px(14)))
            tv.setTextColor(0xFFFFFFFF)
        else
            tv.setBackgroundDrawable(RadiuButton(C.ButtonColor, dp2px(14)))
            tv.setTextColor(C.ButtonTextColor)
        end
    end
    -- 滚动触发的高亮：让标签条跟到可见位置
    if fromScroll and tabViews[i] then
        pcall(function()
            local tv = tabViews[i]
            local x = tv.getLeft() - tabScroll.getWidth() / 2 + tv.getWidth() / 2
            tabScroll.smoothScrollTo(math.max(0, math.floor(x)), 0)
        end)
    end
end

for i, name in ipairs(catNames) do
    local tv = TextView(service)
    tv.setText(name)
    tv.setTextSize(13)
    tv.setGravity(17)
    tv.setPadding(dp2px(10), 0, dp2px(10), 0)
    tv.setBackgroundDrawable(RadiuButton(C.ButtonColor, dp2px(14)))
    tv.setTextColor(C.ButtonTextColor)
    local lp = LinearLayout.LayoutParams(-2, dp2px(28))
    lp.setMargins(dp2px(3), 0, dp2px(3), 0)
    tv.setLayoutParams(lp)
    tabBar.addView(tv)
    tabViews[i] = tv
end

-- ========== 中间：四行横向滚动表情流 ==========
local hscroll = HorizontalScrollView(service)
hscroll.setHorizontalScrollBarEnabled(false)
hscroll.setLayoutParams(LinearLayout.LayoutParams(-1, 0, 1))

local columnsBox = LinearLayout(service)
columnsBox.setOrientation(0)
hscroll.addView(columnsBox)

local colWidth = CELL
local DIV_W = dp2px(12)  -- 分栏分隔列宽

-- 建一列表情（keys 不足 ROWS 补空位，保证每个分类都从整列开始）
local function buildColumn(keys, colIdx)
    local colBox = LinearLayout(service)
    colBox.setOrientation(1)
    for row = 1, ROWS do
        local emoji = keys[colIdx * ROWS + row]
        local cell = TextView(service)
        cell.setGravity(17)
        cell.setLayoutParams(LinearLayout.LayoutParams(CELL, 0, 1))
        if emoji then
            cell.setText(emoji)
            -- 字号按字符数分级：颜文字等多字元串用小字号，避免溢出换行
            local charCount = 1
            pcall(function() charCount = utf8.len(emoji) or 1 end)
            if charCount > 5 then
                cell.setTextSize(9)
            elseif charCount > 2 then
                cell.setTextSize(12)
            else
                cell.setTextSize(CONFIG.EMOJI_SP)
            end
            cell.setOnClickListener(function()
                keyVibrate()
                pcall(function() this.commitText(emoji) end)
                addRecent(emoji)
            end)
        end
        colBox.addView(cell)
    end
    columnsBox.addView(colBox, LinearLayout.LayoutParams(colWidth, -1))
end

-- 分栏分隔列：竖线
local function buildDivider()
    local div = LinearLayout(service)
    div.setGravity(17)  -- center
    local line = View(service)
    line.setBackgroundDrawable(RadiuButton(C.TabTrackColor, dp2px(1)))
    div.addView(line, LinearLayout.LayoutParams(dp2px(2), -1))
    columnsBox.addView(div, LinearLayout.LayoutParams(DIV_W, -1))
end

-- 强硬分栏：每个分类占整列（不足补空位），分类间插分隔竖线；
-- catX[i] = 第 i 个分栏的像素起点（含分隔列），末尾补内容总宽
local catX = {}
local curX = 0
for i, cat in ipairs(catTables) do
    catX[i] = curX
    local keys = cat.keys or {}
    local cols = math.max(math.ceil(#keys / ROWS), 1)  -- 空分类也占 1 列占位
    for c = 0, cols - 1 do
        buildColumn(keys, c)
        curX = curX + colWidth
    end
    if i < #catTables then
        buildDivider()
        curX = curX + DIV_W
    end
end
catX[#catX + 1] = curX  -- 末尾边界
local contentW = curX

-- 分类标签点击：跳到该分栏开头
for i, tv in ipairs(tabViews) do
    tv.setOnClickListener(function()
        keyVibrate()
        selectTab(i)
        hscroll.smoothScrollTo(catX[i], 0)
    end)
end

-- ========== 网格下方：细分段进度条 ==========
local track = FrameLayout(service)
track.setLayoutParams(LinearLayout.LayoutParams(-1, dp2px(8)))
local trackBg = View(service)
trackBg.setBackgroundDrawable(RadiuButton(C.TabTrackColor, dp2px(1)))
local trackBgLp = FrameLayout.LayoutParams(-1, dp2px(2))
trackBgLp.gravity = 17
trackBgLp.leftMargin = dp2px(8)
trackBgLp.rightMargin = dp2px(8)
trackBg.setLayoutParams(trackBgLp)
track.addView(trackBg)

local seg = View(service)  -- 亮段：宽度=可见比例，位置=滚动进度
seg.setBackgroundDrawable(RadiuButton(ActiveColor, dp2px(1)))
local segLp = FrameLayout.LayoutParams(dp2px(40), dp2px(3))
segLp.gravity = 16 + 3  -- left|center_vertical
seg.setLayoutParams(segLp)
track.addView(seg)

-- 滚动时：进度条按当前分栏独立计算（进入新分栏进度归零重滑）
-- + 自动高亮当前分类
local function onScrolled()
    pcall(function()
        local viewW = hscroll.getWidth()
        local trackW = track.getWidth() - dp2px(16)
        local sx = hscroll.getScrollX()
        -- 当前分栏：最后一个 catX[i] <= sx 的 i
        local cat = 1
        for i = #catX - 1, 1, -1 do
            if sx >= catX[i] then cat = i break end
        end
        selectTab(cat, true)
        -- 分栏独立进度：本分栏起点到终点的滚动比例
        local catW = catX[cat + 1] - catX[cat]      -- 本分栏内容宽
        if viewW <= 0 or catW <= viewW then
            -- 分栏不足一屏：进度条顶满（本分栏没有滚动余地）
            local lp = seg.getLayoutParams()
            if lp.width ~= trackW then lp.width = trackW seg.setLayoutParams(lp) end
            seg.setTranslationX(dp2px(8))
            seg.setVisibility(0)
            return
        end
        seg.setVisibility(0)
        local segW = math.max(math.floor(trackW * viewW / catW), dp2px(20))
        local lp = seg.getLayoutParams()
        if lp.width ~= segW then lp.width = segW seg.setLayoutParams(lp) end
        local maxScroll = catW - viewW               -- 本分栏最大滚动量
        local frac = (sx - catX[cat]) / maxScroll
        if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
        seg.setTranslationX(dp2px(8) + frac * (trackW - segW))
    end)
end

pcall(function()
    hscroll.getViewTreeObserver().addOnScrollChangedListener(luajava.createProxy("android.view.ViewTreeObserver$OnScrollChangedListener", {
        onScrollChanged = function() onScrolled() end
    }))
end)

-- ========== 底部 ==========
local keyRow = LinearLayout(service)
keyRow.setOrientation(0)
keyRow.setGravity(17)
keyRow.setPadding(dp2px(6), dp2px(2), dp2px(6), dp2px(6))

local function miniKey(text, sp, weight, width)
    local b = TextView(service)
    b.setText(text)
    b.setTextSize(sp or 15)
    b.setTextColor(C.ButtonTextColor)
    b.setGravity(17)
    b.setBackgroundDrawable(RadiuButton(C.ButtonColor, dp2px(10)))
    local lp
    if weight then
        lp = LinearLayout.LayoutParams(0, dp2px(44), weight)
    else
        lp = LinearLayout.LayoutParams(dp2px(width or 56), dp2px(44))
    end
    lp.setMargins(dp2px(3), 0, dp2px(3), 0)
    b.setLayoutParams(lp)
    return b
end

-- 返回
local btnBack = miniKey("↪", 17, nil, 56)
btnBack.setOnClickListener(function()
    keyVibrate()
    closePanel()  -- 收掉面板，露出原键盘
end)
keyRow.addView(btnBack)

-- 空格
local btnSpace = miniKey(" ", 15, 1)
btnSpace.setOnClickListener(function()
    keyVibrate()
    pcall(function() this.commitText(" ") end)
end)
keyRow.addView(btnSpace)

-- 退格
local btnDel = miniKey("⌫", 17, nil, 56)
btnDel.setOnClickListener(function()
    keyVibrate()
    pcall(function() this.onKey(KeyEvent.KEYCODE_DEL, 0) end)
end)
keyRow.addView(btnDel)

-- 回车
local btnEnter = miniKey("⏎", 17, nil, 56)
btnEnter.setOnClickListener(function()
    keyVibrate()
    pcall(function() this.sendEvent("Return") end)
end)
keyRow.addView(btnEnter)

-- ========== 组装 ==========
mainContainer.addView(tabScroll)
mainContainer.addView(hscroll)
mainContainer.addView(track)
mainContainer.addView(keyRow)

-- 默认停在「表情」分栏（第 2 栏；第 1 栏是「最近」，左滑或点标签查看）
selectTab(2)
hscroll.post(function() hscroll.scrollTo(catX[2], 0) onScrolled() end)
track.post(function() onScrolled() end)


-- ========== 打开面板 ==========
this.showCustomView(mainContainer)
_G.__emoji_panel_shown = true
return
