
--
--  Firewolf Website Browser
--  Made by GravityScore and 1lann
--  License found here: https://raw.github.com/1lann/Firewolf/master/LICENSE
--
--  Original Concept From RednetExplorer 2.4.1
--  RednetExplorer Made by ComputerCraftFan11
--


--  -------- Variables

-- Version
local version = "2.5"
local build = 36
local browserAgent = "Firewolf " .. version
local tArgs = {...}

-- Server Identification
local serverID = "other"
local serverList = {experimental = "Experimental", other = "Other"}

-- Updating
local autoupdate = "true"
local noInternet = false

-- Resources
local graphics = {}
local files = {}
local w, h = term.getSize()

-- Debugging
local debugFile = nil

-- Environment
local oldEnv = {}
local env = {}
local api = {}
local override = {}
local antivirus = {}

-- Themes
local theme = {}

-- Databases
local blacklist = {}
local whitelist = {}
local dnsDatabase = {{}, {}}

-- Website Loading
local pages = {}
local errorPages = {}

local website = ""
local homepage = ""
local timeout = 0.2
local loadingRate, loadingClock = 0, nil
local openAddressBar, clickableAddressBar = true, true
local menuBarOpen = false
local offsetclick = true
local websiteerror = nil

-- Tabs
local tabs = {}
local filters = {}
local currentTab = 1

-- Protocols
local curProtocol = {}
local protocols = {}

-- History
local addressBarHistory = {}

-- Events
local event_load = "firewolf_websiteLoadEvent"
local event_redirect = "firewolf_redirectEvent"
local event_error = "firewolf_siteErrorEvent"
local event_exit = "firewolf_exitEvent"

-- Download URLs
local firewolfURL = "https://raw.github.com/1lann/Firewolf/master/entities/other.lua"
local serverURL = "https://raw.github.com/1lann/Firewolf/master/server/server-release.lua"
local buildURL = "https://raw.github.com/1lann/Firewolf/master/build"

-- Data Locations
local rootFolder = "/.Firewolf_Data"
local cacheFolder = rootFolder .. "/cache"
local serverFolder = rootFolder .. "/servers"
local websiteDataFolder = rootFolder .. "/website_data"
local themeLocation = rootFolder .. "/theme"
local serverLocation = rootFolder .. "/server_software"
local settingsLocation = rootFolder .. "/settings"
local debugLogLocation = "/firewolf-log"
local firewolfLocation = "/" .. shell.getRunningProgram()

local userBlacklist = rootFolder .. "/user_blacklist"
local userWhitelist = rootFolder .. "/user_whitelist"

local function isAdvanced() return term.isColor and term.isColor() end

local function modemPresent()
	if curProtocol == protocols.rdnt then
		for _, v in pairs(rs.getSides()) do
			if peripheral.getType(v) == "modem" then rednet.open(v) return true end
		end
	else return true end
	return false
end


--  -------- Utilities

local function debugLog(n, ...)
	local lArgs = {...}
	if debugFile then
		if not n then return end
		debugFile:write("\n" .. tostring(n) .. " : ")
		for k, v in pairs(lArgs) do
			if type(v) == "string" or type(v) == "number" or not type(v) or type(v) == "boolean" then
				debugFile:write(tostring(v) .. ", ")
			else debugFile:write("type-" .. type(v) .. ", ") end
		end
	end
end

local function clear(site, background, drawmenu)
	local titles = {
		["firewolf"] = "Firewolf",
		["server/rdnt"] = "Server Management",
		["server/http"] = "Server Management",
		["help"] = "Help",
		["settings"] = "Settings",
		["credits"] = "Credits",
		["crash"] = "Crashed!",
		["overspeed"] = "Too Fast!"
	}

	local title = titles[site] or ""
	term.setBackgroundColor(background or colors.black)
	term.setTextColor(colors[theme["address-bar-text"]])
	if drawmenu ~= true then term.clear() end

	if not menuBarOpen then
		term.setBackgroundColor(colors[theme["address-bar-background"]])
		term.setCursorPos(2, 1)
		term.clearLine()
		if site:len() > w - 10 then site = site:sub(1, 38) .. "..." end
		if curProtocol == protocols.http then write("http://" .. site)
		else write("rdnt://" .. site) end
		term.setCursorPos(w - title:len() - 1, 1)
		write(title)

		if isAdvanced() then
			term.setCursorPos(w, 1)
			term.setBackgroundColor(colors[theme["top-box"]])
			term.setTextColor(colors[theme["text-color"]])
			write("<")
		end

		term.setBackgroundColor(background or colors.black)
		term.setTextColor(colors.white)
	else
		term.setCursorPos(1, 1)
		term.setBackgroundColor(colors[theme["top-box"]])
		term.setTextColor(colors[theme["text-color"]])
		term.clearLine()
		write("> [- Exit Firewolf -]                              ")
	end

	print("")
end

local function modRead(properties)
	local w, h = term.getSize()
	local defaults = {replaceChar = nil, history = nil, visibleLength = nil, textLength = nil,
		liveUpdates = nil, exitOnKey = nil}
	if not properties then properties = {} end
	for k, v in pairs(defaults) do if not properties[k] then properties[k] = v end end
	if properties.replaceChar then properties.replaceChar = properties.replaceChar:sub(1, 1) end
	if not properties.visibleLength then properties.visibleLength = w end

	local sx, sy = term.getCursorPos()
	local line = ""
	local pos = 0
	local historyPos = nil

	local function redraw(repl)
		local scroll = 0
		if properties.visibleLength and sx + pos > properties.visibleLength + 1 then
			scroll = (sx + pos) - (properties.visibleLength + 1)
		end

		term.setCursorPos(sx, sy)
		local a = repl or properties.replaceChar
		if a then term.write(string.rep(a, line:len() - scroll))
		else term.write(line:sub(scroll + 1, -1)) end
		term.setCursorPos(sx + pos - scroll, sy)
	end

	local function sendLiveUpdates(event, ...)
		if type(properties.liveUpdates) == "function" then
			local ox, oy = term.getCursorPos()
			local a, data = properties.liveUpdates(line, event, ...)
			if a == true and not data then
				term.setCursorBlink(false)
				return line
			elseif a == true and data then
				term.setCursorBlink(false)
				return data
			end
			term.setCursorPos(ox, oy)
		end
	end

	local a = sendLiveUpdates("delete")
	if a then return a end
	term.setCursorBlink(true)
	while true do
		local e, but, x, y, p4, p5 = os.pullEvent()
		if e == "char" then
			local s = false
			if properties.textLength and line:len() < properties.textLength then s = true
			elseif not properties.textLength then s = true end

			local canType = true
			if not properties.grantPrint and properties.refusePrint then
				local canTypeKeys = {}
				if type(properties.refusePrint) == "table" then
					for _, v in pairs(properties.refusePrint) do
						table.insert(canTypeKeys, tostring(v):sub(1, 1))
					end
				elseif type(properties.refusePrint) == "string" then
					for char in properties.refusePrint:gmatch(".") do
						table.insert(canTypeKeys, char)
					end
				end
				for _, v in pairs(canTypeKeys) do if but == v then canType = false end end
			elseif properties.grantPrint then
				canType = false
				local canTypeKeys = {}
				if type(properties.grantPrint) == "table" then
					for _, v in pairs(properties.grantPrint) do
						table.insert(canTypeKeys, tostring(v):sub(1, 1))
					end
				elseif type(properties.grantPrint) == "string" then
					for char in properties.grantPrint:gmatch(".") do table.insert(canTypeKeys, char) end
				end
				for _, v in pairs(canTypeKeys) do if but == v then canType = true end end
			end

			if s and canType then
				line = line:sub(1, pos) .. but .. line:sub(pos + 1, -1)
				pos = pos + 1
				redraw()
			end
		elseif e == "key" then
			if but == keys.enter then break
			elseif but == keys.left then if pos > 0 then pos = pos - 1 redraw() end
			elseif but == keys.right then if pos < line:len() then pos = pos + 1 redraw() end
			elseif (but == keys.up or but == keys.down) and properties.history and
					#properties.history > 0 then
				redraw(" ")
				if but == keys.up then
					if not historyPos and #properties.history > 0 then
						historyPos = #properties.history
					elseif historyPos > 1 then historyPos = historyPos - 1 end
				elseif but == keys.down then
					if historyPos == #properties.history then historyPos = nil
					elseif historyPos then historyPos = historyPos + 1 end
				end

				if properties.history and historyPos then
					line = properties.history[historyPos]
					pos = line:len()
				else
					line = ""
					pos = 0
				end

				redraw()
				local a = sendLiveUpdates("history")
				if a then return a end
			elseif but == keys.backspace and pos > 0 then
				redraw(" ")
				line = line:sub(1, pos - 1) .. line:sub(pos + 1, -1)
				pos = pos - 1
				redraw()
				local a = sendLiveUpdates("delete")
				if a then return a end
			elseif but == keys.home then
				pos = 0
				redraw()
			elseif but == keys.delete and pos < line:len() then
				redraw(" ")
				line = line:sub(1, pos) .. line:sub(pos + 2, -1)
				redraw()
				local a = sendLiveUpdates("delete")
				if a then return a end
			elseif but == keys["end"] then
				pos = line:len()
				redraw()
			elseif properties.exitOnKey then
				if but == properties.exitOnKey or (properties.exitOnKey == "control" and
						(but == 29 or but == 157)) then
					term.setCursorBlink(false)
					return nil
				end
			end
		end

		local a = sendLiveUpdates(e, but, x, y, p4, p5)
		if a then return a end
	end

	term.setCursorBlink(false)
	if line then line = line:gsub("^%s*(.-)%s*$", "%1") end
	return line
end


--  -------- API

--  Drawing

local function printWithType(t, func)
	if type(t) == "table" then
		for _, v in pairs(t) do env.pcall(function() printWithType(v, func) end) end
	else func(tostring(t)) end
end

api.centerWrite = function(text)
	printWithType(text, function(t)
		local x, y = term.getCursorPos()
		term.setCursorPos(math.ceil((w + 1)/2 - t:len()/2), y)
		write(t)
	end)
end

api.centerPrint = function(text)
	printWithType(text, function(t)
		local x, y = term.getCursorPos()
		term.setCursorPos(math.ceil((w + 2)/2 - t:len()/2), y)
		print(t)
	end)
end

api.leftWrite = function(text)
	printWithType(text, function(t)
		local x, y = term.getCursorPos()
		term.setCursorPos(1, y)
		write(t)
	end)
