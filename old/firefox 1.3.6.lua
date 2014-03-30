--  -------- Mozilla Firefox
--  -------- Designed and Programmed by 1lann and GravityScore

--  -------- Originally Based off RednetExplorer v2.4.1
--  -------- RednetExplorer Originally Made by xXm0dzXx/CCFan11


--  -------- Features to Come

-- 1. Unified Title and URL Bar 			1.4
-- 2. Server Managing						1.4
-- 4. View History 							1.3.5
-- 5. Upgraded Help 						1.4
-- 6. Preferences							1.4
--   1. Auto-Updating on/off
--   2. Change Homepage
-- 	 3. Ability to download pre-releases (off unstable)
--   4. Reset Firefox
-- 7. Sites: Description of Each  			1.3.4


--  -------- Variables

-- Prevent function overrides
local sParallel = parallel
local sPcall = pcall
local sString = string
local sRednet = rednet
local sTable = table
local sOs = os
local sShell = shell
local sFs = fs
local sIo = io


-- Version
local firefoxVersion = "1.3.6"

-- Title
local firefoxTitle = "Mozilla Firefox " .. firefoxVersion
local firefoxServerTitle = "Firefox Server " .. firefoxVersion
local title = firefoxTitle

-- Pastebin IDs
local firefoxURL = "http://dl.dropbox.com/u/97263369/immibis/firefox-stable.lua"
local databaseURL = "http://dl.dropbox.com/u/97263369/immibis/firefox-database.txt"
local serverURL = "http://dl.dropbox.com/u/97263369/immibis/firefox-server.lua"

-- Data Locations
local root = "/.FirefoxData"
local blacklistLoc = root .. "/firefox_blacklist"
local whitelistLoc = root .. "/firefox_whitelist"
local definitionsLoc = root .. "/firefox_definitions"
local firefoxLoc = "/" .. sShell.getRunningProgram()
local website = "home"

-- Other
exitFirefox = false
local firstOpen = true
local quickHistory = {}
local websiteRunning = false
local redirection = false
local webSecure = false
local designedFor = "Turtle.dig() Server: 122.59.227.101"

local autoUpdate = true
local debugging = false

-- Open Rednet
sRednet.open("top")
sRednet.open("left")
sRednet.open("right")
sRednet.open("back")
sRednet.open("front")
sRednet.open("bottom")


-- Quickly debug a message 
local function debug(msg)
	term.setCursorPos(1,1)
	term.clearLine()
	write(tostring(msg))
	sleep(3)
end

--  -------- Prompt Function

-- Prompt the user for an input
local function prompt(list, dir)
	--Variables
	local curSel = 1
	local c1 = 200
	local c2 = 208
	if dir == "horizontal" then c1 = 203 c2 = 205 end
	
	--Draw words
	for i = 1, #list do
		if list[i][2] == 1 then list[i][2] = 2
		elseif list[i][2] + sString.len(list[i][1]) >= 50 then 
			list[i][2] = 49 - sString.len(list[i][1]) 
		end
		
		term.setCursorPos(list[i][2], list[i][3])
		write(list[i][1])
	end
	
	--Functions
	local function drawArrows(word, x, y)
		--Draw arrows
		term.setCursorPos(x, y)
		write("[")
		term.setCursorPos(x + 1 + sString.len(word), y)
		write("]")
	end
	
	local function removeArrows(word, x, y)
		--Remove current arrows
		term.setCursorPos(x, y)
		write(" ")
		term.setCursorPos(x + 1 + sString.len(word), y)
		write(" ")
	end
	
	--Draw arrows
	drawArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])
	
	--Start loop
	while true do
		--Get the key
		local event, key = sOs.pullEvent("key")
		
		--Remove arrows
		removeArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])
		
		if key == c1 then
			--Subtract
			if curSel ~= 1 then
				curSel = curSel - 1
			end
		elseif key == c2 then
			--Add
			if curSel ~= #list then
				curSel = curSel + 1
			end
		elseif key == 28 then
			--Enter
			return list[curSel][1]
		end
		
		--Draw Arrows
		drawArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])
	end
