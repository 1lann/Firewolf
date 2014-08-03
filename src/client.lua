
--
--  Firewolf
--  Made by GravityScore and 1lann
--



--    Variables


local version = "3.0"
local build = 3

local w, h = term.getSize()

local isMenubarOpen = true
local menubarWindow = nil

local allowUnencryptedConnections = true
local enableTabBar = true

local currentWebsiteURL = ""
local builtInSites = {}

local currentProtocol = ""
local protocols = {}

local currentTab = 1
local maxTabs = 5
local maxTabNameWidth = 8
local tabs = {}

local languages = {}

local history = {}

local sides = {}
local publicDNSChannel = 9999
local publicResponseChannel = 9998
local responseID = 41738

local httpTimeout = 10
local searchResultTimeout = 0.5
local initiationTimeout = 0.2
local animationInterval = 0.125
local fetchTimeout = 1
local serverLimitPerComputer = 3

local listToken = "--@!FIREWOLF-LIST!@--"
local initiateToken = "--@!FIREWOLF-INITIATE!@--"
local fetchToken = "--@!FIREWOLF-FETCH!@--"
local disconnectToken = "--@!FIREWOLF-DISCONNECT!@--"
local protocolToken = "--@!FIREWOLF-REDNET-PROTOCOL!@--"

local connectToken = "^%-%-@!FIREWOLF%-CONNECT!@%-%-(.+)"
local DNSToken = "^%-%-@!FIREWOLF%-DNSRESP!@%-%-(.+)"
local receiveToken = "^%-%-@!FIREWOLF%-HEAD!@%-%-(.+)%-%-@!FIREWOLF%-BODY!@%-%-(.+)$"

local websiteErrorEvent = "firewolf_websiteErrorEvent"
local redirectEvent = "firewolf_redirectEvent"

local baseURL = "https://raw.githubusercontent.com/1lann/Firewolf/master/src"
local buildURL = baseURL .. "/build.txt"
local firewolfURL = baseURL .. "/client.lua"
local serverURL = baseURL .. "/server.lua"

local firewolfLocation = "/" .. shell.getRunningProgram()


local theme = {}

local colorTheme = {
	background = colors.gray,
	accent = colors.red,
	subtle = colors.orange,

	lightText = colors.gray,
	text = colors.white,
	errorText = colors.red,
}

local grayscaleTheme = {
	background = colors.black,
	accent = colors.black,
	subtle = colors.black,

	lightText = colors.white,
	text = colors.white,
	errorText = colors.white,
}



--    Utilities


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

	if readHistory[1] == text then
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


local prompt = function(items, x, y, w, h)
	local selected = 1
	local scroll = 0

	local draw = function()
		for i = scroll + 1, scroll + h do
			local item = items[i]
			if item then
				term.setCursorPos(x, y + i - 1)
				term.setBackgroundColor(theme.background)
				term.setTextColor(theme.lightText)

				if scroll + selected == i then
					term.setTextColor(theme.text)
					term.write(" > ")
				else
					term.write(" - ")
				end

				term.write(item)
			end
		end
	end

	draw()
	while true do
		local event, key, x, y = os.pullEvent()

		if event == "key" then
			if key == keys.up and selected > 1 then
				selected = selected - 1

				if selected - scroll == 0 then
					scroll = scroll - 1
				end
			elseif key == keys.down and selected < #items then
				selected = selected + 1
			end

			draw()
		elseif event == "mouse_click" then

		elseif event == "mouse_scroll" then
			if key > 0 then
				os.queueEvent("key", keys.down)
			else
				os.queueEvent("key", keys.up)
			end
		end
	end
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



--    Updating


local download = function(url)
	local timeoutID = os.startTimer(httpTimeout)
	while true do
		local event, fetchedURL, response = os.pullEvent()
		if (event == "timer" and fetchedURL == timeoutID) or event == "http_failure" then
			return false
		elseif event == "http_success" and fetchedURL == url then
			local contents = response.readAll()
			response.close()
			return contents
		end
	end
end


local downloadAndSave = function(url, path)
	local contents = download(url)
	if contents and not fs.isReadOnly(path) and not fs.isDir(path) then
		local f = io.open(path, "w")
		f:write(contents)
		f:close()
		return false
	end
	return true
end


local updateAvailable = function()
	local number = download(buildURL)
	if not number then
		return false, true
	end

	if number and tonumber(number) and tonumber(number) > build then
		return true, false
	end

	return false, false
end


local redownloadBrowser = function()
	return downloadAndSave(firewolfURL, firewolfLocation)
end



--    Display Websites


builtInSites["display"] = {}


builtInSites["display"]["firewolf"] = function()
	local logo = {
		"______                         _  __ ",
		"|  ___|                       | |/ _|",
		"| |_  _ ____ _____      _____ | | |_ ",
		"|  _|| |  __/ _ \\ \\ /\\ / / _ \\| |  _|",
		"| |  | | | |  __/\\ V  V / <_> | | |  ",
		"\\_|  |_|_|  \\___| \\_/\\_/ \\___/|_|_|  ",
	}

	clear(theme.background, theme.text)
	fill(1, 3, w, 9, theme.subtle)

	term.setCursorPos(1, 3)
	for _, line in pairs(logo) do
		center(line)
	end

	term.setCursorPos(1, 10)
	center(version)

	term.setBackgroundColor(theme.background)
	term.setTextColor(theme.text)
	term.setCursorPos(1, 14)
	center("Search using the Query Box above")
	center("Visit rdnt://help for help using Firewolf.")

	term.setCursorPos(1, h - 2)
	center("Made by GravityScore and 1lann")
end


builtInSites["display"]["credits"] = function()
	clear(theme.background, theme.text)

	fill(1, 6, w, 3, theme.subtle)
	term.setCursorPos(1, 7)
	center("Credits")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 11)
	center("Written by GravityScore and 1lann")
	print("")
	center("RC4 Implementation by AgentE382")
end


