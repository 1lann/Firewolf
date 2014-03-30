--  -------- Mozilla Firefox
--  -------- Made by GravityScore and 1lann

--  -------- Original Idea from Rednet Explorer v2.4.1
--  -------- Rednet Explorer made by xXm0dzXx/CCFan11


--  -------- Ideas:
-- - Multiple servers running simultaneously


--  -------- To Do:
-- - Search to support blacklist/whitelist/antivirus/verified
-- - Do not delete old-startup, but rename old-startup1, old-startup2 ...
-- - Control-T to return to home


--  -------- Constants

-- Version
local firefoxVersion = "1.4.0"
local browserAgentTemplate = "Mozilla Firefox " .. firefoxVersion
browserAgent = ""

-- Server Identification
local serverID = "ctcraft"
local serverList = {ccnet = "CCServers", immibis = "turtle.dig()", ctcraft = "CTCraft", 
					noodle = "Noodle", ["firefox-14"] = "Experimental"}

-- Updating
local override = false
local autoupdate = "true"
local incognito = "false"
local debugging = false

-- Dropbox URLs
local firefoxURL = "http://dl.dropbox.com/u/97263369/" .. serverID .. "/firefox-stable.lua"
local databaseURL = "http://dl.dropbox.com/u/97263369/" .. serverID .. "/firefox-database.txt"
local serverURL = "http://dl.dropbox.com/u/97263369/" .. serverID .. "/firefox-server.lua"
local customEditURL = "http://dl.dropbox.com/u/97263369/" .. serverID .. "/custom-edit.lua"

-- Events
local openURLBarEvent = "firefox_open_url_bar_event"
local websiteLoadEvent = "firefox_website_loaded_event"

-- Webpage Variables
local website = ""
local homepage = ""
local history = {}
local searchBarHistory = {}
local exitApp = false

-- Prevent API Overrides
local function copyTable(oldTable)
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
local ftostring = tostring
local ftonumber = tonumber
local fpcall = pcall
local fperipheral = copyTable(peripheral)
local fsleep = sleep
local fprint = print
local fwrite = write

-- Data Locations
local rootFolder = "/.Firefox_Data"
local cacheFolder = rootFolder .. "/cache"
local serverFolder = rootFolder .. "/servers"
local serverSoftwareLocation = rootFolder .. "/server_software"
local customEditLocation = rootFolder .. "/custom_edit"
local settingsLocation = rootFolder .. "/settings"
local historyLocation = rootFolder .. "/history"
local firefoxLocation = "/" .. fshell.getRunningProgram()

local userBlacklist = rootFolder .. "/user_blacklist"
local userWhitelist = rootFolder .. "/user_whitelist"
local globalDatabase = rootFolder .. "/database"

-- Firefox 1.3 Support
local runningWebsite = ""


--  -------- Prompt Software

function prompt(list, dir, startCurSel, notControl)
	-- Functions
	local function drawArrows(word, x, y)
		fterm.setCursorPos(x, y)
		fwrite("[")
		fterm.setCursorPos(x + 1 + fstring.len(word), y)
		fwrite("]")
	end
	
	local function removeArrows(word, x, y)
		fterm.setCursorPos(x, y)
		fwrite(" ")
		fterm.setCursorPos(x + 1 + fstring.len(word), y)
		fwrite(" ")
	end

	-- Variables
	local curSel = 1
	if startCurSel ~= nil then
		curSel = startCurSel
	end
	local nc = false
	if notControl == true then nc = true end
	local c1 = 200
	local c2 = 208
	if dir == "horizontal" then c1 = 203 c2 = 205 end

	-- Draw
	for i = 1, #list do
		if list[i][2] == -1 then
			local w, h = fterm.getSize()
			list[i][2] = math.floor(w/2 - list[i][1]:len()/2) 
		end
		fterm.setCursorPos(list[i][2], list[i][3])
		fwrite(list[i][1])
	end
	drawArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])

	-- Selection
	while not(exitApp) do
		local event, key = fos.pullEvent("key")
		removeArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])
		if key == c1 then
			if curSel ~= 1 then curSel = curSel - 1 end
		elseif key == c2 then
			if curSel ~= #list then curSel = curSel + 1 end
		elseif key == 28 then
			return list[curSel][1]
		elseif key == 29 or key == 157 then
			if not(nc) then
				fos.queueEvent(openURLBarEvent)
				return nil
			end
		end
		drawArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])
	end
end