end

--  -------- Drawing

-- Print text in the center of the screen
function cPrint(text)
	local w, h = term.getSize()
	local x, y = term.getCursorPos()
	term.setCursorPos(math.ceil((w / 2) - (text:len() / 2)), y)
	print(text)
end

-- Clear page apart from title and website name
function clearArea()
	term.clear()
	term.setCursorPos(1, 1)
	cPrint(title)
	cPrint("rdnt://" .. website .. "\n")
end

--  -------- Utilities
-- Get code from pastebin
local function getPastebin(code, location)
	sleep(0.01)
	while true do
		http.request(code)
		sleep(0.0000000001)
        while true do
        	event, a, response = sOs.pullEvent()
	        if event == "http_failure" then
				break
			elseif event == "http_success" and response ~= nil then
				local pastebintext = response:readAll()
				f = sIo.open(location, "w")
				sleep(0.01)
				f:write(pastebintext)
				sleep(0.01)
				f:close()
				response:close()
				return
			end
		end	
	end
end

--  -------- Database Functions

-- Variables
local bDatabase = {}
local bvIDs = {}
local bvAddresses = {}
local bType = nil
local secureIDs = {}
local secureAddresses = {}
local avDefinitions = {}

-- Download and update the database of servers (white and blacklists)
local function getDatabase()
	-- Get database from pastebin
	getPastebin(databaseURL, root .. "/fireDatabase")

	local f = sIo.open(root .. "/fireDatabase", "r")
	bDatabase = {}
	readData = f:read("*l")
	while readData ~= "START-DEFINITIONS" do
		sTable.insert(bDatabase, readData)
		readData = f:read("*l")
	end
	avDefinitions = {}
	readData = f:read("*l")
	while readData ~= "START-WHITELIST" do
		sTable.insert(avDefinitions, readData)
		readData = f:read("*l")
	end
	bvIDs = {}
	bvAddresses = {}
	readData = f:read("*l")
	bType = "url"
	while readData ~= "START-VERIFIED" do
		if bType == "url" then
			sTable.insert(bvAddresses, readData)
			bType = "id"
		else
			sTable.insert(bvIDs, readData)
			bType = "url"
		end
		readData = f:read("*l")
	end
	secureIDs = {}
	secureAddresses = {}
	readData = f:read("*l")
	bType = "url"
	while readData ~= "END-DATABASE" do
		if bType == "url" then
			sTable.insert(secureAddresses, readData)
			bType = "id"
		else
			sTable.insert(secureIDs, readData)
			bType = "url"
		end
		readData = f:read("*l")
	end
	f:close()

	if not(sFs.exists(blacklistLoc)) then 
		f = sIo.open(blacklistLoc, "w") f:write("\n") f:close()
	else
		f = sIo.open(blacklistLoc, "r")
		for readData in f:lines() do
			sTable.insert(bDatabase, readData)
		end
		f:close()
	end

	if not(sFs.exists(definitionsLoc)) then 
		f = sIo.open(definitionsLoc, "w") f:write("\n") f:close()
	else
		f = sIo.open(definitionsLoc, "r")
		for readData in f:lines() do
			sTable.insert(avDefinitions, readData)
		end
		f:close()
	end


	if not sFs.exists(whitelistLoc) then 
		f = sIo.open(whitelistLoc, "w") f:write("\n") f:close()
	else
		bType = "url"
		f = sIo.open(whitelistLoc, "r")
		local x = 1 
		local bnLines = 0
		for readData in f:lines() do
			bnLines = bnLines+1
			if bType == "url" then
				sTable.insert(bvAddresses, readData)
				bType = "id"
			else
				sTable.insert(bvIDs, readData)
				bType = "url"
			end
		end
		f:close()
		if #bvAddresses > #bvIDs then sTable.remove(bvAddresses, #bvAddresses)
		elseif #bvAddresses < #bvIDs then sTable.remove(bvIDs, #bvIDs) end
	end

	return