builtInSites["display"]["help"] = function()
	clear(theme.background, theme.text)

	fill(1, 3, w, 3, theme.subtle)
	term.setCursorPos(1, 4)
	center("Help")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 7)
	center("Click on the URL bar or press control to")
	center("open the query box")
	print("")
	center("Type in a search query or website URL")
	center("into the query box.")
	print("")
	center("Search for nothing to see all available")
	center("websites.")
	print("")
	center("Visit rdnt://server to setup a server.")
	center("Visit rdnt://update to update Firewolf.")
end


builtInSites["display"]["server"] = function()
	clear(theme.background, theme.text)

	fill(1, 6, w, 3, theme.subtle)
	term.setCursorPos(1, 7)
	center("Server Software")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 11)
	if not http then
		center("HTTP is not enabled!")
		print("")
		center("Please enable it in your config file")
		center("to download Firewolf Server.")
	else
		center("Press space to download")
		center("Firewolf Server to:")
		print("")
		center("/fwserver")

		while true do
			local event, key = os.pullEvent()
			if event == "key" and key == 57 then
				fill(1, 11, w, 4, theme.background)
				term.setCursorPos(1, 11)
				center("Downloading...")

				local err = downloadAndSave("http://pastebin.com/raw.php?i=hi4xFVxn", "/fwserver")

				fill(1, 11, w, 4, theme.background)
				term.setCursorPos(1, 11)
				center(err and "Download failed!" or "Download successful!")
			end
		end
	end
end


builtInSites["display"]["update"] = function()
	clear(theme.background, theme.text)

	fill(1, 3, w, 3, theme.subtle)
	term.setCursorPos(1, 4)
	center("Update")

	term.setBackgroundColor(theme.background)
	if not http then
		term.setCursorPos(1, 9)
		center("HTTP is not enabled!")
		print("")
		center("Please enable it in your config")
		center("file to download Firewolf updates.")
	else
		term.setCursorPos(1, 10)
		center("Checking for updates...")

		local available, err = updateAvailable()

		term.setCursorPos(1, 10)
		if available then
			term.clearLine()
			center("Update found!")
			center("Press enter to download.")

			while true do
				local event, key = os.pullEvent()
				if event == "key" and key == keys.enter then
					break
				end
			end

			fill(1, 10, w, 2, theme.background)
			term.setCursorPos(1, 10)
			center("Downloading...")

			local err = redownloadBrowser()

			term.setCursorPos(1, 10)
			term.clearLine()
			if err then
				center("Download failed!")
			else
				center("Download succeeded!")
				center("Please restart Firewolf...")
			end
		elseif err then
			term.clearLine()
			center("Checking failed!")
		else
			term.clearLine()
			center("No updates found.")
		end
	end
end



--    Built In Websites


builtInSites["error"] = function(err)
	fill(1, 3, w, 3, theme.subtle)
	term.setCursorPos(1, 4)
	center("Failed to load page!")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 9)
	center(err)
	print("")
	center("Please try again.")
end


builtInSites["noresults"] = function()
	fill(1, 3, w, 3, theme.subtle)
	term.setCursorPos(1, 4)
	center("No results!")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 9)
	center("Your search didn't return")
	center("any results!")

	os.pullEvent("key")
	os.queueEvent("")
	os.pullEvent()
end