end

api.leftPrint = function(text)
	printWithType(text, function(t)
		local x, y = term.getCursorPos()
		term.setCursorPos(1, y)
		print(t)
	end)
end

api.rightWrite = function(text)
	printWithType(text, function(t)
		local x, y = term.getCursorPos()
		term.setCursorPos(w - t:len() + 1, y)
		write(t)
	end)
end

api.rightPrint = function(text)
	printWithType(text, function(t)
		local x, y = term.getCursorPos()
		term.setCursorPos(w - t:len() + 1, y)
		print(t)
	end)
end

api.clearArea = function() term.clear() term.setCursorPos(1, 1) end
api.cPrint = function(text) api.centerPrint(text) end
api.cWrite = function(text) api.centerWrite(text) end
api.lPrint = function(text) api.leftPrint(text) end
api.lWrite = function(text) api.leftWrite(text) end
api.rPrint = function(text) api.rightPrint(text) end
api.rWrite = function(text) api.rightWrite(text) end


--  Server Interation

api.loadFileFromServer = function(path)
	if type(path) ~= "string" then error("expected string", 2) end
	sleep(0.05)
	if path:sub(1, 1) == "/" then path = path:sub(2, -1) end
	local id, content = curProtocol.getWebsite(website .. "/" .. path)
	if id then return content end
	return nil
end

api.ioReadFileFromServer = function(path)
	local content = api.loadFileFromServer(path)
	if content then
		local f = env.io.open(rootFolder .. "/temp_file", "w")
		f:write(content)
		f:close()
		return env.io.open(rootFolder .. "/temp_file", "r")
	end
	return nil
end

api.loadImageFromServer = function(path)
	local content = api.loadFileFromServer(path)
	if content then
		local f = env.io.open(rootFolder .. "/temp_file", "w")
		f:write(content)
		f:close()

		local image = paintutils.loadImage(rootFolder .. "/temp_file")
		env.fs.delete("/temp_file")
		return image
	end
	return nil
end

api.writeDataFile = function(path, content)
	if type(path) ~= "string" or type(content) ~= "string" then
		error("expected string, string", 2) end
	if path:sub(1, 1) == "/" then path = path:sub(2, -1) end
	local dataPath = websiteDataFolder .. "/" .. path:gsub("/", "$slazh$")

	if env.fs.isReadOnly(dataPath) then return false end
	if env.fs.exists(dataPath) then env.fs.delete(dataPath) end
	local f = env.io.open(dataPath, "w")
	if not f then return false end
	f:write(content)
	f:close()
	return true
end

api.readDataFile = function(path)
	if type(path) ~= "string" then error("readDataFile: expected string") end
	if path:sub(1, 1) == "/" then path = path:sub(2, -1) end
	local dataPath = websiteDataFolder .. "/" .. path:gsub("/", "$slazh$")

	if env.fs.isDir(dataPath) then env.fs.delete(dataPath) end
	if env.fs.exists(dataPath) then
		local f = env.io.open(dataPath, "r")
		local cont = f:read("*a")
		f:close()
		return cont
	end
	return nil
end

api.saveFileToUserComputer = function(content)
	if type(content) ~= "string" then error("expected string", 2) end
	local oldback, oldtext = override.term.getBackgroundColor(), override.term.getTextColor()
	local ox, oy = term.getCursorPos()

	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setCursorPos(1, 1)
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	leftPrint(string.rep(" ", 20))
	leftPrint(" Save File Request  ")
	leftPrint(string.rep(" ", 20))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 11 do rightPrint(string.rep(" ", 36)) end
	term.setCursorPos(1, 7)
	rightPrint("The website: ")
	rightPrint(website .. "  ")
	rightPrint("Is requesting to save a file ")
	rightPrint("to your computer. ")

	local ret = nil
	local opt = prompt({{"Save File", w - 16, 12}, {"Cancel", w - 13, 13}}, "vertical")
	if opt == "Save File" then
		while not ret do
			term.setCursorPos(1, 15)
			rightWrite(string.rep(" ", 36))
			term.setCursorPos(w - 34, 15)
			write("Path: /")
			local p = read()

			term.setCursorPos(1, 15)
			rightWrite(string.rep(" ", 36))
			if p == "" then
				rightWrite("Cancelled ")
				break
			elseif fs.exists("/" .. p) then
				rightWrite("File Already Exists! ")
			else
				rightWrite("File Saved! ")
				ret = "/" .. p
				local f = env.io.open(ret, "w")
				f:write(content)
				f:close()
			end

			openAddressBar = false
			sleep(1.3)
			openAddressBar = true
		end
	elseif opt == "Cancel" then
		term.setCursorPos(1, 15)
		rightWrite("Saving Cancelled! ")
	end

	openAddressBar = false
	sleep(1.3)
	openAddressBar = true

	term.setBackgroundColor(oldback or colors.black)
	term.setTextColor(oldtext or colors.white)
	term.clear()
	term.setCursorPos(ox, oy)
	return ret
end

api.urlDownload = function(url)
	if type(url) ~= "string" then error("expected string", 2) end
	local source = nil
	http.request(url)
	local a = os.startTimer(10)
	while true do
		local e, surl, handle = os.pullEvent()
		if e == "http_success" then
			source = handle.readAll()
			break
		elseif e == "http_failure" or (e == "timer" and surl == a) then
			break
		end
	end

	if type(source) == "string" then
		return api.saveFileToUserComputer(source)
	else return nil end
end

api.pastebinDownload = function(code)
	return api.urlDownload("http://pastebin.com/raw.php?i=" .. tostring(code))
end


--  Redirection

api.redirect = function(url)
	if type(url) ~= "string" then url = "home" end
	os.queueEvent(event_redirect, url:gsub("rdnt://"):gsub("http://"))
	error()
end


--  Theme

api.themeColor = function(tag)
	if type(tag) ~= "string" then error("themeColor: expected string") end
	return colors[theme[tag] or defaultTheme[tag] or "white"]
end

api.themeColour = function(tag) return api.themeColor(tag) end


--  Prompt

api.prompt = function(list, dir)
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
					if x >= v[2] and x <= v[2] + v[1]:len() + 5 and y + (v.coffset or 0) == v[3] then
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

		local key1 = dir == "horizontal" and 203 or 200
		local key2 = dir == "horizontal" and 205 or 208

		local curSel = 1
		term.setCursorPos(list[curSel][2], list[curSel][3])
		write("[")
		term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
		write("]")
		while true do
			local e, key = os.pullEvent("key")
			term.setCursorPos(list[curSel][2], list[curSel][3])
			write(" ")
			term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
			write(" ")
			if key == key1 and curSel > 1 then curSel = curSel - 1
			elseif key == key2 and curSel < #list then curSel = curSel + 1
			elseif key == 28 then return list[curSel][1] end
			term.setCursorPos(list[curSel][2], list[curSel][3])
			write("[")
			term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
			write("]")
		end
	end
end

api.scrollingPrompt = function(list, x, y, len, width, coffset)
	local wid = width
	if not wid then wid = w - 3 end

	local function updateDisplayList(items, loc, len)
		local ret = {}
		for i = 1, len do
			local item = items[i + loc - 1]
			if item then table.insert(ret, item) end
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
					if clx >= x and clx <= x + wid and cly + coffset == i + y - 1 then return v end
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
				if curSel > 1 then curSel = curSel - 1
				elseif loc > 1 then
					loc = loc - 1
					disList = updateDisplayList(list, loc, len)
					draw(disList)
				end
			elseif e == "key" and key == 208 then
				if curSel < #disList then curSel = curSel + 1
				elseif loc + len - 1 < #list then
					loc = loc + 1
					disList = updateDisplayList(list, loc, len)
					draw(disList)
				end
			elseif e == "key" and key == 28 then return list[curSel + loc - 1] end
			term.setCursorPos(x + 1, y + curSel - 1)
			write("x")
		end
	end
end

-- Set Environment
for k, v in pairs(getfenv(0)) do env[k] = v end
for k, v in pairs(getfenv(1)) do env[k] = v end
for k, v in pairs(env) do oldEnv[k] = v end
for k, v in pairs(api) do env[k] = v end


--  -------- Override

for k, v in pairs(env) do override[k] = v end
local curtext, curbackground = colors.white, colors.black
override.term = {}
for k, v in pairs(env.term) do override.term[k] = v end
override.os = {}
for k, v in pairs(env.os) do override.os[k] = v end

override.term.getSize = function()
	local a, b = env.term.getSize()
	return a, b - 2
end

override.term.setCursorPos = function(x, y)
	if y < 1 then return env.term.setCursorPos(x, 2)
	else return env.term.setCursorPos(x, y + 1) end
end

override.term.getCursorPos = function()
	local x, y = env.term.getCursorPos()
	return x, y - 1
end

override.term.getBackgroundColor = function() return curbackground end
override.term.getBackgroundColour = function() return override.term.getBackgroundColor() end

override.term.setBackgroundColor = function(col)
	curbackground = col
	return env.term.setBackgroundColor(col)
end

override.term.setBackgroundColour = function(col) return override.term.setBackgroundColor(col) end

override.term.getTextColor = function() return curtext end
override.term.getTextColour = function() return override.term.getTextColor() end

override.term.setTextColor = function(col)
	curtext = col
	return env.term.setTextColor(col)
end

override.term.setTextColour = function(col) return override.term.setTextColor(col) end

override.term.clear = function()
	local x, y = term.getCursorPos()
	local oldbackground = override.term.getBackgroundColor()
	local oldtext = override.term.getTextColor()
	clear(website, curbackground)

	term.setBackgroundColor(oldbackground)
	term.setTextColor(oldtext)
	term.setCursorPos(x, y)
end

override.term.scroll = function(n)
	local x, y = term.getCursorPos()
	local oldbackground = override.term.getBackgroundColor()
	local oldtext = override.term.getTextColor()

	env.term.scroll(n)
	clear(website, curbackground, true)
	term.setBackgroundColor(oldbackground)
	term.setTextColor(oldtext)
	term.setCursorPos(x, y)
end

override.term.isColor = function() return isAdvanced() end
override.term.isColour = function() return override.term.isColor() end

override.os.queueEvent = function(event, ...)
	if event == "terminate" or event == event_exit then return end
	if event == event_error and not websiteerror then return end
	env.os.queueEvent(event, ...)
end

