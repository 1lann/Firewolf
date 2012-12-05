
--  -------- Mozilla Firefox Server
--  -------- Made by GravityScore and 1lann

--  -------- Original Idea from Rednet Explorer v2.4.1
--  -------- Rednet Explorer made by xXm0dzXx/CCFan11



--  -------- Global Variables

local tArgs = {...}


-- Encase in function
local function entiretyOfServer()


--  -------- Constants

-- Updating
local autoupdate = true
local debugging = false

-- Searching
local searching = true
local respond = true
local managing = false

-- Dropbox URLs
local serverURL = "http://dl.dropbox.com/u/97263369/firefox/firefox-server.lua"

-- Events
local updatePagesListEvent = "firefox_server_update_pages"
local stopServerEvent = "firefox_server_stop_event"

-- Statistics
local visits = 0
local searches = 0

-- Website
local website = ""
local title = ""
local fileLocation = ""
local pages = {}
local failedToLoadSuc = false
local failedToLoadFail = false
local failedToLoadAny = false
local failedToLoadOther = false
local triggered = false
local suspectedIDs = {}
local ignoreDatabase = {}

-- Locations
local rootFolder = "/.Firefox_Data"
local serverFolder = rootFolder .. "/servers"
local serverLocation = "/" .. shell.getRunningProgram()
local statsLocation = ""
local serverPath = ""


--  -------- Prompt

local function prompt(list, dir, startCurSel)
	-- Functions
	local function drawArrows(word, x, y)
		term.setCursorPos(x, y)
		write("[")
		term.setCursorPos(x + 1 + string.len(word), y)
		write("]")
	end
	
	local function removeArrows(word, x, y)
		term.setCursorPos(x, y)
		write(" ")
		term.setCursorPos(x + 1 + string.len(word), y)
		write(" ")
	end

	-- Variables
	local curSel = 1
	if startCurSel ~= nil then
		curSel = startCurSel
	end
	local c1 = 200
	local c2 = 208
	if dir == "horizontal" then c1 = 203 c2 = 205 end

	-- Draw
	for i = 1, #list do
		if list[i][2] == -1 then
			local w, h = term.getSize()
			list[i][2] = math.floor(w/2 - list[i][1]:len()/2) 
		end
		term.setCursorPos(list[i][2], list[i][3])
		write(list[i][1])
	end
	drawArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])

	-- Selection
	while not(exitApp) do
		local event, key = os.pullEvent("key")
		removeArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])
		if key == c1 then
			if curSel ~= 1 then curSel = curSel - 1 end
		elseif key == c2 then
			if curSel ~= #list then curSel = curSel + 1 end
		elseif key == 28 then
			return list[curSel][1]
		end
		drawArrows(list[curSel][1], list[curSel][2] - 1, list[curSel][3])
	end
end

local function scrollingPrompt(list, disLen, xStart, yStart)
	-- Functions 
	local function drawItems(items)
		for i = 1, #items do
			term.setCursorPos(xStart, i + yStart)
			term.clearLine(i + 4)
			write("[ ]  " .. items[i])
		end
	end

	local function updateDisplayList(items, disLoc, disLen)
		local ret = {}
		for i = 1, disLen do
			local item = items[i + disLoc - 1]
			if item ~= nil then table.insert(ret, item) end
		end
		return ret
	end

	local function drawArrows(word, x, y)
		term.setCursorPos(x + 1, y)
		write("x")
	end

	local function removeArrows(word, x, y)
		term.setCursorPos(x + 1, y)
		write(" ")
	end

	-- Variables
	local disLoc = 1
	local disList = updateDisplayList(list, 1, disLen)
	local curSel = 1
	drawItems(disList)
	drawArrows(list[1], xStart, yStart + 1)
	
	-- Selection
	while true do
		local event, key = os.pullEvent("key")
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
		end
		drawArrows(list[curSel + disLoc - 1], xStart, curSel + yStart)
	end
end


--  -------- Utilities

local function getDropbox(url, file)
	for i = 1, 3 do
		local response = http.get(url)
		if response then
			local fileData = response.readAll()
			response.close()
			local f = io.open(file,"w")
			f:write(fileData)
			f:close()
			return true
		end
	end
	return false
end

local function cPrint(text)
	local w, h = term.getSize()
	local x, y = term.getCursorPos()
	term.setCursorPos(math.ceil((w + 1)/2 - text:len()/2), y)
	print(text)
