
--  -------- Mozilla Firefox
--  -------- Made by GravityScore and 1lann

--  -------- Original Idea from Rednet Explorer v2.4.1
--  -------- Rednet Explorer made by xXm0dzXx/CCFan11



--  -------- Global Variables

local exitApp = false
local finishExit = false
local exitWebsite = false

-- Encase in function
local function entiretyFirefox()


--  -------- Constants

-- Version
local firefoxVersion = "1.4.6"
local browserAgentTemplate = "Mozilla Firefox " .. firefoxVersion
browserAgent = ""

-- Server Identification
local serverID = "m0dz"
local serverList = {m0dz = "Hacker's Paradise", immibis = "turtle.dig()", ctcraft = "CTCraft", 
					geevancraft = "GeevanCraft", experimental = "Experimental", 
					other = "Other", old = "None"}

-- Updating
local autoupdate = "true"
local incognito = "false"
local debugging = false
local override = false

-- Dropbox URLs
local firefoxURL = "http://dl.dropbox.com/u/97263369/firefox/entities/" .. serverID .. ".lua"
local databaseURL = "http://dl.dropbox.com/u/97263369/firefox/databases/" .. serverID .. "-database.txt"
local serverURL = "http://dl.dropbox.com/u/97263369/firefox/firefox-server.lua"

-- Events
local openURLBarEvent = "firefox_open_url_bar_event"
local websiteLoadEvent = "firefox_website_loaded_event"
local exitFirefoxEvent = "firefox_exit_program_event"

-- Webpage Variables
local website = ""
local homepage = ""
local site = "home"
local history = {}
local searchBarHistory = {}
local websiteLoadingRate = 0
local loadingRateClock = os.clock()
local timeout = 0.05
local userTerminated = false
local errorMessage = nil
local lockCtrl = false
local secureRedirection = nil

-- Prevent API Overrides
local function copyTable(oldTable)
	local oldTable = oldTable
	local newTable = {}
	for k,v in pairs(oldTable) do
		newTable[k] = v
	end
	return newTable
end

local fparallel = copyTable(parallel)
local fstring = copyTable(string)
local frednet = copyTable(rednet)
local ftable = copyTable(table)
local fhttp = copyTable(http)
local ftextutils = copyTable(textutils)
local fos = copyTable(os)
local fterm = copyTable(term)
local fshell = copyTable(shell)
local ffs = copyTable(fs)
local fio = copyTable(io)
local fperipheral = copyTable(peripheral)
local fmath = copyTable(math)
local fcoroutine = copyTable(coroutine)
local fcolors = copyTable(colors)
local ftostring = tostring
local ftonumber = tonumber
local fpairs = pairs
local fipairs = ipairs
local fpcall = pcall
local fsleep = sleep
local fprint = print
local fwrite = write
local ferror = error
local securePastebinDownload = nil
local secureUrlDownload = nil

-- Databases
local blacklistDatabase = {}
local whitelistDatabase = {}
local verifiedDatabase = {}
local antivirusDefinitions = {}
local downloadDatabase = {}

-- Data Locations
local rootFolder = "/.Firefox_Data"
local cacheFolder = rootFolder .. "/cache"
local serverFolder = rootFolder .. "/servers"
local serverSoftwareLocation = rootFolder .. "/server_software"
local settingsLocation = rootFolder .. "/settings"
local historyLocation = rootFolder .. "/history"
local firefoxLocation = "/" .. fshell.getRunningProgram()

local userBlacklist = rootFolder .. "/user_blacklist"
local userWhitelist = rootFolder .. "/user_whitelist"
local globalDatabase = rootFolder .. "/database"

-- Firefox 1.3 Support
local runningWebsite = ""


--  -------- Drawing

local function titleForPage(site)
	-- Preset titles
	local siteTitles = {{"firefox", "Mozilla Firefox"}, {"history", "Firefox History"}, 
						{"server", "Server Management"}, {"help", "Firefox Help"}, 
						{"settings", "Firefox Settings"}, {"getinfo", "Website Information"}, 
						{"downloads", "Download Center"}, {"credits", "Firefox Credits"}}

	-- Search
	for i = 1, #siteTitles do
		if fstring.lower(siteTitles[i][1]) == fstring.lower(site) then
			return siteTitles[i][2]
		end
	end

	return nil
end

local function clearPage(url)
	-- URL
	local w, h = fterm.getSize()
	local title = titleForPage(url)
	fterm.clear()
	fterm.setCursorPos(2, 1)
	fterm.clearLine()
	fwrite("rdnt://" .. url)

	-- Title
	if title ~= nil then
		fterm.setCursorPos(w - fstring.len("  " .. title), 1)
		fwrite("  " .. title)
	end

	-- Line
	fterm.setCursorPos(1, 2)
	fterm.clearLine()
	if fterm.setTextColor then
		fterm.setCursorPos(1, 2)
	else
		fterm.setCursorPos(1, 1)
	end
	fwrite(fstring.rep("-", w))
	fprint(" ")
end

local function restoreFunctions()
	redirect = secureRedirection
	peripheral = copyTable(fperipheral)
	browserAgent = browserAgentTemplate
	pastebinDownload = securePastebinDownload
	urlDownload = secureUrlDownload
	string = copyTable(fstring)
	shell = copyTable(fshell)
	term = copyTable(fterm)

	function compatability()
		term = copyTable(fterm)
		shell = copyTable(fshell)
	end

	function centerPrint(text)
		local w, h = fterm.getSize()
		local x, y = fterm.getCursorPos()
		fterm.setCursorPos(fmath.ceil((w + 1)/2 - text:len()/2), y)
		fprint(text)
	end

	function centerWrite(text)
		local w, h = fterm.getSize()
		local x, y = fterm.getCursorPos()
		fterm.setCursorPos(fmath.ceil((w + 1)/2 - text:len()/2), y)
		fwrite(text)
	end

	function leftPrint(text)
		local x, y = fterm.getCursorPos()
		fterm.setCursorPos(4, y)
		fprint(text)
	end

	function leftWrite(text)
		local x, y = fterm.getCursorPos()
		fterm.setCursorPos(4, y)
		fwrite(text)
	end

	function rightPrint(text)
		local x, y = fterm.getCursorPos()
		local w, h = fterm.getSize()
		fterm.setCursorPos(w - text:len() - 1, y)
		fprint(text)
	end

	function rightWrite(text)
		local x, y = fterm.getCursorPos()
		local w, h = fterm.getSize()
		fterm.setCursorPos(w - text:len() - 1, y)
		fwrite(text)
	end

	function cPrint(text)
		centerPrint(text)
	end

	function cWrite(text)
		centerWrite(text)
	end

	function lPrint(text)
		leftWrite(text)
	end

	function lWrite(text)
		leftWrite(text)
	end

	function rPrint(text)
		rightWrite(text)
	end

	function rWrite(text)
		rightWrite(text)
	end

	function reDirect(site)
		redirect(site)
	end

	function clearArea()
		clearPage(runningWebsite)
	end

	function lockControl()
		lockCtrl = true
	end

	function unlockControl()
		lockCtrl = false
	end
end


--  -------- Prompt Software

local prompt_defaultTextColor = fcolors.white
local prompt_defaultBackgroundColor = nil
function prompt(list, nc)
	-- Draw
	for _, v in fpairs(list) do
		if v.textcolor then fterm.setTextColor(v.textcolor)
		else fterm.setTextColor(prompt_defaultTextColor) end
		if v.bgcolor then fterm.setBackgroundColor(v.bgcolor)
		elseif prompt_defaultBackgroundColor then 
			fterm.setBackgroundColor(prompt_defaultBackgroundColor) 
		end

		local w, h = fterm.getSize()
		if v[2] == -1 then v[2] = fmath.ceil(w/2 - v[1]:len()/2) end

		fterm.setCursorPos(v[2] - 1, v[3])
		write("[ " .. v[1])
		fterm.setCursorPos(v[2] + v[1]:len() + 2, v[3])
		write("]")
	end

	-- Wait for click
	while not(exitApp) do
		local e, key, x, y = fos.pullEvent()

		if e == "mouse_click" then
			if (y == 1 or y == 2) and nc ~= true then
				fos.queueEvent(openURLBarEvent)
				return nil
			else
				for _, v in fpairs(list) do
					if x >= v[2] - 1 and x <= v[2] + v[1]:len() + 2 and y == v[3] then
						return v[1]
					end
				end
			end
		elseif e == "key" and (key == 29 or key == 157) then
			if nc ~= true then
				fos.queueEvent(openURLBarEvent)
				return nil
			end
		end
	end
end