function scrollingPrompt(list, disLen, xStart, yStart)
	-- Functions 
	local function drawItems(items)
		for i = 1, #items do
			fterm.setCursorPos(xStart, i + yStart)
			fterm.clearLine(i + 4)
			fwrite("[ ]  " .. items[i])
		end
	end

	local function updateDisplayList(items, disLoc, disLen)
		local ret = {}
		for i = 1, disLen do
			local item = items[i + disLoc - 1]
			if item ~= nil then ftable.insert(ret, item) end
		end
		return ret
	end

	local function drawArrows(word, x, y)
		fterm.setCursorPos(x + 1, y)
		fwrite("x")
	end

	local function removeArrows(word, x, y)
		fterm.setCursorPos(x + 1, y)
		fwrite(" ")
	end

	-- Variables
	local disLoc = 1
	local disList = updateDisplayList(list, 1, disLen)
	local curSel = 1
	drawItems(disList)
	drawArrows(list[1], xStart, yStart + 1)
	
	-- Selection
	while true do
		local event, key = fos.pullEvent("key")
		removeArrows(list[curSel + disLoc - 1], xStart, curSel + yStart)
		if key == 200 then
			if curSel ~= 1 then 
				curSel = curSel - 1 
			else
				if disLoc ~= 1 then
					disLoc = disLoc - 1
					disList = updateDisplayList(list, disLoc, disLen)
					drawItems(disList)
				end
			end	
		elseif key == 208 then
			if curSel ~= #disList then 
				curSel = curSel + 1 
			else
				if disLoc + curSel - 1 ~= #list then
					disLoc = disLoc + 1
					disList = updateDisplayList(list, disLoc, disLen)
					drawItems(disList)
				end
			end
		elseif key == 28 then
			return list[curSel + disLoc - 1], false
		elseif key == 29 or key == 157 then
			fos.queueEvent(openURLBarEvent)
			return "", true
		end
		drawArrows(list[curSel + disLoc - 1], xStart, curSel + yStart)
	end
end


--  -------- Drawing Utilities

local function titleForPage(site)
	-- Preset titles
	local siteTitles = {{"firefox", "Mozilla Firefox"}, {"update", "Update Firefox"}, 
						{"upgrade", "Update Firefox"}, {"search", "Firefox Serach"}, 
						{"history", "Firefox History"}, {"server", "Server Management"}, 
						{"settings", "Firefox Settings"}, {"credits", "Firefox Credits"}, 
						{"whatsnew", "What's New"}, {"exit", nil}, {"", "All Sites"}}

	-- Search
	for i = 1, #siteTitles do
		if fstring.lower(siteTitles[i][1]) == fstring.lower(site) then
			return siteTitles[i][2]
		end
	end

	return nil
end

function clearPage(url)
	-- URL
	local w, h = fterm.getSize()
	local title = titleForPage(url)
	fterm.clear()
	fterm.setCursorPos(2, 1)
	fwrite("rdnt://" .. url)

	-- Title
	if title ~= nil then
		fterm.setCursorPos(w - fstring.len("  " .. title), 1)
		fwrite("  " .. title)
	end

	-- Line
	fterm.setCursorPos(1, 1)
	fwrite(fstring.rep("-", w))
	fprint(" ")
end

function centerPrint(text)
	local w, h = fterm.getSize()
	local x, y = fterm.getCursorPos()
	fterm.setCursorPos(math.ceil((w + 1)/2 - text:len()/2), y)
	fprint(text)
end

local function centerWrite(text)
	local w, h = fterm.getSize()
	local x, y = fterm.getCursorPos()
	fterm.setCursorPos(math.ceil((w + 1)/2 - text:len()/2), y)
	fwrite(text)
end

function leftPrint(text)
	local x, y = fterm.getCursorPos()
	fterm.setCursorPos(4, y)
	fwrite(text)
end

function rightPrint(text)
	local x, y = fterm.getCursorPos()
	local w, h = fterm.getSize()
	fterm.setCursorPos(w - text:len() - 1, y)
	fwrite(text)
end


--  -------- Filesystem Management

local function getDropbox(url, file)
	fsleep(0.01)
	while not(exitApp) do
		-- Request
		fhttp.request(url)
		fsleep(0.0000000001)
        while not(exitApp) do
        	local event, _, response = fos.pullEvent()
	        if event == "http_failure" then
				break
			elseif event == "http_success" then
				if response ~= nil then
					-- Put into file
					local text = response:readAll()
					local f = fio.open(file, "w")
					fsleep(0.01)
					f:write(text)
					fsleep(0.01)
					f:close()
					response:close()
					return "true"
				else
					return "false"
				end
			end
		end	
	end
end

