
--  
--  Firewolf Website Browser
--  Made by GravityScore and 1lann
--  License found here: https://raw.github.com/1lann/Firewolf/master/LICENSE
--  
--  Original Concept From RednetExplorer 2.4.1
--  RednetExplorer Made by ComputerCraftFan11
--  


--  -------- Variables

-- Version
local version = "3.0"
local browserAgentTemplate = "Firewolf " .. version
browserAgent = browserAgentTemplate
local tArgs = {...}

-- Server Identification
local serverID = "experimental"
local serverList = {experimental = "Experimental", other = "Other"}

-- Security
local h3t59qc1fo2 = "6001e441ab0002813c6e9170a5045000500c52088200088c0a00580809008009"

-- Updating
local autoupdate = "true"
local incognito = "false"
local noInternet = false

-- Geometry
local w, h = term.getSize()
local graphics = {}
local files = {}

-- Debugging
local debugFile = nil

-- Environment
local oldEnv = {}
local env = {}
local backupEnv = {}
local api = {}

-- Themes
local theme = {}

-- Databases
local blacklist = {}
local whitelist = {}
local definitions = {}
local verifiedDownloads = {}
local dnsDatabase = {[1] = {}, [2] = {}}

-- Website loading
local website = ""
local homepage = ""
local timeout = 0.08
local openAddressBar = true
local loadingRate = 0
local curSites = {}
local menuBarOpen = false
local internalWebsite = false
local serverWebsiteID = nil

-- Protocols
local curProtocol = {}
local protocols = {}

-- History
local history = {}
local addressBarHistory = {}

-- Events
local event_loadWebsite = "firewolf_loadWebsiteEvent"
local event_exitWebsite = "firewolf_exitWebsiteEvent"
local event_openAddressBar = "firewolf_openAddressBarEvent"
local event_exitApp = "firewolf_exitAppEvent"
local event_redirect = "firewolf_redirectEvent"

-- Download URLs
local firewolfURL = "https://raw.github.com/1lann/firewolf/master/entities/" .. serverID .. ".lua"
local databaseURL = "https://raw.github.com/1lann/firewolf/master/databases/" .. serverID .. 
	"-database.txt"
local serverURL = "https://raw.github.com/1lann/firewolf/master/server/server-release.lua"
if serverID == "experimental" then 
	serverURL = "https://raw.github.com/1lann/firewolf/master/server/server-experimental.lua"
end
local availableThemesURL = "https://raw.github.com/1lann/firewolf/master/themes/available.txt"

-- Data Locations
local rootFolder = "/.Firewolf_Data"
local cacheFolder = rootFolder .. "/cache"
local serverFolder = rootFolder .. "/servers"
local themeLocation = rootFolder .. "/theme"
local defaultThemeLocation = rootFolder .. "/default_theme"
local availableThemesLocation = rootFolder .. "/available_themes"
local serverSoftwareLocation = rootFolder .. "/server_software"
local settingsLocation = rootFolder .. "/settings"
local historyLocation = rootFolder .. "/history"
local debugLogLocation = "/firewolf-log"
local firewolfLocation = "/" .. shell.getRunningProgram()

local userBlacklist = rootFolder .. "/user_blacklist"
local userWhitelist = rootFolder .. "/user_whitelist"


--  -------- SHA-256 Hashing Algorithm

local function band(int1, int2, int3, ...)
	local ret =
	((int1%0x00000002>=0x00000001 and int2%0x00000002>=0x00000001 and 0x00000001) or 0)+
	((int1%0x00000004>=0x00000002 and int2%0x00000004>=0x00000002 and 0x00000002) or 0)+
	((int1%0x00000008>=0x00000004 and int2%0x00000008>=0x00000004 and 0x00000004) or 0)+
	((int1%0x00000010>=0x00000008 and int2%0x00000010>=0x00000008 and 0x00000008) or 0)+
	((int1%0x00000020>=0x00000010 and int2%0x00000020>=0x00000010 and 0x00000010) or 0)+
	((int1%0x00000040>=0x00000020 and int2%0x00000040>=0x00000020 and 0x00000020) or 0)+
	((int1%0x00000080>=0x00000040 and int2%0x00000080>=0x00000040 and 0x00000040) or 0)+
	((int1%0x00000100>=0x00000080 and int2%0x00000100>=0x00000080 and 0x00000080) or 0)+
	((int1%0x00000200>=0x00000100 and int2%0x00000200>=0x00000100 and 0x00000100) or 0)+
	((int1%0x00000400>=0x00000200 and int2%0x00000400>=0x00000200 and 0x00000200) or 0)+
	((int1%0x00000800>=0x00000400 and int2%0x00000800>=0x00000400 and 0x00000400) or 0)+
	((int1%0x00001000>=0x00000800 and int2%0x00001000>=0x00000800 and 0x00000800) or 0)+
	((int1%0x00002000>=0x00001000 and int2%0x00002000>=0x00001000 and 0x00001000) or 0)+
	((int1%0x00004000>=0x00002000 and int2%0x00004000>=0x00002000 and 0x00002000) or 0)+
	((int1%0x00008000>=0x00004000 and int2%0x00008000>=0x00004000 and 0x00004000) or 0)+
	((int1%0x00010000>=0x00008000 and int2%0x00010000>=0x00008000 and 0x00008000) or 0)+
	((int1%0x00020000>=0x00010000 and int2%0x00020000>=0x00010000 and 0x00010000) or 0)+
	((int1%0x00040000>=0x00020000 and int2%0x00040000>=0x00020000 and 0x00020000) or 0)+
	((int1%0x00080000>=0x00040000 and int2%0x00080000>=0x00040000 and 0x00040000) or 0)+
	((int1%0x00100000>=0x00080000 and int2%0x00100000>=0x00080000 and 0x00080000) or 0)+
	((int1%0x00200000>=0x00100000 and int2%0x00200000>=0x00100000 and 0x00100000) or 0)+
	((int1%0x00400000>=0x00200000 and int2%0x00400000>=0x00200000 and 0x00200000) or 0)+
	((int1%0x00800000>=0x00400000 and int2%0x00800000>=0x00400000 and 0x00400000) or 0)+
	((int1%0x01000000>=0x00800000 and int2%0x01000000>=0x00800000 and 0x00800000) or 0)+
	((int1%0x02000000>=0x01000000 and int2%0x02000000>=0x01000000 and 0x01000000) or 0)+
	((int1%0x04000000>=0x02000000 and int2%0x04000000>=0x02000000 and 0x02000000) or 0)+
	((int1%0x08000000>=0x04000000 and int2%0x08000000>=0x04000000 and 0x04000000) or 0)+
	((int1%0x10000000>=0x08000000 and int2%0x10000000>=0x08000000 and 0x08000000) or 0)+
	((int1%0x20000000>=0x10000000 and int2%0x20000000>=0x10000000 and 0x10000000) or 0)+
	((int1%0x40000000>=0x20000000 and int2%0x40000000>=0x20000000 and 0x20000000) or 0)+
	((int1%0x80000000>=0x40000000 and int2%0x80000000>=0x40000000 and 0x40000000) or 0)+
	((int1>=0x80000000 and int2>=0x80000000 and 0x80000000) or 0)

	return (int3 and band(ret, int3, ...)) or ret
end

local function bxor(int1, int2, int3, ...)
	local ret =
	((int1%0x00000002>=0x00000001 ~= (int2%0x00000002>=0x00000001) and 0x00000001) or 0)+
	((int1%0x00000004>=0x00000002 ~= (int2%0x00000004>=0x00000002) and 0x00000002) or 0)+
	((int1%0x00000008>=0x00000004 ~= (int2%0x00000008>=0x00000004) and 0x00000004) or 0)+
	((int1%0x00000010>=0x00000008 ~= (int2%0x00000010>=0x00000008) and 0x00000008) or 0)+
	((int1%0x00000020>=0x00000010 ~= (int2%0x00000020>=0x00000010) and 0x00000010) or 0)+
	((int1%0x00000040>=0x00000020 ~= (int2%0x00000040>=0x00000020) and 0x00000020) or 0)+
	((int1%0x00000080>=0x00000040 ~= (int2%0x00000080>=0x00000040) and 0x00000040) or 0)+
	((int1%0x00000100>=0x00000080 ~= (int2%0x00000100>=0x00000080) and 0x00000080) or 0)+
	((int1%0x00000200>=0x00000100 ~= (int2%0x00000200>=0x00000100) and 0x00000100) or 0)+
	((int1%0x00000400>=0x00000200 ~= (int2%0x00000400>=0x00000200) and 0x00000200) or 0)+
	((int1%0x00000800>=0x00000400 ~= (int2%0x00000800>=0x00000400) and 0x00000400) or 0)+
	((int1%0x00001000>=0x00000800 ~= (int2%0x00001000>=0x00000800) and 0x00000800) or 0)+
	((int1%0x00002000>=0x00001000 ~= (int2%0x00002000>=0x00001000) and 0x00001000) or 0)+
	((int1%0x00004000>=0x00002000 ~= (int2%0x00004000>=0x00002000) and 0x00002000) or 0)+
	((int1%0x00008000>=0x00004000 ~= (int2%0x00008000>=0x00004000) and 0x00004000) or 0)+
	((int1%0x00010000>=0x00008000 ~= (int2%0x00010000>=0x00008000) and 0x00008000) or 0)+
	((int1%0x00020000>=0x00010000 ~= (int2%0x00020000>=0x00010000) and 0x00010000) or 0)+
	((int1%0x00040000>=0x00020000 ~= (int2%0x00040000>=0x00020000) and 0x00020000) or 0)+
	((int1%0x00080000>=0x00040000 ~= (int2%0x00080000>=0x00040000) and 0x00040000) or 0)+
	((int1%0x00100000>=0x00080000 ~= (int2%0x00100000>=0x00080000) and 0x00080000) or 0)+
	((int1%0x00200000>=0x00100000 ~= (int2%0x00200000>=0x00100000) and 0x00100000) or 0)+
	((int1%0x00400000>=0x00200000 ~= (int2%0x00400000>=0x00200000) and 0x00200000) or 0)+
	((int1%0x00800000>=0x00400000 ~= (int2%0x00800000>=0x00400000) and 0x00400000) or 0)+
	((int1%0x01000000>=0x00800000 ~= (int2%0x01000000>=0x00800000) and 0x00800000) or 0)+
	((int1%0x02000000>=0x01000000 ~= (int2%0x02000000>=0x01000000) and 0x01000000) or 0)+
	((int1%0x04000000>=0x02000000 ~= (int2%0x04000000>=0x02000000) and 0x02000000) or 0)+
	((int1%0x08000000>=0x04000000 ~= (int2%0x08000000>=0x04000000) and 0x04000000) or 0)+
	((int1%0x10000000>=0x08000000 ~= (int2%0x10000000>=0x08000000) and 0x08000000) or 0)+
	((int1%0x20000000>=0x10000000 ~= (int2%0x20000000>=0x10000000) and 0x10000000) or 0)+
	((int1%0x40000000>=0x20000000 ~= (int2%0x40000000>=0x20000000) and 0x20000000) or 0)+
	((int1%0x80000000>=0x40000000 ~= (int2%0x80000000>=0x40000000) and 0x40000000) or 0)+
	((int1>=0x80000000 ~= (int2>=0x80000000) and 0x80000000) or 0)

	return (int3 and bxor(ret, int3, ...)) or ret
end

local function bnot(int)
	return 4294967295 - int
end

local function rshift(int, by)
	local shifted = int / (2 ^ by)
	return shifted - shifted % 1
end

local function rrotate(int, by)
	local shifted = int / (2 ^ by)
	local fraction = shifted % 1
	return (shifted - fraction) + fraction * (2 ^ 32)
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
	local h = string.gsub(s, ".", function(c)
		return string.format("%02x", string.byte(c))
	end)
	return h
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
	for i = i, i + 3 do n = n*256 + string.byte(s, i) end
	return n
end

local function preproc(msg, len)
	local extra = 64 - ((len + 1 + 8) % 64)
	len = num2s(8 * len, 8)
	msg = msg .. "\128" .. string.rep("\0", extra) .. len
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
	for j = 1, 16 do w[j] = s232num(msg, i + (j - 1) * 4) end
	for j = 17, 64 do
		local v = w[j - 15]
		local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
		v = w[j - 2]
		local s1 = bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
		w[j] = w[j - 16] + s0 + w[j - 7] + s1
	end

	local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
	for i = 1, 64 do
		local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
		local maj = bxor(band(a, b), band(a, c), band(b, c))
		local t2 = s0 + maj
		local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
		local ch = bxor (band(e, f), band(bnot(e), g))
		local t1 = h + s1 + ch + k[i] + w[i]
		h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
	end

	H[1] = band(H[1], a)
	H[2] = band(H[2], b)
	H[3] = band(H[3], c)
	H[4] = band(H[4], d)
	H[5] = band(H[5], e)
	H[6] = band(H[6], f)
	H[7] = band(H[7], g)
	H[8] = band(H[8], h)
end

local function sha256(msg)
	msg = preproc(msg, #msg)
	local H = initH256({})
	for i = 1, #msg, 64 do digestblock(msg, i, H) end
	return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
		num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
end


--  -------- Firewolf API

local function isAdvanced()
	return term.isColor and term.isColor()
end

api.clearPage = function(site, color, redraw, tcolor)
	-- Site titles
	local titles = {firewolf = "Firewolf Homepage", server = "Server Management", 
		history = "Firewolf History", help = "Help Page", downloads = "Downloads Center", 
		settings = "Firewolf Settings", credits = "Firewolf Credits", getinfo = "Website Information",
		nomodem = "No Modem Attached!", crash = "Website Has Crashed!", overspeed = "Too Fast!", 
		incorrect = "Incorrect Website!"}
	local title = titles[site]

	-- Clear
	local c = color
	if c == nil then c = colors.black end
	term.setBackgroundColor(c)
	term.setTextColor(colors[theme["address-bar-text"]])
	if redraw ~= true then term.clear() end

	if not(menuBarOpen) then
		-- URL bar
		term.setCursorPos(2, 1)
		term.setBackgroundColor(colors[theme["address-bar-background"]])
		term.clearLine()
		term.setCursorPos(2, 1)
		local a = site
		if a:len() > w - 9 then a = a:sub(1, 39) .. "..." end
		if curProtocol == protocols.rdnt then write("rdnt://" .. a)
		elseif curProtocol == protocols.http then write("http://" .. a)
		end

		if title ~= nil then
			term.setCursorPos(w - title:len() - 1, 1)
			write(title)
		end
		term.setCursorPos(w, 1)
		term.setBackgroundColor(colors[theme["top-box"]])
		term.setTextColor(colors[theme["text-color"]])
		write("<")
		term.setBackgroundColor(c)
		if tcolor then term.setTextColor(tcolor)
		else term.setTextColor(colors.white) end
		print("")
	else
		term.setCursorPos(1, 1)
		term.setBackgroundColor(colors[theme["top-box"]])
		term.setTextColor(colors[theme["text-color"]])
		term.clearLine()
		write("> [- Exit Firewolf -] [- Incorrect Website -]      ")
		print("")
	end
end

api.centerPrint = function(text)
	local w, h = term.getSize()
	local x, y = term.getCursorPos()
	term.setCursorPos(math.ceil((w + 1)/2 - text:len()/2), y)
	print(text)
end

api.centerWrite = function(text)
	local w, h = term.getSize()
	local x, y = term.getCursorPos()
	term.setCursorPos(math.ceil((w + 1)/2 - text:len()/2), y)
	write(text)
end

api.leftPrint = function(text)
	local x, y = term.getCursorPos()
	term.setCursorPos(4, y)
	print(text)
end

api.leftWrite = function(text)
	local x, y = term.getCursorPos()
	term.setCursorPos(4, y)
	write(text)
end

api.rightPrint = function(text)
	local x, y = term.getCursorPos()
	local w, h = term.getSize()
	term.setCursorPos(w - text:len() - 1, y)
	print(text)
end

api.rightWrite = function(text)
	local x, y = term.getCursorPos()
	local w, h = term.getSize()
	term.setCursorPos(w - text:len() - 1, y)
	write(text)
end

api.redirect = function(url)
	os.queueEvent(event_redirect, url:gsub("rdnt://", ""):gsub("http://", ""))
end

api.prompt = function(list, dir)
	if isAdvanced() then
		for _, v in pairs(list) do
			if v.bg then term.setBackgroundColor(v.bg) end
			if v.tc then term.setTextColor(v.tc) end
			if v[2] == -1 then v[2] = math.ceil((w + 1)/2 - (v[1]:len() + 6)/2) end

			term.setCursorPos(v[2], v[3])
			write("[- " .. v[1])
			term.setCursorPos(v[2] + v[1]:len() + 3, v[3])
			write(" -]")
		end

		while true do
			local e, but, x, y = os.pullEvent()
			if e == "mouse_click" then
				for _, v in pairs(list) do
					if x >= v[2] and x <= v[2] + v[1]:len() + 5 and y == v[3] then
						return v[1]
					end
				end
			elseif e == event_exitWebsite then
				return nil
			end
		end
	else
		for _, v in pairs(list) do
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			if v[2] == -1 then v[2] = math.ceil((w + 1)/2 - (v[1]:len() + 4)/2) end

			term.setCursorPos(v[2], v[3])
			write("  " .. v[1])
			term.setCursorPos(v[2] + v[1]:len() + 2, v[3])
			write("  ")
		end

		local key1 = 200
		local key2 = 208
		if dir == "horizontal" then
			key1 = 203
			key2 = 205
		end

		local curSel = 1
		term.setCursorPos(list[curSel][2], list[curSel][3])
		write("[")
		term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
		write("]")

		while true do
			local e, key = os.pullEvent()
			term.setCursorPos(list[curSel][2], list[curSel][3])
			write(" ")
			term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
			write(" ")
			if e == "key" and key == key1 and curSel > 1 then
				curSel = curSel - 1
			elseif e == "key" and key == key2 and curSel < #list then
				curSel = curSel + 1
			elseif e == "key" and key == 28 then
				return list[curSel][1]
			elseif e == event_exitWebsite then
				return nil
			end
			term.setCursorPos(list[curSel][2], list[curSel][3])
			write("[")
			term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, list[curSel][3])
			write("]")
		end
	end