local scrollingPrompt_textColor = fcolors.white
local scrollingPrompt_backgroundColor = fcolors.black
local scrollingPrompt_scrollBarColor = fcolors.white
local function scrollingPrompt(list, x, y, len)
	local w, h = fterm.getSize()

	-- Functions
	local function drawItems(items)
		for i, v in fipairs(items) do
			fterm.setTextColor(scrollingPrompt_textColor)
			fterm.setBackgroundColor(scrollingPrompt_backgroundColor)

			fterm.setCursorPos(x, y + i)
			fterm.clearLine()
			local a = v
			if v:len() > w - (x + 9) then a = v:sub(1, w - (x + 9) - 3) .. "..." end
			write("[ " .. a)
			
			fterm.setCursorPos(w - 5, y + i)
			fterm.setTextColor(scrollingPrompt_scrollBarColor)
			write(".")
			fterm.setCursorPos(w - 3, y + i)
			fterm.setTextColor(scrollingPrompt_textColor)
			write("]")
		end

		fterm.setCursorPos(w - 5, y + 1)
		fterm.setTextColor(scrollingPrompt_scrollBarColor)
		write("o")
		fterm.setCursorPos(w - 3, y + 1)
		fterm.setTextColor(scrollingPrompt_textColor)
		write("]")
	end

	local function updateDisplayList(items, loc, len)
		local ret = {}
		for i = 1, len do
			local item = items[i + loc - 1]
			if item ~= nil then ftable.insert(ret, item) end
		end

		return ret
	end

	-- Variables
	local loc = 1
	local disList = updateDisplayList(list, loc, len)
	drawItems(disList)

	-- Pull Event
	while true do
		local e, key, clx, cly = fos.pullEvent()

		if e == "mouse_click" then
			if cly == 1 or cly == 2 then
				fos.queueEvent(openURLBarEvent)
				return nil, true
			else
				for i, v in fipairs(disList) do
					if clx >= x and clx <= w - 3 and cly == i + y then
						return v, false
					end
				end
			end
		elseif e == "key" then
			if key == 200 then
				if loc > 1 then
					loc = loc - 1
					disList = updateDisplayList(list, loc, len)
					drawItems(disList)
				end
			elseif key == 208 then
				if loc + len - 1 < #list then
					loc = loc + 1
					disList = updateDisplayList(list, loc, len)
					drawItems(disList)
				end
			elseif key == 29 or key == 157 then
				fos.queueEvent(openURLBarEvent)
				return nil, true
			end
		end
	end
end


--  -------- Drawing Utilities

function centerPrint(text)
	local w, h = fterm.getSize()
	local x, y = fterm.getCursorPos()
	fterm.setCursorPos(fmath.ceil((w + 1)/2 - text:len()/2), y)
	fprint(text)
end

function centerWrite(text)
	local w, h = fterm.getSize()
	local x, y = fterm.getCursorPos()
	fterm.setCursorPos(fmath.ceil((w + 1)/2 - text:len()/2), y)
	fwrite(text)
end

function leftPrint(text)
	local x, y = fterm.getCursorPos()
	fterm.setCursorPos(4, y)
	fprint(text)
end

function leftWrite(text)
	local x, y = fterm.getCursorPos()
	fterm.setCursorPos(4, y)
	fwrite(text)
end

function rightPrint(text)
	local x, y = fterm.getCursorPos()
	local w, h = fterm.getSize()
	fterm.setCursorPos(w - text:len() - 1, y)
	fprint(text)
end

function rightWrite(text)
	local x, y = fterm.getCursorPos()
	local w, h = fterm.getSize()
	fterm.setCursorPos(w - text:len() - 1, y)
	fwrite(text)
end


--  -------- Filesystem

local function getDropbox(url, file)
	for i = 1, 3 do
		local response = fhttp.get(url)
		if response then
			local fileData = response.readAll()
			response.close()
			local f = fio.open(file, "w")
			f:write(fileData)
			f:close()
			return true
		end
	end

	return false
end

local function resetFilesystem()
	-- Folders
	if not(ffs.exists(rootFolder)) then 
		ffs.makeDir(rootFolder)
	elseif not(ffs.isDir(rootFolder)) then
		ffs.move(rootFolder, "/Old_Firefox_Data_File")
		ffs.makeDir(rootFolder)
	end
	if not(ffs.exists(cacheFolder)) then ffs.makeDir(cacheFolder) end
	if not(ffs.exists(serverFolder)) then ffs.makeDir(serverFolder) end

	-- Settings
	if not(ffs.exists(settingsLocation)) then
		local f = fio.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = "true", incog = "false", home = "firefox"}))
		f:close()
	end

	-- Server software
	if not(ffs.exists(serverSoftwareLocation)) then
		getDropbox(serverURL, serverSoftwareLocation)
	end

	-- History
	if not(ffs.exists(historyLocation)) then
		local f = fio.open(historyLocation, "w")
		f:write(textutils.serialize({}))
		f:close()
	end

	-- Databases
	ffs.delete(globalDatabase)
	for _, v in fipairs({globalDatabase, userWhitelist, userBlacklist}) do
		if not(ffs.exists(v)) then
			local f = fio.open(v, "w")
			f:write("")
			f:close()
		end
	end
end


--  -------- Updating Utilities

local function updateClient()
	local updateLocation = rootFolder .. "/firefox-update"

	-- Get files and contents
	getDropbox(firefoxURL, updateLocation)
	local f1 = fio.open(updateLocation, "r")
	local f2 = fio.open(firefoxLocation, "r")
	local update = f1:read("*a")
	local current = f2:read("*a")
	f1:close()
	f2:close()

	-- Update
	if current ~= update then
		ffs.delete(firefoxLocation)
		ffs.move(updateLocation, firefoxLocation)
		fshell.run(firefoxLocation)
		ferror()
	else
		ffs.delete(updateLocation)
	end
end

