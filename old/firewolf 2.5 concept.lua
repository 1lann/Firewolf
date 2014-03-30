
-- Proof of Concept for Firewolf 2.5

local website = "home"
local current = 1
local cor = {}
local w, h = term.getSize()

local function testSite()
	print("This is the test site 1.")
end

local function testSite2()
	print("This is the test site 2.")
	while true do
		local e, but = os.pullEvent("char")
		print(but)
	end
end

local function website()
	term.setCursorPos(2, 1)
	term.clearLine()
	term.write("rdnt://")

	while true do
		local e, but, x, y, p4, p5 = os.pullEvent()
		if (e == "mouse_click" and y == 1) or (e == "key" and but == 29 or but == 157) then
			-- Stop site
			if cor[current] then cor[current] = nil end

			-- Read site
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			term.setCursorPos(2, 1)
			term.clearLine()
			term.write("rdnt://")
			website = read()

			-- Load
			if website == "test1" then
				cor[current] = coroutine.create(testSite)
			elseif website == "test2" then
				cor[current] = coroutine.create(testSite2)
			elseif website == "exit" then
				break
			end

			-- Clear
			term.setCursorPos(1, 2)

			-- Run
			if cor[current] then coroutine.resume(cor[current])
			else print("Site not found!") end
		elseif e == "mouse_click" and y == 2 then
			if x >= 1 and x <= 20 then
				current = 1
			elseif x >= w - 20 and x <= w then
				current = 2
			end
			term.clear()
			term.setCursorPos(2, 1)
			term.write("rdnt://")
		elseif cor[current] then
			if coroutine.status(cor[current]) == "suspended" then
				if e == "mouse_click" then y = y + 1 end
				coroutine.resume(cor[current], e, but, x, y, p4, p5)
			end
		end
	end
end


local function main()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)

	website()
end

main()
