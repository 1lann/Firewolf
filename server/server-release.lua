
--  
--  Firewolf Server Software
--  Created By GravityScore and 1lann
--  License found here: https://raw.github.com/1lann/Firewolf/master/LICENSE  
--
--  Orignal Idea from RednetExplorer 2.4.1
--  RednetExplorer Made by ComputerCraftFan11
--  


--  -------- Variables

-- Version
local version = "2.4"
local serverID = "release"

-- Prevent Control-T
os.pullEvent = os.pullEventRaw

-- Updating
local autoupdate = true

-- Responding
local enableSearch = true
local enableResponse = true
local enableRecording = true

-- Download URLs
local serverURL = "https://raw.github.com/1lann/firewolf/master/server/server-" .. serverID .. ".lua"

-- Events
local event_stopServer = "firewolf_stopServerEvent"

-- Statistics
local searches = 0
local visits = 0

-- Theme
local theme = {}

-- Databases
local ignoreDatabase = {}
local permantentIgnoreDatabase = {}
local suspected = {}

-- Server
local w, h = term.getSize()
local args = {...}
local website = ""
local dataLocation = ""
local pages = {}
local totalRecordLines = {}
local recordLines = {}
local serverPassword = nil
local serverLocked = false

-- Locations
local rootFolder = "/.Firewolf_Data"
local serverFolder = rootFolder .. "/servers"
local statsLocation = rootFolder .. "/" .. website .. "_stats"
local themeLocation = rootFolder .. "/theme"
local defaultThemeLocation = rootFolder .. "/default_theme"
local passwordDataLocation = rootFolder .. "/." .. website .. "_password"
local serverLocation = "/" .. shell.getRunningProgram()

-- Parse Arguments
if #args >= 2 then
	website = args[1]:gsub("^%s*(.-)%s*$", "%1")
	dataLocation = args[2]:gsub("^%s*(.-)%s*$", "%1")
	statsLocation = rootFolder .. "/" .. website .. "_stats"
	passwordDataLocation = rootFolder .. "/." .. website .. "_password"
else
	print("Invalid Arguments! D:")
	return
end


--  -------- Utility Functions

local function isAdvanced()
	if term.isColor then return term.isColor()
	else return false end
end

local function oldPullEvent(ex)
	event, p1, p2, p3, p4, p5 = os.pullEventRaw(ex)
	if event == "terminate" then
		print("Terminated")
		error()
	else
		return event, p1, p2, p3, p4, p5
	end
end

local function printWithType(t, func)
	if type(t) == "table" then
		for k, v in pairs(t) do
			env.pcall(function() printWithType(v, func) end)
		end
	else
		func(tostring(t))
	end
end

local function centerWrite(text)
	local x, y = term.getCursorPos()
	printWithType(text, function(t)
		term.setCursorPos(math.ceil((w + 1)/2 - t:len()/2), y)
		write(t)
	end)
end

local function centerPrint(text)
	centerWrite(text)
	print()
end

local function leftWrite(text)
	local x, y = term.getCursorPos()
	printWithType(text, function(t)
		term.setCursorPos(1, y)
		write(text)
	end)
end

local function leftPrint(text)
	leftWrite(text)
	print()
end

local function rightWrite(text)
	local x, y = term.getCursorPos()
	printWithType(text, function(t)
		term.setCursorPos(w - text:len() + 1, y)
		write(text)
	end)
end

local function rightPrint(text)
	rightWrite(text)
	print()
end

local function clearPage(r)
	-- Site titles
	title = "Hosting: rdnt://" .. website

	-- Address Bar
	term.setTextColor(colors[theme["address-bar-text"]])
	term.setCursorPos(2, 1)
	term.setBackgroundColor(colors[theme["address-bar-background"]])
	term.clearLine()
	term.setCursorPos(2, 1)
	if title:len() > 42 then title = title:sub(1, 39) .. "..." end
	write(title)

	-- Records
	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 11 do
		term.setCursorPos(1, i + 7) 
		centerWrite(string.rep(" ", 47)) 
	end
	if r == true then
		for i, v in ipairs(recordLines) do
			term.setCursorPos(5, i + 8)
			write(v)
		end
	end

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	print("")
end