local function appendToHistory(item)
	if incognito == "false" then
		-- Clean up item
		local a = item:gsub("^%s*(.-)%s*$", "%1"):lower()
		if a == "home" then
			a = homepage
		end

		-- Append to overall history
		if a ~= "exit" and a ~= "history" and a ~= "" and history[1] ~= a then
			ftable.insert(history, 1, a)
			local f = fio.open(historyLocation, "w")
			f:write(textutils.serialize(history))
			f:close()
		end

		-- Append to search bar history
		if searchBarHistory[#searchBarHistory] ~= a then
			ftable.insert(searchBarHistory, a)
		end
	end
end


------ Website Verification

local function reloadDatabases()
	-- Get
	getDropbox(databaseURL, globalDatabase)
	local f = fio.open(globalDatabase, "r")

	-- Blacklist
	blacklistDatabase = {}
	local l = f:read("*l")
	while l ~= "START-WHITELIST" do
		l = f:read("*l")
		if l ~= nil and l ~= "" and l ~= "\n" and l ~= "START-BLACKLIST" and 
		   l ~= "START-WHITELIST" then
		    l = l:gsub("^%s*(.-)%s*$", "%1"):lower()
			ftable.insert(blacklistDatabase, l)
		end
	end

	-- Whitelist
	whitelistDatabase = {}
	l = ""
	while l ~= "START-VERIFIED" do
		l = f:read("*l")
		if l ~= nil and l ~= "" and l ~= "\n" and l ~= "START-VERIFIED" and 
		   l ~= "START-WHITELIST" and l:find("| |") then
		   	l = l:gsub("^%s*(.-)%s*$", "%1"):lower()
		    local a, b = l:find("| |")
		    local n = l:sub(1, a - 1)
		    local id = l:sub(b + 1, -1)
			ftable.insert(whitelistDatabase, {n, id})
		end
	end

	-- Verified
	verifiedDatabase = {}
	l = ""
	while l ~= "START-DOWNLOADS" do
		l = f:read("*l")
		if l ~= nil and l ~= "" and l ~= "\n" and l ~= "START-VERIFIED" and 
		   l ~= "START-DOWNLOADS" and l:find("| |") then
		   	l = l:gsub("^%s*(.-)%s*$", "%1"):lower()
		    local a, b = l:find("| |")
		    local n = l:sub(1, a - 1)
		    local id = l:sub(b + 1, -1)
			ftable.insert(verifiedDatabase, {n, id})
		end
	end

	-- Downloads
	downloadDatabase  = {}
	l = ""
	while l ~= "START-DEFINITIONS" do
		l = f:read("*l")
		if l ~= nil and l ~= "" and l ~= "\n" and l ~= "START-DOWNLOADS" and 
		   l ~= "START-DEFINITIONS" then
		    l = l:gsub("^%s*(.-)%s*$", "%1")
			ftable.insert(downloadDatabase, l)
		end
	end

	-- Definitions
	antivirusDefinitions = {}
	l = ""
	while l ~= "END-DATABASE" do
		l = f:read("*l")
		if l ~= nil and l ~= "" and l ~= "\n" and l ~= "START-VERIFIED" and 
		   l ~= "END-DATABASE" then
		    l = l:gsub("^%s*(.-)%s*$", "%1")
			ftable.insert(antivirusDefinitions, l)
		end
	end

	f:close()

	-- User Blacklist
	if not(ffs.exists(userBlacklist)) then 
		local bf = fio.open(userBlacklist, "w") 
		bf:write("\n") 
		bf:close()
	else
		local f = fio.open(userBlacklist, "r")
		for line in f:lines() do
			if line ~= nil and line ~= "" and line ~= "\n" then
				ftable.insert(blacklistDatabase, line:gsub("^%s*(.-)%s*$", "%1"):lower())
			end
		end
		f:close()
	end

	-- User Whitelist
	if not(ffs.exists(userWhitelist)) then 
		local f = fio.open(userWhitelist, "w") 
		f:write("\n")
		f:close()
	else
		local switch = "url"
		local f = fio.open(userWhitelist, "r")

		for l in f:lines() do
			if l ~= nil and l ~= "" and l ~= "\n" then
				l = l:gsub("^%s*(.-)%s*$", "%1"):lower()
				local a, b = l:find("| |")
			    local n = l:sub(1, a - 1)
			    local id = l:sub(b + 1, -1)
				ftable.insert(whitelistDatabase, {n, id})
			end
		end

		f:close()
	end
end

local function verifyAgainstWhitelist(site, id)
	if site:find("/") then
		local startPoint = site:find("/")
		site = site:sub(1, startPoint-1)
	end
	for i = 1, #whitelistDatabase do
		if whitelistDatabase[i][1] == site then
			if whitelistDatabase[i][2] == ftostring(id) then
				return true
			else
				return false
			end
		end
	end
	return "not verified"
end

local function verifyAgainstVerified(site, id)
	for i = 1, #verifiedDatabase do
		if verifiedDatabase[i][1] == site and verifiedDatabase[i][2] == ftostring(id) then
			return true
		end
	end

	return false
end

local function verifyAgainstBlacklist(id)
	for i = 1, #blacklistDatabase do
		if blacklistDatabase[i] == ftostring(id) then
			return true
		end
	end
	return false
end

local function verifyAgainstAntivirus(checkData)
	local a = checkData
	a = a:gsub(" ", ""):gsub("\n", ""):gsub("\t", "")
	for i = 1, #antivirusDefinitions do
		local b = antivirusDefinitions[i]
		if b ~= "" and b ~= "\n" and b ~= nil then
			if fstring.find(a, b, 1, true) then
				return true
			end
		end
	end

	return false
end

local function downloadVerified(checkData)
	for i = 1, #downloadDatabase do
		if downloadDatabase[i] == checkData then
			return true
		end
	end

	return false
end

local function blacklistRedirectionBots()
	local suspected = {}
	local alphabet = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", 
				      "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "."}
	local name = ""
	for i = 1, fmath.random(1,3) do
		name = ""
		for d = 1, fmath.random(6, 17) do
			name = name .. alphabet[fmath.random(1, 27)]
		end
		rednet.broadcast(name)
		sleep(timeout)
	end

	for i = 1, 4 do
		name = ""
		for d = 1, fmath.random(6, 17) do
			name = name .. alphabet[fmath.random(1, 27)]
		end

		local finishCheck = false
		frednet.broadcast(name)
		clock = fos.clock()
		for i = 1, 5 do
			while fos.clock() - clock < timeout do
				local id = frednet.receive(timeout)
				if id ~= nil and verifyAgainstBlacklist(id) == false then
					name = ""
					for d = 1, fmath.random(6, 17) do
						name = name .. alphabet[fmath.random(1, 27)]
					end

					local inSuspected = false
					for b = 1, #suspected do
						if suspected[b][1] == id then
							suspected[b][2] = suspected[b][2] + 1
							inSuspected = true
						end
					end

					if not(inSuspected) then
						ftable.insert(suspected, {id, 1})
						break
					end
				elseif id == nil then finishCheck = true
					break
				end
			end
			if finishCheck then break end
		end
		if finishCheck then break end
	end

	for i = 1, #suspected do
		if suspected[i][2] > 2 then
			local f = fio.open(userBlacklist, "a")
			f:write(ftostring(suspected[i][1]) .. "\n")
			f:close()
			ftable.insert(blacklistDatabase, ftostring(suspected[i][1]))
		end
	end
end

local function updateDatabases()
	while not(exitApp) do
		fos.pullEvent(websiteLoadEvent)
		reloadDatabases()
	end
end


--  -------- Error Websites

local function webpageCrash()
	-- URL
	local url = runningWebsite
	if errorMessage ~= nil then
		url = "crash"
	end

	-- Draw
	local title = ""
	local w, h = fterm.getSize()
	if errorMessage ~= nil then
		title = "Crash"
	else
		title = ""
	end

	if errorMessage ~= nil then
		fterm.clear()
	end
	fterm.setCursorPos(2, 1)
	fwrite("rdnt://" .. url)

	-- Title
	if title ~= nil then
		fterm.setCursorPos(w - fstring.len("  " .. title), 1)
		fwrite("  " .. title)
	end

	-- Line
	fterm.setCursorPos(1, 2)
	fwrite(fstring.rep("-", w))

	-- Content
	if errorMessage == nil then
		fos.queueEvent("key", 29)
	else
		fprint("\n\n")
		centerPrint("Error")
		fprint(" ")
		centerPrint("Firefox Has Crashed!")
		centerPrint("Error Message:")
		fprint(" ")
		fprint(" " .. errorMessage)
		fprint(" ")
		centerPrint("Please Report This Error To")
		centerPrint("1lann or GravityScore")
		fprint(" ")
		centerPrint("You May Now Browse Normally...")
		errorMessage = nil
	end
end

local function webpageOverspeed(overspeed)
	-- Reset
	overspeed = false
	loadingRateClock = fos.clock()
	websiteLoadingRate = 0
	runningWebsite = "toofast"

	-- URL
	local w, h = fterm.getSize()
	local title = "Overspeed"
	fterm.clear()
	fterm.setCursorPos(2, 1)
	fwrite("rdnt://toofast")

	-- Title
	if title ~= nil then
		fterm.setCursorPos(w - fstring.len("  " .. title), 1)
		fwrite("  " .. title)
	end

	-- Line
	for i = 1, 5 do
		fterm.setCursorPos(1, 2)
		fwrite(fstring.rep("-", w))
		fprint("\n\n")
		centerPrint("Warning!")
		fprint(" ")
		centerPrint("Website Browsing Speed Limit Reached!")
		fprint(" ")
		centerPrint("To Prevent Firefox From Spamming Rednet,")
		centerPrint("Firefox Has Stopped Loading The Page.")
		fprint("\n\n")
		if 6 - i == 1 then
			term.clearLine()
			centerPrint("Please Wait " .. ftostring(6 - i) .. " Second...")
		else
			term.clearLine()
			centerPrint("Please Wait " .. ftostring(6 - i) .. " Seconds...")
		end
		fsleep(1)
	end

	fterm.setCursorPos(1, 2)
	fwrite(fstring.rep("-", w))
	fprint("\n\n")
	centerPrint("Warning!")
	fprint(" ")
	centerPrint("Website Browsing Speed Limit Reached!")
	fprint(" ")
	centerPrint("To Prevent Firefox From Spamming Rednet,")
	centerPrint("Firefox Has Stopped Loading The Page.")
	fprint("\n\n")
	centerPrint("You May Now Browse Normally...")
end

local function checkForModem()
	while not(exitApp) do
		-- Check For Modem
		local present = false
		for _, v in fpairs(rs.getSides()) do
			if fperipheral.getType(v) == "modem" then
				frednet.open(v)
				present = true
				break
			end
		end

		if not(present) then
			runningWebsite = "nomodem"
			clearPage("nomodem")
			fprint(" ")
			centerPrint("No Wireless Modem!")
			fprint("\n\n")
			centerPrint("No Wireless Modem Has Been Detected")
			centerPrint("On This Computer!")
			fprint(" ")
			centerPrint("Waiting For A Modem To Be Attached...")
			fprint("\n\n")
			centerPrint("[Exit Firefox]")
			while not(exitApp) do
				local event, id = fos.pullEvent()
				if event == "key" and id == 28 then
					return true
				elseif event == "peripheral" then
					break
				end
			end
		else
			return
		end
	end
end


--  -------- Built-In Websites

local function webpageHome(site)
	-- Title
	local w, h = fterm.getSize()
	fprint(" ")
	centerPrint("        _,-='\"-.__               /\\_/\\   ")
	centerPrint("         -.}        =._,.-==-._.,  @ @._,")
	centerPrint("            -.__  __,-.   )       _,.-'  ")
	centerPrint("                 \"     G..m-\"^m m'       ")
	fprint(" ")
	leftWrite("  Welcome to Mozilla Firefox " .. firefoxVersion)

	-- Useful websites
	fterm.setCursorPos(1, 11)
	lWrite("      rdnt://history")
	rWrite("History      \n")
	lWrite("      rdnt://server")
	rWrite("Servers      \n")
	lWrite("      rdnt://downloads")
	rWrite("Downloads      \n")
	lWrite("      rdnt://help")
	rWrite("Help Page      \n")
	lWrite("      rdnt://settings")
	rWrite("Settings      \n")
	lWrite("      rdnt://credits")
	rWrite("Credits      \n")
	lWrite("      rdnt://exit")
	rWrite("Exit      \n")
	fprint(" ")
	cWrite("Control To Navigate The Web")
end

local function webpageHistory(site)
	-- Title
	centerPrint("Firefox History")

	if #history ~= 0 then
		-- Organise
		local his = {"Clear History"}
		for i = 1, #history do
			ftable.insert(his, "rdnt://" .. history[i])
		end

		-- Prompt
		local web, ex = scrollingPrompt(his, 4, 4, 14)
		if not(ex) then
			if web == "Clear History" then
				-- Reset history
				history = {}
				searchBarHistory = {}
				local f = fio.open(historyLocation, "w")
				f:write(textutils.serialize(history))
				f:close()

				-- Draw
				clearPage(site)
				centerPrint("Firefox History")
				fprint("\n")
				centerPrint("History Cleared")
				fsleep(0.9)
				redirect("history")
			else
				-- Redirect
				redirect(web:gsub("rdnt://", ""))
			end
		end
	else
		-- No Items
		fprint("\n\n")
		centerPrint("No Items In History")
	end
end

local function webpageServerManagement(site)
	centerPrint("Firefox Server Management")

	local l = ffs.list(serverFolder)
	local s = {"New Server"}
	for i = 1, #l do
		if ffs.isDir(serverFolder .. "/" .. l[i]) then
			ftable.insert(s, l[i])
		end
	end

	local server, ex = scrollingPrompt(s, 4, 4, 14)
	if not(ex) then
		if server == "New Server" then
			-- Get URL
			clearPage(site)
			centerPrint("Firefox Server Management")
			fprint("\n\n")
			leftWrite("Server URL:\n")
			leftWrite("    rdnt://")
			local url = read():lower():gsub(" ", "")
			fprint("\n")

			if url ~= "" then
				if url:find("/") then
					leftWrite("Server URL Invalid\n")
					leftWrite("Contains Illegal '/'\n")
					fsleep(0.9)
				elseif url:find("| |") then
					leftWrite("Server URL Invalid\n")
					leftWrite("Contains Illegal '| |'\n")
					fsleep(0.9)
				else
					leftWrite("Creating Server: " .. url)
					fsleep(0.4)

					local serverLoc = serverFolder .. "/" .. url
					ffs.makeDir(serverLoc)
					local homeF = fio.open(serverLoc .. "/home", "w")
					homeF:write("print(\" \")\ncenterPrint(\"Welcome To " .. url .. "\")")
					homeF:close()
				end
			else
				leftWrite("Server URL Empty!")
				leftWrite("Could Not Create Server")
				fsleep(0.4)
			end
			redirect("server")
		else
			local redir = false
			while not(exitApp) do
				clearPage(site)
				local serverPath = serverFolder .. "/" .. server
				server = server:gsub("^%s*(.-)%s*$", "%1"):lower()
				centerPrint("Firefox Server Management")
				fprint(" ")
				leftWrite("Server: " .. server)

				local opt = prompt({{"Start Server", 5, 8}, 
					{"Run On Startup", 5, 10}, {"Edit Pages", 5, 12}, 
					{"Delete Server", 5, 14}, {"Back", 5, 16}})
				if opt == "Start Server" then
					fshell.run(serverSoftwareLocation, server, serverPath)
					checkForModem()
					redir = true

					break
				elseif opt == "Run On Startup" then
					-- Move to startup
					ffs.delete("/old-startup")
					if ffs.exists("/startup") then ffs.move("/startup", "/old-startup") end
					local f = fio.open("/startup", "w")
					f:write("shell.run(\"" .. serverSoftwareLocation .. "\", \"" .. server .. 
							"\", \"" .. serverPath .. "\")")
					f:close()

					-- Display
					clearPage(site)
					cPrint("Firefox Server Management")
					fprint("\n\n")
					cPrint("Server Will Run On Startup")
					fsleep(0.9)
				elseif opt == "Edit Pages" then
					-- Variables
					local oldLocation = fshell.dir()
					local comHis = {}

					-- Title
					fterm.clear()
					fterm.setCursorPos(1, 1)
					fshell.setDir(serverFolder .. "/" .. server)
					fprint("Server File Editing")
					fprint("Type 'exit' To Return To Server Management")
					fprint(" ")
					fprint("Server files:")
					fshell.run("/rom/programs/list")
					fprint(" ")

					-- Shell
					while true do
						fshell.setDir(serverFolder .. "/" .. server)
						fwrite("> ")

						local line = read(nil, comHis)
						ftable.insert(comHis, line)

						local words = {}
						for match in fstring.gmatch(line, "[^ \t]+") do
							ftable.insert(words, match)
						end

						local command = words[1]
						if command == "exit" then
							break
						elseif command then
							fshell.run(command, unpack(words, 2))
						end
					end

					-- Reset
					fshell.setDir(oldLocation)
					fterm.clear()
				elseif opt == "Delete Server" then
					clearPage(site)
					centerPrint("Firefox Server Management")
					local w, h = fterm.getSize()
					local opt = prompt({{"Delete Server", 
						fmath.ceil(w/4 - fstring.len("Delete Server")/2), 9}, 
						{"Cancel", fmath.ceil(w/4 - fstring.len("Cancel")/2 + w/2), 9}})
					if opt == "Delete Server" then
						clearPage(site)
						centerPrint("Firefox Server Management")
						fprint("\n\n")
						centerPrint("Deleted Server")
						fsleep(0.9)
						ffs.delete(serverPath)
					elseif opt == "Cancel" then
						clearPage(site)
						centerPrint("Firefox Server Management")
						fprint("\n\n")
						centerPrint("Cancelled Delete Operation")
						fsleep(0.9)
					end

					redir = true
					break
				elseif opt == "Back" then
					redir = true
					break
				elseif opt == nil then
					return
				end
			end

			if redir then redirect("server") end
		end
	end
end

local function webpageDownloads(site)
	fprint("\n\n\n")
	centerPrint("Comming Soon!")
end

local function webpageSettings(site)
	while not(exitApp) do
		-- Clear
		clearPage(site)
		centerPrint("Firefox Settings")
		fprint(" ")
		leftWrite("Designed For: " .. serverList[serverID])

		-- Load different options
		local t1 = "Auto-Update - Off"
		if autoupdate == "true" then t1 = "Auto-Update - On" end
		local t2 = "Record History - Off"
		if incognito == "true" then t2 = "Record History - On" end
		local x = homepage
		if x:len() > 22 then x = x:sub(1, 20) .. "..." end
		local t3 = "Homepage - rdnt://" .. x

		-- Prompt the user
		local opt = prompt({{t1, 5, 8}, {t2, 5, 10}, {t3, 5, 12}, {"Reset Firefox", -1, 17}})

		-- Respond depending on option
		if opt == nil then
			break
		elseif opt == t1 then
			if autoupdate == "true" then
				autoupdate = "false"
			else
				autoupdate = "true"
			end
		elseif opt == t2 then
			if incognito == "true" then
				incognito = "false"
			else
				incognito = "true"
			end
		elseif opt == t3 then
			fterm.setCursorPos(9, 13)
			fwrite("rdnt://")
			homepage = read():gsub("^%s*(.-)%s*$", "%1"):lower()
		elseif opt == "Reset Firefox" then
			-- Clear
			clearPage(site)
			fprint(" ")
			centerPrint("Firefox Settings")

			-- Prompt
			local w, h = fterm.getSize()
			local a = prompt({{"Reset", fmath.floor(w/4 - fstring.len("Reset")/2), 9}, 
				{"Cancel", fmath.ceil(w/4 - fstring.len("Cancel")/2 + w/2), 9}})

			if a == "Reset" then
				-- Delete root folder
				ffs.delete(rootFolder)

				-- Draw
				clearPage(site)
				fprint(" ")
				centerPrint("Firefox Settings")
				fprint("\n\n")
				centerPrint("Firefox Has Been Reset")
				fprint("\n\n\n")
				centerPrint("[ Exit Firefox ]")
				while not(exitApp) do
					local e, key = fos.pullEvent()
					if (e == "key" and key == 28) or e == "mouse_click" then
						break
					end
				end
				redirect("exit")
			elseif a == "Cancel" then
				-- Draw
				clearPage(site)
				fprint(" ")
				centerPrint("Firefox Settings")
				fprint("\n\n")
				centerPrint("Reset Cancelled")
				fsleep(0.9)
			end
		end

		-- Save settings
		local f = fio.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = autoupdate, incog = incognito, home = homepage}))
		f:close()
	end
