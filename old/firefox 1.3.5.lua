
--  -------- Mozilla Firefox
--  -------- Designed and Programmed by 1lann and GravityScore

--  -------- Originally Based off RednetExplorer v2.4.1
--  -------- RednetExplorer Originally Made by xXm0dzXx/CCFan11


--  -------- Features to Come

-- 1. Unified Title and URL Bar 			1.4
-- 2. Server Managing						1.4
-- 3. Bookmarks								1.3.5
-- 4. View History 							1.3.5
-- 5. Upgraded Help 						1.4
-- 6. Preferences							1.4
--   1. Auto-Updating on/off
--   2. Change Homepage
-- 	 3. Ability to download pre-releases (off unstable)
--   4. Reset Firefox
-- 7. Sites: Description of Each  			1.3.4



--  -------- Variables

-- Version
local firefoxVersion = "1.3.5"

-- Title
local firefoxTitle = "Mozilla Firefox " .. firefoxVersion
local firefoxServerTitle = "Firefox Server " .. firefoxVersion
local title = firefoxTitle

-- Pastebin IDs
local firefoxPastebinID = "firefox-stable.lua"
local fireDatabasePastebinID = "firefox-firewall.txt"
local fireVerifiedPastebinID = "firefox-verified.txt"
local firefoxServerPastebinID = "firefox-server.lua"
local fireDefinitionsPastebinID = "firefox-defs.txt"

-- Data Locations
local root = "/.FirefoxData"
local blacklistLoc = root .. "/firefox_blacklist"
local whitelistLoc = root .. "/firefox_whitelist"
local definitionsLoc = root .. "/firefox_definitions"
local firefoxLoc = "/" .. shell.getRunningProgram()
local website = "home"

-- Other
exitFirefox = false
local firstOpen = true
local quickHistory = {}
local websiteRunning = false

local autoUpdate = true
local debugging = false

-- Open Rednet
rednet.open("top")
rednet.open("left")
rednet.open("right")
rednet.open("back")
rednet.open("front")
rednet.open("bottom")

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
		elseif list[i][2] + string.len(list[i][1]) >= 50 then 
			list[i][2] = 49 - string.len(list[i][1]) 
		end
		
		term.setCursorPos(list[i][2], list[i][3])
		write(list[i][1])
	end
	
	--Functions
	local function drawArrows(word, x, y)
		--Draw arrows
		term.setCursorPos(x, y)
		write("[")
		term.setCursorPos(x + 1 + string.len(word), y)
		write("]")
	end
	
	local function removeArrows(word, x, y)
		--Remove current arrows
		term.setCursorPos(x, y)
		write(" ")
		term.setCursorPos(x + 1 + string.len(word), y)
		write(" ")
	end
	
	--Draw arrows
	drawArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])
	
	--Start loop
	while true do
		--Get the key
		local event, key = os.pullEvent("key")
		
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
function getPastebin(code, location)
	local response = http.get("http://dl.dropbox.com/u/97263369/" .. code)

	if response then
		local text = response.readAll()
		response.close()
		
		local file = fs.open(location, "w")
		file.write(text)
		file.close()
	end	
end

-- Quickly debug a message 
local function debug(msg)
	term.setCursorPos(1,1)
	term.clearLine()
	write(tostring(msg))
	sleep(3)
end

--  -------- Database Functions

-- Variables
local bDatabase = {}
local bvIDs = {}
local bvAddresses = {}
local bType = nil