local function prompt(list)
	if isAdvanced() then
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
	else
		for _, v in pairs(list) do
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			if v[2] == -1 then v[2] = math.ceil((w + 1)/2 - (v[1]:len() + 4)/2) end

			term.setCursorPos(v[2], v[3])
			write("  " .. v[1])
			term.setCursorPos(v[2] + v[1]:len() + 2, v[3])
			write("  ")
		end

		local key1 = 200
		local key2 = 208
		if dir == "horizontal" then
			key1 = 203
			key2 = 205
		end

		local curSel = 1
		term.setCursorPos(list[curSel][2], list[curSel][3])
		write("[")
		term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
		write("]")

		while true do
			local e, key = os.pullEvent()
			term.setCursorPos(list[curSel][2], list[curSel][3])
			write(" ")
			term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
			write(" ")
			if e == "key" and key == key1 and curSel > 1 then
				curSel = curSel - 1
			elseif e == "key" and key == key2 and curSel < #list then
				curSel = curSel + 1
			elseif e == "key" and key == 28 then
				return list[curSel][1]
			end
			term.setCursorPos(list[curSel][2], list[curSel][3])
			write("[")
			term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
			write("]")
		end
	end
end

local function scrollingPrompt(list, x, y, len, width)
	local wid = width
	if wid == nil then wid = w - 3 end

	local function updateDisplayList(items, loc, len)
		local ret = {}
		for i = 1, len do
			local item = items[i + loc - 1]
			if item ~= nil then table.insert(ret, item) end
		end
		return ret
	end

	if isAdvanced() then
		local function draw(a)
			for i, v in ipairs(a) do
				term.setCursorPos(x, y + i - 1)
				write(string.rep(" ", wid))
				term.setCursorPos(x, y + i - 1)
				write("[ " .. v:sub(1, wid - 5))
				term.setCursorPos(wid + x - 2, y + i - 1)
				write("  ]")
			end
		end

		local loc = 1
		local disList = updateDisplayList(list, loc, len)
		draw(disList)
		
		while true do
			local e, but, clx, cly = os.pullEvent()
			if e == "key" and but == 200 and loc > 1 then
				loc = loc - 1
				disList = updateDisplayList(list, loc, len)
				draw(disList)
			elseif e == "key" and but == 208 and loc + len - 1 < #list then
				loc = loc + 1
				disList = updateDisplayList(list, loc, len)
				draw(disList)
			elseif e == "mouse_scroll" and but > 0 and loc + len - 1 < #list then
				loc = loc + but
				disList = updateDisplayList(list, loc, len)
				draw(disList)
			elseif e == "mouse_scroll" and but < 0 and loc > 1 then
				loc = loc + but
				disList = updateDisplayList(list, loc, len)
				draw(disList)
			elseif e == "mouse_click" then
				for i, v in ipairs(disList) do
					if clx >= x and clx <= x + wid and cly == i + y - 1 then
						return v
					end
				end
			end
		end
	else
		local function draw(a)
			for i, v in ipairs(a) do
				term.setCursorPos(x, y + i - 1)
				write(string.rep(" ", wid))
				term.setCursorPos(x, y + i - 1)
				write("[ ] " .. v:sub(1, wid - 5))
			end
		end

		local loc = 1
		local curSel = 1
		local disList = updateDisplayList(list, loc, len)
		draw(disList)
		term.setCursorPos(x + 1, y + curSel - 1)
		write("x")

		while true do
			local e, key = os.pullEvent()
			term.setCursorPos(x + 1, y + curSel - 1)
			write(" ")
			if e == "key" and key == 200 then
				if curSel > 1 then
					curSel = curSel - 1
				elseif loc > 1 then
					loc = loc - 1
					disList = updateDisplayList(list, loc, len)
					draw(disList)
				end
			elseif e == "key" and key == 208 then
				if curSel < #disList then
					curSel = curSel + 1
				elseif loc + len - 1 < #list then
					loc = loc + 1
					disList = updateDisplayList(list, loc, len)
					draw(disList)
				end
			elseif e == "key" and key == 28 then
				return list[curSel + loc - 1]
			end
			term.setCursorPos(x + 1, y + curSel - 1)
			write("x")
		end
	end
end


--  -------- Themes

local defaultTheme = {["address-bar-text"] = "white", ["address-bar-background"] = "gray", 
	["address-bar-base"] = "lightGray", ["top-box"] = "red", ["bottom-box"] = "orange", 
	["text-color"] = "white", ["background"] = "gray"}
local originalTheme = {["address-bar-text"] = "white", ["address-bar-background"] = "black", 
	["address-bar-base"] = "black", ["top-box"] = "black", ["bottom-box"] = "black", 
	["text-color"] = "white", ["background"] = "black"}

