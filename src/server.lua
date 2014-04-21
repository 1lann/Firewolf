
--
--  Firewolf Server
--  Made by GravityScore and 1lann
--



--    Variables


local version = "3.0"
local build = 0
local args = {...}

local w, h = term.getSize()

local serversFolder = "/fw_servers"
local indexFileName = "index"

local sides = {}

local menubarWindow = nil
local updateMenubarEvent = "firewolfServer_updateMenubarEvent"
local triggerErrorEvent = "firewolfServer_triggerErrorEvent"
local tabSwitchEvent = "firewolfServer_tabSwitchEvent"

local maxTabs = 3
local maxTabNameWidth = 14
local currentTab = 1
local tabs = {}

local publicDnsChannel = 9999
local publicRespChannel = 9998
local responseID = 41738

local DNSRequestTag = "--@!FIREWOLF-LIST!@--"
local DNSResponseTag = "--@!FIREWOLF-DNSRESP!@--"
local connectTag = "--@!FIREWOLF-CONNECT!@--"
local disconnectTag = "--@!FIREWOLF-DISCONNECT!@--"
local receiveTag = "--@!FIREWOLF-RECEIVE!@--"
local headTag = "--@!FIREWOLF-HEAD!@--"
local bodyTag = "--@!FIREWOLF-BODY!@--"
local initiateTag = "--@!FIREWOLF-INITIATE!@--"
local protocolTag = "--@!FIREWOLF-REDNET-PROTOCOL!@--"

local initiatePattern = "^%-%-@!FIREWOLF%-INITIATE!@%-%-(.+)"
local retrievePattern = "^%-%-@!FIREWOLF%-FETCH!@%-%-(.+)"


local theme = {}

local colorTheme = {
	background = colors.gray,
	accent = colors.red,
	subtle = colors.orange,

	lightText = colors.gray,
	text = colors.white,
	errorText = colors.red,

	yellow = colors.yellow,
}

local grayscaleTheme = {
	background = colors.black,
	accent = colors.black,
	subtle = colors.black,

	lightText = colors.white,
	text = colors.white,
	errorText = colors.white,

	yellow = colors.white
}



--    Default Pages


local defaultPages = {}


defaultPages["404"] = [[
local function center(text)
	local w, h = term.getSize()
	local x, y = term.getCursorPos()
	term.setCursorPos(math.floor(w / 2 - text:len() / 2) + (text:len() % 2 == 0 and 1 or 0), y)
	term.write(text)
	term.setCursorPos(1, y + 1)
end

term.setTextColor(colors.white)
term.setBackgroundColor(colors.gray)
term.clear()

term.setCursorPos(1, 4)
center("Error 404")
print("\n")
center("The page could not be found.")
]]


defaultPages["index"] = [[
term.setCursorPos(3, 5)
print("Welcome to ${DOMAIN}")
]]



--    Modified Read