override.prompt = function(list, dir)
	local a = {}
	for k, v in pairs(list) do
		table.insert(a, {v[1], v[2], v[3] + 1, tc = v.tc or curtext,
			bg = v.bg or curbackground, coffset = 1})
	end
	return env.prompt(a, dir)
end

override.scrollingPrompt = function(list, x, y, len, width)
	return env.scrollingPrompt(list, x, y + 1, len, width, 1)
end

local barTerm = {}
for k, v in pairs(override.term) do barTerm[k] = v end
barTerm.clear = override.term.clear
barTerm.scroll = override.term.scroll

local safeTerm = {}
for k, v in pairs(term) do safeTerm[k] = v end

override.showBar = function()
	offsetclick, clickableAddressBar = true, true
	return os.pullEvent, barTerm
end

override.hideBar = function()
	offsetclick, clickableAddressBar = false, false
	return os.pullEvent, safeTerm
end

setfenv(api.saveFileToUserComputer, override)


--  -------- Antivirus

local antivirusOverrides = {
	["Run Files"] = {"shell.run", "os.run"},
	["Modify System"] = {"shell.setAlias", "shell.clearAlias", "os.setComputerLabel", 
		"shell.setDir", "shell.setPath"},
	["Modify Files"] = {"fs.makeDir", "fs.move", "fs.copy", "fs.delete", "fs.open",
		"io.open", "io.write", "io.read", "io.close"},
	["Shutdown Computer"] = {"os.shutdown", "os.reboot", "shell.exit"}
}

local antivirusDestroy = {
	"rawset", "rawget", "setfenv", "loadfile", "loadstring", "dofile", "getfenv"
}

local function triggerAntivirus(offence, onlyCancel)
	local oldback, oldtext = curbackground, curtext
	local ox, oy = term.getCursorPos()
	openAddressBar = false
	term.setBackgroundColor(colors[theme["address-bar-background"]])
	term.setTextColor(colors[theme["address-bar-text"]])
	term.setCursorPos(2, 1)
	term.clearLine()
	write("Request: " .. offence)
	term.setCursorPos(w - 8, 1)
	write("[C]ancel")
	if not onlyCancel then
		term.setCursorPos(w - 16, 1)
		write("[A]llow")
	end

	offsetclick = false
	local stat = ""
	while true do
		local e, but, x, y = env.os.pullEvent()
		if e == "mouse_click" and y == 1 then
			if x >= w - 8 and x <= w - 1 then stat = "cancel"
			elseif not onlyCancel and x >= w - 16 and x <= w - 9 then stat = "allow" end
		elseif e == "char" and but == "c" then stat = "cancel"
		elseif e == "char" and not onlyCancel and but == "a" then stat = "allow" end
		if stat ~= "" then break end
	end
	offsetclick = true

	clear(website, nil, true)
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(ox, oy)
	term.setBackgroundColor(oldback)
	term.setTextColor(oldtext)
	if not onlyCancel and stat == "allow" then
		-- To prevent the menu bar from opening
		os.queueEvent("firewolf_requiredEvent")
		os.pullEvent()

		openAddressBar = true
		return true
	elseif stat == "cancel" then
		openAddressBar = true
		redirect("home")
	end
end

for k, v in pairs(override) do antivirus[k] = v end

antivirus.shell = {}
for k, v in pairs(override.shell) do antivirus.shell[k] = v end
antivirus.os = {}
for k, v in pairs(override.os) do antivirus.os[k] = v end
antivirus.fs = {}
for k, v in pairs(override.fs) do antivirus.fs[k] = v end
antivirus.io = {}
for k, v in pairs(override.io) do antivirus.io[k] = v end

for warning, v in pairs(antivirusOverrides) do
	for k, func in pairs(v) do
		if func:find(".", 1, true) then
			-- Functions in another table
			local table = func:sub(1, func:find(".", 1, true) - 1)
			local funcname = func:sub(func:find(".", 1, true) + 1, -1)

			antivirus[table][funcname] = function(...)
				env.setfenv(triggerAntivirus, env)
				if triggerAntivirus(warning) then
					return override[table][funcname](...)
				end
			end
		else
			-- Plain functions
			antivirus[func] = function(...)
				env.setfenv(triggerAntivirus, env)
				if triggerAntivirus(warning) then
					return override[func](...)
				end
			end
		end
	end
end

for k, v in pairs(antivirusDestroy) do
	antivirus[v] = function(...)
		env.setfenv(triggerAntivirus, env)
		triggerAntivirus("Destory your System! D:", true)
		return nil
	end
end

antivirus.pcall = function(...)
	local suc, err = env.pcall(...)
	if err:lower():find("terminate") then error("terminate") end
	return suc, err
end


--  -------- Themes

local defaultTheme = {
	["address-bar-text"] = "white",
	["address-bar-background"] = "gray",
	["address-bar-base"] = "lightGray",
	["top-box"] = "red",
	["bottom-box"] = "orange",
	["text-color"] = "white",
	["background"] = "gray"
} local originalTheme = {
	["address-bar-text"] = "white",
	["address-bar-background"] = "black",
	["address-bar-base"] = "black",
	["top-box"] = "black",
	["bottom-box"] = "black",
	["text-color"] = "white",
	["background"] = "black"
}

local function loadTheme(path)
	if fs.exists(path) and not fs.isDir(path) then
		local a = {}
		local f = io.open(path, "r")
		local l = f:read("*l")
		while l do
			l = l:gsub("^%s*(.-)%s*$", "%1")
			if l and l ~= "" and l ~= "\n" and l:sub(1, 2) ~= "--" then
				local k, v = string.match(l, "^(%a+)=(%a+)")
				if k and v then a[k] = v
				else return nil end
			end
			l = f:read("*l")
		end
		f:close()
		return a
	end
	return nil
end


--  -------- Filesystem

local function download(url, path)
	for i = 1, 3 do
		local response = http.get(url)
		if response then
			local data = response.readAll()
			response.close()
			if path then
				local f = io.open(path, "w")
				f:write(data)
				f:close()
			end
			return true
		end
	end

	return false
end

local function updateClient()
	local skipNormal = false
	if serverID ~= "experimental" then
		http.request(buildURL)
		local a = os.startTimer(10)
		while true do
			local e, url, handle = os.pullEvent()
			if e == "http_success" then
				local b = handle.readAll():gsub("^%s*(.-)%s*$", "%1")
				if not tonumber(b) or tonumber(b) > build then break
				else return false end
			elseif e == "http_failure" or (e == "timer" and url == a) then
				skipNormal = true
				break
			end
		end
	end

	local source = nil
	if not skipNormal then
		local _, y = term.getCursorPos()
		term.setCursorPos(1, y - 2)
		rightWrite(string.rep(" ", 32))
		rightWrite("Updating Firewolf... ")

		http.request(firewolfURL)
		local a = os.startTimer(10)
		while true do
			local e, url, handle = os.pullEvent()
			if e == "http_success" then
				source = handle
				break
			elseif e == "http_failure" or (e == "timer" and url == a) then
				break
			end
		end
	end

	if not source then
		if isAdvanced() then
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["background"]])
			term.clear()
			if not fs.exists(rootFolder) then fs.makeDir(rootFolder) end
			local f = io.open(rootFolder .. "/temp_file", "w")
			f:write(graphics.githubImage)
			f:close()
			local a = paintutils.loadImage(rootFolder .. "/temp_file")
			paintutils.drawImage(a, 5, 5)
			sleep(0.2)
			fs.delete(rootFolder .. "/temp_file")

			term.setCursorPos(19, 4)
			term.setBackgroundColor(colors[theme["top-box"]])
			write(string.rep(" ", 32))
			term.setCursorPos(19, 5)
			write("  Could Not Connect to GitHub!  ")
			term.setCursorPos(19, 6)
			write(string.rep(" ", 32))
			term.setBackgroundColor(colors[theme["bottom-box"]])
			term.setCursorPos(19, 8)
			write(string.rep(" ", 32))
			term.setCursorPos(19, 9)
			write("    Sorry, Firewolf could not   ")
			term.setCursorPos(19, 10)
			write(" connect to GitHub to download  ")
			term.setCursorPos(19, 11)
			write(" necessary files. Please check: ")
			term.setCursorPos(19, 12)
			write("    http://status.github.com    ")
			term.setCursorPos(19, 13)
			write(string.rep(" ", 32))
			term.setCursorPos(19, 14)
			write("        Click to exit...        ")
			term.setCursorPos(19, 15)
			write(string.rep(" ", 32))
		else
			term.clear()
			term.setCursorPos(1, 1)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			print("\n")
			centerPrint("Could not connect to GitHub!")
			print("")
			centerPrint("Sorry, Firewolf could not connect to")
			centerPrint("GitHub to download necessary files.")
			centerPrint("Please check:")
			centerPrint("http://status.github.com")
			print("")
			centerPrint("Press any key to exit...")
		end

		while true do
			local e = os.pullEvent()
			if e == "mouse_click" or e == "key" then break end
		end

		return false
	elseif source and autoupdate == "true" then
		local b = io.open(firewolfLocation, "r")
		local new = source.readAll()
		local cur = b:read("*a")
		source.close()
		b:close()

		if cur ~= new then
			fs.delete(firewolfLocation)
			local f = io.open(firewolfLocation, "w")
			f:write(new)
			f:close()
			return true
		else
			return false
		end
	end
end

local function resetFilesystem()
	-- Migrate
	fs.delete(rootFolder .. "/available_themes")
	fs.delete(rootFolder .. "/default_theme")

	-- Reset
	if not fs.exists(rootFolder) then fs.makeDir(rootFolder)
	elseif not fs.isDir(rootFolder) then fs.move(rootFolder, "/Firewolf_Data.old") end

	for _, v in pairs({serverFolder, cacheFolder, websiteDataFolder}) do
		if not fs.isDir(v) then fs.delete(v) end
		if not fs.exists(v) then fs.makeDir(v) end
	end

	if fs.isDir(settingsLocation) then fs.delete(settingsLocation) end
	if fs.isDir(serverLocation) then fs.delete(serverLocation) end

	if not fs.exists(settingsLocation) then
		local f = io.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = "true", incog = "false", home = "firewolf"}))
		f:close()
	end

	if not fs.exists(serverLocation) then download(serverURL, serverLocation) end
	fs.delete(rootFolder .. "/temp_file")

	for _, v in pairs({userWhitelist, userBlacklist}) do
		if fs.isDir(v) then fs.delete(v) end
		if not fs.exists(v) then
			local f = io.open(v, "w")
			f:write("")
			f:close()
		end
	end
