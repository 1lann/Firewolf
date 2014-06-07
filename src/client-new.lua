
--
--  Firewolf
--  Made by GravityScore and 1lann
--



local version = "3.0"
local w, h = term.getSize()

local theme = {
	["background"] = colors.gray,
	["highlightBackground"] = colors.lightGray,

	["accent"] = colors.red,
	["subtle"] = colors.orange,

	["text"] = colors.white,
	["hiddenText"] = colors.lightGray,

	["error"] = colors.red,
}



--    Events


local Events = {}


Events.openMenubar = "firewolf_openMenubarEvent"
Events.exit = "firewolf_exitEvent"



--    Utilities


local function clear(bg, fg)
	term.setTextColor(fg)
	term.setBackgroundColor(bg)
	term.clear()
	term.setCursorPos(1, 1)
end


local function fill(x, y, width, height, bg)
	term.setBackgroundColor(bg)
	for i = y, y + height - 1 do
		term.setCursorPos(x, i)
		term.write(string.rep(" ", width))
	end
end


local function center(text)
	local x, y = term.getCursorPos()
	local w, h = term.getSize()
	local offset = (text:len() % 2 == 0 and 1 or 0)
	term.setCursorPos(math.floor(w / 2 - text:len() / 2) + offset, y)
	term.write(text)
	term.setCursorPos(1, y + 1)
end


local function centerSplit(text, width)
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


local function localiseEvent(event, startY, startX)
	local localised = event

	if localised[1] == "mouse_click" then
		if startY then
			localised[4] = localised[4] - startY + 1
		end

		if startX then
			localised[3] = localised[3] - startX + 1
		end
	end

	return localised
end



--    FWML


local FWML = {}


function FWML.parse(contents)
	contents = contents:gsub("\n", "")

	local lines = {}
	for line in contents:gmatch("%[br%]") do
		table.insert(lines, line)
	end

	print(table.concat(lines))
end


function FWML.getExecutionFunction(contents)

end



--    Internal Sites


local InternalSites = {}

InternalSites.visible = {}
InternalSites.invisible = {}
InternalSites.pageTypes = {}


InternalSites.pageTypes["firewolf"] = "lua"
InternalSites.visible["firewolf"] = function()
	print("hello there!")
	print("testing")
end


InternalSites.pageTypes["none"] = "lua"
InternalSites.invisible["none"] = function()
	print("not found!")
end


InternalSites.pageTypes["error"] = "lua"
InternalSites.invisible["error"] = function(err)
	print("Error occured!")
	print(tostring(err))
end


InternalSites.pageTypes["search"] = "lua"
InternalSites.invisible["search"] = function(results)

end


function InternalSites.isInternal(url)
	success = false
	if InternalSites.visible[url] then
		success = true
	end

	return success
end


function InternalSites.protect(fn, args)
	if not args then
		args = {}
	end

	return function()
		local _, err = pcall(function()
			fn(unpack(args))
		end)

		if err then
			InternalSites.helperPage("error", err)()
		end
	end
end


function InternalSites.fetch(url)
	local fn = nil
	local page = InternalSites.visible[url]
	if page then
		if InternalSites.pageTypes[url] == "lua" then
			fn = InternalSites.protect(page)
		elseif InternalSites.pageTypes[url] == "fwml" then
			fn = FWML.getExecutionFunction(page)
		end
	end

	return fn
end


function InternalSites.helperPage(pageType, ...)
	local fn = nil
	local page = InternalSites.invisible[pageType]
	if page then
		if InternalSites.pageTypes[pageType] == "lua" then
			local args = {...}
			fn = InternalSites.protect(page, args)
		elseif InternalSites.pageTypes[pageType] == "fwml" then
			fn = FWML.getExecutionFunction(page)
		end
	end

	return fn
end



--    External Sites


local ExternalSites = {}


function ExternalSites.fetch(url)
	-- Return connection object
	-- fetchPage()
	-- close()
