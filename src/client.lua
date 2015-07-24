
--
--  Firewolf
--  Made by GravityScore and 1lann
--



--    Variables


local version = "3.5"
local build = 18

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

local publicDNSChannel = 9999
local publicResponseChannel = 9998
local responseID = 41738

local httpTimeout = 10
local searchResultTimeout = 1
local initiationTimeout = 2
local animationInterval = 0.125
local fetchTimeout = 3
local serverLimitPerComputer = 1

local websiteErrorEvent = "firewolf_websiteErrorEvent"
local redirectEvent = "firewolf_redirectEvent"

local baseURL = "https://raw.githubusercontent.com/1lann/Firewolf/master/src"
local buildURL = baseURL .. "/build.txt"
local firewolfURL = baseURL .. "/client.lua"
local serverURL = baseURL .. "/server.lua"

local originalTerminal = term.current()

local firewolfLocation = "/" .. shell.getRunningProgram()
local downloadsLocation = "/downloads"


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
	http.request(url)
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

				local err = downloadAndSave(serverURL, "/fwserver")

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
		elseif event == "mouse_scroll" then
			if but > 0 then
				os.queueEvent("key", keys.down)
			else
				os.queueEvent("key", keys.up)
			end
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
		elseif event == "mouse_scroll" then
			if but > 0 then
				os.queueEvent("key", keys.down)
			else
				os.queueEvent("key", keys.up)
			end
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
		menubarWindow = window.create(originalTerminal, 1, 1, w, 2, false)
	else
		menubarWindow = window.create(originalTerminal, 1, 1, w, 1, false)
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
		if currentWebsiteURL:match("^[^%?]+") then
			term.write(currentProtocol .. "://" .. currentWebsiteURL:match("^[^%?]+"))
		else
			term.write(currentProtocol .. "://" ..currentWebsiteURL)
		end

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



--  RC4
--  Implementation by AgentE382


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


local crypt = function(text, key)
	local resp, msg = pcall(cryptWrapper, text, key)
	if resp then
		return msg
	else
		return nil
	end
end



--  Base64
--
--  Base64 Encryption/Decryption
--  By KillaVanilla
--  http://www.computercraft.info/forums2/index.php?/topic/12450-killavanillas-various-apis/
--  http://pastebin.com/rCYDnCxn
--


local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


local function sixBitToBase64(input)
	return string.sub(alphabet, input+1, input+1)
end


local function base64ToSixBit(input)
	for i=1, 64 do
		if input == string.sub(alphabet, i, i) then
			return i-1
		end
	end
end


local function octetToBase64(o1, o2, o3)
	local shifted = bit.brshift(bit.band(o1, 0xFC), 2)
	local i1 = sixBitToBase64(shifted)
	local i2 = "A"
	local i3 = "="
	local i4 = "="
	if o2 then
		i2 = sixBitToBase64(bit.bor( bit.blshift(bit.band(o1, 3), 4), bit.brshift(bit.band(o2, 0xF0), 4) ))
		if not o3 then
			i3 = sixBitToBase64(bit.blshift(bit.band(o2, 0x0F), 2))
		else
			i3 = sixBitToBase64(bit.bor( bit.blshift(bit.band(o2, 0x0F), 2), bit.brshift(bit.band(o3, 0xC0), 6) ))
		end
	else
		i2 = sixBitToBase64(bit.blshift(bit.band(o1, 3), 4))
	end
	if o3 then
		i4 = sixBitToBase64(bit.band(o3, 0x3F))
	end

	return i1..i2..i3..i4
end


local function base64ToThreeOctet(s1)
	local c1 = base64ToSixBit(string.sub(s1, 1, 1))
	local c2 = base64ToSixBit(string.sub(s1, 2, 2))
	local c3 = 0
	local c4 = 0
	local o1 = 0
	local o2 = 0
	local o3 = 0
	if string.sub(s1, 3, 3) == "=" then
		c3 = nil
		c4 = nil
	elseif string.sub(s1, 4, 4) == "=" then
		c3 = base64ToSixBit(string.sub(s1, 3, 3))
		c4 = nil
	else
		c3 = base64ToSixBit(string.sub(s1, 3, 3))
		c4 = base64ToSixBit(string.sub(s1, 4, 4))
	end
	o1 = bit.bor( bit.blshift(c1, 2), bit.brshift(bit.band( c2, 0x30 ), 4) )
	if c3 then
		o2 = bit.bor( bit.blshift(bit.band(c2, 0x0F), 4), bit.brshift(bit.band( c3, 0x3C ), 2) )
	else
		o2 = nil
	end
	if c4 then
		o3 = bit.bor( bit.blshift(bit.band(c3, 3), 6), c4 )
	else
		o3 = nil
	end
	return o1, o2, o3