-- Download and update the database of servers (white and blacklists)
local function getDatabase()
	-- Get database from pastebin
	getPastebin(fireDatabasePastebinID, root .. "/fireDatabase")
	getPastebin(fireVerifiedPastebinID, root .. "/fireVerified")
	getPastebin(fireDefinitionsPastebinID, root .. "/fireDefinitions")

	local f = io.open(root .. "/fireDatabase", "r")
	bDatabase = {}
	for readData in f:lines() do
		table.insert(bDatabase, readData)
	end
	f:close()
	local f = io.open(root .. "/fireDefinitions")
	webDefinitions = {}
	for readData in f:lines() do
		table.insert(webDefinitions, readData)
	end
	f:close()
	f = io.open(root .. "/fireVerified", "r")
	bvIDs = {}
	bvAddresses = {}
	bType = "url"
	for readData in f:lines() do
		if bType == "url" then
			table.insert(bvAddresses, readData)
			bType = "id"
		else
			table.insert(bvIDs, readData)
			bType = "url"
		end
	end
	f:close()

	if not(fs.exists(blacklistLoc)) then 
		f = io.open(blacklistLoc, "w") f:write("\n") f:close()
	else
		f = io.open(blacklistLoc, "r")
		for readData in f:lines() do
			table.insert(bDatabase, readData)
		end
		f:close()
	end

	if not(fs.exists(definitionsLoc)) then 
		f = io.open(definitionsLoc, "w") f:write("\n") f:close()
	else
		f = io.open(definitionsLoc, "r")
		for readData in f:lines() do
			table.insert(webDefinitions, readData)
		end
		f:close()
	end


	if not fs.exists(whitelistLoc) then 
		f = io.open(whitelistLoc, "w") f:write("\n") f:close()
	else
		bType = "url"
		f = io.open(whitelistLoc, "r")
		local x = 1 
		local bnLines = 0
		for readData in f:lines() do
			bnLines = bnLines+1
			if bType == "url" then
				table.insert(bvAddresses, readData)
				bType = "id"
			else
				table.insert(bvIDs, readData)
				bType = "url"
			end
		end
		f:close()
		if #bvAddresses > #bvIDs then table.remove(bvAddresses, #bvAddresses)
		elseif #bvAddresses < #bvIDs then table.remove(bvIDs, #bvIDs) end
	end

	return bDatabase
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
		local aDE = os.pullEvent()
		if aDE == "firefoxDoneLoading" then
			getDatabase()
		end
	end
end

--  -------- Verifing Websites

-- Verify the website against the whitelist
local function isVerified(vWebsite, vID)
	-- Verify an ID
	if string.find(vWebsite, "/") then
		local vFind = string.find(vWebsite, "/")
		vWebsite = string.sub(vWebsite, 1, vFind - 1)
	end

	for i = 1, #bvAddresses do
		if vWebsite == string.lower(bvAddresses[i]) then
			if tostring(vID) == bvIDs[i] then
				return "good"
			else
				return "bad"
			end
		end
	end

	return "unknown"
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
	for i = 1, #webDefinitions do
		if string.find(dataCheck, webDefinitions[i], 1, true) and webDefinitions[i] ~= nil and webDefinitions[i] ~= "" and webDefinitions[i] ~= "\n" then
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
		rednet.broadcast(tostring(math.random(1, 9001)))
		startClock = os.clock()
		while os.clock() - startClock < 0.1 do
			local a = rednet.receive(0.05)
			if a ~= nil then
				dbState, dbPos = dbContains(a, suspected)
				if isBad(a) then
				elseif not dbState then
					table.insert(suspected, tostring(a)) 
					table.insert(times, 1)
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
			f = io.open(blacklistLoc, "a")
			f:write("\n" .. suspected[i])
			f:close()
			table.insert(bDatabase, suspected[i])
		end
	end
end

--  -------- File System

-- Update the file system from previous versions
local function resetFileSystem()
	if not fs.exists(root) then
		fs.makeDir(root)
		fs.makeDir(root .. "/cache")
	elseif not fs.isDir(root) then
		fs.delete(root)
		fs.makeDir(root)
		fs.makeDir(root .. "/cache")
	end

	if fs.exists("/fireverify") then fs.move("/fireverify", whitelistLoc) end
	if fs.exists("/firelist") then fs.move("/firelist", blacklistLoc) end
	if fs.exists("/firefox_whitelist") then fs.move("/firefox_whitelist", whitelistLoc) end
	if fs.exists("/firefox_blacklist") then fs.move("/firefox_blacklist", blacklistLoc) end
	if fs.exists("/.fireServerPref") then fs.move("/.fireServerPref", root .. "/fireServerPref") end

	fs.delete("/.fireDatabase")
	fs.delete("/.fireVerify")
end

-- Update Firefox client
local function autoUpdater()
	if autoUpdate then
		getPastebin(firefoxPastebinID, root .. "/firefoxClientUpdate")
		local f = io.open(root .. "/firefoxClientUpdate", "r")
		local clientUpdate = f:read("*a")
		f:close()

		local ff = io.open(firefoxLoc)
		local currentClient = ff:read("*a")
		ff:close()

		if currentClient ~= clientUpdate then
			fs.delete(firefoxLoc)
			fs.move(root .. "/firefoxClientUpdate", firefoxLoc)
			shell.run(firefoxLoc)
			error()
		end
	end
end

--  -------- Webpage Loading

-- Browser controls