end

function randomName()
alphabet= { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "." }
rName = ""
for i = 1, math.random(5,15) do
local rName = rName .. alphabet[math.random(1,27)]
end
return rName
end

-- Check if the database contains an object
local function dbContains(object, dbase)
	for i = 1, #dbase do
		if tostring(object) == dbase[i] then
			return true, i
		end
	end

	return false
end

-- Constantly Update the Database Upon Webpage Load
local function autoDatabase()
	while true do
		local aDE = sOs.pullEvent()
		if aDE == "firefoxDoneLoading" then
			getDatabase()
		end
	end
end

--  -------- Verifing Websites

-- Verify the website against the whitelist
local function isVerified(vWebsite, vID)
	-- Verify an ID
	if sString.find(vWebsite, "/") then
		local vFind = sString.find(vWebsite, "/")
		vWebsite = sString.sub(vWebsite, 1, vFind - 1)
	end

	for i = 1, #bvAddresses do
		if vWebsite == sString.lower(bvAddresses[i]) then
			if tostring(vID) == bvIDs[i] then
				return "good"
			else
				return "bad"
			end
		end
	end

	return "unknown"
end

local function isSecure(secWebsite, secID)
	-- Verify an ID
	for i = 1, #secureAddresses do
		if secWebsite == sString.lower(secureAddresses[i]) then
			if tostring(secID) == secureIDs[i] then
				return true
			else
				return false
			end
		end
	end

	return false
end

-- Check a database entry against the database
local function isBad(number)
	for i = 1, #bDatabase do
		if tostring(number) == bDatabase[i] then
			return true
		end
	end

	return false
end

local function checkWebsite(dataCheck)
	for i = 1, #avDefinitions do
		if sString.find(dataCheck, avDefinitions[i], 1, true) and avDefinitions[i] ~= nil and avDefinitions[i] ~= "" and avDefinitions[i] ~= "\n" then
			return true
		end
	end
	return false
end


-- Check if a website it malicious
local function checkMalicious()
	local suspected = {}
	local times = {}
	for i = 1, 5 do
		sRednet.broadcast(randomName())
		startClock = sOs.clock()
		while sOs.clock() - startClock < 0.1 do
			local a = sRednet.receive(0.05)
			if a ~= nil then
				dbState, dbPos = dbContains(a, suspected)
				if isBad(a) then
				elseif not dbState then
					sTable.insert(suspected, tostring(a)) 
					sTable.insert(times, 1)
					break
				else
					local newTimes = times[dbPos] + 1
					times[dbPos] = newTimes
				end
			end
		end
	end

	for i =1, #suspected do
		if times[i] > 2 then
			f = sIo.open(blacklistLoc, "a")
			f:write("\n" .. suspected[i])
			f:close()
			sTable.insert(bDatabase, suspected[i])
		end
	end
end

--  -------- File System

-- Update the file system from previous versions
local function resetFileSystem()
	if not sFs.exists(root) then
		sFs.makeDir(root)
		sFs.makeDir(root .. "/cache")
	elseif not sFs.isDir(root) then
		sFs.delete(root)
		sFs.makeDir(root)
		sFs.makeDir(root .. "/cache")
	end

	if sFs.exists("/fireverify") then sFs.move("/fireverify", whitelistLoc) end
	if sFs.exists("/firelist") then sFs.move("/firelist", blacklistLoc) end
	if sFs.exists("/firefox_whitelist") then sFs.move("/firefox_whitelist", whitelistLoc) end
	if sFs.exists("/firefox_blacklist") then sFs.move("/firefox_blacklist", blacklistLoc) end
	if sFs.exists("/.fireServerPref") then sFs.move("/.fireServerPref", root .. "/fireServerPref") end

	sFs.delete("/.fireDatabase")
	sFs.delete("/.fireVerify")
end