end

local function webpageHelp(site)
	-- Draw Dev page
	centerPrint("Firefox Help")
	fprint("\n")
	leftWrite("View a Help Topic:")
	local b = {{"Getting Started", 10, 8}, {"Making A Website", 10, 10}, {"API Documentation", 10, 12}}
	for _, v in fpairs(b) do
		term.setCursorPos(v[2] - 3, v[3])
		write("-")
	end
	local topic = prompt(b)
	if topic == nil then return end

	local pages = {}
	if topic == "Getting Started" then
		-- Pages
		pages[1] = function()
			centerPrint("Getting Started - 1")
			fprint(" ")
			centerPrint("Firefox is an application which allows you to")
			centerPrint("visit websites made by other people in Minecraft!")
			fprint(" ")
			centerPrint("You can also set up your own website for others")
			centerPrint("visit in-game.")
			fprint(" ")
			centerPrint("To access the URL bar, just press Control")
		end

		pages[2] = function()
			centerPrint("Getting Started - 2")
			fprint(" ")
			centerPrint("To search all the websites online, just type")
			centerPrint("nothing into the URL bar, and press enter")
			fprint(" ")
			centerPrint("To search for a specific keyword, type it into")
			centerPrint("the URL bar and press enter")
			fprint(" ")
			centerPrint("To visit a specific website, type its URL into")
			centerPrint("the URL bar, or select it from the list of search")
			centerPrint("results after searching.")
		end

		pages[3] = function()
			centerPrint("Getting Started - 3")
			fprint(" ")
			centerPrint("Firefox also offers a set of built in websites.")
			fprint(" ")
			centerPrint("These include:")
			leftPrint("   - rdnt://firefox")
			leftPrint("   - rdnt://history")
			leftPrint("   - rdnt://server")
			leftPrint("   - rdnt://help")
			leftPrint("   - rdnt://settings")
			leftPrint("   - rdnt://credits")
			leftPrint("   - rdnt://getinfo")
			leftPrint("   - rdnt://exit")
		end

		pages[4] = function()
			centerPrint("Getting Started - 4")
			fprint(" ")
			centerPrint("On the rdnt://settings page, you are able to")
			centerPrint("change whether Firefox automatically updates")
			centerPrint("itself, whether it records history, and the")
			centerPrint("default homepage.")
			fprint(" ")
			centerPrint("You can also completely reset Firefox to its")
			centerPrint("default settings. You will lose all your")
			centerPrint("servers, history items, and settings.")
		end
	elseif topic == "Making A Website" then
		-- Pages
		pages[1] = function() 
			centerPrint("Making A Website - 1")
			fprint(" ")
			centerPrint("Websites are sites that players may create")
			centerPrint("and are accessable by other Firefox Browers.")
			fprint(" ")
			centerPrint("A server is software which allows you to host")
			centerPrint("a website, and make it viewable to other players.")
			fprint(" ")
			centerPrint("They can be created at rdnt://server.")
		end

		pages[2] = function()
			centerPrint("Making A Website - 2")
			fprint(" ")
			centerPrint("In rdnt://server, there is a list of servers")
			centerPrint("on this computer, as well as the option to")
			centerPrint("create a new one.")
			fprint(" ")
			centerPrint("Selecting a servers from the list displays")
			centerPrint("options for editing parts that server.")
			fprint(" ")
			centerPrint("You can edit the pages of a server in a")
			centerPrint("shell-style console when you select 'Edit Pages'")
		end
	elseif topic == "API Documentation" then
		pages[1] = function()
			centerPrint("API Documentation - 1")
			fprint(" ")
			centerPrint("Firefox API is a set of functions that")
			centerPrint("can be used by website developers.")
			fprint(" ")
			centerPrint("They are documented on the next few pages...")
		end

		pages[2] = function()
			centerPrint("API Documentation - 2")
			fprint(" ")
			leftPrint("centerPrint(text)  or   cPrint(text)")
			leftPrint("  - Prints text to the center of the page")
			leftPrint("  - Returns nothing")
			fprint(" ")
			leftPrint("leftPrint(text)    or   lPrint(text)")
			leftPrint("  - Prints text to the left of the page")
			leftPrint("  - Returns nothing")
			fprint(" ")
			leftPrint("rightPrint(text)   or   rPrint(text)")
			leftPrint("  - Prints text in the right of the page")
			leftPrint("  - Returns nothing")
		end

		pages[3] = function()
			centerPrint("API Documentation - 3")
			fprint(" ")
			leftPrint("centerWrite(text)  or   cWrite(text)")
			leftPrint("  - Writes text to the center of the page")
			leftPrint("  - Returns nothing")
			fprint(" ")
			leftPrint("leftWrite(text)    or   lWrite(text)")
			leftPrint("  - Writes text to the left of the page")
			leftPrint("  - Returns nothing")
			fprint(" ")
			leftPrint("rightWrite(text)   or   rWrite(text)")
			leftPrint("  - Writes text in the right of the page")
			leftPrint("  - Returns nothing")
		end

		pages[4] = function()
			centerPrint("API Documentation - 4")
			fprint(" ")
			leftPrint("prompt(options)")
			leftPrint("  - Prompts the user to select an option")
			leftPrint("  - 'options' is an array, formatted like:")
			leftPrint("       {{[option name], [x], [y]}}")
			leftPrint("  - Example:")
			leftPrint("    opt = prompt({{\"Option 1\", 4, 5},")
			leftPrint("                  {\"Option 2\", 5, 7}})")
			fprint(" ")
			leftPrint("pastebinDownload(pastebinCode)")
			leftPrint("  - Downloads code from pastebin into a user")
			leftPrint("    chosen path")
			leftPrint("  - Returns the name of the path of the user")
			leftPrint("    chose, or nil if the download failed")
		end

		pages[5] = function()
			centerPrint("API Documentation - 5")
			fprint(" ")
			leftPrint("urlDownload(url)")
			leftPrint("  - Downloads the contents of a url into a user")
			leftPrint("    chosen path")
			leftPrint("  - Returns the path of the file the user")
			leftPrint("    chose, or nil if the download failed")
			fprint(" ")
			leftPrint("redirect(site)")
			leftPrint("  - Redirects to another website")
			leftPrint("  - Eg: redirect(\"mozilla.org/firefox\")")
		end
	end

	local curPage = 1
	clearPage(site)
	pages[curPage]()
	while not(exitApp) do
		local w, h = fterm.getSize()
		local l = {{"Previous", 3, 18}, {"Back", -1, 18}, 
			{"Next", w - 7, 18}}
		if curPage == 1 then
			l = {{"Back", -1, 18}, {"Next", w - 7, 18}}
		elseif curPage == #pages then
			l = {{"Previous", 3, 18}, {"Back", -1, 18}}
		end
		local opt = prompt(l)
		if opt ~= nil then clearPage(site) end

		if opt == "Previous" then
			curPage = curPage - 1
		elseif opt == "Back" then
			break
		elseif opt == "Next" then
			curPage = curPage + 1
		elseif opt == nil then
			return
		end

		pages[curPage]()
	end

	redirect("help")