local function upgradeFilesystem()
	if fs.exists("/.FirefoxData") then
		-- Shift
		fs.delete("/.temp_whitelist")
		if fs.exists("/.FirefoxData/firefox_whitelist") then 
			fs.move("/.FirefoxData/firefox_whitelist", "/.temp_whitelist") 
		end
		fs.delete("/.temp_blacklist")
		if fs.exists("/.FirefoxData/firefox_blacklist") then 
			fs.move("/.FirefoxData/firefox_blacklist", "/.temp_blacklist")
		end
		fs.delete("/.temp_server_prefs")
		if fs.exists("/.FirefoxData/fireServerPref") then 
			fs.move("/.FirefoxData/fireServerPref", "/.temp_server_prefs") 
		end

		-- Delete
		fs.delete("/.FirefoxData")
		fs.makeDir(rootFolder)
		fs.makeDir(serverFolder)

		-- Move
		if fs.exists("/.temp_whitelist") then 
			if fs.exists(userWhitelist) then fs.delete(userWhitelist) end
			fs.move("/.temp_whitelist", userWhitelist) 
		end
		if fs.exists("/.temp_blacklist") then 
			if fs.exists(userBlacklist) then fs.delete(userBlacklist) end
			fs.move("/.temp_blacklist", userBlacklist) 
		end
		if fs.exists("/.temp_server_prefs") then
			local f = fio.open("/.temp_server_prefs", "r")
			local serverName = f:read("*l")
			f:close()
			if fs.exists("/" .. serverName) and fs.isDir("/" .. serverName) then 
				fs.move("/" .. serverName, serverFolder .. "/" .. serverName) 
			end
		end
	end
end

local function resetFilesystem()
	-- Folders
	if not(fs.exists(rootFolder)) then 
		fs.makeDir(rootFolder)
	elseif not(fs.isDir(rootFolder)) then
		fs.move(rootFolder, "/Old_Firefox_Data_File")
		fs.makeDir(rootFolder)
	end
	if not(fs.exists(cacheFolder)) then fs.makeDir(cacheFolder) end
	if not(fs.exists(serverFolder)) then fs.makeDir(serverFolder) end

	-- Settings
	if not(fs.exists(settingsLocation)) then
		local f = fio.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = "true", incog = "false", home = "firefox"}))
		f:close()
	end

	-- Server software
	if not(fs.exists(serverSoftwareLocation)) then
		getDropbox(serverURL, serverSoftwareLocation)
	end

	-- Custom Edit
	if not(fs.exists(customEditLocation)) then
		getDropbox(customEditURL, customEditLocation)
	end

	-- History
	if not(fs.exists(historyLocation)) then
		local f = fio.open(historyLocation, "w")
		f:write(textutils.serialize({}))
		f:close()
	end

	-- Databases
	fs.delete(globalDatabase)
	for _, v in ipairs({globalDatabase, userWhitelist, userBlacklist}) do
		if not(fs.exists(v)) then
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
		fs.delete(firefoxLocation)
		fs.move(updateLocation, firefoxLocation)
		fshell.run(firefoxLocation)
		error()
	else
		fs.delete(updateLocation)
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
		if a ~= "exit" and a ~= "history" and history[1] ~= a then
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

local blacklistDatabase = {}
local whitelistDatabase = {}
local verifiedDatabase = {}
local antivirusDefinitions = {}

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
	while l ~= "START-DEFINITIONS" do
		l = f:read("*l")
		if l ~= nil and l ~= "" and l ~= "\n" and l ~= "START-VERIFIED" and 
		   l ~= "START-DEFINITIONS" and l:find("| |") then
		   	l = l:gsub("^%s*(.-)%s*$", "%1"):lower()
		    local a, b = l:find("| |")
		    local n = l:sub(1, a - 1)
		    local id = l:sub(b + 1, -1)
			ftable.insert(verifiedDatabase, {n, id})
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
	if not(fs.exists(userBlacklist)) then 
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
	if not(fs.exists(userWhitelist)) then 
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
	for i = 1, #whitelistDatabase do
		if whitelistDatabase[i][1] == site and whitelistDatabase[i][2] == ftostring(id) then
			return true
		end
	end

	return false
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

local function blacklistRedirectionBots()
	local suspected = {}
	for i = 1, 5 do
		local alphabet = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", 
				    	  "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "."}
		local name = ""
		for i = 1, math.random(6, 17) do
			name = name .. alphabet[math.random(1, 27)]
		end
		frednet.broadcast(name)

		clock = fos.clock()
		while fos.clock() - clock < 0.01 do
			local id = frednet.receive(0.01)
			if id ~= nil and verifyAgainstBlacklist(id) == false then
				local inSuspected = false
				for i = 1, #suspected do
					if suspected[i][1] == id then
						suspected[i][2] = suspected[i][2] + 1
						inSuspected = true
					end
				end

				if not(inSuspected) then
					ftable.insert(suspected, {id, 1})
					break
				end
			end
		end
	end

	for i = 1, #suspected do
		if suspected[i][2] > 2 then
			local f = fio.open(userBlacklist, "a")
			f:write(ftostring(suspected[i][1]) .. "\n")
			f:close()

			ftable.insert(blacklistDatabase, suspected[i][1])
		end
	end
end

local function updateDatabases()
	while not(exitApp) do
		fos.pullEvent(websiteLoadEvent)
		reloadDatabases()
	end
end


--  -------- Built-In Websites