end



--    Searching


local Search = {}


function Search.results(query)
	-- Query is nil for all available websites
	-- Returns array of URLs, prefixed with rdnt://
end



--   Page Execution


local Language = {}


function Language.determineType(headers)
	local languageType = "lua"

	if headers and type(headers) == "table" then
		if headers.language and headers.language == "Firewolf Markup" then
			language = "fwml"
		end
	end

	return languageType
end


function Language.getLuaExecutionFunction(contents)
	local fn, err = loadstring(contents)
	local actualFn = nil

	if err then
		actualFn = InternalSites.helperPage("error", err)
	else
		actualFn = function()
			local _, err = pcall(fn)
			if err then
				InternalSites.helperPage("error", err)()
			end
		end
	end

	return actualFn
end


function Language.getExecutionFunction(contents, headers)
	local languageType = Language.determineType(headers)
	local fn = nil
	if languageType == "fwml" then
		fn = FWML.getExecutionFunction(contents)
	elseif languageType == "lua" then
		fn = Language.getLuaExecutionFunction(contents)
	end

	return fn
end



--    Website Fetching


local Fetch = {}


function Fetch.normalizeURL(url)
	url = url:lower():gsub(" ", "")
	if url == "home" or url == "homepage" then
		url = "firewolf"
	end

	return url
end


function Fetch.normalizePage(page)
	page = page:lower()
	if page == "" then
		page = "/"
	end

	return page
end


function Fetch.isInvalidURL(url)
	local invalid = false

	if url:len() > 0 and url:gsub("/", ""):len() == 0 then
		invalid = true
	end

	if not url:find("^[a-zA-Z0-9_/%-%.]*$") then
		invalid = true
	end

	return invalid
end


function Fetch.determineType(url)
	local urlType = "none"
	local data = nil

	url = Fetch.normalizeURL(url)
	if not Fetch.isInvalidURL(url) then
		if url == "exit" then
			urlType = "exit"
		elseif InternalSites.isInternal(url) then
			urlType = "internal"
		elseif url == "" then
			local results = Search.results()
			if results and #results > 0 then
				urlType = "search"
				data = results
			end
		else
			local connection = ExternalSites.fetch(url)
			if connection then
				urlType = "external"
				data = connection
			else
				local results = Search.results(url)
				if results and #results > 0 then
					urlType = "search"
					data = results
				end
			end
		end
	end

	return urlType, data
end


function Fetch.getPageFromConnection(connection, url)
	local actualConnection = connection
	if connection.multipleServers then
		-- I'm sorry
		-- So so sorry
		-- We're just really lazy
		actualConnection = connection.servers[1]
	end

	local page = url:match("^[^/]+(.+)$")
	page = Fetch.normalizePage(page)

	local contents, headers = actualConnection.fetchPage(page)
	actualConnection.close()

	local fn = nil
	if contents then
		if type(contents) ~= "string" then
			fn = InternalSites.helperPage("none")
		else
			fn = Language.getExecutionFunction(contents, headers)
		end
	else
		fn = InternalSites.helperPage("error", "A connection timeout occured!")
	end

	return fn
end


function Fetch.getExecutionFunction(url)
	url = Fetch.normalizeURL(url)

	local urlType, data = Fetch.determineType(url)
	local fn = nil
	if urlType == "none" then
		fn = InternalSites.helperPage("none")
	elseif urlType == "exit" then
		os.queueEvent(Events.exit)
	elseif urlType == "internal" then
		fn = InternalSites.fetch(url)
	elseif urlType == "external" then
		fn = Fetch.getPageFromConnection(data, url)
	elseif urlType == "search" then
		fn = InternalSites.helperPage("search", data)
	end

	return fn
end



--    Content


local Content = {}
Content.__index = Content


Content.startY = 3


function Content.new()
	local self = setmetatable({}, Content)
	self:setup()
	return self
end