end

local function lWrite(text)
	local x, y = term.getCursorPos()
	term.setCursorPos(4, y)
	write(text)
end


--  -------- Drawing

local recordLines = {}
local function clearPage(title, r)
	-- URL
	local w, h = term.getSize()
	term.setCursorPos(2, 1)
	term.clearLine()
	write(title)

	-- Line
	if term.setTextColor then
		term.setCursorPos(1,2)
	else
		term.setCursorPos(1,1)
	end
	write(string.rep("-", w))
	print(" ")

	-- Vertical line
	for i = 1, h - 2 do
		term.setCursorPos(21, i + 2)
		write("|")
	end

	-- Records
	for x = 4, 18 do
		term.setCursorPos(23, x)
		write(string.rep(" ", 28))
	end
	if r ~= nil and r == true then
		for i = 1, #recordLines do
			term.setCursorPos(23, i + 3)
			write(recordLines[i])
		end
	end
end

local function record(text)
	if #recordLines > 14 then
		table.remove(recordLines, 1)
	end
	table.insert(recordLines, text)
	if not managing then
		clearPage(title, true)
	end
end


--  -------- Updating

local function updateClient()
	local updateLocation = rootFolder .. "/firefox-server-update"

	-- Get files and contents
	getDropbox(serverURL, updateLocation)
	local f1 = io.open(updateLocation, "r")
	local f2 = io.open(serverLocation, "r")
	local update = f1:read("*a")
	local current = f2:read("*a")
	f1:close()
	f2:close()

	-- Update
	if current ~= update then
		fs.delete(serverLocation)
		fs.move(updateLocation, serverLocation)
		shell.run(serverLocation, tArgs[1], tArgs[2], tArgs[3])
		error()
	else
		fs.delete(updateLocation)
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
	if not(fs.exists(serverFolder)) then fs.makeDir(serverFolder) end
end

local function loadServerAPI()
	-- Create API
	if not fs.exists(serverPath .. "/serverapi") then
		f = io.open(serverPath .. "/serverapi", "w")
		f:write(
[[

--  -------- Custom Server API
--  -------- Part Of Mozilla Firefox Server
--  -------- Created By 1lann and GravityScore

--  Notes:

--  These functions are called when certain events occur
--  The function names are required to be as they are
--  If the functions do not execute instantly, your server will be DDoS-able
--  If writing to a file, it is recommended to pre-open the file when
--    this API is loaded, to prevent the triggering of the Anti-Filespammer


function uponSuccessfulRequest(page, id)
	-- Called when a successful request to a page is made
	-- Your Code Here...
end

function uponFailedRequest(page, id)
	-- Called when an unsuccessful request to a page is made
	-- Your Code Here...
end

function uponAnyMessage(message, id)
	-- Called when any rednet message is sent to the computer
	-- Your Code Here...
end

function uponAnyOtherMessage(message, id)
	-- Called when a rednet message is sent to the computer which is not requesting a page
	-- Your Code Here...
end

local function uponServerApiLoad()
	-- Called when the server API is loaded
	-- Your Code Here...
end

function parallelWithServer()
	-- Runs alongside the server
	-- Modifications only take effect when the server restarts
	-- Your Code Here...
end

uponServerApiLoad()

]])
		f:close()
	end

	-- Start API
	shell.run(serverPath .. "/serverapi")

	-- Check if it is valid
	if type(uponSuccessfulRequest) ~= "function" then
		uponSuccessfulRequest = nil
		failedToLoadSuc = true
	end
	if type(uponFailedRequest) ~= "function" then
		uponFailedRequest = nil
		failedToLoadFail = true
	end
	if type(uponAnyMessage) ~= "function" then
		uponAnyMessage = nil
		failedToLoadAny = true
	end
	if type(uponAnyOtherMessage) ~= "function" then
		uponAnyOtherMessage = nil
		failedToLoadOther = true
	end
	if type(parallelWithServer) ~= "function" then
		parallelWithServer = nil
		failedToLoadParallel = true
	end
end