local function webpageHome(site)
	-- Title
	local w, h = fterm.getSize()
	fprint("\n")
	centerPrint("        _,-='\"-.__               /\\_/\\   ")
	centerPrint("         -.}        =._,.-==-._.,  @ @._,")
	centerPrint("            -.__  __,-.   )       _,.-'  ")
	centerPrint("                 \"     G..m-\"^m m'       ")
	fprint(" ")
	leftPrint("  Welcome to Mozilla Firefox " .. firefoxVersion)

	-- Useful websites
	fterm.setCursorPos(1, 13)
	leftPrint("      rdnt://firefox")
	rightPrint("Welcome Page      \n")
	leftPrint("      rdnt://search")
	rightPrint("Search      \n")
	leftPrint("      rdnt://history")
	rightPrint("History      \n")
	leftPrint("      rdnt://credits")
	rightPrint("Credits      \n")
	leftPrint("      rdnt://exit")
	rightPrint("Exit      \n")
end

local function webpageSearch(site)
	-- Title and input
	centerPrint("Firefox Search Engine")
	fprint("\n")
	centerPrint("Enter 'firefox' to View Built-In Sites")
	fprint(" ")
	leftPrint("Search: ")
	local input = read():gsub("^%s*(.-)%s*$", "%1"):lower()

	-- Organise results
	local results = {}
	if input == "firefox" then 
		results = {"firefox", "update", "search", 
				   "whatsnew", "history", "settings", 
				   "server", "credits", "exit"}
	end

	-- Get items
	frednet.broadcast("frednet.api.ping.searchengine")
	while not(exitApp) do
		local _, i = frednet.receive(0)
		if i then
			if input == "" then
				ftable.insert(results, i)
			else
				if fstring.find(i, input) then
					ftable.insert(results, i)
				end
			end
		else
			break
		end
	end

	-- Draw
	clearPage(site)
	centerPrint("Firefox Search Engine")
	if #results ~= 0 then
		-- Organise
		local nResults = {}
		for i = 1, #results do
			ftable.insert(nResults, "rdnt://" .. results[i]:gsub("^%s*(.-)%s*$", "%1"):lower())
		end

		-- Prompt and redirect
		local ssite, ex = scrollingPrompt(nResults, 14, 4, 4)
		if not(ex) then
			redirect(ssite:gsub("rdnt://", ""))
		end
	else
		-- No items
		fprint("\n")
		centerPrint("No Search Results Found")
	end
end

local function webpageHistory(site)
	-- Title
	centerPrint("Firefox History")

	if #history ~= 0 then
		-- Organise
		local nHistory = {"Clear History"}
		for i = 1, #history do
			ftable.insert(nHistory, "rdnt://" .. history[i])
		end

		-- Prompt
		local web, ex = scrollingPrompt(nHistory, 14, 4, 4)
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
				fsleep(1.1)
				redirect("history")
			else
				-- Redirect
				redirect(web:gsub("rdnt://", ""))
			end
		end
	else
		-- No Items
		fprint("\n")
		centerPrint("No Items In History")
	end
end

local function webpageUpdate(site)
	-- Title
	fprint("\n")
	centerPrint("Firefox Force Update")
	
	-- Prompt for update
	local w, h = fterm.getSize()
	local opt = prompt({{"Continue", math.floor(w/4 - fstring.len("Continue")/2), 10}, 
						{"Cancel", math.ceil(w/4 - fstring.len("Cancel")/2 + w/2), 10}}, 
						"horizontal")
	if opt == "Continue" then
		-- Clear
		clearPage(site)
		fprint("\n")
		centerPrint("Firefox Force Update")
		fprint("\n\n\n")

		-- Update file
		centerPrint("Updating Firefox...")
		getDropbox(firefoxURL, "/.temp_firefox")
		fsleep(0.2)

		-- Draw
		clearPage(site)
		fprint("\n")
		centerPrint("Firefox Force Update")
		fprint("\n\n")
		centerPrint("Firefox Has Been Updated")

		-- Delete temp file
		fs.delete(firefoxLocation)
		fs.move("/.temp_firefox", firefoxLocation)
		prompt({{"Exit Firefox", -1, 14}}, "vertical", 1, true)

		-- Exit
		redirect("exit")
	elseif opt == "Cancel" then
		-- Draw
		clearPage(site)
		fprint("\n")
		centerPrint("Firefox Force Update")
		fprint("\n\n\n")
		centerPrint("Update Cancelled")
	end
end