local function loadTheme(path)
	if fs.exists(path) and not fs.isDir(path) then
		local a = {}
		local f = io.open(path, "r")
		local l = f:read("*l")
		while l ~= nil do
			l = l:gsub("^%s*(.-)%s*$", "%1")
			if l ~= "" and l ~= nil and l ~= "\n" then
				local b = l:find("=")
				if a and b then
					local c = l:sub(1, b - 1)
					local d = l:sub(b + 1, -1)
					if c == "" or d == "" then return nil
					else a[c] = d end
				else return nil end
			end
			l = f:read("*l")
		end
		f:close()

		return a
	else
		return nil
	end
end


--  -------- Filesystem

local function download(url, path)
	for i = 1, 3 do
		local response = http.get(url)
		if response then
			local data = response.readAll()
			response.close()
			local f = io.open(path, "w")
			f:write(data)
			f:close()
			return true
		end
	end

	return false
end

local function validateFilesystem()
	if not fs.exists(rootFolder) or not fs.exists(serverFolder) or not fs.exists(dataLocation) or
			not fs.exists(serverLocation) or not fs.exists(dataLocation .. "/home") then
		term.setBackgroundColor(colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.clear()
		term.setCursorPos(1, 1)
		print("")
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Invalid Filesystem!")
		centerPrint(string.rep(" ", 47))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		centerPrint(string.rep(" ", 47))
		centerPrint("  The files required to run this server        ")
		centerPrint("  cannot be found! Run Firewolf to create      ")
		centerPrint("  them!                                        ")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		if isAdvanced() then centerPrint("Click to exit...")
		else centerPrint("Press any key to exit...") end
		centerPrint(string.rep(" ", 47))

		while true do
			local e = os.pullEvent()
			if e == "key" or e == "mouse_click" then break end
		end

		return false
	else
		return true
	end
end

local function updateClient()
	local updateLocation = rootFolder .. "/server-update"
	fs.delete(updateLocation)

	-- Update
	download(serverURL, updateLocation)
	local a = io.open(updateLocation, "r")
	local b = io.open(serverLocation, "r")
	local new = a:read("*a")
	local cur = b:read("*a")
	a:close()
	b:close()

	if cur ~= new then
		fs.delete(serverLocation)
		fs.move(updateLocation, serverLocation)
		shell.run(serverLocation, args[1], args[2])
		error()
	else
		fs.delete(updateLocation)
	end
end


--  -------- Loading

local serverAPIContent = [[

--  
--  Custom Server API
--  

-- Notes:
-- - These functions are called when events occur
-- - Their names are required to be kept the same
-- - These functions must be able to execute
--   instantly, else your server may be DDoS-able


uponSuccessfulRequest = function(page, id)
	-- Called when a request for a page is successful

	-- Your Code Here...
end

uponFailedRequest = function(page, id)
	-- Called when a request for a page is unsuccessful

	-- Your Code Here...
end

uponAnyOtherMessage = function(message, id)
	-- Called when any rendet message is received
	-- that is not requesting a page

	-- Your Code Here...
end

uponAnyMessage = function(message, id)
	-- Called when any rednet message is received

	-- Your Code Here...
end

parallelWithServer = function()
	-- Runs in a parallel alongside the server

	-- Your Code Here...
end

local function uponServerApiLoad()
	-- Called when this Server API is loaded

	-- Your Code Here...
end

uponServerApiLoad()

]]

local function loadServerAPI()
	if not fs.exists(dataLocation .. "/serverapi") then
		local f = io.open(dataLocation .. "/serverapi", "w")
		f:write(serverAPIContent)
		f:close()
	end

	shell.run(dataLocation .. "/serverapi")
	if type(uponSuccessfulRequest) ~= "function" then
		uponSuccessfulRequest = nil
	end if type(uponFailedRequest) ~= "function" then
		uponFailedRequest = nil
	end if type(uponAnyOtherMessage) ~= "function" then
		uponAnyOtherMessage = nil
	end if type(uponAnyMessage) ~= "function" then
		uponAnyMessage = nil
	end if type(parallelWithServer) ~= "function" then
		parallelWithServer = nil
	end
end

local function loadPages(loc)
	local a = fs.list(loc)
	local p = {}
	for i = 1, #a do
		if not fs.isDir(loc .. "/" .. a[i]) then
			local f = io.open(loc .. "/" .. a[i])
			local cont = f:read("*a")
			f:close()

			p[loc .. "/" .. a[i]] = cont
		else
			local b = loadPages(loc .. "/" .. a[i])
			for x = 1, #b do
				table.insert(p, b[x])
			end
		end
	end

	return p
end

local function checkForModem()
	while true do
		local present = false
		for _, v in pairs(rs.getSides()) do
			if peripheral.getType(v) == "modem" then
				rednet.open(v)
				present = true
				break
			end
		end

		if not present then
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["background"]])
			term.clear()
			term.setCursorPos(1, 2)
			print("")
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("No Modem Attached! D:")
			centerPrint(string.rep(" ", 43))
			print("")

			term.setBackgroundColor(colors[theme["bottom-box"]])
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("No wireless modem was found on this")
			centerWrite(string.rep(" ", 43))
			centerPrint("computer, and Firewolf is not able to")
			centerWrite(string.rep(" ", 43))
			centerPrint("run without one!")
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Waiting for a modem to be attached...")
			centerWrite(string.rep(" ", 43))
			if isAdvanced() then centerPrint("Click to exit...")
			else centerPrint("Press any key to exit...") end
			centerPrint(string.rep(" ", 43))

			while true do
				local e, id = os.pullEvent()
				if e == "key" or e == "mouse_click" then return false
				elseif e == "peripheral" then break end
			end
		else
			return true
		end
	end