local function loadPages(loc, p)
	local a = fs.list(loc)
	for i = 1, #a do
		if a[i]:lower() ~= a[i] then
			fs.delete(loc .. "/" .. a[i]:lower())
			fs.move(loc .. "/" .. a[i], loc .. "/" .. a[i]:lower())
			a[i] = a[i]:lower()
		end
		if not(fs.isDir(loc .. "/" .. a[i])) then
			local f = io.open(loc .. "/" .. a[i])
			local cont = f:read("*a")
			f:close()

			p[loc .. "/" .. a[i]] = cont
		else
			local b = {}
			loadPages(loc .. "/" .. a[i], b)
			for x = 1, #b do
				table.insert(p, b[x])
			end
		end
	end
	os.queueEvent(updatePagesListEvent, textutils.serialize(p))
end


--  -------- Server Responding

local function inIgnoreList(id)
	for _, v in pairs(ignoreDatabase) do
		if v == tostring(id) then
			return true
		end
	end

	return false
end

local function respondToRequests()
	-- Load API
	local writingClock = os.clock()
	if failedToLoadSuc or failedToLoadFail or failedToLoadAny or failedToLoadOther then
		record("Warning - Failed To Load:")
		if failedToLoadSuc then record("  uponSuccessfulRequest()") end
		if failedToLoadFail then record("  uponFailedRequest()") end
		if failedToLoadAny then record("  uponAnyMessage()") end
		if failedToLoadOther then record("  uponAnyOtherMessage()") end
		if failedToLoadParallel then record("  parallelWithServer()") end
	else
		record("Loaded Server API")
	end

	local pastClock = os.clock()
	while true do
		triggered = false
		if os.clock() - pastClock < 6 then
			for k, v in pairs(suspectedIDs) do
				if v > 10 then
					table.insert(ignoreDatabase, tostring(k))
				end
			end
		else
			ignoreDatabase = {}
			suspectedIDs = {}
			pastClock = os.clock()
		end

		-- Pull Event
		local event, id, mes = os.pullEvent()

		-- Respond
		if event == "rednet_message" and respond == true then
			if not(inIgnoreList(id)) then
				if mes == website or mes == website .. "/" or mes == website .. "/home" then
					if suspectedIDs[tostring(id)] then
						suspectedIDs[tostring(id)] = suspectedIDs[tostring(id)] + 1
					else
						suspectedIDs[tostring(id)] = 1
					end
					triggered = true
					for i = 1, 3 do
						rednet.send(id, pages[fileLocation .. "/home"])
					end
					record("/home : " .. id)

					visits = visits + 1
					if uponSuccessfulRequest then uponSuccessfulRequest("/home", id) end
				elseif mes:find("/") then
					triggered = true
					local a = mes:find("/")
					if mes:sub(1, a - 1) == website then
						if suspectedIDs[tostring(id)] then
							suspectedIDs[tostring(id)] = suspectedIDs[tostring(id)] + 1
						else
							suspectedIDs[tostring(id)] = 1
						end

						local subDir = mes:sub(a, -1)
						if pages[fileLocation .. subDir] and subDir ~= "/serverapi" then
							for i = 1, 3 do
								rednet.send(id, pages[fileLocation .. subDir])
							end
							
							if subDir:len() > 18 then
								subDir = subDir:sub(1, 9) .. "..." .. subDir:sub(subDir:len() - 9, -1)
							end
							record(subDir .. " : " .. id)
							visits = visits + 1
							if uponSuccessfulRequest then
								uponSuccessfulRequest(subDir, id)
							end
						else
							record("Failed Request : " .. id)
							if uponFailedRequest then
								uponFailedRequest(subDir, id)
							end
						end
					end
				elseif mes == "rednet.api.ping.searchengine" and searching == true then
					if suspectedIDs[tostring(id)] then
						suspectedIDs[tostring(id)] = suspectedIDs[tostring(id)] + 1
					else
						suspectedIDs[tostring(id)] = 1
					end

					triggered = true
					rednet.send(id, website)
					record("Search Request : " .. id)
					searches = searches + 1
				end

				-- Trigger events
				if uponAnyMessage then 
					uponAnyMessage(mes, id) 
				end

				if not(triggered) and uponAnyOtherMessage then
					uponAnyOtherMessage(mes, id)
				end
				
				-- Save stats
				if os.clock() - writingClock > 5 then
					local statsFile = io.open(statsLocation, "w")
					statsFile:write(tostring(visits) .. "\n" .. tostring(searches))
					statsFile:close()
					writingClock = os.clock()
				end
			end
		elseif event == updatePagesListEvent then
			pages = textutils.unserialize(id)
		elseif event == stopServerEvent then
			break
		end
	end