end

api.scrollingPrompt = function(list, x, y, len, width)
	local wid = width
	if wid == nil then wid = w - 3 end

	local function updateDisplayList(items, loc, len)
		local ret = {}
		for i = 1, len do
			local item = items[i + loc - 1]
			if item ~= nil then table.insert(ret, item) end
		end
		return ret
	end

	if isAdvanced() then
		local function draw(a)
			for i, v in ipairs(a) do
				term.setCursorPos(1, y + i - 1)
				api.centerWrite(string.rep(" ", wid + 2))
				term.setCursorPos(x, y + i - 1)
				write("[ " .. v:sub(1, wid - 5))
				term.setCursorPos(wid + x - 2, y + i - 1)
				write("  ]")
			end
		end

		local loc = 1
		local disList = updateDisplayList(list, loc, len)
		draw(disList)
		
		while true do
			local e, but, clx, cly = os.pullEvent()
			if e == "key" and but == 200 and loc > 1 then
				loc = loc - 1
				disList = updateDisplayList(list, loc, len)
				draw(disList)
			elseif e == "key" and but == 208 and loc + len - 1 < #list then
				loc = loc + 1
				disList = updateDisplayList(list, loc, len)
				draw(disList)
			elseif e == "mouse_scroll" and but > 0 and loc + len - 1 < #list then
				loc = loc + but
				disList = updateDisplayList(list, loc, len)
				draw(disList)
			elseif e == "mouse_scroll" and but < 0 and loc > 1 then
				loc = loc + but
				disList = updateDisplayList(list, loc, len)
				draw(disList)
			elseif e == "mouse_click" then
				for i, v in ipairs(disList) do
					if clx >= x and clx <= x + wid and cly == i + y - 1 then
						return v
					end
				end
			elseif e == event_exitWebsite then
				return nil
			end
		end
	else
		local function draw(a)
			for i, v in ipairs(a) do
				term.setCursorPos(1, y + i - 1)
				api.centerWrite(string.rep(" ", wid + 2))
				term.setCursorPos(x, y + i - 1)
				write("[ ] " .. v:sub(1, wid - 5))
			end
		end

		local loc = 1
		local curSel = 1
		local disList = updateDisplayList(list, loc, len)
		draw(disList)
		term.setCursorPos(x + 1, y + curSel - 1)
		write("x")

		while true do
			local e, key = os.pullEvent()
			term.setCursorPos(x + 1, y + curSel - 1)
			write(" ")
			if e == "key" and key == 200 then
				if curSel > 1 then
					curSel = curSel - 1
				elseif loc > 1 then
					loc = loc - 1
					disList = updateDisplayList(list, loc, len)
					draw(disList)
				end
			elseif e == "key" and key == 208 then
				if curSel < #disList then
					curSel = curSel + 1
				elseif loc + len - 1 < #list then
					loc = loc + 1
					disList = updateDisplayList(list, loc, len)
					draw(disList)
				end
			elseif e == "key" and key == 28 then
				return list[curSel + loc - 1]
			elseif e == event_exitWebsite then
				return nil
			end
			term.setCursorPos(x + 1, y + curSel - 1)
			write("x")
		end
	end
end

api.clearArea = function() api.clearPage(website) end
api.cPrint = function(text) api.centerPrint(text) end
api.cWrite = function(text) api.centerWrite(text) end
api.lPrint = function(text) api.leftPrint(text) end
api.lWrite = function(text) api.leftWrite(text) end
api.rPrint = function(text) api.rightPrint(text) end
api.rWrite = function(text) api.rightWrite(text) end

-- Set Environment
for k, v in pairs(getfenv(0)) do env[k] = v end
for k, v in pairs(getfenv(1)) do env[k] = v end
for k, v in pairs(env) do oldEnv[k] = v end
for k, v in pairs(api) do env[k] = v end
for k, v in pairs(env) do backupEnv[k] = v end
setfenv(1, env)


--  -------- Utilities

local function debugLog(n, ...)
	local lArgs = {...}
	if debugFile then
		if n == nil then n = "" end
		debugFile:write("\n" .. tostring(n) .. " : ")
		for k, v in pairs(lArgs) do 
			if type(v) == "string" or type(v) == "number" or type(v) == nil or 
					type(v) == "boolean" then
				debugFile:write(tostring(v) .. ", ")
			else debugFile:write("type-" .. type(v) .. ", ") end
		end
	end
end

local function modRead(replaceChar, his, maxLen, stopAtMaxLen, liveUpdates, exitOnControl)
	term.setCursorBlink(true)
	local line = ""
	local hisPos = nil
	local pos = 0
	if replaceChar then replaceChar = replaceChar:sub(1, 1) end
	local w, h = term.getSize()
	local sx, sy = term.getCursorPos()

	local function redraw(repl)
		local scroll = 0
		if line:len() >= maxLen then scroll = line:len() - maxLen end

		term.setCursorPos(sx, sy)
		local a = repl or replaceChar
		if a then term.write(string.rep(a, line:len() - scroll))
		else term.write(line:sub(scroll + 1)) end
		term.setCursorPos(sx + pos - scroll, sy)
	end

	while true do
		local e, but, x, y, p4, p5 = os.pullEvent()
		if e == "char" and not(stopAtMaxLen == true and line:len() >= maxLen) then
			line = line:sub(1, pos) .. but .. line:sub(pos + 1, -1)
			pos = pos + 1
			redraw()
		elseif e == "key" then
			if but == keys.enter then
				break
			elseif but == keys.left then
				if pos > 0 then pos = pos - 1 redraw() end
			elseif but == keys.right then
				if pos < line:len() then pos = pos + 1 redraw() end
			elseif (but == keys.up or but == keys.down) and his then
				redraw(" ")
				if but == keys.up then
					if hisPos == nil and #his > 0 then hisPos = #his
					elseif hisPos > 1 then hisPos = hisPos - 1 end
				elseif but == keys.down then
					if hisPos == #his then hisPos = nil
					elseif hisPos ~= nil then hisPos = hisPos + 1 end
				end

				if hisPos then
					line = his[hisPos]
					pos = line:len()
				else
					line = ""
					pos = 0
				end
				redraw()
				if liveUpdates then
					local a, data = liveUpdates(line, "update_history", nil, nil, nil, nil, nil)
					if a == true and data == nil then
						term.setCursorBlink(false)
						return line
					elseif a == true and data ~= nil then
						term.setCursorBlink(false)
						return data
					end
				end
			elseif but == keys.backspace and pos > 0 then
				redraw(" ")
				line = line:sub(1, pos - 1) .. line:sub(pos + 1, -1)
				pos = pos - 1
				redraw()
				if liveUpdates then
					local a, data = liveUpdates(line, "delete", nil, nil, nil, nil, nil)
					if a == true and data == nil then
						term.setCursorBlink(false)
						return line
					elseif a == true and data ~= nil then
						term.setCursorBlink(false)
						return data
					end
				end
			elseif but == keys.home then
				pos = 0
				redraw()
			elseif but == keys.delete and pos < line:len() then
				redraw(" ")
				line = line:sub(1, pos) .. line:sub(pos + 2, -1)
				redraw()
				if liveUpdates then
					local a, data = liveUpdates(line, "delete", nil, nil, nil, nil, nil)
					if a == true and data == nil then
						term.setCursorBlink(false)
						return line
					elseif a == true and data ~= nil then
						term.setCursorBlink(false)
						return data
					end
				end
			elseif but == keys["end"] then
				pos = line:len()
				redraw()
			elseif (but == 29 or but == 157) and not(exitOnControl) then 
				term.setCursorBlink(false)
				return nil
			end
		end if liveUpdates then
			local a, data = liveUpdates(line, e, but, x, y, p4, p5)
			if a == true and data == nil then
				term.setCursorBlink(false)
				return line
			elseif a == true and data ~= nil then
				term.setCursorBlink(false)
				return data
			end
		end
	end

	term.setCursorBlink(false)
	if line ~= nil then line = line:gsub("^%s*(.-)%s*$", "%1") end
	return line
end


--  -------- Graphics and Files

graphics.githubImage = [[
f       f 
fffffffff 
fffffffff 
f4244424f 
f4444444f 
fffffefffe
   fffe e 
 fffff e  
ff f fe e 
     e   e
]]

files.availableThemes = [[
https://raw.github.com/1lann/firewolf/master/themes/default.txt| |Fire (default)
https://raw.github.com/1lann/firewolf/master/themes/ice.txt| |Ice
https://raw.github.com/1lann/firewolf/master/themes/carbon.txt| |Carbon
https://raw.github.com/1lann/firewolf/master/themes/christmas.txt| |Christmas
https://raw.github.com/1lann/firewolf/master/themes/original.txt| |Original
https://raw.github.com/1lann/firewolf/master/themes/ocean.txt| |Ocean
https://raw.github.com/1lann/firewolf/master/themes/forest.txt| |Forest
https://raw.github.com/1lann/firewolf/master/themes/pinky.txt| |Pinky
]]

files.defaultTheme = [[
address-bar-text=white
address-bar-background=gray
address-bar-base=lightGray
top-box=red
bottom-box=orange
background=gray
text-color=white
]]

files.newTheme = [[
-- Text color of the address bar
address-bar-text=

-- Background color of the address bar
address-bar-background=

-- Color of separator bar when live searching
address-bar-base=

-- Top box color
top-box=

-- Bottom box color
bottom-box=

-- Background color
background=

-- Main text color
text-color=

]]

files.blacklist = {}

files.whitelist = {}

files.downloads = {}

files.antivirusDefinitions = {{"shell.", "Modify Filesystem"}, 
	{"fs.", "Modify Files"}, {"io.", "Modify Files"}, {"os.run", "Run Files"}, 
	{"io[", "Modify Files"}, {"fs[", "Modify Files"}, {"fs)", "Modify Files"}, 
	{"io)", "Modify Files"}, {"os)", "Run Files"}, {"loadstring", "Execute Text"}, 
	{"fs--", "Modify Files"}, {"io--", "Modify Files"}, {"os--", "Run Files"}, 
	{"fsor", "Modify Files"}, {"fs,", "Modify Files"}, {"io,", "Modify Files"}, 
	{"ioor", "Modify Files"}, {"osor", "Run Files"}, {"shell[", "Run Files"}, 
	{"os[\"run", "Run Files"}, {"loadstring", "Run Files"}, {"loadfile", "Run Files"}, 
	{"dofile", "Run Files"}, {"getfenv", "Modify Env"}, {"setfenv", "Modify Env"}, 
	{"rawset", "Modify Anything"}, {"_g", "Modify Env"}, {"_G", "Modify Env"}}


--  -------- Themes

local defaultTheme = {["address-bar-text"] = "white", ["address-bar-background"] = "gray", 
	["address-bar-base"] = "lightGray", ["top-box"] = "red", ["bottom-box"] = "orange", 
	["text-color"] = "white", ["background"] = "gray"}
local originalTheme = {["address-bar-text"] = "white", ["address-bar-background"] = "black", 
	["address-bar-base"] = "black", ["top-box"] = "black", ["bottom-box"] = "black", 
	["text-color"] = "white", ["background"] = "black"}

local function loadTheme(path)
	if fs.exists(path) and not(fs.isDir(path)) then
		local a = {}
		local f = io.open(path, "r")
		local l = f:read("*l")
		while l ~= nil do
			l = l:gsub("^%s*(.-)%s*$", "%1")
			if l ~= "" and l ~= nil and l ~= "\n" and l:sub(1, 2) ~= "--" then
				local b = l:find("=")
				if a and b then
					local c = l:sub(1, b - 1)
					local d = l:sub(b + 1, -1)
					if c == "" or d == "" then return nil
					else a[c] = d end
				else return nil end
			end
			l = f:read("*l")
		end
		f:close()

		return a
	else
		return nil
	end
end


--  -------- Filesystem

local function download(url, path)
	for i = 1, 3 do
		local response = http.get(url)
		if response then
			local data = response.readAll()
			response.close()
			if path then
				local f = io.open(path, "w")
				f:write(data)
				f:close()
			end
			return true
		end
	end

	return false
end

local function updateClient()
	local ret = false
	local source = nil
	http.request(firewolfURL)
	local a = os.startTimer(15)
	while true do
		local e, url, handle = os.pullEvent()
		if e == "http_success" then
			source = handle
			ret = true
			break
		elseif e == "http_failure" then
			ret = false
			break
		elseif e == "timer" and url == a then
			ret = false
			break
		end
	end

	if not(ret) then
		sleep(0.5)
		if isAdvanced() then
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["background"]])
			term.clear()
			local f = io.open(rootFolder .. "/temp_file", "w")
			f:write(graphics.githubImage)
			f:close()
			local a = paintutils.loadImage(rootFolder .. "/temp_file")
			paintutils.drawImage(a, 5, 5)
			fs.delete(rootFolder .. "/temp_file")

			term.setCursorPos(19, 4)
			term.setBackgroundColor(colors[theme["top-box"]])
			write(string.rep(" ", 32))
			term.setCursorPos(19, 5)
			write("  Could Not Connect to GitHub!  ")
			term.setCursorPos(19, 6)
			write(string.rep(" ", 32))
			term.setBackgroundColor(colors[theme["bottom-box"]])
			term.setCursorPos(19, 8)
			write(string.rep(" ", 32))
			term.setCursorPos(19, 9)
			write("    Sorry, Firewolf could not   ")
			term.setCursorPos(19, 10)
			write(" connect to GitHub to download  ")
			term.setCursorPos(19, 11)
			write(" necessary files. Please check: ")
			term.setCursorPos(19, 12)
			write("    http://status.github.com    ")
			term.setCursorPos(19, 13)
			write(string.rep(" ", 32))
			term.setCursorPos(19, 14)
			write("        Click to exit...        ")
			term.setCursorPos(19, 15)
			write(string.rep(" ", 32))
			os.pullEvent("mouse_click")
		else
			term.clear()
			term.setCursorPos(1, 1)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			print("\n")
			centerPrint("Could not connect to GitHub!")
			print("")
			centerPrint("Sorry, Firewolf could not connect to")
			centerPrint("GitHub to download necessary files.")
			centerPrint("Please check:")
			centerPrint("http://status.github.com")
			print("")
			centerPrint("Press any key to exit...")
			os.pullEvent("key")
		end

		return true
	elseif source and autoupdate == "true" then
		local b = io.open(firewolfLocation, "r")
		local new = source.readAll()
		local cur = b:read("*a")
		source.close()
		b:close()

		if cur ~= new then
			fs.delete(firewolfLocation)
			local f = io.open(firewolfLocation, "w")
			f:write(new)
			f:close()
			shell.run(firewolfLocation)
			return true
		else
			return false
		end
	end
end

local function migrateFilesystem()
	if fs.exists("/.Firefox_Data") then
		fs.move("/.Firefox_Data", rootFolder)
		fs.delete(serverSoftwareLocation)
	end

	fs.delete(rootFolder .. "/database")
end