local function webpageNewSite(site)
	centerPrint("Firefox Server Management")

	local l = fs.list(serverFolder)
	local s = {"New Server"}
	for i = 1, #l do
		if fs.isDir(serverFolder .. "/" .. l[i]) then
			ftable.insert(s, l[i])
		end
	end
	local server, ex = scrollingPrompt(s, 14, 4, 4)
	if not(ex) then
		if server == "New Server" then
			-- Get URL
			clearPage(site)
			centerPrint("Firefox Server Management")
			fprint("\n\n")
			leftPrint("Server URL:\n")
			leftPrint("    rdnt://")
			local url = read():lower():gsub(" ", "")
			fprint("\n")
			if url ~= "" then
				if url:find("/") then
					leftPrint("Server URL Invalid\n")
					leftPrint("Contains Illegal '/'\n")
					fsleep(1.4)
				elseif url:find("| |") then
					leftPrint("Server URL Invalid\n")
					leftPrint("Contains Illegal '| |'\n")
					fsleep(1.4)
				else
					leftPrint("Creating Server: " .. url)
					fsleep(0.35)

					local serverLoc = serverFolder .. "/" .. url
					fs.makeDir(serverLoc)
					local homeF = fio.open(serverLoc .. "/home", "w")
					homeF:write("fprint(\" \")\ncenterPrint(\"Welcome To " .. url .. "\")")
					homeF:close()
				end
			else
				leftPrint("Server URL Empty!")
				leftPrint("Could Not Create Server")
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
				leftPrint("Server: " .. server)

				local opt = prompt({{"Start Server", 5, 8}, {"Run On Startup", 5, 10}, 
									{"Edit Pages", 5, 12}, {"Delete Server", 5, 14}, 
									{"Back", 5, 16}}, "vertical")
				if opt == "Start Server" then
					fshell.run(serverSoftwareLocation, server, serverPath)
					frednet.open("top")
					frednet.open("left")
					frednet.open("right")
					frednet.open("back")
					frednet.open("front")
					frednet.open("bottom")
					redir = true
					break
				elseif opt == "Run On Startup" then
					fs.delete("/old-startup")
					if fs.exists("/startup") then fs.move("/startup", "/old-startup") end
					local f = fio.open("/startup", "w")
					f:write("fshell.run(\"" .. serverSoftwareLocation .. "\", \"" .. server .. 
							"\", \"" .. serverPath .. "\")")
					f:close()

					clearPage(site)
					centerPrint("Firefox Server Management")
					fprint("\n\n")
					centerPrint("Server Will Run on Startup")
					fsleep(0.9)
				elseif opt == "Edit Pages" then
					while not(exitApp) do
						clearPage(site)
						centerPrint("Firefox Server Management")
						fprint(" ")
						leftPrint("Server Pages:")

						local pages = {"Back", "New...", "Rename...", "Copy File...", "Delete..."}
						local a = fs.list(serverPath)
						for i = 1, #a do
							if fs.isDir(serverPath .. "/" .. a[i]) then
								a[i] = "[Directory] " .. a[i]
							end
							ftable.insert(pages, a[i])
						end

						local page, ex = scrollingPrompt(pages, 12, 4, 6)
						if not(ex) then
							if page == "Back" then 
								break
							elseif page == "New..." then
								fterm.setCursorPos(1, 5)
								fterm.clearLine()
								local w, h = fterm.getSize()
								local o = prompt({{"File", math.floor(w/4 - 
									fstring.len("File")/2), 5}, {"Folder", 
									math.ceil(w/4 - fstring.len("Folder")/2 + w/2), 5}}, "horizontal")
								if o == nil then
									return
								end
								fterm.setCursorPos(1, 5)
								fterm.clearLine()
								leftPrint("Name: ")
								local name = read():gsub(" ", ""):lower()
								if o == "File" then
									local f = fio.open(serverPath .. "/" .. name, "w")
									f:write(" ")
									f:close()
								elseif o == "Folder" then
									fs.makeDir(serverPath .. "/" .. name)
								end
							elseif page == "Rename..." then
								clearPage(site)
								centerPrint("Firefox Server Management")
								fprint(" ")
								leftPrint("Select Page to Rename:")
								local p = {"Cancel"}
								for i = 1, #a do
									if fs.isDir(serverPath .. "/" .. a[i]) then
										a[i] = "[Directory] " .. a[i]
									end
									ftable.insert(p, a[i])
								end

								local a, ex = scrollingPrompt(p, 12, 4, 6)
								if not(ex) then
									if a ~= nil and a ~= "Cancel" then
										fterm.setCursorPos(1, 5)
										fterm.clearLine()
										fterm.setCursorPos(1, 5)
										leftPrint("New Name: ")
										local name = read():gsub(" ", ""):lower()
										a = a:gsub("[Directory] ", "")
										fs.move(serverPath .. "/" .. a, serverPath .. "/" .. name)
									end
								else
									return
								end
							elseif page == "Copy File..." then
								fterm.setCursorPos(1, 5)
								fterm.clearLine()
								leftPrint("File To Copy: /")
								local file = "/" .. read()
								fterm.setCursorPos(1, 5)
								fterm.clearLine()
								if fs.exists(file) then
									leftPrint("Name: ")
									local na = read():gsub(" ", ""):lower()
									if fs.exists(serverPath .. "/" .. na) then
										fs.delete(serverPath .. "/" .. na)
									end
									fs.copy(file, serverPath .. "/" .. na)
								else
									leftPrint("File Does Not Exist!")
									fsleep(1.1)
								end
							elseif page == "Delete..." then
								clearPage(site)
								centerPrint("Firefox Server Management")
								fprint(" ")
								leftPrint("Select Page to Delete:")
								local p = {"Cancel"}
								for i = 1, #a do
									if fs.isDir(serverPath .. "/" .. a[i]) then
										a[i] = "[Directory] " .. a[i]
									end
									ftable.insert(p, a[i])
								end

								local a, ex = scrollingPrompt(p, 12, 4, 6)
								if not(ex) then
									if a ~= nil and a ~= "Cancel" then
										a = a:gsub("[Directory] ", "")
										fs.delete(serverPath .. "/" .. a)
									end
								else
									return
								end
							elseif page ~= nil and not(fs.isDir(serverPath .. "/" .. page)) then
								fterm.clear()
								fshell.run(customEditLocation, serverPath .. "/" .. page)
							end
						else
							return
						end
					end
				elseif opt == "Delete Server" then
					clearPage(site)
					centerPrint("Firefox Server Management")
					local w, h = fterm.getSize()
					local opt = prompt({{"Delete Server", 
										 math.floor(w/4 - fstring.len("Delete Server")/2), 9}, 
										{"Cancel", math.ceil(w/4 - fstring.len("Cancel")/2 + w/2), 
										9}}, "horizontal")
					if opt == "Delete Server" then
						clearPage(site)
						centerPrint("Firefox Server Management")
						fprint("\n\n")
						centerPrint("Deleted Server")
						fsleep(1.1)
						fs.delete(serverPath)
					elseif opt == "Cancel" then
						clearPage(site)
						centerPrint("Firefox Server Management")
						fprint("\n\n")
						centerPrint("Cancelled Delete Operation")
						fsleep(1.1)
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