-- Update Firefox client
local function autoUpdater()
	if autoUpdate then
		sleep(0.01)
		getPastebin(firefoxURL, root .. "/firefoxClientUpdate")
		sleep(0.01)
		local f = sIo.open(root .. "/firefoxClientUpdate", "r")
		local clientUpdate = f:read("*a")
		f:close()

		local ff = sIo.open(firefoxLoc)
		local currentClient = ff:read("*a")
		ff:close()

		if currentClient ~= clientUpdate then
			sFs.delete(firefoxLoc)
			sFs.move(root .. "/firefoxClientUpdate", firefoxLoc)
			sShell.run(firefoxLoc)
			error()
		end
	end
end

--  -------- Webpage Loading

function warning()
error("WARNING: MALICIOUS WEBSITE")
end

-- Browser controls
local function browserControl()
	websiteRunning = false
	term.setCursorBlink(false)
	if exitFirefox then error() end
	setTitle()
	sOs.queueEvent("firefoxDoneLoading")

	local w, h = term.getSize()
	term.setCursorPos(1, h)
	write(" Control to Surf the Web")
	term.setCursorPos(w - sString.len("F5 to Refresh"), h)
	write("F5 to Refresh")
	
	while true do
		local e, k = sOs.pullEvent("key")
		if k == 63 then
			loadWebpage()
			break
		elseif k == 29 then
			term.setCursorPos(1,2)
			term.clearLine()
			write(" rdnt://")
			website = read(nil, quickHistory)
			loadWebpage()
			break
		end
	end
end

-- Set the webpage title
function setTitle(newTitle)
	title = newTitle
	if title == nil then
		title = firefoxTitle
	elseif title:len() == 0 then
		title = firefoxTitle
	end

	term.setCursorPos(1, 1)
	term.clearLine()
	cPrint(title)
	term.setCursorPos(1, 2)
	term.clearLine()
	cPrint("rdnt://" .. website .. "\n")
end

-- Create webiste
local function createSite(websitename)
	term.clear()
	term.setCursorPos(1, 2)
	print("Creating Site: " .. websitename)
	print("Please Wait...")

	f = sIo.open(root .. "/fireServerPref", "w")
	f:write(websitename)
	f:close()
	getPastebin(serverURL, root .. "/firefoxServerUpdater")
	sShell.run(root .. "/firefoxServerUpdater")
	exitFirefox = true
	error()
end

-- Redirect the user to a different page
function reDirect(url)
	redirection = true
	website = url
	loadWebpage()
end