builtInSites["search advanced"] = function(results)
	local startY = 6
	local height = h - startY - 1
	local scroll = 0

	local draw = function()
		fill(1, startY, w, height + 1, theme.background)

		for i = scroll + 1, scroll + height do
			if results[i] then
				term.setCursorPos(5, (i - scroll) + startY)
				term.write(currentProtocol .. "://" .. results[i])
			end
		end
	end

	draw()
	while true do
		local event, but, x, y = os.pullEvent()

		if event == "mouse_click" and y >= startY and y <= startY + height then
			local item = results[y - startY + scroll]
			if item then
				os.queueEvent(redirectEvent, item)
				coroutine.yield()
			end
		elseif event == "key" then
			if but == keys.up then
				scroll = math.max(0, scroll - 1)
			elseif but == keys.down and #results > height then
				scroll = math.min(scroll + 1, #results - height)
			end

			draw()
		end
	end
end


builtInSites["search basic"] = function(results)
	local startY = 6
	local height = h - startY - 1
	local scroll = 0
	local selected = 1

	local draw = function()
		fill(1, startY, w, height + 1, theme.background)

		for i = scroll + 1, scroll + height do
			if results[i] then
				if i == selected + scroll then
					term.setCursorPos(3, (i - scroll) + startY)
					term.write("> " .. currentProtocol .. "://" .. results[i])
				else
					term.setCursorPos(5, (i - scroll) + startY)
					term.write(currentProtocol .. "://" .. results[i])
				end
			end
		end
	end

	draw()
	while true do
		local event, but, x, y = os.pullEvent()

		if event == "key" then
			if but == keys.up and selected + scroll > 1 then
				if selected > 1 then
					selected = selected - 1
				else
					scroll = math.max(0, scroll - 1)
				end
			elseif but == keys.down and selected + scroll < #results then
				if selected < height then
					selected = selected + 1
				else
					scroll = math.min(scroll + 1, #results - height)
				end
			elseif but == keys.enter then
				local item = results[scroll + selected]
				if item then
					os.queueEvent(redirectEvent, item)
					coroutine.yield()
				end
			end

			draw()
		end
	end
end


builtInSites["search"] = function(results)
	clear(theme.background, theme.text)

	fill(1, 3, w, 3, theme.subtle)
	term.setCursorPos(1, 4)
	center(#results .. " Search " .. (#results == 1 and "Result" or "Results"))

	term.setBackgroundColor(theme.background)

	if term.isColor() then
		builtInSites["search advanced"](results)
	else
		builtInSites["search basic"](results)
	end
end


builtInSites["crash"] = function(err)
	fill(1, 3, w, 3, theme.subtle)
	term.setCursorPos(1, 4)
	center("The website crashed!")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 8)
	centerSplit(err, w - 4)
	print("\n")
	center("Please report this error to")
	center("the website creator.")
end



--    Menubar


local getTabName = function(url)
	local name = url:match("^[^/]+")

	if not name then
		name = "Search"
	end

	if name:sub(1, 3) == "www" then
		name = name:sub(5):gsub("^%s*(.-)%s*$", "%1")
	end

	if name:len() > maxTabNameWidth then
		name = name:sub(1, maxTabNameWidth):gsub("^%s*(.-)%s*$", "%1")
	end

	if name:sub(-1, -1) == "." then
		name = name:sub(1, -2):gsub("^%s*(.-)%s*$", "%1")
	end

	return name:gsub("^%s*(.-)%s*$", "%1")
end


local determineClickedTab = function(x, y)
	if y == 2 then
		local minx = 2
		for i, tab in pairs(tabs) do
			local name = getTabName(tab.url)

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
	if enableTabBar then
		menubarWindow = window.create(term.native(), 1, 1, w, 2, false)
	else
		menubarWindow = window.create(term.native(), 1, 1, w, 1, false)
	end
end


local drawMenubar = function()
	if isMenubarOpen then
		term.redirect(menubarWindow)
		menubarWindow.setVisible(true)

		fill(1, 1, w, 1, theme.accent)
		term.setTextColor(theme.text)

		term.setBackgroundColor(theme.accent)
		term.setCursorPos(2, 1)
		term.write(currentProtocol .. "://" .. currentWebsiteURL)

		term.setCursorPos(w - 5, 1)
		term.write("[===]")

		if enableTabBar then
			fill(1, 2, w, 1, theme.subtle)

			term.setCursorPos(1, 2)
			for i, tab in pairs(tabs) do
				term.setBackgroundColor(theme.subtle)
				term.setTextColor(theme.lightText)
				if i == currentTab then
					term.setTextColor(theme.text)
				end

				local tabName = getTabName(tab.url)
				term.write(" " .. tabName)

				if i == currentTab and #tabs > 1 then
					term.setTextColor(theme.errorText)
					term.write("x")
				else
					term.write(" ")
				end
			end

			if #tabs < maxTabs then
				term.setTextColor(theme.lightText)
				term.setBackgroundColor(theme.subtle)
				term.write(" + ")
			end
		end
	else
		menubarWindow.setVisible(false)
	end
end



--    RDNT Protocol


protocols["rdnt"] = {}


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


protocols["rdnt"]["setup"] = function()
	for _, v in pairs(redstone.getSides()) do
		if peripheral.getType(v) == "modem" then
			table.insert(sides, v)
		end
	end

	if #sides <= 0 then
		error("No modem found!")
	end
end


protocols["rdnt"]["modem"] = function(func, ...)
	for _, side in pairs(sides) do
		if peripheral.getType(side) == "modem" then
			peripheral.call(side, func, ...)
		end
	end

	return true
end


protocols["rdnt"]["fetchAllSearchResults"] = function()
	local results = {}
	local toDelete = {}

	local checkResults = function(distance)
		local repeatedResults = {}
		for k, result in pairs(results) do
			if result == distance then
				if not repeatedResults[tostring(result)] then
					repeatedResults[tostring(result)] = 1
				elseif repeatedResults[tostring(result)] >= serverLimitPerComputer - 1 then
					table.insert(toDelete, result)
					return false
				else
					repeatedResults[tostring(result)] = repeatedResults[tostring(result)] + 1
				end
			end
		end

		return true
	end

	protocols.rdnt.modem("open", publicResponseChannel)
	protocols.rdnt.modem("open", publicDNSChannel)

	if allowUnencryptedConnections then
		for _, side in pairs(sides) do
			if peripheral.getType(side) == "modem" then
				rednet.open(side)
			end
		end

		rednet.broadcast(listToken, listToken)
	end

	protocols.rdnt.modem("transmit", publicDNSChannel, responseID, listToken)
	protocols.rdnt.modem("close", publicDNSChannel)

	local timer = os.startTimer(searchResultTimeout)
	while true do
		local event, connectionSide, channel, verify, msg, distance = os.pullEvent()

		if event == "modem_message" and channel == publicResponseChannel and verify == responseID then
			if msg:match(DNSToken) and #msg:match(DNSToken) >= 4 and #msg:match(DNSToken) <= 30 then
				if checkResults(distance) then
					results[msg:match(DNSToken)] = distance
				end
			end
		elseif event == "rednet_message" and verify == listToken and allowUnencryptedConnections then
			if channel:match(DNSToken) and #channel:match(DNSToken) >= 4 and #channel:match(DNSToken) <= 30 then
				results[channel:match(DNSToken)] = -1
			end
		elseif event == "timer" and connectionSide == timer then
			local finalResult = {}
			for k, v in pairs(results) do
				local shouldDelete = false
				for b, n in pairs(toDelete) do
					if v > 0 and tostring(n) == tostring(v) then
						shouldDelete = true
					end
				end

				if not shouldDelete then
					table.insert(finalResult, k:lower())
				end
			end

			if allowUnencryptedConnections then
				for _, side in pairs(sides) do
					if peripheral.getType(side) == "modem" then
						rednet.close(side)
					end
				end
			end

			protocols.rdnt.modem("close", publicResponseChannel)

			return finalResult
		end
	end
end


protocols["rdnt"]["fetchConnectionObject"] = function(url)
	local channel = calculateChannel(url)
	local results = {}
	local unencryptedResults = {}

	local checkDuplicate = function(distance)
		for k, v in pairs(results) do
			if v.dist == distance then
				return true
			end
		end

		return false
	end

	local checkRednetDuplicate = function(id)
		for k, v in pairs(unencryptedResults) do
			if v.id == id then
				return true
			end
		end

		return false
	end

	protocols.rdnt.modem("closeAll")
	protocols.rdnt.modem("open", channel)
	protocols.rdnt.modem("transmit", channel, os.getComputerID(), initiateToken .. url)

	local timer = os.startTimer(initiationTimeout)
	while true do
		local event, connectionSide, connectionChannel, verify, msg, distance = os.pullEvent()

		if event == "modem_message" and connectionChannel == channel and verify == responseID then
			local decrypt = crypt(textutils.unserialize(msg), url .. tostring(distance) .. os.getComputerID())
			if decrypt and decrypt:match(connectToken) == url and
					not checkDuplicate(distance) then
				local calculatedChannel = calculateChannel(url, distance, os.getComputerID())

				table.insert(results, {
					dist = distance,
					channel = calculatedChannel,
					url = url,
					wired = peripheral.call(connectionSide, "isWireless"),
					encrypted = true,

					fetchPage = function(page)
						protocols.rdnt.modem("open", calculatedChannel)

						local fetchTimer = os.startTimer(fetchTimeout)
						protocols.rdnt.modem("transmit", calculatedChannel, os.getComputerID(), crypt(fetchToken .. url .. page, url .. tostring(distance) .. os.getComputerID()))

						while true do
							local event, fetchSide, fetchChannel, fetchVerify, fetchMessage, fetchDistance = os.pullEvent()

							if event == "modem_message" and fetchChannel == calculatedChannel and
									fetchVerify == responseID and fetchDistance == distance then
								local rawHeader, data = crypt(textutils.unserialize(fetchMessage), url .. tostring(fetchDistance) .. os.getComputerID()):match(receiveToken)
								local header = textutils.unserialize(rawHeader)

								if data and header then
									protocols.rdnt.modem("close", calculatedChannel)
									return data, header
								end
							elseif event == "timer" and fetchSide == fetchTimer then
								protocols.rdnt.modem("close", calculatedChannel)
								return nil
							end
						end
					end,

					close = function()
						protocols.rdnt.modem("open", calculatedChannel)
						protocols.rdnt.modem("transmit", calculatedChannel, os.getComputerID(), crypt(disconnectToken, url .. tostring(distance) .. os.getComputerID()))
						protocols.rdnt.modem("close", calculatedChannel)
					end
				})
			end
		elseif event == "timer" and connectionSide == timer then
			protocols.rdnt.modem("close", channel)

			if #results == 0 then
				break
			elseif #results == 1 then
				return results[1]
			else
				local wiredResults = {}
				for k, v in pairs(results) do
					if v.wired then
						table.insert(wiredResults, v)
					end
				end
				if #wiredResults == 0 then
					local finalResult = {multipleServers = true, servers = results}
					return finalResult
				elseif #wiredResults == 1 then
					return wiredResults[1]
				else
					local finalResult = {multipleServers = true, servers = wiredResults}
					return finalResult
				end
			end
		end
	end

	if allowUnencryptedConnections then
		for _, side in pairs(sides) do
			if peripheral.getType(side) == "modem" then
				rednet.open(side)
			end
		end

		local ret = {rednet.lookup(protocolToken .. url)}

		for _, v in pairs(ret) do
			table.insert(unencryptedResults, {
				dist = v,
				channel = -1,
				url = url,
				encrypted = false,
				wired = false,
				id = v,

				fetchPage = function(page)
					for _, side in pairs(sides) do
						if peripheral.getType(side) == "modem" then
							rednet.open(side)
						end
					end

					local fetchTimer = os.startTimer(fetchTimeout)
					rednet.send(v, crypt(fetchToken .. url .. page, url .. tostring(os.getComputerID())), protocolToken .. url)

					while true do
						local event, fetchId, fetchMessage, fetchProtocol = os.pullEvent()
						if event == "rednet_message" and fetchId == v and fetchProtocol == (protocolToken .. url) then
							local decrypt = crypt(textutils.unserialize(fetchMessage), url .. tostring(os.getComputerID()))
							if decrypt then
								local rawHeader, data = decrypt:match(receiveToken)
								local header = textutils.unserialize(rawHeader)
								if data and header then
									for _, side in pairs(sides) do
										if peripheral.getType(side) == "modem" then
											rednet.close(side)
										end
									end

									return data, header
								end
							end
						elseif event == "timer" and fetchId == fetchTimer then
							for _, side in pairs(sides) do
								if peripheral.getType(side) == "modem" then
									rednet.close(side)
								end
							end

							return nil
						end
					end
				end,

				close = function()
					for _, side in pairs(sides) do
						if peripheral.getType(side) == "modem" then
							rednet.open(side)
						end
					end

					rednet.send(v, crypt(disconnectToken, url .. tostring(os.getComputerID())), protocolToken .. url)

					for _, side in pairs(sides) do
						if peripheral.getType(side) == "modem" then
							rednet.close(side)
						end
					end
				end
			})
		end
		if #unencryptedResults == 0 then
			return nil
		elseif #unencryptedResults == 1 then
			return unencryptedResults[1]
		else
			local finalResult = {multipleServers = true, servers = unencryptedResults}
			return finalResult
		end
	end

	return nil
end



--    Fetching Raw Data


local fetchSearchResultsForQuery = function(query)
	local all = protocols[currentProtocol]["fetchAllSearchResults"]()
	local results = {}
	if query and query:len() > 0 then
		for _, v in pairs(all) do
			if v:find(query:lower()) then
				table.insert(results, v)
			end
		end
	else
		results = all
	end

	table.sort(results)
	return results
end


local getConnectionObjectFromURL = function(url)
	local domain = url:match("^([^/]+)")
	return protocols[currentProtocol]["fetchConnectionObject"](domain)
end


local determineLanguage = function(header)
	if type(header) == "table" then
		if header.language and header.language == "Firewolf Markup" then
			return "fwml"
		else
			return "lua"
		end
	else
		return "lua"
	end
end



--    History


local appendToHistory = function(url)
	if history[1] ~= url then
		table.insert(history, 1, url)
	end
end



--    Fetch Websites


local loadingAnimation = function()
	local state = -2

	term.setTextColor(theme.text)
	term.setBackgroundColor(theme.accent)

	term.setCursorPos(w - 5, 1)
	term.write("[=  ]")

	local timer = os.startTimer(animationInterval)

	while true do
		local event, timerID = os.pullEvent()
		if event == "timer" and timerID == timer then
			term.setTextColor(theme.text)
			term.setBackgroundColor(theme.accent)

			state = state + 1

			term.setCursorPos(w - 5, 1)
			term.write("[   ]")
			term.setCursorPos(w - 2 - math.abs(state), 1)
			term.write("=")

			if state == 2 then
				state = -2
			end

			timer = os.startTimer(animationInterval)
		end
	end
end


local normalizeURL = function(url)
	url = url:lower():gsub(" ", "")
	if url == "home" or url == "homepage" then
		url = "firewolf"
	end

	return url
end


local normalizePage = function(page)
	page = page:lower()
	if page == "" then
		page = "/"
	end
	return page
end


local determineActionForURL = function(url)
	if url:len() > 0 and url:gsub("/", ""):len() == 0 then
		return "none"
	end

	if url == "exit" then
		return "exit"
	elseif builtInSites["display"][url] then
		return "internal website"
	elseif url == "" then
		local results = fetchSearchResultsForQuery()
		if #results > 0 then
			return "search", results
		else
			return "none"
		end
	else
		local connection = getConnectionObjectFromURL(url)
		if connection then
			return "external website", connection
		else
			local results = fetchSearchResultsForQuery(url)
			if #results > 0 then
				return "search", results
			else
				return "none"
			end
		end
	end
end


local fetchSearch = function(url, results)
	return languages["lua"]["runWithoutAntivirus"](builtInSites["search"], results)
end


local fetchInternal = function(url)
	return languages["lua"]["runWithoutAntivirus"](builtInSites["display"][url])
end


local fetchError = function(err)
	return languages["lua"]["runWithoutAntivirus"](builtInSites["error"], err)
end


local fetchExternal = function(url, connection)

	if connection.multipleServers then
		-- Please forgive me
		-- GravityScore forced me to do it like this
		-- I don't mean it, I really don't.
		connection = connection.servers[1]
	end

	local page = normalizePage(url:match("^[^/]+(.+)"))
	local contents, header = connection.fetchPage(page)
	connection.close()
	if contents then
		if type(contents) ~= "string" then
			return fetchNone()
		else
			local language = determineLanguage(header)
			return languages[language]["run"](contents, page)
		end
	else
		return fetchError("A connection timeout occurred!")
	end
end


local fetchNone = function()
	return languages["lua"]["runWithoutAntivirus"](builtInSites["noresults"])
end


local fetchURL = function(url)
	url = normalizeURL(url)
	currentWebsiteURL = url

	local action, connection = determineActionForURL(url)

	if action == "search" then
		return fetchSearch(url, connection), true
	elseif action == "internal website" then
		return fetchInternal(url), true
	elseif action == "external website" then
		return fetchExternal(url, connection), false
	elseif action == "none" then
		return fetchNone(), true
	elseif action == "exit" then
		os.queueEvent("terminate")
	end

	return nil
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
	isMenubarOpen = tabs[currentTab].isMenubarOpen
	currentWebsiteURL = tabs[currentTab].url

	term.redirect(term.native())
	clear(theme.background, theme.text)
	drawMenubar()

	term.redirect(tabs[currentTab].win)
	term.setCursorPos(1, 1)
	tabs[currentTab].win.setVisible(true)
	tabs[currentTab].win.redraw()

	if not shouldntResume then
		coroutine.resume(tabs[currentTab].thread)
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


local loadTab = function(index, url, givenFunc)
	url = normalizeURL(url)

	local func = nil
	local isOpen = true

	isMenubarOpen = true
	currentWebsiteURL = url
	drawMenubar()

	if givenFunc then
		func = givenFunc
	else
		parallel.waitForAny(function()
			func, isOpen = fetchURL(url)
		end, function()
			while true do
				local event, key = os.pullEvent()
				if event == "key" and (key == 29 or key == 157) then
					break
				end
			end
		end, loadingAnimation)
	end

	if func then
		appendToHistory(url)

		tabs[index] = {}
		tabs[index].url = url
		tabs[index].win = window.create(term.native(), 1, 1, w, h, false)

		tabs[index].thread = coroutine.create(func)
		tabs[index].isMenubarOpen = isOpen
		tabs[index].isMenubarPermanent = isOpen

		tabs[index].ox = 1
		tabs[index].oy = 1

		term.redirect(tabs[index].win)
		clear(theme.background, theme.text)

		switchTab(index)
	end
end



--    Website Environments


local getWhitelistedEnvironment = function()
	local env = {}

	local function copy(source, destination, key)
		destination[key] = {}
		for k, v in pairs(source) do
			destination[key][k] = v
		end
	end

	copy(bit, env, "bit")
	copy(colors, env, "colors")
	copy(colours, env, "colours")
	copy(coroutine, env, "coroutine")

	copy(disk, env, "disk")
	env["disk"]["setLabel"] = nil
	env["disk"]["eject"] = nil

	copy(gps, env, "gps")
	copy(help, env, "help")
	copy(keys, env, "keys")
	copy(math, env, "math")

	copy(os, env, "os")
	env["os"]["run"] = nil
	env["os"]["shutdown"] = nil
	env["os"]["reboot"] = nil
	env["os"]["setComputerLabel"] = nil
	env["os"]["queueEvent"] = nil
	env["os"]["pullEventRaw"] = os.pullEvent

	copy(paintutils, env, "paintutils")
	copy(parallel, env, "parallel")
	copy(peripheral, env, "peripheral")
	copy(rednet, env, "rednet")
	copy(redstone, env, "redstone")
	copy(redstone, env, "rs")

	copy(shell, env, "shell")
	env["shell"]["run"] = nil
	env["shell"]["exit"] = nil
	env["shell"]["setDir"] = nil
	env["shell"]["setAlias"] = nil
	env["shell"]["clearAlias"] = nil
	env["shell"]["setPath"] = nil

	copy(string, env, "string")
	copy(table, env, "table")

	copy(term, env, "term")
	env["term"]["redirect"] = nil
	env["term"]["restore"] = nil

	copy(textutils, env, "textutils")
	copy(vector, env, "vector")

	if turtle then
		copy(turtle, env, "turtle")
	end

	if http then
		copy(http, env, "http")
	end

	env["assert"] = assert
	env["printError"] = printError
	env["tonumber"] = tonumber
	env["tostring"] = tostring
	env["type"] = type
	env["next"] = next
	env["unpack"] = unpack
	env["pcall"] = pcall
	env["xpcall"] = xpcall
	env["sleep"] = sleep
	env["pairs"] = pairs
	env["ipairs"] = ipairs
	env["read"] = read
	env["write"] = write
	env["select"] = select
	env["print"] = print
	env["setmetatable"] = setmetatable
	env["getmetatable"] = getmetatable

	env["_G"] = env
	return env
end


local overrideEnvironment = function(env)
	local localTerm = {}
	for k, v in pairs(term) do
		localTerm[k] = v
	end

	env["term"]["clear"] = function()
		localTerm.clear()
		drawMenubar()
	end

	env["term"]["scroll"] = function(n)
		localTerm.scroll(n)
		drawMenubar()
	end


	env["shell"]["getRunningProgram"] = function()
		return currentWebsiteURL
	end
end


local applyAPIFunctions = function(env)
	env["firewolf"] = {}
	env["firewolf"]["version"] = version

	env["firewolf"]["redirect"] = function(url)
		if not url then
			error("string expected, got nil", 2)
		end

		os.queueEvent(redirectEvent, url)
		coroutine.yield()
	end

	env["center"] = center
	env["fill"] = fill
end


local getWebsiteEnvironment = function(antivirus)
	local env = {}

	if antivirus then
		env = getWhitelistedEnvironment()
		overrideEnvironment(env)
	else
		setmetatable(env, {__index = _G})
	end

	applyAPIFunctions(env)

	return env
end



--    FWML Execution


local render = {}

render["functions"] = {}
render["functions"]["public"] = {}
render["alignations"] = {}

render["variables"] = {
	scroll,
	maxScroll,
	align,
	linkData = {},
	blockLength,
	link,
	linkStart,
	markers,
	currentOffset,
}


local function getLine(loc, data)
	local _, changes = data:sub(1, loc):gsub("\n", "")
	if not changes then
		return 1
	else
		return changes + 1
	end
end


local function parseData(data)
	local commands = {}
	local searchPos = 1

	while #data > 0 do
		local sCmd, eCmd = data:find("%[[^%]]+%]", searchPos)
		if sCmd then
			sCmd = sCmd + 1
			eCmd = eCmd - 1

			if (sCmd > 2) then
				if data:sub(sCmd - 2, sCmd - 2) == "\\" then
					local t = data:sub(searchPos, sCmd - 1):gsub("\n", ""):gsub("\\%[", "%["):gsub("\\%]", "%]")
					if #t > 0 then
						if #commands > 0 and type(commands[#commands][1]) == "string" then
							commands[#commands][1] = commands[#commands][1] .. t
						else
							table.insert(commands, {t})
						end
					end
					searchPos = sCmd
				else
					local t = data:sub(searchPos, sCmd - 2):gsub("\n", ""):gsub("\\%[", "%["):gsub("\\%]", "%]")
					if #t > 0 then
						if #commands > 0 and type(commands[#commands][1]) == "string" then
							commands[#commands][1] = commands[#commands][1] .. t
						else
							table.insert(commands, {t})
						end
					end

					t = data:sub(sCmd, eCmd):gsub("\n", "")
					table.insert(commands, {getLine(sCmd, data), t})
					searchPos = eCmd + 2
				end
			else
				local t = data:sub(sCmd, eCmd):gsub("\n", "")
				table.insert(commands, {getLine(sCmd, data), t})
				searchPos = eCmd + 2
			end
		else
			local t = data:sub(searchPos, -1):gsub("\n", ""):gsub("\\%[", "%["):gsub("\\%]", "%]")
			if #t > 0 then
				if #commands > 0 and type(commands[#commands][1]) == "string" then
					commands[#commands][1] = commands[#commands][1] .. t
				else
					table.insert(commands, {t})
				end
			end

			break
		end
	end

	return commands
end


local function proccessData(commands)
	searchIndex = 0

	while searchIndex < #commands do
		searchIndex = searchIndex + 1

		local length = 0
		local origin = searchIndex

		if type(commands[searchIndex][1]) == "string" then
			length = length + #commands[searchIndex][1]
			local endIndex = origin
			for i = origin + 1, #commands do
				if commands[i][2] then
					local command = commands[i][2]:match("^(%w+)%s-")
					if not (command == "c" or command == "color" or command == "bg"
							or command == "background" or command == "newlink" or command == "endlink") then
						endIndex = i
						break
					end
				elseif commands[i][2] then

				else
					length = length + #commands[i][1]
				end
				if i == #commands then
					endIndex = i
				end
			end

			commands[origin][2] = length
			searchIndex = endIndex
			length = 0
		end
	end

	return commands
end


local function parse(original)
	return proccessData(parseData(original))
end


render["functions"]["display"] = function(text, length, offset, center)
	if not offset then
		offset = 0
	end

	return render.variables.align(text, length, w, offset, center);
end


render["functions"]["displayText"] = function(source)
	if source[2] then
		render.variables.blockLength = source[2]
		if render.variables.link and not render.variables.linkStart then
			render.variables.linkStart = render.functions.display(
				source[1], render.variables.blockLength, render.variables.currentOffset, w / 2)
		else
			render.functions.display(source[1], render.variables.blockLength, render.variables.currentOffset, w / 2)
		end
	else
		if render.variables.link and not render.variables.linkStart then
			render.variables.linkStart = render.functions.display(source[1], nil, render.variables.currentOffset, w / 2)
		else
			render.functions.display(source[1], nil, render.variables.currentOffset, w / 2)
		end
	end
end


render["functions"]["public"]["br"] = function(source)
	if render.variables.link then
		return "Cannot insert new line within a link on line " .. source[1]
	end

	render.variables.scroll = render.variables.scroll + 1
	render.variables.maxScroll = math.max(render.variables.scroll, render.variables.maxScroll)
end


render["functions"]["public"]["c "] = function(source)
	local sColor = source[2]:match("^%w+%s+(.+)$") or ""
	if colors[sColor] then
		term.setTextColor(colors[sColor])
	else
		return "Invalid color: \"" .. sColor .. "\" on line " .. source[1]
	end
end


render["functions"]["public"]["color "] = render["functions"]["public"]["c "]


render["functions"]["public"]["bg "] = function(source)
	local sColor = source[2]:match("^%w+%s+(.+)$") or ""
	if colors[sColor] then
		term.setBackgroundColor(colors[sColor])
	else
		return "Invalid color: \"" .. sColor .. "\" on line " .. source[1]
	end
end


render["functions"]["public"]["background "] = render["functions"]["public"]["bg "]


render["functions"]["public"]["newlink "] = function(source)
	if render.variables.link then
		return "Cannot nest links on line " .. source[1]
	end

	render.variables.link = source[2]:match("^%w+%s+(.+)$") or ""
	render.variables.linkStart = false
end


render["functions"]["public"]["endlink"] = function(source)
	if not render.variables.link then
		return "Cannot end a link without a link on line " .. source[1]
	end

	local linkEnd = term.getCursorPos()-1
	table.insert(render.variables.linkData, {render.variables.linkStart,
		linkEnd, render.variables.scroll, render.variables.link})
	render.variables.link = false
	render.variables.linkStart = false
end


render["functions"]["public"]["offset "] = function(source)
	local offset = tonumber((source[2]:match("^%w+%s+(.+)$") or ""))
	if offset then
		render.variables.currentOffset = offset
	else
		return "Invalid offset value: \"" .. (source[2]:match("^%w+%s+(.+)$") or "") .. "\" on line " .. source[1]
	end
end


render["functions"]["public"]["marker "] = function(source)
	render.variables.markers[(source[2]:match("^%w+%s+(.+)$") or "")] = render.variables.scroll
end


render["functions"]["public"]["goto "] = function(source)
	local location = source[2]:match("%w+%s+(.+)$")
	if render.variables.markers[location] then
		render.variables.scroll = render.variables.markers[location]
	else
		return "No such location: \"" .. (source[2]:match("%w+%s+(.+)$") or "") .. "\" on line " .. source[1]
	end
end


render["functions"]["public"]["box "] = function(source)
	local sColor, align, height, width, offset, url = source[2]:match("^box (%a+) (%a+) (%-?%d+) (%-?%d+) (%-?%d+) ?([^ ]*)")
	if not sColor then
		return "Invalid box syntax on line " .. source[1]
	end

	local x, y = term.getCursorPos()
	local startX

	if align == "center" or align == "centre" then
		startX = math.ceil((w / 2) - width / 2) + offset
	elseif align == "left" then
		startX = 1 + offset
	elseif align == "right" then
		startX = (w - width + 1) + offset
	else
		return "Invalid align option for box on line " .. source[1]
	end

	if not colors[sColor] then
		return "Invalid color: \"" .. sColor .. "\" for box on line " .. source[1]
	end

	term.setBackgroundColor(colors[sColor])
	for i = 0, height - 1 do
		term.setCursorPos(startX, render.variables.scroll + i)
		term.write(string.rep(" ", width))
		if url:len() > 3 then
			table.insert(render.variables.linkData, {startX, startX + width - 1, render.variables.scroll + i, url})
		end
	end

	render.variables.maxScroll = math.max(render.variables.scroll + height - 1, render.variables.maxScroll)
	term.setCursorPos(x, y)
end


render["alignations"]["left"] = function(text, length, _, offset)
	local x, y = term.getCursorPos()
	if length then
		term.setCursorPos(1 + offset, render.variables.scroll)
		term.write(text)
		return 1 + offset
	else
		term.setCursorPos(x, render.variables.scroll)
		term.write(text)
		return x
	end
end


render["alignations"]["right"] = function(text, length, width, offset)
	local x, y = term.getCursorPos()
	if length then
		term.setCursorPos((width - length + 1) + offset, render.variables.scroll)
		term.write(text)
		return (width - length + 1) + offset
	else
		term.setCursorPos(x, render.variables.scroll)
		term.write(text)
		return x
	end
end


render["alignations"]["center"] = function(text, length, _, offset, center)
	local x, y = term.getCursorPos()
	if length then
		term.setCursorPos(math.ceil(center - length / 2) + offset, render.variables.scroll)
		term.write(text)
		return math.ceil(center - length / 2) + offset
	else
		term.setCursorPos(x, render.variables.scroll)
		term.write(text)
		return x
	end
end


render["render"] = function(data, startScroll)
	if startScroll == nil then
		render.variables.startScroll = 0
	else
		render.variables.startScroll = startScroll
	end

	render.variables.scroll = startScroll + 1
	render.variables.maxScroll = render.variables.scroll

	render.variables.linkData = {}

	render.variables.align = render.alignations.left

	render.variables.blockLength = 0
	render.variables.link = false
	render.variables.linkStart = false
	render.variables.markers = {}
	render.variables.currentOffset = 0

	for k, v in pairs(data) do
		if type(v[2]) ~= "string" then
			render.functions.displayText(v)
		elseif v[2] == "<" or v[2] == "left" then
			render.variables.align = render.alignations.left
		elseif v[2] == ">" or v[2] == "right" then
			render.variables.align = render.alignations.right
		elseif v[2] == "=" or v[2] == "center" then
			render.variables.align = render.alignations.center
		else
			local existentFunction = false

			for name, func in pairs(render.functions.public) do
				if v[2]:find(name) == 1 then
					existentFunction = true
					local ret = func(v)
					if ret then
						return ret
					end
				end
			end

			if not existentFunction then
				return "Non-existent tag: \"" .. v[2] .. "\" on line " .. v[1]
			end
		end
	end

	return render.variables.linkData, render.variables.maxScroll - render.variables.startScroll
end



--    Lua Execution


languages["lua"] = {}
languages["fwml"] = {}


languages["lua"]["runWithErrorCatching"] = function(func, ...)
	local _, err = pcall(func, ...)
	if err then
		os.queueEvent(websiteErrorEvent, err)
	end
end


languages["lua"]["runWithoutAntivirus"] = function(func, ...)
	local args = {...}
	local env = getWebsiteEnvironment(false)
	setfenv(func, env)
	return function()
		languages["lua"]["runWithErrorCatching"](func, unpack(args))
	end
end


languages["lua"]["run"] = function(contents, page, ...)
	local func, err = loadstring(contents, page)
	if err then
		return languages["lua"]["runWithoutAntivirus"](builtInSites["crash"], err)
	else
		local args = {...}
		local env = getWebsiteEnvironment(true)
		setfenv(func, env)
		return function()
			languages["lua"]["runWithErrorCatching"](func, unpack(args))
		end
	end
end


languages["fwml"]["run"] = function(contents, page, ...)
	local err, data = pcall(parse, contents)
	if not err then
		return languages["lua"]["runWithoutAntivirus"](builtInSites["crash"], data)
	end

	return function()
		local currentScroll = 0
		local err, links, pageHeight = pcall(render.render, data, currentScroll)
		if type(links) == "string" or not err then
			term.clear()
			os.queueEvent(websiteErrorEvent, links)
		else
			while true do
				local e, scroll, x, y = os.pullEvent()
				if e == "mouse_click" then
					for k, v in pairs(links) do
						if x >= math.min(v[1], v[2]) and x <= math.max(v[1], v[2]) and y == v[3] then
							os.queueEvent(redirectEvent, v[4])
							coroutine.yield()
						end
					end
				elseif e == "mouse_scroll" then
					if currentScroll - scroll - h >= -pageHeight and currentScroll - scroll <= 0 then
						currentScroll = currentScroll - scroll
						clear(theme.background, theme.text)
						links = render.render(data, currentScroll)
					end
				elseif e == "key" and (scroll == keys.up or scroll == keys.down) then
					local scrollAmount

					if scroll == keys.up then
						scrollAmount = 1
					elseif scroll == keys.down then
						scrollAmount = -1
					end

					if currentScroll + scrollAmount - h >= -pageHeight and currentScroll + scrollAmount <= 0 then
						currentScroll = currentScroll + scrollAmount
						clear(theme.background, theme.text)
						links = render.render(data, currentScroll)
					end
				end
			end
		end
	end
end



--    Query Bar


local readNewWebsiteURL = function()
	local onEvent = function(text, event, key, x, y)
		if event == "mouse_click" then
			if y == 2 then
				local index = determineClickedTab(x, y)
				if index == "new" and #tabs < maxTabs then
					loadTab(#tabs + 1, "firewolf")
				elseif index == "close" then
					closeCurrentTab()
				elseif index then
					switchTab(index)
				end

				return {["nullifyText"] = true, ["exit"] = true}
			elseif y > 2 then
				return {["nullifyText"] = true, ["exit"] = true}
			end
		elseif event == "key" then
			if key == 29 or key == 157 then
				return {["nullifyText"] = true, ["exit"] = true}
			end
		end
	end

	isMenubarOpen = true
	drawMenubar()
	term.setCursorPos(2, 1)
	term.setTextColor(theme.text)
	term.setBackgroundColor(theme.accent)
	term.clearLine()
	term.write(currentProtocol .. "://")

	local website = modifiedRead({
		["onEvent"] = onEvent,
		["displayLength"] = w - 9,
		["history"] = history,
	})

	if not website then
		if not tabs[currentTab].isMenubarPermanent then
			isMenubarOpen = false
			menubarWindow.setVisible(false)
		else
			isMenubarOpen = true
			menubarWindow.setVisible(true)
		end

		term.redirect(tabs[currentTab].win)
		tabs[currentTab].win.setVisible(true)
		tabs[currentTab].win.redraw()

		return
	elseif website == "exit" then
		error()
	end

	loadTab(currentTab, website)
end



--    Event Management


local handleKeyDown = function(event)
	if event[2] == 29 or event[2] == 157 then
		readNewWebsiteURL()
		return true
	end

	return false
end


local handleMouseDown = function(event)
	if isMenubarOpen then
		if event[4] == 1 then
			readNewWebsiteURL()
			return true
		elseif event[4] == 2 then
			local index = determineClickedTab(event[3], event[4])
			if index == "new" and #tabs < maxTabs then
				loadTab(#tabs + 1, "firewolf")
			elseif index == "close" then
				closeCurrentTab()
			elseif index then
				switchTab(index)
			end

			return true
		end
	end

	return false
end


local handleEvents = function()
	loadTab(1, "firewolf")
	currentTab = 1

	while true do
		drawMenubar()
		local event = {os.pullEventRaw()}
		drawMenubar()

		local cancelEvent = false
		if event[1] == "terminate" then
			break
		elseif event[1] == "key" then
			cancelEvent = handleKeyDown(event)
		elseif event[1] == "mouse_click" then
			cancelEvent = handleMouseDown(event)
		elseif event[1] == websiteErrorEvent then
			cancelEvent = true

			loadTab(currentTab, tabs[currentTab].url, function()
				builtInSites["crash"](event[2])
			end)
		elseif event[1] == redirectEvent then
			cancelEvent = true

			if (event[2]:match("^rdnt://(.+)$")) then
				event[2] = event[2]:match("^rdnt://(.+)$")
			end

			loadTab(currentTab, event[2])
		end

		if not cancelEvent then
			term.redirect(tabs[currentTab].win)
			term.setCursorPos(tabs[currentTab].ox, tabs[currentTab].oy)

			coroutine.resume(tabs[currentTab].thread, unpack(event))

			local ox, oy = term.getCursorPos()
			tabs[currentTab].ox = ox
			tabs[currentTab].oy = oy
		end
	end
end



--    Main


local main = function()
	currentProtocol = "rdnt"
	currentTab = 1

	if term.isColor() then
		theme = colorTheme
		enableTabBar = true
	else
		theme = grayscaleTheme
		enableTabBar = false
	end

	setupMenubar()
	protocols[currentProtocol]["setup"]()

	clear(theme.background, theme.text)
	handleEvents()
end


local handleError = function(err)
	clear(theme.background, theme.text)

	fill(1, 3, w, 3, theme.subtle)
	term.setCursorPos(1, 4)
	center("Firewolf has crashed!")

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


local originalTerminal = term.current()
local _, err = pcall(main)
term.redirect(originalTerminal)

protocols.rdnt.modem("closeAll")

if err and not err:lower():find("terminate") then
	handleError(err)
end


clear(colors.black, colors.white)
center("Thanks for using Firewolf " .. version)
center("Made by GravityScore and 1lann")
print("")