local modifiedRead = function(properties)
	local text = ""
	local startX, startY = term.getCursorPos()
	local pos = 0

	local previousText = ""
	local readHistory = nil
	local historyPos = 0

	if not properties then
		properties = {}
	end

	if properties.displayLength then
		properties.displayLength = math.min(properties.displayLength, w - 2)
	else
		properties.displayLength = w - startX - 1
	end

	if properties.startingText then
		text = properties.startingText
		pos = text:len()
	end

	if properties.history then
		readHistory = {}
		for k, v in pairs(properties.history) do
			readHistory[k] = v
		end
	end

	if readHistory and readHistory[1] == text then
		table.remove(readHistory, 1)
	end

	local draw = function(replaceCharacter)
		local scroll = 0
		if properties.displayLength and pos > properties.displayLength then
			scroll = pos - properties.displayLength
		end

		local repl = replaceCharacter or properties.replaceCharacter
		term.setTextColor(theme.text)
		term.setCursorPos(startX, startY)
		if repl then
			term.write(string.rep(repl:sub(1, 1), text:len() - scroll))
		else
			term.write(text:sub(scroll + 1))
		end

		term.setCursorPos(startX + pos - scroll, startY)
	end

	term.setCursorBlink(true)
	draw()
	while true do
		local event, key, x, y, param4, param5 = os.pullEvent()

		if properties.onEvent then
			-- Actions:
			-- - exit (bool)
			-- - text
			-- - nullifyText

			term.setCursorBlink(false)
			local action = properties.onEvent(text, event, key, x, y, param4, param5)
			if action then
				if action.text then
					draw(" ")
					text = action.text
					pos = text:len()
				end if action.nullifyText then
					text = nil
					action.exit = true
				end if action.exit then
					break
				end
			end
			draw()
		end

		term.setCursorBlink(true)
		if event == "char" then
			local canType = true
			if properties.maxLength and text:len() >= properties.maxLength then
				canType = false
			end

			if canType then
				text = text:sub(1, pos) .. key .. text:sub(pos + 1, -1)
				pos = pos + 1
				draw()
			end
		elseif event == "key" then
			if key == keys.enter then
				break
			elseif key == keys.left and pos > 0 then
				pos = pos - 1
				draw()
			elseif key == keys.right and pos < text:len() then
				pos = pos + 1
				draw()
			elseif key == keys.backspace and pos > 0 then
				draw(" ")
				text = text:sub(1, pos - 1) .. text:sub(pos + 1, -1)
				pos = pos - 1
				draw()
			elseif key == keys.delete and pos < text:len() then
				draw(" ")
				text = text:sub(1, pos) .. text:sub(pos + 2, -1)
				draw()
			elseif key == keys.home then
				pos = 0
				draw()
			elseif key == keys["end"] then
				pos = text:len()
				draw()
			elseif (key == keys.up or key == keys.down) and readHistory then
				local shouldDraw = false
				if historyPos == 0 then
					previousText = text
				elseif historyPos > 0 then
					readHistory[historyPos] = text
				end

				if key == keys.up then
					if historyPos < #readHistory then
						historyPos = historyPos + 1
						shouldDraw = true
					end
				else
					if historyPos > 0 then
						historyPos = historyPos - 1
						shouldDraw = true
					end
				end

				if shouldDraw then
					draw(" ")
					if historyPos > 0 then
						text = readHistory[historyPos]
					else
						text = previousText
					end
					pos = text:len()
					draw()
				end
			end
		elseif event == "mouse_click" then
			local scroll = 0
			if properties.displayLength and pos > properties.displayLength then
				scroll = pos - properties.displayLength
			end

			if y == startY and x >= startX and x <= math.min(startX + text:len(), startX + (properties.displayLength or 10000)) then
				pos = x - startX + scroll
				draw()
			elseif y == startY then
				if x < startX then
					pos = scroll
					draw()
				elseif x > math.min(startX + text:len(), startX + (properties.displayLength or 10000)) then
					pos = text:len()
					draw()
				end
			end
		end
	end

	term.setCursorBlink(false)
	print("")
	return text
end



--    RC4
--    Implementation by AgentE382