function Content:setup()
	local height = h - Content.startY + 1
	self.win = window.create(term.native(), 1, Content.startY, w, height, false)
	self.thread = nil
	self.url = ""

	self:loadURL("firewolf")
end


function Content:show()
	term.redirect(self.win)
	self.win.setVisible(true)
	self.win.redraw()
	self.win.restoreCursor()
end


function Content:hide()
	self.win.setVisible(false)
end


function Content:draw()
	self:show()
end


function Content:loadURL(url)
	local fn = Fetch.getExecutionFunction(url)
	if fn then
		self.thread = coroutine.create(fn)
		self.url = url

		term.redirect(self.win)
		clear(colors.black, colors.white)
		coroutine.resume(self.thread)
	end
end


function Content:getName()
	local name = self.url
	if name:len() == 0 then
		name = "Search"
	end

	return name
end


function Content:event(event)
	if self.thread and coroutine.status(self.thread) ~= "dead" then
		term.redirect(self.win)
		self.win.restoreCursor()
		coroutine.resume(self.thread, unpack(event))
	end
end



--    Content Manager


local ContentManager = {}
ContentManager.__index = ContentManager


function ContentManager.new()
	local self = setmetatable({}, ContentManager)
	self:setup()
	return self
end


function ContentManager:setup()
	self.contents = {}
	self.current = 1
end


function ContentManager:create(index)
	if not index then
		index = #self.contents + 1
	end

	local content = Content.new()
	table.insert(self.contents, index, content)
end


function ContentManager:switch(index)
	if self.contents[index] then
		self:hideAll()
		self.current = index
		self.contents[self.current]:show()
	end
end


function ContentManager:close(index)
	if not index then
		index = self.current
	end

	if index <= #self.contents then
		table.remove(self.contents, index)

		if self.current >= index then
			local index = math.max(1, self.current - 1)
			self:switch(index)
		end
	end
end


function ContentManager:getTabNames()
	local names = {}
	for _, content in pairs(self.contents) do
		table.insert(names, content:getName())
	end

	return names
end


function ContentManager:show()
	self.contents[self.current]:show()
end


function ContentManager:hideAll()
	for i, _ in pairs(self.contents) do
		self.contents[i]:hide()
	end
end


function ContentManager:event(event)
	self.contents[self.current]:event(event)
end



--    Tab Bar

-- Delegate responds to:
--  getTabNames()


local TabBar = {}
TabBar.__index = TabBar


TabBar.y = 2

TabBar.maxTabWidth = 8
TabBar.maxTabs = 5


function TabBar.new(delegate)
	local self = setmetatable({}, TabBar)
	self:setup(delegate)
	return self
end


function TabBar.sanitiseName(name)
	local new = name:gsub("^%s*(.-)%s*$", "%1")
	if new:len() > TabBar.maxTabWidth then
		new = new:sub(1, TabBar.maxTabWidth):gsub("^%s*(.-)%s*$", "%1")
	end

	if new:sub(-1, -1) == "." then
		new = new:sub(1, -2):gsub("^%s*(.-)%s*$", "%1")
	end

	return new:gsub("^%s*(.-)%s*$", "%1")
end


function TabBar:setup(delegate)
	self.delegate = delegate
	self.win = window.create(term.native(), 1, TabBar.y, w, 1, false)
	self.current = 1
end


function TabBar:draw()
	local names = self.delegate:getTabNames()

	term.redirect(self.win)
	self.win.setVisible(true)

	clear(theme.background, theme.text)

	for i, name in pairs(names) do
		local actualName = TabBar.sanitiseName(name)

		if i == self.current then
			term.setTextColor(theme.text)
		else
			term.setTextColor(theme.hiddenText)
		end

		term.write(" " .. actualName)

		if i == self.current and #names > 1 then
			term.setTextColor(theme.error)
			term.write("x")
		else
			term.write(" ")
		end
	end

	if #names < TabBar.maxTabs then
		term.setTextColor(theme.hiddenText)
		term.write(" + ")
	end
