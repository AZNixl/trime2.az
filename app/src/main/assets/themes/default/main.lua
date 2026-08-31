name = "AZ"
author = "AZNixl"
style="春芽初醒"
keyboard="26键"
function get_keyboard(id,alphabet)
    return "26键"
end
action_labels = {
    none = "Enter", --默认状态
    send = "发送", --回车键发送按钮文本
    go = "前往", --回车键前往按钮文本
    done = "完成", --回车键完成按钮文本
    search = "搜索", --回车键搜索按钮文本
    previous = "上一个", --回车键上一个按钮文本
    next = "下一个", --回车键下一个按钮文本
}
preset_keys = {
    -- 安卓
    BRIGHTNESS_DOWN = { label = "亮度 -", send = "BRIGHTNESS_DOWN" },
    BRIGHTNESS_UP = { label = "亮度 +", send = "BRIGHTNESS_UP" },
    CALCULATOR = { label = "計算機", send = "CALCULATOR" },
    CALENDAR = { label = "日曆", send = "CALENDAR" },
    CONTACTS = { label = "電話簿", send = "CONTACTS" },
    ENVELOPE = { label = "信箱", send = "ENVELOPE" },
    EXPLORER = { label = "瀏覽器", send = "EXPLORER" },
    MUSIC = { label = "音樂", send = "MUSIC" },
    POWER = { label = "電源", send = "POWER" },
    SEARCH = { label = "搜尋", send = "Find" },
    SLEEP = { label = "休眠", send = "SLEEP" },
    VOICE_ASSIST = { label = "voicePNG", send = "VOICE_ASSIST" },
    VOLUME_DOWN = { label = "音量 -", send = "VOLUME_DOWN" },
    VOLUME_UP = { label = "音量 +", send = "VOLUME_UP" },
    VOLUME_MUTE = { label = "靜音", send = "VOLUME_MUTE" },
    -- 編輯
    Shift_L = { label = "shift1", send = "Shift_L", shift_lock = "ascii_long" },
    Return = { label = "action_labels", send = "Return" },
    Return1 = { label = "ent", send = "Return" },
    Return2 = { label = "回车", send = "Return" },
    Hide = { label = "隱藏", send = "BACK" },
    BackSpace = { label = "del1", description = "退格", repeatable = true, send = "BackSpace" },
    space = { repeatable = false, send = "space" },
    space1 = { label = "spacePNG", repeatable = false, send = "space" },
    Escape = { label = "Esc", send = "Escape" },
    Home = { label = "⇤", send = "Home" },
    Insert = { label = "插入", send = "Insert" },
    Delete = { label = "Del", send = "Delete" },
    End = { label = "⇥", send = "End" },
    Page_Up = { label = "◁", send = "Page_Up" },
    Page_Down = { label = "▷", send = "Page_Down" },
    Left = { label = "←", send = "Left" },
    Down = { label = "↓", send = "Down" },
    Up = { label = "↑", send = "Up" },
    Right = { label = "→", send = "Right" },
    select_all = { label = "☑", send = "Control+a" },
    Clear = { label = "清除", text = "{Control+a}{BackSpace}" }, --全選並刪除
    cut = { label = "✁", send = "Control+x" },
    SelectCandidate = { laber = "删前一位", text = "{commit}{BackSpace}"},
    cut_all = { label = "全剪", text = "{Control+a}{Control+x}" }, --全選並剪切
    copy = { label = "❐", send = "Control+c" },
    copy_all = { label = "全部复制", text = "{Control+a}{Control+c}" }, --全選並複製
    paste = { label = "▣", send = "Control+v" },
    paste_text = { label = "粘贴文本", send = "Control+Shift+Alt+v" }, -->=Android 6.0
    share_text = { label = "分享文本", send = "Control+Alt+s" }, -->=Android 6.0
    redo = { label = "redo", send = "Control+Shift+z" }, -->=Android 6.0
    undo = { label = "undo", send = "Control+z" }, -->=Android 6.0
    -- Tab = { lebel = "Tab", send = "Tab"}
    -- rime組合鍵
    F4 = { label = "菜单", send = "F4" },
    BackToPreviousSyllable = { label = "删音节", send = "Control+BackSpace" },
    CommitRawInput = { label = "编码", send = "Control+Return" },
    CommitScriptText = { label = "编码", send = "Shift+Return" },
    CommitComment = { label = "编码", send = "Control+Shift+Return" },
    DeleteCandidate = { label = "删词", send = "Control+Delete" },
    delimiter = {label = "分词", text = "'", description = "分词"},
    -- rime狀態
    Mode_switch = { toggle = "ascii_mode", send = "Mode_switch", states = {"中文", "英文" } },
    Zenkaku_Hankaku = { toggle = "full_shape", send = "Mode_switch", states = { "半角", "全角" } },
    Henkan = { toggle = "simplification", send = "Mode_switch", states = { "简体", "繁体" } },
    Charset_switch = { toggle = "extended_char", send = "Mode_switch", states = { "全字集", "常用字" } },
    Punct_switch = { toggle = "ascii_punct", send = "Mode_switch", states = { "。，", "．，" } },
    Keyboard_menu = { label = "menu", send = "Eisu_toggle", select = "功能键盘/menu" },
    Keyboard_editor = {label = "edit", send = "Eisu_toggle", select = "功能键盘/editor"},
    Keyboard_number = { label = "123", send = "Eisu_toggle", select = "功能键盘/number" },
    Keyboard_symbols_en = { label = "英文", send = "Eisu_toggle", select = "功能键盘/symbols_en" },
    Keyboard_symbols_cn = { label = "中文", send = "Eisu_toggle", select = "功能键盘/symbols_cn" },
    Keyboard_letter = { label = "字母", send = "Eisu_toggle", select = "default" },
    Keyboard_default = { label = "返回", send = "Eisu_toggle", select = ".default" },
    Keyboard_switch = { label = "鍵盤", send = "Eisu_toggle", select = ".next" },
    Keyboard_clipboard = { label = "剪贴板", send = "Eisu_toggle", select = "clipboard" },
    keyboard_clip = { label = "剪切板", send = "Eisu_toggle", select = "clipBoard" },
    Keyboard_settings = { label = "键盘", send = "SETTINGS", option = "keyboard" }, --添加select参数可以直接设置指定键盘
    -- trime設定
    IME_switch = { label = "imePNG", send = "LANGUAGE_SWITCH" }, --彈出對話框選擇輸入法
    IME_last = { label = "上一输入法", send = "LANGUAGE_SWITCH", select = ".last" }, --直接切換到上一輸入法
    IME_next = { label = "下一输入法", send = "LANGUAGE_SWITCH", select = ".next" }, --直接切換到下一輸入法
    Schema_switch = { label = "下一方案", send = "Control+Shift+1" },
    Color_switch = { label = "配色", send = "PROG_RED" },
    Menu = { label = "方案", send = "Menu" },
    Settings = { label = "設定", send = "SETTINGS" },
    Color_settings = { label = "◲", send = "SETTINGS", option = "color" },
    Theme_settings = { label = "theme", send = "SETTINGS", option = "theme" },
    Schema_settings = { label = "方案", send = "SETTINGS", option = "schema" },
    Schema_group = { label = "方案组", send = "SETTINGS", option = "group" }, --添加select参数可以直接设置指定方案
    Candidate_switch = { toggle = "_hide_candidate", send = "Mode_switch", states = { "有候选", "无候选" } },
    Comment_switch = { toggle = "_hide_comment", send = "Mode_switch", states = { "有注释", "无注释" } },
    Hint_switch = { toggle = "_hide_key_hint", send = "Mode_switch", states = { "有助記", "無助記" } },
    -- trime命令
    Date = { label = "日期", command = "date", option = "yyyy-MM-dd" },
    ChineseDate = { label = "农历", command = "date", option = "zh_CN@calendar=chinese" }, --農曆等日期(>=Android 7.0)：date 語言@calendar=曆法 格式。具體參見https=//developer.android.com/reference/android/icu/util/Calendar.html
    Time = { label = "时间", command = "date", option = "HH=mm=ss" }, --時間： date 格式
    TrimeApp = { label = "同文", command = "run", option = "com.osfans.trime" }, --運行程序= run 包名
    TrimeCmp = { label = "同文组件", command = "run", option = "com.osfans.trime/.ui.main.MainActivity" }, --運行程序指定組件= run 包名/組件名
    Homepage = { label = "同文主页", command = "run", option = "https=//github.com/osfans/trime" }, --查看網頁= run 網址
    CommitHomepage = { label = "同文网址", commit = "https = //github.com/osfans/trime" }, --直接上屏
    Wiki = { label = "维基", command = "run", option = "https=//zh.wikipedia.org/wiki/%s" }, --搜索網頁= %s或者%1$s爲當前字符
    Google = { label = "谷歌", command = "run", option = "https=//www.google.com/search?q=%s" }, --搜索網頁= %s或者%1$s爲當前字符
    MoeDict = { label = "萌典", command = "run", option = "https=//www.moedict.tw/%3$s" }, --搜索網頁= %3$s爲光標前字符
    Baidu = { label = "百度搜索", command = "run", option = "https=//www.baidu.com/s?wd=%4$s" }, --搜索網頁= %4s爲光標前所有字符
    Zdic = { label = "漢典", command = "run", option = "http=//www.zdic.net/sousuo/?q=%1$s" }, --搜索網頁= %s或者%1$s爲當前字符
    Zdic2 = { label = "漢典", command = "run", option = "http=//www.zdic.net/sousuo/?q=%2$s" }, --搜索網頁= %2$s爲當前輸入的編碼
    WebSearch = { label = "搜索网页", command = "web_search", option = "%4$s" }, --搜索，其他view、dial、edit、search等intent，參考安卓的intent文檔：https=//developer.android.com/reference/android/content/Intent.html
    Search = { label = "搜索", command = "search", option = "%1$s" }, --搜索短信、字典等
    Share = { label = "分享", command = "send", option = "%s" }, --分享指定文本= %s或者%1$s爲當前字符
    Deploy = { label = "部署", command = "broadcast", option = "com.osfans.trime.action.DEPLOY" },
    ToolsManager = { label = "工具箱", command = "工具箱.lua" },
    Sync = { label = "同步", command = "broadcast", option = "com.osfans.trime.action.SYNC_USER_DATA" },
    RepeatCommit = { label = "重复", command = "commit", option = "%1$s" },
    -- 用户定义 以下部份摘自秋月|小鹤主题
    select_2 = {label = "次选", send = 2},
    select_3 = {label = "三选", send = 3},
    select_4 = {label = "四选", send = 4},
    DelH = { functional = false, text = "{END}{Shift+Home}{Delete}" },
    select_H = {label = "↔", functional = false, text = "{End}{Shift+Home}"},
    logcat = { command = "LogCat.lua", label = "log"},
    jtb = { label = "clip", send = "Eisu_toggle", select = "clipboard" },
    emoji = { command = "emoji.lua", label = "emoji" },
    restheme = { label = "重载主题", command = "重载主题.lua" },
    auto_land = { toggle = "landscape_kb", send = "Mode_switch", states = { "自动悬浮", "横屏键盘" } },
    hover_set = { label = "悬浮窗设置", command = "悬浮窗设置.lua" },
    move_set = { label = "手势参数", command = "手势参数设置.lua" },
    all_switch = { label = "样式开关", command = "全局开关.lua" },
    game2048 = { command = "2048.lua", label = "2048"},
    Tab = { label = "↹", send = "Tab"},
    Shift1 = { label = "☩", send = "Shift_L", shift_lock = "click" },
    space2 = { repeatable = true, send = "space", preview = "␣", functional = false},
    Mode_small= {toggle= "small_mode", send= "Mode_switch", states= {"ds", "ds1"}},--单手模式
    Mode_float= {toggle= "float_mode", send= "Mode_switch", states= {"xf", "xf1"}},--悬浮模式
  -- AI
    gpt1 = {
        label = "生成",
        send = "function",
        command = "gpt",
        option = "根据 %4$s 生成内容"
    },
    gpt2 = {
        label = "润色",
        send = "function",
        command = "gpt",
        option = "润色以下内容 %4$s"
    },
    gpt3 = {
        label = "翻译",
        send = "function",
        command = "gpt",
        option = "翻译以下内容 %4$s"
    },
    gpt4 = {
        label = "续写",
        send = "function",
        command = "gpt",
        option = "根据以下内容续写 %4$s"
    },
    gpt5 = {
        label = "小V",
        send = "function",
        command = "gpt",
        option = "%4$s"
    }
}