end


--  -------- Respond to Messages

local i = 1
local function record(text)
	local oldX, oldY = term.getCursorPos()
	local a = tostring(i) .. ":" .. string.rep(" ", 4 - tostring(i):len()) .. text
	table.insert(totalRecordLines, a)
	if #recordLines > 8 then table.remove(recordLines, 1) end
	table.insert(recordLines, a)

	if enableRecording then clearPage(true) end
	i = i + 1
	term.setCursorPos(oldX, oldY)
	term.setBackgroundColor(colors[theme["top-box"]])
	term.setTextColor(colors[theme["text-color"]])
end

local function respondToEvents()
	if uponSuccessfulRequest == nil or uponFailedRequest == nil or uponAnyMessage == nil or 
			uponAnyOtherMessage == nil or parallelWithServer == nil then
		record("Warning - Failed To Load Server API:")
		if uponSuccessfulRequest == nil then record(" - uponSuccessfulRequest()") end
		if uponFailedRequest == nil then record(" - uponFailedRequest()") end
		if uponAnyMessage == nil then record(" - uponAnyMessage()") end
		if uponAnyOtherMessage == nil then record(" - uponAnyOtherMessage()") end
		if parallelWithServer == nil then record(" - parallelWithServer()") end
	else record("Loaded Server API") end

	local writingClock = os.clock()
	local ignoreClock = os.clock()
	while true do
		if os.clock() - ignoreClock < 6 then
			for k, v in pairs(suspected) do
				if v > 10 then table.insert(ignoreDatabase, tostring(k)) end
			end
		else
			ignoreDatabase = {}
			suspected = {}
			ignoreClock = os.clock()
		end

		local e, id, mes = os.pullEvent()

		local ignore = false
		for _, v in pairs(ignoreDatabase) do
			if tostring(id) == v then ignore = true break end
		end for _, v in pairs(permantentIgnoreDatabase) do
			if tostring(id) == v then ignore = true break end
		end

		if e == "rednet_message" and enableResponse == true and not ignore then
			if mes == website or mes == website .. "/" or mes == website .. "/home" then
				if suspected[tostring(id)] then suspected[tostring(id)] = suspected[tostring(id)] + 1
				else suspected[tostring(id)] = 1 end
				for i = 1, 3 do rednet.send(id, pages[dataLocation .. "/home"]) end
				record("/home : " .. tostring(id))
				visits = visits + 1

				if uponSuccessfulRequest ~= nil then uponSuccessfulRequest("/home", id) end
			elseif mes:find("/") then
				local a = mes:sub(1, mes:find("/") - 1)
				if a == website then
					if suspected[tostring(id)] then 
						suspected[tostring(id)] = suspected[tostring(id)] + 1
					else suspected[tostring(id)] = 1 end
					local b = mes:sub(mes:find("/"), -1)
					local c = b
					if c:len() > 18 then c = c:sub(1, 15) .. "..." end
					if pages[dataLocation .. b] and b ~= "/serverapi" then
						for i = 1, 3 do rednet.send(id, pages[dataLocation .. b]) end
						record(c .. " : " .. id)
						visits = visits + 1

						if uponSuccessfulRequest ~= nil then uponSuccessfulRequest(b, id) end
					else
						record("Failed - " .. c .. " : " .. id)
						if uponFailedRequest ~= nil then uponFailedRequest(b, id) end
					end
				end
			elseif mes == "firewolf.broadcast.dns.list" then
				if suspected[tostring(id)] then suspected[tostring(id)] = suspected[tostring(id)] + 1
				else suspected[tostring(id)] = 1 end
				rednet.send(id, "firewolf-site:" .. website)
				searches = searches + 1
			else
				if uponAnyOtherMessage ~= nil then uponAnyOtherMessage(mes, id) end
			end

			if uponAnyMessage ~= nil then uponAnyMessage(mes, id) end
		elseif e == event_stopServer then
			return
		end

		-- Save stats
		if os.clock() - writingClock > 5 then
			local f = io.open(statsLocation, "w")
			f:write(tostring(visits) .. "\n" .. tostring(searches) .. "\n" ..
				textutils.serialize(permantentIgnoreDatabase))
			f:close()
			writingClock = os.clock()
		end
	end
