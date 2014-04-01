--  -------- Mozilla Firefox 
--  -------- Created by 1lann
--  -------- Edited by GravityScore

--  -------- Variables

autoUpdate = true

local x,y = term.getSize()
local EditingValue = ""
local bDatabase = {}
local bvIDs = {}
local bvAddresses = {}
local bType = nil
exitFirefox = false
local firsttime = true

--Open Rednet
rednet.open("top")
rednet.open("left")
rednet.open("right")
rednet.open("back")
rednet.open("front")
rednet.open("bottom")

--  -------- Functions

local function prompt(list, dir)
    --Variables
	local curSel = 1
	local c1 = 200
	local c2 = 208
	if dir == "horizontal" then c1 = 203 c2 = 205 end
	
	--Draw words
	for i = 1, #list do
		if list[i][2] == 1 then list[i][2] = 2
		elseif list[i][2] + string.len(list[i][1]) >= 50 then list[i][2] = 49 - string.len(list[i][1]) end
		
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

function getPastebin(pCode, pLocation)
	-- Get from pastebin
	local response = http.get("http://pastebin.com/raw.php?i=" .. textutils.urlEncode(pCode))

	if response then
		local sResponse = response.readAll()
		response.close()
		
		local file = fs.open(pLocation, "w")
		file.write(sResponse)
		file.close()
	end	
end

function debug(debugmsg)
	-- Print a debug message
	term.setCursorPos(1,1)
	term.clearLine()
	write(debugmsg)
	sleep(3)
end

function isVerified(vWebsite, vID)
	--Verify an ID
	for i = 1, #bvAddresses do
		if vWebsite == bvAddresses[i] then
			if tostring(vID) == bvIDs[i] then
				return "good"
			else
				return "bad"
			end
		end
	end

	return "unknown"
end

function getDatabase()
	-- Get database from pastebin
	getPastebin("KL3WwmER", "/.fireDatabase")
	getPastebin("GC4HK1We", "/.fireVerified")

	f = io.open("/.fireDatabase", "r")
	bDatabase = {}
	for readData in f:lines() do
		table.insert(bDatabase, readData)
	end
	f:close()

	f = io.open("/.fireVerified", "r")
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

	if not(fs.exists("/firelist")) then 
		f = io.open("/firelist", "w") f:write("\n") f:close()
	else
		f = io.open("/firelist", "r")
		for readData in f:lines() do
			table.insert(bDatabase, readData)
		end
		f:close()
	end

	if not fs.exists("/fireverify") then 
		f = io.open("/fireverify", "w") f:write("\n") f:close()
	else
		bType = "url"
		f = io.open("/fireverify", "r")
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
	return (bDatabase)
end

function isBad(number)
	for i = 1, #bDatabase do
		if tostring(number) == bDatabase[i] then
			return true
		end
	end

	return false
end

function dbContains(object, dbase)
	for i = 1, #dbase do
		if tostring(object) == dbase[i] then
			return true, i
		end
	end

	return false
end


function checkMalicious()
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
			f = io.open("/firelist", "a")
			f:write(suspected[i] .. "\n")
			f:close()
			table.insert(bDatabase, suspected[i])
		end
	end
end

function rednetV()
	return "1.3"
end

title = "Mozilla Firefox " .. rednetV()
local website = "home";
if fs.exists(".cache") then fs.delete(".cache") end
if fs.exists(".websiteedited") then fs.delete(".websiteedited") end
fs.makeDir(".cache")

local cPrint = function(text)
	local x2, y2 = term.getCursorPos()
	term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)
	print(text)
end

function reDirect(url)
	website = url
	loadWebpage()
end

local function createSite(websitename)
	term.clear()
	term.setCursorPos(1, 2)
	print("Creating Site: " .. websitename)
	print("Please Wait...")
	f = io.open("/.fireServerPref", "w")
	f:write(websitename)
	f:close()
	getPastebin("wEmK4D4U", "/.firefoxServerUpdater")
	shell.run("/.firefoxServerUpdater")
	exitFirefox = true
	error()
end

local Address = function()
	local text = "rdnt://"
	term.setCursorPos(1,2)
	term.clearLine()
	write("rdnt://")
	website = read()
	loadWebpage()
