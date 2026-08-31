import("android.app.*")
import("android.os.*")
import("android.widget.*")
import("android.view.*")
import("java.io.File")
import("android.view.animation.DecelerateInterpolator")
import("android.view.animation.Animation")
import("android.animation.ObjectAnimator")
import("android.graphics.drawable.ColorDrawable")
import("com.androlua.LuaAdapter")

onEvent = function(str)
	if this and str then
		local Event = luajava.bindClass("com.osfans.trime.Event")
		local event = Event(str)
		this.onEvent(event)
	end
end

local activity = luajava.bindClass("com.osfans.trime.TrimeApplication").getInstance()
-- 在文件开头获取屏幕密度（放在 init() 之前或其中）
local density = activity.getResources().getDisplayMetrics().density
local cellStep = 56 * density -- 46dp格子 + 10dp间距
local startOffset = 18 * density -- 8dp内边距 + 10dp外边距

local layout = {
	LinearLayout,
	layout_width = "match_parent",
	layout_height = "match_parent",
	orientation = "horizontal",
	background = "#ffffffff",
	{
		FrameLayout,
		{
			GridView,
			id = "grid1",
			layout_width = "230dp",
			layout_height = "230dp",
			numColumns = 4,
			verticalSpacing = "10dp",
			padding = "8dp",
			layout_marginTop = "10dp",
			layout_marginLeft = "10dp",
			horizontalSpacing = "10dp",
			background = "#ffBDAEA4",
		},
		{
			FrameLayout,
			id = "fl",
			layout_width = "240dp",
			layout_height = "240dp",
		},
	},
	{
		LinearLayout,
		orientation = "vertical",
		{
			TextView,
			layout_width = "wrap_content",
			layout_height = "50dp",
			layout_marginLeft = "24dp",
			layout_marginRight = "4dp",
			gravity = "center",
			text = "Score:",
		},

		{
			TextView,
			id = "score",
			layout_width = "wrap_content",
			-- layout_height = "50dp",
			layout_marginLeft = "24dp",
			layout_marginRight = "4dp",
			gravity = "center",
			text = "0",
		},

		{
			TextView,
			layout_width = "wrap_content",
			layout_height = "50dp",
			gravity = "center",
			text = "Best:",
			layout_marginLeft = "24dp",
			id = "b1",
			layout_marginRight = "4dp",
		},

		{
			TextView,
			id = "best",
			layout_width = "wrap_content",
			layout_height = "50dp",
			gravity = "center",
			text = "0",
			layout_marginLeft = "24dp",
			layout_marginRight = "4dp",
		},

		{
			Button,
			layout_width = "120dp",
			layout_height = "40dp",
			-- layout_columnSpan = "4",
			layout_marginLeft = "24dp",
			layout_marginRight = "4dp",
			-- onClick = "reset",
			text = "返回",
			id = "bn",
		},
	},
}

local item = {
	CardView,
	radius = "8",
	layout_width = "46dp",
	layout_height = "46dp",
	background = "#CEC2B5",
	CardElevation = "0",
	id = "tv",
}
layout = loadlayout(layout)
local nmap = {} 
local data = {}
local adp = LuaAdapter(activity, data, item)
grid1.setAdapter(adp)
for i = 1, 16 do
	table.insert(data, { tv = "" })
end
adp.notifyDataSetChanged()
local cvs = {}

-- 分数相关全局变量
local currentScore = 0
local bestScore = 0

-- 更新分数显示，并检查最高分
local function updateScore(addScore)
	currentScore = currentScore + addScore
	score.setText(tostring(currentScore))
	if currentScore > bestScore then
		bestScore = currentScore
		best.setText(tostring(bestScore))
	end
end