end


local function splitIntoBlocks(bytes)
	local blockNum = 1
	local blocks = {}
	for i=1, #bytes, 3 do
		blocks[blockNum] = {bytes[i], bytes[i+1], bytes[i+2]}
		blockNum = blockNum+1
	end
	return blocks
end


function base64Encode(bytes)
	local blocks = splitIntoBlocks(bytes)
	local output = ""
	for i=1, #blocks do
		output = output..octetToBase64( unpack(blocks[i]) )
	end
	return output
end


function base64Decode(str)
	local bytes = {}
	local blocks = {}
	local blockNum = 1

	for i=1, #str, 4 do
		blocks[blockNum] = string.sub(str, i, i+3)
		blockNum = blockNum+1
	end

	for i=1, #blocks do
		local o1, o2, o3 = base64ToThreeOctet(blocks[i])
		table.insert(bytes, o1)
		table.insert(bytes, o2)
		table.insert(bytes, o3)
	end

	return bytes
end



--  SHA-256
--
--  Adaptation of the Secure Hashing Algorithm (SHA-244/256)
--  Found Here: http://lua-users.org/wiki/SecureHashAlgorithm
--
--  Using an adapted version of the bit library
--  Found Here: https://bitbucket.org/Boolsheet/bslf/src/1ee664885805/bit.lua


local MOD = 2^32
local MODM = MOD-1


local function memoize(f)
	local mt = {}
	local t = setmetatable({}, mt)
	function mt:__index(k)
		local v = f(k)
		t[k] = v
		return v
	end
	return t
end


local function make_bitop_uncached(t, m)
	local function bitop(a, b)
		local res,p = 0,1
		while a ~= 0 and b ~= 0 do
			local am, bm = a % m, b % m
			res = res + t[am][bm] * p
			a = (a - am) / m
			b = (b - bm) / m
			p = p * m
		end
		res = res + (a + b) * p
		return res
	end

	return bitop
end


local function make_bitop(t)
	local op1 = make_bitop_uncached(t,2^1)
	local op2 = memoize(function(a)
		return memoize(function(b)
			return op1(a, b)
		end)
	end)
	return make_bitop_uncached(op2, 2 ^ (t.n or 1))
end


local customBxor1 = make_bitop({[0] = {[0] = 0,[1] = 1}, [1] = {[0] = 1, [1] = 0}, n = 4})

local function customBxor(a, b, c, ...)
	local z = nil
	if b then
		a = a % MOD
		b = b % MOD
		z = customBxor1(a, b)
		if c then
			z = customBxor(z, c, ...)
		end
		return z
	elseif a then
		return a % MOD
	else
		return 0
	end
end


local function customBand(a, b, c, ...)
	local z
	if b then
		a = a % MOD
		b = b % MOD
		z = ((a + b) - customBxor1(a,b)) / 2
		if c then
			z = customBand(z, c, ...)
		end
		return z
	elseif a then
		return a % MOD
	else
		return MODM
	end
end


local function bnot(x)
	return (-1 - x) % MOD
end


local function rshift1(a, disp)
	if disp < 0 then
		return lshift(a, -disp)
	end
	return math.floor(a % 2 ^ 32 / 2 ^ disp)
end


local function rshift(x, disp)
	if disp > 31 or disp < -31 then
		return 0
	end
	return rshift1(x % MOD, disp)
end


local function lshift(a, disp)
	if disp < 0 then
		return rshift(a, -disp)
	end
	return (a * 2 ^ disp) % 2 ^ 32
end


local function rrotate(x, disp)
    x = x % MOD
    disp = disp % 32
    local low = customBand(x, 2 ^ disp - 1)
    return rshift(x, disp) + lshift(low, 32 - disp)
end


local k = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
	0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
	0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
	0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
	0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}


local function str2hexa(s)
	return (string.gsub(s, ".", function(c)
		return string.format("%02x", string.byte(c))
	end))
end


local function num2s(l, n)
	local s = ""
	for i = 1, n do
		local rem = l % 256
		s = string.char(rem) .. s
		l = (l - rem) / 256
	end
	return s
end


local function s232num(s, i)
	local n = 0
	for i = i, i + 3 do
		n = n*256 + string.byte(s, i)
	end
	return n
end