end


function TabBar:determineClickedTab(x, y)
	local index, action = nil, nil

	if y == 1 then
		local names = self.delegate:getTabNames()
		local currentX = 2

		for i, name in pairs(names) do
			local actualName = TabBar.sanitiseName(name)
			local endX = currentX + actualName:len() - 1

			if x >= currentX and x <= endX then
				index = i
				action = "switch"
			elseif x == endX + 1 and i == self.current and #names > 1 then
				index = i
				action = "close"
			end

			currentX = endX + 3
		end

		if x == currentX then
			action = "create"
		end
	end

	return action, index
end


function TabBar:click(button, x, y)
	local action, index = self:determineClickedTab(x, y)

	local cancel = false
	if y == 1 then
		cancel = true
	end

	if action then
		local names = self.delegate:getTabNames()

		if action == "switch" then
			self.current = index
			os.queueEvent("tab_bar_switch", index)
		elseif action == "create" then
			os.queueEvent("tab_bar_create")
		elseif action == "close" and #names > 1 then
			os.queueEvent("tab_bar_close", index)
		end
	end

	return cancel
end


function TabBar:event(event)
	local cancel = false

	if event[1] == "mouse_click" then
		cancel = self:click(event[2], event[3], event[4])
	end

	return cancel
end



--    Content Tab Bar Link


local ContentTabLink = {}
ContentTabLink.__index = ContentTabLink


function ContentTabLink.new()
	local self = setmetatable({}, ContentTabLink)
	self:setup()
	return self
end


function ContentTabLink:setup()
	self.contentManager = ContentManager.new()
	self.tabBar = TabBar.new(self.contentManager)
	self.visible = true

	local index = #self.contentManager.contents + 1
	self.contentManager:create(index)
	self.contentManager:switch(index)
end


function ContentTabLink:getCurrentTab()
	return self.contentManager.contents[self.contentManager.current]
end


function ContentTabLink:draw()
	self.tabBar:draw()
	self.contentManager.contents[self.contentManager.current]:draw()
end


function ContentTabLink:getTabBarAction(event)
	local action = nil

	if event:find("tab_bar_") == 1 then
		action = event:gsub("tab_bar_", "")
	end

	return action
end


function ContentTabLink:tabBarAction(action, index)
	if action == "switch" then
		self.contentManager:switch(index)
	elseif action == "close" then
		self.contentManager:close()

		self.tabBar.current = self.contentManager.current
		self.tabBar:draw()
	elseif action == "create" then
		self.contentManager:create()
	end
end


function ContentTabLink:event(event)
	local cancel = false

	local action = self:getTabBarAction(event[1])
	if action then
		self:tabBarAction(action, event[2])
		self.tabBar:draw()
		cancel = true
	end

	if not cancel then
		cancel = self.tabBar:event(localiseEvent(event, TabBar.y))
	end

	if not cancel then
		cancel = self.contentManager:event(localiseEvent(event, Content.startY))
	end

	return cancel
end



--    Menu Bar


local MenuBar = {}
MenuBar.__index = MenuBar


MenuBar.y = 1


function MenuBar.new()
	local self = setmetatable({}, MenuBar)
	self:setup()
	return self
end


function MenuBar:setup()
	self.win = window.create(term.native(), 1, MenuBar.y, w, 1, false)
	self.currentURL = ""
	self.currentProtocol = ""
	self.visible = true
end


function MenuBar:readURL()
	term.redirect(self.win)
	self.win.setVisible(true)

	clear(theme.accent, theme.text)
	term.write(" " .. self.currentProtocol .. "://")

	local url = nil
	local readCoroutine = coroutine.create(function()
		url = read()
	end)

	coroutine.resume(readCoroutine)

	while coroutine.status(readCoroutine) ~= "dead" do
		local event = {os.pullEvent()}

		if event[1] == "mouse_click" then
			if event[4] ~= MenuBar.y then
				break
			end
		elseif event[1] == "key" then
			if event[2] == 29 or event[2] == 157 then
				break
			end
		end

		coroutine.resume(readCoroutine, unpack(event))
	end

	if url then
		self.currentURL = url
	end

	term.setCursorBlink(false)
	self:draw()

	return url