end


--  -------- UI

local function startUI()
	term.clear()
	local s = 1
	while true do
		-- Clear
		clearPage(title, true)
		term.setCursorPos(4,4)
		write(string.rep(" ", 17))
		local t1 = "Pause Server"
		if respond == false then t1 = "Unpause Server" end

		-- Prompt for option
		local opt = prompt({{t1, 4, 4}, {"View Statistics", 4, 6}, {"Edit Pages", 4, 8}, 
							{"Stop Server", 4, 10}}, "vertical", s)
		if opt == t1 then
			respond = not(respond)
			s = 1
		elseif opt == "View Statistics" then
			managing = true
			clearPage(title)
			term.setCursorPos(23, 5)
			write("Visits: " .. visits)
			term.setCursorPos(23, 7)
			write("Searches: " .. searches)
			prompt({{"Back", 26, 15}}, "vertical")
			s = 2
			managing = false
		elseif opt == "Edit Pages" then
			-- Variables
			managing = true
			local oldLocation = shell.dir()
			local comHis = {}

			-- Title
			term.clear()
			term.setCursorPos(1,1)
			shell.setDir(serverPath)
			print("Server File Editing")
			print("Type 'exit' To Return To Server Management")
			print(" ")
			print("Server files:")
			shell.run("/rom/programs/list")
			print(" ")

			-- Shell
			while true do
				shell.setDir(serverPath)
				write("> ")

				local line = read(nil, comHis)
				table.insert(comHis, line)

				local words = {}
				for match in string.gmatch(line, "[^ \t]+") do
					table.insert(words, match)
				end

				local command = words[1]
				if command == "exit" then
					break
				elseif command then
					shell.run(command, unpack(words, 2))
				end
			end

			-- Reset
			shell.setDir(oldLocation)
			term.clear()
			managing = false
			pages = {}
			loadPages(fileLocation, pages)

			-- Post events
			uponSuccessfulRequest = nil
			uponFailedRequest = nil
			uponAnyMessage = nil
			uponAnyOtherMessage = nil
			parallelWithServer = nil

			shell.run(serverPath .. "/serverapi")
			if type(uponSuccessfulRequest) ~= "function" then
				uponSuccessfulRequest = nil
				failedToLoadSuc = true
			end
			if type(uponFailedRequest) ~= "function" then
				uponFailedRequest = nil
				failedToLoadFail = true
			end
			if type(uponAnyMessage) ~= "function" then
				uponAnyMessage = nil
				failedToLoadAny = true
			end
			if type(uponAnyOtherMessage) ~= "function" then
				uponAnyOtherMessage = nil
				failedToLoadOther = true
			end
			if type(parallelWithServer) ~= "function" then
				parallelWithServer = nil
				failedToLoadParallel = true
			end

			-- Record
			if failedToLoadSuc or failedToLoadFail or failedToLoadAny or failedToLoadOther then
				record("Warning - Failed To Load:")
				if failedToLoadSuc then record("  uponSuccessfulRequest()") end
				if failedToLoadFail then record("  uponFailedRequest()") end
				if failedToLoadAny then record("  uponAnyMessage()") end
				if failedToLoadOther then record("  uponAnyOtherMessage()") end
			else
				record("Loaded Server API")
			end
		elseif opt == "Stop Server" then
			os.queueEvent(stopServerEvent)
			term.clear()
			term.setCursorPos(1, 1)
			break
		end
	end
end

--  -------- Main

