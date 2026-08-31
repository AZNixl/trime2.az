--[[========================================================================
重载主题（命令脚本 · trime2）
AZNixl | Kimi K3
========================================================================
【功能】
  一键重载当前主题：重跑入口 main.lua + 重建键盘 UI，
  脚本开关、横屏模式切换等改动即时生效。

【安装】
  1. 本文件放到 rime/scripts/ 目录
  2. 主题 main.lua 的 preset_keys 里加（分类按需）：
       retheme = { label = "重载主题", command = "重载主题.lua" },
  3.绑定到menu.lua或click使用。
========================================================================]]

local this = rawget(_G, "this") or luajava.bindClass("com.osfans.trime.TrimeService").getInstance()
pcall(function()
    local Config = luajava.bindClass("com.osfans.trime.Config")
    this.setTheme(tostring(Config.getTheme()))
end)