end


--  -------- Interface

local function edit()
	openAddressBar = false
	local oldLoc = shell.dir()
	local commandHis = {}
	local dir = dataLocation
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)
	print("")
	print(" Server Shell Editing")
	print(" Type 'exit' to return to Firewolf.")
	print(" The 'home' file is the index of your site")
	print("")

	local allowed = {"move", "mv", "cp", "copy", "drive", "delete", "rm", "edit", 
		"eject", "exit", "help", "id", "monitor", "rename", "alias", "clear",
		"paint", "firewolf", "lua", "redstone", "rs", "redprobe", "redpulse", "programs",
		"redset", "reboot", "hello", "label", "list", "ls", "easter", "pastebin", "dir"}
	
	while true do
		shell.setDir(serverFolder .. "/" .. website)
		term.setBackgroundColor(colors.black)
		if isAdvanced() then term.setTextColor(colors.yellow)
		else term.setTextColor(colors.white) end
		write("> ")
		term.setTextColor(colors.white)
		local line = read(nil, commandHis)
		table.insert(commandHis, line)

		local words = {}
		for m in string.gmatch(line, "[^ \t]+") do
			local a = m:gsub("^%s*(.-)%s*$", "%1")
			table.insert(words, a)
		end

		local com = words[1]
		if com == "exit" then
			break
		elseif com then
			local a = false
			for _, v in pairs(allowed) do
				if com == v then a = true break end
			end

			if a then
				term.setBackgroundColor(colors.black)
				term.setTextColor(colors.white)
				shell.run(com, unpack(words, 2))
			else
				term.setTextColor(colors.red)
				print("Program Not Allowed!")
			end
		end
	end
	shell.setDir(oldLoc)
end