local function startup()
	-- Logo
	term.clear()
	term.setCursorPos(1, 3)
	cPrint("           _   _                    __ __   ")
	cPrint("--------- / | / |   ____ ____   __ / // /___")
	cPrint("-------- /  |/  |  /   //_  /  / // // //  |")
	cPrint("------- / /| /| | / / /  / /_ / // // // - |")
	cPrint("------ /_/ |/ |_|/___/  /___//_//_//_//_/|_|")
	cPrint("----- _____ __ ____   ____ ___  ______  __  ")
	cPrint("---- / ___// // __ \\ / __// __//   /\\ \\/ /  ")
	cPrint("--- / /__ / // _  / / __// __// / /  >  <   ")
	cPrint("-- / ___//_//_/ \\_\\/___//_/  /___/  /_/\\_\\  ")
	cPrint("- / /                                       ")
	cPrint(" /_/    Doing Good is Part of Our Code      ")
	print("\n\n")
	cPrint("Loading Firefox Server...")

	-- Update
	if autoupdate then
		updateClient()
	end

	-- Load variables
	if #tArgs > 1 then
		website = tArgs[1]:gsub("^%s*(.-)%s*$", "%1")
		fileLocation = tArgs[2]:gsub("^%s*(.-)%s*$", "%1")
		statsLocation = rootFolder .. "/" .. website .. "_stats"
		title = "Hosting: rdnt://" .. website
	end

	-- Filesystem
	resetFilesystem()
	loadPages(fileLocation, pages)

	-- Load stats
	if fs.exists(statsLocation) then
		local f = io.open(statsLocation, "r")
		local a = tonumber(f:read("*l"))
		local b = tonumber(f:read("*l"))
		f:close()
		
		if a then
			visits = a
		end if b then
			searches = b
		end
	end
	serverPath = serverFolder .. "/" .. website

	-- Load server API
	loadServerAPI()

	-- Open Modem
	local present = false
	for _, v in pairs(rs.getSides()) do
		if peripheral.getType(v) == "modem" then
			rednet.open(v)
			present = true
			break
		end
	end

	if present == false then
		term.clear()
		term.setCursorPos(1, 1)
		cPrint("No Attached Modem!")
		print(" ")
		cPrint("Please Attach A Modem Before")
		cPrint("Starting The Server!")
		return
	end

	-- Start UI and responder
	parallel.waitForAll(respondToRequests, startUI, parallelWithServer)
end

-- Start App
startup()

-- Close Rednet
for _, v in pairs(rs.getSides()) do
	if peripheral.getType(v) == "modem" then
		rednet.close(v)
	end
end

-- End Encasing Function
end


--  -------- Complete Crash Protection

-- Copy APIs
local function copyTable(table)
	local newTable = {}
	for k, v in pairs(table) do
		newTable[k] = v
	end
	return newTable
end

local sterm = copyTable(term)
local sos = copyTable(os)
local smath = copyTable(math)
local sprint = print
local swrite = write
local serror = error

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

if http then
	-- Start Server
	while true do
		local _, errorCode = pcall(entiretyOfServer)
		local stopServerEvent = "firefox_server_stop_event"
		os.queueEvent(stopServerEvent)

		-- Catch error
		if errorCode then
			sterm.clear()
			sterm.setCursorPos(1, 2)
			scenterPrint("Critical Error!")
			sprint("\n")
			scenterPrint("Firefox Server Has Encountered A")
			scenterPrint("Critical Internal Error!")
			sprint("\n")
			scenterPrint("Error:")
			sprint("  " .. errorCode)
			sprint(" ")
			scenterPrint("Please Report This To 1lann or GravityScore")
			sprint(" ")
			scenterPrint("The Server Will Restart in 9 Seconds...")
			scenterPrint("Press Enter To Stop the Server...")

			-- Countdown
			local x, y = sterm.getCursorPos()
			for i = 1, 9 do
				local check = sos.startTimer(1)

				while true do
					local event, id = sos.pullEvent()
					if event == "timer" and id == check then
						sterm.setCursorPos(1, 15)
						scenterWrite("The Server Will Restart in " .. 9 - i .. " Seconds...")
						break
					elseif event == "key" and id == 28 then
						sterm.clear()
						sterm.setCursorPos(1, 1)
						scenterPrint("Server Stopped...")
						serror()
						break
					end
				end
			end
		else
			serror()
			break
		end
	end
else
	sterm.clear()
	sterm.setCursorPos(1, 2)
	scenterPrint("HTTP API Not Enabled!")
	sprint("\n")
	scenterPrint("Warning:")
	scenterPrint("The HTTP API Is Not Enabled!")
	sprint(" ")
	scenterPrint("Firefox Server Requires The HTTP API To Be")
	scenterPrint("Enabled Before Running It.")
	sprint("\n\n")
	scenterPrint("[Exit Firefox Server]")
	while true do
		local _, key = os.pullEvent("key")
		if key == 28 then
			term.clear()
			term.setCursorPos(1, 1)
			break
		end
	end

	serror()
end