local function webpageWhatsNew(site)
	-- Draw what's new
	fprint(" ")
	centerPrint("What's New in Firefox " .. firefoxVersion)
	fprint(" ")
	leftPrint("- Added Viewable History\n")
	leftPrint("- Added Incognito Mode\n")
	leftPrint("- Added Multiple Server Management\n")
	leftPrint("- Added Settings\n")
	leftPrint("- Added Reset Browser Button\n")
	leftPrint("- Added Customizable Homepage\n")
	leftPrint("- Added Auto-Search\n")
	leftPrint("- Re-Wrote Search Page\n")
	leftPrint("- Re-Designed Logo\n")
	leftPrint("- Removed Sites Page\n")
	leftPrint("- Removed Get ID Page \n")
	leftPrint("- Removed Refesh\n")
	leftPrint("- Added More Easter Eggs :D\n")
end

local function webpageSettings(site)
	local selected = 1
	while not(exitApp) do
		-- Clear
		clearPage(site)
		centerPrint("Firefox Settings")
		fprint(" ")
		leftPrint("Designed For: " .. serverList[serverID])

		-- Load different options
		local t1 = "Automatic Updating - Off"
		if autoupdate == "true" then t1 = "Automatic Updating - On" end
		local t2 = "Incognito Mode - Off"
		if incognito == "true" then t2 = "Incognito Mode - On" end
		local t3 = "Homepage - rdnt://" .. homepage

		-- Prompt the user
		local opt = prompt({{t1, 5, 8}, {t2, 5, 10}, {t3, 5, 12}, {"Reset Firefox", -1, 17}}, 
						   "vertical", selected)

		-- Respond depending on option
		if opt == nil then
			break
		elseif opt == t1 then
			if autoupdate == "true" then
				autoupdate = "false"
			else
				autoupdate = "true"
			end
			selected = 1
		elseif opt == t2 then
			if incognito == "true" then
				incognito = "false"
			else
				incognito = "true"
			end
			selected = 2
		elseif opt == t3 then
			fterm.setCursorPos(5, 12)
			fwrite("rdnt://")
			homepage = read():gsub("^%s*(.-)%s*$", "%1"):lower()
			selected = 3
		elseif opt == "Reset Firefox" then
			-- Clear
			clearPage(site)
			fprint(" ")
			centerPrint("Firefox Settings")

			-- Prompt
			local w, h = fterm.getSize()
			local a = prompt({{"Reset", math.floor(w/4 - fstring.len("Continue")/2), 9}, 
							  {"Cancel", math.ceil(w/4 - fstring.len("Continue")/2 + w/2), 9}},
							   "horizontal")

			-- Depending on option
			if a == "Reset" then
				-- Delete root folder
				fs.delete(rootFolder)

				-- Draw
				clearPage(site)
				fprint(" ")
				centerPrint("Firefox Settings")
				fprint("\n\n")
				centerPrint("Firefox Has Been Reset")
				fprint(" ")
				centerPrint("Press Any Key To Exit")
				fos.pullEvent("key")
				redirect("exit")
			elseif a == "Cancel" then
				-- Draw
				clearPage(site)
				fprint(" ")
				centerPrint("Firefox Settings")
				fprint("\n\n")
				centerPrint("Reset Cancelled")
				fsleep(1.6)
			end
			selected = 1
		end

		-- Save settings
		local f = fio.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = autoupdate, incog = incognito, home = homepage}))
		f:close()
	end