local function resetFilesystem()
	-- Folders
	if not(fs.exists(rootFolder)) then fs.makeDir(rootFolder)
	elseif not(fs.isDir(rootFolder)) then fs.move(rootFolder, "/old-firewolf-data-file") end
	if not(fs.exists(serverFolder)) then fs.makeDir(serverFolder) end
	if not(fs.exists(cacheFolder)) then fs.makeDir(cacheFolder) end

	-- Settings
	if not(fs.exists(settingsLocation)) then
		local f = io.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = "true", incog = "false", home = "firewolf"}))
		f:close()
	end

	-- History
	if not(fs.exists(historyLocation)) then
		local f = io.open(historyLocation, "w")
		f:write(textutils.serialize({}))
		f:close()
	end

	-- Server Software
	if not(fs.exists(serverSoftwareLocation)) then
		download(serverURL, serverSoftwareLocation)
	end

	-- Themes
	if isAdvanced() then
		local f = io.open(availableThemesLocation, "w")
		f:write(files.availableThemes)
		f:close()
		if not(fs.exists(themeLocation)) then
			local f = io.open(themeLocation, "w")
			f:write(files.defaultTheme)
			f:close()
		end
	else
		fs.delete(availableThemesLocation)
		fs.delete(themeLocation)
	end

	-- Databases
	for _, v in pairs({userWhitelist, userBlacklist}) do
		if not(fs.exists(v)) then
			local f = io.open(v, "w")
			f:write("")
			f:close()
		end
	end

	-- Temp file
	fs.delete(rootFolder .. "/temp_file")

	return nil
end