end


function MenuBar:draw()
	if self.visible then
		term.redirect(self.win)
		self.win.setVisible(true)

		clear(theme.accent, theme.text)
		term.write(" " .. self.currentProtocol .. "://" .. self.currentURL)
	else
		self.win.setVisible(false)
	end
end


function MenuBar:click(button, x, y)
	local cancel = false

	if y == MenuBar.y then
		cancel = true
		os.queueEvent(Events.openMenubar)
	end

	return cancel
end


function MenuBar:key(key)
	local cancel = false

	if key == 29 or key == 157 then
		cancel = true
		os.queueEvent(Events.openMenubar)
	end

	return cancel
end


function MenuBar:event(event)
	if event[1] == "mouse_click" then
		return self:click(event[2], event[3], event[4])
	elseif event[1] == "key" then
		return self:key(event[2])
	end
end



--    App


local App = {}
App.__index = App


function App.new()
	local self = setmetatable({}, App)
	self:setup()
	return self
end


function App:setup()
	self.tabBar = ContentTabLink.new()

	self.menuBar = MenuBar.new()
	self.menuBar.currentProtocol = "rdnt"
	self.menuBar.currentURL = "firewolf"
end


function App:readURLOnCurrentTab()
	local url = self.menuBar:readURL()

	if url then
		local tab = self.tabBar:getCurrentTab()
		tab:loadURL(url)
		self.tabBar:draw()
		self.menuBar.currentURL = tab.url
	end
end


function App:draw()
	self.tabBar:draw()
	self.menuBar:draw()
end


function App:event(event)
	local cancel = false

	if event[1] == Events.openMenubar then
		cancel = true
		self:readURLOnCurrentTab()
	end

	if not cancel then
		cancel = self.menuBar:event(localiseEvent(event, MenuBar.y))
	end

	if not cancel then
		cancel = self.tabBar:event(event)

		local tab = self.tabBar:getCurrentTab()
		if self.menuBar.currentURL ~= tab.url then
			self.menuBar.currentURL = tab.url
			self.menuBar:draw()
		end
	end
end


function App:main()
	self:draw()

	while true do
		local event = {os.pullEvent()}

		if event[1] == Events.exit then
			break
		end

		self:draw()
		self:event(event)
	end
end



--    Error Handling


local Error = {}
Error.__index = Error


function Error.new(msg)
	local self = setmetatable({}, Error)
	self:setup(msg)

	return self
end


function Error:setup(msg)
	self.msg = msg
end


function Error:shouldThrow()
	return self.msg and not self.msg:lower():find("terminate")
end


function Error:displayCrash()
	clear(theme.background, theme.text)

	fill(1, 3, w, 3, theme.accent)
	term.setCursorPos(1, 4)
	center("LuaIDE has crashed!")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 8)
	centerSplit(self.msg, w - 4)
	print("\n")
	center("Please report this error to")
	center("GravityScore.")
	print("")
	center("Press any key to exit.")

	os.pullEvent("key")
	os.queueEvent("")
	os.pullEvent()
end



--    Main


local function main()
	local app = App.new()
	app:main()
end


local originalTerminal = term.current()
local originalDir = shell.dir()
local _, errorMessage = pcall(main)
term.redirect(originalTerminal)
shell.setDir(originalDir)

local err = Error.new(errorMessage)
if err:shouldThrow() then
	err:displayCrash()
end


clear(colors.black, colors.white)
center("Thanks for using Firewolf " .. version)
center("Made by GravityScore and 1lann")
print("")