end

local function webpageCredits(site)
	-- Draw Credits
	fprint(" ")
	centerPrint("Firefox Credits")
	fprint("\n")
	centerPrint("Coded By:")
	centerPrint("1lann and GravityScore")
	fprint("\n")
	centerPrint("Originally Based Off:")
	centerPrint("Rednet Explorer 2.4.1")
	fprint(" ")
	centerPrint("Rednet Explorer Made By:")
	centerPrint("xXm0dzXx/CCFan11")
end

local function webpageGetInfo(site)
	-- Title
	clearPage(site)
	fprint(" ")
	centerPrint("Website Information")
	fprint("\n\n")
	leftPrint("Enter URL: ")
	leftWrite("    rdnt://")
	local url = read():gsub("^%s*(.-)%s*$", "%1"):lower()

	-- Get website
	local id, content, valid = nil
	local av, bl, wl, vf = nil, nil, nil, nil
	local clock = fos.clock()
	frednet.broadcast(url)
	while fos.clock() - clock < timeout do
		-- Get
		id, content = frednet.receive(timeout)

		if id ~= nil then
			-- Validity check
			av = verifyAgainstAntivirus(content)
			bl = verifyAgainstBlacklist(id)
			wl = verifyAgainstWhitelist(url, id)
			vf = verifyAgainstVerified(url, id)
			valid = ""
			if bl or not(wl) then
				valid = "blacklist"
			elseif av and not(vf) then
				valid = "antivirus"
				break
			else
				valid = "true"
				break
			end
		end
	end

	if valid ~= nil and id ~= nil and content ~= nil then
		-- Print information
		clearPage(site)
		fprint(" ")
		centerPrint("Website Information")
		fprint("\n")
		leftWrite("Site: " .. url .. "\n")
		fprint(" ")
		leftWrite("ID: " .. id .. "\n")
		if bl then
			leftWrite("Site Is Filtered/Ignored\n")
		end if type(wl) ~= "string" and wl then
			leftWrite("Site Is Whitelisted\n")
		end 
		fprint(" ")
		if av then
			leftWrite("Site Triggered Antivirus\n")
		end if vf then
			leftWrite("Site Is Verified\n")
		end
	else
		-- Not Found
		clearPage(site)
		fprint(" ")
		centerPrint("Website Information")
		fprint("\n")
		centerPrint("Page Not Found")
		fsleep(0.9)
		redirect("getinfo")
	end
