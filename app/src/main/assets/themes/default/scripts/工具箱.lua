--[[
--@zums
文件位置:
    rime/scripts/工具箱.lua
    rime/themes/你的主题/scripts/工具箱.lua
    二选一
 
•主题main.lua中添加
preset_keys = {
    ToolsManager = {command = "工具箱.lua", label = "📦"},
    
}
按键上 click = "ToolsManager"

]]
import "android.view.Gravity"
import "android.widget.GridView"
import "android.widget.LinearLayout"
import "android.widget.TextView"
import "com.androlua.LuaAdapter"
local GitHubColors = {
    -- 深色主题（默认）
    dark = {
        bgDialog = 0xFF393B38,           -- 主背景色
        bgItem = 0xFF484A46,           -- 卡片背景
        textPrimary = 0xeeC9D1D9,      -- 主文字色
    },
    -- 浅色主题
    light = {
        bgDialog = 0xFFc9d1d9,
        bgItem = 0xFFF6F8FA,
        textPrimary = 0xFF24292F,
    }
}

local function getColors(colors)
    local Config = luajava.bindClass("com.osfans.trime.Config")
    return when Config.getStyle()
    case "light" return colors.light
    case "night" return colors.dark
    default return colors.light
    end
end
local function isDarkTheme()

    return true
end

local theme =  getColors(GitHubColors) --isDarkTheme() and GitHubColors.dark or GitHubColors.light
--启动工具箱
local function OpenToolsManager()
    local Intent = luajava.bindClass("android.content.Intent")
    local intent = Intent()

    intent.setClassName("com.nirenr.trime", "com.osfans.trime.ToolActivity")
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    service.startActivity(intent)
end

-- 启动指定工具(文件夹名)
local function RunTool(toolName)
    local Intent = luajava.bindClass("android.content.Intent")
    local Uri = luajava.bindClass("android.net.Uri")
    local File = luajava.bindClass("java.io.File")

    local instance = service.getApplicationContext()

    local toolsDir = instance.getLuaExtDir("tools")
    local mainLuaPath = toolsDir .. "/" .. toolName .. "/main.lua"
    local mainLuaFile = File(mainLuaPath)

    if mainLuaFile.exists() then
        local intent = Intent()
        intent.setClassName("com.nirenr.trime", "com.androlua.LuaActivity")
        intent.setData(Uri.parse(mainLuaPath))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        service.startActivity(intent)
        -- print("启动工具. " .. toolName)
    else
        print("工具不存在. " .. mainLuaPath)
    end
end

--工具箱列表
local function ListTools()
    local File = luajava.bindClass("java.io.File")
    local instance = service.getApplicationContext()

    local toolsDir = instance.getLuaExtDir("tools")
    local dir = File(toolsDir)

    if dir.exists() and dir.isDirectory() then
        local files = dir.listFiles()
        local tools = {}
        for i = 0, files.length - 1 do
            local f = files[i]
            if f.isDirectory() then
                local mainLua = File(f, "main.lua")
                if mainLua.exists() then
                    table.insert(tools, f.getName())
                end
            end
        end
        return tools
    end
    return {}
end

local function ColorDrawable(color)
    local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
    local drawable = GradientDrawable()
    drawable.setColor(color)
    drawable.setCornerRadius(18)
    return drawable
end
local function dpToPx(dp)
    local DisplayMetrics = luajava.bindClass("android.util.DisplayMetrics")
    local metrics = service.getResources().getDisplayMetrics()
    return dp * (metrics.densityDpi / DisplayMetrics.DENSITY_DEFAULT)
end

function Grid(dlg)
    local tools = ListTools()

    if #tools == 0 then
        print("没有找到任何工具")
        return
    end
    local grid = GridView(this)
    grid.setNumColumns(3)
    grid.setPadding(16, 16, 16, 16)
    grid.setVerticalScrollBarEnabled(true)

    -- 设置垂直和水平分割线
    grid.setVerticalSpacing(dpToPx(5)) -- 垂直间距（作为分割线）
    grid.setHorizontalSpacing(dpToPx(5)) -- 水平间距（作为分割线）

    -- local ColorDrawable = luajava.bindClass("android.graphics.drawable.ColorDrawable")
    -- grid.setBackgroundColor(0xFFCCCCCC)  -- 分割线颜色

    local item = {
        LinearLayout;
        id="layout_1";
        layout_width="fill";
        layout_height="fill";
        orientation="vertical";
        gravity="center";
        background=ColorDrawable(theme.bgItem);
        {
            TextView;
            id="tv_2";
            layout_width="wrap";
            layout_height="wrap";
            textSize="18sp";
            text="📁";
        };
        {
            TextView;
            id="tv_3";
            layout_width="wrap";
            layout_height="wrap";
            textColor=theme.textPrimary;
            textSize="12sp";
            text="TextView";
        };
    };


    -- 设置适配器
    local adapter = LuaAdapter(service.getApplicationContext(), item)
    grid.setAdapter(adapter)
    for i, c in ipairs(tools) do
        adapter.add({
            tv_3 ={ text = c}
        })
    end
    -- 设置点击事件
    grid.onItemClick = function(l, v, p, i)
        RunTool(v.Tag.tv_3.Text)
        dlg.dismiss()
    end
    return grid
end

--工具箱列表对话框 配合 ListTools , RunTool 
local function ShowToolsDialog()
    local LuaDialog = luajava.bindClass("com.androlua.LuaDialog")
    local dlg = LuaDialog(service)
    dlg.setTitle("选择工具")
    dlg.setView(Grid(dlg))
    dlg.setNegativeButton("取消", nil)
    dlg.show()

    -- 设置对话框样式
    local window = dlg.getWindow()
    if window then
        window.setBackgroundDrawable(ColorDrawable(theme.bgDialog))
        local params = window.getAttributes()
        params.gravity = Gravity.CENTER
        params.width = -2 -- WRAP_CONTENT
        params.height = dpToPx(400) -- 使用固定高度更稳定
        -- window.setAttributes(params)
    end



end


-- OpenToolsManager()  --启动工具箱

-- RunTool("布局助手") -- 使用文件夹名，不是显示名称
ShowToolsDialog() -- 工具箱列表对话框


return