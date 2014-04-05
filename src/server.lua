
--  
--  Firewolf
--  Made by GravityScore and 1lann
--  



--    Variables


local version = "3.0"
local build = 0

local w, h = term.getSize()

local serversFolder = "/fw_servers"
local indexFileName = "index"

local sides = {}

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

local theme = {
	background = colors.gray, 
	accent = colors.red, 
	subtle = colors.orange, 

	lightText = colors.gray, 
	text = colors.white, 
	errorText = colors.red, 
}

local default404 = [[
local function center(text)
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



--    Server Listing Interface


local deleteServer = function(domain)
	local path = serversFolder .. "/" .. domain
	fs.delete(path)
end


local allServers = function()
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


local selectServer = function()
	clear(theme.background, theme.text)
	title("Select a server to host ...")

	local servers = allServers()
	table.insert(servers, 1, "New Server")

	local startY = 3
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
					servers = allServers()
					table.insert(servers, 1, "New Server")
					draw()
				elseif x > 3 then
					if item == "New Server" then
						return nil, "new"
					else
						return item
					end
				end
			end
		elseif event == "mouse_click" and y == 1 and x == w then
			return nil
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

local modem = function(func,  ...)
	for _, side in pairs(sides) do
		if peripheral.getType(side) == "modem" then
			peripheral.call(side, func,  ...)
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
		return default404
	end
end


local backend = function(serverURL, onEvent, onMessage)
	local serverChannel = calculateChannel(serverURL)
	local sessions = {}

	local receivedMessages = {}
    local receivedMessageTimeouts = {}

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

	onMessage("Hosting rdnt://" .. serverURL)
	onMessage("Listening for incoming requests ...")

	while true do
		local eventArgs = {os.pullEvent()}
		local event, givenSide, givenChannel, givenID, givenMessage, givenDistance = unpack(eventArgs)
		if event == "modem_message" then
			if givenChannel == publicDnsChannel and givenMessage == DNSRequestTag and givenID == responseID then
				--onMessage("[DIRECT] Responding to DNS request")

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
				onMessage("[DIRECT] Request from active session")

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
			end
		elseif event == "modem_message" and givenChannel == rednet.CHANNEL_REPEAT and
				type(givenMessage) == "table" and givenMessage.nMessageID and givenMessage.nRecipient and
				not receivedMessages[givenMessage.nMessageID] then
			receivedMessages[givenMessage.nMessageID] = true
			receivedMessageTimeouts[os.startTimer(30)] = givenMessage.nMessageID

			modem("transmit", rednet.CHANNEL_REPEAT, givenID, givenMessage)
			modem("transmit", givenMessage.nRecipient, givenID, givenMessage)
		elseif event == "timer" then
			local messageID = receivedMessageTimeouts[givenSide]
			if messageID then
				receivedMessageTimeouts[givenSide] = nil
				receivedMessages[messageID] = nil
			end
		elseif event == "rednet_message" then
			if givenID == DNSRequestTag and givenChannel == DNSRequestTag then
				--onMessage("[REDNET] Responding to DNS request")
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



--    Hosting Interface


local host = function(domain)
	clear(theme.background, theme.text)

	local onEvent = function( ...)
		local event = { ...}
		if event[1] == "mouse_click" and event[3] == w and event[4] == 1 then
			return true
		end
	end

	local onMessage = function(text)
		print("  " .. text)

		local ox, oy = term.getCursorPos()
		title("Hosting rdnt://" .. domain)
		term.setCursorPos(ox, oy)
	end

	title("Hosting rdnt://" .. domain)

	term.setCursorPos(1, 3)
	backend(domain, onEvent, onMessage)
end



--    New Server Interface


local newServer = function()
	clear(theme.background, theme.text)
	title("Create a Server")

	term.setCursorPos(3, 4)
	term.write("Domain: rdnt://")
	local domain = read()
	if domain:len() == 0 then
		return
	end

	if domain:len() < 4 then
		term.setCursorPos(3, 6)
		term.write("Domain name must be at least 4 characters!")
		sleep(2)
		return
	end

	if domain:find(" ") then
		term.setCursorPos(3, 6)
		term.write("Domain name cannot contain spaces!")
		sleep(2)
		return
	end

	local path = serversFolder .. "/" .. domain
	if not fs.exists(path) then
		fs.makeDir(path)

		local f = io.open(path .. "/index", "w")
		f:write("print(\"Hello there!\")\nprint(\"Welcome to " .. domain .. "!\")")
		f:close()
	end
end



--    Main


local main = function()
	setupModem()
	fs.makeDir(serversFolder)

	while true do
		local domain, action = selectServer()
		if not domain and not action then
			break
		end

		if action == "new" then
			newServer()
		else
			local shouldExit = host(domain)
			if shouldExit then
				break
			end
		end
	end
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


local _, err = pcall(main)

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