end

local function loadWebpage(site)
	-- Functions
	local function runSite(cacheLoc)
		clearPage(site)

		function term.getSize()
			return 51, 17
		end

		function term.setCursorPos(x, y)
			return fterm.setCursorPos(x, y + 2)
		end

		function term.clear()
			return clearArea()
		end

		function term.getCursorPos()
			local x, y = fterm.getCursorPos()
			return x, y - 2
		end

		function shell.run(file)
			if file == "clear" then
				clearArea()
				fterm.setCursorPos(1,3)
			else
				return fshell.run(file)
			end
		end

		local function ctrlControl()
			while not(exitApp) do
				local event, key, x, y = fos.pullEvent()
				if (event == "key" and (key == 29 or key == 157)) or 
						(event == "mouse_click" and (y == 1 or y == 2)) and not(lockCtrl) then
					exitWebsite = true
				end
			end
		end

		parallel.waitForAll(ctrlControl, function() 
			fshell.run(cacheLoc) 
		end)

		exitWebsite = false
		term = copyTable(fterm)
		shell = copyTable(fshell)
		string = copyTable(fstring)
		lockCtrl = false
	end

	-- Draw
	term = copyTable(fterm)
	shell = copyTable(fshell)
	clearPage(site)
	fprint("\n")
	centerPrint("Connecting...")

	-- Reset
	websiteLoadingRate = websiteLoadingRate + 1
	restoreFunctions()

	-- Redirection Bots
	blacklistRedirectionBots()

	-- Get website
	local id, content, valid = nil
	local clock = fos.clock()
	frednet.broadcast(site)
	while fos.clock() - clock < timeout do
		-- Get
		id, content = frednet.receive(timeout)
		if id ~= nil then
			-- Validity check
			local av = verifyAgainstAntivirus(content)
			local bl = verifyAgainstBlacklist(id)
			local wl = verifyAgainstWhitelist(site, id)
			local vf = verifyAgainstVerified(site, id)
			valid = nil
			if bl or not(wl) or site == "" or site == "." or site == ".." then
				-- Ignore
			elseif av and not(vf) then
				valid = "antivirus"
				break
			else
				valid = "true"
				break
			end
		end
	end

	local cacheLoc = cacheFolder .. "/" .. site:gsub("/", "$slazh$")
	if valid then
		-- Run page
		if valid == "antivirus" then
			clearPage(site)
			fprint("\n")
			centerPrint("    ___     __             __   __")
			centerPrint("   /   |   / /___   _____ / /_ / /")
			centerPrint("  / /| |  / // _ \\ / ___// __// / ")
			centerPrint(" / ___ | / //  __// /   / /_ /_/  ")
			centerPrint("/_/  |_|/_/ \\___//_/    \\__/(_)   ")
			fprint("\n")
			centerPrint("Warning!")
			fprint(" ")
			centerPrint("This Website Has Been Detected")
			centerPrint("As Malicious!")

			local w, h = fterm.getSize()
			local opt = prompt({{"Cancel", fmath.floor(w/4 - fstring.len("Cancel")/2), 17}, 
				{"Load Page", fmath.ceil(w/4 - fstring.len("Load Page")/2 + w/2), 17}})
			if opt == "Cancel" then
				ffs.delete(cacheLoc)
				clearPage(site)
				fprint("\n")
				centerPrint("    ______                          __")
				centerPrint("   / ____/_____ _____ ____   _____ / /")
				centerPrint("  / __/  / ___// ___// __ \\ / ___// / ")
				centerPrint(" / /___ / /   / /   / /_/ // /   /_/  ")
				centerPrint("/_____//_/   /_/    \\____//_/   (_)   ")
				fprint("\n")
				centerPrint("Could Not Connect To Website!")
				fprint(" ")
				centerPrint("Antivirus Cancelled Loading")
			elseif opt == "Load Page" then
				valid = "true"
			end
		end

		if valid == "true" and site ~= "" then
			local f = io.open(cacheLoc, "w")
			f:write(content)
			f:close()
			runSite(cacheLoc)
		end
	else
		if ffs.exists(cacheLoc) and site ~= "" and site ~= ".." and site ~= "." then
			clearPage(site)
			fprint("\n")
			centerPrint("   ______                        ")
			centerPrint("  / ____/____ _ _____ __  __ ___ ")
			centerPrint(" / /    / __ '// ___// /_/ // _ \\")
			centerPrint("/ /___ / /_/ // /__ / __  //  __/")
			centerPrint("\\____/ \\__,_/ \\___//_/ /_/ \\___/ ")
			fprint("\n")
			centerPrint("Could Not Connect To Website!")
			fprint(" ")
			centerPrint("A Cache Version Was Found")
			local w, h = fterm.getSize()
			local opt = prompt({{"Load Cache", fmath.floor(w/4 - fstring.len("Load Cache")/2), 17}, 
			{"Delete Cache", -1, 17}, {"Cancel", fmath.ceil(w/4 - fstring.len("Cancel")/2 + w/2), 17}})

			if opt == "Load Cache" then
				runSite(cacheLoc)
			elseif opt == "Delete Cache" then
				ffs.delete(cacheLoc)
				clearPage(site)
				fprint("\n")
				centerPrint("   ______                        ")
				centerPrint("  / ____/____ _ _____ __  __ ___ ")
				centerPrint(" / /    / __ '// ___// /_/ // _ \\")
				centerPrint("/ /___ / /_/ // /__ / __  //  __/")
				centerPrint("\\____/ \\__,_/ \\___//_/ /_/ \\___/ ")
				fprint("\n")
				centerPrint("Deleted Cached Page!")
				fsleep(1.8)

				clearPage(site)
				fprint("\n")
				centerPrint("    ______                          __")
				centerPrint("   / ____/_____ _____ ____   _____ / /")
				centerPrint("  / __/  / ___// ___// __ \\ / ___// / ")
				centerPrint(" / /___ / /   / /   / /_/ // /   /_/  ")
				centerPrint("/_____//_/   /_/    \\____//_/   (_)   ")
				fprint("\n")
				centerPrint("Could Not Connect To Website!")
				fprint(" ")
				centerPrint("The Address Could Not Be Found")
			elseif opt == "Cancel" then
				clearPage(site)
				fprint("\n")
				centerPrint("    ______                          __")
				centerPrint("   / ____/_____ _____ ____   _____ / /")
				centerPrint("  / __/  / ___// ___// __ \\ / ___// / ")
				centerPrint(" / /___ / /   / /   / /_/ // /   /_/  ")
				centerPrint("/_____//_/   /_/    \\____//_/   (_)   ")
				fprint("\n")
				centerPrint("Could Not Connect To Website!")
				fprint(" ")
				centerPrint("Cached Version Was Not Loaded")
			end
		else
			-- Get search results
			local input = site:gsub("^%s*(.-)%s*$", "%1"):lower()
			local results = {}
			local resultIDs = {}

			frednet.broadcast("rednet.api.ping.searchengine")
			local startClock = fos.clock()
			while fos.clock() - startClock < 1 do
				local id, i = nil, nil
				local id, i = frednet.receive(timeout)
				if id then
					if not(i:find(" ")) and i:len() < 40 and not(verifyAgainstBlacklist(id)) then
						if not(resultIDs[ftostring(id)]) then
							resultIDs[ftostring(id)] = 1
						else
							resultIDs[ftostring(id)] = resultIDs[ftostring(id)]+1
						end
						local x = false
						for y = 1, #results do
							if results[y]:lower() == i:lower() then
								x = true
							end
						end
						if not(x) then
							if resultIDs[ftostring(id)] <= 5 then
								if input == "" then
									ftable.insert(results, i)
								elseif fstring.find(i, input) and i ~= input then
									ftable.insert(results, i)
								end
							else
								ftable.insert(blacklistDatabase, ftostring(id))
							end
						end
					end
				else
					break
				end
			end

			-- Display
			if #results ~= 0 then
				clearPage(site)
				centerPrint("Search Results")
				local res = {}
				for i = 1, #results do
					ftable.insert(res, "rdnt://" .. results[i]:gsub("^%s*(.-)%s*$", "%1"):lower())
				end

				ftable.sort(res)
				local s, ex = scrollingPrompt(res, 4, 4, 14)
				if not(ex) then
					redirect(s:gsub("rdnt://", ""))
				end
			elseif site == "" then
				clearPage(site)
				centerPrint("Search Results")
				fprint("\n\n")
				centerPrint("No Websites Online")
			else
				clearPage(site)
				fprint("\n")
				centerPrint("    ______                          __")
				centerPrint("   / ____/_____ _____ ____   _____ / /")
				centerPrint("  / __/  / ___// ___// __ \\ / ___// / ")
				centerPrint(" / /___ / /   / /   / /_/ // /   /_/  ")
				centerPrint("/_____//_/   /_/    \\____//_/   (_)   ")
				fprint("\n")
				centerPrint("Could Not Connect To Website!")
				fprint(" ")
				centerPrint("The Address Could Not Be Found")
				centerPrint("Or The Website Was Blocked")
			end
		end
	end
	string = copyTable(fstring)

	-- Render bar
	local w, h = fterm.getSize()
	local title = titleForPage(runningWebsite)
	fterm.setCursorPos(2, 1)
	fterm.clearLine()
	fwrite("rdnt://" .. runningWebsite)
	if title ~= nil then
		fterm.setCursorPos(w - fstring.len("  " .. title), 1)
		fwrite("  " .. title)
	end

	-- Line
	fterm.setCursorPos(1, 2)
	fterm.clearLine()
	fwrite(fstring.rep("-", w))
	fprint(" ")