local function browserControl()
	websiteRunning = false
	term.setCursorBlink(false)
	if exitFirefox then error() end
	setTitle()
	os.queueEvent("firefoxDoneLoading")

	local w, h = term.getSize()
	term.setCursorPos(1, h)
	write(" Control to Surf the Web")
	term.setCursorPos(w - string.len("F5 to Refresh"), h)
	write("F5 to Refresh")
	
	while true do
		local e, k = os.pullEvent("key")
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

	f = io.open(root .. "/fireServerPref", "w")
	f:write(websitename)
	f:close()
	getPastebin(firefoxServerPastebinID, root .. "/firefoxServerUpdater")
	shell.run(root .. "/firefoxServerUpdater")
	exitFirefox = true
	error()
end

-- Redirect the user to a different page
function redirect(url)
	website = url
	loadWebpage()
end

-- Load the website
function loadWebpage()
	if exitFirefox then error() end
if websiteRunning then
	browserControl()
	else
	websiteRunning = true
		title = firefoxTitle
		website = website:lower()

		clearArea()
		table.insert(quickHistory, website)
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
				if not(autoUpdate) then sleep(0.75) end
				autoUpdater()
				firstOpen = false
			end

			clearArea()
			cPrint("Welcome To " .. firefoxTitle)
			print(" ")

			if autoUpdate then
				print(" Automatic Updating is On")
			else
				print(" Automatic Updating is Off")
			end

			local w, h = term.getSize()
			print(" ")
			term.setCursorPos(2, 8)
			write("rdnt://sites")
			term.setCursorPos(w - 1 - string.len("See Sites"), 8)
			write("See Sites")
			term.setCursorPos(2, 9)
			write("rdnt://whatsnew")
			term.setCursorPos(w - 1 - string.len("See Whats New in " .. firefoxVersion), 9)
			write("See Whats New in " .. firefoxVersion)
			term.setCursorPos(2, 10)
			write("rdnt://credits")
			term.setCursorPos(w - 1 - string.len("View Credits"), 10)
			write("View Credits")
			term.setCursorPos(2, 11)
			write("rdnt://exit")
			term.setCursorPos(w - 1 - string.len("Exit Firefox"), 11)
			write("Exit Firefox")
		elseif website == "" or website == " " then
			clearArea()
			print(" ")
			cPrint("OMFG Y U NO ENTER SOMETING?!?!")
		elseif website == "exit" then
			term.clear()
			term.setCursorPos(1,1)
			print("Thank You for Using Firefox!")
			sleep(0.3)

			exitFirefox = true
			return
		elseif website == "update" then
			cPrint("Force Update Firefox")
			print(" ")
			local o = prompt({{"Yes", 11, 8}, {"No", 36, 8}},  "horizontal")
			if o == "Yes" then
				clearArea()
				cPrint("Updating...")
				getPastebin(firefoxPastebinID, firefoxLoc)

				clearArea()
				cPrint("Firefox Has Been Updated")
				cPrint("Press Any Key to Restart")
				os.pullEvent("key")
				shell.run(firefoxLoc)
				error()
			else
				clearArea()
				cPrint("Cancelled Update")
			end
		elseif website == "whatsnew" then
			cPrint("New Fetures in Firefox " .. firefoxVersion)
			print(" ")
			print(" Changed the UI Slightly")
			print(" Improved In-Built Server Software")
			print(" Moved from Pastebin to Dropbox")
			print(" Added Virus Detection and Protection")
			print(" Fixed Several Bugs that Cause Crashing")
			print(" Added Secret Easter Egg :D")
		elseif website == "sites" then
			--[[cPrint("Sites")
			print(" ")
			print(" Enter \"firefox\" to See Firefox Sites")
			term.setCursorPos(2, 7)
			write("Enter Search: ")
			local search = read()

			if search:lower() == "firefox" then]]--
				--clearArea()
				cPrint("Standard Firefox Sites")
				print(" ")
				print(" rdnt://home")
				print(" rdnt://update")
				print(" rdnt://whatsnew")
				print(" rdnt://sites")
				print(" rdnt://getid")
				print(" rdnt://newsite")
				print(" rdnt://credits")
				print(" rdnt://exit")
				print(" ")
			--[[else
				rednet.broadcast("rednet.api.ping.searchengine")
				local s = {}
				local x = 1
				while true do
					local i, m = rednet.receive(0.1)
					if i then table.insert(s, (i .. " : " .. m))
					else break end
				end

				clearArea()
				cPrint("User Sites")
				print(" ")
				for i = 1, s do
					print(" " + s[i])
				end
			end]]--
		elseif website == "getid" then
			cPrint("Get Server Computer ID")
			term.setCursorPos(2, 7)
			write("Enter Server URL: ")
			local url = read()

			rednet.broadcast(url)
			local i, m = rednet.receive(0.1)

			clearArea()
			cPrint("Get Server Computer ID")
			print(" ")
			term.setCursorPos(1, 7)
			if string.len(m) ~= 0 and i ~= nil then
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
			term.setCursorPos(w - 1 - string.len("1lann and GravityScore"), 7)
			write("1lann and GravityScore")
			term.setCursorPos(2, 9)
			write("Based off:")
			term.setCursorPos(w - 1 - string.len("Rednet Explorer v2.4.1"), 9)
			write("Rednet Explorer v2.4.1")
			term.setCursorPos(2, 10)
			write("Rednet Explorer Made by:")
			term.setCursorPos(w - 1 - string.len("xXm0dzXx/CCFan11"), 10)
			write("xXm0dzXx/CCFan11")
		elseif website == "newsite" then
			term.setCursorPos(1, 4)
			cPrint("Use This Computer as a Webserver")
			local opt = prompt({{"Yes", 11, 6}, {"No", 36, 6}}, "horizontal")
			
			if opt == "Yes" then
				clearArea()
				if fs.exists(root .. "/fireServerPref") then
					f = io.open(root .. "/fireServerPref", "r")
					websitename = f:read("*l")
					f:close()

					if fs.isDir("/" .. websitename) then
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
				f = io.open(root .. "/fireServerPref", "w")
				f:write(websitename)
				f:close()

				term.clear()
				term.setCursorPos(1, 1)
				cPrint(title .. "\n")
					
				if fs.exists("/" .. websitename) and not(fs.isDir("/" .. websitename)) then
					fs.move("/" .. websitename, root .. "/firefoxtemphome")
					fs.makeDir("/" .. websitename)
					fs.move(root .. "/firefoxtemphome", "/" .. websitename .. "/home")
					print(" An Old Website Has Been Detected")
					print(" It Has Been Moved To: ")
					print(" /" .. websitename .. "/home")
					print(" ")
				else
					fs.makeDir("/" .. websitename)
				end

				rednet.broadcast(string.lower(websitename))
				local i, me = rednet.receive(0.5)
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
					shell.run("/rom/programs/edit", "/" .. websitename .. "/" .. "home")
				elseif o == "No" then
					if not fs.exists("/" .. websitename .. "/" .. "home") then
						local f = io.open("/" .. websitename .. "/" .. "home", "w")
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
			rednet.broadcast(website)
			local fWebsite = ""
			if string.find(website, "/") then
				fWebsite = string.gsub(website, "/", "$slazh$")
			else
				fWebsite = website
			end

			local website1 = root .. "/cache/" .. fWebsite
			local startClock = os.clock()
			local id, message = nil
			while os.clock() - startClock < 0.2 do 
				id, message = rednet.receive(0.1)
				local vResult = isVerified(website, id)
				if vResult == "bad" then message = nil
				elseif vResult == "good" then break
				elseif vResult == "unknown" and isBad(id) == false then break
				else message = nil
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
				if fs.exists(website1) then
					clearArea()
					cPrint("Unable to Connect to Website")
					cPrint("Resort to Cached Version?")
					local o = prompt({{"Yes", 7, 8}, {"No", 16, 8}, {"Delete Cached Version", 24, 8}}, "horizontal")
					if o == "Yes" then
						clearArea()
						websiteRunning = true
						shell.run(website1)
					elseif o == "No" then
						drawError()
					else
						fs.delete(website1)
						clearArea()
						cPrint("Deleted cached version!")
					end
				else 
					drawError()
				end
			else
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
						local f = io.open(blacklistLoc, "a")
						f:write("\n" .. tostring(id))
						f:close()
						table.insert(bDatabase, tostring(id))
						clearArea()
						cPrint("Added to the blacklist!")
						cPrint("The blacklist can be accessed from")
						cPrint("/.FirefoxData/firefox_blacklist")
					elseif aO == "Go to Homepage" then
						websiteRunning = false
						redirect("home")
					elseif aO == "Continue Loading" then
						if fs.exists(website1) then fs.delete(website1) end
                        local webpage = io.open(website1, "w")
                        webpage:write(message)
                        webpage:close()
                        clearArea()
                        websiteRunning = true
                        shell.run(website1)
 					end
                else
                    if fs.exists(website1) then fs.delete(website1) end
                    local webpage = io.open(website1, "w")
                    webpage:write(message)
                    webpage:close()
                    clearArea()
                    websiteRunning = true
                    shell.run(website1)
                end
			end
		end
		browserControl()
	end
end

--  -------- Main

resetFileSystem()
if debugging then
	parallel.waitForAny(autoDatabase, loadWebpage)
else
	while not exitFirefox do
		pcall(function() parallel.waitForAny(autoDatabase, loadWebpage) end)
	end
end