function CreateCV(x, y, color)
	local x = x or 0
	local y = y or 0
	local color = color or "#EFE7DE"
	local cv = loadlayout({
		CardView,
		layout_height = "46dp",
		layout_width = "46dp",
		radius = "8",
		background = color,
		id = "c2",
		CardElevation = "0",
		{
			TextView,
			text = "2",
			id = "t2",
			textSize = "18",
			layout_gravity = "center",
		},
	})
	fl.addView(cv)
	t2.getPaint().setFakeBoldText(true)

	local px = startOffset + cellStep * (x - 1)
	local py = startOffset + cellStep * (y - 1)
	cv.setX(px)
	cv.setY(py)
	return cv
end

function autoMove(v, direction, step)
	local moveanimator
	local delta = cellStep * step
	switch(direction)
	do
		case(1)
		moveanimator = ObjectAnimator.ofFloat(v, "Y", { v.getY(), v.getY() - delta })
		case(2)
		moveanimator = ObjectAnimator.ofFloat(v, "Y", { v.getY(), v.getY() + delta })
		case(3)
		moveanimator = ObjectAnimator.ofFloat(v, "X", { v.getX(), v.getX() - delta })
		case(4)
		moveanimator = ObjectAnimator.ofFloat(v, "X", { v.getX(), v.getX() + delta })
	end
	moveanimator.setRepeatCount(0)
	moveanimator.setInterpolator(DecelerateInterpolator())
	moveanimator.setDuration(250)
	moveanimator.start()
end

local xstr = ""
function rand2()
	local r1 = { math.random(1, 4), math.random(1, 4) }
	if nmap[r1[2]][r1[1]][1] == 0 then
		local x = CreateCV(r1[1], r1[2])
		nmap[r1[2]][r1[1]] = { 2, x }
		xstr = xstr .. r1[2] .. "-" .. r1[1] .. "生成" .. "\n"
	else
		rand2()
	end
end

function printTable()
	local str = ""
	for i = 1, 4 do
		for j = 1, 4 do
			if j ~= 4 then
				str = str .. nmap[i][j][1] .. "-"
			else
				str = str .. nmap[i][j][1]
			end
		end
		str = str .. "\n"
	end
end

local function coloring(v)
	local colorTab = {
		[2] = 0xfff7f4e5,
		[4] = 0xffEFE3CE,
		[8] = 0xffF7B27B,
		[16] = 0xfff59563,
		[32] = 0xfff7a08a,
		[64] = 0xfff65e3b,
		[128] = 0xffeccd74,
		[512] = 0xffb683aa,
		[1024] = 0xffab60a6,
		[2048] = 0xff353954,
	}
	local index = tonumber(v.getChildAt(0).Text)
	v.setBackgroundColor(colorTab[index])
end

local function swapeUp(v)
	for i = 1, 4 do
		for j = 2, 4 do
			if nmap[j][i][1] ~= 0 then
				for k = 1, j - 1 do
					if nmap[k][i][1] == 0 then
						autoMove(nmap[j][i][2], 1, j - k)
						nmap[j][i], nmap[k][i] = nmap[k][i], nmap[j][i]
						break
					else
						if nmap[k + 1][i][1] ~= 0 and k + 1 ~= j then
							continue
						end
						if nmap[j][i][1] == nmap[k][i][1] then
							fl.removeView(nmap[j][i][2])
							nmap[j][i] = { 0, nil }
							local newValue = tonumber(nmap[k][i][1]) * 2
							nmap[k][i][1] = newValue
							nmap[k][i][2].getChildAt(0).setText(tostring(newValue))
							coloring(nmap[k][i][2])
							-- 累加分数
							updateScore(newValue)
							break
						else
							continue
						end
					end
				end
			end
		end
	end
	v.post({
		run = function()
			rand2()
		end,
	})
end