local cryptWrapper = function(plaintext, salt)
	local key = type(salt) == "table" and {unpack(salt)} or {string.byte(salt, 1, #salt)}
	local S = {}
	for i = 0, 255 do
		S[i] = i
	end

	local j, keylength = 0, #key
	for i = 0, 255 do
		j = (j + S[i] + key[i % keylength + 1]) % 256
		S[i], S[j] = S[j], S[i]
	end

	local i = 0
	j = 0
	local chars, astable = type(plaintext) == "table" and {unpack(plaintext)} or {string.byte(plaintext, 1, #plaintext)}, false

	for n = 1, #chars do
		i = (i + 1) % 256
		j = (j + S[i]) % 256
		S[i], S[j] = S[j], S[i]
		chars[n] = bit.bxor(S[(S[i] + S[j]) % 256], chars[n])
		if chars[n] > 127 or chars[n] == 13 then
			astable = true
		end
	end

	return astable and chars or string.char(unpack(chars))
end


local crypt = function(plaintext, salt)
	local resp, msg = pcall(cryptWrapper, plaintext, salt)
	if resp then
		if type(msg) == "table" then
			return textutils.serialize(msg)
		else
			return msg
		end
	else
		return nil
	end
end



--    GUI


local clear = function(bg, fg)
	term.setTextColor(fg)
	term.setBackgroundColor(bg)
	term.clear()
	term.setCursorPos(1, 1)
end


local fill = function(x, y, width, height, bg)
	term.setBackgroundColor(bg)
	for i = y, y + height - 1 do
		term.setCursorPos(x, i)
		term.write(string.rep(" ", width))
	end
end


local center = function(text)
	local x, y = term.getCursorPos()
	term.setCursorPos(math.floor(w / 2 - text:len() / 2) + (text:len() % 2 == 0 and 1 or 0), y)
	term.write(text)
	term.setCursorPos(1, y + 1)
end


local title = function(text)
	fill(1, 1, w, 1, theme.accent)
	term.setCursorPos(2, 1)
	term.write(text)

	term.setCursorPos(w, 1)
	term.write("x")

	term.setBackgroundColor(theme.background)
end


local centerSplit = function(text, width)
	local words = {}
	for word in text:gmatch("[^ \t]+") do
		table.insert(words, word)
	end

	local lines = {""}
	while lines[#lines]:len() < width do
		lines[#lines] = lines[#lines] .. words[1] .. " "
		table.remove(words, 1)

		if #words == 0 then
			break
		end

		if lines[#lines]:len() + words[1]:len() >= width then
			table.insert(lines, "")
		end
	end

	for _, line in pairs(lines) do
		center(line)
	end
end



--    Backend


local setupModem = function()
	for _, v in pairs(redstone.getSides()) do
		if peripheral.getType(v) == "modem" then
			table.insert(sides, v)
		end
	end

	if #sides <= 0 then
		error("No modem found!")
	end
end


local modem = function(func, ...)
	for _, side in pairs(sides) do
		if peripheral.getType(side) == "modem" then
			peripheral.call(side, func, ...)
		end
	end

	return true
end


local calculateChannel = function(domain, distance, id)
	local total = 1

	if distance then
		id = (id + 3642 * math.pi) % 100000
		if tostring(distance):find("%.") then
			local distProc = (tostring(distance):sub(1, tostring(distance):find("%.") + 1)):gsub("%.", "")
			total = tonumber(distProc..id)
		else
			total = tonumber(distance..id)
		end
	end

	for i = 1, #domain do
		total = total * string.byte(domain:sub(i, i))
		if total > 10000000000 then
			total = tonumber(tostring(total):sub(-5, -1))
		end
		while tostring(total):sub(-1, -1) == "0" do
			total = tonumber(tostring(total):sub(1, -2))
		end
	end

	return (total % 50000) + 10000
end


local isSession = function(sessions, channel, distance, id)
	for k, v in pairs(sessions) do
		if v[1] == distance and v[2] == id and v[3] == channel then
			return true
		end
	end

	return false
end


local fetchPage = function(domain, page)
	if (page:match("(.+)%.fwml$")) then
		page = page:match("(.+)%.fwml$")
	end

	local path = serversFolder .. "/" .. domain .. "/" .. page
	if fs.exists(path) and not fs.isDir(path) then
		local f = io.open(path, "r")
		local contents = f:read("*a")
		f:close()

		return contents, "lua"
	else
		if fs.exists(path..".fwml") and not fs.isDir(path..".fwml") then
			local f = io.open(path..".fwml", "r")
			local contents = f:read("*a")
			f:close()

			return contents, "fwml"
		end
	end

	return nil
end


local fetch404 = function(domain)
	local path = serversFolder .. "/" .. domain .. "/404"
	if fs.exists(path) and not fs.isDir(path) then
		local f = io.open(path, "r")
		local contents = f:read("*a")
		f:close()

		return contents
	else
		return defaultPages["404"]
	end
end


local backend = function(serverURL, onEvent, onMessage)
	local serverChannel = calculateChannel(serverURL)
	local sessions = {}

	local receivedMessages = {}
    local receivedMessageTimeouts = {}

    onMessage("Hosting rdnt://" .. serverURL)
	onMessage("Listening for incoming requests...")

	modem("closeAll")
	modem("open", publicDnsChannel)
	modem("open", serverChannel)
	modem("open", rednet.CHANNEL_REPEAT)

	for _, side in pairs(sides) do
		if peripheral.getType(side) == "modem" then
			rednet.open(side)
		end
	end

	rednet.host(protocolTag .. serverURL, initiateTag .. serverURL)

	while true do
		local eventArgs = {os.pullEvent()}
		local event, givenSide, givenChannel, givenID, givenMessage, givenDistance = unpack(eventArgs)
		if event == "modem_message" then
			if givenChannel == publicDnsChannel and givenMessage == DNSRequestTag and givenID == responseID then
				modem("open", publicRespChannel)
				modem("transmit", publicRespChannel, responseID, DNSResponseTag .. serverURL)
				modem("close", publicRespChannel)
			elseif givenChannel == serverChannel and givenMessage:match(initiatePattern) == serverURL then
				modem("transmit", serverChannel, responseID, crypt(connectTag .. serverURL, serverURL .. tostring(givenDistance) .. givenID))

				if #sessions > 50 then
					modem("close", sessions[#sessions][3])
					table.remove(sessions)
				end

				local isInSessions = false
				for k, v in pairs(sessions) do
					if v[1] == givenDistance and v[3] == givenID then
						isInSessions = true
					end
				end

				local userChannel = calculateChannel(serverURL, givenDistance, givenID)
				if not isInSessions then
					onMessage("[DIRECT] Starting encrypted connection: " .. userChannel)
					table.insert(sessions, {givenDistance, givenID, userChannel})
					modem("open", userChannel)
				else
					modem("open", userChannel)
				end
			elseif isSession(sessions, givenChannel, givenDistance, givenID) then
				local request = crypt(textutils.unserialize(givenMessage), serverURL .. tostring(givenDistance) .. givenID)
				if request then
					local domain = request:match(retrievePattern)
					if domain then
						local page = domain:match("^[^/]+/(.+)")
						if not page then
							page = "index"
						end

						onMessage("[DIRECT] Requested: /" .. page)

						local contents, language = fetchPage(serverURL, page)
						if not contents then
							contents = fetch404(serverURL)
						end

						local header
						if language == "fwml" then
							header = {language = "Firewolf Markup"}
						else
							header = {language = "Lua"}
						end

						modem("transmit", givenChannel, responseID, crypt(headTag .. textutils.serialize(header) .. bodyTag .. contents, serverURL .. tostring(givenDistance) .. givenID))
					elseif request == disconnectTag then
						for k, v in pairs(sessions) do
							if v[2] == givenChannel then
								sessions[k] = nil
								break
							end
						end

						modem("close", givenChannel)
						onMessage("[DIRECT] Connection closed: " .. givenChannel)
					end
				end
			elseif givenChannel == rednet.CHANNEL_REPEAT and type(givenMessage) == "table"
			and givenMessage.nMessageID and givenMessage.nRecipient and
			not receivedMessages[givenMessage.nMessageID] then
				receivedMessages[givenMessage.nMessageID] = true
				receivedMessageTimeouts[os.startTimer(30)] = givenMessage.nMessageID

				modem("transmit", rednet.CHANNEL_REPEAT, givenID, givenMessage)
				modem("transmit", givenMessage.nRecipient, givenID, givenMessage)
			end
		elseif event == "timer" then
			local messageID = receivedMessageTimeouts[givenSide]
			if messageID then
				receivedMessageTimeouts[givenSide] = nil
				receivedMessages[messageID] = nil
			end
		elseif event == "rednet_message" then
			if givenID == DNSRequestTag and givenChannel == DNSRequestTag then
				rednet.send(givenSide, DNSResponseTag .. serverURL, DNSRequestTag)
			elseif givenID == protocolTag .. serverURL then
				local id = givenSide
				local decrypt = crypt(textutils.unserialize(givenChannel), serverURL .. id)
				if decrypt then
					local domain = decrypt:match(retrievePattern)
					if domain then
						local page = domain:match("^[^/]+/(.+)")
						if not page then
							page = "index"
						end

						onMessage("[REDNET] Requested: /" .. page .. " from " .. id)

						local contents, language = fetchPage(serverURL, page)
						if not contents then
							contents = fetch404(serverURL)
						end

						local header
						if language == "fwml" then
							header = {language = "Firewolf Markup"}
						else
							header = {language = "Lua"}
						end

						rednet.send(id, crypt(headTag .. textutils.serialize(header) .. bodyTag .. contents, serverURL .. givenSide), protocolTag .. serverURL)
					end
				end
			end
		end

		local shouldExit = onEvent(unpack(eventArgs))
		if shouldExit then
			rednet.unhost(protocolTag .. serverURL, initiateTag .. serverURL)
			break
		end
	end
end



--    Modification


local isValidDomain = function(domain)
	local success = domain:match("^([a-zA-Z0-9_%-%.]+)$")
	if success and domain:sub(1, 1) ~= "-" and domain:len() > 3 and domain:len() < 30 then
		return true
	else
		return false
	end
end


local serverExists = function(domain)
	local path = serversFolder .. "/" .. domain
	if fs.exists(path) and fs.exists(path .. "/" .. indexFileName) then
		return true
	end

	return false
end


local listServers = function()
	local servers = {}
	local contents = fs.list(serversFolder)

	for k, name in pairs(contents) do
		local path = serversFolder .. "/" .. name
		if fs.isDir(path) and not fs.isDir(path .. "/" .. indexFileName) then
			table.insert(servers, "rdnt://" .. name)
		end
	end

	return servers
end


local newServer = function(domain)
	if not isValidDomain(domain) then
		return
	end

	local path = serversFolder .. "/" .. domain
	fs.makeDir(path)

	local indexPath = path .. "/index"
	local indexContent = defaultPages["index"]:gsub("${DOMAIN}", domain)

	local f = io.open(indexPath, "w")
	f:write(indexContent)
	f:close()
end


local deleteServer = function(domain)
	if not isValidDomain(domain) then
		return
	end

	local path = serversFolder .. "/" .. domain
	fs.delete(path)
end


local hostOnStartup = function(domain)
	local path = serversFolder .. "/" .. domain
	if fs.isDir(path) and fs.exists(path .. "/" .. indexFileName) then
		if fs.exists("/startup") then
			if not fs.isDir("/startup") then
				local f = io.open("/startup", "r")
				local firstLine = f:read("*l")
				if firstLine ~= "-- Launch Firewolf Server" then
					fs.move("/startup", "/old-startup")
				end

				f:close()
			else
				fs.move("/startup", "/old-startup")
			end
		end

		local f = io.open("/startup", "w")
		f:write("-- Launch Firewolf Server\nshell.run(\"/" .. shell.getRunningProgram() .. "\", \"" .. domain .. "\")")
		f:close()
	end
end



--    Menu Bar


local getTabName = function(domain)
	local name = domain
	if name:len() > maxTabNameWidth then
		name = name:sub(1, maxTabNameWidth)
	end

	if name:sub(-1, -1) == "." then
		name = name:sub(1, -2)
	end

	return name
end


local determineClickedTab = function(x, y)
	if y == 2 then
		local minx = 2
		for i, tab in pairs(tabs) do
			local name = getTabName(tab.domain)

			if x >= minx and x <= minx + name:len() - 1 then
				return i
			elseif x == minx + name:len() and i == currentTab and #tabs > 1 then
				return "close"
			else
				minx = minx + name:len() + 2
			end
		end

		if x == minx and #tabs < maxTabs then
			return "new"
		end
	end

	return nil
end


local setupMenubar = function()
	menubarWindow = window.create(term.native(), 1, 1, w, 2, false)
end


local drawMenubar = function()
	term.redirect(menubarWindow)
	menubarWindow.setVisible(true)

	clear(theme.background, theme.text)

	fill(1, 1, w, 1, theme.accent)
	term.setCursorPos(2, 1)
	term.write("Firewolf Server " .. version)
	term.setCursorPos(w, 1)
	term.write("x")

	fill(1, 2, w, 1, theme.subtle)
	term.setCursorPos(1, 2)

	for i, tab in pairs(tabs) do
		term.setTextColor(theme.lightText)
		if i == currentTab then
			term.setTextColor(theme.text)
		end

		local name = getTabName(tab.domain)
		term.write(" " .. name)

		if i == currentTab then
			term.setTextColor(theme.errorText)
			term.write("x")
		else
			term.write(" ")
		end
	end

	if #tabs < maxTabs then
		term.setTextColor(theme.lightText)
		term.write(" + ")
	end
end



--    Hosting Interface


local editServer = function(domain)
	clear(colors.black, colors.white)

	local path = serversFolder .. "/" .. domain
	local oldDir = shell.dir()
	shell.setDir(path)

	term.setCursorPos(1, 1)
	while true do
		term.setTextColor(theme.yellow)
		term.write("> ")
		term.setTextColor(colors.white)
		local command = modifiedRead()
	end

	shell.setDir(oldDir)
end


local hostInterface = function(index, domain)
	local log = {}
	local height = h - 4

	local buttons = {
		{text = "Edit Files", action = function()
			editServer(domain)
		end},
		{text = "Run on Startup", action = function()
			hostOnStartup(domain)
		end},
	}

	local draw = function()
		clear(theme.background, theme.text)
		term.setCursorPos(1, 2)

		for i, button in pairs(buttons) do
			local x, y = term.getCursorPos()
			buttons[i].startX = x + 1
			term.write(" [" .. button.text .. "] ")

			x, y = term.getCursorPos()
			buttons[i].endX = x - 1
			buttons[i].y = y
		end

		term.setCursorPos(1, 4)
		for i = 1, height do
			local message = log[height - i]
			if message then
				print(" " .. message)
			end
		end
	end

	local onMessage = function(message)
		table.insert(log, 1, message)
		if index == currentTab then
			draw()
		end
	end

	local onEvent = function(...)
		local event = {...}

		if currentTab == index then
			if event[1] == "mouse_click" then
				local clicked = nil
				for i, button in pairs(buttons) do
					if event[3] >= button.startX and event[3] <= button.endX and event[4] == button.y then
						button.action()
					end
				end
			end

			draw()
		end

		return false
	end

	clear(theme.background, theme.text)
	term.setCursorPos(1, 2)
	draw()

	backend(domain, onEvent, onMessage)
end



--    Tab Interface


local newServerInterface = function()
	clear(theme.background, theme.text)

	term.setCursorPos(4, 3)
	term.write("Domain name: rdnt://")

	local domain = modifiedRead()

	term.setCursorPos(1, 5)
	if not isValidDomain(domain) then
		print("   Invalid domain name!")
		print("")
		print("   Domain names must be 3 - 30 letters")
		print("   and only contain a to z, 0 to 9, -, ., and _")
	else
		print("   Server created successfully!")

		newServer(domain)
	end

	sleep(2)
end


local serverSelectionInterface = function()
	local servers = listServers()
	table.insert(servers, 1, "New Server")

	local startY = 1
	local height = h - startY - 1
	local scroll = 0

	local draw = function()
		fill(1, startY, w, height + 1, theme.background)

		for i = scroll + 1, scroll + height do
			if servers[i] then
				term.setCursorPos(3, (i - scroll) + startY)

				if servers[i]:find("rdnt://") then
					term.setTextColor(theme.errorText)
					term.write("x ")
					term.setTextColor(theme.text)
				else
					term.write("  ")
				end

				term.write(servers[i])
			end
		end
	end

	draw()

	while true do
		local event, but, x, y = os.pullEvent()

		if event == "mouse_click" and y >= startY and y <= startY + height then
			local item = servers[y - startY + scroll]
			if item then
				item = item:gsub("rdnt://", "")
				if x == 3 then
					deleteServer(item)
					servers = listServers()
					table.insert(servers, 1, "New Server")
					draw()
				elseif x > 3 then
					if item == "New Server" then
						newServerInterface()
						servers = listServers()
						table.insert(servers, 1, "New Server")
						draw()
					else
						return item
					end
				end
			end
		elseif event == "key" then
			if but == keys.up then
				scroll = math.max(0, scroll - 1)
			elseif but == keys.down and #servers > height then
				scroll = math.min(scroll + 1, #servers - height)
			end

			draw()
		end
	end
end


local tabInterface = function(index, startDomain)
	if startDomain then
		tabs[index].domain = startDomain
		hostInterface(index, startDomain)
	end

	while true do
		local domain = serverSelectionInterface(index)

		tabs[index].domain = domain
		os.queueEvent(updateMenubarEvent)

		hostInterface(index, domain)
	end
end



--    Tabs


local switchTab = function(index, shouldntResume)
	if not tabs[index] then
		return
	end

	if tabs[currentTab].win then
		tabs[currentTab].win.setVisible(false)
	end

	currentTab = index

	term.redirect(term.native())
	clear(theme.background, theme.text)
	drawMenubar()

	for _, tab in pairs(tabs) do
		tab.win.setVisible(false)
	end

	term.redirect(tabs[index].win)
	term.setCursorPos(1, 1)
	tabs[index].win.setVisible(true)
	tabs[index].win.redraw()

	if not shouldntResume then
		term.redirect()
		term.setCursorPos(tabs[index].ox, tabs[index].oy)

		coroutine.resume(tabs[index].thread, tabSwitchEvent, index)

		local ox, oy = term.getCursorPos()
		tabs[index].ox = ox
		tabs[index].oy = oy
	end
end


local closeCurrentTab = function()
	if #tabs <= 0 then
		return
	end

	table.remove(tabs, currentTab)

	currentTab = math.max(currentTab - 1, 1)
	switchTab(currentTab, true)
end


local loadTab = function(index, domain)
	tabs[index] = {}
	tabs[index].domain = domain and domain or "Server Listing"
	tabs[index].win = window.create(term.native(), 1, 3, w, h - 2, false)
	tabs[index].thread = coroutine.create(function()
		local _, err = pcall(function()
			tabInterface(index, domain)
		end)

		if err then
			os.queueEvent(triggerErrorEvent, err)
		end
	end)

	tabs[index].ox = 1
	tabs[index].oy = 1

	switchTab(index)
end



--    Interface


local handleMouseClick = function(event, but, x, y)
	if y == 1 then
		if x == w then
			error()
		end

		return true
	elseif y == 2 then
		local index = determineClickedTab(x, y)
		if index == "new" and #tabs < maxTabs then
			loadTab(#tabs + 1)
		elseif index == "close" then
			closeCurrentTab()
		elseif index then
			switchTab(index)
		end

		return true
	end

	return false
end


local handleEvents = function()
	local loadedTab = false

	if #args > 0 then
		for _, domain in pairs(args) do
			if isValidDomain(domain) and serverExists(domain) then
				loadTab(#tabs + 1, domain)
				loadedTab = true
			end
		end
	end

	if not loadedTab then
		loadTab(1)
	end

	while true do
		drawMenubar()
		local event = {os.pullEvent()}
		drawMenubar()

		local cancelEvent = false
		if event[1] == "mouse_click" then
			cancelEvent = handleMouseClick(unpack(event))
		elseif event[1] == triggerErrorEvent then
			error(event[2])
		end

		if not cancelEvent then
			term.redirect(tabs[currentTab].win)
			term.setCursorPos(tabs[currentTab].ox, tabs[currentTab].oy)

			if event[1] == "mouse_click" then
				event[4] = event[4] - 2
			end

			coroutine.resume(tabs[currentTab].thread, unpack(event))

			local ox, oy = term.getCursorPos()
			tabs[currentTab].ox = ox
			tabs[currentTab].oy = oy

			local allowedEvents = {
				["rednet_message"] = true,
				["modem_message"] = true,
				["timer"] = true,
			}

			if allowedEvents[event[1]] then
				for i, tab in pairs(tabs) do
					if i ~= currentTab then
						term.setCursorPos(tab.ox, tab.oy)
						coroutine.resume(tab.thread, unpack(event))

						local ox, oy = term.getCursorPos()
						tabs[i].ox = ox
						tabs[i].oy = oy
					end
				end
			end
		end
	end
end



--    Main


local main = function()
	if term.isColor() then
		theme = colorTheme
	else
		theme = grayscaleTheme
	end

	setupModem()
	setupMenubar()
	fs.makeDir(serversFolder)

	handleEvents()
end


local handleError = function(err)
	clear(theme.background, theme.text)

	fill(1, 3, w, 3, theme.subtle)
	term.setCursorPos(1, 4)
	center("Firewolf Server has crashed!")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 8)
	centerSplit(err, w - 4)
	print("\n")
	center("Please report this error to")
	center("GravityScore or 1lann.")
	print("")
	center("Press any key to exit.")

	os.pullEvent("key")
	os.queueEvent("")
	os.pullEvent()
end


local originalDir = shell.dir()
local originalTerminal = term.current()
local _, err = pcall(main)
term.redirect(originalTerminal)
shell.setDir(originalDir)

if err and not err:lower():find("terminate") then
	handleError(err)
end

if modem then
	for _, side in pairs(sides) do
		if peripheral.getType(side) == "modem" then
			rednet.close(side)
		end
	end
	modem("closeAll")
end


clear(colors.black, colors.white)
center("Thanks for using Firewolf Server " .. version)
center("Made by GravityScore and 1lann")
print("")