-- Load the website
function loadWebpage()
	if exitFirefox then error() end
	if websiteRunning and not redirection then
		browserControl()
	else
		redirection = false
		websiteRunning = true
		title = firefoxTitle
		website = website:lower()

		clearArea()
		sTable.insert(quickHistory, website)
		if website == "home" then
			if firstOpen then
				term.clear()
				term.setCursorPos(1, 4)
				cPrint("         _____  _   ______   _____ ")
				cPrint("~~~~~~~ / ___/ / / / _   /  / ___/ ")
				cPrint("------ / /__  / / / /_/ /  / /_    ")
				cPrint("~~~~~ / ___/ / / / _  _/  / __/    ")
				cPrint("---- / /    / / / / \\ \\  / /___    ")
				cPrint("~~~ / /    /_/ /_/   \\_\\/_____/    ")
				cPrint("-- / /  _,-=._              /|_/|  ")
				cPrint("~ /_/  `-.}   `=._,.-=-._.,  @ @._,")
				cPrint("          `. _ _,-.   )      _,.-' ")
				cPrint("                   G.m-\"^m`m'       ")
				print(" ")
				cPrint(" Mozilla Firefox is Now Loading... ")
				--if not(autoUpdate) then sleep(0.75) end
				--autoUpdater()
				firstOpen = false
				sOs.queueEvent("firefoxDoneLoading")
			end

			clearArea()
			cPrint("Welcome to " .. firefoxTitle)
			print(" ")
			cPrint("This version of firefox is designed for")
			cPrint(designedFor)
			print(" ")

			if autoUpdate then
				print(" Automatic Updating is On")
			else
				print(" Automatic Updating is Off")
			end

			local w, h = term.getSize()
			print(" ")
			term.setCursorPos(2, 11)
			write("rdnt://sites")
			term.setCursorPos(w - 1 - sString.len("See Sites"), 11)
			write("See Sites")
			term.setCursorPos(2, 12)
			write("rdnt://whatsnew")
			term.setCursorPos(w - 1 - sString.len("See Whats New in " .. firefoxVersion), 12)
			write("See Whats New in " .. firefoxVersion)
			term.setCursorPos(2, 13)
			write("rdnt://credits")
			term.setCursorPos(w - 1 - sString.len("View Credits"), 13)
			write("View Credits")
			term.setCursorPos(2, 14)
			write("rdnt://exit")
			term.setCursorPos(w - 1 - sString.len("Exit Firefox"), 14)
			write("Exit Firefox")
		elseif website == "" or website == " " then
			clearArea()
			print(" ")
			cPrint("OMFG Y U NO ENTER SOMETING?!?!")
		elseif website == "exit" then
			term.clear()
			term.setCursorPos(1,1)
			print("Thank You for Using Firefox!")
			sleep(0.1)

			exitFirefox = true
			return
		elseif website == "search" then
			sleep(0)
			cPrint("Firefox Search")
			print(" ")
			write(" Search: ")
			input = read()
			sRednet.broadcast("rednet.api.ping.searchengine")
			while true do
				local a, i = sRednet.receive(0)
				if i then
					if input == "" then
						print(" " .. i)
					else
						if sString.find(i, input) then
							print(" " .. i)
						end
					end
				else
					break
				end
			end
		elseif website == "update" then
			cPrint("Force Update Firefox")
			print(" ")
			local o = prompt({{"Yes", 11, 8}, {"No", 36, 8}},  "horizontal")
			if o == "Yes" then
				clearArea()
				cPrint("Updating...")
				getPastebin(firefoxURL, firefoxLoc)

				clearArea()
				cPrint("Firefox Has Been Updated")
				cPrint("Press Any Key to Restart")
				sOs.pullEvent("key")
				sShell.run(firefoxLoc)
				error()
			else
				clearArea()
				cPrint("Cancelled Update")
			end
		elseif website == "whatsnew" then
			cPrint("New Fetures in Firefox " .. firefoxVersion)
			print(" ")
			print(" Improved UI")
			print(" Improved Website Verification")
			print(" Added Built-In Antivirus")
			print(" Moved from Pastebin to Dropbox")
			print(" Fixed Bugs that Cause Crashing")
		elseif website == "sites" then
			cPrint("Standard Firefox Sites")
			print(" ")
			print(" rdnt://home")
			print(" rdnt://search")
			print(" rdnt://update")
			print(" rdnt://whatsnew")
			print(" rdnt://sites")
			print(" rdnt://search")
			print(" rdnt://getid")
			print(" rdnt://newsite")
			print(" rdnt://credits")
			print(" rdnt://exit")
			print(" ")
		elseif website == "getid" then
			cPrint("Get Server Computer ID")
			term.setCursorPos(2, 7)
			write("Enter Server URL: ")
			local url = read()

			local i, m = nil
			if sString.len(url) ~= 0 then
				sRednet.broadcast(url)
				i, m = sRednet.receive(0.1)
			end

			clearArea()
			cPrint("Get Server Computer ID")
			print(" ")

			term.setCursorPos(1, 7)
			if m ~= nil and i ~= nil then
				print(" Server Computer ID: " .. i)
			else
				print(" Could Not Get Computer ID")
			end
		elseif website == "credits" then
			local w, h = term.getSize()

			term.setCursorPos(1, 4)
			cPrint("Firefox Credits")
			print(" ")
			term.setCursorPos(2, 7)
			write("Designed and Coded by:")
			term.setCursorPos(w - 1 - sString.len("1lann and GravityScore"), 7)
			write("1lann and GravityScore")
			term.setCursorPos(2, 8)
			write("Finding Bugs and Flaws:")
			term.setCursorPos(w - 1 - sString.len("_Kyouko/Pinkishu"), 8)
			write("_Kyouko/Pinkishu")
			term.setCursorPos(2, 10)
			write("Based off:")
			term.setCursorPos(w - 1 - sString.len("Rednet Explorer v2.4.1"), 10)
			write("Rednet Explorer v2.4.1")
			term.setCursorPos(2, 11)
			write("Rednet Explorer Made by:")
			term.setCursorPos(w - 1 - sString.len("xXm0dzXx/CCFan11"), 11)
			write("xXm0dzXx/CCFan11")
		elseif website == "newsite" then
			term.setCursorPos(1, 4)
			cPrint("Use This Computer as a Webserver")
			local opt = prompt({{"Yes", 11, 6}, {"No", 36, 6}}, "horizontal")
			
			if opt == "Yes" then
				clearArea()
				if sFs.exists(root .. "/fireServerPref") then
					f = sIo.open(root .. "/fireServerPref", "r")
					websitename = f:read("*l")
					f:close()

					if sFs.isDir("/" .. websitename) then
						cPrint("A Previous Server Setup has Been Detected")
						cPrint("For Site: " .. websitename)
						cPrint("Use This Setup")
						local opt = prompt({{"Yes", 11, 9}, {"No", 36, 9}}, "horizontal")

						if opt == "Yes" then
							createSite(websitename)
						end
					end
				end

				term.clear()
				term.setCursorPos(1, 1)
				cPrint(title)
				term.setCursorPos(2, 4)
				write("Website Name: ")
				websitename = read()
				f = sIo.open(root .. "/fireServerPref", "w")
				f:write(websitename)
				f:close()

				term.clear()
				term.setCursorPos(1, 1)
				cPrint(title .. "\n")
					
				if sFs.exists("/" .. websitename) and not(sFs.isDir("/" .. websitename)) then
					sFs.move("/" .. websitename, root .. "/firefoxtemphome")
					sFs.makeDir("/" .. websitename)
					sFs.move(root .. "/firefoxtemphome", "/" .. websitename .. "/home")
					print(" An Old Website Has Been Detected")
					print(" It Has Been Moved To: ")
					print(" /" .. websitename .. "/home")
					print(" ")
				else
					sFs.makeDir("/" .. websitename)
				end

				sRednet.broadcast(sString.lower(websitename))
				local i, me = sRednet.receive(0.5)
				if i ~= nil then
					print(" WARNING: This Domain Name May Already Be In Use")
					print(" ")
				end

				print(" The Website Files can be Found In:")
				print(" /" .. websitename)
				print(" The Homepage is Located At:")
				print(" /" .. websitename .. "/home")
				print(" ")

				print(" Edit the Homepage of the Website?")
				local o = prompt({{"Yes", 11, 14}, {"No", 36, 14}}, "horizontal")
				if o == "Yes" then
					sShell.run("/rom/programs/edit", "/" .. websitename .. "/" .. "home")
				elseif o == "No" then
					if not sFs.exists("/" .. websitename .. "/" .. "home") then
						local f = sIo.open("/" .. websitename .. "/" .. "home", "w")
						f:write("print(\" \")\nprint(\"Welcome to " .. websitename .. "\")")
					end

					f:close()
				end
				
				term.clear()
				term.setCursorPos(1, 1)
				createSite(websitename)
			end
		else
			title = firefoxTitle
			clearArea()
			print(" Connecting to Website...")

			checkMalicious()
			sRednet.broadcast(website)
			local fWebsite = ""
			if sString.find(website, "/") then
				fWebsite = sString.gsub(website, "/", "$slazh$")
			else
				fWebsite = website
			end

			local website1 = root .. "/cache/" .. fWebsite
			local startClock = sOs.clock()
			local id, message = nil
			while sOs.clock() - startClock < 0.2 do 
				id, message = sRednet.receive(0.1)
				if not isSecure(website, id) then
					webSecure = false
					local vResult = isVerified(website, id)
					if vResult == "bad" then message = nil
					elseif vResult == "good" then break
					elseif vResult == "unknown" and isBad(id) == false then break
					else message = nil
					end
				else
					webSecure = true
					break
				end
			end

			local function drawError()
				clearArea()
				cPrint(" _____                         _ ")
				cPrint("|  ___|                       | |")
				cPrint("| |__  _ __  _ __  ___   _ __ | |")
				cPrint("|  __|| '__|| '__|/ _ \\ | '__|| |")
				cPrint("| |___| |   | |  | (_) || |   |_|")
				cPrint("\\____/|_|   |_|   \\___/ |_|   (_)")
				print(" ")
				cPrint("Unable to Connect to Website")
				cPrint("The Website May Be Down or Blocked")
			end

			if message == nil then
				if sFs.exists(website1) then
					clearArea()
					cPrint("Unable to Connect to Website")
					cPrint("Resort to Cached Version?")
					local o = prompt({{"Yes", 7, 8}, {"No", 16, 8}, {"Delete Cached Version", 24, 8}}, "horizontal")
					if o == "Yes" then
						clearArea()
						websiteRunning = true
						sShell.run(website1)
					elseif o == "No" then
						drawError()
					else
						sFs.delete(website1)
						clearArea()
						cPrint("Deleted cached version!")
					end
				else 
					drawError()
				end
			else
				if not webSecure then
	                if checkWebsite(message) then
	                	clearArea()
						cPrint("  ___   _      ___________ _____ _ ")
						cPrint(" / _ \\ | |    |  ___| ___ \\_   _| |")
						cPrint("/ /_\\ \\| |    | |__ | |_/ / | | | |")
						cPrint("|  _  || |    |  __||    /  | | | |")
						cPrint("| | | || |____| |___| |\\ \\  | | |_|")
						cPrint("\\_| |_/\\_____/\\____/\\_| \\_| \\_/ (_)")
						print(" ")
						cPrint("The Website you are Trying to Access has Been")
						cPrint("Detected to be Malicious. It is Highly")
						cPrint("Recommended to Blacklist this Server")
					
						local aO = prompt({{"Blacklist this Server", 15, 15}, {"Go to Homepage", 18, 16}, {"Continue Loading", 17, 17}}, "vertical")
						if aO == "Blacklist this Server" then
							local f = sIo.open(blacklistLoc, "a")
							f:write("\n" .. tostring(id))
							f:close()
							sTable.insert(bDatabase, tostring(id))
							clearArea()
							cPrint("Added to the blacklist!")
							cPrint("The blacklist can be accessed from")
							cPrint("/.FirefoxData/firefox_blacklist")
						elseif aO == "Go to Homepage" then
							websiteRunning = false
							reDirect("home")
						elseif aO == "Continue Loading" then
							if sFs.exists(website1) then sFs.delete(website1) end
	                        local webpage = sIo.open(website1, "w")
	                        webpage:write(message)
	                        webpage:close()
	                        clearArea()
	                        websiteRunning = true
	                        sShell.run(website1)
	 					end
	                else
	                    if sFs.exists(website1) then sFs.delete(website1) end
	                    local webpage = sIo.open(website1, "w")
	                    webpage:write(message)
	                    webpage:close()
	                    clearArea()
	                    websiteRunning = true
						sShell.run(website1)
	                end
				else
					if sFs.exists(website1) then sFs.delete(website1) end
                    local webpage = sIo.open(website1, "w")
                    webpage:write(message)
                    webpage:close()
                    clearArea()
                    websiteRunning = true
					sShell.run(website1)
				end
				webSecure = false
			end
		end
		browserControl()
	end
end

--  -------- Main

resetFileSystem()
if debugging then
	sParallel.waitForAny(autoDatabase, loadWebpage)
else
	while not exitFirefox do
		sPcall(function() sParallel.waitForAny(autoDatabase, loadWebpage) end)
		sleep(0.0000000000001)
	end
end