local function swapeDown(v)
	for i = 1, 4 do
		for j = 3, 1, -1 do
			if nmap[j][i][1] ~= 0 then
				for k = 4, j + 1, -1 do
					if nmap[k][i][1] == 0 then
						autoMove(nmap[j][i][2], 2, k - j)
						nmap[j][i], nmap[k][i] = nmap[k][i], nmap[j][i]
						break
					else
						if nmap[k - 1][i][1] ~= 0 and k - 1 ~= j then
							continue
						end
						if nmap[j][i][1] == nmap[k][i][1] then
							fl.removeView(nmap[j][i][2])
							nmap[j][i] = { 0, nil }
							local newValue = tonumber(nmap[k][i][1]) * 2
							nmap[k][i][1] = newValue
							nmap[k][i][2].getChildAt(0).setText(tostring(newValue))
							coloring(nmap[k][i][2])
							updateScore(newValue)
							break
						else
							continue
						end
					end
				end
			end
		end
	end
	v.post({
		run = function()
			rand2()
		end,
	})
end

local function swapeLeft(v)
	for i = 1, 4 do
		for j = 2, 4 do
			if nmap[i][j][1] ~= 0 then
				for k = 1, j - 1 do
					if nmap[i][k][1] == 0 then
						autoMove(nmap[i][j][2], 3, j - k)
						nmap[i][k], nmap[i][j] = nmap[i][j], nmap[i][k]
						break
					else
						if nmap[i][k + 1][1] ~= 0 and k + 1 ~= j then
							continue
						end
						if nmap[i][k][1] == nmap[i][j][1] then
							fl.removeView(nmap[i][j][2])
							nmap[i][j] = { 0, nil }
							local newValue = tonumber(nmap[i][k][1]) * 2
							nmap[i][k][1] = newValue
							nmap[i][k][2].getChildAt(0).setText(tostring(newValue))
							coloring(nmap[i][k][2])
							updateScore(newValue)
							break
						else
							continue
						end
					end
				end
			end
		end
	end
	v.post({
		run = function()
			rand2()
		end,
	})
end

local function swapeRight(v)
	for i = 1, 4 do
		for j = 3, 1, -1 do
			if nmap[i][j][1] ~= 0 then
				for k = 4, j + 1, -1 do
					if nmap[i][k][1] == 0 then
						autoMove(nmap[i][j][2], 4, k - j)
						nmap[i][k], nmap[i][j] = nmap[i][j], nmap[i][k]
						break
					else
						if nmap[i][k - 1][1] ~= 0 and k - 1 ~= j then
							continue
						end
						if nmap[i][k][1] == nmap[i][j][1] then
							fl.removeView(nmap[i][j][2])
							nmap[i][j] = { 0, nil }
							local newValue = tonumber(nmap[i][k][1]) * 2
							nmap[i][k][1] = newValue
							nmap[i][k][2].getChildAt(0).setText(tostring(newValue))
							coloring(nmap[i][k][2])
							updateScore(newValue)
							break
						else
							continue
						end
					end
				end
			end
		end
	end
	v.post({
		run = function()
			rand2()
		end,
	})
end

grid1.onTouch = function(v, event)
	if event.getAction() == MotionEvent.ACTION_DOWN then
		downX = event.getRawX()
		downY = event.getRawY()
	elseif event.getAction() == MotionEvent.ACTION_MOVE then
	elseif event.getAction() == MotionEvent.ACTION_UP then
		upX = event.getRawX()
		upY = event.getRawY()
		local tMoveX = math.abs(upX - downX)
		local tMoveY = math.abs(upY - downY)
		if tMoveX > 15 and tMoveY < tMoveX then
			if upX - downX > 0 then
				swapeRight(v)
			elseif upX - downX < 0 then
				swapeLeft(v)
			end
		elseif tMoveY > 15 and tMoveX < tMoveY then
			if upY - downY > 0 then
				swapeDown(v)
			elseif upY - downY < 0 then
				swapeUp(v)
			end
		end
	end
	return true
end

function init()
	for i = 1, 4 do
		local t = {}
		for j = 1, 4 do
			table.insert(t, { 0, nil })
		end
		table.insert(nmap, t)
	end
	-- 重置分数
	currentScore = 0
	bestScore = 0
	score.setText("0")
	best.setText("0")
	rand2()
	rand2()
end

init()

bn.onClick = function(v)
	onEvent("Keyboard_default")
end

return layout