end

local function webpageCredits()
	-- Draw Credits
	fprint(" ")
	centerPrint("Firefox Credits")
	fprint(" ")
	centerPrint("Coded By:")
	centerPrint("1lann and GravityScore")
	fprint(" ")
	centerPrint("Logo By:")
	centerPrint("Magnetic Hamster")
	fprint("\n")
	centerPrint("Originally Based Off:")
	centerPrint("Rednet Explorer 2.4.1")
	fprint(" ")
	centerPrint("Rednet Explorer Made By:")
	centerPrint("xXm0dzXx/CCFan11")
end

local function loadWebpage(site)
	clearPage(site)
	fprint("\n")
	centerPrint("Connecting To Website...")
	peripheral = fperipheral
	browserAgent = browserAgentTemplate

	blacklistRedirectionBots()

	-- Get website
	local id, content, valid = nil
	local clock = fos.clock()
	frednet.broadcast(site)
	while fos.clock() - clock < 0.01 do
		-- Get
		id, content = frednet.receive(0.01)

		if id ~= nil then
			-- Validity check
			local av = verifyAgainstAntivirus(content)
			local bl = verifyAgainstBlacklist(id)
			local wl = verifyAgainstWhitelist(site, id)
			local vf = verifyAgainstVerified(site, id)
			valid = ""
			if bl and not(wl) then
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

	local cacheLoc = (cacheFolder .. "/" .. site:gsub("/", "$slazh$"))
	if valid ~= nil then
		-- Run page
		if valid == "blacklist" then
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
			centerPrint("The Website Could be Blocked, or Down")
		elseif valid == "antivirus" then
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
			local opt = prompt({{"Cancel", math.floor(w/4 - fstring.len("Cancel")/2), 17}, 
								{"Load Page", math.ceil(w/4 - fstring.len("Load Page")/2 + w/2), 17}}, 
								"horizontal")
			if opt == "Cancel" then
				fs.delete(cacheLoc)
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

		if valid == "true" then
			local f = fio.open(cacheLoc, "w")
			f:write(content)
			f:close()
			clearPage(site)
			fshell.run(cacheLoc)
		end
	else
		if fs.exists(cacheLoc) and site ~= "" then
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
			local opt = prompt({{"Load Cache", math.floor(w/4 - fstring.len("Load Cache")/2), 17}, 
								{"Delete Cache", 20, 17},
								{"Cancel", math.ceil(w/4 - fstring.len("Cancel")/2 + w/2), 17}}, 
								"horizontal")
			if opt == "Load Cache" then
				clearPage(site)
				fshell.run(cacheLoc)
			elseif opt == "Delete Cache" then
				fs.delete(cacheLoc)
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

			frednet.broadcast("frednet.api.ping.searchengine")
			while not(exitApp) do
				local _, i = frednet.receive(0)
				if i then
					if input == "" then
						ftable.insert(results, i)
					else
						if fstring.find(i, input) then
							ftable.insert(results, i)
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
				local nResults = {}
				for i = 1, #results do
					ftable.insert(nResults, "rdnt://" .. results[i]:gsub("^%s*(.-)%s*$", "%1"):lower())
				end

				local site, ex = scrollingPrompt(nResults, 14, 4, 4)
				if not(ex) then
					redirect(site:gsub("rdnt://", ""))
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
			end
		end
	end