end

local function checkForModem(display)
	while true do
		local present = false
		for _, v in pairs(rs.getSides()) do
			if peripheral.getType(v) == "modem" then rednet.open(v) present = true break end
		end

		if not present and type(display) == "function" then display() os.pullEvent("peripheral")
		else return true end
	end
end


--  -------- Databases

local function loadDatabases()
	if fs.exists(userBlacklist) and not fs.isDir(userBlacklist) then
		local bf = io.open(userBlacklist, "r")
		local l = bf:read("*l")
		while l do
			if l and l ~= "" and l ~= "\n" then
				l = l:gsub("^%s*(.-)%s*$", "%1")
				table.insert(blacklist, l)
			end
			l = bf:read("*l")
		end
		bf:close()
	end

	if fs.exists(userWhitelist) and not fs.isDir(userWhitelist) then
		local wf = io.open(userWhitelist, "r")
		local l = wf:read("*l")
		while l do
			if l and l ~= "" and l ~= "\n" then
				l = l:gsub("^%s*(.-)%s*$", "%1")
				local a, b = l:find("| |")
				table.insert(whitelist, {l:sub(1, a - 1), l:sub(b + 1, -1)})
			end
			l = wf:read("*l")
		end
		wf:close()
	end
end

local function verifyBlacklist(id)
	for _, v in pairs(blacklist) do if tostring(id) == v then return true end end
	return false
end

local function verifyWhitelist(id, url)
	for _, v in pairs(whitelist) do
		if v[2] == tostring(id) and v[1] == tostring(url) then return true end
	end
	return false
end


--  -------- Graphics and Files

graphics.githubImage = [[
f       f
fffffffff
fffffffff
f4244424f
f4444444f
fffffefffe
   fffe e
 fffff e
ff f fe e
     e   e
]]

graphics.nomodem = function()
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setCursorPos(1, 1)
	print("\n")
	term.setBackgroundColor(colors[theme["top-box"]])
	api.leftPrint(string.rep(" ", 24))
	api.leftPrint(" No Modem Attached! D:  ")
	api.leftPrint(string.rep(" ", 24))
	print("\n")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	api.rightPrint(string.rep(" ", 40))
	api.rightPrint("    No wireless modem was found on this ")
	api.rightPrint("  computer, and Firewolf cannot use the ")
	api.rightPrint("             RDNT protocol without one! ")
	api.rightPrint(string.rep(" ", 40))
	api.rightPrint("  Waiting for a modem to be attached... ")
	api.rightPrint(string.rep(" ", 40))
end