end


--  -------- Download API

local function download(url)
	clearPage(runningWebsite)
	fprint("\n")
	centerPrint("Processing Download Request...")

	local fileData = nil
	local exitDownload = false
	local response = fhttp.get(url)
	if response then
		fileData = response.readAll()
		response.close()
	else
		clearPage(runningWebsite)
		fprint("\n\n")
		centerPrint("Download Request Failed!")
		fprint(" ")
		centerPrint("Please Report This To The Website Owner!")
		prompt({{"Continue To Website", -1, 11}}, "vertical")
		clearPage(runningWebsite)
		exitDownload = true

		return nil
	end

	if not(exitDownload) then
		clearPage(runningWebsite)
		fprint(" ")
		centerPrint("The Website:")
		centerPrint(runningWebsite)
		fprint(" ")
		centerPrint("Is Attempting To Download A File To")
		centerPrint("Your Computer.")
		fprint(" ")

		local w, h = fterm.getSize()
		local a = {{"Download", fmath.floor(w/4 - fstring.len("Download")/2), 15},
				   {"Cancel", fmath.ceil(w/4 - fstring.len("Cancel")/2 + w/2), 15}}

		if downloadVerified(code) then
			centerPrint("This Download Has Been Deemed Safe By Mozilla")
		else
			centerPrint("Warning - This Download Has Not Been Deemed Safe!")
			centerPrint("Download With Caution!")
			a = {{"Cancel", fmath.floor(w/4 - fstring.len("Cancel")/2), 15},
				 {"Download", fmath.ceil(w/4 - fstring.len("Download")/2 + w/2), 15}}
		end

		local opt = prompt(a, "horizontal")
		if opt == "Download" then
			local randomCheck = ftostring(fmath.random(1000, 9999))
			fterm.setCursorPos(2, 13)
			centerPrint("This is for security purposes: " .. randomCheck)
			fterm.setCursorPos(2, 15)
			fterm.clearLine()
			fwrite("Enter the numbers above: ")
			local numberCheck = read()
			if numberCheck == randomCheck then
				fterm.setCursorPos(2, 13)
				term.clearLine()
				fterm.setCursorPos(2, 15)
				fterm.clearLine()
				fwrite("Save As: /")
				local b = "/" .. read()

				local dlf = fio.open(b, "w")
				dlf:write(fileData)
				dlf:close()

				clearPage(runningWebsite)
				fprint("\n")
				centerPrint("Download Successful!")
				prompt({{"Continue To Website", -1, 11}}, "vertical")
				clearPage(runningWebsite)

				return b
			else
				clearPage(runningWebsite)
				fprint("\n")
				centerPrint("Number Entered Is Incorrect!")
				centerPrint("Download Cancelled!")
				prompt({{"Continue To Website", -1, 11}}, "vertical")
				clearPage(runningWebsite)
				return nil
			end
		elseif opt == "Cancel" then
			clearPage(runningWebsite)
			fprint("\n")
			centerPrint("Download Cancelled!")
			prompt({{"Continue To Website", -1, 11}}, "vertical")
			clearPage(runningWebsite)

			return nil
		end
	end
end

function pastebinDownload(code)
	return download("http://pastebin.com/raw.php?i=" .. textutils.urlEncode(code))
end

function urlDownload(url)
	return download(url)
end

securePastebinDownload = pastebinDownload
secureUrlDownload = urlDownload


--  -------- Website Management

local function enterURL()
	-- Clear
	fterm.setCursorPos(2, 1)
	fterm.clearLine()
	fwrite("rdnt://")

	-- Read
	local ret = read(nil, searchBarHistory):gsub("^%s*(.-)%s*$", "%1"):lower()
	appendToHistory(ret)
	if ret:len() > 32 then
		ret = fstring.sub(ret, 1, 39) .. "..."
	end

	return ret
end

local function renderWebpage(site)
	term = copyTable(fterm)
	shell = copyTable(fshell)

	-- Check for modem
	if checkForModem() then
		fterm.clear()
		fterm.setCursorPos(1, 1)
		centerPrint("Thank You for Using Mozilla Firefox " .. firefoxVersion)
		centerPrint("Made by 1lann and GravityScore")
		term = copyTable(fterm)
		shell = copyTable(fshell)

		-- Close rednet
		for _, v in fpairs(rs.getSides()) do
			frednet.close(v)
		end

		exitApp = true
		return "exit"
	end

	-- Variables
	local overspeed = false
	runningWebsite = site
	restoreFunctions()
	fos.queueEvent(websiteLoadEvent)
	if fos.clock() - loadingRateClock > 5 then
		websiteLoadingRate = 0
		loadingRateClock = fos.clock()
	elseif websiteLoadingRate >= 7 then
		overspeed = true
	end

	-- Render site
	if overspeed then webpageOverspeed(overspeed)
	elseif site == "firefox" then webpageHome(site)
	elseif site == "history" then webpageHistory(site)
	elseif site == "server" then webpageServerManagement(site)
	elseif site == "downloads" then webpageDownloads(site)
	elseif site == "help" then webpageHelp(site)
	elseif site == "settings" then webpageSettings(site)
	elseif site == "credits" then webpageCredits(site)
	elseif site == "getinfo" then webpageGetInfo(site)
	elseif site == "exit" then
		-- Exit client
		fterm.clear()
		fterm.setCursorPos(1, 1)
		centerPrint("Thank You for Using Mozilla Firefox " .. firefoxVersion)
		centerPrint("Made by 1lann and GravityScore")
		term = copyTable(fterm)
		shell = copyTable(fshell)

		-- Close rednet
		for _, v in fpairs(rs.getSides()) do
			rednet.close(v)
		end
		
		exitApp = true
		return "exit"
	else
		-- Load the site
		loadWebpage(site)
	end
end

function redirect(site)
	-- Reset
	term = copyTable(fterm)
	shell = copyTable(fshell)

	-- Convert site
	local url = site:gsub("^%s*(.-)%s*$", "%1"):lower()
	if url == "home" then
		url = homepage
	end

	-- Load site
	appendToHistory(url)
	clearPage(url)
	local opt = renderWebpage(url)
	if opt == "exit" then
		exitApp = true
		fos.queueEvent(exitFirefoxEvent)
		ferror()
	end

	if fshell.getRunningProgram():find(".Firefox_Data/cache") then
		ferror()
	end
end

secureRedirection = redirect

local function manageWebpages()
	while not(exitApp) do
		-- Render Page
		local opt = ""
		if not(userTerminated) then
			clearPage(website)
			opt = renderWebpage(website)
		else
			webpageCrash()
		end

		-- Exit
		userTerminated = false
		if opt == "exit" then
			exitApp = true
			fos.queueEvent(exitFirefoxEvent)
			ferror()
		end

		-- Wait for URL bar open
		fos.pullEvent(openURLBarEvent)
		website = enterURL()
		if website == "home" then
			website = homepage
		end
	end
end

