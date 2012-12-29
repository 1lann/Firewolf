--  
--  Firewolf Website Browser
--  Made by GravityScore and 1lann
--  License: https://raw.github.com/1lann/Firewolf/master/LICENSE
--
--  Original Concept From RednetExplorer 2.4.1
--  RednetExplorer Made by ComputerCraftFan11
--  


--  Features:
--  - Debug mode
--  - Proper support for NDF-OS
--  - Support for normal computers
--  - Christmas Theme
--  - Christmas startup icon
--  * Live Search List Updating


--  -------- Variables

-- Version
local version = "2.3"
local browserAgentTemplate = "Firewolf " .. version
browserAgent = browserAgentTemplate
local tArgs = {...}

-- Server Identification
local serverID = "other"
local serverList = {blackwolf = "BlackWolf", geevancraft = "GeevanCraft", 
		experimental = "Experimental", other = "Other"}

-- Updating
local autoupdate = "true"
local incognito = "false"

-- Geometry
local w, h = term.getSize()

-- Debugging
local debugFile = nil

-- Environment
local oldEnv = {}
local env = {}
local backupEnv = {}
local api = {}

-- Themes
local theme = {}

-- Databases
local blacklist = {}
local whitelist = {}
local definitions = {}
local verifiedDownloads = {}

-- Website loading
local website = ""
local homepage = ""
local timeout = 0.08
local openAddressBar = true
local loadingRate = 0
local curSites = {}

-- Protocols
local curProtocol = {}
local protocols = {}

-- History
local history = {}
local addressBarHistory = {}

-- Events
local event_loadWebsite = "firewolf_loadWebsiteEvent"
local event_exitWebsite = "firewolf_exitWebsiteEvent"
local event_exitApp = "firewolf_exitAppEvent"
local event_redirect = "firewolf_redirectEvent"

-- Download URLs
local firewolfURL = "https://raw.github.com/1lann/firewolf/master/entities/" .. serverID .. ".lua"
local databaseURL = "https://raw.github.com/1lann/firewolf/master/databases/" .. serverID .. 
	"-database.txt"
local serverURL = "https://raw.github.com/1lann/firewolf/master/server/server-release.lua"
if serverID == "experimental" then 
	serverURL = "https://raw.github.com/1lann/firewolf/master/server/server-experimental.lua"
end
local availableThemesURL = "https://raw.github.com/1lann/firewolf/master/themes/available.txt"

-- Data Locations
local rootFolder = "/.Firewolf_Data"
local cacheFolder = rootFolder .. "/cache"
local serverFolder = rootFolder .. "/servers"
local themeLocation = rootFolder .. "/theme"
local defaultThemeLocation = rootFolder .. "/default_theme"
local availableThemesLocation = rootFolder .. "/available_themes"
local serverSoftwareLocation = rootFolder .. "/server_software"
local settingsLocation = rootFolder .. "/settings"
local historyLocation = rootFolder .. "/history"
local firewolfLocation = "/" .. shell.getRunningProgram()

local userBlacklist = rootFolder .. "/user_blacklist"
local userWhitelist = rootFolder .. "/user_whitelist"
local globalDatabase = rootFolder .. "/database"


--  -------- Firewolf API

api.clearPage = function(site, color, redraw)
	-- Site titles
	local titles = {firewolf = "Firewolf Homepage", server = "Server Management", 
		history = "Firewolf History", help = "Help Page", downloads = "Downloads Center", 
		settings = "Firewolf Settings", credits = "Firewolf Credits", getinfo = "Website Information",
		nomodem = "No Modem Attached!", crash = "Website Has Crashed!", overspeed = "Too Fast!"}
	local title = titles[site]

	-- Clear
	local c = color
	if c == nil then c = colors.black end
	term.setBackgroundColor(c)
	term.setTextColor(colors[theme["address-bar-text"]])
	if redraw ~= true then term.clear() end

	-- URL bar
	term.setCursorPos(2, 1)
	term.setBackgroundColor(colors[theme["address-bar-background"]])
	term.clearLine()
	term.setCursorPos(2, 1)
	local a = site
	if a:len() > w - 9 then a = a:sub(1, 39) .. "..." end
	write("rdnt://" .. a)
	if title ~= nil then
		term.setCursorPos(w - title:len(), 1)
		write(title)
	end

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	print("")
end

api.centerPrint = function(text)
	local w, h = term.getSize()
	local x, y = term.getCursorPos()
	term.setCursorPos(math.ceil((w + 1)/2 - text:len()/2), y)
	print(text)
end

api.centerWrite = function(text)
	local w, h = term.getSize()
	local x, y = term.getCursorPos()
	term.setCursorPos(math.ceil((w + 1)/2 - text:len()/2), y)
	write(text)
end

api.leftPrint = function(text)
	local x, y = term.getCursorPos()
	term.setCursorPos(4, y)
	print(text)
end

api.leftWrite = function(text)
	local x, y = term.getCursorPos()
	term.setCursorPos(4, y)
	write(text)
end

api.rightPrint = function(text)
	local x, y = term.getCursorPos()
	local w, h = term.getSize()
	term.setCursorPos(w - text:len() - 1, y)
	print(text)
end

api.rightWrite = function(text)
	local x, y = term.getCursorPos()
	local w, h = term.getSize()
	term.setCursorPos(w - text:len() - 1, y)
	write(text)
end

api.redirect = function(url)
	os.queueEvent(event_redirect, url:gsub("rdnt://", ""))
end

api.prompt = function(list, dir)
	if term.isColor() then
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
			elseif e == event_exitWebsite then
				return nil
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
			elseif e == event_exitWebsite then
				return nil
			end
			term.setCursorPos(list[curSel][2], list[curSel][3])
			write("[")
			term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
			write("]")
		end
	end
end

api.scrollingPrompt = function(list, x, y, len, width)
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

	if term.isColor() then
		local function draw(a)
			for i, v in ipairs(a) do
				term.setCursorPos(1, y + i - 1)
				api.centerWrite(string.rep(" ", wid + 2))
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
			elseif e == event_exitWebsite then
				return nil
			end
		end
	else
		local function draw(a)
			for i, v in ipairs(a) do
				term.setCursorPos(1, y + i - 1)
				api.centerWrite(string.rep(" ", wid + 2))
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
			elseif e == event_exitWebsite then
				return nil
			end
			term.setCursorPos(x + 1, y + curSel - 1)
			write("x")
		end
	end
end

api.clearArea = function() api.clearPage(website) end
api.cPrint = function(text) api.centerPrint(text) end
api.cWrite = function(text) api.centerWrite(text) end
api.lPrint = function(text) api.leftPrint(text) end
api.lWrite = function(text) api.leftWrite(text) end
api.rPrint = function(text) api.rightPrint(text) end
api.rWrite = function(text) api.rightWrite(text) end


-- Set Environment
for k, v in pairs(getfenv(0)) do env[k] = v end
for k, v in pairs(getfenv(1)) do env[k] = v end
for k, v in pairs(env) do oldEnv[k] = v end
for k, v in pairs(api) do env[k] = v end
for k, v in pairs(env) do backupEnv[k] = v end
setfenv(1, env)


--  -------- Utilities

local function debugLog(n, ...)
	local lArgs = {...}
	if debugFile then
		if n == nil then n = "" end
		debugFile:write("\n" .. n .. " : ")
		for k, v in pairs(lArgs) do 
			if type(v) == "string" or type(v) == "number" or type(v) == nil then
				f:write(tostring(v) .. ", ")
			else f:write("type-" .. type(v) .. ", ") end
		end
	end
end

local function modRead(replaceChar, his, maxLen, stopAtMaxLen, liveUpdates, exitOnControl)
	term.setCursorBlink(true)
	local line = ""
	local hisPos = nil
	local pos = 0
	if replaceChar then replaceChar = replaceChar:sub(1, 1) end
	local w, h = term.getSize()
	local sx, sy = term.getCursorPos()

	local function redraw(repl)
		local scroll = 0
		if line:len() >= maxLen then scroll = line:len() - maxLen end

		term.setCursorPos(sx, sy)
		local a = repl or replaceChar
		if a then term.write(string.rep(a, line:len() - scroll))
		else term.write(line:sub(scroll + 1)) end
		term.setCursorPos(sx + pos - scroll, sy)
	end

	while true do
		local e, but, x, y, p4, p5 = os.pullEvent()
		if e == "char" and not(stopAtMaxLen == true and line:len() >= maxLen) then
			line = line:sub(1, pos) .. but .. line:sub(pos + 1, -1)
			pos = pos + 1
			redraw()
		elseif e == "key" then
			if but == keys.enter then
				break
			elseif but == keys.left then
				if pos > 0 then pos = pos - 1 redraw() end
			elseif but == keys.right then
				if pos < line:len() then pos = pos + 1 redraw() end
			elseif (but == keys.up or but == keys.down) and his then
				redraw(" ")
				if but == keys.up then
					if hisPos == nil and #his > 0 then hisPos = #his
					elseif hisPos > 1 then hisPos = hisPos - 1 end
				elseif but == keys.down then
					if hisPos == #his then hisPos = nil
					elseif hisPos ~= nil then hisPos = hisPos + 1 end
				end

				if hisPos then
					line = his[hisPos]
					pos = line:len()
				else
					line = ""
					pos = 0
				end
				redraw()
				if liveUpdates then
					local a, data = liveUpdates(line, "update_history", nil, nil, nil, nil, nil)
					if a == true and data == nil then
						term.setCursorBlink(false)
						return line
					elseif a == true and data ~= nil then
						term.setCursorBlink(false)
						return data
					end
				end
			elseif but == keys.backspace and pos > 0 then
				redraw(" ")
				line = line:sub(1, pos - 1) .. line:sub(pos + 1, -1)
				pos = pos - 1
				redraw()
				if liveUpdates then
					local a, data = liveUpdates(line, "delete", nil, nil, nil, nil, nil)
					if a == true and data == nil then
						term.setCursorBlink(false)
						return line
					elseif a == true and data ~= nil then
						term.setCursorBlink(false)
						return data
					end
				end
			elseif but == keys.home then
				pos = 0
				redraw()
			elseif but == keys.delete and pos < line:len() then
				redraw(" ")
				line = line:sub(1, pos) .. line:sub(pos + 2, -1)
				redraw()
				if liveUpdates then
					local a, data = liveUpdates(line, "delete", nil, nil, nil, nil, nil)
					if a == true and data == nil then
						term.setCursorBlink(false)
						return line
					elseif a == true and data ~= nil then
						term.setCursorBlink(false)
						return data
					end
				end
			elseif but == keys["end"] then
				pos = line:len()
				redraw()
			elseif (but == 29 or but == 157) and not(exitOnControl) then 
				term.setCursorBlink(false)
				return nil
			end
		end if liveUpdates then
			local a, data = liveUpdates(line, e, but, x, y, p4, p5)
			if a == true and data == nil then
				term.setCursorBlink(false)
				return line
			elseif a == true and data ~= nil then
				term.setCursorBlink(false)
				return data
			end
		end
	end

	term.setCursorBlink(false)
	if line ~= nil then line = line:gsub("^%s*(.-)%s*$", "%1") end
	return line
end


--  -------- Themes