local function interface()
	local opt = ""
	while true do
		term.setBackgroundColor(colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.clear()
		term.setCursorPos(1, 1)
		clearPage(true)
		term.setCursorPos(1, 2)
		print("")
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		for i = 1, 4 do centerPrint(string.rep(" ", 47)) end
		print("")
		term.setBackgroundColor(colors[theme["bottom-box"]])

		if enableResponse == false then p1 = "Unpause Server" end
		term.setBackgroundColor(colors[theme["top-box"]])
		if not serverLocked and not serverPassword then
			os.pullEvent = oldPullEvent
			opt = prompt({{"Add Lock", 5, 4}, {"Edit", 5, 5}, {"Manage", w - 15, 4}, 
				{"Stop", w - 13, 5}}, "vertical")
		elseif not serverLocked and serverPassword then
			opt = prompt({{"Lock Server", 5, 4}, {"Edit", 5, 5}, {"Manage", w - 15, 4}, 
				{"Stop", w - 13, 5}}, "vertical")
		elseif serverLocked then
			while true do
				enableRecording = true
				term.setCursorPos(1, 2)
				print("")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				for i = 1, 4 do centerPrint(string.rep(" ", 47)) end
				term.setCursorPos(5, 4)
				print("Enter Password:")
				term.setCursorPos(5, 5)
				write("> ")
				local enteredPassword = read("*")
				if enteredPassword == serverPassword then
					term.setCursorPos(1, 2)
					print("")
					term.setTextColor(colors[theme["text-color"]])
					term.setBackgroundColor(colors[theme["top-box"]])
					for i = 1, 4 do centerPrint(string.rep(" ", 47)) end
					term.setCursorPos(5, 4)
					write("Password Accepted!")
					opt = ""
					serverLocked = false
					os.pullEvent = oldPullEvent
					sleep(1.3)
					break
				else
					term.setCursorPos(1, 2)
					print("")
					term.setTextColor(colors[theme["text-color"]])
					term.setBackgroundColor(colors[theme["top-box"]])
					for i = 1, 4 do centerPrint(string.rep(" ", 47)) end
					term.setCursorPos(5, 4)
					write("Password Incorrect!")
					sleep(1.3)
				end
			end
		end

		if opt == p1 then
			enableResponse = not enableResponse
		elseif opt == "Manage" then
			while true do
				enableRecording = false
				clearPage()
				term.setCursorPos(1, 8)
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["bottom-box"]])
				for i = 1, 11 do centerPrint(string.rep(" ", 47)) end

				term.setCursorPos(5, 9)
				write("Visits: " .. tostring(visits))
				term.setCursorPos(5, 10)
				write("Searches: " .. tostring(searches))
				local opt = ""
				if serverPassword then
					opt = prompt({{"Manage Blocked IDs", 9, 12}, {"Remove Password", 9, 13}, 
						{"Delete Server", 9, 14}, {"Back", 9, 16}}, "vertical")
				else
					opt = prompt({{"Manage Blocked IDs", 9, 12}, {"Delete Server", 9, 13}, 
						{"Back", 9, 15}}, "vertical")
				end
				if opt == "Manage Blocked IDs" then
					while true do
						clearPage()
						term.setCursorPos(1, 8)
						term.setTextColor(colors[theme["text-color"]])
						term.setBackgroundColor(colors[theme["bottom-box"]])
						for i = 1, 11 do centerPrint(string.rep(" ", 47)) end

						term.setCursorPos(5, 9)
						if isAdvanced() then write("Blocked IDs: (Click to Unblock)")
						else write("Blocked IDs: (Select to Unblock)") end
						local a = {"Back", "Block New ID"}
						for _, v in pairs(permantentIgnoreDatabase) do
							table.insert(a, v)
						end

						local b = scrollingPrompt(a, 5, 11, 7, 43)
						if b == "Back" then
							break
						elseif b == "Block New ID" then
							term.setCursorPos(5, 10)
							write("ID: ")
							local c = read():gsub("^%s*(.-)%s*$", "%1")
							local d = tonumber(c)
							local found = false
							for k, v in pairs(permantentIgnoreDatabase) do
								if v == tostring(d) then found = true break end
							end
							if d == nil then
								term.setCursorPos(1, 10)
								centerWrite(string.rep(" ", 47))
								term.setCursorPos(5, 10)
								write("Not a Valid ID!")
								sleep(1.1)
							elseif found == true then
								term.setCursorPos(1, 10)
								centerWrite(string.rep(" ", 47))
								term.setCursorPos(5, 10)
								write("ID Already Exists!")
								sleep(1.1)
							else
								term.setCursorPos(1, 10)
								centerWrite(string.rep(" ", 47))
								term.setCursorPos(5, 10)
								write("Blocked ID: " .. c .. "!")
								table.insert(permantentIgnoreDatabase, tostring(d))
								sleep(1.1)
							end
						else
							for i, v in ipairs(permantentIgnoreDatabase) do
								if v == b then table.remove(permantentIgnoreDatabase, i) end
							end
						end
					end
				elseif opt == "Delete Server" then
					clearPage()
					term.setCursorPos(1, 8)
					term.setTextColor(colors[theme["text-color"]])
					term.setBackgroundColor(colors[theme["bottom-box"]])
					for i = 1, 11 do centerPrint(string.rep(" ", 47)) end
					term.setCursorPos(9, 11)
					centerPrint("Are you sure you want to delete the server?")
					centerPrint("This cannot be undone!")
					local opt = prompt({{"No", 11, 14}, {"Yes", 35, 14}}, "horizontal")
					if opt == "Yes" then
						fs.delete(dataLocation)
						os.queueEvent(event_stopServer)
						return
					end
				elseif opt == "Remove Password" then
					clearPage()
					term.setCursorPos(1, 8)
					term.setTextColor(colors[theme["text-color"]])
					term.setBackgroundColor(colors[theme["bottom-box"]])
					for i = 1, 11 do centerPrint(string.rep(" ", 47)) end
					term.setCursorPos(9, 11)
					print("Enter your old password:")
					term.setCursorPos(9, 12)
					write("> ")
					local oldPass = read("*")
					if oldPass == serverPassword then
						fs.delete(passwordDataLocation)
						serverPassword = nil
						serverLocked = false
						term.setCursorPos(9, 14)
						print("Password Removed!")
						sleep(1.3)
						break
					else
						term.setCursorPos(9, 14)
						print("Password incorrect! Locking server...")
						os.pullEvent = os.pullEventRaw
						serverLocked = true
						sleep(1.3)
						break
					end
				elseif opt == "Back" then
					break
				end
			end
			
			enableRecording = true
		elseif opt == "Edit" then
			enableRecording = false
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			term.clear()
			term.setCursorPos(1, 1)
			edit()

			term.clear()
			pages = loadPages(dataLocation)
			loadServerAPI()
			if uponSuccessfulRequest == nil or uponFailedRequest == nil or uponAnyMessage == nil or 
					uponAnyOtherMessage == nil or parallelWithServer == nil then
				record("Warning - Failed To Load Server API:")
				if uponSuccessfulRequest == nil then record(" - uponSuccessfulRequest()") end
				if uponFailedRequest == nil then record(" - uponFailedRequest()") end
				if uponAnyMessage == nil then record(" - uponAnyMessage()") end
				if uponAnyOtherMessage == nil then record(" - uponAnyOtherMessage()") end
				if parallelWithServer == nil then record(" - parallelWithServer()") end
			else record("Re-Loaded Server API") end
			enableRecording = true
		elseif opt == "Add Lock" then
			enableRecording = false
			clearPage()
			term.setCursorPos(1, 8)
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["bottom-box"]])
			for i = 1, 11 do centerPrint(string.rep(" ", 47)) end
			term.setCursorPos(5, 9)
			write("Enter a password to secure your")
			term.setCursorPos(5, 10)
			write("server from being managed by others:")
			term.setCursorPos(5, 11)
			write("> ")
			local newPassword = read("*")
			term.setCursorPos(5, 13)
			write("Enter the password again:")
			term.setCursorPos(5, 14)
			write("> ")
			if read("*") == newPassword then
				serverPassword = newPassword
				serverLocked = false
				local f = io.open(passwordDataLocation, "w")
				f:write(newPassword)
				f:close()
				term.setCursorPos(5, 16)
				write("Password Set!")
				sleep(1.3)
			else
				term.setCursorPos(5, 16)
				print("Passwords did not match!")
				sleep(1.3)
			end
			enableRecording = false
		elseif opt == "Lock Server" then
				os.pullEvent = os.pullEventRaw
				serverLocked = true
				term.setCursorPos(1, 2)
				print("")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				for i = 1, 4 do centerPrint(string.rep(" ", 47)) end
				term.setCursorPos(5, 4)
				print("Server Locked!")
				sleep(2)
		elseif opt == "Stop" then
			-- Stop server
			os.queueEvent(event_stopServer)
			return
		end
	end