graphics.nonexistantwebpage = function()
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setCursorPos(1, 2)
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	leftPrint(string.rep(" ", 11))
	leftPrint(" Oh Noes!  ")
	leftPrint(string.rep(" ", 11))
	print("\n")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	rightPrint(string.rep(" ", 43))
	rightPrint([[       ______                          __  ]])
	rightPrint([[      / ____/_____ _____ ____   _____ / /  ]])
	rightPrint([[     / __/  / ___// ___// __ \ / ___// /   ]])
	rightPrint([[    / /___ / /   / /   / /_/ // /   /_/    ]])
	rightPrint([[   /_____//_/   /_/    \____//_/   (_)     ]])
	rightPrint(string.rep(" ", 43))
	rightPrint("  Could not connect to the website! It may ")
	rightPrint("  be down, or not exist!                   ")
	rightPrint(string.rep(" ", 43))
end

graphics.nosearchresults = function()
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setCursorPos(1, 5)
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 40))
	centerPrint("  No Websites are Currently Online! D:  ")
	centerPrint(string.rep(" ", 40))
	centerPrint("       Why not make one yourself?       ")
	centerPrint("          Visit rdnt://server!          ")
	centerPrint(string.rep(" ", 40))
end

files.availableThemes = [[
https://raw.github.com/1lann/firewolf/master/themes/default.txt| |Fire (default)
https://raw.github.com/1lann/firewolf/master/themes/ice.txt| |Ice
https://raw.github.com/1lann/firewolf/master/themes/carbon.txt| |Carbon
https://raw.github.com/1lann/firewolf/master/themes/christmas.txt| |Christmas
https://raw.github.com/1lann/firewolf/master/themes/original.txt| |Original
https://raw.github.com/1lann/firewolf/master/themes/ocean.txt| |Ocean
https://raw.github.com/1lann/firewolf/master/themes/forest.txt| |Forest
https://raw.github.com/1lann/firewolf/master/themes/pinky.txt| |Pinky
https://raw.github.com/1lann/firewolf/master/themes/azhftech.txt| |AzhfTech
]]

files.newTheme = [[
-- Address bar text color
address-bar-text=

-- Address bar background color
address-bar-background=

-- Color of separator bar on live search dropdown
address-bar-base=

-- Top box background color
top-box=

-- Bottom box background color
bottom-box=

-- Main background color
background=

-- Main text color
text-color=

]]


--  -------- Protocols

protocols.rdnt = {}
protocols.http = {}

protocols.rdnt.getSearchResults = function()
	dnsDatabase = {[1] = {}, [2] = {}}
	local resultIDs = {}
	local conflict = {}

	rednet.broadcast("firewolf.broadcast.dns.list")
	local startClock = os.clock()
	while os.clock() - startClock < timeout do
		local id, i = rednet.receive(timeout)
		if id then
			if i:sub(1, 14) == "firewolf-site:" then
				i = i:sub(15, -1)
				local bl, wl = verifyBlacklist(id), verifyWhitelist(id, i)
				if not i:find(" ") and i:len() < 40 and (not bl or (bl and wl)) then
					if not resultIDs[tostring(id)] then resultIDs[tostring(id)] = 1
					else resultIDs[tostring(id)] = resultIDs[tostring(id)] + 1 end
					
					if not i:find("rdnt://") then i = ("rdnt://" .. i) end
					local x = false
					if conflict[i] then
						x = true
						table.insert(conflict[i], id)
					else
						for m, n in pairs(dnsDatabase[1]) do
							if n:lower() == i:lower() then
								x = true
								table.remove(dnsDatabase[1], m)
								table.remove(dnsDatabase[2], m)
								if conflict[i] then table.insert(conflict[i], id)
								else conflict[i] = {} table.insert(conflict[i], id) end
								break
							end
						end
					end

					if not x and resultIDs[tostring(id)] <= 3 then
						table.insert(dnsDatabase[1], i)
						table.insert(dnsDatabase[2], id)
					end
				end
			end
		else break end
	end

	for k, v in pairs(conflict) do
		table.sort(v)
		table.insert(dnsDatabase[1], k)
		table.insert(dnsDatabase[2], v[1])
	end
end

protocols.rdnt.getWebsite = function(site)
	local id, content, status = nil, nil, nil
	local clock = os.clock()
	local websiteID = nil
	for k, v in pairs(dnsDatabase[1]) do
		local web = site:gsub("rdnt://", "")
		if web:find("/") then web = web:sub(1, web:find("/") - 1) end
		if web == v:gsub("rdnt://", "") then websiteID = dnsDatabase[2][k] break end
	end
	if not websiteID then return nil, nil, nil end

	sleep(timeout)
	rednet.send(websiteID, site)
	clock = os.clock()
	while os.clock() - clock < timeout do
		id, content = rednet.receive(timeout)
		if id and id == websiteID then
			local bl, wl = verifyBlacklist(id), verifyWhitelist(id, site)
			status = nil
			if (bl and not wl) or site == "" or site == "." or site == ".." then
				-- Ignore
			elseif wl then status = "whitelist" break
			else status = "safe" break end
		end
	end

	return id, content, status
end

protocols.http.getSearchResults = function()
	dnsDatabase = {[1] = {}, [2] = {}}
end

protocols.http.getWebsite = function(site)
	return nil, nil, nil
end


--  -------- Homepage

pages["firewolf"] = function()
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	leftPrint(string.rep(" ", 42))
	leftPrint([[        _,-='"-.__               /\_/\    ]])
	leftPrint([[         -.}        =._,.-==-._.,  @ @._, ]])
	leftPrint([[            -.__  __,-.   )       _,.-'   ]])
	leftPrint([[ Firewolf ]] .. version .. string.rep(" ", 8 - version:len()) ..
		[["    G..m-"^m m'        ]])
	leftPrint(string.rep(" ", 42))
	print("\n")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	rightPrint(string.rep(" ", 42))
	if isAdvanced() then rightPrint("  News:                       [- Sites -] ")
	else rightPrint("  News:                                   ") end
	rightPrint("     Firewolf 2.5 is out! It rewrites the ")
	rightPrint("    whole Firewolf's internals (again :P) ")
	rightPrint(string.rep(" ", 42))
	rightPrint("   Firewolf 3.0 will be out soon! It will ")
	rightPrint("     bring the long awaited HTTP support! ")
	rightPrint(string.rep(" ", 42))

	while true do
		local e, but, x, y = os.pullEvent()
		if e == "mouse_click" and x >= 40 and x <= 50 and y == 11 then redirect("sites") end
	end
end

pages["sites"] = function()
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("\n")
	leftPrint(string.rep(" ", 17))
	leftPrint(" Built-In Sites  ")
	leftPrint(string.rep(" ", 17))

	local sx = 8
	term.setBackgroundColor(colors[theme["bottom-box"]])
	term.setCursorPos(1, sx)
	rightPrint(string.rep(" ", 40))
	rightPrint("  rdnt://firewolf              Homepage ")
	rightPrint("  rdnt://sites                    Sites ")
	rightPrint("  rdnt://server       Server Management ")
	rightPrint("  rdnt://help                 Help Page ")
	rightPrint("  rdnt://settings              Settings ")
	rightPrint("  rdnt://credits                Credits ")
	rightPrint("  rdnt://exit                      Exit ")
	rightPrint(string.rep(" ", 40))

	local a = {"firewolf", "sites", "server", "help", "settings", "credits", "exit"}
	while true do
		local e, but, x, y = os.pullEvent()
		if e == "mouse_click" and x >= 14 and x <= 50 then
			for i, v in ipairs(a) do if y == sx + i and v ~= "exit" then redirect(v) end end
		end
	end
end


--  -------- Server Management

local function manageServers(site, protocol, functionList, startServerName)
	local servers = functionList["reload servers"]()
	local sy = 7

	if not startServerName then startServerName = "Start" end
	if isAdvanced() then
		local function draw(l, sel)
			term.setBackgroundColor(colors[theme["bottom-box"]])
			term.setCursorPos(4, sy)
			write("[- New Server -]")
			for i, v in ipairs(l) do
				term.setCursorPos(3, i + sy)
				write(string.rep(" ", 24))
				term.setCursorPos(4, i + sy)
				local nv = v
				if nv:len() > 18 then nv = nv:sub(1, 15) .. "..." end
				if i == sel then write("[ " .. nv .. " ]")
				else write("  " .. nv) end
			end

			if #l < 1 then
				term.setCursorPos(4, sy + 2)
				write("A website is literally")
				term.setCursorPos(4, sy + 3)
				write("just a lua script!")
				term.setCursorPos(4, sy + 4)
				write("Go ahead and make one!")
				term.setCursorPos(4, sy + 6)
				write("Also, be sure to check")
				term.setCursorPos(4, sy + 7)
				write("out Firewolf's APIs to")
				term.setCursorPos(4, sy + 8)
				write("help you make your")
				term.setCursorPos(4, sy + 9)
				write("site, at rdnt://help")
			end

			term.setCursorPos(30, sy)
			write(string.rep(" ", 19))
			term.setCursorPos(30, sy)
			if l[sel] then
				local nl = l[sel]
				if nl:len() > 19 then nl = nl:sub(1, 16) .. "..." end
				write(nl)
			else write("No Server Selected!") end
			term.setCursorPos(30, sy + 2)
			write("[- " .. startServerName .. " -]")
			term.setCursorPos(30, sy + 4)
			write("[- Edit -]")
			term.setCursorPos(30, sy + 6)
			if functionList["run on boot"] then write("[- Run on Boot -]") end
			term.setCursorPos(30, sy + 8)
			write("[- Delete -]")
		end

		local function updateDisplayList(items, loc, len)
			local ret = {}
			for i = 1, len do
				if items[i + loc - 1] then table.insert(ret, items[i + loc - 1]) end
			end
			return ret
		end

		while true do
			term.setBackgroundColor(colors[theme["background"]])
			term.clear()
			term.setCursorPos(1, 1)
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			leftPrint(string.rep(" ", 27))
			leftPrint(" Server Management - " .. protocol:upper() .. "  ")
			leftPrint(string.rep(" ", 27))
			print("")

			term.setBackgroundColor(colors[theme["bottom-box"]])
			for i = 1, 12 do
				term.setCursorPos(3, i + sy - 2)
				write(string.rep(" ", 24))
				term.setCursorPos(29, i + sy - 2)
				write(string.rep(" ", 21))
			end

			local sel, loc, len = 1, 1, 10
			local disList = updateDisplayList(servers, loc, len)
			draw(disList, sel)

			while true do
				local e, but, x, y = os.pullEvent()
				if e == "key" and but == 200 and #servers > 0 and loc > 1 then
					loc = loc - 1
					disList = updateDisplayList(servers, loc, len)
					draw(disList, sel)
				elseif e == "key" and but == 208 and #servers > 0 and loc + len - 1 < #servers then
					loc = loc + 1
					disList = updateDisplayList(servers, loc, len)
					draw(disList, sel)
				elseif e == "mouse_click" then
					if x >= 4 and x <= 25 then
						if y == 7 then
							functionList["new server"]()
							servers = functionList["reload servers"]()
							break
						elseif #servers > 0 then
							for i, v in ipairs(disList) do
								if y == i + 7 then
									sel = i
									draw(disList, sel)
								end
							end
						end
					elseif x >= 30 and x <= 40 and y == 9 and #servers > 0 then
						functionList["start"](disList[sel])
						servers = functionList["reload servers"]()
						break
					elseif x >= 30 and x <= 39 and y == 11 and #servers > 0 then
						functionList["edit"](disList[sel])
						servers = functionList["reload servers"]()
						break
					elseif x >= 30 and x <= 46 and y == 13 and #servers > 0 and
							functionList["run on boot"] then
						functionList["run on boot"](disList[sel])
						term.setBackgroundColor(colors[theme["bottom-box"]])
						term.setCursorPos(32, 15)
						write("Will Run on Boot!")
						openAddressBar = false
						sleep(1.3)
						openAddressBar = true
						term.setCursorPos(32, 15)
						write(string.rep(" ", 18))
						break
					elseif x >= 30 and x <= 41 and y == 15 and #servers > 0 then
						functionList["delete"](disList[sel])
						servers = functionList["reload servers"]()
						break
					end
				end
			end
		end
	else
		while true do
			term.setBackgroundColor(colors[theme["background"]])
			term.clear()
			term.setCursorPos(1, 1)
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 27))
			centerPrint(" Server Management - " .. protocol:upper() .. "  ")
			centerPrint(string.rep(" ", 27))
			print("")

			local a = {"New Server"}
			for _, v in pairs(servers) do table.insert(a, v) end
			local server = scrollingPrompt(a, 4, 7, 10)
			if server == "New Server" then
				functionList["new server"]()
				servers = functionList["reload servers"]()
			else
				term.setCursorPos(30, 8)
				write(server)
				local a = {{"Start", 30, 9}, {"Edit", 30, 11}, {"Run on Boot", 30, 12},
					{"Delete", 30, 13}, {"Back", 30, 15}}
				if not functionList["run on boot"] then
					a = {{"Start", 30, 9}, {"Edit", 30, 11}, {"Delete", 30, 13}, {"Back", 30, 15}}
				end
				local opt = prompt(a, "vertical")
				if opt == "Start" then
					functionList["start"](server)
					servers = functionList["reload servers"]()
				elseif opt == "Edit" then
					functionList["edit"](server)
					servers = functionList["reload servers"](server)
				elseif opt == "Run on Boot" and functionList["run on boot"] then
					functionList["run on boot"](server)
					term.setCursorPos(32, 16)
					write("Will Run on Boot!")
					openAddressBar = false
					sleep(1.3)
					openAddressBar = true
				elseif opt == "Delete" then
					functionList["delete"](server)
					servers = functionList["reload servers"]()
				end
			end
		end
	end
end

local function editPages(dir)
	local oldLoc = shell.dir()
	local commandHis = {}
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)
	print("")
	print(" Server Shell Editing")
	print(" Type 'exit' to return to Firewolf.")
	print(" The 'home' file is the index of your site.")
	print("")

	local allowed = {"move", "mv", "cp", "copy", "drive", "delete", "rm", "edit",
		"eject", "exit", "help", "id", "monitor", "rename", "alias", "clear",
		"paint", "lua", "redstone", "rs", "redprobe", "redpulse", "programs",
		"redset", "reboot", "hello", "label", "list", "ls", "easter", "pastebin", "dir"}
	
	while true do
		shell.setDir(dir)
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
		if com == "exit" then break
		elseif com then
			local a = false
			for _, v in pairs(allowed) do if com == v then a = true break end end

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

local function newServer(onCreate)
	term.setBackgroundColor(colors[theme["background"]])
	for i = 1, 12 do
		term.setCursorPos(3, i + 5)
		term.clearLine()
	end

	term.setBackgroundColor(colors[theme["bottom-box"]])
	term.setCursorPos(1, 7)
	for i = 1, 8 do centerPrint(string.rep(" ", 47)) end
	term.setCursorPos(5, 8)
	write("Name: ")
	local name = modRead({refusePrint = "`", visibleLength = w - 4, textLength = 200})
	term.setCursorPos(5, 10)
	write("URL:")
	term.setCursorPos(8, 11)
	write("rdnt://")
	local url = modRead({grantPrint = "abcdefghijklmnopqrstuvwxyz1234567890-_.+",
		visibleLength = w - 4, textLength = 200})
	url = url:gsub(" ", "")
	if name == "" or url == "" then
		term.setCursorPos(5, 13)
		write("URL or Name is Empty!")
		openAddressBar = false
		sleep(1.3)
		openAddressBar = true
	else
		local c = onCreate(name, url)

		term.setCursorPos(5, 13)
		if c and c == "true" then write("Successfully Created Server!")
		elseif c == "false" or not c then write("Server Creation Failed!")
		else write(c) end
		openAddressBar = false
		sleep(1.3)
		openAddressBar = true
	end
end

pages["server/rdnt"] = function(site)
	manageServers(site, "rdnt", {["reload servers"] = function()
		local servers = {}
		for _, v in pairs(fs.list(serverFolder)) do
			if fs.isDir(serverFolder .. "/" .. v) then table.insert(servers, v) end
		end
		return servers
	end, ["new server"] = function()
		newServer(function(name, url)
			if fs.exists(serverFolder .. "/" .. url) then return "Server Already Exists!" end
			fs.makeDir(serverFolder .. "/" .. url)
			local f = io.open(serverFolder .. "/" .. url .. "/home", "w")
			f:write("print(\"\")\ncenterPrint(\"Welcome To " .. name .. "!\")\n\n")
			f:close()
			return "true"
		end)
	end, ["start"] = function(server)
		term.clear()
		term.setCursorPos(1, 1)
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		openAddressBar, offsetclick = false, false
		setfenv(1, oldEnv)
		shell.run(serverLocation, server, serverFolder .. "/" .. server)
		setfenv(1, override)
		openAddressBar, offsetclick = true, true
		checkForModem()
	end, ["edit"] = function(server)
		openAddressBar, offsetclick = false, false
		editPages(serverFolder .. "/" .. server)
		openAddressBar, offsetclick = true, true
		if not fs.exists(serverFolder .. "/" .. server .. "/home") then
			local f = io.open(serverFolder .. "/" .. server .. "/home", "w")
			f:write("print(\"\")\ncenterPrint(\"Welcome To " .. server .. "!\")\n\n")
			f:close()
		end
	end, ["run on boot"] = function(server)
		fs.delete("/old-startup")
		if fs.exists("/startup") then fs.move("/startup", "/old-startup") end
		local f = io.open("/startup", "w")
		f:write("shell.run(\"" .. serverLocation .. "\", \"" .. server .. "\", \"" ..
			serverFolder .. "/" .. server .. "\")")
		f:close()
	end, ["delete"] = function(server)
		fs.delete(serverFolder .. "/" .. server)
	end})
end

pages["server/http"] = function()
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	print("\n\n")
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 17))
	centerPrint("  Comming Soon!  ")
	centerPrint(string.rep(" ", 17))
end

pages["server"] = function()
	setfenv(manageServers, override)
	setfenv(newServer, override)
	setfenv(editPages, env)
	if curProtocol == protocols.rdnt then redirect("server/rdnt")
	elseif curProtocol == protocols.http then redirect("server/http") end
end


--  -------- Help

pages["help"] = function()
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	leftPrint(string.rep(" ", 16))
	leftPrint(" Firewolf Help  ")
	leftPrint(string.rep(" ", 16))
	print("\n")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 11 do rightPrint(string.rep(" ", 41)) end
	term.setCursorPos(1, 15)
	rightPrint("         View the full documentation at: ")
	rightPrint("  https://github.com/1lann/Firewolf/wiki ")

	local opt = prompt({{"Getting Started", w - 21, 8}, {"Making a Theme", w - 20, 10},
		{"API Documentation", w - 23, 12}}, "vertical")
	local pages = {}
	if opt == "Getting Started" then
		pages[1] = {title = "Getting Started - Intoduction", content = {
			"Hey there!",
			"",
			"Firewolf is an app that allows you to create",
			"and visit websites! Each site has an address",
			"(the URL) which you can type into the address",
			"bar above, and then visit the site.",
			"",
			"You can open the address bar by clicking on",
			"it, or by pressing control."
		}} pages[2] = {title = "Getting Started - Searching", content = {
			"The address bar can be also be used to",
			"search for sites, by simply typing in the",
			"search term.",
			"",
			"To view all sites, just open it and hit",
			"enter (leave the field blank)."
		}} pages[3] = {title = "Getting Started - Built-In Websites", content = {
			"Firewolf has a set of built-in websites",
			"available for use:",
			"",
			"rdnt://firewolf   Normal hompage",
			"rdnt://sites      Built-In Site",
			"rdnt://server     Create websites",
			"rdnt://help       Help and documentation"
		}} pages[4] = {title = "Getting Started - Built-In Websites", content = {
			"More built-in websites:",
			"",
			"rdnt://settings   Firewolf settings",
			"rdnt://credits    View the credits",
			"rdnt://exit       Exit the app"
		}}
	elseif opt == "Making a Theme" then
		pages[1] = {title = "Making a Theme - Introduction", content = {
			"Firewolf themes are files that tell Firewolf",
			"to color which things what.",
			"Several themes can already be downloaded for",
			"Firewolf from rdnt://settings/themes.",
			"",
			"You can also make your own theme, use it in",
			"your copy of Firewolf.Your theme can also be",
			"submitted it to the themes list!"
		}} pages[2] = {title = "Making a Theme - Example", content = {
			"A theme file consists of several lines of",
			"text. Here is the default theme file:",
			"address-bar-text=white",
			"address-bar-background=gray",
			"address-bar-base=lightGray",
			"top-box=red",
			"bottom-box=orange",
			"background=gray",
			"text-color=white"
		}} pages[3] = {title = "Making a Theme - Explanation", content = {
			"On each line of the example, something is",
			"given a color, like on the last line, the",
			"text of the page is told to be white.",
			"",
			"The color specified after the = is the same",
			"as when you call colors.[color name].",
			"For example, specifying 'red' after the =",
			"colors that object red."
		}} pages[4] = {title = "Making a Theme - Have a Go", content = {
			"Themes can be made at rdnt://settings/themes,",
			"click on 'Change Theme' button, and click on",
			"'New Theme'.",
			"",
			"Enter a theme name, then exit Firewolf and",
			"edit the newly created file",
			"Specify the colors for each of the keys,",
			"and return to the themes section of the",
			"downloads center. Click 'Load Theme'."
		}} pages[5] = {title = "Making a Theme - Submitting", content = {
			"To submit a theme to the theme list,",
			"send GravityScore a message on the CCForums",
			"that contains your theme file and name.",
			"",
			"He will message you back saying whether your",
			"theme has been added, or if anything needs to",
			"be changed before it is added."
		}}
	elseif opt == "API Documentation" then
		pages[1] = {title = "API Documentation - 1", content = {
			"The Firewolf API is a bunch of global",
			"functions that aim to simplify your life when",
			"designing and coding websites.",
			"",
			"For a full documentation on these functions,",
			"visit the Firewolf Wiki Page here:",
			"https://github.com/1lann/Firewolf/wiki"
		}} pages[2] = {title = "API Documentation - 2", content = {
			"centerPrint(string text)",
			"cPrint(string text)",
			"centerWrite(string text)",
			"cWrite(string text)",
			"",
			"leftPrint(string text)",
			"lPrint(string text)",
		}} pages[3] = {title = "API Documentation - 3", content = {
			"leftWrite(string text)",
			"lWrite(string text)",
			"",
			"rightPrint(string text)",
			"rPrint(string text)",
			"rightWrite(string text)",
			"rWrite(string text)"
		}} pages[4] = {title = "API Documentation - 4", content = {
			"prompt(table list, string direction)",
			"scrollingPrompt(table list, integer x,",
			"   integer y, integer length[,",
			"   integer width])",
			"",
			"urlDownload(string url)",
			"pastebinDownload(string code)",
			"redirect(string site)",
		}} pages[5] = {title = "API Documentation - 5", content = {
			"loadImageFromServer(string imagePath)",
			"ioReadFileFromServer(string filePath)",
			"fileFileFromServer(string filePath)",
			"saveFileToUserComputer(string content)",
			"",
			"writeDataFile(string path, string contents)",
			"readDataFile(string path)"
		}} pages[6] = {title = "API Documentation - 6", content = {
			"themeColor(string tag)",
			"themeColour(string tag)"
		}}
	end

	local function drawPage(page)
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 1)
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("")
		leftPrint(string.rep(" ", page.title:len() + 3))
		leftPrint(" " .. page.title .. "  ")
		leftPrint(string.rep(" ", page.title:len() + 3))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 12 do print(string.rep(" ", w)) end
		for i, v in ipairs(page.content) do
			term.setCursorPos(4, i + 6)
			write(v)
		end
	end

	local curPage = 1
	local a = {{"Prev", 26, 17}, {"Next", 38, 17}, {"Back",  14, 17}}
	drawPage(pages[curPage])
	while true do
		local b = {a[3]}
		if curPage == 1 then table.insert(b, a[2])
		elseif curPage == #pages then table.insert(b, a[1])
		else table.insert(b, a[1]) table.insert(b, a[2]) end

		local opt = prompt(b, "horizontal")
		if opt == "Prev" then curPage = curPage - 1
		elseif opt == "Next" then curPage = curPage + 1
		elseif opt == "Back" then break end
		drawPage(pages[curPage])
	end

	redirect("help")
end


--  -------- Settings

pages["settings/themes"] = function()
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	leftPrint(string.rep(" ", 17))
	leftPrint(" Theme Settings  ")
	leftPrint(string.rep(" ", 17))
	print("")

	if isAdvanced() then
		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 12 do rightPrint(string.rep(" ", 36)) end

		local themes = {}
		local themenames = {"Back", "New Theme", "Load Theme"}
		local f = io.open(rootFolder .. "/temp_file", "w")
		f:write(files.availableThemes)
		f:close()
		local f = io.open(rootFolder .. "/temp_file", "r")
		local l = f:read("*l")
		while l do
			l = l:gsub("^%s*(.-)%s*$", "%1")
			local a, b = l:find("| |")
			table.insert(themenames, l:sub(b + 1, -1))
			table.insert(themes, {name = l:sub(b + 1, -1), url = l:sub(1, a - 1)})
			l = f:read("*l")
		end
		f:close()
		fs.delete(rootFolder .. "/temp_file")

		local t = scrollingPrompt(themenames, w - 33, 7, 10, 32)
		if t == "Back" then redirect("settings")
		elseif t == "New Theme" then
			term.setCursorPos(w - 33, 17)
			write("Path: /")
			local n = modRead({visibleLength = w - 2, textLength = 100})
			if n ~= "" and n then
				n = "/" .. n
				local f = io.open(n, "w")
				f:write(files.newTheme)
				f:close()

				term.setCursorPos(1, 17)
				rightWrite(string.rep(" ", 36))
				term.setCursorPos(1, 17)
				rightWrite("File Created! ")
				openAddressBar = false
				sleep(1.1)
				openAddressBar = true
				redirect("settings/themes")
			end
		elseif t == "Load Theme" then
			term.setCursorPos(w - 33, 17)
			write("Path: /")
			local n = modRead({visibleLength = w - 2, textLength = 100})
			if n ~= "" and n then
				n = "/" .. n
				term.setCursorPos(1, 17)
				rightWrite(string.rep(" ", 36))
				
				term.setCursorPos(1, 17)
				if fs.exists(n) and not fs.isDir(n) then
					local a = loadTheme(n)
					if a then
						fs.delete(themeLocation)
						fs.copy(n, themeLocation)
						theme = a
						rightWrite("Theme File Loaded! :D ")
					else rightWrite("Theme File is Corrupt! D: ") end
				elseif not fs.exists(n) then rightWrite("File does not exist! ")
				elseif fs.isDir(n) then rightWrite("File is a directory! ") end

				openAddressBar = false
				sleep(1.1)
				openAddressBar = true
				redirect("settings/themes")
			end
		else
			local url = ""
			for _, v in pairs(themes) do if v.name == t then url = v.url break end end
			term.setBackgroundColor(colors[theme["top-box"]])
			term.setCursorPos(1, 3)
			leftWrite(string.rep(" ", 17))
			leftWrite(" Downloading...  ")

			fs.delete(rootFolder .. "/temp_file")
			download(url, rootFolder .. "/temp_file")
			local th = loadTheme(rootFolder .. "/temp_file")
			if not th then
				term.setCursorPos(1, 3)
				leftWrite(string.rep(" ", 17))
				leftWrite(" Theme Corrupt!  ")
				openAddressBar = false
				sleep(1.3)
				openAddressBar = true

				fs.delete(rootFolder .. "/temp_file")
				redirect("settings/themes")
			else
				term.setCursorPos(1, 3)
				leftWrite(string.rep(" ", 17))
				leftWrite(" Theme Loaded!   ")
				openAddressBar = false
				sleep(1.3)
				openAddressBar = true

				fs.delete(themeLocation)
				fs.move(rootFolder .. "/temp_file", themeLocation)
				theme = th
				redirect("home")
			end
		end
	else
		print("")
		rightPrint(string.rep(" ", 30))
		rightPrint("  Themes are not available on ")
		rightPrint("         normal computers! :( ")
		rightPrint(string.rep(" ", 30))
	end
end

pages["settings"] = function()
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	leftPrint(string.rep(" ", 17 + serverList[serverID]:len()))
	leftPrint(" Firewolf Settings  " .. string.rep(" ", serverList[serverID]:len() - 3))
	leftPrint(" Designed For: " .. serverList[serverID] .. "  ")
	leftPrint(string.rep(" ", 17 + serverList[serverID]:len()))
	print("\n")

	local a = "Automatic Updating - On"
	if autoupdate == "false" then a = "Automatic Updating - Off" end
	local b = "Home - rdnt://" .. homepage
	if b:len() >= 28 then b = b:sub(1, 24) .. "..." end

	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 9 do rightPrint(string.rep(" ", 36)) end
	local c = {{a, w - a:len() - 6, 9}, {"Change Theme", w - 18, 11}, {b, w - b:len() - 6, 13},
		{"Reset Firewolf", w - 20, 15}}
	if not isAdvanced() then
		c = {{a, w - a:len(), 9}, {b, w - b:len(), 11}, {"Reset Firewolf", w - 14, 13}}
	end

	local opt = prompt(c, "vertical")
	if opt == a then
		if autoupdate == "true" then autoupdate = "false"
		elseif autoupdate == "false" then autoupdate = "true" end
	elseif opt == "Change Theme" and isAdvanced() then
		redirect("settings/themes")
	elseif opt == b then
		if isAdvanced() then term.setCursorPos(w - 30, 14)
		else term.setCursorPos(w - 30, 12) end
		write("rdnt://")
		local a = read()
		if a ~= "" then homepage = a end
	elseif opt == "Reset Firewolf" then
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 1)
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("")
		leftPrint(string.rep(" ", 17))
		leftPrint(" Reset Firewolf  ")
		leftPrint(string.rep(" ", 17))
		print("\n")
		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 11 do rightPrint(string.rep(" ", 26)) end
		local opt = prompt({{"Reset History", w - 19, 8}, {"Reset Servers", w - 19, 9},
			{"Reset Theme", w - 17, 10}, {"Reset Cache", w - 17, 11}, 
			{"Reset Databases", w - 21, 12},
			{"Reset Settings", w - 20, 13}, {"Back", w - 10, 14}, {"Reset All", w - 15, 16}},
			"vertical")

		openAddressBar = false
		if opt == "Reset All" then
			fs.delete(rootFolder)
		elseif opt == "Reset History" then
			fs.delete(historyLocation)
		elseif opt == "Reset Servers" then
			fs.delete(serverFolder)
			fs.delete(serverLocation)
		elseif opt == "Reset Cache" then
			fs.delete(cacheFolder)
		elseif opt == "Reset Databases" then
			fs.delete(userWhitelist)
			fs.delete(userBlacklist)
		elseif opt == "Reset Settings" then
			fs.delete(settingsLocation)
		elseif opt == "Reset Theme" then
			fs.delete(themeLocation)
		elseif opt == "Back" then
			openAddressBar = true
			redirect("settings")
		end

		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 1)
		term.setBackgroundColor(colors[theme["top-box"]])
		print("\n\n")
		leftPrint(string.rep(" ", 17))
		leftPrint(" Reset Firewolf  ")
		leftPrint(string.rep(" ", 17))
		print("")

		term.setCursorPos(1, 10)
		term.setBackgroundColor(colors[theme["bottom-box"]])
		rightPrint(string.rep(" ", 27))
		rightPrint("  Firewolf has been reset! ")
		rightWrite(string.rep(" ", 27))
		if isAdvanced() then rightPrint("          Click to exit... ")
		else rightPrint("  Press any key to exit... ") end
		rightPrint(string.rep(" ", 27))

		while true do
			local e = os.pullEvent()
			if e == "mouse_click" or e == "key" then return true end
		end
	end

	-- Save
	local f = io.open(settingsLocation, "w")
	f:write(textutils.serialize({auto = autoupdate, incog = incognito, home = homepage}))
	f:close()

	redirect("settings")
end


--  -------- Credits

pages["credits"] = function()
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	print("\n")
	term.setBackgroundColor(colors[theme["top-box"]])
	leftPrint(string.rep(" ", 19))
	leftPrint(" Firewolf Credits  ")
	leftPrint(string.rep(" ", 19))
	print("\n")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	rightPrint(string.rep(" ", 38))
	rightPrint("  Coded by:              GravityScore ")
	rightPrint("                            and 1lann ")
	rightPrint(string.rep(" ", 38))
	rightPrint("  Based off:     RednetExplorer 2.4.1 ")
	rightPrint("           Made by ComputerCraftFan11 ")
	rightPrint(string.rep(" ", 38))
end


--  -------- Error Pages

errorPages["overspeed"] = function()
	clear("overspeed", colors[theme["background"]])
	print("")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	leftPrint(string.rep(" ", 14))
	leftPrint(" Warning! D:  ")
	leftPrint(string.rep(" ", 14))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	rightPrint(string.rep(" ", 40))
	rightPrint("  Website browsing sleep limit reached! ")
	rightPrint(string.rep(" ", 40))
	rightPrint("      To prevent Firewolf from spamming ")
	rightPrint("   rednet, Firewolf has stopped loading ")
	rightPrint("                              the page. ")
	for i = 1, 3 do rightPrint(string.rep(" ", 40)) end

	openAddressBar = false
	for i = 1, 5 do
		term.setCursorPos(1, 14)
		rightWrite(string.rep(" ", 43))
		if 6 - i == 1 then rightWrite("                Please wait 1 second... ")
		else rightWrite("                Please wait " .. tostring(6 - i) .. " seconds... ") end
		sleep(1)
	end
	openAddressBar = true

	term.setCursorPos(1, 14)
	rightWrite(string.rep(" ", 43))
	rightWrite("            You may now browse normally ")
end

errorPages["crash"] = function(error)
	clear("crash", colors[theme["background"]])
	print("")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	leftPrint(string.rep(" ", 30))
	leftPrint(" The Website Has Crashed! D:  ")
	leftPrint(string.rep(" ", 30))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	rightPrint(string.rep(" ", 31))
	rightPrint("      The website has crashed! ")
	rightPrint("  Report this to the operator: ")
	rightPrint(string.rep(" ", 31))
	term.setBackgroundColor(colors[theme["background"]])
	print("")
	print(" " .. tostring(error))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	rightPrint(string.rep(" ", 31))
	rightPrint("   You may now browse normally ")
	rightPrint(string.rep(" ", 31))
end


--  -------- External

local function validateexternal(site)
	-- Modem
	if not modemPresent() then return "modem" end

	-- Website
	local id, content, status = curProtocol.getWebsite(site)
	if id and status then return "exists", id, content, status end

	-- Cache
	local cacheLoc = cacheFolder .. "/" .. site:gsub("/", "$slazh$")
	if fs.exists(cacheLoc) and not fs.isDir(cacheLoc) then return "cache" end

	-- Search results
	local res = {}
	if site ~= "" then
		for _, v in pairs(dnsDatabase[1]) do
			if v:find(site:lower(), 1, true) then table.insert(res, v) end
		end
	else for _, v in pairs(dnsDatabase[1]) do table.insert(res, v) end end
	table.sort(res)
	table.sort(res, function(a, b)
		local _, ac = a:gsub("rdnt://", ""):gsub("http://", ""):gsub(site:lower(), "")
		local _, bc = b:gsub("rdnt://", ""):gsub("http://", ""):gsub(site:lower(), "")
		return ac > bc
	end)

	if #res > 0 then return "search", res
	elseif site == "" then return "search", res end

	-- Doesn't exist
	return "false"
end

local function loadexternal(site)
	local a, res, content, status = validateexternal(site)
	local func = nil

	if a == "exists" then
		local cacheLoc = cacheFolder .. "/" .. site:gsub("/", "$slazh$")
		local f = io.open(cacheLoc, "w")
		f:write(content)
		f:close()

		local fn, err = loadfile(cacheLoc)
		if not err then
			setfenv(fn, antivirus)
			if status == "whitelist" then setfenv(fn, override) end

			func = function()
				local _, err = pcall(fn)
				if err then
					websiteerror = err
					os.queueEvent(event_error)
				end
			end
		else
			func = function()
				local errf = errorPages["crash"]
				setfenv(errf, override)
				pcall(function() errf(err) end)
			end
		end
	elseif a == "modem" then
		func = function() checkForModem(graphics.nomodem) end
	elseif a == "search" then
		if #res > 0 then
			func = function()
				term.setBackgroundColor(colors[theme["background"]])
				term.clear()
				term.setCursorPos(1, 2)
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				local t = "1 Search Result"
				if #res > 1 then t = #res .. " Search Results" end
				leftPrint(string.rep(" ", t:len() + 3))
				leftPrint(" " .. t .. "  ")
				leftPrint(string.rep(" ", t:len() + 3))
				print("")

				term.setBackgroundColor(colors[theme["bottom-box"]])
				for i = 1, 12 do rightPrint(string.rep(" ", 42)) end
				local opt = scrollingPrompt(res, w - 39, 7, 10, 38)
				if opt then redirect(opt:gsub("rdnt://", ""):gsub("http://", "")) end
			end
		else
			func = graphics.nosearchresults
		end
	elseif a == "false" or a == "cache" then
		func = graphics.nonexistantwebpage
	end

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)

	local a = override
	a["browserAgent"] = browserAgent
	setfenv(func, a)
	curtext, curbackground = colors.white, colors.black
	tabs[currentTab] = coroutine.create(func)
end


--  -------- Website

local function loadinternal(site)
	if pages[site] then
		local func = pages[site]
		setfenv(func, override)
		tabs[currentTab] = coroutine.create(function()
			local _, err = pcall(function() func() end)
			if err then
				websiteerror = err
				os.queueEvent(event_error)
			end
		end)

		return true
	else return false end
end

local function loadsite(site)
	w, h = term.getSize()
	clear(site)
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	fs.delete(websiteDataFolder)
	fs.makeDir(websiteDataFolder)

	if site ~= "exit" and site ~= addressBarHistory[#addressBarHistory] then
		table.insert(addressBarHistory, site)
	end

	checkForModem()
	if os.clock() - loadingClock > 5 then loadingRate, loadingClock = 0, os.clock() end
	if loadingRate >= 8 then
		local overspeedFunc = errorPages["overspeed"]
		setfenv(overspeedFunc, override)
		overspeedFunc()
		loadingRate, loadingClock = 0, os.clock()
	end

	-- Load
	os.queueEvent(event_load)
	website = site
	setfenv(loadinternal, override)
	setfenv(loadexternal, override)
	if not loadinternal(site) then loadexternal(site) end
	if tabs[currentTab] then _, filters[currentTab] = coroutine.resume(tabs[currentTab]) end
end


--  -------- Address Bar

local function addressbarread()
	local len, list = 4, {}

	local function draw(l)
		local ox, oy = term.getCursorPos()
		for i = 1, len do
			term.setTextColor(colors[theme["address-bar-text"]])
			term.setBackgroundColor(colors[theme["address-bar-background"]])
			term.setCursorPos(1, i + 1)
			write(string.rep(" ", w))
		end

		term.setBackgroundColor(colors[theme["address-bar-base"] or theme["bottom-box"]])
		term.setCursorPos(1, len + 2)
		write(string.rep(" ", w))
		term.setBackgroundColor(colors[theme["address-bar-background"]])
		for i, v in ipairs(l) do term.setCursorPos(2, i + 1) write(v) end
		term.setCursorPos(ox, oy)
	end

	local function update(line, event, ...)
		local params = {...}
		local y = params[3]
		if event == "char" or event == "history" or event == "delete" then
			list = {}
			for _, v in pairs(dnsDatabase[1]) do
				if #list < len and
						v:gsub("rdnt://", ""):gsub("http://", ""):find(line:lower(), 1, true) then
					table.insert(list, v)
				end
			end

			table.sort(list)
			table.sort(list, function(a, b)
				local _, ac = a:gsub("rdnt://", ""):gsub("http://", ""):gsub(line:lower(), "")
				local _, bc = b:gsub("rdnt://", ""):gsub("http://", ""):gsub(line:lower(), "")
				return ac > bc
			end)
			draw(list)
			return false
		elseif event == "mouse_click" then
			for i = 1, #list do
				if y == i + 1 then return true, list[i]:gsub("rdnt://", ""):gsub("http://", "") end
			end
		end
	end

	if isAdvanced() and modemPresent() then
		return modRead({history = addressBarHistory, visibleLength = w - 2, textLength = 300, 
			liveUpdates = update, exitOnKey = "control"})
	else
		return modRead({history = addressBarHistory, visibleLength = w - 2, textLength = 300,
			exitOnKey = "control"})
	end
end


--  -------- Main

local function searchresults()
	if modemPresent() then curProtocol.getSearchResults() end
	local lastCheck = os.clock()
	while true do
		local e = os.pullEvent()
		if e == event_load and modemPresent() and os.clock() - lastCheck > 5 then
			curProtocol.getSearchResults()
			lastCheck = os.clock()
		end
	end
end

local function run()
	loadingClock = os.clock()
	loadsite(homepage)
	while true do
		local e, but, x, y, p4, p5 = os.pullEvent()
		if ((e == "mouse_click" and y == 1 and clickableAddressBar) or
				(e == "key" and (but == 29 or but == 157))) and openAddressBar then
			if e == "key" then x = -1 end
			if not menuBarOpen and x == w then
				-- Open menu bar
				menuBarOpen = true
				term.setBackgroundColor(colors[theme["top-box"]])
				term.setTextColor(colors[theme["address-bar-text"]])
				term.setCursorPos(1, 1)
				write("> [- Exit Firewolf -]                              ")
			elseif menuBarOpen and (x == 1 or (but == 29 or but == 157)) then
				-- Close menu bar
				menuBarOpen = false
				clear(website, nil, true)
			elseif menuBarOpen and x > 2 and x < 22 then
				return
			elseif not menuBarOpen then
				-- Stop
				if tabs[currentTab] then tabs[currentTab] = nil end

				-- Clear
				term.setBackgroundColor(colors[theme["address-bar-background"]])
				term.setTextColor(colors[theme["address-bar-text"]])
				term.setCursorPos(2, 1)
				term.clearLine()
				if curProtocol == protocols.rdnt then write("rdnt://")
				elseif curProtocol == protocols.http then write("http://") end

				-- Read
				local osite = website
				local site = addressbarread()
				if not site then site = osite
				elseif site == "home" or site == "homepage" then site = homepage
				elseif site == "exit" then return end

				-- Load
				loadsite(site)
			end
		elseif e == event_error and websiteerror then
			-- Display
			if tabs[currentTab] then tabs[currentTab] = nil end

			local errf = errorPages["crash"]
			setfenv(errf, override)
			errf(websiteerror)
			websiteerror = nil
		elseif e == event_redirect and openAddressBar then
			-- Stop
			if tabs[currentTab] then tabs[currentTab] = nil end

			-- Load
			if not but or but == "exit" then but = website
			elseif but == "home" or but == "homepage" then but = homepage end
			loadsite(but)
		elseif tabs[currentTab] then
			if coroutine.status(tabs[currentTab]) == "suspended" then
				if e == "mouse_click" and offsetclick then y = y - 1 end
				if (filters[currentTab] or e) == e then
					_, filters[currentTab] = coroutine.resume(tabs[currentTab], e, but, x, y, 
						p4, p5)
				end
			end

			for i = 1, #tabs do
				if tabs[i] and coroutine.status(tabs[i]) == "dead" then
					tabs[i] = nil
				end
			end
		end
	end
end


--  -------- Startup

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

	-- Load Settings
	if fs.exists(settingsLocation) and not fs.isDir(settingsLocation) then
		local f = io.open(settingsLocation, "r")
		local a = textutils.unserialize(f:read("*l"))
		if type(a) == "table" then autoupdate, incognito, homepage = a.auto, a.incog, a.home end
		f:close()
	else autoupdate, incognito, homepage = "true", "false", "firewolf" end
	curProtocol = protocols.rdnt

	-- Update
	rightPrint(string.rep(" ", 32))
	rightPrint("        Checking for Updates... ")
	rightPrint(string.rep(" ", 32))
	setfenv(updateClient, env)
	if not noInternet then
		if updateClient() then
			if debugFile then debugFile:close() end
			shell.run(firewolfLocation)
			error()
		end
	end

	-- Download Files
	local x, y = term.getCursorPos()
	term.setCursorPos(1, y - 2)
	rightWrite(string.rep(" ", 32))
	rightWrite("  Downloading Required Files... ")
	if not noInternet then resetFilesystem() end
	loadDatabases()
	checkForModem()

	-- Run
	setfenv(run, env)
	parallel.waitForAny(run, searchresults)
end

local function startup()
	-- HTTP
	if not http and not noInternet then
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 2)
		term.setBackgroundColor(colors[theme["top-box"]])
		api.leftPrint(string.rep(" ", 24))
		api.leftPrint(" HTTP API Not Enabled!  ")
		api.leftPrint(string.rep(" ", 24))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		api.rightPrint(string.rep(" ", 36))
		api.rightPrint("  Firewolf is unable to run without ")
		api.rightPrint("       the HTTP API Enabled! Please ")
		api.rightPrint("    enable it in your ComputerCraft ")
		api.rightPrint("                            Config! ")
		api.rightPrint(string.rep(" ", 36))

		if isAdvanced() then api.rightPrint("                   Click to exit... ")
		else api.rightPrint("           Press any key to exit... ") end
		api.rightPrint(string.rep(" ", 36))

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
		api.centerPrint("Advanced computer Required!")
		print("\n")
		api.centerPrint("  This version of Firewolf requires  ")
		api.centerPrint("  an Advanced computer to run!       ")
		print("")
		api.centerPrint("  Turtles may not be used to run     ")
		api.centerPrint("  Firewolf! :(                       ")
		print("")
		api.centerPrint("Press any key to exit...")

		os.pullEvent("key")
		return false
	end

	-- Run
	setfenv(main, env)
	local _, err = pcall(main)
	if err and not err:lower():find("terminated") then
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 2)
		term.setCursorBlink(false)
		term.setBackgroundColor(colors[theme["top-box"]])
		api.leftPrint(string.rep(" ", 27))
		api.leftPrint(" Firewolf has Crashed! D:  ")
		api.leftPrint(string.rep(" ", 27))
		print("")
		term.setBackgroundColor(colors[theme["background"]])
		print("")
		print("  " .. err)
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		api.rightPrint(string.rep(" ", 41))
		if autoupdate == "true" then
			api.rightPrint("    Please report this error to 1lann or ")
			api.rightPrint("  GravityScore so we are able to fix it! ")
			api.rightPrint("  If this problem persists, try deleting ")
			api.rightPrint("                         " .. rootFolder .. " ")
		else
			api.rightPrint("        Automatic updating is off! A new ")
			api.rightPrint("     version may have have been released ")
			api.rightPrint("                that may fix this error! ")
			api.rightPrint("        If you didn't turn auto updating ")
			api.rightPrint("             off, delete " .. rootFolder .. " ")
		end

		api.rightPrint(string.rep(" ", 41))
		if isAdvanced() then api.rightPrint("                        Click to exit... ")
		else api.rightPrint("                Press any key to exit... ") end
		api.rightPrint(string.rep(" ", 41))

		while true do
			local e, but, x, y = os.pullEvent()
			if e == "mouse_click" or e == "key" then break end
		end

		return false
	end
end

-- Check If Read Only
if fs.isReadOnly(firewolfLocation) or fs.isReadOnly(rootFolder) then
	print("Firewolf cannot modify itself or its root folder!")
	print("")
	print("This cold be caused by Firewolf being placed in")
	print("the rom folder, or another program may be")
	print("preventing the modification of Firewolf.")
	error()
end

-- Theme
if not isAdvanced() then theme = originalTheme
else theme = loadTheme(themeLocation) or defaultTheme end

-- Debug File
if #tArgs > 0 and tArgs[1] == "debug" then
	print("Debug Mode Enabled")
	if fs.exists(debugLogLocation) then debugFile = io.open(debugLogLocation, "a")
	else debugFile = io.open(debugLogLocation, "w") end
	debugFile:write("\n-- [" .. textutils.formatTime(os.time()) .. "] New Log --")
	sleep(1)
end

-- Start
startup()

-- Exit Message
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.setCursorBlink(false)
term.clear()
term.setCursorPos(1, 1)
api.centerPrint("Thank You for Using Firewolf " .. version)
api.centerPrint("Made by 1lann and GravityScore")

-- Close
for _, v in pairs(rs.getSides()) do 
	if peripheral.getType(v) == "modem" then rednet.close(v) end
end
if debugFile then debugFile:close() end