local defaultTheme = {["address-bar-text"] = "white", ["address-bar-background"] = "gray", 
	["address-bar-base"] = "lightGray", ["top-box"] = "red", ["bottom-box"] = "orange", 
	["text-color"] = "white", ["background"] = "gray"}
local originalTheme = {["address-bar-text"] = "white", ["address-bar-background"] = "black", 
	["address-bar-base"] = "black", ["top-box"] = "black", ["bottom-box"] = "black", 
	["text-color"] = "white", ["background"] = "black"}

local ownThemeFileContent = [[
-- Text color of the address bar
address-bar-text=

-- Background color of the address bar
address-bar-background=

-- Color of separator bar when live searching
address-bar-base=

-- Top box color
top-box=

-- Bottom box color
bottom-box=

-- Background color
background=

-- Main text color
text-color=

]]

local function loadTheme(path)
	if fs.exists(path) and not(fs.isDir(path)) then
		local a = {}
		local f = io.open(path, "r")
		local l = f:read("*l")
		while l ~= nil do
			l = l:gsub("^%s*(.-)%s*$", "%1")
			if l ~= "" and l ~= nil and l ~= "\n" and l:sub(1, 2) ~= "--" then
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


--  -------- Download API

function urlDownload(url)
	clearPage(website, colors[theme["background"]])
	print("\n\n")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Processing Download Request...")
	centerPrint(string.rep(" ", 47))

	openAddressBar = false
	local res = http.get(url)
	openAddressBar = true
	local data = nil
	if res then
		data = res.readAll()
		res.close()
	else
		term.setCursorPos(1, 5)
		centerWrite(string.rep(" ", 47))
		centerPrint("Download Failed!")
		centerPrint("Please report this to the website owner!")
		centerPrint(string.rep(" ", 47))
		openAddressBar = false
		sleep(1.1)
		openAddressBar = true

		clearPage(website, colors.black)
		term.setCursorPos(1, 2)
		return nil
	end

	clearPage(website, colors[theme["background"]])
	print("")
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Download Files")
	centerPrint(string.rep(" ", 47))
	print("")

	local a = website
	if a:find("/") then a = a:sub(1, a:find("/") - 1) end

	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 10 do centerPrint(string.rep(" ", 47)) end
	term.setCursorPos(1, 8)
	centerPrint("  The website:                                 ")
	centerPrint("     rdnt://" .. a .. string.rep(" ", w - a:len() - 16))
	centerPrint("  Is attempting to download a file to this     ")
	centerPrint("  computer!                                    ")

	local opt = prompt({{"Download", 6, 14}, {"Cancel", w - 16, 14}}, "horizontal")
	if opt == "Download" then
		clearPage(website, colors[theme["background"]])
		print("")
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Download Files")
		centerPrint(string.rep(" ", 47))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 10 do centerPrint(string.rep(" ", 47)) end
		local a = tostring(math.random(1000, 9999))
		term.setCursorPos(5, 8)
		write("This is for security purposes: " .. a)
		term.setCursorPos(5, 9)
		write("Enter the 4 numbers above: ")
		local b = modRead(nil, nil, 4, true)
		if b == nil then
			os.queueEvent(event_exitWebsite)
			return
		end

		if b == a then
			term.setCursorPos(5, 11)
			write("Save As: /")
			local c = modRead(nil, nil, w - 18, false)
			if c ~= "" and c ~= nil then
				c = "/" .. c
				local f = io.open(c, "w")
				f:write(data)
				f:close()
				term.setCursorPos(5, 13)
				centerWrite("Download Successful! Continuing to Website...")
				openAddressBar = false
				sleep(1.1)
				openAddressBar = true

				clearPage(website, colors.black)
				term.setCursorPos(1, 2)
				return c
			elseif c == nil then
				os.queueEvent(event_exitWebsite)
				return
			end
		else
			term.setCursorPos(5, 13)
			centerWrite("Incorrect! Cancelling Download...")
			openAddressBar = false
			sleep(1.1)
			openAddressBar = true
		end
	elseif opt == "Cancel" then
		term.setCursorPos(1, 15)
		centerWrite("Download Canceled!")
		openAddressBar = false
		sleep(1.1)
		openAddressBar = true
	elseif opt == nil then
		os.queueEvent(event_exitWebsite)
		return
	end

	clearPage(website, colors.black)
	term.setCursorPos(1, 2)
	return nil
end

function pastebinDownload(code)
	return urlDownload("http://pastebin.com/raw.php?i=" .. code)
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