end


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
	-- Render site
	runningWebsite = site
	browserAgent = browserAgentTemplate
	fos.queueEvent(websiteLoadEvent)
	if site == "firefox" then webpageHome(site)
	elseif site == "search" then webpageSearch(site)
	elseif site == "history" then webpageHistory(site)
	elseif site == "update" then webpageUpdate(site)
	elseif site == "server" then webpageNewSite(site)
	elseif site == "newsite" then redirect("server")
	elseif site == "whatsnew" then webpageWhatsNew(site)
	elseif site == "settings" then webpageSettings(site)
	elseif site == "credits" then webpageCredits(site)
	elseif site == "getinfo" then
		-- Title
		clearPage(site)
		fprint(" ")
		centerPrint("Get Website Information")
		fprint("\n\n")
		leftPrint("Enter URL: ")
		local url = read():gsub("^%s*(.-)%s*$", "%1"):lower()

		-- Get website
		local id, content, valid = nil
		local av, bl, wl, vf = nil
		local clock = fos.clock()
		frednet.broadcast(url)
		while fos.clock() - clock < 0.05 do
			-- Get
			id, content = frednet.receive(0.05)

			if id ~= nil then
				-- Validity check
				av = verifyAgainstAntivirus(content)
				bl = verifyAgainstBlacklist(id)
				wl = verifyAgainstWhitelist(url, id)
				vf = verifyAgainstVerified(url, id)
				valid = ""
				if bl and not(wl) then
					valid = "blacklist"
				elseif av and not(vf) then
					valid = "antivirus"
				else
					valid = "true"
					break
				end
			end
		end

		if valid ~= nil then
			-- Print information
			clearPage(site)
			fprint(" ")
			centerPrint("Get Website Information")
			fprint("\n")
			leftPrint("Site: " .. url .. "\n")
			fprint(" ")
			leftPrint("ID: " .. id .. "\n")
			if bl then
				leftPrint("Site Is Blacklisted\n")
			end if wl then
				leftPrint("Site Is Whitelisted\n")
			end 
			fprint(" ")
			if av then
				leftPrint("Site Triggered Antivirus\n")
			end if vf then
				leftPrint("Site Is Verified\n")
			end
		else
			-- Not Found
			clearPage(site)
			fprint(" ")
			centerPrint("Get Website Information")
			fprint("\n")
			centerPrint("Page Not Found")
		end
	elseif site == "kittez" or site == "kitten" or site == "kitteh" then
		-- Easter Egg :D
		fterm.clear()
		fterm.setCursorPos(1, 2)
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
		fprint(" ")
		centerPrint("Firefox Kitteh Is Not Amused...")
		centerPrint("An Easter Egg Brought to You By GravityScore :D")
		fsleep(6)
		fterm.clear()
		fterm.setCursorPos(1, 1)
		fos.shutdown()
	elseif site == "exit" then
		-- Exit client
		fterm.clear()
		fterm.setCursorPos(1, 1)
		centerPrint("Thank You for Using Mozilla Firefox " .. firefoxVersion)
		centerPrint("Made by 1lann and GravityScore")
		return "exit"
	else
		-- Load the site
		loadWebpage(site)
	end
end

function redirect(site)
	-- Convert site
	local url = site:gsub("^%s*(.-)%s*$", "%1"):lower()
	if site == "home" then
		url = homepage
	end

	-- Load site
	appendToHistory(url)
	clearPage(url)
	local opt = renderWebpage(url)
	if opt == "exit" then
		exitApp = true
		error()
	end
end

local function manageWebpages()
	while not(exitApp) do
		-- Render Page
		clearPage(website)
		local opt = renderWebpage(website)
		if opt == "exit" then
			exitApp = true
			error()
		end

		-- Wait for URL bar open
		fos.pullEvent(openURLBarEvent)
		local url = enterURL()
		if url == "home" then
			website = homepage
		else
			website = url
		end
	end
end

local function waitForURLEnter()
	while not(exitApp) do
		-- Wait for URL Bar Open
		_, key = fos.pullEvent("key")
		if key == 29 or key == 157 then
			fos.queueEvent(openURLBarEvent)
		end
	end
end


--  -------- Firefox 1.3 Support

function cfprint(text)
	centerPrint(text)
end

function reDirect(site)
	redirect(site)
end

function clearArea()
	clearPage(runningWebsite)
end


--  -------- Main

local function startup()
	-- Logo
	fterm.clear()
	fterm.setCursorPos(1, 3)
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
	fprint("\n\n")
	centerWrite("Cleaning up Firefox Data folder...")
	-- Filesystem
	upgradeFilesystem()
	resetFilesystem()

	-- Databases
	term.clearLine()
	centerWrite("Downloading Databases...")
	reloadDatabases()

	-- Load settings
	term.clearLine()
	centerWrite("Loading Settings...")
	local f1 = fio.open(settingsLocation, "r")
	local set = textutils.unserialize(f1:read("*l"))
	homepage = set.home
	website = homepage
	if not override then
	autoupdate = set.auto
	incognito = set.incog
	end
	browserAgent = browserAgentTemplate
	f1:close()

	local f2 = fio.open(historyLocation, "r")
	history = textutils.unserialize(f2:read("*l"))
	f2:close()
	
	term.clearLine()
	centerWrite("Checking for Updates...")
	-- Update
	if autoupdate == "true" then
		updateClient()
		fsleep(0.1)
	else
		fsleep(0.65)
	end
	-- Start websites
	if debugging then
		fparallel.waitForAny(manageWebpages, waitForURLEnter, updateDatabases)
	else
		while not(exitApp) do
			fterm.setCursorBlink(false)
			fpcall(fparallel.waitForAny(manageWebpages, waitForURLEnter, updateDatabases))
		end
	end
end

-- Open Rednet
frednet.open("top")
frednet.open("left")
frednet.open("right")
frednet.open("back")
frednet.open("front")
frednet.open("bottom")

-- Start App
startup()

-- Close Rednet
frednet.close("top")
frednet.close("left")
frednet.close("right")
frednet.close("back")
frednet.close("front")
frednet.close("bottom")