local function appendToHistory(site)
	if incognito == "false" then
		if site == "home" or site == "homepage" then 
			site = homepage 
		end if site ~= "exit" and site ~= "" and site ~= "history" and site ~= history[1] then
			local a = "rdnt://" .. site
			if curProtocol == protocols.http then a = "http://" .. site end
			table.insert(history, 1, a)

			local f = io.open(historyLocation, "w")
			f:write(textutils.serialize(history))
			f:close()
		end if site ~= addressBarHistory[#addressBarHistory] then
			table.insert(addressBarHistory, site)
		end
	end
end


--  -------- Databases

local function loadDatabases()
	blacklist = files.blacklist
	whitelist = files.whitelist
	downloads = files.downloads
	definitions = files.antivirusDefinitions

	if not(fs.exists(userBlacklist)) then 
		local bf = fio.open(userBlacklist, "w") 
		bf:write("\n") 
		bf:close()
	else
		local bf = io.open(userBlacklist, "r")
		local l = bf:read("*l")
		while l ~= nil do
			if l ~= nil and l ~= "" and l ~= "\n" then
				l = l:gsub("^%s*(.-)%s*$", "%1")
				table.insert(blacklist, l)
			end
			l = bf:read("*l")
		end
		bf:close()
	end

	if not(fs.exists(userWhitelist)) then 
		local wf = io.open(userWhitelist, "w") 
		wf:write("\n")
		wf:close()
	else
		local wf = io.open(userWhitelist, "r")
		local l = wf:read("*l")
		while l ~= nil do
			if l ~= nil and l ~= "" and l ~= "\n" then
				l = l:gsub("^%s*(.-)%s*$", "%1")
				local a, b = l:find("| |")
				table.insert(whitelist, {l:sub(1, a - 1), l:sub(b + 1, -1)})
			end
			l = wf:read("*l")
		end
		wf:close()
	end
end

local function verify(database, ...)
	local args = {...}
	if database == "blacklist" and #args >= 1 then
		-- id
		local found = false
		for _, v in pairs(blacklist) do
			if tostring(args[1]) == v then found = true end
		end

		return found
	elseif database == "whitelist" and #args >= 2 then
		-- id, site
		local found = false
		for _, v in pairs(whitelist) do
			if v[2] == tostring(args[1]) and v[1] == tostring(args[2]) then 
				found = true 
			end
		end

		return found
	elseif database == "antivirus" and #args >= 1 then
		-- content
		local a = verify("antivirus offences", args[1])
		if #a == 0 then return false
		else return true end
	elseif database == "antivirus offences" and #args >= 1 then
		-- content
		local c = args[1]:gsub(" ", ""):gsub("\n", ""):gsub("\t", "")
		local a = {}
		for _, v in pairs(definitions) do
			local b = false
			for _, c in pairs(a) do
				if c == v[2] then b = true end
			end

			if c:find(v[1], 1, true) and not(b) then
				table.insert(a, v[2])
			end
		end
		table.sort(a)

		return a
	else
		return nil
	end
end


--  -------- Protocols

protocols.http = {}
protocols.rdnt = {}

protocols.rdnt.getSearchResults = function()
	dnsDatabase = {[1] = {}, [2] = {}}
	local resultIDs = {}
	local conflict = {}

	rednet.broadcast("firewolf.broadcast.dns.list")
	local startClock = os.clock()
	while os.clock() - startClock < timeout do
		local id, i = rednet.receive(timeout)
		if id then
			if i:sub(1, 14) == "firewolf-site:" then
				i = i:sub(15, -1)
				local bl, wl = verify("blacklist", id), verify("whitelist", id, i)
				if not(i:find(" ")) and i:len() < 40 and (not(bl) or (bl and wl)) then
					if not(resultIDs[tostring(id)]) then resultIDs[tostring(id)] = 1
					else resultIDs[tostring(id)] = resultIDs[tostring(id)] + 1
					end
					
					if not(i:find("rdnt://")) then i = ("rdnt://" .. i) end
					local x = false
					if conflict[i] then
						x = true
						table.insert(conflict[i], id)
					else
						for m, n in pairs(dnsDatabase[1]) do
							if n:lower() == i:lower() then
								x = true
								table.remove(dnsDatabase[1], m)
								table.remove(dnsDatabase[2], m)
								if conflict[i] then
									table.insert(conflict[i], id)
								else
									conflict[i] = {}
									table.insert(conflict[i], id)
								end
								break
							end
						end
					end

					if not(x) and resultIDs[tostring(id)] <= 3 then
						table.insert(dnsDatabase[1], i)
						table.insert(dnsDatabase[2], id)
					end
				end
			end
		else
			break
		end
	end
	for k,v in pairs(conflict) do
		table.sort(v)
		table.insert(dnsDatabase[1], k)
		table.insert(dnsDatabase[2], v[1])
	end

	return dnsDatabase[1]
end

protocols.rdnt.getWebsite = function(site)
	local id, content, status = nil, nil, nil
	local clock = os.clock()
	local websiteID = nil
	for k, v in pairs(dnsDatabase[1]) do
		local web = site:gsub("rdnt://", "")
		if web:find("/") then web = web:sub(1, web:find("/") - 1) end
		if web == v:gsub("rdnt://", "") then
			websiteID = dnsDatabase[2][k]
			break
		end
	end
	if not(websiteID) then return nil, nil, nil end

	sleep(timeout)
	rednet.send(websiteID, site)
	clock = os.clock()
	while os.clock() - clock < timeout do
		id, content = rednet.receive(timeout)
		if id then
			if id == websiteID then
				local bl = verify("blacklist", id)
				local av = verify("antivirus", content)
				local wl = verify("whitelist", id, site)
				status = nil
				if (bl and not(wl)) or site == "" or site == "." or site == ".." then
					-- Ignore
				elseif av and not(wl) then
					status = "antivirus"
					break
				else
					status = "safe"
					break
				end
			end
		end
	end

	serverWebsiteID = id
	return id, content, status
end

protocols.http.getSearchResults = function(input)
	dnsDatabase = {[1] = {}, [2] = {}}
	return dnsDatabase[1]
end

protocols.http.getWebsite = function(site)
	return nil, nil, nil
end


--  -------- Built-In Websites

--  Homepage

local pages = {}
local errPages = {}

pages.firewolf = function(site)
	internalWebsite = true
	clearPage(site, colors[theme["background"]])
	print("")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 43))
	centerPrint([[         _,-='"-.__               /\_/\    ]])
	centerPrint([[          -.}        =._,.-==-._.,  @ @._, ]])
	centerPrint([[             -.__  __,-.   )       _,.-'   ]])
	centerPrint([[ Firewolf ]] .. version .. string.rep(" ", 8 - version:len()) ..
		[["     G..m-"^m m'        ]])
	centerPrint(string.rep(" ", 43))
	print("\n")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	centerPrint(string.rep(" ", 43))
	centerPrint("  News:                       [- Sites -]  ")
	centerPrint("  - Version 2.3.8 has just been released!  ")
	centerPrint("    Check it out on the forums! It has     ")
	centerPrint("    a massive overhaul of all the systems  ")
	centerPrint("  - Version 2.3.7 has been released! It    ")
	centerPrint("    includes a new mini menu and help!     ")
	centerPrint(string.rep(" ", 43))

	while true do
		local e, but, x, y = os.pullEvent()
		if e == "mouse_click" and x >= 35 and x <= 45 and y == 12 then
			redirect("sites")
			return
		elseif e == event_exitWebsite then
			os.queueEvent(event_exitWebsite)
			return
		end
	end
end

pages.firefox = function(site)
	redirect("firewolf")
end

pages.sites = function(site)
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("Firewolf Built-In Sites")
	centerPrint(string.rep(" ", 43))
	print("")

	local sx = 8
	term.setBackgroundColor(colors[theme["bottom-box"]])
	term.setCursorPos(1, sx - 1)
	centerPrint(string.rep(" ", 43))
	centerPrint("  rdnt://firewolf                Homepage  ")
	centerPrint("  rdnt://history                  History  ")
	centerPrint("  rdnt://downloads       Downloads Center  ")
	centerPrint("  rdnt://server         Server Management  ")
	centerPrint("  rdnt://help                   Help Page  ")
	centerPrint("  rdnt://settings                Settings  ")
	centerPrint("  rdnt://sites             Built-In Sites  ")
	centerPrint("  rdnt://credits                  Credits  ")
	centerPrint("  rdnt://exit                        Exit  ")
	centerPrint(string.rep(" ", 43))

	local a = {"firewolf", "history", "downloads", "server", "help", "settings", "sites", 
		"credits", "exit"}
	while true do
		local e, but, x, y = os.pullEvent()
		if e == "mouse_click" and x >= 7 and x <= 45 then
			for i, v in ipairs(a) do
				if y == sx + i - 1 then 
					redirect(v)
					return
				end
			end
		elseif e == event_exitWebsite then
			os.queueEvent(event_exitWebsite)
			return
		end
	end
end

--  History

pages.history = function(site)
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Firewolf History")
	centerPrint(string.rep(" ", 47))
	print("")
	term.setBackgroundColor(colors[theme["bottom-box"]])

	if #history > 0 then
		for i = 1, 12 do centerPrint(string.rep(" ", 47)) end

		local a = {"Clear History"}
		for i, v in ipairs(history) do table.insert(a, v) end
		local opt = scrollingPrompt(a, 6, 8, 10, 40)
		if opt == "Clear History" then
			history = {}
			addressBarHistory = {}
			local f = io.open(historyLocation, "w")
			f:write(textutils.serialize(history))
			f:close()

			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Firewolf History")
			centerPrint(string.rep(" ", 47))
			print("\n")
			term.setBackgroundColor(colors[theme["bottom-box"]])
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Cleared history.")
			centerPrint(string.rep(" ", 47))
			openAddressBar = false
			sleep(1.3)

			openAddressBar = true
			redirect("history")
			return
		elseif opt then
			if opt:find("http://") then curProtocol = protocols.http
			else curProtocol = protocols.rdnt
			end

			redirect(opt:gsub("rdnt://", ""):gsub("http://", ""))
			return
		elseif opt == nil then
			os.queueEvent(event_exitWebsite)
			return
		end
	else
		print("")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("No Items in History!")
		centerPrint(string.rep(" ", 47))
	end
end

--  Downloads Center

pages.downloads = function(site)
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Download Center")
	centerPrint(string.rep(" ", 47))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 5 do
		centerPrint(string.rep(" ", 47))
	end
	local opt = prompt({{"Themes", 7, 8}, {"Plugins", 7, 10}}, "vertical")
	if opt == "Themes" and isAdvanced() then
		while true do
			local themes = {}
			local c = {"Make my Own", "Load my Own"}
			local f = io.open(availableThemesLocation, "r")
			local l = f:read("*l")
			while l ~= nil do
				l = l:gsub("^%s*(.-)%s*$", "%1")
				local a, b = l:find("| |")
				table.insert(themes, {l:sub(1, a - 1), l:sub(b + 1, -1)})
				table.insert(c, l:sub(b + 1, -1))
				l = f:read("*l")
			end
			f:close()
			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Download Center - Themes")
			centerPrint(string.rep(" ", 47))
			print("")
			term.setBackgroundColor(colors[theme["bottom-box"]])
			for i = 1, 12 do centerPrint(string.rep(" ", 47)) end
			local t = scrollingPrompt(c, 4, 8, 10, 44)
			if t == nil then
				os.queueEvent(event_exitWebsite)
				return
			elseif t == "Make my Own" then
				term.setCursorPos(6, 18)
				write("Path: /")
				local n = modRead(nil, nil, 35)
				if n ~= "" and n ~= nil then
					n = "/" .. n
					local f = io.open(n, "w")
					f:write(ownThemeFileContent)
					f:close()

					term.setCursorPos(1, 18)
					centerWrite(string.rep(" ", 47))
					term.setCursorPos(6, 18)
					write("File Created!")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
				elseif n == nil then
					os.queueEvent(event_exitWebsite)
					return
				end
			elseif t == "Load my Own" then
				term.setCursorPos(6, 18)
				write("Path: /")
				local n = modRead(nil, nil, 35)
				if n ~= "" and n ~= nil then
					n = "/" .. n
					term.setCursorPos(1, 18)
					centerWrite(string.rep(" ", 47))
					
					if fs.exists(n) and not(fs.isDir(n)) then
						theme = loadTheme(n)
						if theme ~= nil then
							fs.delete(themeLocation)
							fs.copy(n, themeLocation)
							term.setCursorPos(6, 18)
							write("Theme File Loaded! :D")
						else
							term.setCursorPos(6, 18)
							write("Theme File is Corrupt! D:")
							theme = loadTheme(themeLocation)
						end
						openAddressBar = false
						sleep(1.1)
						openAddressBar = true
					elseif not(fs.exists(n)) then
						term.setCursorPos(6, 18)
						write("File does not exist!")
						openAddressBar = false
						sleep(1.1)
						openAddressBar = true
					elseif fs.isDir(n) then
						term.setCursorPos(6, 18)
						write("File is a directory!")
						openAddressBar = false
						sleep(1.1)
						openAddressBar = true
					end
				elseif n == nil then
					os.queueEvent(event_exitWebsite)
					return
				end
			else
				local url = ""
				for _, v in pairs(themes) do if v[2] == t then url = v[1] break end end
				term.setCursorPos(1, 4)
				term.setBackgroundColor(colors[theme["top-box"]])
				centerWrite(string.rep(" ", 47))
				centerWrite("Download Center - Downloading...")
				fs.delete(rootFolder .. "/temp_theme")
				download(url, rootFolder .. "/temp_theme")
				theme = loadTheme(rootFolder .. "/temp_theme")
				if theme == nil then
					theme = loadTheme(themeLocation)
					fs.delete(rootFolder .. "/temp_theme")
					centerWrite(string.rep(" ", 47))
					centerWrite("Download Center - Theme Is Corrupt! D:")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
				else
					fs.delete(themeLocation)
					fs.copy(rootFolder .. "/temp_theme", themeLocation)
					fs.delete(rootFolder .. "/temp_theme")
					centerWrite(string.rep(" ", 47))
					centerWrite("Download Center - Done! :D")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
					redirect("home")
					return
				end
			end
		end
	elseif opt == "Themes" and not(isAdvanced()) then
		clearPage(site, colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Download Center")
		centerPrint(string.rep(" ", 47))
		print("\n")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Themes are not available on normal")
		centerWrite(string.rep(" ", 47))
		centerPrint("computers! :(")
		centerPrint(string.rep(" ", 47))
	elseif opt == "Plugins" then
		clearPage(site, colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Download Center - Plugins")
		centerPrint(string.rep(" ", 47))
		print("\n")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Comming Soon! (hopefully :P)")
		centerPrint(string.rep(" ", 47))
		centerPrint(string.rep(" ", 47))
		centerPrint(string.rep(" ", 47))

		local opt = prompt({{"Back", -1, 11}}, "vertical")
		if opt == nil then
			os.queueEvent(event_exitWebsite)
			return
		elseif opt == "Back" then
			redirect("downloads")
		end
	elseif opt == nil then
		os.queueEvent(event_exitWebsite)
		return
	end
end

--  Server Management

local testingHTTP = false
local username, password = "", ""

local function validateCredentials(username, password)
	if not(testingHTTP) then
		local res = http.post(serverURL .. "/verify.php",
			"username=" .. textutils.urlEncode(username) .. "&" ..
			"password=" .. textutils.urlEncode(password))
		if res then
			local a = res.readAll()
			res.close()
			return a
		else
			return "false"
		end
	else
		return "true"
	end
end

local function registerAccount(username, password, repeatedPassword)
	if not(testingHTTP) then
		local res = http.post(serverURL .. "/verify.php",
			"username=" .. textutils.urlEncode(username) .. "&" ..
			"password=" .. textutils.urlEncode(password) .. "&" .. 
			"repeatedpassword=" .. textutils.urlEncode(repeatedPassword))
		if res then
			local a = res.readAll()
			res.close()
			return a
		else
			return "false"
		end
	else
		return "true"
	end
end

local function sitesForAccount(username, password)
	if not(testingHTTP) then

	else
		return {{url = "www.httptest.com", siteid = 0, online = "true"}}
	end
end

local function pagesForSite(username, password, url)
	if not(testingHTTP) then

	else
		return {{url = "www.httptest.com", pageid = 0, name = "test", content = "print(\"hai\")\n"}}
	end
end

local function downloadSite(username, password, loc, url, id)
	if not(testingHTTP) then

	else
		return "true"
	end
end

local function createSite(username, password, url)
	if not(testingHTTP) then

	else
		return "true"
	end
end

local function deletePages(username, password, url)
	if not(testingHTTP) then

	else
		return "true"
	end
end

local function updateSite(username, password, url, dataloc)
	if not(testingHTTP) then
		
	else
		return "true"
	end
end

local function deleteSite(username, password, url, id)
	if not(testingHTTP) then

	else
		return "true"
	end
end

local function setOnline(username, password, id, flag)
	if not(testingHTTP) then

	else
		return "true"
	end
end

local function manageServers(site, protocol, reloadServers, onNewServer, onStart, onEdit, onRunOnBoot, 
		onDelete, startServerName)
	local servers = reloadServers()

	if startServerName == nil then startServerName = "Start" end
	if isAdvanced() then
		local function draw(l, sel)
			term.setBackgroundColor(colors[theme["bottom-box"]])
			term.setCursorPos(4, 8)
			write("[- New Server -]")
			for i, v in ipairs(l) do
				term.setCursorPos(3, i + 8)
				write(string.rep(" ", 24))
				term.setCursorPos(4, i + 8)
				local nv = v
				if nv:len() > 18 then nv = nv:sub(1, 15) .. "..." end
				if i == sel then
					write("[ " .. nv .. " ]")
				else
					write("  " .. nv)
				end
			end
			if #l < 1 then
				term.setCursorPos(4, 10)
				write("A website is literally")
				term.setCursorPos(4, 11)
				write("just a lua script!")
				term.setCursorPos(4, 12)
				write("Go ahead and make one!")
				term.setCursorPos(4, 14)
				write("Also, be sure to check")
				term.setCursorPos(4, 15)
				write("out Firewolf's APIs to")
				term.setCursorPos(4, 16)
				write("help you make your")
				term.setCursorPos(4, 17)
				write("site, at rdnt://help")
			end

			term.setCursorPos(30, 8)
			write(string.rep(" ", 19))
			term.setCursorPos(30, 8)
			if l[sel] then 
				local nl = l[sel]
				if nl:len() > 19 then nl = nl:sub(1, 16) .. "..." end
				write(nl)
			else write("No Server Selected!") end
			term.setCursorPos(30, 10)
			write("[- " .. startServerName .. " -]")
			term.setCursorPos(30, 12)
			write("[- Edit -]")
			term.setCursorPos(30, 14)
			if onRunOnBoot then write("[- Run on Boot -]") end
			term.setCursorPos(30, 16)
			write("[- Delete -]")
		end

		local function updateDisplayList(items, loc, len)
			local ret = {}
			for i = 1, len do
				local item = items[i + loc - 1]
				if item ~= nil then table.insert(ret, item) end
			end
			return ret
		end

		while true do
			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Firewolf Server Management - " .. protocol:upper())
			centerPrint(string.rep(" ", 47))
			print("")

			term.setBackgroundColor(colors[theme["bottom-box"]])
			for i = 1, 12 do
				term.setCursorPos(3, i + 6)
				write(string.rep(" ", 24))
				term.setCursorPos(29, i + 6)
				write(string.rep(" ", 21))
			end

			local sel = 1
			local loc = 1
			local len = 10
			local disList = updateDisplayList(servers, loc, len)
			draw(disList, sel)

			while true do
				local e, but, x, y = os.pullEvent()
				if e == "key" and but == 200 and #servers > 0 and loc > 1 then
					loc = loc - 1
					disList = updateDisplayList(servers, loc, len)
					draw(disList, sel)
				elseif e == "key" and but == 208 and #servers > 0 and loc + len - 1 < #servers then
					loc = loc + 1
					disList = updateDisplayList(servers, loc, len)
					draw(disList, sel)
				elseif e == "mouse_click" then
					if x >= 4 and x <= 25 then
						if y == 8 then
							onNewServer()
							servers = reloadServers()
							break
						elseif #servers > 0 then
							for i, v in ipairs(disList) do
								if y == i + 8 then 
									sel = i 
									draw(disList, sel)
								end
							end
						end
					elseif x >= 30 and x <= 40 and y == 10 and #servers > 0 then
						onStart(disList[sel])
						servers = reloadServers()
						break
					elseif x >= 30 and x <= 39 and y == 12 and #servers > 0 then
						onEdit(disList[sel])
						servers = reloadServers()
						break
					elseif x >= 30 and x <= 46 and y == 14 and #servers > 0 and onRunOnBoot then
						onRunOnBoot(disList[sel])
						term.setBackgroundColor(colors[theme["bottom-box"]])
						term.setCursorPos(32, 15)
						write("Will Run on Boot!")
						openAddressBar = false
						sleep(1.3)
						openAddressBar = true
						term.setCursorPos(32, 15)
						write(string.rep(" ", 18))
						break
					elseif x >= 30 and x <= 41 and y == 16 and #servers > 0 then
						onDelete(disList[sel])
						servers = reloadServers()
						break
					end
				elseif e == event_exitWebsite then return end
			end
		end
	else
		while true do
			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Firewolf Server Management - " .. protocol:upper())
			centerPrint(string.rep(" ", 47))
			print("")

			local a = {"New Server"}
			for _, v in pairs(servers) do table.insert(a, v) end
			local server = scrollingPrompt(a, 4, 8, 10)
			if server == nil then
				os.queueEvent(event_exitWebsite)
				return
			elseif server == "New Server" then
				onNewServer()
				servers = reloadServers()
			else
				term.setCursorPos(30, 8)
				write(server)
				local a = {{"Start", 30, 10}, {"Edit", 30, 12}, {"Run on Boot", 30, 13}, 
					{"Delete", 30, 14}, {"Back", 30, 16}}
				if not(onRunOnBoot) then
					a = {{"Start", 30, 10}, {"Edit", 30, 12}, {"Delete", 30, 14}, {"Back", 30, 16}}
				end
				local opt = prompt(a, "vertical")
				if opt == "Start" then
					onStart()
					servers = reloadServers()
				elseif opt == "Edit" then
					onEdit()
					servers = reloadServers()
				elseif opt == "Run on Boot" and onRunOnBoot then
					onRunOnBoot()
					term.setCursorPos(32, 17)
					write("Will Run on Boot!")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
				elseif opt == "Delete" then
					onDelete()
					servers = reloadServers()
				elseif opt == nil then return end
			end
		end
	end
end

local function editPages(dir)
	openAddressBar = false
	local oldLoc = shell.dir()
	local commandHis = {}
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)
	print("")
	print(" Server Shell Editing")
	print(" Type 'exit' to return to Firewolf.")
	print(" Note: The 'home' file is the index of your site.")
	print("")

	local allowed = {"move", "mv", "cp", "copy", "drive", "delete", "rm", "edit", 
		"eject", "exit", "help", "id", "monitor", "rename", "alias", "clear",
		"paint", "firewolf", "lua", "redstone", "rs", "redprobe", "redpulse", "programs",
		"redset", "reboot", "hello", "label", "list", "ls", "easter", "pastebin", "dir"}
	
	while true do
		shell.setDir(dir)
		term.setBackgroundColor(colors.black)
		if isAdvanced() then term.setTextColor(colors.yellow)
		else term.setTextColor(colors.white) end
		write("> ")
		term.setTextColor(colors.white)
		local line = read(nil, commandHis)
		table.insert(commandHis, line)

		local words = {}
		for m in string.gmatch(line, "[^ \t]+") do
			local a = m:gsub("^%s*(.-)%s*$", "%1")
			table.insert(words, a)
		end

		local com = words[1]
		if com == "exit" then
			break
		elseif com then
			local a = false
			for _, v in pairs(allowed) do
				if com == v then a = true break end
			end

			if a then
				term.setBackgroundColor(colors.black)
				term.setTextColor(colors.white)
				shell.run(com, unpack(words, 2))
			else
				term.setTextColor(colors.red)
				print("Program Not Allowed!")
			end
		end
	end
	shell.setDir(oldLoc)
	openAddressBar = true
end

local function newServer(onCreate)
	term.setBackgroundColor(colors[theme["background"]])
	for i = 1, 12 do
		term.setCursorPos(3, i + 6)
		write(string.rep(" ", 47))
	end

	term.setBackgroundColor(colors[theme["bottom-box"]])
	term.setCursorPos(1, 8)
	for i = 1, 8 do centerPrint(string.rep(" ", 47)) end
	term.setCursorPos(5, 9)
	write("Name: ")
	local name = modRead(nil, nil, 28, true)
	if name == nil then
		os.queueEvent(event_exitWebsite)
		return
	end
	term.setCursorPos(5, 11)
	write("URL:")
	term.setCursorPos(8, 12)
	write("rdnt://")
	local url = modRead(nil, nil, 33)
	if url == nil then
		os.queueEvent(event_exitWebsite)
		return
	end
	url = url:gsub(" ", "")

	local a = {"/", "| |", " ", "@", "!", "$", "#", "%", "^", "&", "*", "(", ")", "rdnt://",
		"[", "]", "{", "}", "\\", "\"", "'", ":", ";", "?", "<", ">", ",", "`", "http://"}
	local b = false
	for k, v in pairs(a) do
		if url:find(v, 1, true) then
			term.setCursorPos(5, 14)
			write("URL Contains Illegal '" .. v .. "'!")
			openAddressBar = false
			sleep(1.5)
			openAddressBar = true
			b = true
			break
		elseif name == "" or url == "" then
			term.setCursorPos(5, 14)
			write("URL or Name Is Empty!")
			openAddressBar = false
			sleep(1.5)
			openAddressBar = true
			b = true
			break
		end
	end

	if not(b) then
		local c = onCreate(name, url)

		term.setCursorPos(5, 14)
		if c and c == "true" then
			write("Successfully Created Server!")
		elseif c == "false" or c == nil then
			write("Server Creation Failed!")
		else
			write(c)
		end
		openAddressBar = false
		sleep(1.5)
		openAddressBar = true
	end
end

local function serverHTTP(site, auser, apass)
	if auser == nil or apass == nil then
		clearPage(site, colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("\n")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint("Firewolf Server Management - HTTP")
		centerPrint(string.rep(" ", 47))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		centerPrint(string.rep(" ", 47))
		centerWrite("Welcome to Firewolf HTTP Management")
		for i = 1, 7 do centerPrint(string.rep(" ", 47)) end

		local opt = prompt({{"Login", w/2 - 15, 9}, {"Register", w/2 + 3, 9}}, "horizontal")
		if opt == "Login" then
			term.setCursorPos(4, 11)
			write("Username: ")
			local user = modRead(nil, nil, 28, true)
			if user == nil then	return end

			term.setCursorPos(4, 12)
			write("Password: ")
			local pass = sha256(modRead("*", nil, 28, true))
			if pass == nil then return end

			local a = validateCredentials(user, pass)
			term.setCursorPos(1, 14)
			if a == "true" then
				centerWrite("Login Successful!")
				openAddressBar = false
				sleep(1.5)
				openAddressBar = true
				username, password = user, pass
			else
				if a == "false" then centerWrite("Invalid Credentials!")
				else centerWrite(a) end
				openAddressBar = false
				sleep(1.5)
				openAddressBar = true
				serverHTTP(site)
				return
			end
		elseif opt == "Register" then
			term.setCursorPos(4, 11)
			write("New Username: ")
			local nuser = modRead(nil, nil, 28, true)
			if nuser == nil then return end

			term.setCursorPos(4, 12)
			write("New Password: ")
			local npass = sha256(modRead("*", nil, 28, true))
			if npass == nil then return end

			term.setCursorPos(4, 13)
			write("Password Again: ")
			local npassagain = sha256(modRead("*", nil, 28, true))
			if npassagain == nil then return end

			local a = registerAccount(nuser, npass, npassagain)
			term.setCursorPos(1, 14)
			if a == "true" then
				centerWrite("Login Successful!")
				openAddressBar = false
				sleep(1.5)
				openAddressBar = true
				username, password = nuser, npass
			else
				if a == "false" then centerWrite("Account Creation Failed!")
				else centerWrite(a) end
				openAddressBar = false
				sleep(1.5)
				openAddressBar = true
				serverHTTP(site)
				return
			end
		elseif opt == nil then return end
	else
		username, password = auser, apass
	end

	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Firewolf Server Management - HTTP")
	centerPrint(string.rep(" ", 47))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	local sites = sitesForAccount(username, password)
	if type(sites) == "table" then
		manageServers(site, "http", function()
			sites = sitesForAccount(username, password)
			local a = {}
			for _, v in pairs(sites) do table.insert(a, v.url) end
			return a
		end, function()
			newServer(function(name, url)
				return createSite(username, password, url)
			end)
		end, function(server)
			local data = nil
			for _, v in pairs(sites) do if v.url == url then data = v end end

			local new = "true"
			if v.online == "true" then new = "false" end
			setOnline(username, password, v.id, new)
		end, function(server)
			local data = nil
			for _, v in pairs(sites) do if v.url == url then data = v end end

			fs.delete(rootFolder .. "/temp_dir")
			fs.makeDir(rootFolder .. "/temp_dir")
			local a = downloadSite(username, password, rootFolder .. "/temp_dir", v.url, v.id)
			editPages(rootFolder .. "/temp_dir")
			updateSite(username, password, server, rootFolder .. "/temp_dir")
			fs.delete(rootFolder .. "/temp_dir")
			openAddressBar = true
		end, nil, function(server)
			local data = nil
			for _, v in pairs(sites) do if v.url == url then data = v end end
			deleteSite(username, password, data.siteid)
		end)
	else
		for i = 1, 7 do centerPrint(string.rep(" ", 47)) end
		term.setCursorPos(1, 8)
		centerWrite("A Server Error Has Occured!")
		term.setCursorPos(1, 10)
		centerWrite(tostring(sites))

		local opt = prompt({{"Try Again", -1, 12}}, "vertical")
		if opt == "Try Again" then
			serverHTTP(site, username, password)
			return
		elseif opt == nil then return end
	end
end

local function serverRDNT(site)
	manageServers(site, "rdnt", function()
		local servers = {}
		for _, v in pairs(fs.list(serverFolder)) do
			if fs.isDir(serverFolder .. "/" .. v) then table.insert(servers, v) end
		end

		return servers
	end, function()
		newServer(function(name, url)
			if fs.exists(serverFolder .. "/" .. url) then
				return "Server Already Exists!"
			end

			fs.makeDir(serverFolder .. "/" .. url)
			local f = io.open(serverFolder .. "/" .. url .. "/home", "w")
			f:write("print(\"\")\ncenterPrint(\"Welcome To " .. name .. "!\")\n")
			f:close()
			return "true"
		end)
	end, function(server)
		term.clear()
		term.setCursorPos(1, 1)
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		openAddressBar = false
		setfenv(1, oldEnv)
		shell.run(serverSoftwareLocation, server, serverFolder .. "/" .. server)
		setfenv(1, env)
		openAddressBar = true
		errPages.checkForModem()
	end, function(server)
		editPages(serverFolder .. "/" .. server)
		openAddressBar = true
	end, function(server)
		fs.delete("/old-startup")
		if fs.exists("/startup") then fs.move("/startup", "/old-startup") end
		local f = io.open("/startup", "w")
		f:write("shell.run(\"" .. serverSoftwareLocation .. "\", \"" .. 
			server .. "\", \"" .. serverFolder .. "/" .. server .. "\")")
		f:close()
	end, function(server)
		fs.delete(serverFolder .. "/" .. server)
	end)
end

pages.server = function(site)
	if curProtocol == protocols.rdnt then
		serverRDNT(site)
	elseif curProtocol == protocols.http then
		serverHTTP(site)
	end
end

--  Help Page

pages.help = function(site)
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	print("")
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Firewolf Help")
	centerPrint(string.rep(" ", 47))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	for i = 1, 12 do centerPrint(string.rep(" ", 47)) end
	term.setCursorPos(7, 15)
	write("View the full documentation here:")
	term.setCursorPos(7, 16)
	write("https://github.com/1lann/Firewolf/wiki")

	local opt = prompt({{"Getting Started", 7, 8}, {"Making a Theme", 7, 10}, 
		{"API Documentation", 7, 12}}, "vertical")
	local pages = {}
	if opt == "Getting Started" then
		pages[1] = {title = "Getting Started - Intoduction", content = {
			"Hey there!", 
			"",
			"Firewolf is an app that allows you to create", 
			"and visit websites! Each site has name (the",
			"URL) which you can type into the address bar",
			"above, and then visit the site.",
		}} pages[2] = {title = "Getting Started - Searching", content = {
			"The address bar can be also be used to",
			"search for sites, by simply typing in the",
			"search term.",
			"",
			"To view all sites, just open it and hit",
			"enter (leave the field blank)."
		}} pages[3] = {title = "Getting Started - Built-In Websites", content = {
			"Firewolf has a set of built-in websites", 
			"available for use:",
			"",
			"rdnt://firewolf   Normal hompage",
			"rdnt://history    Your history",
			"rdnt://downloads  Download themes and plugins",
			"rdnt://server     Create websites",
			"rdnt://help       Help and documentation"
		}} pages[4] = {title = "Getting Started - Built-In Websites", content = {
			"More built-in websites:",
			"",
			"rdnt://settings   Firewolf settings",
			"rdnt://credits    View the credits",
			"rdnt://exit       Exit the app"
		}}
	elseif opt == "Making a Theme" then
		pages[1] = {title = "Making a Theme - Introduction", content = {
			"Firewolf themes are files that tell Firewolf",
			"to color things certain colors.",
			"Several themes can already be downloaded for",
			"Firewolf from the Download Center.",
			"",
			"You can also make your own theme, use it in",
			"your copy of Firewolf, and submit it to the",
			"Firewolf Download Center!"
		}} pages[2] = {title = "Making a Theme - Example", content = {
			"A theme file consists of several lines of",
			"text. Here is the default theme file:",
			"",
			"address-bar-text=white",
			"address-bar-background=gray",
			"top-box=red",
			"bottom-box=orange",
			"background=gray",
			"text-color=white"
		}} pages[3] = {title = "Making a Theme - Explanation", content = {
			"On each line of the example, something is",
			"given a color, like on the last line, the",
			"text of the page is told to be white.",
			"",
			"The color specified after the = is the same",
			"as when you call colors.[color name].",
			"For example, specifying red after the =",
			"colors that object red."
		}} pages[4] = {title = "Making a Theme - Have a Go", content = {
			"To make a theme, go to rdnt://downloads,",
			"click on the themes section, and click on",
			"'Create my Own'.",
			"",
			"Enter a theme name, then exit Firewolf and",
			"edit the newly create file in the root",
			"folder. Specify the colors for the keys,",
			"and return to the themes section of the",
			"downloads center. Click 'Load my Own'."
		}} pages[5] = {title = "Making a Theme - Submitting", content = {
			"To submit a theme to the Downloads Center,",
			"send GravityScore a message on the CCForums",
			"that contains your theme file and name.",
			"",
			"He will message you back saying whether your",
			"theme has been added, or if anything needs to",
			"be changed before it is added."
		}}
	elseif opt == "API Documentation" then
		pages[1] = {title = "API Documentation - 1", content = {
			"The Firewolf API is a bunch of global",
			"functions that aim to simplify your life when",
			"designing and coding websites.",
			"",
			"For a full documentation on these functions,",
			"visit the Firewolf Wiki Page here:",
			"https://github.com/1lann/Firewolf/wiki"
		}} pages[2] = {title = "API Documentation - 2", content = {
			"centerPrint(string text)",
			"cPrint(string text)",
			"centerWrite(string text)",
			"cWrite(string text)",
			"",
			"leftPrint(string text)",
			"lPrint(string text)",
		}} pages[3] = {title = "API Documentation - 3", content = {
			"leftWrite(string text)",
			"lWrite(string text)",
			"",
			"rightPrint(string text)",
			"rPrint(string text)",
			"rightWrite(string text)",
			"rWrite(string text)"
		}} pages[4] = {title = "API Documentation - 4", content = {
			"prompt(table list, string direction)",
			"scrollingPrompt(table list, integer x,",
			"   integer y, integer length[,",
			"   integer width])",
			"",
			"urlDownload(string url)",
			"pastebinDownload(string code)",
			"redirect(string site)",
		}} pages[5] = {title = "API Documentation - 5", content = {
			"loadImageFromServer(string imagePath)",
			"ioReadFileFromServer(string filePath)",
			"",
			"Full documentation can be found here:",
			"https://github.com/1lann/Firewolf/wiki"
		}}
	elseif opt == nil then
		os.queueEvent(event_exitWebsite)
		return
	end

	local function drawPage(page)
		clearPage(site, colors[theme["background"]])
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		print("")
		centerPrint(string.rep(" ", 47))
		centerWrite(string.rep(" ", 47))
		centerPrint(page.title)
		centerPrint(string.rep(" ", 47))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 12 do centerPrint(string.rep(" ", 47)) end
		for i, v in ipairs(page.content) do
			term.setCursorPos(4, i + 7)
			write(v)
		end
	end

	local curPage = 1
	local a = {{"Prev", 26, 18}, {"Next", 38, 18}, {"Back",  14, 18}}
	drawPage(pages[curPage])

	while true do
		local b = {a[3]}
		if curPage == 1 then table.insert(b, a[2])
		elseif curPage == #pages then table.insert(b, a[1])
		else table.insert(b, a[1]) table.insert(b, a[2]) end

		local opt = prompt(b, "horizontal")
		if opt == "Prev" then
			curPage = curPage - 1
		elseif opt == "Next" then
			curPage = curPage + 1
		elseif opt == "Back" then
			break
		elseif opt == nil then
			os.queueEvent(event_exitWebsite)
			return
		end

		drawPage(pages[curPage])
	end

	redirect("help")
end

--  Settings

pages.settings = function(site)
	while true do
		clearPage(site, colors[theme["background"]])
		print("")
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		centerPrint(string.rep(" ", 43))
		centerWrite(string.rep(" ", 43))
		centerPrint("Firewolf Settings")
		centerWrite(string.rep(" ", 43))
		centerPrint("Designed For: " .. serverList[serverID])
		centerPrint(string.rep(" ", 43))
		print("")

		local a = "Automatic Updating - On"
		if autoupdate == "false" then a = "Automatic Updating - Off" end
		local b = "Record History - On"
		if incognito == "true" then b = "Record History - Off" end
		local c = "Homepage - rdnt://" .. homepage

		term.setBackgroundColor(colors[theme["bottom-box"]])
		for i = 1, 11 do centerPrint(string.rep(" ", 43)) end
		local opt = prompt({{a, 7, 9}, {b, 7, 11}, {c, 7, 13}, 
			 {"Reset Firewolf", 7, 17}}, "vertical")
		if opt == a then
			if autoupdate == "true" then autoupdate = "false"
			elseif autoupdate == "false" then autoupdate = "true" end
		elseif opt == b then
			if incognito == "true" then incognito = "false"
			elseif incognito == "false" then incognito = "true" end
		elseif opt == c then
			term.setCursorPos(9, 15)
			write("rdnt://")
			local a = modRead(nil, nil, 30)
			if a == nil then
				os.queueEvent(event_exitWebsite)
				return
			end
			if a ~= "" then homepage = a end
		elseif opt == "Reset Firewolf" then
			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Reset Firewolf")
			centerPrint(string.rep(" ", 43))
			print("")
			term.setBackgroundColor(colors[theme["bottom-box"]])
			for i = 1, 12 do centerPrint(string.rep(" ", 43)) end
			local opt = prompt({{"Reset History", 7, 8}, {"Reset Servers", 7, 9}, 
				{"Reset Theme", 7, 10}, {"Reset Cache", 7, 11}, {"Reset Databases", 7, 12}, 
				{"Reset Settings", 7, 13}, {"Back", 7, 14}, {"Reset All", 7, 16}}, "vertical")

			openAddressBar = false
			if opt == "Reset All" then
				fs.delete(rootFolder)
			elseif opt == "Reset History" then
				fs.delete(historyLocation)
			elseif opt == "Reset Servers" then
				fs.delete(serverFolder)
				fs.delete(serverSoftwareLocation)
			elseif opt == "Reset Cache" then
				fs.delete(cacheFolder)
			elseif opt == "Reset Databases" then
				fs.delete(userWhitelist)
				fs.delete(userBlacklist)
			elseif opt == "Reset Settings" then
				fs.delete(settingsLocation)
			elseif opt == "Reset Theme" then
				fs.delete(themeLocation)
			elseif opt == "Back" then
				openAddressBar = true
				redirect("settings")
				return
			elseif opt == nil then
				openAddressBar = true
				os.queueEvent(event_exitWebsite)
				return
			end

			clearPage(site, colors[theme["background"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Reset Firewolf")
			centerPrint(string.rep(" ", 43))
			print("")
			term.setCursorPos(1, 10)
			term.setBackgroundColor(colors[theme["bottom-box"]])
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Firewolf has been reset.")
			centerWrite(string.rep(" ", 43))
			if isAdvanced() then centerPrint("Click to exit...")
			else centerPrint("Press any key to exit...") end
			centerPrint(string.rep(" ", 43))
			while true do
				local e = os.pullEvent()
				if e == "mouse_click" or e == "key" then return true end
			end
		elseif opt == "Manage Blocked Servers" then
			openAddressBar = true
			clearPage(site, colors[theme["background"]])
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			print("")
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Manage Blocked Servers")
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Click on ID to remove server")
			centerPrint(string.rep(" ", 43))
			print("")
			for i = 1, 40 do
				centerPrint(string.rep(" ", 43))
			end
			local rBlacklist = {}
			local f = io.open(userBlacklist, "r")
			for line in f:lines() do
				if line ~= nil and line ~= "" and line ~= "\n" then
				line = line:gsub("^%s*(.-)%s*$", "%1")
				table.insert(rBlacklist, line)
			end
			end
			f:close()
			table.insert(rBlacklist, "Add Button Comming Soon!")
			while true do
				local opt = scrollingPrompt(rBlacklist, 7, 8, 10, 38)
				if opt == "Add Button Comming Soon!" then
				elseif opt == nil then
					return
				else
					table.remove(rBlacklist, opt)
					table.remove(blacklist, opt)
					local data = ""
					f = io.open(userBlacklist, "w")
					for k,v in pairs(rBlacklist) do
						data = ("\n" .. v)
					end
					f:write(data)
				end
			end
		elseif opt == nil then
			os.queueEvent(event_exitWebsite)
			return
		end

		-- Save
		local f = io.open(settingsLocation, "w")
		f:write(textutils.serialize({auto = autoupdate, incog = incognito, home = homepage}))
		f:close()
	end
end

--  Other

pages.credits = function(site)
	clearPage(site, colors[theme["background"]])
	print("\n")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("Firewolf Credits")
	centerPrint(string.rep(" ", 43))
	print("\n")
	term.setBackgroundColor(colors[theme["bottom-box"]])
	centerPrint(string.rep(" ", 43))
	centerPrint("   Coded by:      GravityScore and 1lann   ")
	centerPrint("   Art by:                     lieudusty   ")
	centerPrint(string.rep(" ", 43))
	centerPrint("   Based off:       RednetExplorer 2.4.1   ")
	centerPrint("              Made by ComputerCraftFan11   ")
	centerPrint(string.rep(" ", 43))
end

pages.kitteh = function(site)
	openAddressBar = false
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setCursorPos(1, 3)
	centerPrint([[       .__....._             _.....__,         ]])
	centerPrint([[         .": o :':         ;': o :".           ]])
	centerPrint([[         '. '-' .'.       .'. '-' .'           ]])
	centerPrint([[           '---'             '---'             ]])
	centerPrint([[                                               ]])
	centerPrint([[    _...----...    ...   ...    ...----..._    ]])
	centerPrint([[ .-'__..-""'----  '.  '"'  .'  ----'""-..__'-. ]])
	centerPrint([['.-'   _.--"""'     '-._.-'     '"""--._   '-.']])
	centerPrint([['  .-"'                :                '"-.  ']])
	centerPrint([[  '   '.            _.'"'._            .'   '  ]])
	centerPrint([[        '.     ,.-'"       "'-.,     .'        ]])
	centerPrint([[          '.                       .'          ]])
	centerPrint([[            '-._               _.-'            ]])
	centerPrint([[                '"'--.....--'"'                ]])
	print("")
	centerPrint("Firewolf Kitteh is Not Amused...")
	sleep(4)
	os.shutdown()
end

--  Error Pages

errPages.overspeed = function()
	website = "overspeed"
	clearPage("overspeed", colors[theme["background"]])
	print("\n")
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 43))
	centerWrite(string.rep(" ", 43))
	centerPrint("Warning! D:")
	centerPrint(string.rep(" ", 43))
	print("")

	term.setBackgroundColor(colors[theme["bottom-box"]])
	centerPrint(string.rep(" ", 43))
	centerPrint("  Website browsing sleep limit reached!    ")
	centerPrint(string.rep(" ", 43))
	centerPrint("  To prevent Firewolf from spamming        ")
	centerPrint("  rednet, Firewolf has stopped loading     ")
	centerPrint("  the page.                                ")
	centerPrint(string.rep(" ", 43))
	centerPrint(string.rep(" ", 43))
	centerPrint(string.rep(" ", 43))
	openAddressBar = false
	for i = 1, 5 do
		term.setCursorPos(1, 14)
		centerWrite(string.rep(" ", 43))
		if 6 - i == 1 then centerWrite("Please wait 1 second...")
		else centerWrite("Please wait " .. tostring(6 - i) .. " seconds...") end
		sleep(1)
	end
	openAddressBar = true

	term.setCursorPos(1, 14)
	centerWrite(string.rep(" ", 43))
	centerWrite("You may now browse normally...")
end

errPages.crash = function(err)
	if err:find("Firewolf Antivirus: Unauthorized Function") then
		clearPage("crash", colors[theme["background"]])
		print("")
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		centerPrint(string.rep(" ", 43))
		centerWrite(string.rep(" ", 43))
		centerPrint("Website Aborted!")
		centerPrint(string.rep(" ", 43))
		print("")
		term.setBackgroundColor(colors[theme["bottom-box"]])
		centerPrint(string.rep(" ", 43))
		centerPrint("  The website has attempted to use a       ")
		centerPrint("  potentially malicious function that you  ")
		centerPrint("  did not authorize! This might also be    ")
		centerPrint("  a mistake.                               ")
		centerPrint(string.rep(" ", 43))
		centerPrint("  Please ask 1lann or GravityScore if you  ")
		centerPrint("  have any questions about this.           ")
		centerPrint(string.rep(" ", 43))
		centerWrite(string.rep(" ", 43))
		centerPrint("You may now browse normally!")
		centerWrite(string.rep(" ", 43))
	else
		clearPage("crash", colors[theme["background"]])
		print("")
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["top-box"]])
		centerPrint(string.rep(" ", 43))
		centerWrite(string.rep(" ", 43))
		centerPrint("The Website Has Crashed! D:")
		centerPrint(string.rep(" ", 43))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		centerPrint(string.rep(" ", 43))
		centerPrint("  It looks like the website has crashed!   ")
		centerPrint("  Report this error to the website owner:  ")
		centerPrint(string.rep(" ", 43))
		term.setBackgroundColor(colors[theme["background"]])
		print("")
		print("  " .. err)
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		centerPrint(string.rep(" ", 43))
		centerWrite(string.rep(" ", 43))
		centerPrint("You may now browse normally!")
		centerPrint(string.rep(" ", 43))
	end
end

errPages.checkForModem = function()
	while true do
		local present = false
		for _, v in pairs(rs.getSides()) do
			if peripheral.getType(v) == "modem" then
				rednet.open(v)
				present = true
				break
			end
		end

		if not(present) then
			website = "nomodem"
			clearPage("nomodem", colors[theme["background"]])
			print("")
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("No Modem Attached! D:")
			centerPrint(string.rep(" ", 43))
			print("")

			term.setBackgroundColor(colors[theme["bottom-box"]])
			centerPrint(string.rep(" ", 43))
			centerPrint("  No wireless modem was found on this      ")
			centerPrint("  computer, and Firewolf is not able to    ")
			centerPrint("  run without one!                         ")
			centerPrint(string.rep(" ", 43))
			centerWrite(string.rep(" ", 43))
			centerPrint("Waiting for a modem to be attached...")
			centerWrite(string.rep(" ", 43))
			if isAdvanced() then centerPrint("Click to exit...")
			else centerPrint("Press any key to exit...") end
			centerPrint(string.rep(" ", 43))

			while true do
				local e, id = os.pullEvent()
				if e == "key" or e == "mouse_click" then return false
				elseif e == "peripheral" then break end
			end
		else
			return true
		end
	end
end

--  Run Pages

local function loadSite(site)
	local shellAllowed = false
	local function runSite(cacheLoc, antivirusEnv)
		if not(antivirusEnv) then
			antivirusEnv = {}
			nenv = {}
		end

		-- Clear
		clearPage(site, colors.black)
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)

		-- Setup environment
		local cbc, ctc = colors.black, colors.white
		local nenv = antivirusEnv
		local safeFunc = true
		local unsafeFunc = {}
		if antivirusEnv[1] ~= "firewolf-override" then
			unsafeFunc = {"os", "shell", "fs", "io", "loadstring", "loadfile", "dofile", 
				"getfenv", "setfenv", "rawset"}
		end
		for k, v in pairs(env) do 
			safeFunc = true
			for ki, vi in pairs(unsafeFunc) do
				if k == vi then safeFunc = false break end
			end
			if safeFunc then
				if type(v) ~= "table" then nenv[k] = v
				else
					nenv[k] = {}
					for i, d in pairs(v) do nenv[k][i] = d end
				end
			end
		end
		nenv.term = {}

		local function ospullEvent(a)
			if a == "derp" then return true end
			while true do
				local e, p1, p2, p3, p4, p5 = env.os.pullEventRaw()
				if e == event_exitWebsite then
					queueWebsiteExit = true
					env.error(event_exitWebsite)
				elseif e == "terminate" then
					env.error()
				end

				if e ~= event_exitWebsite and e ~= event_redirect and e ~= event_exitApp 
						and e ~= event_loadWebsite then
					if a then
						if e == a then return e, p1, p2, p3, p4, p5 end
					else return e, p1, p2, p3, p4, p5 end
				end
			end
		end

		nenv.term.getSize = function()
			local wid, hei = env.term.getSize()
			return wid, hei - 1
		end

		nenv.term.setCursorPos = function(x, y)
			if not(y > 0) then y = 1 end
			return env.term.setCursorPos(x, y + 1)
		end

		nenv.term.getCursorPos = function()
			local x, y = env.term.getCursorPos()
			return x, y + 1
		end

		nenv.term.clear = function()
			local x, y = env.term.getCursorPos()
			api.clearPage(website, cbc, nil, ctc)
			env.term.setCursorPos(x, y)
		end

		nenv.term.setBackgroundColor = function(col)
			cbc = col
			return env.term.setBackgroundColor(col)
		end

		nenv.term.setBackgroundColour = function(col)
			cbc = col
			return env.term.setBackgroundColour(col)
		end

		nenv.term.getBackgroundColor = function()
			return cbc
		end

		nenv.term.getBackgroundColour = function()
			return cbc
		end

		nenv.term.setTextColor = function(col)
			ctc = col
			return env.term.setTextColor(col)
		end

		nenv.term.setTextColour = function(col)
			ctc = col
			return env.term.setTextColour(col)
		end

		nenv.term.getTextColour = function()
			return ctc
		end

		nenv.term.getTextColor = function()
			return ctc
		end

		nenv.term.write = function(text)
			return env.term.write(text)
		end

		nenv.term.setCursorBlink = function(bool)
			return env.term.setCursorBlink(bool)
		end

		nenv.write = function(text)
			return env.write(text)
		end

		nenv.print = function(...)
			return env.print(...)
		end

		nenv.term.isColor = function()
			return isAdvanced()
		end

		nenv.term.isColour = function()
			return isAdvanced()
		end

		local oldScroll = term.scroll
		term.scroll = function(n)
			local x, y = env.term.getCursorPos()
			oldScroll(n)
			clearPage(website, cbc, true)
			env.term.setCursorPos(x, y)
		end

		nenv.prompt = function(list, dir)
			local fixPrompt = function(list, dir)
				if isAdvanced() then
					for _, v in pairs(list) do
						if v.bg then term.setBackgroundColor(v.bg) end
						if v.tc then term.setTextColor(v.tc) end
						if v[2] == -1 then v[2] = math.ceil((w + 1)/2 - (v[1]:len() + 6)/2) end

						term.setCursorPos(v[2], v[3])
						write("[- " .. v[1])
						term.setCursorPos(v[2] + v[1]:len() + 3, v[3])
						write(" -]")
					end

					while true do
						local e, but, x, y = ospullEvent()
						if e == "mouse_click" then
							for _, v in pairs(list) do
								if x >= v[2] and x <= v[2] + v[1]:len() + 5 and y == v[3] then
									return v[1]
								end
							end
						elseif e == event_exitWebsite then
							os.queueEvent(event_exitWebsite)
							return nil
						end
					end
				else
					for _, v in pairs(list) do
						term.setBackgroundColor(colors.black)
						term.setTextColor(colors.white)
						if v[2] == -1 then v[2] = math.ceil((w + 1)/2 - (v[1]:len() + 4)/2) end

						term.setCursorPos(v[2], v[3])
						write("  " .. v[1])
						term.setCursorPos(v[2] + v[1]:len() + 2, v[3])
						write("  ")
					end

					local key1 = 200
					local key2 = 208
					if dir == "horizontal" then
						key1 = 203
						key2 = 205
					end

					local curSel = 1
					term.setCursorPos(list[curSel][2], list[curSel][3])
					write("[")
					term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, 
						list[curSel][3])
					write("]")

					while true do
						local e, key = ospullEvent()
						term.setCursorPos(list[curSel][2], list[curSel][3])
						write(" ")
						term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, 
							list[curSel][3])
						write(" ")
						if e == "key" and key == key1 and curSel > 1 then
							curSel = curSel - 1
						elseif e == "key" and key == key2 and curSel < #list then
							curSel = curSel + 1
						elseif e == "key" and key == 28 then
							return list[curSel][1]
						elseif e == event_exitWebsite then
							os.queueEvent(event_exitWebsite)
							return nil
						end
						term.setCursorPos(list[curSel][2], list[curSel][3])
						write("[")
						term.setCursorPos(list[curSel][2] + list[curSel][1]:len() + 3, 
							list[curSel][3])
						write("]")
					end
				end
			end

			local a = {}
			for k, v in pairs(list) do
				local b, t = v.b, v.t
				if b == nil then b = cbg end
				if t == nil then t = ctc end
				table.insert(a, {v[1], v[2], v[3] + 1, bg = b, tc = t})
			end

			return fixPrompt(a, dir)
		end

		nenv.scrollingPrompt = function(list, x, y, len, width)
			local y = y + 1
			local wid = width
			if wid == nil then wid = w - 3 end

			local function updateDisplayList(items, loc, len)
				local ret = {}
				for i = 1, len do
					local item = items[i + loc - 1]
					if item ~= nil then table.insert(ret, item) end
				end
				return ret
			end

			if isAdvanced() then
				local function draw(a)
					for i, v in ipairs(a) do
						term.setCursorPos(1, y + i - 1)
						api.centerWrite(string.rep(" ", wid + 2))
						term.setCursorPos(x, y + i - 1)
						write("[ " .. v:sub(1, wid - 5))
						term.setCursorPos(wid + x - 2, y + i - 1)
						write("  ]")
					end
				end

				local loc = 1
				local disList = updateDisplayList(list, loc, len)
				draw(disList)
				
				while true do
					local e, but, clx, cly = ospullEvent()
					if e == "key" and but == 200 and loc > 1 then
						loc = loc - 1
						disList = updateDisplayList(list, loc, len)
						draw(disList)
					elseif e == "key" and but == 208 and loc + len - 1 < #list then
						loc = loc + 1
						disList = updateDisplayList(list, loc, len)
						draw(disList)
					elseif e == "mouse_scroll" and but > 0 and loc + len - 1 < #list then
						loc = loc + but
						disList = updateDisplayList(list, loc, len)
						draw(disList)
					elseif e == "mouse_scroll" and but < 0 and loc > 1 then
						loc = loc + but
						disList = updateDisplayList(list, loc, len)
						draw(disList)
					elseif e == "mouse_click" then
						for i, v in ipairs(disList) do
							if clx >= x and clx <= x + wid and cly == i + y - 1 then
								return v
							end
						end
					elseif e == event_exitWebsite then
						os.queueEvent(event_exitWebsite)
						return nil
					end
				end
			else
				local function draw(a)
					for i, v in ipairs(a) do
						term.setCursorPos(1, y + i - 1)
						api.centerWrite(string.rep(" ", wid + 2))
						term.setCursorPos(x, y + i - 1)
						write("[ ] " .. v:sub(1, wid - 5))
					end
				end

				local loc = 1
				local curSel = 1
				local disList = updateDisplayList(list, loc, len)
				draw(disList)
				term.setCursorPos(x + 1, y + curSel - 1)
				write("x")

				while true do
					local e, key = ospullEvent()
					term.setCursorPos(x + 1, y + curSel - 1)
					write(" ")
					if e == "key" and key == 200 then
						if curSel > 1 then
							curSel = curSel - 1
						elseif loc > 1 then
							loc = loc - 1
							disList = updateDisplayList(list, loc, len)
							draw(disList)
						end
					elseif e == "key" and key == 208 then
						if curSel < #disList then
							curSel = curSel + 1
						elseif loc + len - 1 < #list then
							loc = loc + 1
							disList = updateDisplayList(list, loc, len)
							draw(disList)
						end
					elseif e == "key" and key == 28 then
						return list[curSel + loc - 1]
					elseif e == event_exitWebsite then
						os.queueEvent(event_exitWebsite)
						return nil
					end
					term.setCursorPos(x + 1, y + curSel - 1)
					write("x")
				end
			end
		end

		nenv.loadImageFromServer = function(image)
			sleep(0.05)
			local mid, msgImage = curProtocol.getWebsite(site .. "/" .. image)
			if mid then
				local f = env.io.open(rootFolder .. "/temp_file", "w")
				f:write(msgImage)
				f:close()
				local rImage = env.paintutils.loadImage(rootFolder .. "/temp_file")
				fs.delete(rootFolder .. "/temp_file")
				return rImage
			end
			return nil
		end

		nenv.ioReadFileFromServer = function(file)
			sleep(0.05)
			local mid, msgFile = curProtocol.getWebsite(site .. "/" .. file)
			if mid then
				local f = env.io.open(rootFolder .. "/temp_file", "w")
				f:write(msgFile)
				f:close()
				local rFile = env.io.open(rootFolder .. "/temp_file", "r")
				return rFile
			end
			return nil
		end

		--[[
		nenv.getCookie = function(cookieId)
			sleep(0.1)
			env.rednet.send(id, textutils.serialize({"getCookie", cookieId}))
			local startClock = os.clock()
			while os.clock() - startClock < timeout do
				local mid, status = env.rednet.receive(timeout)
				if mid == id then
					if status == "[$notexist$]" then
						return false
					elseif env.string.find(status, "[$cookieData$]") then
						return env.string.gsub(status, "[$cookieData$]", "")
					end
				end
			end
			return false
		end

		nenv.takeFromCookieJar = function(cookieId)
			nenv.getCookie(cookieId)
		end

		nenv.createCookie = function(cookieId)
			sleep(0.1)
			env.rednet.send(id, textutils.serialize({"createCookie", cookieId}))
			local startClock = os.clock()
			while os.clock() - startClock < timeout do
				local mid, status = env.rednet.receive(timeout)
				if mid == id then
					if status == "[$notexist$]" then
						return false
					elseif env.string.find(status, "[$cookieData$]") then
						return env.string.gsub(status, "[$cookieData$]", "")
					end
				end
			end
			return false
		end

		nenv.bakeCookie = function(cookieId)
			nenv.createCookie(cookieId)
		end

		nenv.deleteCookie = function(cookieId)

		end

		nenv.eatCookie = function(cookieId)
			nenv.deleteCookie(cookieId)
		end
		]]--

		nenv.redirect = function(url)
			api.redirect(url)
			env.error()
		end

		if shellAllowed then
			nenv.shell.run = function(file, ...)
				if file == "clear" then
					api.clearPage(website, cbc)
					env.term.setCursorPos(1, 2)
				else
					env.shell.run(file, ...)
				end
			end
		end

		local queueWebsiteExit = false
		nenv.os.pullEvent = function(a)
			if a == "derp" then return true end
			while true do
				local e, p1, p2, p3, p4, p5 = env.os.pullEventRaw()
				if e == event_exitWebsite then
					queueWebsiteExit = true
					env.error(event_exitWebsite)
				elseif e == "terminate" then
					env.error()
				end

				if e ~= event_exitWebsite and e ~= event_redirect and e ~= event_exitApp 
						and e ~= event_loadWebsite then
					if a then
						if e == a then return e, p1, p2, p3, p4, p5 end
					else return e, p1, p2, p3, p4, p5 end
				end
			end
		end

		nenv.sleep = function(_nTime)
		    local timer = os.startTimer(_nTime)
			repeat local _, param = ospullEvent("timer")
			until param == timer
		end

		nenv.read = function(_sReplaceChar, _tHistory)
			term.setCursorBlink(true)

		    local sLine = ""
			local nHistoryPos = nil
			local nPos = 0
		    if _sReplaceChar then
				_sReplaceChar = string.sub(_sReplaceChar, 1, 1)
			end
			
			local w, h = term.getSize()
			local sx, sy = term.getCursorPos()
			
			local function redraw(_sCustomReplaceChar)
				local nScroll = 0
				if sx + nPos >= w then
					nScroll = (sx + nPos) - w
				end
					
				term.setCursorPos(sx, sy)
				local sReplace = _sCustomReplaceChar or _sReplaceChar
				if sReplace then
					term.write(string.rep(sReplace, string.len(sLine) - nScroll))
				else
					term.write(string.sub(sLine, nScroll + 1))
				end
				term.setCursorPos(sx + nPos - nScroll, sy)
			end
			
			while true do
				local sEvent, param = ospullEvent()
				if sEvent == "char" then
					sLine = string.sub(sLine, 1, nPos) .. param .. string.sub(sLine, nPos + 1)
					nPos = nPos + 1
					redraw()
					
				elseif sEvent == "key" then
				    if param == keys.enter then
						break
					elseif param == keys.left then
						if nPos > 0 then
							nPos = nPos - 1
							redraw()
						end
					elseif param == keys.right then
						if nPos < string.len(sLine) then
							nPos = nPos + 1
							redraw()
						end
					elseif param == keys.up or param == keys.down then
						if _tHistory then
							redraw(" ");
							if param == keys.up then
								if nHistoryPos == nil then
									if #_tHistory > 0 then
										nHistoryPos = #_tHistory
									end
								elseif nHistoryPos > 1 then
									nHistoryPos = nHistoryPos - 1
								end
							else
								if nHistoryPos == #_tHistory then
									nHistoryPos = nil
								elseif nHistoryPos ~= nil then
									nHistoryPos = nHistoryPos + 1
								end						
							end
							
							if nHistoryPos then
		                    	sLine = _tHistory[nHistoryPos]
		                    	nPos = string.len(sLine) 
		                    else
								sLine = ""
								nPos = 0
							end
							redraw()
		                end
					elseif param == keys.backspace then
						if nPos > 0 then
							redraw(" ");
							sLine = string.sub(sLine, 1, nPos - 1) .. string.sub(sLine, nPos + 1)
							nPos = nPos - 1					
							redraw()
						end
					elseif param == keys.home then
						nPos = 0
						redraw()		
					elseif param == keys.delete then
						if nPos < string.len(sLine) then
							redraw(" ");
							sLine = string.sub(sLine, 1, nPos) .. string.sub(sLine, nPos + 2)
							redraw()
						end
					elseif param == keys["end"] then
						nPos = string.len(sLine)
						redraw()
					end
				end
			end
			
			term.setCursorBlink(false)
			term.setCursorPos(w + 1, sy)
			print()
			
			return sLine
		end

		-- Download API
		nenv.urlDownload = function(url)
			local function webmodRead(replaceChar, his, maxLen, stopAtMaxLen, liveUpdates, 
					exitOnControl)
				term.setCursorBlink(true)
				local line = ""
				local hisPos = nil
				local pos = 0
				if replaceChar then replaceChar = replaceChar:sub(1, 1) end
				local w, h = term.getSize()
				local sx, sy = term.getCursorPos()

				local function redraw(repl)
					local scroll = 0
					if line:len() >= maxLen then scroll = line:len() - maxLen end

					term.setCursorPos(sx, sy)
					local a = repl or replaceChar
					if a then term.write(string.rep(a, line:len() - scroll))
					else term.write(line:sub(scroll + 1)) end
					term.setCursorPos(sx + pos - scroll, sy)
				end

				while true do
					local e, but, x, y, p4, p5 = ospullEvent()
					if e == "char" and not(stopAtMaxLen == true and line:len() >= maxLen) then
						line = line:sub(1, pos) .. but .. line:sub(pos + 1, -1)
						pos = pos + 1
						redraw()
					elseif e == "key" then
						if but == keys.enter then
							break
						elseif but == keys.left then
							if pos > 0 then pos = pos - 1 redraw() end
						elseif but == keys.right then
							if pos < line:len() then pos = pos + 1 redraw() end
						elseif (but == keys.up or but == keys.down) and his then
							redraw(" ")
							if but == keys.up then
								if hisPos == nil and #his > 0 then hisPos = #his
								elseif hisPos > 1 then hisPos = hisPos - 1 end
							elseif but == keys.down then
								if hisPos == #his then hisPos = nil
								elseif hisPos ~= nil then hisPos = hisPos + 1 end
							end

							if hisPos then
								line = his[hisPos]
								pos = line:len()
							else
								line = ""
								pos = 0
							end
							redraw()
							if liveUpdates then
								local a, data = liveUpdates(line, "update_history", nil, nil, 
										nil, nil, nil)
								if a == true and data == nil then
									term.setCursorBlink(false)
									return line
								elseif a == true and data ~= nil then
									term.setCursorBlink(false)
									return data
								end
							end
						elseif but == keys.backspace and pos > 0 then
							redraw(" ")
							line = line:sub(1, pos - 1) .. line:sub(pos + 1, -1)
							pos = pos - 1
							redraw()
							if liveUpdates then
								local a, data = liveUpdates(line, "delete", nil, nil, nil, nil, nil)
								if a == true and data == nil then
									term.setCursorBlink(false)
									return line
								elseif a == true and data ~= nil then
									term.setCursorBlink(false)
									return data
								end
							end
						elseif but == keys.home then
							pos = 0
							redraw()
						elseif but == keys.delete and pos < line:len() then
							redraw(" ")
							line = line:sub(1, pos) .. line:sub(pos + 2, -1)
							redraw()
							if liveUpdates then
								local a, data = liveUpdates(line, "delete", nil, nil, nil, nil, nil)
								if a == true and data == nil then
									term.setCursorBlink(false)
									return line
								elseif a == true and data ~= nil then
									term.setCursorBlink(false)
									return data
								end
							end
						elseif but == keys["end"] then
							pos = line:len()
							redraw()
						elseif (but == 29 or but == 157) and not(exitOnControl) then 
							term.setCursorBlink(false)
							return nil
						end
					end if liveUpdates then
						local a, data = liveUpdates(line, e, but, x, y, p4, p5)
						if a == true and data == nil then
							term.setCursorBlink(false)
							return line
						elseif a == true and data ~= nil then
							term.setCursorBlink(false)
							return data
						end
					end
				end

				term.setCursorBlink(false)
				if line ~= nil then line = line:gsub("^%s*(.-)%s*$", "%1") end
				return line
			end

			clearPage(website, colors[theme["background"]])
			print("\n\n")
			nenv.term.setTextColor(colors[theme["text-color"]])
			nenv.term.setBackgroundColor(colors[theme["top-box"]])
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Processing Download Request...")
			centerPrint(string.rep(" ", 47))

			openAddressBar = false
			local res = http.get(url)
			openAddressBar = true
			local data = nil
			if res then
				data = res.readAll()
				res.close()
			else
				term.setCursorPos(1, 5)
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("Error: Download Failed!")
				centerPrint(string.rep(" ", 47))
				openAddressBar = false
				sleep(3)
				openAddressBar = true

				clearPage(website, colors.black)
				term.setCursorPos(1, 2)
				return nil
			end

			clearPage(website, colors[theme["background"]])
			print("")
			nenv.term.setBackgroundColor(colors[theme["top-box"]])
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Download Files")
			centerPrint(string.rep(" ", 47))
			print("")

			local a = website
			if a:find("/") then a = a:sub(1, a:find("/") - 1) end

			nenv.term.setBackgroundColor(colors[theme["bottom-box"]])
			for i = 1, 10 do centerPrint(string.rep(" ", 47)) end
			term.setCursorPos(1, 8)
			centerPrint("  The website:                                 ")
			if curProtocol == protocols.rdnt then 
				centerPrint("     rdnt://" .. a .. string.rep(" ", w - a:len() - 16))
			elseif curProtocol == protocols.http then 
				centerPrint("     http://" .. a .. string.rep(" ", w - a:len() - 16))
			end
			centerPrint("  Is attempting to download a file to this     ")
			centerPrint("  computer!                                    ")

			local opt = nenv.prompt({{"Download", 6, 14}, {"Cancel", w - 16, 14}}, "horizontal")
			if opt == "Download" then
				clearPage(website, colors[theme["background"]])
				print("")
				nenv.term.setTextColor(colors[theme["text-color"]])
				nenv.term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("Download Files")
				centerPrint(string.rep(" ", 47))
				print("")

				term.setBackgroundColor(colors[theme["bottom-box"]])
				for i = 1, 10 do centerPrint(string.rep(" ", 47)) end
				local a = tostring(math.random(1000, 9999))
				term.setCursorPos(5, 8)
				write("This is for security purposes: " .. a)
				term.setCursorPos(5, 9)
				write("Enter the 4 numbers above: ")
				local b = webmodRead(nil, nil, 4, true)
				if b == nil then
					os.queueEvent(event_exitWebsite)
					return
				end

				if b == a then
					term.setCursorPos(5, 11)
					write("Save As: /")
					local c = webmodRead(nil, nil, w - 18, false)
					if c ~= "" and c ~= nil then
						c = "/" .. c
						local f = io.open(c, "w")
						f:write(data)
						f:close()
						term.setCursorPos(5, 13)
						centerWrite("Download Successful! Continuing to Website...")
						openAddressBar = false
						sleep(1.1)
						openAddressBar = true

						clearPage(website, colors.black)
						term.setCursorPos(1, 2)
						return c
					elseif c == nil then
						os.queueEvent(event_exitWebsite)
						return
					end
				else
					term.setCursorPos(5, 13)
					centerWrite("Incorrect! Cancelling Download...")
					openAddressBar = false
					sleep(1.1)
					openAddressBar = true
				end
			elseif opt == "Cancel" then
				term.setCursorPos(1, 15)
				centerWrite("             Download Canceled!             ")
				openAddressBar = false
				sleep(1.1)
				openAddressBar = true
			elseif opt == nil then
				os.queueEvent(event_exitWebsite)
				return
			end

			clearPage(website, colors.black)
			term.setCursorPos(1, 2)
			return nil
		end

		nenv.pastebinDownload = function(code)
			return nenv.urlDownload("http://pastebin.com/raw.php?i=" .. code)
		end

		-- Run
		local fn, err = env.loadfile(cacheLoc)
		if fn and not(err) then
			env.setfenv(fn, nenv)
			_, err = env.pcall(fn)
			env.setfenv(1, backupEnv)
		end

		-- Catch website error
		if err and not(err:find(event_exitWebsite)) then errPages.crash(err) end
		if queueWebsiteExit then os.queueEvent(event_exitWebsite) end
	end

	local function allowFunctions(offences)
		local function appendTable(tableData, addTable, tableName, ignore, overrideFunc)
			if not(tableData[tableName]) then tableData[tableName] = {} end
			for k, v in pairs(addTable) do
				if ignore then
					if ignore ~= k then
						if overrideFunc then
							tableData[tableName][k] = function() 
								env.error("Firewolf Antivirus: Unauthorized Function") end
						else
							tableData[tableName][k] = v
						end
					end
				else
					if overrideFunc then
						tableData[tableName][k] = function() 
							env.error("Firewolf Antivirus: Unauthorized Function") end
					else
						tableData[tableName][k] = v
					end
				end
			end
			return tableData
		end

		local returnTable = appendTable({}, os, "os", nil, true)
		returnTable = appendTable(returnTable, fs, "fs", nil, true)
		returnTable = appendTable(returnTable, io, "io", nil, true)
		returnTable = appendTable(returnTable, shell, "shell", nil, true)
		shellAllowed = false
		returnTable["loadfile"] = function() 
				env.error("Firewolf Antivirus: Unauthorized Function") end
		returnTable["loadstring"] = function() 
				env.error("Firewolf Antivirus: Unauthorized Function") end
		returnTable["dofile"] = function() 
				env.error("Firewolf Antivirus: Unauthorized Function") end
		returnTable["getfenv"] = function() 
				env.error("Firewolf Antivirus: Unauthorized Function") end
		returnTable["setfenv"] = function() 
				env.error("Firewolf Antivirus: Unauthorized Function") end
		returnTable["rawset"] = function()
				env.error("Firewolf Antivirus: Unauthorized Function") end

		returnTable = appendTable(returnTable, os, "os", "run")
		for k, v in pairs(offences) do
			if v == "Modify Files" then
				returnTable = appendTable(returnTable, io, "io")
				returnTable = appendTable(returnTable, fs, "fs")
			elseif v == "Run Files" then 
				returnTable = appendTable(returnTable, os, "os")
				returnTable = appendTable(returnTable, shell, "shell")
				shellAllowed = true
				returnTable["loadfile"] = loadfile
				returnTable["dofile"] = dofile
			elseif v == "Execute Text" then
				returnTable["loadstring"] = loadstring
			elseif v == "Modify Env" then
				returnTable["getfenv"] = getfenv
				returnTable["setfenv"] = setfenv
			elseif v == "Modify Anything" then
				returnTable["rawset"] = rawset
			end
		end

		return returnTable
	end

	-- Draw
	openAddressBar = false
	clearPage(site, colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	print("\n\n")
	centerWrite("Getting DNS Listing...")
	internalWebsite = true

	-- Redirection bots
	loadingRate = loadingRate + 1
	term.clearLine()
	centerWrite("Getting Website...")

	-- Get website
	local id, content, status = curProtocol.getWebsite(site)
	term.clearLine()
	centerWrite("Processing Website...")

	-- Display website
	local cacheLoc = cacheFolder .. "/" .. site:gsub("/", "$slazh$")
	local antivirusProcessed = false
	local antivirusEnv = {}
	if id ~= nil and status ~= nil then
		openAddressBar = true
		if status == "antivirus" then
			local offences = verify("antivirus offences", content)
			if #offences > 0 then
				antivirusProcessed = true
				clearPage(site, colors[theme["background"]])
				print("")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("Antivirus Triggered!")
				centerPrint(string.rep(" ", 47))
				print("")

				term.setBackgroundColor(colors[theme["bottom-box"]])
				centerPrint(string.rep(" ", 47))
				centerPrint("  The antivirus has been triggered on this     ")
				centerPrint("  website! Do you want to give this website    ")
				centerPrint("  permissions to:                              ")
				for i = 1, 8 do centerPrint(string.rep(" ", 47)) end
				for i, v in ipairs(offences) do
					if i > 3 then term.setCursorPos(w - 21, i + 8)
					else term.setCursorPos(6, i + 11) end
					write("[ " .. v)
				end
				while true do
					local opt = prompt({{"Allow", 5, 17}, {"Cancel", 17, 17}, {"View Source", 31, 17}}, 
							"horizontal")
					if opt == "Allow" then
						antivirusEnv = allowFunctions(offences)
						status = "safe"
						break
					elseif opt == "Cancel" then
						clearPage(site, colors[theme["background"]])
						print("")
						term.setTextColor(colors[theme["text-color"]])
						term.setBackgroundColor(colors[theme["top-box"]])
						centerPrint(string.rep(" ", 47))
						centerWrite(string.rep(" ", 47))
						centerPrint("O Noes!")
						centerPrint(string.rep(" ", 47))
						print("")

						term.setBackgroundColor(colors[theme["bottom-box"]])
						centerPrint(string.rep(" ", 47))
						centerPrint("         ______                          __    ")
						centerPrint("        / ____/_____ _____ ____   _____ / /    ")
						centerPrint("       / __/  / ___// ___// __ \\ / ___// /     ")
						centerPrint("      / /___ / /   / /   / /_/ // /   /_/      ")
						centerPrint("     /_____//_/   /_/    \\____//_/   (_)       ")
						centerPrint(string.rep(" ", 47))
						centerPrint("  Could not connect to the website! The        ")
						centerPrint("  website was not given enough permissions to  ")
						centerPrint("  execute properly!                            ")
						centerPrint(string.rep(" ", 47))
						break
					elseif opt == "View Source" then
						local f = io.open(rootFolder .. "/temp-source", "w")
						f:write(content)
						f:close()
						openAddressBar = false
						shell.run("edit", rootFolder .. "/temp-source")
						fs.delete(rootFolder .. "/temp-source")
						clearPage(site, colors[theme["background"]])
						print("")
						term.setTextColor(colors[theme["text-color"]])
						term.setBackgroundColor(colors[theme["top-box"]])
						centerPrint(string.rep(" ", 47))
						centerWrite(string.rep(" ", 47))
						centerPrint("Antivirus Triggered!")
						centerPrint(string.rep(" ", 47))
						print("")

						term.setBackgroundColor(colors[theme["bottom-box"]])
						centerPrint(string.rep(" ", 47))
						centerPrint("  The antivirus has been triggered on this     ")
						centerPrint("  website! Do you want to give this website    ")
						centerPrint("  permissions to:                              ")
						for i = 1, 8 do centerPrint(string.rep(" ", 47)) end
						for i, v in ipairs(offences) do
							if i > 3 then term.setCursorPos(w - 21, i + 8)
							else term.setCursorPos(6, i + 11) end
							write("[ " .. v)
						end
						openAddressBar = true
					elseif opt == nil then
						os.queueEvent(event_exitWebsite)
						return
					end
				end
			else
				status = "safe"
			end
		end

		if status == "safe" and site ~= "" then
			if not(antivirusProcessed) then
				antivirusEnv = allowFunctions({""})
			end
			internalWebsite = false
			local f = io.open(cacheLoc, "w")
			f:write(content)
			f:close()
			term.clearLine()
			centerWrite("Running Website...")
			runSite(cacheLoc, antivirusEnv)
			return
		end
	else
		if fs.exists(cacheLoc) and site ~= "" and site ~= "." and site ~= ".." and
				not(verify("blacklist", site)) then
			openAddressBar = true
			clearPage(site, colors[theme["background"]])
			print("")
			term.setTextColor(colors[theme["text-color"]])
			term.setBackgroundColor(colors[theme["top-box"]])
			centerPrint(string.rep(" ", 47))
			centerWrite(string.rep(" ", 47))
			centerPrint("Cache Exists!")
			centerPrint(string.rep(" ", 47))
			print("")

			term.setBackgroundColor(colors[theme["bottom-box"]])
			centerPrint(string.rep(" ", 47))
			centerPrint("       ______              __            __    ")
			centerPrint("      / ____/____ _ _____ / /_   ___    / /    ")
			centerPrint("     / /    / __ '// ___// __ \\ / _ \\  / /     ")
			centerPrint("    / /___ / /_/ // /__ / / / //  __/ /_/      ")
			centerPrint("    \\____/ \\__,_/ \\___//_/ /_/ \\___/ (_)       ")
			centerPrint(string.rep(" ", 47))
			centerPrint("  Could not connect to the website! It may be  ")
			centerPrint("  down, or not exist! A cached version was     ")
			centerPrint("  found!                                       ")
			centerPrint(string.rep(" ", 47))
			centerPrint(string.rep(" ", 47))

			local opt = prompt({{"Load Cache", 6, 17}, {"Cancel", w - 16, 17}}, "horizontal")
			if opt == "Load Cache" then
				internalWebsite = false
				runSite(cacheLoc, {"firewolf-override"})
				return
			elseif opt == "Cancel" then
				clearPage(site, colors[theme["background"]])
				print("\n")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("O Noes!")
				centerPrint(string.rep(" ", 47))
				print("")

				term.setBackgroundColor(colors[theme["bottom-box"]])
				centerPrint(string.rep(" ", 47))
				centerPrint("         ______                          __    ")
				centerPrint("        / ____/_____ _____ ____   _____ / /    ")
				centerPrint("       / __/  / ___// ___// __ \\ / ___// /     ")
				centerPrint("      / /___ / /   / /   / /_/ // /   /_/      ")
				centerPrint("     /_____//_/   /_/    \\____//_/   (_)       ")
				centerPrint(string.rep(" ", 47))
				centerPrint("  Could not connect to the website! The        ")
				centerPrint("  cached version was not loaded!               ")
				centerPrint(string.rep(" ", 47))
			elseif opt == nil then
				os.queueEvent(event_exitWebsite)
				return
			end
		else
			openAddressBar = true
			local res = {}
			if site ~= "" then
				for k, v in pairs(dnsDatabase[1]) do
					if v:find(site:lower()) then
						table.insert(res, v)
					end
				end
			else
				for k,v in pairs(dnsDatabase[1]) do
					table.insert(res, v)
				end
			end

			if #res > 0 then
				clearPage(site, colors[theme["background"]])
				print("")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				if #res == 1 then centerPrint("1 Search Result")
				else centerPrint(#res .. " Search Results") end
				centerPrint(string.rep(" ", 47))
				print("")

				term.setBackgroundColor(colors[theme["bottom-box"]])
				for i = 1, 12 do centerPrint(string.rep(" ", 47)) end
				local opt = scrollingPrompt(res, 4, 8, 10, 43)
				if opt then
					redirect(opt:gsub("rdnt://", ""):gsub("http://", ""))
					return
				else
					os.queueEvent(event_exitWebsite)
					return
				end
			elseif site == "" and #res == 0 then
				clearPage(site, colors[theme["background"]])
				print("\n\n")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("No Websites are Currently Online! D:")
				centerWrite(string.rep(" ", 47))
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("Why not make one yourself?")
				centerWrite(string.rep(" ", 47))
				centerPrint("Visit rdnt://server!")
				centerPrint(string.rep(" ", 47))
				while true do
					local e, p1, p2, p3 = os.pullEvent()
					if e == "mouse_click" then
						if p2 < 50 and p2 > 2 and p3 > 4 and p3 < 11 then
							redirect("server")
							break
						end
					elseif e == event_openAddressBar then
						break
					end
				end
			else
				clearPage(site, colors[theme["background"]])
				print("\n")
				term.setTextColor(colors[theme["text-color"]])
				term.setBackgroundColor(colors[theme["top-box"]])
				centerPrint(string.rep(" ", 47))
				centerWrite(string.rep(" ", 47))
				centerPrint("O Noes!")
				centerPrint(string.rep(" ", 47))
				print("")
				term.setBackgroundColor(colors[theme["bottom-box"]])
				centerPrint(string.rep(" ", 47))
				centerPrint("         ______                          __    ")
				centerPrint("        / ____/_____ _____ ____   _____ / /    ")
				centerPrint("       / __/  / ___// ___// __ \\ / ___// /     ")
				centerPrint("      / /___ / /   / /   / /_/ // /   /_/      ")
				centerPrint("     /_____//_/   /_/    \\____//_/   (_)       ")
				centerPrint(string.rep(" ", 47))
				if verify("blacklist", id) then
					centerPrint("  Could not connect to the website! It has     ")
					centerPrint("  been blocked by a database admin!            ")
				else
					centerPrint("  Could not connect to the website! It may     ")
					centerPrint("  be down, or not exist!                       ")
				end
				centerPrint(string.rep(" ", 47))
			end
		end
	end
end


--  -------- Websites

local function websiteMain()
	-- Variables
	local loadingClock = os.clock()

	-- Main loop
	while true do
		-- Reset
		setfenv(1, backupEnv)
		browserAgent = browserAgentTemplate
		clearPage(website)
		w, h = term.getSize()
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)

		-- Exit
		if website == "exit" then
			os.queueEvent(event_exitApp)
			return
		end

		-- Perform Checks
		local skip = false
		local oldWebsite = website
		if not(errPages.checkForModem()) then
			os.queueEvent(event_exitApp)
			return
		end
		website = oldWebsite
		if os.clock() - loadingClock > 5 then
			loadingRate = 0
			loadingClock = os.clock()
		elseif loadingRate >= 8 then
			errPages.overspeed()
			loadingClock = os.clock()
			loadingRate = 0
			skip = true
		end if not(skip) then
			-- Add to history
			appendToHistory(website)

			-- Render site
			clearPage(website)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			if pages[website] then 
				local ex = pages[website](website)
				if ex == true then 
					os.queueEvent(event_exitApp)
					return
				end
			else
				loadSite(website)
			end
		end

		-- Wait
		os.pullEvent(event_loadWebsite)
	end
end


--  -------- Address Bar

local function retrieveSearchResults()
	local lastCheck = os.clock()
	curSites = curProtocol.getSearchResults()
	while true do
		local e = os.pullEvent()
		if website ~= "exit" and e == event_loadWebsite then
			if os.clock() - lastCheck > 5 then
				curSites = curProtocol.getSearchResults()
				lastCheck = os.clock()
			end
		elseif e == event_exitApp then
			os.queueEvent(event_exitApp)
			return
		end
	end
end

local function addressBarRead()
	local len = 4
	local list = {}

	local function draw(l)
		local ox, oy = term.getCursorPos()
		for i = 1, len do
			term.setTextColor(colors[theme["address-bar-text"]])
			term.setBackgroundColor(colors[theme["address-bar-background"]])
			term.setCursorPos(1, i + 1)
			write(string.rep(" ", w))
		end
		if theme["address-bar-base"] then term.setBackgroundColor(colors[theme["address-bar-base"]])
		else term.setBackgroundColor(colors[theme["bottom-box"]]) end
		term.setCursorPos(1, len + 2)
		write(string.rep(" ", w))
		term.setBackgroundColor(colors[theme["address-bar-background"]])

		for i, v in ipairs(l) do
			term.setCursorPos(2, i + 1)
			write(v)
		end
		term.setCursorPos(ox, oy)
	end

	local function onLiveUpdate(cur, e, but, x, y, p4, p5)
		if e == "char" or e == "update_history" or e == "delete" then
			list = {}
			for _, v in pairs(curSites) do
				if #list < len and 
						v:gsub("rdnt://", ""):gsub("http://", ""):find(cur:lower(), 1, true) then
					table.insert(list, v)
				end
			end
			table.sort(list)
			table.sort(list, function(a, b)
				local _, ac = a:gsub("rdnt://", ""):gsub("http://", ""):gsub(cur:lower(), "")
				local _, bc = b:gsub("rdnt://", ""):gsub("http://", ""):gsub(cur:lower(), "")
				return ac > bc
			end)
			draw(list)
			return false, nil
		elseif e == "mouse_click" then
			for i = 1, #list do
				if y == i + 1 then
					return true, list[i]:gsub("rdnt://", ""):gsub("http://", "")
				end
			end
		end
	end

	onLiveUpdate("", "delete", nil, nil, nil, nil, nil)
	return modRead(nil, addressBarHistory, 41, false, onLiveUpdate)
end

local function addressBarMain()
	while true do
		local e, but, x, y = os.pullEvent()
		if (e == "key" and (but == 29 or but == 157)) or 
				(e == "mouse_click" and y == 1) then
			if openAddressBar then
				if e == "key" then x = 45 end
				if x == term.getSize() then
					menuBarOpen = true
					local list = nil
					if not(internalWebsite) then
						list = "> [- Exit Firewolf -] [- Incorrect Website -]      "
					else
						list = "> [- Exit Firewolf -]                              "
					end

					term.setBackgroundColor(colors[theme["top-box"]])
					term.setTextColor(colors[theme["text-color"]])
					term.setCursorPos(1, 1)
					write(list)
				elseif menuBarOpen and (x == 1 or (but == 29 or but == 157)) then
					menuBarOpen = false
					clearPage(website, nil, true)
				elseif x < 18 and x > 2 and menuBarOpen then
					website = "exit"
					menuBarOpen = false
					os.queueEvent(event_openAddressBar)
					os.queueEvent(event_exitWebsite)
					sleep(0.0001)
					website = "exit"
					os.queueEvent(event_loadWebsite)
				elseif x < 38 and x > 18 and not(internalWebsite) and menuBarOpen then
					menuBarOpen = false
					clearPage("incorrect", colors[theme["background"]])
					print("")
					term.setBackgroundColor(colors[theme["top-box"]])
					term.setTextColor(colors[theme["text-color"]])
					centerPrint(string.rep(" ", 47))
					centerPrint(string.rep(" ", 47))
					centerPrint(string.rep(" ", 47))
					term.setCursorPos(1, 4)
					centerPrint("Incorrect Website: ID Block")
					term.setCursorPos(1, 7)
					term.setBackgroundColor(colors[theme["bottom-box"]])
					for i = 1, 12 do centerPrint(string.rep(" ", 47)) end

					term.setCursorPos(1, 8)
					centerPrint("This feature is used to block a server's ID")
					centerPrint("if it's intercepting a website")
					centerPrint("Ex. You got onto a website you didn't expect")
					centerPrint("Managing servers comming soon!")
					--centerPrint("Manage blocked servers at rdnt://settings")
					centerPrint("")
					centerPrint("You are about to block the server ID: " .. tostring(serverWebsiteID))
					local opt = prompt({{"Block", 8, 15}, {"Don't Block", 28, 15}})
					if opt == "Block" then
						table.insert(blacklist, tostring(serverWebsiteID))
						local f = io.open(userBlacklist,"a")
						f:write(tostring(serverWebsiteID))
						f:close()
						centerPrint("")
						centerPrint("Server Blocked!")
						centerPrint("You may now browse normally!")
					else
						centerPrint("")
						centerPrint("Server Not Blocked!")
						centerPrint("You may now browse normally!")
					end
				elseif x >= 2 and x <= 5 then
					-- Swap protocols
					if curProtocol == protocols.rdnt then curProtocol = protocols.http
					elseif curProtocol == protocols.http then curProtocol = protocols.rdnt
					end
					curSites = curProtocol.getSearchResults()
					clearPage(website, nil, true)
					redirect(homepage)
				elseif not(menuBarOpen) then
					internalWebsite = true

					-- Exit
					os.queueEvent(event_openAddressBar)
					os.queueEvent(event_exitWebsite)

					-- Read
					term.setBackgroundColor(colors[theme["address-bar-background"]])
					term.setTextColor(colors[theme["address-bar-text"]])
					term.setCursorPos(2, 1)
					term.clearLine()
					if curProtocol == protocols.rdnt then write("rdnt://")
					elseif curProtocol == protocols.http then write("http://")
					end
					local oldWebsite = website
					website = addressBarRead()
					if website == nil then
						website = oldWebsite
					elseif website == "home" or website == "homepage" then
						website = homepage
					end

					-- Load
					os.queueEvent(event_loadWebsite)
				end
			end
		elseif e == event_redirect then
			if openAddressBar then
				-- Redirect
				os.queueEvent(event_exitWebsite)
				if but == "home" or but == "homepage" then website = homepage
				else website = but end
				os.queueEvent(event_loadWebsite)
			end
		elseif e == event_exitApp then
			os.queueEvent(event_exitApp)
			break
		end
	end
end


--  -------- Main

local function main()
	-- Logo
	term.setBackgroundColor(colors[theme["background"]])
	term.setTextColor(colors[theme["text-color"]])
	term.clear()
	term.setCursorPos(1, 2)
	term.setBackgroundColor(colors[theme["top-box"]])
	centerPrint(string.rep(" ", 47))
	centerPrint([[          ______ ____ ____   ______            ]])
	centerPrint([[ ------- / ____//  _// __ \ / ____/            ]])
	centerPrint([[ ------ / /_    / / / /_/ // __/               ]])
	centerPrint([[ ----- / __/  _/ / / _  _// /___               ]])
	centerPrint([[ ---- / /    /___//_/ |_|/_____/               ]])
	centerPrint([[ --- / /       _       __ ____   __     ______ ]])
	centerPrint([[ -- /_/       | |     / // __ \ / /    / ____/ ]])
	centerPrint([[              | | /| / // / / // /    / /_     ]])
	centerPrint([[              | |/ |/ // /_/ // /___ / __/     ]])
	centerPrint([[              |__/|__/ \____//_____//_/        ]])
	centerPrint(string.rep(" ", 47))
	print("\n")
	term.setBackgroundColor(colors[theme["bottom-box"]])

	-- Load settings data
	if fs.exists(settingsLocation) then
		local f = io.open(settingsLocation, "r")
		local a = textutils.unserialize(f:read("*l"))
		if a then
			autoupdate = a.auto
			incognito = a.incog
			homepage = a.home
		end
		f:close()
	else
		autoupdate = "true"
		incognito = "false"
		homepage = "firewolf"
	end
	curProtocol = protocols.rdnt

	-- Update
	centerPrint(string.rep(" ", 47))
	centerWrite(string.rep(" ", 47))
	centerPrint("Checking for Updates...")
	centerWrite(string.rep(" ", 47))
	if not(noInternet) then if updateClient() then return end end

	-- Download Files
	local x, y = term.getCursorPos()
	term.setCursorPos(1, y - 1)
	centerWrite(string.rep(" ", 47))
	centerWrite("Downloading Required Files...")
	migrateFilesystem()
	if not(noInternet) then resetFilesystem() end
	loadDatabases()

	-- Load history
	local b = io.open(historyLocation, "r")
	history = textutils.unserialize(b:read("*l"))
	b:close()

	-- Modem
	if not(errPages.checkForModem()) then return end
	website = homepage

	-- Run
	parallel.waitForAll(websiteMain, addressBarMain, retrieveSearchResults)

	return false
end

local function startup()
	-- HTTP API
	if not(http) and not(noInternet) then
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 2)
		term.setBackgroundColor(colors[theme["top-box"]])
		api.centerPrint(string.rep(" ", 47))
		api.centerWrite(string.rep(" ", 47))
		api.centerPrint("HTTP API Not Enabled! D:")
		api.centerPrint(string.rep(" ", 47))
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		api.centerPrint(string.rep(" ", 47))
		api.centerPrint("  Firewolf is unable to run without the HTTP   ")
		api.centerPrint("  API Enabled! Please enable it in the CC      ")
		api.centerPrint("  Config!                                      ")
		api.centerPrint(string.rep(" ", 47))

		api.centerPrint(string.rep(" ", 47))
		api.centerWrite(string.rep(" ", 47))
		if isAdvanced() then api.centerPrint("Click to exit...")
		else api.centerPrint("Press any key to exit...") end
		api.centerPrint(string.rep(" ", 47))

		while true do
			local e, but, x, y = os.pullEvent()
			if e == "mouse_click" or e == "key" then break end
		end

		return false 
	end

	-- Turtle
	if turtle then
		term.clear()
		term.setCursorPos(1, 2)
		api.centerPrint("Advanced Comptuer Required!")
		print("\n")
		api.centerPrint("  This version of Firewolf requires  ")
		api.centerPrint("  an Advanced Comptuer to run!       ")
		print("")
		api.centerPrint("  Turtles may not be used to run     ")
		api.centerPrint("  Firewolf! :(                       ")
		print("")
		api.centerPrint("Press any key to exit...")

		os.pullEvent("key")
		return false
	end

	-- Run
	local _, err = pcall(function() main() end)
	if err ~= nil then
		term.setTextColor(colors[theme["text-color"]])
		term.setBackgroundColor(colors[theme["background"]])
		term.clear()
		term.setCursorPos(1, 2)
		term.setCursorBlink(false)
		term.setBackgroundColor(colors[theme["top-box"]])
		api.centerPrint(string.rep(" ", 47))
		api.centerWrite(string.rep(" ", 47))
		api.centerPrint("Firewolf has Crashed! D:")
		api.centerPrint(string.rep(" ", 47))
		print("")
		term.setBackgroundColor(colors[theme["background"]])
		print("")
		print("  " .. err)
		print("")

		term.setBackgroundColor(colors[theme["bottom-box"]])
		api.centerPrint(string.rep(" ", 47))
		if autoupdate == "true" then
			api.centerPrint("  Please report this error to 1lann or         ")
			api.centerPrint("  GravityScore so we are able to fix it!       ")
			api.centerPrint("  If this problem persists, try deleting       ")
			api.centerPrint("  " .. rootFolder .. "                              ")
		else
			api.centerPrint("  Automatic updating is off! A new version     ")
			api.centerPrint("  may have have been released, which could     ")
			api.centerPrint("  fix this problem!                            ")
			api.centerPrint("  If you didn't intend to turn auto-updating   ")
			api.centerPrint("  off, delete " .. rootFolder .. "                  ")
		end
		api.centerPrint(string.rep(" ", 47))
		api.centerWrite(string.rep(" ", 47))
		if isAdvanced() then api.centerPrint("Click to exit...")
		else api.centerPrint("Press any key to exit...") end
		api.centerPrint(string.rep(" ", 47))

		while true do
			local e, but, x, y = os.pullEvent()
			if e == "mouse_click" or e == "key" then break end
		end

		return false
	end

	return true
end

-- Check if read only
if fs.isReadOnly(firewolfLocation) or fs.isReadOnly(rootFolder) then
	print("Firewolf cannot modify itself or its root folder!")
	print("")
	print("This cold be caused by Firewolf being placed in")
	print("the rom folder, or another program may be")
	print("preventing the modification of Firewolf.")

	-- Reset Environment and exit
	setfenv(1, backupEnv)
	error()
end

-- Theme
if not(isAdvanced()) then 
	theme = originalTheme
else
	theme = loadTheme(themeLocation)
	if theme == nil then theme = defaultTheme end
end

-- Debugging
if #tArgs > 0 and tArgs[1] == "debug" then
	term.setTextColor(colors[theme["text-color"]])
	term.setBackgroundColor(colors[theme["background"]])
	term.clear()
	term.setCursorPos(1, 4)
	api.centerPrint(string.rep(" ", 43))
	api.centerWrite(string.rep(" ", 43))
	api.centerPrint("Debug Mode Enabled...")
	api.centerPrint(string.rep(" ", 43))

	if fs.exists(debugLogLocation) then debugFile = io.open(debugLogLocation, "a")
	else debugFile = io.open(debugLogLocation, "w") end
	debugFile:write("\n-- [" .. textutils.formatTime(os.time()) .. "] New Log --")
	sleep(1.3)
end

-- Start
startup()

-- Exit Message
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.setCursorBlink(false)
term.clear()
term.setCursorPos(1, 1)
api.centerPrint("Thank You for Using Firewolf " .. version)
api.centerPrint("Made by 1lann and GravityScore")
term.setCursorPos(1, 3)

-- Closes
for _, v in pairs(rs.getSides()) do rednet.close(v) end
if debugFile then debugFile:close() end

-- Reset Environment
setfenv(1, backupEnv)