local function preproc(msg, len)
	local extra = 64 - ((len + 9) % 64)
	len = num2s(8 * len, 8)
	msg = msg .. "\128" .. string.rep("\0", extra) .. len
	assert(#msg % 64 == 0)
	return msg
end


local function initH256(H)
	H[1] = 0x6a09e667
	H[2] = 0xbb67ae85
	H[3] = 0x3c6ef372
	H[4] = 0xa54ff53a
	H[5] = 0x510e527f
	H[6] = 0x9b05688c
	H[7] = 0x1f83d9ab
	H[8] = 0x5be0cd19
	return H
end


local function digestblock(msg, i, H)
	local w = {}
	for j = 1, 16 do
		w[j] = s232num(msg, i + (j - 1)*4)
	end
	for j = 17, 64 do
		local v = w[j - 15]
		local s0 = customBxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
		v = w[j - 2]
		w[j] = w[j - 16] + s0 + w[j - 7] + customBxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
	end

	local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
	for i = 1, 64 do
		local s0 = customBxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
		local maj = customBxor(customBand(a, b), customBand(a, c), customBand(b, c))
		local t2 = s0 + maj
		local s1 = customBxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
		local ch = customBxor (customBand(e, f), customBand(bnot(e), g))
		local t1 = h + s1 + ch + k[i] + w[i]
		h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
	end

	H[1] = customBand(H[1] + a)
	H[2] = customBand(H[2] + b)
	H[3] = customBand(H[3] + c)
	H[4] = customBand(H[4] + d)
	H[5] = customBand(H[5] + e)
	H[6] = customBand(H[6] + f)
	H[7] = customBand(H[7] + g)
	H[8] = customBand(H[8] + h)
end


local function sha256(msg)
	msg = preproc(msg, #msg)
	local H = initH256({})
	for i = 1, #msg, 64 do
		digestblock(msg, i, H)
	end
	return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
		num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
end


local protocolName = "Firewolf"



--    Cryptography


local Cryptography = {}
Cryptography.sha = {}
Cryptography.base64 = {}
Cryptography.aes = {}


function Cryptography.bytesFromMessage(msg)
	local bytes = {}

	for i = 1, msg:len() do
		local letter = string.byte(msg:sub(i, i))
		table.insert(bytes, letter)
	end

	return bytes
end


function Cryptography.messageFromBytes(bytes)
	local msg = ""

	for i = 1, #bytes do
		local letter = string.char(bytes[i])
		msg = msg .. letter
	end

	return msg
end


function Cryptography.bytesFromKey(key)
	local bytes = {}

	for i = 1, key:len() / 2 do
		local group = key:sub((i - 1) * 2 + 1, (i - 1) * 2 + 1)
		local num = tonumber(group, 16)
		table.insert(bytes, num)
	end

	return bytes
end


function Cryptography.sha.sha256(msg)
	return sha256(msg)
end


function Cryptography.aes.encrypt(msg, key)
	return base64Encode(crypt(msg, key))
end


function Cryptography.aes.decrypt(msg, key)
	return crypt(base64Decode(msg), key)
end


function Cryptography.base64.encode(msg)
	return base64Encode(Cryptography.bytesFromMessage(msg))
end


function Cryptography.base64.decode(msg)
	return Cryptography.messageFromBytes(base64Decode(msg))
end


function Cryptography.channel(text)
	local hashed = Cryptography.sha.sha256(text)

	local total = 0

	for i = 1, hashed:len() do
		total = total + string.byte(hashed:sub(i, i))
	end

	return (total % 55530) + 10000
end


function Cryptography.sanatize(text)
	local sanatizeChars = {"%", "(", ")", "[", "]", ".", "+", "-", "*", "?", "^", "$"}

	for _, char in pairs(sanatizeChars) do
		text = text:gsub("%"..char, "%%%"..char)
	end
	return text
end



--  Modem


local Modem = {}
Modem.modems = {}


function Modem.exists()
	Modem.exists = false
	for _, side in pairs(rs.getSides()) do
		if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
			Modem.exists = true

			if not Modem.modems[side] then
				Modem.modems[side] = peripheral.wrap(side)
			end
		end
	end

	return Modem.exists
end


function Modem.open(channel)
	if not Modem.exists then
		return false
	end

	for side, modem in pairs(Modem.modems) do
		modem.open(channel)
		rednet.open(side)
	end

	return true
end


function Modem.close(channel)
	if not Modem.exists then
		return false
	end

	for side, modem in pairs(Modem.modems) do
		modem.close(channel)
	end

	return true
end


function Modem.closeAll()
	if not Modem.exists then
		return false
	end

	for side, modem in pairs(Modem.modems) do
		modem.closeAll()
	end

	return true
end


function Modem.isOpen(channel)
	if not Modem.exists then
		return false
	end

	local isOpen = false
	for side, modem in pairs(Modem.modems) do
		if modem.isOpen(channel) then
			isOpen = true
			break
		end
	end

	return isOpen
end


function Modem.transmit(channel, msg)
	if not Modem.exists then
		return false
	end

	if not Modem.isOpen(channel) then
		Modem.open(channel)
	end

	for side, modem in pairs(Modem.modems) do
		modem.transmit(channel, channel, msg)
	end

	return true
end



--    Handshake


local Handshake = {}

Handshake.prime = 625210769
Handshake.channel = 54569
Handshake.base = -1
Handshake.secret = -1
Handshake.sharedSecret = -1
Handshake.packetHeader = "["..protocolName.."-Handshake-Packet-Header]"
Handshake.packetMatch = "%["..protocolName.."%-Handshake%-Packet%-Header%](.+)"


function Handshake.exponentWithModulo(base, exponent, modulo)
	local remainder = base

	for i = 1, exponent-1 do
		remainder = remainder * remainder
		if remainder >= modulo then
			remainder = remainder % modulo
		end
	end

	return remainder
end


function Handshake.clear()
	Handshake.base = -1
	Handshake.secret = -1
	Handshake.sharedSecret = -1
end


function Handshake.generateInitiatorData()
	Handshake.base = math.random(10,99999)
	Handshake.secret = math.random(10,99999)
	return {
		type = "initiate",
		prime = Handshake.prime,
		base = Handshake.base,
		moddedSecret = Handshake.exponentWithModulo(Handshake.base, Handshake.secret, Handshake.prime)
	}
end


function Handshake.generateResponseData(initiatorData)
	local isPrimeANumber = type(initiatorData.prime) == "number"
	local isPrimeMatching = initiatorData.prime == Handshake.prime
	local isBaseANumber = type(initiatorData.base) == "number"
	local isInitiator = initiatorData.type == "initiate"
	local isModdedSecretANumber = type(initiatorData.moddedSecret) == "number"
	local areAllNumbersNumbers = isPrimeANumber and isBaseANumber and isModdedSecretANumber

	if areAllNumbersNumbers and isPrimeMatching then
		if isInitiator then
			Handshake.base = initiatorData.base
			Handshake.secret = math.random(10,99999)
			Handshake.sharedSecret = Handshake.exponentWithModulo(initiatorData.moddedSecret, Handshake.secret, Handshake.prime)
			return {
				type = "response",
				prime = Handshake.prime,
				base = Handshake.base,
				moddedSecret = Handshake.exponentWithModulo(Handshake.base, Handshake.secret, Handshake.prime)
			}, Handshake.sharedSecret
		elseif initiatorData.type == "response" and Handshake.base > 0 and Handshake.secret > 0 then
			Handshake.sharedSecret = Handshake.exponentWithModulo(initiatorData.moddedSecret, Handshake.secret, Handshake.prime)
			return Handshake.sharedSecret
		else
			return false
		end
	else
		return false
	end
end



--    Secure Connection


local SecureConnection = {}
SecureConnection.__index = SecureConnection


SecureConnection.packetHeaderA = "["..protocolName.."-"
SecureConnection.packetHeaderB = "-SecureConnection-Packet-Header]"
SecureConnection.packetMatchA = "%["..protocolName.."%-"
SecureConnection.packetMatchB = "%-SecureConnection%-Packet%-Header%](.+)"
SecureConnection.connectionTimeout = 0.1
SecureConnection.successPacketTimeout = 0.1


function SecureConnection.new(secret, key, identifier, distance, isRednet)
	local self = setmetatable({}, SecureConnection)
	self:setup(secret, key, identifier, distance, isRednet)
	return self
end


function SecureConnection:setup(secret, key, identifier, distance, isRednet)
	local rawSecret

	if isRednet then
		self.isRednet = true
		self.distance = -1
		self.rednet_id = distance
		rawSecret = protocolName .. "|" .. tostring(secret) .. "|" .. tostring(identifier) ..
		"|" .. tostring(key) .. "|rednet"
	else
		self.isRednet = false
		self.distance = distance
		rawSecret = protocolName .. "|" .. tostring(secret) .. "|" .. tostring(identifier) ..
		"|" .. tostring(key) .. "|" .. tostring(distance)
	end

	self.identifier = identifier
	self.packetMatch = SecureConnection.packetMatchA .. Cryptography.sanatize(identifier) .. SecureConnection.packetMatchB
	self.packetHeader = SecureConnection.packetHeaderA .. identifier .. SecureConnection.packetHeaderB
	self.secret = Cryptography.sha.sha256(rawSecret)
	self.channel = Cryptography.channel(self.secret)

	if not self.isRednet then
		Modem.open(self.channel)
	end
end


function SecureConnection:verifyHeader(msg)
	if msg:match(self.packetMatch) then
		return true
	else
		return false
	end
end


function SecureConnection:sendMessage(msg, rednetProtocol)
	local rawEncryptedMsg = Cryptography.aes.encrypt(self.packetHeader .. msg, self.secret)
	local encryptedMsg = self.packetHeader .. rawEncryptedMsg

	if self.isRednet then
		rednet.send(self.rednet_id, encryptedMsg, rednetProtocol)
		return true
	else
		return Modem.transmit(self.channel, encryptedMsg)
	end
end


function SecureConnection:decryptMessage(msg)
	if self:verifyHeader(msg) then
		local encrypted = msg:match(self.packetMatch)

		local unencryptedMsg = nil
		pcall(function() unencryptedMsg = Cryptography.aes.decrypt(encrypted, self.secret) end)
		if not unencryptedMsg then
			return false, "Could not decrypt"
		end

		if self:verifyHeader(unencryptedMsg) then
			return true, unencryptedMsg:match(self.packetMatch)
		else
			return false, "Could not verify"
		end
	else
		return false, "Could not stage 1 verify"
	end
end



--    RDNT Protocol


protocols["rdnt"] = {}

local header = {}
header.dnsPacket = "[Firewolf-DNS-Packet]"
header.dnsHeaderMatch = "^%[Firewolf%-DNS%-Response%](.+)$"
header.rednetHeader = "[Firewolf-Rednet-Channel-Simulation]"
header.rednetMatch = "^%[Firewolf%-Rednet%-Channel%-Simulation%](%d+)$"
header.responseMatchA = "^%[Firewolf%-"
header.responseMatchB = "%-"
header.responseMatchC = "%-Handshake%-Response%](.+)$"
header.requestHeaderA = "[Firewolf-"
header.requestHeaderB = "-Handshake-Request]"
header.pageRequestHeaderA = "[Firewolf-"
header.pageRequestHeaderB = "-Page-Request]"
header.pageResponseMatchA = "^%[Firewolf%-"
header.pageResponseMatchB = "%-Page%-Response%]%[HEADER%](.-)%[BODY%](.+)$"
header.closeHeaderA = "[Firewolf-"
header.closeHeaderB = "-Connection-Close]"


protocols["rdnt"]["setup"] = function()
	if not Modem.exists() then
		error("No modem found!")
	end
end


protocols["rdnt"]["fetchAllSearchResults"] = function()
	Modem.open(publicDNSChannel)
	Modem.open(publicResponseChannel)
	Modem.transmit(publicDNSChannel, header.dnsPacket)
	Modem.close(publicDNSChannel)

	rednet.broadcast(header.dnsPacket, header.rednetHeader .. publicDNSChannel)

	local uniqueServers = {}
	local uniqueDomains = {}

	local timer = os.startTimer(searchResultTimeout)

	while true do
		local event, id, channel, protocol, message, dist = os.pullEventRaw()
		if event == "modem_message" then
			if channel == publicResponseChannel and message:match(header.dnsHeaderMatch) then
				if not uniqueServers[tostring(dist)] then
					uniqueServers[tostring(dist)] = true
					local domain = message:match(header.dnsHeaderMatch)
					if not uniqueDomains[domain] then
						if not(domain:find("/") or domain:find(":") or domain:find("%?")) and #domain > 4 then
							timer = os.startTimer(searchResultTimeout)
							uniqueDomains[message:match(header.dnsHeaderMatch)] = tostring(dist)
						end
					end
				end
			end
		elseif event == "rednet_message" and allowUnencryptedConnections then
			if protocol and tonumber(protocol:match(header.rednetMatch)) == publicResponseChannel and channel:match(header.dnsHeaderMatch) then
				if not uniqueServers[tostring(id)] then
					uniqueServers[tostring(id)] = true
					local domain = channel:match(header.dnsHeaderMatch)
					if not uniqueDomains[domain] then
						if not(domain:find("/") or domain:find(":") or domain:find("%?")) and #domain > 4 then
							timer = os.startTimer(searchResultTimeout)
							uniqueDomains[domain] = tostring(id)
						end
					end
				end
			end
		elseif event == "timer" and id == timer then
			local results = {}
			for k, _ in pairs(uniqueDomains) do
				table.insert(results, k)
			end

			return results
		end
	end
end


protocols["rdnt"]["fetchConnectionObject"] = function(url)
	local serverChannel = Cryptography.channel(url)
	local requestHeader = header.requestHeaderA .. url .. header.requestHeaderB
	local responseMatch = header.responseMatchA .. Cryptography.sanatize(url) .. header.responseMatchB

	local serializedHandshake = textutils.serialize(Handshake.generateInitiatorData())

	local rednetResults = {}
	local directResults = {}

	local disconnectOthers = function(ignoreDirect)
		for k,v in pairs(rednetResults) do
			v.close()
		end
		for k,v in pairs(directResults) do
			if k ~= ignoreDirect then
				v.close()
			end
		end
	end

	local timer = os.startTimer(initiationTimeout)

	Modem.open(serverChannel)
	Modem.transmit(serverChannel, requestHeader .. serializedHandshake)

	rednet.broadcast(requestHeader .. serializedHandshake, header.rednetHeader .. serverChannel)

	-- Extendable to have server selection

	while true do
		local event, id, channel, protocol, message, dist = os.pullEventRaw()
		if event == "modem_message" then
			local fullMatch = responseMatch .. tostring(dist) .. header.responseMatchC
			if channel == serverChannel and message:match(fullMatch) and type(textutils.unserialize(message:match(fullMatch))) == "table" then
				local key = Handshake.generateResponseData(textutils.unserialize(message:match(fullMatch)))
				if key then
					local connection = SecureConnection.new(key, url, url, dist)
					table.insert(directResults, {
						connection = connection,
						fetchPage = function(page)
							if not connection then
								return nil
							end

							local fetchTimer = os.startTimer(fetchTimeout)

							local pageRequest = header.pageRequestHeaderA .. url .. header.pageRequestHeaderB .. page
							local pageResponseMatch = header.pageResponseMatchA .. Cryptography.sanatize(url) .. header.pageResponseMatchB

							connection:sendMessage(pageRequest, header.rednetHeader .. connection.channel)

							while true do
								local event, id, channel, protocol, message, dist = os.pullEventRaw()
								if event == "modem_message" and channel == connection.channel and connection:verifyHeader(message) then
									local resp, data = connection:decryptMessage(message)
									if not resp then
										-- Decryption error
									elseif data and data ~= page then
										if data:match(pageResponseMatch) then
											local head, body = data:match(pageResponseMatch)
											return body, textutils.unserialize(head)
										end
									end
								elseif event == "timer" and id == fetchTimer then
									return nil
								end
							end
						end,
						close = function()
							if connection ~= nil then
								connection:sendMessage(header.closeHeaderA .. url .. header.closeHeaderB, header.rednetHeader..connection.channel)
								Modem.close(connection.channel)
								connection = nil
							end
						end
					})

					disconnectOthers(1)
					return directResults[1]
				end
			end
		elseif event == "rednet_message" then
			local fullMatch = responseMatch .. os.getComputerID() .. header.responseMatchC
			if protocol and tonumber(protocol:match(header.rednetMatch)) == serverChannel and channel:match(fullMatch) and type(textutils.unserialize(channel:match(fullMatch))) == "table" then
				local key = Handshake.generateResponseData(textutils.unserialize(channel:match(fullMatch)))
				if key then
					local connection = SecureConnection.new(key, url, url, id, true)
					table.insert(rednetResults, {
						connection = connection,
						fetchPage = function(page)
							if not connection then
								return nil
							end

							local fetchTimer = os.startTimer(fetchTimeout)

							local pageRequest = header.pageRequestHeaderA .. url .. header.pageRequestHeaderB .. page
							local pageResponseMatch = header.pageResponseMatchA .. Cryptography.sanatize(url) .. header.pageResponseMatchB

							connection:sendMessage(pageRequest, header.rednetHeader .. connection.channel)

							while true do
								local event, id, channel, protocol, message, dist = os.pullEventRaw()
								if event == "rednet_message" and protocol and tonumber(protocol:match(header.rednetMatch)) == connection.channel and connection:verifyHeader(channel) then
									local resp, data = connection:decryptMessage(channel)
									if not resp then
										-- Decryption error
									elseif data and data ~= page then
										if data:match(pageResponseMatch) then
											local head, body = data:match(pageResponseMatch)
											return body, textutils.unserialize(head)
										end
									end
								elseif event == "timer" and id == fetchTimer then
									return nil
								end
							end
						end,
						close = function()
							connection:sendMessage(header.closeHeaderA .. url .. header.closeHeaderB, header.rednetHeader..connection.channel)
							Modem.close(connection.channel)
							connection = nil
						end
					})

					if #rednetResults == 1 then
						timer = os.startTimer(0.2)
					end
				end
			end
		elseif event == "timer" and id == timer then
			-- Return
			if #directResults > 0 then
				disconnectOthers(1)
				return directResults[1]
			elseif #rednetResults > 0 then
				local lowestID = math.huge
				local lowestResult = nil
				for k,v in pairs(rednetResults) do
					if v.connection.rednet_id < lowestID then
						lowestID = v.connection.rednet_id
						lowestResult = v
					end
				end

				for k,v in pairs(rednetResults) do
					if v.connection.rednet_id ~= lowestID then
						v.close()
					end
				end

				return lowestResult
			else
				return nil
			end
		end
	end
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
	if not page then page = "" end
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

	local page = normalizePage(url:match("^[^/]+/(.+)"))
	local contents, head = connection.fetchPage(page)
	if contents then
		if type(contents) ~= "string" then
			return fetchNone()
		else
			local language = determineLanguage(head)
			return languages[language]["run"](contents, page, connection)
		end
	else
		if connection then
			connection.close()
			return "retry"
		end
		return fetchError("A connection error/timeout has occurred!")
	end
end


local fetchNone = function()
	return languages["lua"]["runWithoutAntivirus"](builtInSites["noresults"])
end


local fetchURL = function(url, inheritConnection)
	url = normalizeURL(url)
	currentWebsiteURL = url

	if inheritConnection then
		local resp = fetchExternal(url, inheritConnection)
		if resp ~= "retry" then
			return resp, false, inheritConnection
		end
	end

	local action, connection = determineActionForURL(url)

	if action == "search" then
		return fetchSearch(url, connection), true
	elseif action == "internal website" then
		return fetchInternal(url), true
	elseif action == "external website" then
		local resp = fetchExternal(url, connection)
		if resp == "retry" then
			return fetchError("A connection error/timeout has occurred!"), false, connection
		else
			return resp, false, connection
		end
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

	term.redirect(originalTerminal)
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
	local currentConnection = false

	isMenubarOpen = true
	currentWebsiteURL = url
	drawMenubar()

	if tabs[index] and tabs[index].connection and tabs[index].url then
		if url:match("^([^/]+)") == tabs[index].url:match("^([^/]+)") then
			currentConnection = tabs[index].connection
		else
			tabs[index].connection.close()
			tabs[index].connection = nil
		end
	end

	if givenFunc then
		func = givenFunc
	else
		parallel.waitForAny(function()
			func, isOpen, connection = fetchURL(url, currentConnection)
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
		tabs[index].connection = connection
		tabs[index].win = window.create(originalTerminal, 1, 1, w, h, false)

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
	env["os"]["pullEvent"] = function(filter)
		while true do
			local event = {os.pullEvent(filter)}
			if not filter then
				return unpack(event)
			elseif filter and event[1] == filter then
				return unpack(event)
			end
		end
	end
	env["os"]["pullEventRaw"] = env["os"]["pullEvent"]

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

local urlEncode = function(url)
	local result = url

	result = result:gsub("%%", "%%a")
	result = result:gsub(":", "%%c")
	result = result:gsub("/", "%%s")
	result = result:gsub("\n", "%%n")
	result = result:gsub(" ", "%%w")
	result = result:gsub("&", "%%m")
	result = result:gsub("%?", "%%q")
	result = result:gsub("=", "%%e")
	result = result:gsub("%.", "%%d")

	return result
end

local urlDecode = function(url)
	local result = url

	result = result:gsub("%%c", ":")
	result = result:gsub("%%s", "/")
	result = result:gsub("%%n", "\n")
	result = result:gsub("%%w", " ")
	result = result:gsub("%%&", "&")
	result = result:gsub("%%q", "%?")
	result = result:gsub("%%e", "=")
	result = result:gsub("%%d", "%.")
	result = result:gsub("%%m", "%%")

	return result
end

local applyAPIFunctions = function(env, connection)
	env["firewolf"] = {}
	env["firewolf"]["version"] = version
	env["firewolf"]["domain"] = currentWebsiteURL:match("^[^/]+")

	env["firewolf"]["redirect"] = function(url)
		if type(url) ~= "string" then
			return error("string (url) expected, got " .. type(url))
		end

		os.queueEvent(redirectEvent, url)
		coroutine.yield()
	end

	env["firewolf"]["download"] = function(page)
		if type(page) ~= "string" then
			return error("string (page) expected")
		end
		local bannedNames = {"ls", "dir", "delete", "copy", "move", "list", "rm", "cp", "mv", "clear", "cd", "lua"}

		local startSearch, endSearch = page:find(currentWebsiteURL:match("^[^/]+"))
		if startSearch == 1 then
			if page:sub(endSearch + 1, endSearch + 1) == "/" then
				page = page:sub(endSearch + 2, -1)
			else
				page = page:sub(endSearch + 1, -1)
			end
		end

		local filename = page:match("([^/]+)$")
		if not filename then
			return false, "Cannot download index"
		end

		for k, v in pairs(bannedNames) do
			if filename == v then
				return false, "Filename prohibited!"
			end
		end

		if not fs.exists(downloadsLocation) then
			fs.makeDir(downloadsLocation)
		elseif not fs.isDir(downloadsLocation) then
			return false, "Downloads disabled!"
		end

		contents = connection.fetchPage(normalizePage(page))
		if type(contents) ~= "string" then
			return false, "Download error!"
		else
			local f = io.open(downloadsLocation .. "/" .. filename, "w")
			f:write(contents)
			f:close()
			return true, downloadsLocation .. "/" .. filename
		end
	end

	env["firewolf"]["encode"] = function(vars)
		if type(vars) ~= "table" then
			return error("table (vars) expected, got " .. type(vars))
		end

		local startSearch, endSearch = page:find(currentWebsiteURL:match("^[^/]+"))
		if startSearch == 1 then
			if page:sub(endSearch + 1, endSearch + 1) == "/" then
				page = page:sub(endSearch + 2, -1)
			else
				page = page:sub(endSearch + 1, -1)
			end
		end

		local construct = "?"
		for k,v in pairs(vars) do
 			construct = construct .. urlEncode(tostring(k)) .. "=" .. urlEncode(tostring(v)) .. "&"
		end
		-- Get rid of that last ampersand
		construct = construct:sub(1, -2)

		return construct
	end

	env["firewolf"]["query"] = function(page, vars)
		if type(page) ~= "string" then
			return error("string (page) expected, got " .. type(page))
		end
		if vars and type(vars) ~= "table" then
			return error("table (vars) expected, got " .. type(vars))
		end

		local startSearch, endSearch = page:find(currentWebsiteURL:match("^[^/]+"))
		if startSearch == 1 then
			if page:sub(endSearch + 1, endSearch + 1) == "/" then
				page = page:sub(endSearch + 2, -1)
			else
				page = page:sub(endSearch + 1, -1)
			end
		end

		local construct = page .. "?"
		if vars then
			for k,v in pairs(vars) do
	 			construct = construct .. urlEncode(tostring(k)) .. "=" .. urlEncode(tostring(v)) .. "&"
			end
		end
		-- Get rid of that last ampersand
		construct = construct:sub(1, -2)

		contents = connection.fetchPage(normalizePage(construct))
		if type(contents) == "string" then
			return contents
		else
			return false
		end
	end

	env["firewolf"]["loadImage"] = function(page)
		if type(page) ~= "string" then
			return error("string (page) expected, got " .. type(page))
		end

		local startSearch, endSearch = page:find(currentWebsiteURL:match("^[^/]+"))
		if startSearch == 1 then
			if page:sub(endSearch + 1, endSearch + 1) == "/" then
				page = page:sub(endSearch + 2, -1)
			else
				page = page:sub(endSearch + 1, -1)
			end
		end

		local filename = page:match("([^/]+)$")
		if not filename then
			return false, "Cannot load index as an image!"
		end

		contents = connection.fetchPage(normalizePage(page))
		if type(contents) ~= "string" then
			return false, "Download error!"
		else
			local colorLookup = {}
			for n = 1, 16 do
				colorLookup[string.byte("0123456789abcdef", n, n)] = 2 ^ (n - 1)
			end

			local image = {}
			for line in contents:gmatch("[^\n]+") do
				local lines = {}
				for x = 1, line:len() do
					lines[x] = colorLookup[string.byte(line, x, x)] or 0
				end
				table.insert(image, lines)
			end

			return image
		end
	end

	env["center"] = center
	env["fill"] = fill
end


local getWebsiteEnvironment = function(antivirus, connection)
	local env = {}

	if antivirus then
		env = getWhitelistedEnvironment()
		overrideEnvironment(env)
	else
		setmetatable(env, {__index = _G})
	end

	applyAPIFunctions(env, connection)

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


languages["lua"]["run"] = function(contents, page, connection, ...)
	local func, err = loadstring("sleep(0) " .. contents, page)
	if err then
		return languages["lua"]["runWithoutAntivirus"](builtInSites["crash"], err)
	else
		local args = {...}
		local env = getWebsiteEnvironment(true, connection)
		setfenv(func, env)
		return function()
			languages["lua"]["runWithErrorCatching"](func, unpack(args))
		end
	end
end


languages["fwml"]["run"] = function(contents, page, connection, ...)
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
				elseif e == "key" and scroll == keys.up or scroll == keys.down then
					local scrollAmount

					if scroll == keys.up then
						scrollAmount = 1
					elseif scroll == keys.down then
						scrollAmount = -1
					end

					local scrollLessHeight = currentScroll + scrollAmount - h >= -pageHeight
					local scrollZero = currentScroll + scrollAmount <= 0
					if scrollLessHeight and scrollZero then
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

local _, err = pcall(main)
term.redirect(originalTerminal)

Modem.closeAll()

if err and not err:lower():find("terminate") then
	handleError(err)
end


clear(colors.black, colors.white)
center("Thanks for using Firewolf " .. version)
center("Made by GravityScore and 1lann")
print("")