local function checkGitHub()
	if not download("https://raw.github.com") then
		if term.isColor() then
			local githubImage = textutils.unserialize([[{[1]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=2,[6]=2,[7]=2,[8]=2,[9]=2,[10]=2,[11]=2,[12]=2,
				[13]=2,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,
				[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,
				[47]=0,[48]=0,[49]=0,},[2]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=32768,[6]=2,[7]=2,[8]=2,[9]=2,[10]=2,[11]=2,[12]=2,[13]=32768,
				[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,
				[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,
				[48]=0,[49]=0,},[3]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=32768,[6]=32768,[7]=32768,[8]=32768,[9]=32768,[10]=32768,[11]=32768,
				[12]=32768,[13]=32768,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,
				[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,
				[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[4]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=32768,[6]=32768,[7]=32768,[8]=32768,[9]=32768,
				[10]=32768,[11]=32768,[12]=32768,[13]=32768,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,
				[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,
				[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[5]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=32768,[6]=16,[7]=64,[8]=16,
				[9]=16,[10]=16,[11]=64,[12]=16,[13]=32768,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,
				[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,
				[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[6]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=32768,[6]=16,[7]=16,[8]=16,
				[9]=16,[10]=16,[11]=16,[12]=16,[13]=32768,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,
				[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,
				[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[7]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=32768,[6]=32768,[7]=32768,
				[8]=32768,[9]=32768,[10]=32768,[11]=32768,[12]=32768,[13]=32768,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,
				[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,
				[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[8]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=2,[6]=32768,
				[7]=32768,[8]=32768,[9]=2,[10]=16384,[11]=32768,[12]=32768,[13]=2,[14]=2,[15]=16384,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,
				[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,
				[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[9]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=2,
				[6]=32768,[7]=2,[8]=32768,[9]=2,[10]=32768,[11]=16384,[12]=32768,[13]=2,[14]=16384,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,
				[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,
				[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[10]={[1]=0,[2]=2,[3]=2,[4]=2,
				[5]=2,[6]=32768,[7]=2,[8]=32768,[9]=2,[10]=32768,[11]=2,[12]=16384,[13]=16384,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,
				[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,
				[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[11]={[1]=0,[2]=2,[3]=2,[4]=2,
				[5]=32768,[6]=32768,[7]=2,[8]=32768,[9]=2,[10]=32768,[11]=2,[12]=16384,[13]=16384,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,
				[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,
				[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[12]={[1]=0,[2]=2,[3]=2,[4]=2,
				[5]=2,[6]=2,[7]=2,[8]=2,[9]=2,[10]=2,[11]=16384,[12]=2,[13]=2,[14]=16384,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,
				[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,
				[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[13]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=2,[6]=2,[7]=2,[8]=2,
				[9]=2,[10]=16384,[11]=2,[12]=2,[13]=2,[14]=2,[15]=16384,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,
				[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,
				[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[14]={[1]=0,[2]=2,[3]=2,[4]=2,[5]=2,[6]=2,[7]=2,[8]=2,[9]=2,[10]=2,[11]=2,[12]=2,
				[13]=2,[14]=2,[15]=2,[16]=2,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,
				[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,
				[49]=0,},[15]={[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,
				[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,
				[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[16]={[1]=0,[2]=0,[3]=0,
				[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,
				[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,
				[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},[17]={[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,
				[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,
				[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,
				[46]=0,[47]=0,[48]=0,[49]=0,},[18]={[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,
				[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,
				[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,},}]])
			term.setBackgroundColor(colors[theme["background"]])
			term.clear()
			paintutils.drawImage(githubImage, 1, 3)
			term.setCursorPos(19, 4)
			term.setBackgroundColor(colors[theme["top-box"]])
			term.setTextColor(colors[theme["text-color"]])
			print("                                ")
			term.setCursorPos(19, 5)
			print("  Could not connect to GitHub!  ")
			term.setCursorPos(19, 6)
			print("                                ")
			term.setBackgroundColor(colors[theme["bottom-box"]])
			term.setCursorPos(19, 8)
			print("                                ")
			term.setCursorPos(19, 9)
			print("    Sorry, Firewolf could not   ")
			term.setCursorPos(19, 10)
			print(" connect to GitHub to download  ")
			term.setCursorPos(19, 11)
			print(" necessary files. Please check: ")
			term.setCursorPos(19, 12)
			print("    http://status.github.com    ")
			term.setCursorPos(19, 13)
			print("                                ")
			term.setCursorPos(19, 14)
			print("        Click to exit...        ")
			term.setCursorPos(19, 15)
			print("                                ")
			os.pullEvent("mouse_click")
			error()
		else
			term.clear()
			term.setCursorPos(1,1)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			print("")
			print("")
			centerPrint("Could not connect to GitHub!")
			print("")
			centerPrint("Sorry, Firefox could not connect to GitHub to")
			centerPrint("download necessary files. Please check:")
			centerPrint("http://status.github.com")
			print("")
			centerPrint("Press any key to exit...")
			os.pullEvent("key")
			error()
		end
	end
end

local function migrateFilesystem()
	-- Migrate from old version
	if fs.exists("/.Firefox_Data") then
		fs.move("/.Firefox_Data", rootFolder)
		fs.delete(rootFolder .. "/server_software")
		fs.delete(serverSoftwareLocation)
	end

	fs.delete(serverSoftwareLocation)
end

local function resetFilesystem()
	-- Folders
	if not(fs.exists(rootFolder)) then fs.makeDir(rootFolder)
	elseif not(fs.isDir(rootFolder)) then fs.move(rootFolder, "/old-firewolf-data-file") end
	if not(fs.exists(serverFolder)) then fs.makeDir(serverFolder) end
	if not(fs.exists(cacheFolder)) then fs.makeDir(cacheFolder) end

	-- Settings
	if not(fs.exists(settingsLocation)) then
		local f = io.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = "true", incog = "false", home = "firewolf"}))
		f:close()
	end

	-- History
	if not(fs.exists(historyLocation)) then
		local f = io.open(historyLocation, "w")
		f:write(textutils.serialize({}))
		f:close()
	end

	-- Server Software
	if not(fs.exists(serverSoftwareLocation)) then
		download(serverURL, serverSoftwareLocation)
	end

	-- Themes
	if term.isColor() then
		if autoupdate == "true" then
			fs.delete(availableThemesLocation)
			fs.delete(defaultThemeLocation)
		end if not(fs.exists(availableThemesLocation)) then
			download(availableThemesURL, availableThemesLocation)
		end if not(fs.exists(defaultThemeLocation)) then
			local f = io.open(availableThemesLocation, "r")
			local a = f:read("*l")
			f:close()
			a = a:sub(1, a:find("| |") - 1)
			download(a, defaultThemeLocation)
		end if not(fs.exists(themeLocation)) then
			fs.copy(defaultThemeLocation, themeLocation)
		end
	end

	-- Databases
	fs.delete(globalDatabase)
	for _, v in pairs({globalDatabase, userWhitelist, userBlacklist}) do
		if not(fs.exists(v)) then
			local f = io.open(v, "w")
			f:write("")
			f:close()
		end
	end

	fs.delete("/.Firewolf_Data/tempFile")

	return nil
end

local function updateClient()
	local updateLocation = rootFolder .. "/update"
	fs.delete(updateLocation)

	-- Update
	download(firewolfURL, updateLocation)
	local a = io.open(updateLocation, "r")
	local b = io.open(firewolfLocation, "r")
	local new = a:read("*a")
	local cur = b:read("*a")
	a:close()
	b:close()

	if cur ~= new then
		fs.delete(firewolfLocation)
		fs.move(updateLocation, firewolfLocation)
		shell.run(firewolfLocation)
		error()
	else
		fs.delete(updateLocation)
	end
end

local function appendToHistory(site)
	if incognito == "false" then
		if site == "home" or site == "homepage" then 
			site = homepage 
		end if site ~= "exit" and site ~= "" and site ~= "history" and site ~= history[1] then
			table.insert(history, 1, site)
			local f = io.open(historyLocation, "w")
			f:write(textutils.serialize(history))
			f:close()
		end if site ~= addressBarHistory[#addressBarHistory] then
			table.insert(addressBarHistory, site)
		end
	end
end


--  -------- Databases

local function loadDatabases()
	-- Get
	fs.delete(globalDatabase)
	download(databaseURL, globalDatabase)
	local f = io.open(globalDatabase, "r")
	local l = f:read("*l"):gsub("^%s*(.-)%s*$", "%1")

	-- Blacklist  ([id])
	blacklist = {}
	while l ~= "START-WHITELIST" do
		l = f:read("*l"):gsub("^%s*(.-)%s*$", "%1")
		if l ~= "" and l ~= "\n" and l ~= nil and l ~= "START-BLACKLIST" then
			table.insert(blacklist, l)
		end
	end

	-- Whitelist ([site name]| |[id])
	whitelist = {}
	while l ~= "START-DOWNLOADS" do
		l = f:read("*l"):gsub("^%s*(.-)%s*$", "%1")
		if l ~= "" and l ~= "\n" and l ~= nil and l ~= "START-DOWNLOADS" then
			local a, b = l:find("| |")
			table.insert(whitelist, {l:sub(1, a - 1), l:sub(b + 1, -1)})
		end
	end

	-- Downloads ([url])
	downloads = {}
	while l ~= "START-DEFINITIONS" do
		l = f:read("*l"):gsub("^%s*(.-)%s*$", "%1")
		if l ~= "" and l ~= "\n" and l ~= nil and l ~= "START-DEFINITIONS" then
			table.insert(downloads, l)
		end
	end

	-- Definitions ([definition]| |[offence name])
	definitions = {}
	while l ~= "END-DATABASE" do
		l = f:read("*l"):gsub("^%s*(.-)%s*$", "%1")
		if l ~= "" and l ~= "\n" and l ~= nil and l ~= "END-DATABASE" then
			local a, b = l:find("| |")
			table.insert(definitions, {l:sub(1, a - 1), l:sub(b + 1, -1)})
		end
	end
	f:close()

	-- User Blacklist
	if not(fs.exists(userBlacklist)) then 
		local bf = fio.open(userBlacklist, "w") 
		bf:write("\n") 
		bf:close()
	else
		local bf = io.open(userBlacklist, "r")
		local l = bf:read("*l")
		while l ~= nil do
			if l ~= nil and l ~= "" and l ~= "\n" then
				l = l:gsub("^%s*(.-)%s*$", "%1")
				table.insert(blacklist, l)
			end
			l = bf:read("*l")
		end
		f:close()
	end

	-- User Whitelist
	if not(fs.exists(userWhitelist)) then 
		local wf = io.open(userWhitelist, "w") 
		wf:write("\n")
		wf:close()
	else
		local wf = io.open(userWhitelist, "r")
		local l = wf:read("*l")
		while l ~= nil do
			if l ~= nil and l ~= "" and l ~= "\n" then
				l = l:gsub("^%s*(.-)%s*$", "%1")
				local a, b = l:find("| |")
				table.insert(whitelist, {l:sub(1, a - 1), l:sub(b + 1, -1)})
			end
			l = wf:read("*l")
		end
		f:close()
	end
end

local function verify(database, ...)
	local args = {...}
	if database == "blacklist" and #args >= 1 then
		-- id
		local found = false
		for _, v in pairs(blacklist) do
			if tostring(args[1]) == v then found = true end
		end

		return found
	elseif database == "whitelist" and #args >= 2 then
		-- id, site
		local found = false
		for _, v in pairs(whitelist) do
			if v[2] == tostring(args[1]) and v[1] == tostring(args[2]) then 
				found = true 
			end
		end

		return found
	elseif database == "antivirus" and #args >= 1 then
		-- content
		local a = verify("antivirus offences", args[1])
		if #a == 0 then return false
		else return true end
	elseif database == "antivirus offences" and #args >= 1 then
		-- content
		local c = args[1]:gsub(" ", ""):gsub("\n", ""):gsub("\t", "")
		local a = {}
		for _, v in pairs(definitions) do
			local b = false
			for _, c in pairs(a) do
				if c == v[2] then b = true end
			end

			if c:find(v[1], 1, true) and not(b) then
				table.insert(a, v[2])
			end
		end
		table.sort(a)

		return a
	else
		return nil
	end
end


--  -------- Protocols

protocols.http = {}
protocols.rdnt = {}

protocols.rdnt.getSearchResults = function(input)
	local results = {}
	local resultIDs = {}

	rednet.broadcast("rednet.api.ping.searchengine")
	local startClock = os.clock()
	while os.clock() - startClock < 1 do
		local id, i = rednet.receive(timeout)
		if id then
			local bl, wl = verify("blacklist", id), verify("whitelist", id, i)
			if not(i:find(" ")) and i:len() < 40 and (not(bl) or (bl and wl)) then
				if not(resultIDs[tostring(id)]) then
					resultIDs[tostring(id)] = 1
				else
					resultIDs[tostring(id)] = resultIDs[tostring(id)] + 1
				end

				local x = false
				for y = 1, #results do
					if results[y]:lower() == i:lower() then
						x = true
					end
				end

				if not(x) and resultIDs[tostring(id)] <= 5 then
					if not i:find("rdnt://") then i = ("rdnt://" .. i) end
					if input == "" then
						table.insert(results, i)
					elseif string.find(i, input) and i ~= input then
						table.insert(results, i)
					end
				end
			end
		else
			break
		end
	end

	table.sort(results)
	table.sort(results, function(a, b)
		local _, ac = a:gsub("rdnt://", ""):gsub(input:lower(), "")
		local _, bc = b:gsub("rdnt://", ""):gsub(input:lower(), "")
		return ac > bc
	end)
	return results
end

protocols.rdnt.getWebsite = function(site)
	local id, content, status = nil, nil, nil
	local clock = os.clock()
	rednet.broadcast(site)
	while os.clock() - clock < timeout do
		id, content = rednet.receive(timeout)
		if id then
			local bl = verify("blacklist", id)
			local av = verify("antivirus", content)
			local wl = verify("whitelist", id, site)
			status = nil
			if (bl and not(wl)) or site == "" or site == "." or site == ".." then
				-- Ignore
			elseif av and not(wl) then
				status = "antivirus"
				break
			else
				status = "safe"
				break
			end
		end
	end
	debugLog(site)
	return id, content, status
end

protocols.http.getSearchResults = function(input)
	return {}
end

protocols.http.getWebsite = function(site)
	return nil
end


--  -------- Built-In Websites

local pages = {}
local errPages = {}

pages.firewolf = function(site)
	clearPage(site, colors[theme["background"]])
	print("")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 43))
	centerPrint("         _,-='\"-.__               /\\_/\\    ")
	centerPrint("          -.}        =._,.-==-._.,  @ @._, ")
	centerPrint("             -.__  __,-.   )       _,.-'   ")
	centerPrint("  Firewolf " .. version .. "    \"     G..m-\"^m m'        ")
	centerPrint(string.rep(" ", 43))

	term.setBackgroundColor(colors[theme["bottom-box"]])
	term.setCursorPos(1, 10)
	centerPrint(string.rep(" ", 43))
	centerPrint("  rdnt://firewolf                Homepage  ")
	centerPrint("  rdnt://history                  History  ")
	centerPrint("  rdnt://downloads       Downloads Center  ")
	centerPrint("  rdnt://server         Server Management  ")
	centerPrint("  rdnt://help                   Help Page  ")
	centerPrint("  rdnt://settings                Settings  ")
	centerPrint("  rdnt://exit                        Exit  ")
	centerPrint(string.rep(" ", 43))

	while true do
		local e, but, x, y = os.pullEvent()
		if e == "mouse_click" and x >= 7 and x <= 45 then
			if y == 11 then redirect("firewolf") return
			elseif y == 12 then redirect("history") return
			elseif y == 13 then redirect("downloads") return
			elseif y == 14 then redirect("server") return
			elseif y == 15 then redirect("help") return
			elseif y == 16 then redirect("settings") return
			elseif y == 17 then redirect("exit") return
			end
		elseif e == event_exitWebsite then
			os.queueEvent(event_exitWebsite)
			return
		end
	end
end

pages.firefox = function(site)
	redirect("firewolf")
end

pages.history = function(site)
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Firewolf History")
	centerPrint(string.rep(" ", 47))
	print("")
	term.setBackgroundColor(colors[theme["bottom-box"]])

	if #history > 0 then
		for i = 1, 12 do
			centerPrint(string.rep(" ", 47))
		end

		local a = {"Clear History"}
		for i, v in ipairs(history) do
			table.insert(a, "rdnt://" .. v)
		end
		local opt = scrollingPrompt(a, 6, 8, 10, 40)
		if opt == "Clear History" then
			history = {}
			addressBarHistory = {}
			local f = io.open(historyLocation, "w")
			f:write(textutils.serialize(history))
			f:close()

			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Firewolf History")
			centerPrint(string.rep(" ", 47))
			print("\n")
			term.setBackgroundColor(colors[theme["bottom-box"]])
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Cleared history.")
			centerPrint(string.rep(" ", 47))
			openAddressBar = false
			sleep(1.1)

			redirect("history")
			openAddressBar = true
			return
		elseif opt then
			redirect(opt:gsub("rdnt://", ""))
			return
		elseif opt == nil then
			os.queueEvent(event_exitWebsite)
			return
		end
	else
		print("")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("No Items in History!")
		centerPrint(string.rep(" ", 47))
	end
end

pages.downloads = function(site)
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Download Center")
	centerPrint(string.rep(" ", 47))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 5 do
		centerPrint(string.rep(" ", 47))
	end
	local opt = prompt({{"Themes", 7, 8}, {"Plugins", 7, 10}}, "vertical")
	if opt == "Themes" and term.isColor() then
		while true do
			local themes = {}
			local c = {"Make my Own", "Load my Own"}
			local f = io.open(availableThemesLocation, "r")
			local l = f:read("*l")
			while l ~= nil do
				l = l:gsub("^%s*(.-)%s*$", "%1")
				local a, b = l:find("| |")
				table.insert(themes, {l:sub(1, a - 1), l:sub(b + 1, -1)})
				table.insert(c, l:sub(b + 1, -1))
				l = f:read("*l")
			end
			f:close()
			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Download Center - Themes")
			centerPrint(string.rep(" ", 47))
			print("")
			term.setBackgroundColor(colors[theme["bottom-box"]])
			for i = 1, 12 do centerPrint(string.rep(" ", 47)) end
			local t = scrollingPrompt(c, 4, 8, 10, 44)
			if t == nil then
				os.queueEvent(event_exitWebsite)
				return
			elseif t == "Make my Own" then
				term.setCursorPos(6, 18)
				write("Path: /")
				local n = modRead(nil, nil, 35)
				if n ~= "" and n ~= nil then
					n = "/" .. n
					local f = io.open(n, "w")
					f:write(ownThemeFileContent)
					f:close()

					term.setCursorPos(1, 18)
					centerWrite(string.rep(" ", 47))
					term.setCursorPos(6, 18)
					write("File Created!")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
				elseif n == nil then
					os.queueEvent(event_exitWebsite)
					return
				end
			elseif t == "Load my Own" then
				term.setCursorPos(6, 18)
				write("Path: /")
				local n = modRead(nil, nil, 35)
				if n ~= "" and n ~= nil then
					n = "/" .. n
					term.setCursorPos(1, 18)
					centerWrite(string.rep(" ", 47))
					
					if fs.exists(n) and not(fs.isDir(n)) then
						theme = loadTheme(n)
						if theme ~= nil then
							fs.delete(themeLocation)
							fs.copy(n, themeLocation)
							term.setCursorPos(6, 18)
							write("Theme File Loaded! :D")
						else
							term.setCursorPos(6, 18)
							write("Theme File is Corrupt! D:")
							theme = loadTheme(themeLocation)
						end
						openAddressBar = false
						sleep(1.1)
						openAddressBar = true
					elseif not(fs.exists(n)) then
						term.setCursorPos(6, 18)
						write("File does not exist!")
						openAddressBar = false
						sleep(1.1)
						openAddressBar = true
					elseif fs.isDir(n) then
						term.setCursorPos(6, 18)
						write("File is a directory!")
						openAddressBar = false
						sleep(1.1)
						openAddressBar = true
					end
				elseif n == nil then
					os.queueEvent(event_exitWebsite)
					return
				end
			else
				local url = ""
				for _, v in pairs(themes) do if v[2] == t then url = v[1] break end end
				term.setCursorPos(1, 4)
				term.setBackgroundColor(colors[theme["top-box"]])
				centerWrite(string.rep(" ", 47))
				centerWrite("Download Center - Downloading...")
				fs.delete(rootFolder .. "/temp_theme")
				download(url, rootFolder .. "/temp_theme")
				theme = loadTheme(rootFolder .. "/temp_theme")
				if theme == nil then
					theme = loadTheme(themeLocation)
					fs.delete(rootFolder .. "/temp_theme")
					centerWrite(string.rep(" ", 47))
					centerWrite("Download Center - Theme Is Corrupt! D:")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
				else
					fs.delete(themeLocation)
					fs.copy(rootFolder .. "/temp_theme", themeLocation)
					fs.delete(rootFolder .. "/temp_theme")
					centerWrite(string.rep(" ", 47))
					centerWrite("Download Center - Done! :D")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
					redirect("home")
					return
				end
			end
		end
	elseif opt == "Themes" and not(term.isColor()) then
		clearPage(site, colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Download Center")
		centerPrint(string.rep(" ", 47))
		print("\n")

		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Themes are not available on normal")
		centerWrite(string.rep(" ", 47))
		centerPrint("computers! :(")
		centerPrint(string.rep(" ", 47))
	elseif opt == "Plugins" then
		clearPage(site, colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Download Center - Plugins")
		centerPrint(string.rep(" ", 47))
		print("\n")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Comming Soon! (hopefully :P)")
		centerPrint(string.rep(" ", 47))
		centerPrint(string.rep(" ", 47))
		centerPrint(string.rep(" ", 47))

		local opt = prompt({{"Back", -1, 11}}, "vertical")
		if opt == nil then
			os.queueEvent(event_exitWebsite)
			return
		elseif opt == "Back" then
			redirect("downloads")
		end
	elseif opt == nil then
		os.queueEvent(event_exitWebsite)
		return
	end
end

pages.server = function(site)
	local function editPages(server)
		-- Edit
		openAddressBar = false
		local oldLoc = shell.dir()
		local commandHis = {}
		local dir = serverFolder .. "/" .. server
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1, 1)
		print("")
		print("Server Shell Editing")
		print("Type 'exit' to return to Firewolf.")
		print("")

		local allowed = {"cd", "move", "mv", "cp", "copy", "drive", "delete", "rm", "edit", 
			"eject", "exit", "help", "id", "mkdir", "monitor", "rename", "alias", "clear",
			"paint", "firewolf", "lua", "redstone", "rs", "redprobe", "redpulse", 
			"programs", "redset", "reboot", "hello", "label", "list", "ls", "easter"}
		
		while true do
			shell.setDir(serverFolder .. "/" .. server)
			term.setBackgroundColor(colors.black)
			if term.isColor() then term.setTextColor(colors.yellow)
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
			elseif com == "firewolf" or (com == "easter" and words[2] == "egg") then
				-- Easter egg
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

		openAddressBar = true
		redirect("server")
		return
	end

	local function newServer()
		-- New server
		term.setBackgroundColor(colors[theme["background"]])
		for i = 1, 12 do
			term.setCursorPos(3, i + 6)
			write(string.rep(" ", 47))
		end

		term.setBackgroundColor(colors[theme["bottom-box"]])
		term.setCursorPos(1, 8)
		for i = 1, 8 do centerPrint(string.rep(" ", 47)) end
		term.setCursorPos(5, 9)
		write("Name: ")
		local name = modRead(nil, nil, 37)
		if name == nil then
			os.queueEvent(event_exitWebsite)
			return
		end
		term.setCursorPos(5, 11)
		write("URL:")
		term.setCursorPos(8, 12)
		write("rdnt://")
		local url = modRead(nil, nil, 28, true)
		if url == nil then
			os.queueEvent(event_exitWebsite)
			return
		end
		url = url:gsub(" ", "")

		local a = {"/", "| |", " ", "@", "!", "$", "#", "%", "^", "&", "*", "(", ")", 
			"[", "]", "{", "}", "\\", "\"", "'", ":", ";", "?", "<", ">", ",", "`", "~"}
		local b = false
		for k, v in pairs(a) do
			if url:find(v, 1, true) then
				term.setCursorPos(5, 13)
				write("URL Contains Illegal '" .. v .. "'!")
				openAddressBar = false
				sleep(1.1)
				openAddressBar = true
				b = true
				break
			elseif name == "" or url == "" then
				term.setCursorPos(5, 13)
				write("URL or Name Is Empty!")
				openAddressBar = false
				sleep(1.1)
				openAddressBar = true
				b = true
				break
			elseif fs.exists(serverFolder .. "/" .. url) then
				term.setCursorPos(5, 13)
				write("Server Already Exists!")
				openAddressBar = false
				sleep(1.1)
				openAddressBar = true
				b = true
				break
			end
		end

		if not(b) then
			fs.makeDir(serverFolder .. "/" .. url)
			local f = io.open(serverFolder .. "/" .. url .. "/home", "w")
			f:write("print(\"\")\ncenterPrint(\"Welcome To " .. name .. "!\")\n")
			f:close()

			term.setCursorPos(5, 13)
			write("Successfully Created Server! :D")
		end
	end

	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Firewolf Server Management")
	centerPrint(string.rep(" ", 47))
	print("")

	local servers = {}
	for _, v in pairs(fs.list(serverFolder)) do
		if fs.isDir(serverFolder .. "/" .. v) then table.insert(servers, v) end
	end

	if term.isColor() then
		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 12 do
			term.setCursorPos(3, i + 6)
			write(string.rep(" ", 24))
			term.setCursorPos(29, i + 6)
			write(string.rep(" ", 21))
		end

		local function draw(l, sel)
			term.setBackgroundColor(colors[theme["bottom-box"]])
			term.setCursorPos(4, 8)
			write("[- New Server -]")
			for i, v in ipairs(l) do
				term.setCursorPos(3, i + 8)
				write(string.rep(" ", 24))
				term.setCursorPos(4, i + 8)
				local nv = v
				if nv:len() > 18 then nv = nv:sub(1, 15) .. "..." end
				if i == sel then
					write("[ " .. nv .. " ]")
				else
					write("  " .. nv)
				end
			end

			term.setCursorPos(30, 8)
			write(string.rep(" ", 19))
			term.setCursorPos(30, 8)
			if l[sel] then 
				local nl = l[sel]
				if nl:len() > 19 then nl = nl:sub(1, 16) .. "..." end
				write(nl)
			else write("No Server Selected!") end
			term.setCursorPos(30, 10)
			write("[- Start -]")
			term.setCursorPos(30, 12)
			write("[- Edit -]")
			term.setCursorPos(30, 14)
			write("[- Run on Boot -]")
			term.setCursorPos(30, 16)
			write("[- Delete -]")
		end

		local function updateDisplayList(items, loc, len)
			local ret = {}
			for i = 1, len do
				local item = items[i + loc - 1]
				if item ~= nil then table.insert(ret, item) end
			end
			return ret
		end

		local sel = 1
		local loc = 1
		local len = 10
		local disList = updateDisplayList(servers, loc, len)
		draw(disList, sel)

		while true do
			local e, but, x, y = os.pullEvent()
			if e == "key" and but == 200 and #servers > 0 and loc > 1 then
				-- Up
				loc = loc - 1
				disList = updateDisplayList(servers, loc, len)
				draw(disList, sel)
			elseif e == "key" and but == 208 and #servers > 0 and loc + len - 1 < #servers then
				-- Down
				loc = loc + 1
				disList = updateDisplayList(servers, loc, len)
				draw(disList, sel)
			elseif e == "mouse_click" then
				if x >= 4 and x <= 25 then
					if y == 8 then
						newServer()
						redirect("server")
						return
					elseif #servers > 0 then
						for i, v in ipairs(disList) do
							if y == i + 8 then 
								sel = i 
								draw(disList, sel)
							end
						end
					end
				elseif x >= 30 and x <= 40 and y == 10 and #servers > 0 then
					-- Start
					term.clear()
					term.setCursorPos(1, 1)
					term.setBackgroundColor(colors.black)
					term.setTextColor(colors.white)
					openAddressBar = false
					setfenv(1, oldEnv)
					shell.run(serverSoftwareLocation, disList[sel], serverFolder .. "/" .. disList[sel])
					setfenv(1, env)
					openAddressBar = true
					errPages.checkForModem()

					redirect("server")
					return
				elseif x >= 30 and x <= 39 and y == 12 and #servers > 0 then
					editPages(disList[sel])
					redirect("server")
					return
				elseif x >= 30 and x <= 46 and y == 14 and #servers > 0 then
					-- Startup
					fs.delete("/old-startup")
					if fs.exists("/startup") then fs.move("/startup", "/old-startup") end
					local f = io.open("/startup", "w")
					f:write("shell.run(\"" .. serverSoftwareLocation .. "\", \"" .. 
						disList[sel] .. "\", \"" .. serverFolder .. "/" .. disList[sel] .. "\")")
					f:close()

					term.setBackgroundColor(colors[theme["bottom-box"]])
					term.setCursorPos(32, 15)
					write("Will Run on Boot!")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
					term.setCursorPos(32, 15)
					write(string.rep(" ", 18))
				elseif x >= 30 and x <= 41 and y == 16 and #servers > 0 then
					-- Delete
					fs.delete(serverFolder .. "/" .. disList[sel])
					redirect("server")
					return
				end
			elseif e == event_exitWebsite then
				os.queueEvent(event_exitWebsite)
				return
			end
		end
	else
		local a = {"New Server"}
		for _, v in pairs(servers) do table.insert(a, v) end
		local server = scrollingPrompt(a, 4, 8, 10)
		if server == nil then
			os.queueEvent(event_exitWebsite)
			return
		elseif server == "New Server" then
			newServer()
		else
			term.setCursorPos(30, 8)
			write(server)
			local opt = prompt({{"Start", 30, 10}, {"Edit", 30, 12}, {"Run on Boot", 30, 13}, 
				{"Delete", 30, 14}, {"Back", 30, 16}})
			if opt == "Start" then
				-- Start
				term.clear()
				term.setCursorPos(1, 1)
				term.setBackgroundColor(colors.black)
				term.setTextColor(colors.white)
				openAddressBar = false
				setfenv(1, oldEnv)
				shell.run(serverSoftwareLocation, server, serverFolder .. "/" .. server)
				setfenv(1, env)
				openAddressBar = true
				errPages.checkForModem()
			elseif opt == "Edit" then
				editPages(server)
			elseif opt == "Run on Boot" then
				fs.delete("/old-startup")
				if fs.exists("/startup") then fs.move("/startup", "/old-startup") end
				local f = io.open("/startup", "w")
				f:write("shell.run(\"" .. serverSoftwareLocation .. "\", \"" .. 
					server .. "\", \"" .. serverFolder .. "/" .. server .. "\")")
				f:close()

				term.setCursorPos(32, 17)
				write("Will Run on Boot!")
				openAddressBar = false
				sleep(1.1)
				openAddressBar = true
			elseif opt == "Delete" then
				fs.delete(serverFolder .. "/" .. server)
			elseif opt == "Back" then
				-- Do nothing
			elseif opt == nil then
				os.queueEvent(event_exitWebsite)
				return
			end
		end

		redirect("server")
		return
	end
end

pages.help = function(site)
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("\n")
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Firewolf Help")
	centerPrint(string.rep(" ", 47))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 7 do centerPrint(string.rep(" ", 47)) end
	local opt = prompt({{"Getting Started", 7, 9}, {"Making a Theme", 7, 11}, 
		{"API Documentation", 7, 13}}, "vertical")
	local pages = {}
	if opt == "Getting Started" then
		pages[1] = {title = "Getting Started - Intoduction", content = {
			"Hey there!", 
			"",
			"Firewolf is an app that allows you to create", 
			"and visit websites! Each site has name (the",
			"URL) which you can type into the address bar",
			"above, and then visit the site.",
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
			"rdnt://history    Your history",
			"rdnt://downloads  Download themes and plugins",
			"rdnt://server     Create websites",
			"rdnt://help       Help and documentation"
		}} pages[4] = {title = "Getting Started - Built-In Websites", content = {
			"More built-in websites:",
			"",
			"rdnt://settings   Firewolf settings",
			"rdnt://update     Force update Firewolf",
			"rdnt://getinfo    Get website info",
			"rdnt://credits    View the credits",
			"rdnt://exit       Exit the app"
		}}
	elseif opt == "Making a Theme" then
		pages[1] = {title = "Making a Theme - Introduction", content = {
			"Firewolf themes are files that tell Firewolf",
			"to color things certain colors.",
			"Several themes can already be downloaded for",
			"Firewolf from the Download Center.",
			"",
			"You can also make your own theme, use it in",
			"your copy of Firewolf, and submit it to the",
			"Firewolf Download Center!"
		}} pages[2] = {title = "Making a Theme - Example", content = {
			"A theme file consists of several lines of",
			"text. Here is the default theme file:",
			"",
			"address-bar-text=white",
			"address-bar-background=gray",
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
			"For example, specifying red after the =",
			"colors that object red."
		}} pages[4] = {title = "Making a Theme - Have a Go", content = {
			"To make a theme, go to rdnt://downloads,",
			"click on the themes section, and click on",
			"'Create my Own'.",
			"",
			"Enter a theme name, then exit Firewolf and",
			"edit the newly create file in the root",
			"folder. Specify the colors for the keys,",
			"and return to the themes section of the",
			"downloads center. Click 'Load my Own'."
		}} pages[5] = {title = "Making a Theme - Submitting", content = {
			"To submit a theme to the Downloads Center,",
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
			"The functions are documented on the next few",
			"pages."
		}} pages[2] = {title = "API Documentation - 2", content = {
			"centerPrint(text)        cPrint(text)",
			"  - Prints text in the center of the screen",
			"",
			"centerWrite(text)        cWrite(text)",
			"  - Writes text in the center of the screen",
			"",
			"leftPrint(text)          lPrint(text)",
			"  - Prints text to the left of the screen"
		}} pages[3] = {title = "API Documentation - 3", content = {
			"leftWrite(text)          lWrite(text)",
			"  - Writes text to the left of the screen",
			"",
			"rightPrint(text)         rPrint(text)",
			"  - Prints text to the right of the screen",
			"",
			"rightWrite(text)         rWrite(text)",
			"  - Writes text to the right of the screen"
		}} pages[4] = {title = "API Documentation - 4", content = {
			"prompt(list, direction)",
			"  - Prompts the user to choose an option",
			"    from a list formatted like:",
			"    { { \"Option 1\", [x], [y] }, ... }",
			"  - Returns the name of the selected option",
			"  - Example:",
			"    option = prompt({{\"Option 1\", 4, 2},",
			"        {\"Option 2\", 4, 4}})"
		}} pages[5] = {title = "API Documentation - 5", content = {
			"scrollingPrompt(list, x, y, width, height)",
			"  - Prompts the user to choose an option",
			"    from a scrolling list of options",
			"  - Returns the name of the selected option",
			"  - Example:",
			"    option = scrollingPrompt({\"1\", \"2\",",
			"        \"3\", \"4\"}, 4, 2, 41, 12)"
		}} pages[6] = {title = "API Documentation - 6", content = {
			"redirect(site)",
			"  - Redirects to site",
			"",
			"pastebinDownload(code)",
			"  - Prompts user to download from Pastebin",
			"  - Returns the path the user selected to",
			"    download the file to"
		}} pages[7] = {title = "API Documentation - 7", content = {
			"urlDownload(url)",
			"  - Prompts the user to download a raw file",
			"    from a URL",
			"  - Returns the path the user selected to",
			"    download the file to"
		}}
	elseif opt == nil then
		os.queueEvent(event_exitWebsite)
		return
	end

	local function drawPage(page)
		clearPage(site, colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint(page.title)
		centerPrint(string.rep(" ", 47))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 12 do centerPrint(string.rep(" ", 47)) end
		for i, v in ipairs(page.content) do
			term.setCursorPos(4, i + 7)
			write(v)
		end
	end

	local curPage = 1
	local a = {{"Prev", 26, 18}, {"Next", 38, 18}, {"Back",  14, 18}}
	drawPage(pages[curPage])

	while true do
		local b = {a[3]}
		if curPage == 1 then table.insert(b, a[2])
		elseif curPage == #pages then table.insert(b, a[1])
		else table.insert(b, a[1]) table.insert(b, a[2]) end

		local opt = prompt(b, "horizontal")
		if opt == "Prev" then
			curPage = curPage - 1
		elseif opt == "Next" then
			curPage = curPage + 1
		elseif opt == "Back" then
			break
		elseif opt == nil then
			os.queueEvent(event_exitWebsite)
			return
		end

		drawPage(pages[curPage])
	end

	redirect("help")
end

pages.settings = function(site)
	while true do
		clearPage(site, colors[theme["background"]])
		print("\n")
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		centerPrint(string.rep(" ", 43))
		centerWrite(string.rep(" ", 43))
		centerPrint("Firewolf Settings")
		centerWrite(string.rep(" ", 43))
		if not(fs.exists("/.var/settings")) then centerPrint("Designed For: " .. serverList[serverID])
		else centerPrint("Designed For: NDF-OS") end
		centerPrint(string.rep(" ", 43))
		print("")

		local a = "Automatic Updating - On"
		if autoupdate == "false" then a = "Automatic Updating - Off" end
		local b = "Record History - On"
		if incognito == "true" then b = "Record History - Off" end
		local c = "Homepage - rdnt://" .. homepage

		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 9 do centerPrint(string.rep(" ", 43)) end
		local opt = prompt({{a, 7, 10}, {b, 7, 12}, {c, 7, 14}, {"Reset Firewolf", 7, 16}}, "vertical")
		if opt == a then
			if autoupdate == "true" then autoupdate = "false"
			elseif autoupdate == "false" then autoupdate = "true" end
		elseif opt == b then
			if incognito == "true" then incognito = "false"
			elseif incognito == "false" then incognito = "true" end
		elseif opt == c then
			term.setCursorPos(9, 15)
			write("rdnt://")
			local a = modRead(nil, nil, 30)
			if a == nil then
				os.queueEvent(event_exitWebsite)
				return
			end
			if a ~= "" then homepage = a end
		elseif opt == "Reset Firewolf" then
			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Reset Firewolf")
			centerPrint(string.rep(" ", 43))
			print("")
			term.setBackgroundColor(colors[theme["bottom-box"]])
			for i = 1, 12 do centerPrint(string.rep(" ", 43)) end
			local opt = prompt({{"Reset History", 7, 8}, {"Reset Servers", 7, 9}, 
				{"Reset Theme", 7, 10}, {"Reset Cache", 7, 11}, {"Reset Databases", 7, 12}, 
				{"Reset Settings", 7, 13}, {"Back", 7, 14}, {"Reset All", 7, 16}}, "vertical")

			openAddressBar = false
			if opt == "Reset All" then
				fs.delete(rootFolder)
			elseif opt == "Reset History" then
				fs.delete(historyLocation)
			elseif opt == "Reset Servers" then
				fs.delete(serverFolder)
				fs.delete(serverSoftwareLocation)
			elseif opt == "Reset Cache" then
				fs.delete(cacheFolder)
			elseif opt == "Reset Databases" then
				fs.delete(userWhitelist)
				fs.delete(userBlacklist)
				fs.delete(globalDatabase)
			elseif opt == "Reset Settings" then
				fs.delete(settingsLocation)
			elseif opt == "Reset Theme" then
				fs.delete(themeLocation)
				fs.copy(defaultThemeLocation, themeLocation)
			elseif opt == "Back" then
				openAddressBar = true
				redirect("settings")
				return
			elseif opt == nil then
				openAddressBar = true
				os.queueEvent(event_exitWebsite)
				return
			end

			clearPage(site, colors[theme["background"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Reset Firewolf")
			centerPrint(string.rep(" ", 43))
			print("")
			term.setCursorPos(1, 10)
			term.setBackgroundColor(colors[theme["bottom-box"]])
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Firewolf has been reset.")
			centerWrite(string.rep(" ", 43))
			if term.isColor() then centerPrint("Click to exit...")
			else centerPrint("Press any key to exit...") end
			centerPrint(string.rep(" ", 43))
			while true do
				local e = os.pullEvent()
				if e == "mouse_click" or e == "key" then return true end
			end
		elseif opt == nil then
			os.queueEvent(event_exitWebsite)
			return
		end

		-- Save
		local f = io.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = autoupdate, incog = incognito, home = homepage}))
		f:close()
	end
end

pages.update = function(site)
	clearPage(site, colors[theme["background"]])
	print("\n")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("Force Update Firewolf")
	centerPrint(string.rep(" ", 43))

	print("\n")
	term.setBackgroundColor(colors[theme["bottom-box"]])
	centerPrint(string.rep(" ", 43))
	centerPrint(string.rep(" ", 43))
	centerPrint(string.rep(" ", 43))

	local opt = prompt({{"Update", 7, 10}, {"Cancel", 34, 10}}, "horizontal")
	if opt == "Update" then
		openAddressBar = false
		term.setCursorPos(1, 10)
		centerWrite(string.rep(" ", 43))
		centerWrite("Updating...")

		local updateLocation = rootFolder .. "/update"
		fs.delete(updateLocation)
		download(firewolfURL, updateLocation)
		centerWrite(string.rep(" ", 43))
		centerPrint("Done!")
		centerWrite(string.rep(" ", 43))
		if term.isColor() then centerPrint("Click to exit...")
		else centerPrint("Press any key to exit...") end
		centerPrint(string.rep(" ", 43))
		sleep(1.1)
		fs.delete(firewolfLocation)
		fs.move(updateLocation, firewolfLocation)

		return true
	elseif opt == "Cancel" then
		redirect("home")
		return
	elseif opt == nil then
		os.queueEvent(event_exitWebsite)
		return
	end
end

pages.credits = function(site)
	clearPage(site, colors[theme["background"]])
	print("\n")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("Firewolf Credits")
	centerPrint(string.rep(" ", 43))
	print("\n")
	term.setBackgroundColor(colors[theme["bottom-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("Coded by:            GravityScore and")
	centerWrite(string.rep(" ", 43))
	centerPrint("                                1lann")
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("Based off:       RednetExplorer 2.4.1")
	centerWrite(string.rep(" ", 43))
	centerPrint("           Made by ComputerCraftFan11")
	centerPrint(string.rep(" ", 43))
end

--pages.getinfo = function(site)
--	clearPage(site, colors[theme["background"]])
--	print("\n")
--	term.setTextColor(colors[theme["text-color"]])
--	term.setBackgroundColor(colors[theme["top-box"]])
--	centerPrint(string.rep(" ", 43))
--	centerWrite(string.rep(" ", 43))
--	centerPrint("Retrieve Website Information")
--	centerPrint(string.rep(" ", 43))
--	print("\n")
-- 
--	term.setBackgroundColor(colors[theme["bottom-box"]])
--	centerPrint(string.rep(" ", 43))
--	centerPrint(string.rep(" ", 43))
--	centerWrite(string.rep(" ", 43))
--	local x, y = term.getCursorPos()
--	term.setCursorPos(7, y - 1)
--	write("rdnt://")
--	local a = modRead(nil, nil, 31)
--	if a == nil then
--		os.queueEvent(event_exitWebsite)
--		return
--	end
--	local id, content, status = getWebsite(a)
-- 
--	if id ~= nil then
--		term.setCursorPos(1, 10)
--		centerPrint("  rdnt://" .. a .. string.rep(" ", 34 - a:len()))
--		for i = 1, 5 do
--			centerPrint(string.rep(" ", 43))
--		end
--	 	
--		if verify("blacklist", id) then 
--			centerPrint("  Triggers Blacklist" .. string.rep(" ", 43 - 20)) end
--		if verify("whitelist", id, site) then 
--			centerPrint("  Triggers Whitelist" .. string.rep(" ", 43 - 20)) end
--		if verify("antivirus", content) then
--			centerPrint("  Triggers Antivirus" .. string.rep(" ", 43 - 20)) end
--		centerPrint(string.rep(" ", 43))
--		local opt = prompt({{"Save Source", 7, 12}, {"Visit Site", 7, 14}}, "vertical")
--		if opt == "Save Source" then
--			term.setCursorPos(9, 13)
--			write("Save As: /")
--			local loc = modRead(nil, nil, 24)
--			if loc ~= nil and loc ~= "" then
--				loc = "/" .. loc
--				local f = io.open(loc, "w")
--				f:write(content)
--				f:close()
--				term.setCursorPos(1, 13)
--				centerWrite(string.rep(" ", 43))
--			elseif loc == nil then
--				os.queueEvent(event_exitWebsite)
--				return
--			end
--		elseif opt == "Visit Site" then
--			redirect(a)
--			return
--		elseif opt == nil then
--			os.queueEvent(event_exitWebsite)
--			return
--		end
--	else
--		term.setCursorPos(1, 10)
--		centerWrite(string.rep(" ", 43))
--		centerPrint("Webpage Not Found! D:")
--	end
--end

pages.kitteh = function(site)
	openAddressBar = false
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setCursorPos(1, 3)
	centerPrint("       .__....._             _.....__,         ")
	centerPrint("         .\": o :':         ;': o :\".           ")
	centerPrint("         '. '-' .'.       .'. '-' .'           ")
	centerPrint("           '---'             '---'             ")
	centerPrint("                                               ")
	centerPrint("    _...----...    ...   ...    ...----..._    ")
	centerPrint(" .-'__..-\"\"'----  '.  '\"'  .'  ----'\"\"-..__'-. ")
	centerPrint("'.-'   _.--\"\"\"'     '-._.-'     '\"\"\"--._   '-.'")
	centerPrint("'  .-\"'                :                '\"-.  '")
	centerPrint("  '   '.            _.'\"'._            .'   '  ")
	centerPrint("        '.     ,.-'\"       \"'-.,     .'        ")
	centerPrint("          '.                       .'          ")
	centerPrint("            '-._               _.-'            ")
	centerPrint("                '\"'--.....--'\"'                ")
	print("")
	centerPrint("Firewolf Kitteh is Not Amused...")
	sleep(6)
	os.shutdown()
end

errPages.overspeed = function()
	website = "overspeed"
	clearPage("overspeed", colors[theme["background"]])
	print("\n")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("Warning! D:")
	centerPrint(string.rep(" ", 43))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	centerPrint(string.rep(" ", 43))
	centerPrint("  Website browsing sleep limit reached!    ")
	centerPrint(string.rep(" ", 43))
	centerPrint("  To prevent Firewolf from spamming        ")
	centerPrint("  rednet, Firewolf has stopped loading     ")
	centerPrint("  the page.                                ")
	centerPrint(string.rep(" ", 43))
	centerPrint(string.rep(" ", 43))
	centerPrint(string.rep(" ", 43))
	openAddressBar = false
	for i = 1, 5 do
		term.setCursorPos(1, 14)
		centerWrite(string.rep(" ", 43))
		if 6 - i == 1 then centerWrite("Please wait 1 second...")
		else centerWrite("Please wait " .. tostring(6 - i) .. " seconds...") end
		sleep(1)
	end
	openAddressBar = true

	term.setCursorPos(1, 14)
	centerWrite(string.rep(" ", 43))
	centerWrite("You may now browse normally...")
end

errPages.crash = function(err)
	clearPage("crash", colors[theme["background"]])
	print("")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("The Website Has Crashed! D:")
	centerPrint(string.rep(" ", 43))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("It looks like the website has crashed!")
	centerWrite(string.rep(" ", 43))
	centerPrint("Report this error to the website owner:")
	centerPrint(string.rep(" ", 43))
	term.setBackgroundColor(colors[theme["background"]])
	print("")
	print("  " .. err)
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("You may now browse normally!")
	centerPrint(string.rep(" ", 43))
end

errPages.checkForModem = function()
	while true do
		local present = false
		for _, v in pairs(rs.getSides()) do
			if peripheral.getType(v) == "modem" then
				rednet.open(v)
				present = true
				break
			end
		end

		if not(present) then
			website = "nomodem"
			clearPage("nomodem", colors[theme["background"]])
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
			if term.isColor() then centerPrint("Click to exit...")
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

errPages.blacklistRedirectionBots = function()
	local suspected = {}
	local alphabet = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", 
				      "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "."}
	local name = ""
	for i = 1, math.random(1,3) do
		name = ""
		for d = 1, math.random(6, 17) do
			name = name .. alphabet[math.random(1, 27)]
		end
		rednet.broadcast(name)
		sleep(timeout)
	end

	for i = 1, 4 do
		name = ""
		for d = 1, math.random(6, 17) do
			name = name .. alphabet[math.random(1, 27)]
		end

		local finishCheck = false
		rednet.broadcast(name)
		clock = os.clock()
		for i = 1, 5 do
			while os.clock() - clock < timeout do
				local id = rednet.receive(timeout)
				if id ~= nil and not(verify("blacklist", id)) then
					name = ""
					for d = 1, math.random(6, 17) do
						name = name .. alphabet[math.random(1, 27)]
					end

					local inSuspected = false
					for b = 1, #suspected do
						if suspected[b][1] == id then
							suspected[b][2] = suspected[b][2] + 1
							inSuspected = true
						end
					end

					if not(inSuspected) then
						table.insert(suspected, {id, 1})
						break
					end
				elseif id == nil then 
					finishCheck = true
					break
				end
			end
			if finishCheck then break end
		end
		if finishCheck then break end
	end

	for i = 1, #suspected do
		if suspected[i][2] > 2 then
			local f = io.open(userBlacklist, "a")
			f:write(tostring(suspected[i][1]) .. "\n")
			f:close()
			table.insert(blacklist, tostring(suspected[i][1]))
		end
	end
end

local function loadSite(site)
	local function runSite(cacheLoc)
		-- Clear
		clearPage(site, colors.black)
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)

		-- Setup environment
		local curBackgroundColor = colors.black
		local nenv = {}
		for k, v in pairs(getfenv(0)) do nenv[k] = v end
		for k, v in pairs(getfenv(1)) do nenv[k] = v end
		nenv.term = {}
		--nenv.os = {}
		nenv.shell = {}

		nenv.term.getSize = function()
			local wid, hei = env.term.getSize()
			return wid, hei - 1
		end

		nenv.term.setCursorPos = function(x, y)
			return env.term.setCursorPos(x, y + 1)
		end

		nenv.term.getCursorPos = function()
			local x, y = env.term.getCursorPos()
			return x, y + 1
		end

		nenv.term.clear = function()
			local x, y = env.term.getCursorPos()
			local a = api.clearPage(website, curBackgroundColor)
			env.term.setCursorPos(x, y)
			return a
		end

		nenv.term.setBackgroundColor = function(col)
			curBackgroundColor = col
			return env.term.setBackgroundColor(col)
		end

		nenv.term.setBackgroundColour = function(col)
			curBackgroundColor = col
			return env.term.setBackgroundColour(col)
		end

		nenv.term.getBackgroundColor = function()
			return curBackgroundColor
		end

		nenv.term.getBackgroundColour = function()
			return curBackgroundColor
		end

		nenv.term.setTextColor = function(col)
			return env.term.setTextColor(col)
		end

		nenv.term.setTextColour = function(col)
			return env.term.setTextColour(col)
		end

		nenv.term.getTextColour = function()
			return env.term.getTextColour()
		end

		nenv.term.getTextColor = function()
			return env.term.getTextColor()
		end

		nenv.term.write = function(text)
			return env.term.write(text)
		end

		nenv.write = function(text)
			return env.write(text)
		end

		nenv.print = function(text)
			return env.print(text)
		end

		local oldScroll = term.scroll
		term.scroll = function(n)
			local x, y = env.term.getCursorPos()
			oldScroll(n)
			clearPage(website, curBackgroundColor, true)
			env.term.setCursorPos(x, y)
		end

		nenv.redirect = function(url)
			api.redirect(url)
			env.error()
		end

		nenv.loadImageFromServer = function(image)
			sleep(0.1)
			local mid, msgImage = curProtocol.getWebsite(site.."/"..image)
			if mid then
				--debugLog("ID: " .. tostring(mid))
				--debugLog("Temp Image Data: " .. msgImage)
				local f = env.io.open("/.Firewolf_Data/tempImage", "w")
				f:write(msgImage)
				f:close()
				local rImage = env.paintutils.loadImage("/.Firewolf_Data/tempImage")
				fs.delete("/.Firewolf_Data/tempImage")
				return rImage
			end
			return nil
		end

		nenv.ioReadFileFromServer = function(file)
			sleep(0.1)
			local mid, msgFile = curProtocol.getWebsite(site.."/"..file)
			if mid then
				--debugLog("ID: " .. tostring(mid))
				--debugLog("Temp File Data: " .. msgFile)
				local f = env.io.open("/.Firewolf_Data/tempFile", "w")
				f:write(msgFile)
				f:close()
				local rFile = env.io.open("/.Firewolf_Data/tempFile", "r")
				return rFile
			end
			return nil
		end
		--[[

		nenv.getCookie = function(cookieId)
			env.rednet.send(id, textutils.serialize({"getCookie", cookieId}))
			local startClock = os.clock()
			while os.clock() - startClock < 0.1 do
				local mid, status = env.rednet.receive(0.1)
				if mid == id then
					if status == "[$notexist$]" then
						return false
					elseif env.string.find(status, "[$cookieData$]") then
						return env.string.gsub(status, "[$cookieData$]", "")
					end
				end
			end
			return false
		end

		nenv.createCookie = function(cookieId)
			env.rednet.send(id, textutils.serialize({"createCookie", cookieId}))
			local startClock = os.clock()
			while os.clock() - startClock < 0.1 do
				local mid, status = env.rednet.receive(0.1)
				if mid == id then
					if status == "[$notexist$]" then
						return false
					elseif env.string.find(status, "[$cookieData$]") then
						return env.string.gsub(status, "[$cookieData$]", "")
					end
				end
			end
			return false
		end

		nenv.deleteCookie = function(cookieId)

		end]]

		nenv.shell.run = function(file, ...)
			if file == "clear" then
				api.clearPage(website, curBackgroundColor)
				env.term.setCursorPos(1, 2)
			else
				env.shell.run(file, unpack({...}))
			end
		end

		nenv.os.pullEvent = function(a)
			while true do
				if a == "derp" then return true end
				local e, p1, p2, p3, p4, p5 = env.os.pullEventRaw(a)
				if e == event_exitWebsite then
					debugLog("Exiting Website Event")
					env.error(event_exitWebsite)
				elseif e == "terminate" then
					env.error()
				end

				if e ~= event_exitWebsite and e ~= event_redirect and e ~= event_exitApp 
						and e ~= event_loadWebsite then
					if a then
						if e == a then return e, p1, p2, p3, p4, p5 end
					else return e, p1, p2, p3, p4, p5 end
				end
			end
		end

		-- Run
		local fn, err = loadfile(cacheLoc)
		if fn and err == nil then
			setfenv(fn, nenv)
			_, err = pcall(fn)
			setfenv(1, env)
		end
		debugLog("Exiting Website Properly")
		-- Catch website error
		if err and not(err:find(event_exitWebsite)) then errPages.crash(err) end
	end

	-- Draw
	openAddressBar = false
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	print("\n\n")
	centerPrint("Connecting...")

	-- Redirection bots
	errPages.blacklistRedirectionBots()
	loadingRate = loadingRate + 1

	-- Get website
	local id, content, status = curProtocol.getWebsite(site)

	-- Display website
	local cacheLoc = cacheFolder .. "/" .. site:gsub("/", "$slazh$")
	if id ~= nil then
		openAddressBar = true
		if status == "antivirus" then
			local offences = verify("antivirus offences", content)
			if #offences > 0 then
				clearPage(site, colors[theme["background"]])
				print("")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("Antivirus Triggered!")
				centerPrint(string.rep(" ", 47))
				print("")

				term.setBackgroundColor(colors[theme["bottom-box"]])
				centerPrint(string.rep(" ", 47))
				centerPrint("  The antivirus has been triggered on this     ")
				centerPrint("  website! Do you want to give this website    ")
				centerPrint("  permissions to:                              ")
				for i = 1, 8 do centerPrint(string.rep(" ", 47)) end
				for i, v in ipairs(offences) do
					if i > 3 then term.setCursorPos(w - 21, i + 8)
					else term.setCursorPos(6, i + 11) end
					write("[ " .. v)
				end

				local opt = prompt({{"Allow", 6, 17}, {"Cancel", w - 16, 17}}, "horizontal")
				if opt == "Allow" then
					status = "safe"
				elseif opt == "Cancel" then
					clearPage(site, colors[theme["background"]])
					print("")
					term.setTextColor(colors[theme["text-color"]])
					term.setBackgroundColor(colors[theme["top-box"]])
					centerPrint(string.rep(" ", 47))
					centerWrite(string.rep(" ", 47))
					centerPrint("O Noes!")
					centerPrint(string.rep(" ", 47))
					print("")

					term.setBackgroundColor(colors[theme["bottom-box"]])
					centerPrint(string.rep(" ", 47))
					centerPrint("         ______                          __    ")
					centerPrint("        / ____/_____ _____ ____   _____ / /    ")
					centerPrint("       / __/  / ___// ___// __ \\ / ___// /     ")
					centerPrint("      / /___ / /   / /   / /_/ // /   /_/      ")
					centerPrint("     /_____//_/   /_/    \\____//_/   (_)       ")
					centerPrint(string.rep(" ", 47))
					centerPrint("  Could not connect to the website! The        ")
					centerPrint("  website was not given enough permissions to  ")
					centerPrint("  execute properly!                            ")
					centerPrint(string.rep(" ", 47))
				elseif opt == nil then
					os.queueEvent(event_exitWebsite)
					return
				end
			else
				status = "safe"
			end
		end

		if status == "safe" and site ~= "" then
			local f = io.open(cacheLoc, "w")
			f:write(content)
			f:close()
			runSite(cacheLoc)
			return
		end
	else
		if fs.exists(cacheLoc) and site ~= "" and site ~= "." and site ~= ".." and
				not(verify("blacklist", site)) then
			openAddressBar = true
			clearPage(site, colors[theme["background"]])
			print("")
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Cache Exists!")
			centerPrint(string.rep(" ", 47))
			print("")

			term.setBackgroundColor(colors[theme["bottom-box"]])
			centerPrint(string.rep(" ", 47))
			centerPrint("       ______              __            __    ")
			centerPrint("      / ____/____ _ _____ / /_   ___    / /    ")
			centerPrint("     / /    / __ '// ___// __ \\ / _ \\  / /     ")
			centerPrint("    / /___ / /_/ // /__ / / / //  __/ /_/      ")
			centerPrint("    \\____/ \\__,_/ \\___//_/ /_/ \\___/ (_)       ")
			centerPrint(string.rep(" ", 47))
			centerPrint("  Could not connect to the website! It may be  ")
			centerPrint("  down, or not exist! A cached version was     ")
			centerPrint("  found!                                       ")
			centerPrint(string.rep(" ", 47))
			centerPrint(string.rep(" ", 47))

			local opt = prompt({{"Load Cache", 6, 17}, {"Cancel", w - 16, 17}}, "horizontal")
			if opt == "Load Cache" then
				runSite(cacheLoc)
				return
			elseif opt == "Cancel" then
				clearPage(site, colors[theme["background"]])
				print("\n")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("O Noes!")
				centerPrint(string.rep(" ", 47))
				print("")

				term.setBackgroundColor(colors[theme["bottom-box"]])
				centerPrint(string.rep(" ", 47))
				centerPrint("         ______                          __    ")
				centerPrint("        / ____/_____ _____ ____   _____ / /    ")
				centerPrint("       / __/  / ___// ___// __ \\ / ___// /     ")
				centerPrint("      / /___ / /   / /   / /_/ // /   /_/      ")
				centerPrint("     /_____//_/   /_/    \\____//_/   (_)       ")
				centerPrint(string.rep(" ", 47))
				centerPrint("  Could not connect to the website! The        ")
				centerPrint("  cached version was not loaded!               ")
				centerPrint(string.rep(" ", 47))
			elseif opt == nil then
				os.queueEvent(event_exitWebsite)
				return
			end
		else
			local res = curProtocol.getSearchResults(site)

			openAddressBar = true
			if #res > 0 then
				clearPage(site, colors[theme["background"]])
				print("")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				if #res == 1 then centerPrint("1 Search Result")
				else centerPrint(#res .. " Search Results") end
				centerPrint(string.rep(" ", 47))
				print("")

				term.setBackgroundColor(colors[theme["bottom-box"]])
				for i = 1, 12 do centerPrint(string.rep(" ", 47)) end
				local opt = scrollingPrompt(res, 4, 8, 10, 43)
				if opt then
					redirect(opt:gsub("rdnt://", ""))
					return
				else
					os.queueEvent(event_exitWebsite)
					return
				end
			elseif site == "" and #res == 0 then
				clearPage(site, colors[theme["background"]])
				print("\n\n")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("No Websites are Currently Online! D:")
				centerPrint(string.rep(" ", 47))
			else
				clearPage(site, colors[theme["background"]])
				print("\n")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("O Noes!")
				centerPrint(string.rep(" ", 47))
				print("")
				term.setBackgroundColor(colors[theme["bottom-box"]])
				centerPrint(string.rep(" ", 47))
				centerPrint("         ______                          __    ")
				centerPrint("        / ____/_____ _____ ____   _____ / /    ")
				centerPrint("       / __/  / ___// ___// __ \\ / ___// /     ")
				centerPrint("      / /___ / /   / /   / /_/ // /   /_/      ")
				centerPrint("     /_____//_/   /_/    \\____//_/   (_)       ")
				centerPrint(string.rep(" ", 47))
				if verify("blacklist", id) then
					centerPrint("  Could not connect to the website! It has     ")
					centerPrint("  been blocked by a database admin!            ")
				else
					centerPrint("  Could not connect to the website! It may     ")
					centerPrint("  be down, or not exist!                       ")
				end
				centerPrint(string.rep(" ", 47))
			end
		end
	end
end


--  -------- Websites

local function websiteMain()
	-- Variables
	local loadingClock = os.clock()

	-- Main loop
	while true do
		-- Reset
		setfenv(1, backupEnv)
		browserAgent = browserAgentTemplate
		clearPage(website)
		w, h = term.getSize()
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)

		-- Exit
		if website == "exit" then
			os.queueEvent(event_exitApp)
			return
		end

		-- Perform Checks
		local skip = false
		local oldWebsite = website
		if not(errPages.checkForModem()) then
			os.queueEvent(event_exitApp)
			return
		end
		website = oldWebsite
		if os.clock() - loadingClock > 5 then
			loadingRate = 0
			loadingClock = os.clock()
		elseif loadingRate >= 8 then
			errPages.overspeed()
			loadingClock = os.clock()
			loadingRate = 0
			skip = true
		end if not(skip) then
			appendToHistory(website)

			-- Render site
			clearPage(website)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			if pages[website] then 
				local ex = pages[website](website)
				if ex == true then 
					os.queueEvent(event_exitApp)
					return
				end
			else
				loadSite(website)
			end
		end

		-- Wait
		os.pullEvent(event_exitWebsite)
		os.pullEvent(event_loadWebsite)
	end
end


--  -------- Address Bar

local function retrieveSearchResults()
	curSites = curProtocol.getSearchResults("")
	while true do
		local e = os.pullEvent()
		if website ~= "exit" and e == event_loadWebsite then
			curSites = curProtocol.getSearchResults("")
		elseif e == event_exitApp then
			os.queueEvent(event_exitApp)
			return
		end
	end
end

local function addressBarRead()
	local len = 4
	local list = {}

	local function draw(l)
		local ox, oy = term.getCursorPos()
		for i = 1, len do
			term.setTextColor(colors[theme["address-bar-text"]])
			term.setBackgroundColor(colors[theme["address-bar-background"]])
			term.setCursorPos(1, i + 1)
			write(string.rep(" ", w))
		end
		if theme["address-bar-base"] then term.setBackgroundColor(colors[theme["address-bar-base"]])
		else term.setBackgroundColor(colors[theme["bottom-box"]]) end
		term.setCursorPos(1, len + 2)
		write(string.rep(" ", w))
		term.setBackgroundColor(colors[theme["address-bar-background"]])

		for i, v in ipairs(l) do
			term.setCursorPos(2, i + 1)
			write(v)
		end
		term.setCursorPos(ox, oy)
	end

	local function onLiveUpdate(cur, e, but, x, y, p4, p5)
		if e == "char" or e == "update_history" or e == "delete" then
			list = {}
			for _, v in pairs(curSites) do
				if #list < len and v:gsub("rdnt://", ""):find(cur:lower(), 1, true) then
					table.insert(list, v)
				end
			end
			table.sort(list)
			table.sort(list, function(a, b)
				local _, ac = a:gsub("rdnt://", ""):gsub(cur:lower(), "")
				local _, bc = b:gsub("rdnt://", ""):gsub(cur:lower(), "")
				return ac > bc
			end)
			draw(list)
			return false, nil
		elseif e == "mouse_click" then
			for i = 1, len do
				if y == i + 1 then
					return true, list[i]:gsub("rdnt://", "")
				end
			end
		end
	end

	onLiveUpdate("", "delete", nil, nil, nil, nil, nil)
	return modRead(nil, addressBarHistory, 41, false, onLiveUpdate)
end

local function addressBarMain()
	while true do
		local e, but, x, y = os.pullEvent()
		if (e == "key" and (but == 29 or but == 157)) or 
				(e == "mouse_click" and y == 1) then
			if openAddressBar then
				-- Exit
				os.queueEvent(event_exitWebsite)
				debugLog("Address bar activated")

				-- Read
				term.setBackgroundColor(colors[theme["address-bar-background"]])
				term.setTextColor(colors[theme["address-bar-text"]])
				term.setCursorPos(2, 1)
				term.clearLine()
				write("rdnt://")
				local oldWebsite = website
				website = addressBarRead()
				if website == nil then
					website = oldWebsite
				elseif website == "home" or website == "homepage" then
					website = homepage
				end

				-- Load
				os.queueEvent(event_loadWebsite)
			end
		elseif e == event_redirect then
			if openAddressBar then
				-- Redirect
				os.queueEvent(event_exitWebsite)
				if but == "home" or but == "homepage" then website = homepage
				else website = but end
				os.queueEvent(event_loadWebsite)
			end
		elseif e == event_exitApp then
			os.queueEvent(event_exitApp)
			break
		end
	end
end


--  -------- Main

--  centerPrint([[          ______ ____ ____   ______            ]])
--  centerPrint([[ ------- / ____//  _// __ \ / ____/            ]])
--  centerPrint([[ ------ / /_    / / / /_/ // __/               ]])
--  centerPrint([[ ----- / __/  _/ / / _  _// /___               ]])
--  centerPrint([[ ---- / /    /___//_/ |_|/_____/               ]])
--  centerPrint([[ --- / /       _       __ ____   __     ______ ]])
--  centerPrint([[ -- /_/       | |     / // __ \ / /    / ____/ ]])
--  centerPrint([[              | | /| / // / / // /    / /_     ]])
--  centerPrint([[              | |/ |/ // /_/ // /___ / __/     ]])
--  centerPrint([[              |__/|__/ \____//_____//_/        ]])

local function main()
	-- Logo
	term.setBackgroundColor(colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.clear()
	term.setCursorPos(1, 2)
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 47))
	centerPrint([[                    _...._                     ]])
	centerPrint([[                  .::o:::::.                   ]])
	centerPrint([[                 .:::'''':o:.                  ]])
	centerPrint([[                 :o:_    _:::                  ]])
	centerPrint([[                 `:(_>()<_):'                  ]])
	centerPrint([[                   `'//\\''                    ]])
	centerPrint([[                    //  \\                     ]])
	centerPrint([[                   /'    '\                    ]])
	centerPrint([[                                               ]])
	centerPrint([[      Merry Christmas! -The Firewolf Team      ]])
	centerPrint(string.rep(" ", 47))
	print("\n")
	term.setBackgroundColor(colors[theme["bottom-box"]])

	-- Download Files
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Downloading Required Files...")
	centerWrite(string.rep(" ", 47))
	checkGitHub()
	migrateFilesystem()
	resetFilesystem()

	-- Download Databases
	local x, y = term.getCursorPos()
	term.setCursorPos(1, y - 1)
	centerWrite(string.rep(" ", 47))
	centerWrite("Downloading Databases...")
	loadDatabases()

	-- Load Settings
	centerWrite(string.rep(" ", 47))
	centerWrite("Loading Data...")
	local f = io.open(settingsLocation, "r")
	local a = textutils.unserialize(f:read("*l"))
	autoupdate = a.auto
	incognito = a.incog
	homepage = a.home
	curProtocol = protocols.rdnt
	f:close()

	-- Load history
	local b = io.open(historyLocation, "r")
	history = textutils.unserialize(b:read("*l"))
	b:close()

	-- Update
	centerWrite(string.rep(" ", 47))
	centerWrite("Checking For Updates...")
	if autoupdate == "true" then updateClient() end

	-- Modem
	if not(errPages.checkForModem()) then return end
	website = homepage

	-- Run
	parallel.waitForAll(addressBarMain, websiteMain, retrieveSearchResults)
end

local function startup()
	-- HTTP API
	if not(http) then
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 2)
		term.setBackgroundColor(colors[theme["top-box"]])
		api.centerPrint(string.rep(" ", 47))
		api.centerWrite(string.rep(" ", 47))
		api.centerPrint("HTTP API Not Enabled! D:")
		api.centerPrint(string.rep(" ", 47))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		api.centerPrint(string.rep(" ", 47))
		api.centerPrint("  Firewolf is unable to run without the HTTP   ")
		api.centerPrint("  API Enabled! Please enable it in the CC     ")
		api.centerPrint("  Config!                                     ")
		api.centerPrint(string.rep(" ", 47))

		api.centerPrint(string.rep(" ", 47))
		api.centerWrite(string.rep(" ", 47))
		if term.isColor() then api.centerPrint("Click to exit...")
		else api.centerPrint("Press any key to exit...") end
		api.centerPrint(string.rep(" ", 47))

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
		api.centerPrint("Advanced Comptuer Required!")
		print("\n")
		api.centerPrint("This version of Firewolf requires")
		api.centerPrint("an Advanced Comptuer to run!")
		print("")
		api.centerPrint("Turtles may not be used to run")
		api.centerPrint("Firewolf! :(")
		print("")
		api.centerPrint("Press any key to exit...")

		os.pullEvent("key")
		return false
	end

	-- Run
	local _, err = pcall(main)
	if err ~= nil then
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 2)
		term.setBackgroundColor(colors[theme["top-box"]])
		api.centerPrint(string.rep(" ", 47))
		api.centerWrite(string.rep(" ", 47))
		api.centerPrint("Firewolf has Crashed! D:")
		api.centerPrint(string.rep(" ", 47))
		print("")
		term.setBackgroundColor(colors[theme["background"]])
		print("")
		print("  " .. err)
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		api.centerPrint(string.rep(" ", 47))
		api.centerPrint("  Please report this error to 1lann or         ")
		api.centerPrint("  GravityScore so we are able to fix it!       ")
		api.centerPrint("  If this problem persists, try deleting       ")
		api.centerPrint("  " .. rootFolder .. "                              ")
		api.centerPrint(string.rep(" ", 47))
		api.centerWrite(string.rep(" ", 47))
		if term.isColor() then api.centerPrint("Click to exit...")
		else api.centerPrint("Press any key to exit...") end
		api.centerPrint(string.rep(" ", 47))

		while true do
			local e, but, x, y = os.pullEvent()
			if e == "mouse_click" or e == "key" then break end
		end

		return false
	end

	return true
end

-- Theme
if not(term.isColor()) then 
	theme = originalTheme
else
	theme = loadTheme(themeLocation)
	if theme == nil then theme = defaultTheme end
end

-- Debugging
if #tArgs > 0 and tArgs[1] == "debug" then
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setCursorPos(1, 4)
	api.centerPrint(string.rep(" ", 43))
	api.centerWrite(string.rep(" ", 43))
	api.centerPrint("Debug Mode Enabled...")
	api.centerPrint(string.rep(" ", 43))

	if fs.exists("/firewolf-log") then debugFile = io.open("/firewolf-log", "a")
	else debugFile = io.open("/firewolf-log", "w") end
	debugFile:write("\n-- [" .. textutils.formatTime(os.time()) .. "] New Log --")
	sleep(1.8)
end

-- Start
startup()

fs.delete("/.Firewolf_Data/tempFile")

-- Exit Message
if term.isColor() then
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
end
term.setCursorBlink(false)
term.clear()

if not(fs.exists("/.var/settings")) then
	term.setCursorPos(1, 1)
	api.centerPrint("Thank You for Using Firewolf " .. version)
	api.centerPrint("Made by 1lann and GravityScore")
	term.setCursorPos(1, 3)
else
	term.setBackgroundColor(colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.clear()
	term.setCursorPos(1, 5)
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	api.centerPrint("Thank You for Using Firewolf " .. version)
	api.centerPrint("Made by 1lann and GravityScore")
	print("")
	if term.isColor() then api.centerPrint("Click to exit...")
	else api.centerPrint("Press any key to exit...") end

	while true do
		local e = os.pullEvent()
		if e == "mouse_click" or e == "key" then break end
	end
end

-- Close
for _, v in pairs(rs.getSides()) do rednet.close(v) end
if debugFile then debugFile:close() end

-- Reset Environment
setfenv(1, oldEnv)
