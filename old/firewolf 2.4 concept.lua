
--  Variables

local event_exitWebsite = "test_exitWebsiteEvent"
local event_waitForLoad = "test_waitForLoadEvent"
local noQuitPrefix = ":fn2:"


--  -------- Override os.pullEvent

local oldpullevent = os.pullEvent
local oldEnv = {}
local env = {}
local api = {}

local pullevent = function(data)
	while true do
		-- Pull raw
		local e, p1, p2, p3, p4, p5 = os.pullEventRaw()

		-- Exit website if needed
		if e == event_exitWebsite and data:sub(1, noQuitPrefix:len()) ~= noQuitPrefix then
			error()
		-- Exit app (Control-T was pressed)
		elseif e == "terminate" then
			error()
		end

		-- Pass data to website
		if data and e == data then return e, p1, p2, p3, p4, p5
		else return e, p1, p2, p3, p4, p5 end
	end
end

-- Prompt from Firewolf with no special exit (event_exitWebsite catcher)
api.prompt = function(list)
	for _, v in pairs(list) do
		if v.bg then term.setBackgroundColor(v.bg) end
		if v.tc then term.setTextColor(v.tc) end
		if v[2] == -1 then v[2] = math.ceil((w + 1)/2 - (v[1]:len() + 6)/2) end

		term.setCursorPos(v[2], v[3])
		write("[- " .. v[1])
		term.setCursorPos(v[2] + v[1]:len() + 3, v[3])
		write(" -]")
	end

	while true do
		local e, but, x, y = os.pullEvent()
		if e == "mouse_click" then
			for _, v in pairs(list) do
				if x >= v[2] and x <= v[2] + v[1]:len() + 5 and y == v[3] then
					return v[1]
				end
			end
		end
	end
end

api.test = function()
	print("test")
end

for k, v in pairs(getfenv(0)) do env[k] = v end
for k, v in pairs(getfenv(1)) do env[k] = v end
for k, v in pairs(env) do oldEnv[k] = v end
for k, v in pairs(api) do env[k] = v end
env["os"]["pullEvent"] = pullevent
setfenv(1, env)


--  -------- Test Website

-- Test website with no special exit (event_exitWebsite)
local function testSite()
	while true do
		print("Hello this is a test website with a prompt that loops over and over again")
		print("\nThe prompt is the same from Firewolf, but without a special exit feature when you press control")

		local opt = prompt({{"Testing 1", 3, 10}, {"Testing 2", 3, 11}, {"CRASH THIS SITE", 3, 12}})
		print("\n\n  You clicked: " .. opt)
		sleep(1.5)
		term.clear()
		term.setCursorPos(1, 1)

		-- Crash the site to see the error message
		if opt == "CRASH THIS SITE" then
			print(nil .. "")
		end
	end
end


--  -------- Loading websites

local function websites()
	while true do
		-- Clear screen
		term.clear()
		term.setCursorPos(1, 1)

		-- Run the website and catch any errors

		-- If the site is in the testSite function
		local _, err = pcall(testSite) 

		-- If the site is in the testsite.lua file
		--[[local f = io.open("/testsite.lua", "r")
		local a = f:read("*a")
		f:close()
		local fn, err = loadstring(a)
		if not(err) then
			setfenv(fn, env)
			_, err = pcall(fn)
		end]]

		if err then
			-- Print error
			print("D: " .. err)
			print("\nYou may now browse normally!")
		end

		-- Wait for page reload
		oldpullevent(event_waitForLoad)
	end
end


--  -------- Address Bar

local function addressBar()
	while true do
		local e, but = oldpullevent()
		if e == "key" and (but == 29 or but == 157) then
			-- Exit the website
			os.queueEvent(event_exitWebsite)

			-- Clear
			term.clear()
			term.setCursorPos(1, 1)

			-- Read new letters (reset os.pullEvent to avoid quitting)
			write("rdnt://")
			os.pullEvent = oldpullevent -- Use noQuitPrefix in modRead instead
			local web = read()
			os.pullEvent = pullevent

			-- If exit
			if web == "exit" then
				-- Simulate Control-T
				os.queueEvent("terminate") 
				return 
			end

			-- Print entered site
			print("You entered the website: " .. web)
			sleep(1.5)

			-- Load site
			os.queueEvent(event_waitForLoad)
		end
	end
end


--  -------- Main

-- Clear
term.clear()
term.setCursorPos(1, 1)

-- Start the main functions
pcall(function()
	parallel.waitForAll(websites, addressBar)
end)

-- Print exit message
term.clear()
term.setCursorPos(1, 1)
print("Exited!")

setfenv(1, oldEnv)
os.pullEvent = oldpullevent