local function waitForURLEnter()
	while not(exitApp) do
		local event, key, x, y = fos.pullEvent()
		if (event == "key" and (key == 29 or key == 157)) or 
				(event == "mouse_click" and (y == 1 or y == 2)) then
			string = copyTable(fstring)
			fos.queueEvent(openURLBarEvent)
		end
	end
end


--  -------- Firefox 1.3 Support

function cPrint(text)
	centerPrint(text)
end

function cWrite(text)
	centerWrite(text)
end

function lPrint(text)
	leftWrite(text)
end

function lWrite(text)
	leftWrite(text)
end

function rPrint(text)
	rightWrite(text)
end

function rWrite(text)
	rightWrite(text)
end

function reDirect(site)
	redirect(site)
end

function clearArea()
	clearPage(runningWebsite)
end

function lockControl()
	lockCtrl = true
end

function unlockControl()
	lockCtrl = false
end

function compatability()
	term = copyTable(fterm)
	shell = copyTable(fshell)
end


--  -------- Main

local function startup()
	-- Logo
	fterm.setTextColor(fcolors.white)
	fterm.setBackgroundColor(fcolors.black)
	fterm.clear()
	fterm.setCursorPos(1, 4)
	centerPrint("           _   _                    __ __   ")
	centerPrint("--------- / | / |   ____ ____   __ / // /___")
	centerPrint("-------- /  |/  |  /   //_  /  / // // //  |")
	centerPrint("------- / /| /| | / / /  / /_ / // // // - |")
	centerPrint("------ /_/ |/ |_|/___/  /___//_//_//_//_/|_|")
	centerPrint("----- _____ __ ____   ____ ___  ______  __  ")
	centerPrint("---- / ___// // __ \\ / __// __//   /\\ \\/ /  ")
	centerPrint("--- / /__ / // _  / / __// __// / /  >  <   ")
	centerPrint("-- / ___//_//_/ \\_\\/___//_/  /___/  /_/\\_\\  ")
	centerPrint("- / /                                       ")
	centerPrint(" /_/    Doing Good is Part of Our Code      ")
    fprint("\n")

	-- Filesystem
	fterm.clearLine()
	centerWrite("Downloading Required Files...")
	resetFilesystem()

	-- Databases
	fterm.clearLine()
	centerWrite("Downloading Databases...")
	reloadDatabases()

	-- Load settings
	fterm.clearLine()
	centerWrite("Loading Settings...")
	local f1 = fio.open(settingsLocation, "r")
	local set = ftextutils.unserialize(f1:read("*l"))
	homepage = set.home
	website = homepage
	if not(override) then
		autoupdate = set.auto
		incognito = set.incog
	end
	restoreFunctions()
	f1:close()

	local f2 = fio.open(historyLocation, "r")
	history = ftextutils.unserialize(f2:read("*l"))
	f2:close()
	
	-- Update
	fterm.clearLine()
	centerWrite("Checking for Updates...")
	if autoupdate == "true" then
		updateClient()
	end

	-- Modem
	checkForModem()

	-- Start websites
	if debugging then
		fparallel.waitForAny(manageWebpages, waitForURLEnter, updateDatabases)
	else
		function os.pullEvent(stuff)
			if exitWebsite or exitApp then
				if not(finishExit) then
					ferror()
				end
			end

			local event, p1, p2, p3, p4, p5 = os.pullEventRaw(stuff)
			if exitWebsite or exitApp then
				if not(finishExit) then
					ferror()
				elseif event == "terminate" then
					fprint("Terminated")
					ferror()
				else
					return event, p1, p2, p3, p4, p5
				end
			elseif event == "terminate" then
				fprint("Terminated")
				ferror()
			else
				return event, p1, p2, p3, p4, p5
			end
		end
		
		while not(exitApp) do
			fterm.setCursorBlink(false)
			fparallel.waitForAll(
				function() 
					_, errorMessage = fpcall(manageWebpages) 
					ferror() 
				end, waitForURLEnter, updateDatabases)

			if exitApp then
				ferror()
			end
			userTerminated = true
		end
	end
end

-- Start Firefox
startup()

-- End Encasing Function
end


--  -------- Complete Crash Protection

-- Copy APIs
local function fcopyTable(oldTable)
	local newTable = {}
	for k, v in pairs(oldTable) do
		newTable[k] = v
	end
	return newTable
end

local sterm = fcopyTable(term)
local scolors = fcopyTable(colors)
local sos = os
local sprint = print
local ssleep = sleep
local swrite = write
local serror = error
local sio = fcopyTable(io)
if http then
	local shttp = fcopyTable(http)
end
local smath = fcopyTable(math)

-- Functions
local function scenterPrint(text)
	local w, h = sterm.getSize()
	local x, y = sterm.getCursorPos()
	sterm.setCursorPos(smath.ceil((w + 1)/2 - text:len()/2), y)
	sprint(text)
end

local function scenterWrite(text)
	local w, h = sterm.getSize()
	local x, y = sterm.getCursorPos()
	sterm.setCursorPos(smath.ceil((w + 1)/2 - text:len()/2), y)
	swrite(text)
end

local function sgetDropbox(url, file)
	for i = 1, 3 do
		local response = shttp.get(url)
		if response then
			local fileData = response.readAll()
			response.close()
			local f = sio.open(file,"w")
			f:write(fileData)
			f:close()
			return true
		end
	end

	return false
end

if http then
	if term.isColor() then
		-- Run Firefox
		local _, err = pcall(entiretyFirefox)

		-- Catch Crash
		finishExit = true
		exitApp = false
		if err then
			sterm.setTextColor(scolors.white)
			sterm.setBackgroundColor(scolors.black)
			sterm.clear()
			sterm.setCursorPos(1, 2)
			scenterPrint("Critical Error!")
			sprint("\n")
			scenterPrint("Firefox Has Encountered A Critical")
			scenterPrint("Internal Error!")
			sprint("\n")
			scenterPrint("Error:")
			sprint("  " .. err)
			sprint(" ")
			scenterPrint("Please Report This Error To 1lann")
			scenterPrint("or GravityScore")
			sprint("\n")
			scenterPrint("[ Exit Firefox ]")
			while true do
				local event, key = sos.pullEvent()
				if (event == "key" and key == 28) or event == "mouse_click" then
					sterm.clear()
					sterm.setCursorPos(1, 1)
					break
				end
			end
		end
	else
		-- Not an advanced computer
		sterm.clear()
		sterm.setCursorPos(1, 2)
		scenterPrint("Not Using An Advanced Computer!")
		sprint("\n")
		scenterPrint("This Computer Does Not Support Colors")
		scenterPrint("And Mouse Clicking!")
		sprint(" ")
		scenterPrint("Firefox Is Not Able To Run On It!")
		sprint(" ")
		scenterPrint("You Can Download Firefox 1.4.5 And Use")
		scenterPrint("It On This Computer.")
		sprint("\n\n")
		term.clearLine()
		scenterWrite("[Download Firefox 1.4.5]         Exit Firefox ")
		local curOpt = 1
		while true do
			local _, key = sos.pullEvent("key")
			if key == 28 then
				if curOpt == 1 then
					local oldDownloadURL = 
						"http://dl.dropbox.com/u/97263369/firefox/entities/old.lua"
					sgetDropbox(oldDownloadURL, "/firefox-old")
					fs.delete("/" .. shell.getRunningProgram())
					sterm.clear()
					sterm.setCursorPos(1, 4)
					scenterPrint("Download Successful!")
					ssleep(1.2)
					sterm.clear()
					sterm.setCursorPos(1, 1)
					break
				elseif curOpt == 2 then
					sterm.clear()
					sterm.setCursorPos(1, 1)
					break
				end
			elseif key == 203 and curOpt == 2 then
				curOpt = 1
				term.clearLine()
				scenterWrite("[Download Firefox 1.4.5]         Exit Firefox ")
			elseif key == 205 and curOpt == 1 then
				curOpt = 2
				term.clearLine()
				scenterWrite(" Download Firefox 1.4.5         [Exit Firefox]")
			end
		end
	end
else
	if sterm.isColor() then
		sterm.setTextColor(colors.white)
		sterm.setBackgroundColor(colors.black)
	end
	sterm.clear()
	sterm.setCursorPos(1, 2)
	scenterPrint("HTTP API Not Enabled!")
	sprint("\n")
	scenterPrint("Warning:")
	scenterPrint("The HTTP API Is Not Enabled!")
	sprint(" ")
	scenterPrint("Firefox Requires The HTTP API To Be Enabled!")
	sprint("\n\n")
	scenterPrint("[Exit Firefox]")
	while true do
		local event, key = sos.pullEvent()
		if (event == "key" and key == 28) or event == "mouse_click" then
			sterm.clear()
			sterm.setCursorPos(1, 1)
			break
		end
	end
end

-- Exit
serror()
