--[[73
+ Added temp history
]]
local vserin = "--[[73"

local x,y = term.getSize()
local currentURL = "home"
local hasModem = true
local theme = "default"
local rednetType = "Rednet"
local tArgs = { ... }
local sHistory = { "secret" }
browserAgent = "rex_renewed"

local autoUpdater = "http://pastebin.com/raw.php?i=FwhQMq8v"
local WebsiteDatabase = "http://nexusindustries.x10.mx/Websites/folder/" --Folder with all the sites
local ApiPath = "http://nexusindustries.x10.mx/Websites/mcmain.php" --Path API is stored

local userSites = { --Message me on the forums if you want a pre-installed site
	["search"] = [[ loadWebpage( "nexus/search" ) ]],
	["secret"] = [[ print("lolufindsecretpage :3 (not done)") ]],
	["nexus"] = [[
	local x,y = term.getSize()

	function navBar()
		term.setCursorPos(1,y-1)
		write( string.rep( "-", x ) )
		term.setCursorPos(1,y)

		local pages = {}
		function addPage( name, link )
			pages[#pages+1] = {
				["Name"] = name,
				["Link"] = link,
			}
		end

		--Add your pages here

		addPage("Home","nexus")
		addPage("Contact Us","nexus/contact")
		addPage("IRC","nexus/games")
		addPage("Search","nexus/search")

		--End

		local maxPage = #pages
		for i=1,maxPage do
			local page = pages[i]
			newLink( " " ..page["Name"].. " ", page["Link"] )
			if i ~= maxPage then
				write("|")
			end
		end
	end

	cPrint("Site under construction",4)

	navBar()]],
	["nexus/contact"] = [[
	local x,y = term.getSize()

	function navBar()
		term.setCursorPos(1,y-1)
		write( string.rep( "-", x ) )
		term.setCursorPos(1,y)

		local pages = {}
		function addPage( name, link )
			pages[#pages+1] = {
				["Name"] = name,
				["Link"] = link,
			}
		end

		--Add your pages here

		addPage("Home","nexus")
		addPage("Contact Us","nexus/contact")
		addPage("IRC","nexus/games")
		addPage("Search","nexus/search")

		--End

		local maxPage = #pages
		for i=1,maxPage do
			local page = pages[i]
			newLink( " " ..page["Name"].. " ", page["Link"] )
			if i ~= maxPage then
				write("|")
			end
		end
	end

	cPrint("Contact Us",4)
	cPrint("Contact us by messaging xXm0dzXx when I am online")
	cPrint("(Message me with /msg xXm0dzXx <message>)")

	navBar()]],
	["nexus/games"] = [[
	--This program is owned and copyrighted by the NeXuS Coperation (c)
	--Program mainly coded by xXm0dzXx
	--Legal Notice:
	--                   DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
	--                                   Version 2, December 2004
	--Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
	--Everyone is permitted to copy and distribute verbatim or modified
	--copies of this license document, and changing it is allowed as long
	--as the name is changed.
	--                   DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
	--  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
	--0. You just DO WHAT THE FUCK YOU WANT TO.

	local messages = {};
	local serverHost = false;
	local channelOP = 0;
	local programName = shell.getRunningProgram()
	local getVersionIRC = "N-IRC v2.0"
	local x,y = term.getSize()
	local serverOPs = {}
	local banList = {}
	local function cPrint(text)
	   local x,y = term.getSize()
	   x2,y2 = term.getCursorPos()
	   term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)
	   write(text.. "\n")
	end

	function newIRCREAD( _sReplaceChar, _tHistory )
		term.setCursorBlink( true )

		local sLine = ""
		local nHistoryPos = nil
		local nPos = 0
		if _sReplaceChar then
			_sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
		end

		local w, h = term.getSize()
		local sx, sy = term.getCursorPos()
		local function redraw()
			local nScroll = 0
			if sx + nPos >= w then
				nScroll = (sx + nPos) - w
			end

			term.setCursorPos( sx, sy )
			term.write( string.rep(" ", w - sx + 1) )
			term.setCursorPos( sx, sy )
			if _sReplaceChar then
				term.write( string.rep(_sReplaceChar, string.len(sLine) - nScroll) )
			else
				term.write( string.sub( sLine, nScroll + 1 ) )
			end
			term.setCursorPos( sx + nPos - nScroll, h )
		end

		while true do
			local sEvent, param, message = os.pullEvent()
			if sEvent == "char" then
				sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
				nPos = nPos + 1
				redraw()

			elseif sEvent == "key" then
				if param == keys.enter then
					-- Enter
					break

				elseif param == keys.left then
					-- Left
					if nPos > 0 then
						nPos = nPos - 1
						redraw()
					end

				elseif param == keys.right then
					-- Right
					if nPos < string.len(sLine) then
						nPos = nPos + 1
						redraw()
					end

				elseif param == keys.up or param == keys.down then
					-- Up or down
					if _tHistory then
						if param == keys.up then
							-- Up
							if nHistoryPos == nil then
								if #_tHistory > 0 then
									nHistoryPos = #_tHistory
								end
							elseif nHistoryPos > 1 then
								nHistoryPos = nHistoryPos - 1
							end
						else
							-- Down
							if nHistoryPos == #_tHistory then
								nHistoryPos = nil
							elseif nHistoryPos ~= nil then
								nHistoryPos = nHistoryPos + 1
							end
						end

						if nHistoryPos then
							sLine = _tHistory[nHistoryPos]
							nPos = string.len( sLine )
						else
							sLine = ""
							nPos = 0
						end
						redraw()
					end
				elseif param == keys.backspace then
					-- Backspace
					if nPos > 0 then
						sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
						nPos = nPos - 1
						redraw()
					end
				end
			elseif sEvent == "rednet_message" then
				local id = param
				local _messageWords1 = split(message, ":")
				local _messageWords2 = split(message, "<!:>")
				local _messageLength2 = string.len("IRC_MESSAGE<!:>" .._tChannel.. "<!:>");
				local _messageLength3 = string.len("IRC_COMMAND:" .._tChannel.. ":");
				if serverHost and message == ("IRC_OPS:" .._tChannel) then
					rednet.send(id, textutils.serialize(serverOPs))
				elseif serverHost and message == ("IRC_BAN:" .._tChannel) then
					rednet.send(id, textutils.serialize(banList))
				elseif message == ("IRC_OP:" .._tChannel.. ":" .._tUser) then
					addMSG("You are now OP!")
				elseif _messageWords1[1] == ("IRC_JOIN") and _messageWords1[2] == (_tChannel) then
					if isBanned( _messageWords1[3] ) ~= true then
						addMSG(_messageWords1[3].. " has joined the server!")
					end
				elseif _messageWords2[1] == ("IRC_MESSAGE") and _messageWords2[2] == (_tChannel) then
					if isBanned( _messageWords2[3] ) ~= true then
						if isOP(_messageWords2[3],serverOPs) then
							addMSG("[" .._messageWords2[3].. "] " .._messageWords2[4])
						else
							addMSG("<" .._messageWords2[3].. "> " .._messageWords2[4])
						end
					end
				elseif message == ("ServerPing" .._tChannel) and serverHost then
					rednet.send(id, ("Ping_Received_" .._tChannel.. "_IRC"))
				end

				local x11,y11 = term.getSize()
				local x12,y12 = term.getCursorPos()
				term.clear()
				term.setCursorPos(1,1)
				print(_tUser.. " has joined the server!")
				for i=1,#messages do
					print(messages[i])
				end

				print()
				term.setCursorPos(1,y11)
				write("> " ..sLine)
			end
		end

		term.setCursorBlink( false )

		return sLine
	end

	function isOP( username )
		if serverHost ~= true then
			rednet.send(channelOP, "IRC_OPS:" .._tChannel)
			repeat
				id, message2 = rednet.receive()
			until id == channelOP
			serverOPs = textutils.unserialize(message2)
		end
		for i=1,#serverOPs do
			if serverOPs[i] == username then
				return true
			end
		end
		return false
	end

	function isBanned( username )
		if serverHost ~= true then
			rednet.send(channelOP, "IRC_BAN:" .._tChannel)
			repeat
				id, message2 = rednet.receive()
			until id == channelOP
			banList = textutils.unserialize(message2)
		end
		for i=1,#banList do
			if banList[i] == username then
				return true
			end
		end
		return false
	end

	function split( sLine, sCode )
		local tWords = {}
		for match in string.gmatch(sLine, "[^" ..sCode.. "\t]+") do
			table.insert( tWords, match )
		end
		return tWords
	end

	function startProgram()
		term.clear()
		term.setCursorPos(1,1)
		textutils.slowPrint("Opening modems...")
		rednet.open("top")
		textutils.slowPrint("Pinging server: " .._tChannel)
		local timer = os.startTimer(1)
		while true do
			rednet.broadcast("ServerPing" .._tChannel)
			local event, id, message = os.pullEvent()
			if event == "rednet_message" and message == "Ping_Received_" .._tChannel.. "_IRC" then
				channelOP = id;
				serverHost = false;
				textutils.slowPrint("Server found! Joining...")
				sleep(0.5)
				break
			elseif event == "timer" and id == timer then
				textutils.slowPrint("Server not detected. Hosting...")
				serverHost = true;
				serverOPs[1] = _tUser
				sleep(0.5)
				break
			end
		end
		term.clear()
		term.setCursorPos(1,1)
		sleep(0)
		function addMSG( messagez )
			messages[#messages + 1] = messagez
		end

		rednet.broadcast("IRC_JOIN:" .._tChannel.. ":" .._tUser)

		function b()
			while true do
				local x1,y1 = term.getCursorPos()
				local x,y = term.getSize()
				term.setCursorPos(1,1)
				print(_tUser.. " has joined the server!")

				term.setCursorPos(1, y)
				write("> ")
				local messageaa = newIRCREAD()
				term.setCursorPos(1,y-1)
				term.clearLine()
				term.setCursorPos(1,y)
				term.clearLine()
				term.setCursorPos(x1,y1)

				if string.sub(messageaa, 1, 1) == "/" then
					if string.sub(messageaa, 1, 3) == "/op" then
						if isOP(_tUser, serverOPs) then
							addMSG("(Console) Op'ing " ..string.sub(messageaa, 5, string.len(messageaa)))
							serverOPs[#serverOPs+1] = string.sub(messageaa, 5, string.len(messageaa))
							rednet.broadcast("IRC_OP:" .._tChannel.. ":" ..string.sub(messageaa, 5, string.len(messageaa)))
						else
							addMSG("No permission")
						end
					elseif string.sub(messageaa, 1, 5) == "/mute" then
						if isOP(_tUser, serverOPs) then
							addMSG(string.sub(messageaa, 7, string.len(messageaa)).. " has been muted.")
							banList[#banList+1] = string.sub(messageaa, 7, string.len(messageaa))
						else
							addMSG("No permission")
						end
					else
						addMSG("Unknown command.")
					end
				else
					if isBanned( _tUser ) then
						addMSG("You have been muted.")
					else
						if isOP(_tUser, serverOPs) then
							addMSG("[" .._tUser.. "] " ..messageaa)
						else
							addMSG("<" .._tUser.. "> " ..messageaa)
						end
						rednet.broadcast("IRC_MESSAGE<!:>" .._tChannel.. "<!:>" .._tUser.. "<!:>" ..messageaa)
					end
				end

				local x11,y11 = term.getSize()
				local x12,y12 = term.getCursorPos()
				term.clear()
				term.setCursorPos(1,1)
				print(_tUser.. " has joined the server!")
				for i=1,#messages do
					print(messages[i])
				end

				print()
			end
		end

		b()
	end

	function mainMenu( showAdministrator )
		term.clear()
		term.setCursorPos(1,4)
		cPrint("+--------------------+")
		cPrint("|     " ..getVersionIRC.. "     |")
		cPrint("|     ----------     |")
		cPrint("| User:              |")
		cPrint("| Channel: #         |")
		if showAdministrator then
			cPrint("|     ----------     |")
			cPrint("| Admin:             |")
			cPrint("| Enter administrator|")
			cPrint("| code to manage IRC.|")
		end
		cPrint("+--------------------+")

		if showAdministrator then
			term.setCursorPos(23,7)
			write(_tUser)
		else
			repeat
				term.setCursorPos(23,7)
				_tUser = read()
			until _tUser ~= ""
		end

		repeat
			term.setCursorPos(27,8)
			_tChannel = read()
		until _tChannel ~= ""

		if _tChannel == "ShowAdmin" then --OoOoOo! A easter egg :D Too bad you can't use it :/
			mainMenu( true )
		end

		if showAdministrator then
			term.setCursorPos(24,10)
			_tAdminCode = read()
			-- Doesn't do anything yet...
		end
	end

	function autoUpdate()
		term.clear()
		term.setCursorPos(1,6)
		cPrint("+--------------------+")
		cPrint("|     Loading...     |")
		cPrint("| ||||||             |") --Fake loading bar FTW
		cPrint("+--------------------+")
		while true do
			local downloadedFile = http.request("http://pastebin.com/raw.php?i=6QfbvrBW")
			local event, url, body = os.pullEvent()
			if event == "http_success" then
				_tBody = body.readAll()
				break
			elseif event == "http_failed" then
				break
			end
		end
		term.clear()
		term.setCursorPos(1,6)
		cPrint("+--------------------+")
		cPrint("|     Loading...     |")
		cPrint("| ||||||||||||       |")
		cPrint("+--------------------+")
		file = fs.open(programName, "r")
		_fBody = file.readAll()
		file.close()
		sleep(0.5)
		term.clear()
		term.setCursorPos(1,6)
		cPrint("+--------------------+")
		cPrint("|     Loading...     |")
		cPrint("| |||||||||||||||||| |")
		cPrint("+--------------------+")
		sleep(0.5)
		local selection = 1
		if _fBody ~= _tBody then
			while true do
				if selection == 1 then
					term.clear()
					term.setCursorPos(1,6)
					cPrint("+--------------------+")
					cPrint("| Install new update |")
					cPrint("| [Yes]    ?     No  |")
					cPrint("+--------------------+")
				else
					term.clear()
					term.setCursorPos(1,6)
					cPrint("+--------------------+")
					cPrint("| Install new update |")
					cPrint("|  Yes     ?    [No] |")
					cPrint("+--------------------+")
				end
				local event, key = os.pullEvent("key")
				if key == keys.left then
					selection = 1
				elseif key == keys.right then
					selection = 2
				elseif key == keys.enter then
					if selection == 1 then
						fs.delete(programName)
						file = fs.open(programName, "w")
						file.write(_tBody)
						file.close()
						shell.run(programName)
						error()
					else
						break
					end
				end
			end
		end
	end

	autoUpdate()
	mainMenu( false )
	startProgram()]],
	["nexus/search"] = [[
		local x,y = term.getSize()

		function navBar()
			term.setCursorPos(1,y-1)
			write( string.rep( "-", x ) )
			term.setCursorPos(1,y)

			local pages = {}
			function addPage( name, link )
				pages[#pages+1] = {
					["Name"] = name,
					["Link"] = link,
				}
			end

			--Add your pages here

			addPage("Home","nexus")
			addPage("Contact Us","nexus/contact")
			addPage("IRC","nexus/games")
			addPage("Search","nexus/search")

			--End

			if newLink then
				local maxPage = #pages
				for i=1,maxPage do
					local page = pages[i]
					newLink( " " ..page["Name"].. " ", page["Link"] )
					if i ~= maxPage then
						write("|")
					end
				end
			else
				if term.isColor() then
					term.setTextColour( colors.red )
				end
				print("NavBar v1.1 not supported in this version of REX.")
			end
		end

		rednet.broadcast("rednet.api.ping.searchengine")

		cPrint("NeXuS FailSearch v2.0")

		local timez = os.startTimer(0.5)
		repeat
			local event, key, URL = os.pullEvent()
			if event == "rednet_message" then
				cLink( URL )
			end
		until key == timez

		navBar()]],
}

function cWrite( txt, ypos )
	if ypos then
		term.setCursorPos(1,ypos)
	end

	local function printC( text )
		x2,y2 = term.getCursorPos()
		term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)
		write(text)
	end

	if type(txt) == "string" then
		printC( txt )
	elseif type(txt) == "table" then
		for i=1,#txt do
			printC( txt[i] )
		end
	end
end

function cPrint( txt, ypos ) --Version 2.0 of cPrint
	cWrite( txt, ypos )
	print()
end

local function sneakPeek()
	cPrint( {
		" ________/ _[]x |",
		"| Rednet        |",
		"|    News Today |",
		"|  11/29/2012   |",
		" ~~~~~~~~~~~~~~~ ",
	} )
	print("Creator of REX Renewed claims to be making a new protocal, quote: ")
	term.setTextColour( colors.gray )
	cPrint( {
		"\"Hey guys! I'm working on a new protocal",
		"In this protocal, everything is in 1 file,",
		"when you try to browse to it, it will exe-",
		"cute it but use the subpages in the URL as",
		"arguments in the program.                \"",
	} )
	term.setTextColour( colors.white )
	term.setCursorPos( 1, y )
	write("Posted on 11/29/2012")
end

local function newsPage()
	cPrint( {
		" ________/ _[]x |",
		"| Rednet        |",
		"|    News Today |",
		"|  11/29/2012   |",
		" ~~~~~~~~~~~~~~~ ",
	} )
	print()
	print("Welcome to the news site, this is where we add the current/upcoming events :D")
	print("\nWhats new ( #62 ): ")
	print("+ Added rdnt://search")
	print("+ Added rdnt://news")
	print("+ Added offline sites (Pre-installed)")
	print("- Removed text at bottom of Homepage (no room :c)")
	print("\nCreator of REX Renewed says a new protocal coming")
	write("Go to ")
	newLink( "rdnt://news/1-protocal", "news/1-protocal" )
	print(" for more info about this article.")
end

local function homePage()
	cPrint("__________ _______________  ___")
	cPrint("\\______   \\\\_   _____/\\   \\/  /")
	cPrint(" |       _/ |    __)_  \\     / ")
	cPrint(" |    |   \\ |        \\ /     \\ ")
	cPrint(" |____|_  //_______  //___/\\  \\")
	cPrint("        \\/         \\/       \\_/")
	cPrint("~~=> Renewed <=~~")
	print()
	cPrint("Default sites: ")
	cPrint("rdnt://home       Default Homepage")
	cPrint("rdnt://settings   Settings        ")
	cPrint("rdnt://newsite    Website Maker   ")
	cPrint("rdnt://search     Default Search  ")
	cPrint("rdnt://news       Rednet News     ")
	cPrint("rdnt://nexus      NeXuS Website   ")
	print()
	cWrite("rdnt://exit")
end

function rnetHost()
	term.clear()
	term.setCursorPos(1,1)
	cPrint("Rednet Explorer Online Servers")
	write("Domain (ex: YourDomain.com): rnet://")
	domain = read()
	write("Path to file: ")
	path = read()
	if fs.exists(path) then
		file = fs.open(path, "r")
		if file then
			data = file.readAll()
			file.close()
			if not data then
				print("Failed to read " ..path)
				return
			end
			local response = http.post(
			ApiPath,
			"type=upload&"..
			"user=guest&"..
			"pass=guest&"..
			"name=".. textutils.urlEncode(domain) .. "&"..
			"data=" ..textutils.urlEncode(data)
			)

			if response then
				local sResponse = response.readAll()
				response.close()
				print("Done!")
				print("Log: ")
				sleep(0.5)
				if string.find(sResponse, "success") then
					print("Uploading " ..shell.resolve(path).. " complete!")
					print("Errors: 0")
					print("\nGo to " ..domain.. " to check the site!")
				else
					print("Failed : " ..sResponse)
					print()
					if sResponse == "Write_lock" then
						print("The write_lock error means you have been locked out from uploading because are a hacker, a troll, or a spammer that is trying to upload a file to mess up my database and you are gonna be hunted down and killed (not IRL) by my team :)\n\nFYI, your IP has been traced.")
					end
				end
			else
				print("Failed to connect to database.")
			end
		else
			print("Failed to open " ..path)
		end
	else
		print(path.. " doesn't exist.")
	end
end

local function newButton( currentID, id, text, fez )
	if not fez then
		term.clearLine()
	end
	if currentID == id then
		cPrint("[ " ..text.. " ]")
	else
		cPrint(text)
	end
end

local function settings()
	local currentID = 1
	local function settingMenu()
		term.setCursorPos(1,5)
		cPrint("Configuration")
		print()
		newButton( currentID, 1, "Download Settings (" ..rednetType.. ")" )
		newButton( currentID, 2, "Homepage" )
		newButton( currentID, 3, "Extensions (NYI)" )
		newButton( currentID, 4, "Theme (" ..theme.. ")" )
		print()
		newButton( currentID, 5, "Exit" )
	end

	while true do
		settingMenu()
		local event, key = os.pullEvent("key")
		if key == keys.up then
			if currentID ~= 1 then
				currentID = currentID -1
			end
		elseif key == keys.down then
			if currentID ~= 5 then
				currentID = currentID +1
			end
		elseif key == keys.enter then
			if currentID == 1 then
				if rednetType == "Rednet" then
					rednetType = "HTTP"
				elseif rednetType == "HTTP" then
					rednetType = "rnet"
				elseif rednetType == "rnet" then
					rednetType = "Rednet"
				end

				loadWebpage( "settings" )
			elseif currentID == 2 then
				local newID = 1
				local currentTheme = ""
				local function settingMenu()
					term.clear()
					term.setCursorPos(1,1)
					cPrint("Homepage")
					file = fs.open( ".rexsettings", "r" )
					cPrint( "rdnt://" ..file.readLine() )
					currentTheme = file.readLine()
					file.close()
					print()
					newButton( newID, 1, "Change" )
					newButton( newID, 2, "Done" )
				end

				while true do
					settingMenu()
					local event, key = os.pullEvent("key")
					if key == keys.up then
						newID = 1
					elseif key == keys.down then
						newID = 2
					elseif key == keys.enter then
						if newID == 1 then
							term.setCursorPos(1,2)
							term.clearLine()
							write("rdnt://")
							local address = read()
							file = fs.open( ".rexsettings", "w" )
							file.write( address.. "\n" )
							file.write( currentTheme )
							file.close()
						else
							loadWebpage("settings")
						end
					end
				end
			elseif currentID == 3 then
			elseif currentID == 4 then
				if theme == "default" then
					theme = "old"
				elseif theme == "old" then
					theme = "edit"
				elseif theme == "edit" then
					theme = "default"
				end

				file = fs.open( ".rexsettings", "r" )
				local humpage = file.readLine()
				file.close()
				file = fs.open( ".rexsettings", "w" )
				file.write( humpage.. "\n" )
				file.write( theme )
				file.close()
				loadWebpage( "settings" )
			elseif currentID == 5 then
				break
			end
		end
	end

	loadWebpage( "home" )
end

local function newButton2( currentID, id, text )
	term.clearLine()
	if currentID == id then
		print("[>] " ..text)
	else
		print("[ ] " ..text)
	end
end

function newServer( newURL )
	if newURL == nil then
		print("Welcome to Rednet Servers!")
		print("Before we begin, please enter the URL of the website you want: ")
		write("\nrdnt://")
		newURL = read()
		rednet.broadcast( newURL )
		local id,message = rednet.receive( 0.5 )
		if message then
			print( "A website with this URL is already owned by " ..id.. ", continue? (Y/N)" )
			if string.lower( read() ) ~= "y" then
				return
			end
		end
	end

	function drawFooter()
		term.clear()
		term.setCursorPos(1,1)
		write("Hosting rdnt://" ..newURL)
		local x,y = term.getSize()
		for i=1,x do
			term.setCursorPos(i,2)
			write("-")
		end
	end

	function drawBrowser()
		term.setCursorPos(1,3)
		if fs.exists( "." ..newURL ) and fs.isDir( "." ..newURL ) then
			if fs.exists( "." ..newURL.. "/index" ) then
			else
				file = fs.open( "." ..newURL.. "/index", "w" )
				file.write( "print(\"This site has not yet been configured.\")" )
				file.close()
			end
		else
			fs.makeDir( "." ..newURL )
			file = fs.open( "." ..newURL.. "/index", "w" )
			file.write( "print(\"This site has not yet been configured.\")" )
			file.close()
		end

		local filePath = fs.list( "." ..newURL )
		for i=1,#filePath do
			newButton2( currentID, i, filePath[i] )
		end
	end

	local status = "[Delete]New Edit"
	currentID = 1
	while true do
		drawFooter()
		drawBrowser()
		term.setCursorPos(1,y)
		term.clearLine()
		write(status)
		local event, key, message = os.pullEvent()
		if event == "rednet_message" then
			if message == newURL then
				file = fs.open( "." ..newURL.. "/index", "r" )
				rednet.send( key, file.readAll() )
				file.close()
			elseif fs.exists( "." ..message ) then
				file = fs.open( "." ..message, "r" )
				if file then
					rednet.send( key, file.readAll() )
					file.close()
				end
			elseif message == "rednet.api.ping.searchengine" then
				rednet.send( key, newURL )
			end
		elseif event == "key" then
			if key == keys.left then
				if status == " Delete[New]Edit" then
					status = "[Delete]New Edit"
				elseif status == " Delete New[Edit]" then
					status = " Delete[New]Edit"
				end
			elseif key == keys.right then
				if status == " Delete[New]Edit" then
					status = " Delete New[Edit]"
				elseif status == "[Delete]New Edit" then
					status = " Delete[New]Edit"
				end
			elseif key == keys.up then
				if currentID ~= 1 then
					currentID = currentID -1
				end
			elseif key == keys.down then
				if currentID ~= #fs.list( "." ..newURL ) then
					currentID = currentID +1
				end
			elseif key == keys.enter then
				if status == "[Delete]New Edit" then
					local filePath = fs.list( "." ..newURL )
					fs.delete( "." ..newURL.. "/" ..filePath[ currentID ] )
					currentID = 1
				elseif status == " Delete[New]Edit" then
					term.setCursorPos(1,y)
					term.clearLine()
					write("URL: rdnt://" ..newURL.. "/")
					local fileName = read()
					local number = 1
					local origName = fileName

					while fs.exists( "." ..newURL.. "/" ..fileName ) do
						fileName = origName.. " [" ..number.. "]"
						number = number +1
					end

					file = fs.open( "." ..newURL.. "/" ..fileName, "w" )
					file.close()
				else
					local filePath = fs.list( "." ..newURL )
					shouldIendThis = false

					function a()
						while true do
							local timer = os.startTimer( 0.5 )
							local event, key, message = os.pullEvent()
							if event == "rednet_message" then
								if message == newURL then
									file = fs.open( "." ..newURL.. "/index", "r" )
									rednet.send( key, file.readAll() )
									file.close()
								elseif fs.exists( "." ..message ) then
									file = fs.open( "." ..message, "r" )
									if file then
										rednet.send( key, file.readAll() )
										file.close()
									end
								elseif message == "rednet.api.ping.searchengine" then
									rednet.send( key, newURL )
								end
							elseif shouldIendThis then
								break
							end
						end
					end

					function b()
						shell.run( "edit", "." ..newURL.. "/" ..filePath[ currentID ] )
						shouldIendThis = true
					end

					parallel.waitForAny( a, b )
					drawFooter()
				end
			end
		end
	end
end

function loadWebpage( url, id )
	if term.isColor() then
		term.setTextColour( colors.white )
		term.setBackgroundColour( colors.black )
	end

	if not url then
		url = currentURL
	end
	currentURL = url
	tLinks = {}
	function newLink( text, link )
		if link == nil then
			link = text
		end
		local xx, yy = term.getCursorPos()
		if term.isColor() then
			term.setTextColour( colors.lightBlue )
		end
		write( text )
		if term.isColor() then
			term.setTextColour( colors.white )
		end
		local xxx, yyy = term.getCursorPos()
		tLinks[ #tLinks+1 ] = {
			["Text"] = text,
			["To"] = link,
			["X"] = xx,
			["Y"] = yy,
			["eX"] = xxx,
			["eY"] = yyy,
		}

		return
	end

	function cLink( text, link, yPos )
		x2,y2 = term.getCursorPos()
		if yPos ~= nil then
			y2 = yPos
		end
		if link == nil then
			link = text
		elseif type(link) == "number" then
			yPos = link
			link = text
		end
		term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)

		newLink( text, link )
		print()
	end

	term.clear()
	term.setCursorPos(1,1)

	if theme == "default" then
		if rednetType == "HTTP" then
			print("http://" ..currentURL)
		elseif rednetType == "rnet" then
			print("rnet://" ..currentURL)
		else
			print("rdnt://" ..currentURL)
		end

		for i=1,x do
			term.setCursorPos(i,2)
			write("-")
		end
		term.setCursorPos(1,3)
	elseif theme == "old" then
		cPrint("Rednet Explorer")
		if rednetType == "HTTP" then
			cPrint("http://" ..currentURL )
		elseif rednetType == "rnet" then
			cPrint("rnet://" ..currentURL )
		else
			cPrint("rdnt://" ..currentURL)
		end
		term.setCursorPos(1,4)
	elseif theme == "edit" then
		term.setCursorPos(1,y)
		write("Press CTRL to access menu")
	end

	local function executeP( path )
		shell.run( path )
	end

	if url == "home" then
		homePage()
	elseif url == "newsite" then
		if rednetType == "rnet" then
			rnetHost()
		else
			newServer()
		end
	elseif url == "settings" then
		settings()
	elseif url == "exit" then
		error()
	elseif url == "news" then
		newsPage()
	elseif url == "news/1-protocal" then
		sneakPeek()
	elseif url == "search" then
		loadWebpage( "nexus/search" )
	elseif userSites[ url ] then
		fs.delete( ".downloadedWebsite" )
		webpage = fs.open( ".downloadedWebsite", "w" )
		webpage.write( userSites[ url ] )
		webpage.close()
		executeP( ".downloadedWebsite" )
	else
		if rednetType == "HTTP" then
			http.request( "http://" ..url )
			readTimedOut = os.startTimer(3)
			local text = ""
			while true do
				local event, body, url = os.pullEvent()
				if event == "http_success" then
					text = url.readAll()
					break
				elseif event == "http_failed" then
					text = "Failed to load"
					break
				elseif event == "timer" and body == readTimedOut then
					text = "Read timed out"
					break
				end
			end

			print( text )
		elseif rednetType == "rnet" then
			local response = http.post(
			ApiPath,
			"user=guest&"..
			"pass=guest&"..
			"type=download&"..
			"data=blank&"..
			"name=".. textutils.urlEncode(url)
			)

			if response then
				local body = response.readAll()
				response.close()
				if body == nil or body == "" or string.find(body, "auth_error") or string.find(body, "file_not_found") then
					print("Unable to load webpage.")
					print("\nThe website you have requested was unable to work. If you beleive this is a error please contact your rednet service providers. (RSP)")
					print("\nThis may be the result of the list below: ")
					print("1) The site you requested is down.")
					print("2) The site you requested is corrupted.")
					print("3) The site you requested forgot to put a modem")
					print("4) You have no modem")
					print("5) This message is faked, and you have a virus now.")
				else
					fs.delete(".downloadedWebsite")
					webpage = fs.open(".downloadedWebsite", "w")
					webpage.write(body)
					webpage.close()
					executeP(".downloadedWebsite")
				end
			end
		else

			if id then
				fs.delete(".downloadedWebsite")
				file = fs.open(".downloadedWebsite", "w")
				file.write( id )
				file.close()
				executeP(".downloadedWebsite")
			else
				if hasModem then
					if id then
						rednet.send( id, url )
					else
						rednet.broadcast( url )
					end

					local timer = os.startTimer(0)
					local messages = {}
					repeat
						local event, key, message = os.pullEvent()
						if event == "rednet_message" then
							if id then
								if key == id then
									messages[#messages+1] = {
										["id"] = key,
										["code"] = message,
									}
								end
							else
								messages[#messages+1] = {
									["id"] = key,
									["code"] = message,
								}
							end
						end
					until event == "timer" and key == timer

					if #messages == 1 then
						fs.delete(".downloadedWebsite")
						file = fs.open(".downloadedWebsite", "w")
						file.write( messages[1]["code"] )
						file.close()
						executeP(".downloadedWebsite")
					elseif #messages == 0 then
						print("Unable to load webpage.")
						print("\nThe website you have requested was unable to work. If you beleive this is a error please contact your rednet service providers. (RSP)")
						print("\nThis may be the result of the list below: ")
						print("1) The site you requested is down.")
						print("2) The site you requested is corrupted.")
						print("3) The site you requested forgot to put a modem")
						print("4) You have no modem")
						print("5) This message is faked, and you have a virus now.")
					else
						local id = 0
						local valvez = true
						id = messages[1]["id"]
						for i=2,#messages do
							if messages[i]["id"] ~= id then
								valvez = false
							end
						end

						if valvez then
							fs.delete(".downloadedWebsite")
							file = fs.open(".downloadedWebsite", "w")
							file.write( messages[1]["code"] )
							file.close()
							executeP(".downloadedWebsite")
						else
							local x1, y1 = term.getCursorPos()
							local currentID = 1
							while true do
								term.setCursorPos(1,y1)
								cPrint("+---Conflict Warning---+")
								cPrint("| 2 or more hosts have |")
								cPrint("| been found, please   |")
								cPrint("| select the correct ID|")
								cPrint("+----------------------+")
								for i=1,#messages do
									local xx, yy = term.getCursorPos()
									cPrint("|                      |")
									term.setCursorPos(xx, yy)
									newButton( currentID, i, "#" ..messages[i]["id"], true )
								end

								cPrint("+----------------------+")

								local event, key = os.pullEvent("key")
								if key == keys.up then
									if currentID ~= 1 then
										currentID = currentID -1
									end
								elseif key == keys.down then
									if currentID ~= #messages then
										currentID = currentID +1
									end
								elseif key == keys.enter then
									local code = messages[currentID]["code"]
									loadWebpage( url, code )
									break
								end
							end
						end
					end
				else
					print("\nUnable to connect because no modem has been detected on your computer. Please attatch a modem and restart this program. ")
				end
			end
		end
	end

	if term.isColor() then
		term.setTextColour( colors.white )
		term.setBackgroundColour( colors.black )
	end

	if theme == "default" then
		term.setCursorPos(x-#("Press CTRL to brows"), 1)
		write("Press CTRL to browse")
	elseif theme == "old" then
		term.setCursorPos(x-#("Press CTRL to explor"), y)
		write("Press CTRL to explore")
	end

	while true do
		local event, key, mX, mY = os.pullEvent()
		if event == "key" then
			if key == 29 or key == 157 then
				break
			elseif key == 63 then
				loadWebpage( url, id )
			end
		elseif event == "mouse_click" then
			if key == 1 then
				for i=1,#tLinks do
					local link = tLinks[i]
					if mY == link["Y"] then
						if mX >= link["X"] and mX <= link["eX"] then
							loadWebpage( link["To"] )
						end
					end
				end
			end
		end
	end

	if theme == "default" then
		term.setCursorPos(1,1)
		term.clearLine()

		if rednetType == "HTTP" then
			write("http://")
		elseif rednetType == "rnet" then
			write("rnet://")
		else
			write("rdnt://")
		end
	elseif theme == "old" or theme == "edit" then
		term.setCursorPos(1,2)
		term.clearLine()

		if rednetType == "HTTP" then
			write("http://")
		elseif rednetType == "rnet" then
			write("rnet://")
		else
			write("rdnt://")
		end
	end

	local sText = read( nil, sHistory )
	if sHistory[1] == "secret" and #sHistory == 1 then
		sHistory[1] = sText
	else
		table.insert( sHistory, sText )
	end

	loadWebpage( sText )
end

local function openModems()
	for i,v in pairs( rs.getSides() ) do
		if rednet.open( v ) then
			return true
		end
	end
end

openModems()

if fs.exists(".rexsettings") then
	file = fs.open(".rexsettings", "r")
	currentURL = file.readLine()
	theme = file.readLine()
	file.close()
else
	file = fs.open(".rexsettings", "w")
	file.write( "home\n" )
	file.write( "default" )
	file.close()
end

---API/Compatibility---
centerPrint = cPrint
reDirect = loadWebpage
loadPage = loadWebpage
---API/Compatibility---

--tArgs: rex server <name>
if tArgs[1] == "server" then
	if tArgs[2] then
		newServer( tArgs[2] )
	else
		print("Usage: rex server <name>")
		return
	end
end

fs.delete( ".temporarilyUpdatingFileChecker" )
file = fs.open( ".temporarilyUpdatingFileChecker", "w" )
file.write( http.get( autoUpdater ).readAll() )
file.close()

file = fs.open( ".temporarilyUpdatingFileChecker", "r" )
local newestVersion = file.readLine()
local desc = file.readLine()
file.close()

if newestVersion ~= vserin then
	term.clear()
	term.setCursorPos(1,1)
	print("rdnt://update")
	for i=1,x do
		term.setCursorPos(i,2)
		write("-")
	end
	print()
	cPrint("__________ _______________  ___")
	cPrint("\\______   \\\\_   _____/\\   \\/  /")
	cPrint(" |       _/ |    __)_  \\     / ")
	cPrint(" |    |   \\ |        \\ /     \\ ")
	cPrint(" |____|_  //_______  //___/\\  \\")
	cPrint("        \\/         \\/       \\_/")
	cPrint("(!!) New Update Available (!!)")
	print()
	cPrint("Changelog")
	cPrint("+-------+")
	cPrint( desc )
	cPrint("+-------+")
	print()
	cPrint("Update?")
	local x2,y2 = term.getCursorPos()
	local selection = 1
	while true do
		term.setCursorPos( x2, y2 )
		term.clearLine()
		if selection == 1 then
			cPrint("[ Yes ] No  ")
		else
			cPrint("  Yes [ No ]")
		end
		local event, key = os.pullEvent("key")
		if key == keys.left then
			selection = 1
		elseif key == keys.right then
			selection = 9001
		elseif key == keys.enter then
			break
		end
	end

	if selection == 1 then
		cPrint("Updating...")
		local sPath = shell.getRunningProgram()
		if fs.isReadOnly( sPath ) then
			cPrint("Failed...")
			sleep(1)
		else
			fs.delete( sPath )
			shell.run( "pastebin", "get", "FwhQMq8v", sPath )
			term.clear()
			term.setCursorPos(1,1)
			print("rdnt://exit")
			for i=1,x do
				term.setCursorPos(i,2)
				write("-")
			end
			cPrint("Updated! Browser restarted")
			error()
		end
	end
end

loadWebpage()