end

function done()
	if exitFirefox then error() end
	os.queueEvent("firefoxDoneLoading")
	term.setCursorPos(1, y)
	local name = "F5 = Refresh"
	write("Press CTRL to travel the web! :D")
	term.setCursorPos(x - name:len(), y)
	write(name)
	
	while true do
		local e, k = os.pullEvent("key")
		if k == 63 then
			loadWebpage()
			break
		elseif k == 29 then
			Address()
			break
		end
	end
end
	

loadWebpage = function()
	if exitFirefox then error() end
	term.clear()
	term.setCursorPos(1,1)
	cPrint(title)
	cPrint("rdnt://" ..website.. "\n")

	if website == "home" then
		if firsttime then
			term.clear()
			term.setCursorPos(1, 4)
			print("                 _____  _   ______   _____")
			print("        ~~~~~~~ / ___/ / / / _   /  / ___/")
			print("        ------ / /__  / / / /_/ /  / /_")
			print("        ~~~~~ / ___/ / / / _  _/  / __/")
			print("        ---- / /    / / / / \\ \\  / /___")
			print("        ~~~ / /    /_/ /_/   \\_\\/_____/")
			print("        -- / /  _,-=._              /|_/|")
			print("        ~ /_/  `-.}   `=._,.-=-._.,  @ @._,")
			print("                  `. _ _,-.   )      _,.-'")
			print("                           G.m-\"^m`m' ")
			print("        Mozilla Firefox is now loading...")

			if autoUpdate then
				getPastebin("ppnsSi26", "/.firefoxClientUpdate")
				local f = io.open("/.firefoxClientUpdate", "r")
				clientUpdate = f:read("*a")
				f:close()

				f = io.open("/firefox")
				currentClient = f:read("*a")
				f:close()

				if not(currentClient == clientUpdate) then
					fs.delete("/firefox")
					fs.move("/.firefoxClientUpdate", "/firefox")
					shell.run("/firefox")
					error()
				end
			end

			firsttime = false
		end

		term.clear()
		term.setCursorPos(1, 1)
		cPrint(title)
		cPrint("rdnt://" ..website.. "\n")
		cPrint("Welcome to Mozilla Firefox " .. rednetV())
		print(" ")

		if autoUpdate then
			print(" Auto Updating is On")
		else
			print(" Auto Updating is Off")
		end

		print(" ")
		print(" Helpful Websites:")
		print(" - rdnt://exit To Exit")
		print(" - rdnt://help For Help on Black/Whitelisting")
		print(" - rdnt://update to Force Update Firefox")
		print(" - rdnt://newsite to Make a New Website")
		print(" - rdnt://credits to View Firefox's Credits")
	elseif website == "exit" then
		term.clear()
		term.setCursorPos(1,1)
		print("Thank you for using Firefox!")

		exitFirefox = true
		return
	elseif website == "update" then
		reDirect("firefox.mozilla.org")
	elseif website == "help" then
		term.setCursorPos(1, 4)
		print(" Help for Black and Whitelists:")
		print(" - Lists are stored in the root folder")
		print(" - To add a server to the blacklist (firelist):")
		print("   - Enter the ID of the server you wish to block")
		print("   - Example:")
		print("   135")
		print(" - To add a server to the whitelist (fireverify):")
		print("   - Enter the server's URL on the first line")
		print("   - Enter the server's ID on the next line")
		print("   - Example:")
		print("   mozilla")
		print("   175")
	elseif website == "credits" then
		term.setCursorPos(1, 4)
		print(" Firefox Credits:")
		print(" - Mozilla Firefox was programmed by 1lann")
		print(" - It is based off Rednet Explorer v2.4.1")
		print(" - Which is made by xXm0dzXx and CCFan11")
		print(" - Edited and designed by GravityScore")
	elseif website == "newsite" then
		term.setCursorPos(1, 4)
		cPrint("Use This Computer as a Server?")
		local k = prompt({{"Yes", 11, 6}, {"No", 36, 6}}, "horizontal")
		
		if k == "Yes" then
			term.clear()
			term.setCursorPos(1, 1)
			title = "Firefox Server " .. rednetV()
		cPrint(title)
			print(" ")
			if fs.exists("/.fireServerPref") then
				f = io.open("/.fireServerPref", "r")
				websitename = f:read("*l")
				f:close()

				if fs.isDir("/" .. websitename) then
					cPrint("A Previous Server Setup has Been Detected")
					cPrint("For: " .. websitename)
					cPrint("Use This Setup?")
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
			f = io.open("/.fireServerPref", "w")
			f:write(websitename)
			f:close()
			sleep(0.3)

			term.clear()
			term.setCursorPos(1, 1)
			cPrint(title)
		cPrint("rdnt://" ..website.. "\n")
		print(" ")
			if fs.exists("/" .. websitename) then
				if not(fs.isDir("/" .. websitename)) then
					fs.move("/" .. websitename, "firefoxtemphome")
					fs.makeDir("/" .. websitename)
					fs.move("/firefoxtemphome", "/" .. websitename .. "/home")
					print(" An Old Website Has Been Detected")
					print(" It Has Been Moved To: ")
					print("/" .. websitename .. "/home")
					print(" ")
				end
			else
				fs.makeDir("/" .. websitename)
			end

			term.clear()
			term.setCursorPos(1, 1)
			cPrint(title)
			print(" ")

			rednet.broadcast(websitename)
			local i, me = rednet.receive(0.5)
			if not(me == nil) then
				print(" WARNING: This domain may be already in use")
				print(" ")
			end

			print(" The Website Files can be Found In:")
			print(" /" .. websitename)
			print(" The Homepage is Located At:")
			print(" /" .. websitename .. "/home")
			print(" ")
			print(" Edit the Homepage of the Website?")
			local o = prompt({{"Yes", 11, 6}, {"No", 36, 6}}, "horizontal")
			if o == "Yes" then
				shell.run("/rom/programs/edit", "/" .. websitename .. "/" .. "home")
			elseif o == "No" then
				local f = io.open("/" .. websitename .. "/" .. "home", "w")
				f:write("print(\" \")\nprint(\"Welcome to " .. websitename .. "\")")
				f:close()
			end
			
			term.clear()
			term.setCursorPos(1, 1)
			createSite(websitename)
		end
	else
		title = "Mozilla Firefox " ..rednetV()
		term.clear()
			term.setCursorPos(1, 1)
			cPrint(title)
			cPrint("rdnt://" ..website.. "\n")
		print(" Connecting to Website...")

		local website1 = ".depagecrash"
		local startClock = os.clock()
		while os.clock() - startClock < 2 do 
			id, message = rednet.receive(0.5)
			vResult = isVerified(website, id)
			if vResult == "bad" then message = nil
			elseif vResult == "good" then break
			elseif vResult == "unknown" and isBad(id) == false then break
			else message = nil
			end
		end

		if message == nil then
		term.clear()
			term.setCursorPos(1, 1)
			cPrint(title)
			cPrint("rdnt://" ..website.. "\n")
			
cPrint(" _____                         _ ")
cPrint("|  ___|                       | |")
cPrint("| |__  _ __  _ __  ___   _ __ | |")
cPrint("|  __|| '__|| '__|/ _ \\ | '__|| |")
cPrint("| |___| |   | |  | (_) || |   |_|")
cPrint("\\____/|_|   |_|   \\___/ |_|   (_)")
			print(" ")
			cPrint("Unable to Connect to Website")
			cPrint("The Website May Be Down, or Blocked")
		else
			if fs.exists(".cache/" .. website1) then fs.delete(".cache/" ..website1) end
			webpage = fs.open(".cache/" ..website1, "w")
			webpage.write(message)
			webpage.close()

			term.clear()
			term.setCursorPos(1, 1)
			cPrint(title)
			cPrint("rdnt://" ..website.. "\n")
			shell.run(".cache/" ..website1)

			if exitFirefox then
				error()
			end
		end
	end
	
	done()
end

function securityCheck()
	while true do
		os.pullEvent("firefoxDoneLoading")
		getDatabase()
		checkMalicious()
	end
end

parallel.waitForAny(securityCheck, loadWebpage)