end


--  -------- Main

local function main()
	-- Logo
	term.setBackgroundColor(colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.clear()
	term.setCursorPos(1, 2)
	term.setBackgroundColor(colors[theme["top-box"]])
	leftPrint(string.rep(" ", 47))
	leftPrint([[          ______ ____ ____   ______            ]])
	leftPrint([[ ------- / ____//  _// __ \ / ____/            ]])
	leftPrint([[ ------ / /_    / / / /_/ // __/               ]])
	leftPrint([[ ----- / __/  _/ / / _  _// /___               ]])
	leftPrint([[ ---- / /    /___//_/ |_|/_____/               ]])
	leftPrint([[ --- / /       _       __ ____   __     ______ ]])
	leftPrint([[ -- /_/       | |     / // __ \ / /    / ____/ ]])
	leftPrint([[              | | /| / // / / // /    / /_     ]])
	leftPrint([[              | |/ |/ // /_/ // /___ / __/     ]])
	leftPrint([[              |__/|__/ \____//_____//_/        ]])
	leftPrint(string.rep(" ", 47))
	print("\n")
	term.setBackgroundColor(colors[theme["bottom-box"]])

	rightPrint(string.rep(" ", 27 + version:len()))
	rightPrint("  Loading Firewolf Server " .. version .. " ")
	rightPrint(string.rep(" ", 27 + version:len()))

	-- Filesystem
	if not validateFilesystem() then return end

	-- Update
	if autoupdate then updateClient() end

	-- Load
	pages = loadPages(dataLocation)
	loadServerAPI()
	if fs.exists(statsLocation) then
		local f = io.open(statsLocation, "r")
		local a = tonumber(f:read("*l"))
		local b = tonumber(f:read("*l"))
		local c = f:read("*l")
		if a then visits = a end
		if b then searches = b end
		if c then permantentIgnoreDatabase = textutils.unserialize(c) end
		f:close()
	end
	if not checkForModem() then return end

	-- Start UI
	parallel.waitForAll(respondToEvents, interface, parallelWithServer)
end

local function startup()
	-- HTTP API
	if not http then
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 2)
		term.setBackgroundColor(colors[theme["top-box"]])
		leftPrint(string.rep(" ", 24))
		leftPrint(" HTTP Not Enabled!  ")
		leftPrint(string.rep(" ", 24))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		rightPrint(string.rep(" ", 36))
		rightPrint("  Firewolf is unable to run without ")
		rightPrint("       the HTTP Enabled! Please ")
		rightPrint("    enable it in your ComputerCraft ")
		rightPrint("                            Config! ")
		rightPrint(string.rep(" ", 36))

		if isAdvanced() then rightPrint("                   Click to exit... ")
		else rightPrint("           Press any key to exit... ") end
		rightPrint(string.rep(" ", 36))

		while true do
			local e, but, x, y = os.pullEvent()
			if e == "mouse_click" or e == "key" then break end
		end

		return false 
	end

	-- Turtle
	if turtle then
		term.clear()
		term.setCursorPos(1, 2)
		centerPrint("Advanced Comptuer Required!")
		print("\n")
		centerPrint("This version of Firewolf requires")
		centerPrint("an Advanced Comptuer to run!")
		print("")
		centerPrint("Turtles may not be used to run")
		centerPrint("Firewolf! :(")
		print("")
		centerPrint("Press any key to exit...")

		os.pullEvent("key")
		return false
	end

	-- Run
	local _, err = pcall(main)
	if err and err ~= "parallel:22: Terminated" then
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 2)
		term.setCursorBlink(false)
		term.setBackgroundColor(colors[theme["top-box"]])
		leftPrint(string.rep(" ", 27))
		leftPrint(" Firewolf has Crashed! D:  ")
		leftPrint(string.rep(" ", 27))
		print("")
		term.setBackgroundColor(colors[theme["background"]])
		print("")
		print("  " .. err)
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		rightPrint(string.rep(" ", 41))
		if autoupdate == "true" then
			rightPrint("    Please report this error to 1lann or ")
			rightPrint("  GravityScore so we are able to fix it! ")
			rightPrint("  If this problem persists, try deleting ")
			rightPrint("                         " .. rootFolder .. " ")
		else
			rightPrint("        Automatic updating is off! A new ")
			rightPrint("     version may have have been released ")
			rightPrint("                that may fix this error! ")
			rightPrint("        If you didn't turn auto updating ")
			rightPrint("             off, delete " .. rootFolder .. " ")
		end

		rightPrint(string.rep(" ", 41))
		if isAdvanced() then rightPrint("                        Click to exit... ")
		else rightPrint("                Press any key to exit... ") end
		rightPrint(string.rep(" ", 41))

		while true do
			local e, but, x, y = os.pullEvent()
			if e == "mouse_click" or e == "key" then break end
		end

		return false
	end

	return true
end

-- Check If Read Only
if fs.isReadOnly(serverLocation) or fs.isReadOnly(rootFolder) then
	print("Firewolf cannot modify itself or its root folder!")
	print("")
	print("This cold be caused by Firewolf being placed in")
	print("the rom folder, or another program may be")
	print("preventing the modification of Firewolf.")

	-- Reset Environment and Exit
	setfenv(1, oldEnv)
	error()
end

-- Theme
if not isAdvanced() then 
	theme = originalTheme
else
	theme = loadTheme(themeLocation)
	if theme == nil then theme = defaultTheme end
end

-- Pasword
if fs.exists(passwordDataLocation) then
	local f = io.open(passwordDataLocation, "r")
	serverPassword = f:read("*l")
	f:close()
	serverLocked = true
else
	serverLocked = false
end

-- Start
startup()

-- Clear
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
centerPrint("Thank You for Using Firewolf Server " .. version)
centerPrint("Made by 1lann and GravityScore")
term.setCursorPos(1, 3)

-- Close Rednet
for _, v in pairs(rs.getSides()) do 
	if peripheral.getType(v) == "modem" then rednet.close(v) end
end
