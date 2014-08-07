

FWML = {}
local w, h = term.getSize()

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


local function split(str, separator)
	local pos = 1
	local results = {}

	while pos <= str:len() do
		local splitStart, splitEnd = str:find(separator, pos)
		if splitStart and splitEnd then
			local split = str:sub(pos, splitStart - 1)
			table.insert(results, split)

			pos = splitEnd + 1
		else
			local split = str:sub(pos)
			table.insert(results, split)

			pos = str:len() + 1
		end
	end

	return results
end


FWML.aliases = {
	["fg"] = {"fg", "c", "color"},
	["bg"] = {"bg", "background"},
	["left"] = {"left", "<"},
	["center"] = {"center", "="},
	["right"] = {"right", ">"},

}


function FWML.resolveAlias(alias)

end


function FWML.findCommandStart(text)
	local location = text:find("%[")

	while location do
		if location and text:sub(location - 1, location - 1) == "\\" then
			location = text:find("%[", location + 1)
		else
			break
		end
	end

	return location
end


function FWML.findCommandEnd(text)
	local location = text:find("%]")

	while location do
		if location and text:sub(location - 1, location - 1) == "\\" then
			location = text:find("%]", location + 1)
		else
			break
		end
	end

	return location
end


function FWML.parseCommand(text)
	local command = {
		["type"] = "command",
	}

	-- Cut out the brackets
	text = text:sub(2):sub(1, -2)

	local words = {}
	for word in text:gmatch("[^%s]+") do
		word = word:lower()
		table.insert(words, word)
	end

	command.name = FWML.resolveAlias(words[1])
	table.remove(words, 1)

	if command.name == "fg" or command.name == "bg" then
		-- One argument
		if #words < 1 then
			error("Insufficient arguments to command " .. command.name)
		end

		command.color = words[1]
	elseif command.name == "link" then
		-- One argument
		if #words < 1 then
			error("Insufficient arguments to command " .. command.name)
		end

		command.url = words[1]
	elseif command.name == "box" then
		-- 4 arguments
		if #words < 4 then
			error("Insufficient arguments to command " .. command.name)
		end

		command.x = words[1]
		command.y = words[2]
		command.width = words[3]
		command.height = words[4]
	end

	return command
end


function FWML.parse(lines)
	-- Link:
	-- minX
	-- maxX
	-- y
	-- url

	-- Commands:
	-- Alignment
	--	Concat all text up to end of line or next alignment change
	--	Calculate length
	--	Draw from alignment location on length
	-- Color (foreground, background)
	-- Links ([link url]text[/link])
	--	rdnt:// prefix instantly global
	--	URL priority: local, global if rdnt:// missing
	-- Boxes (encased in [box x y w h]text[/box])
	--	Word wrapping in box, margin of 1
	--	Wrap all text up to end of box (ignoring lines)
	--	br should indicate new line in box
	--	Truncate words extending off edge of box
	--	Respect bg (whole of box, change in middle) and fg (whole of box, change in middle)

	-- Data:
	-- Line by line
	-- {text, command, command, text, command, text}

	local commands = {}

	for y = 1, #lines do
		local text = lines[y]
		print("parsing line " .. text)

		local line = {}

		-- If the line doesn't start with a command,
		-- add the text before the first command
		local start = FWML.findCommandStart(text)
		if not start then
			start = text:len() + 1
		end

		if start then
			local t = text:sub(1, start - 1)
			text = text:sub(start)
			table.insert(line, {["type"] = "text", ["content"] = t})
			print("starting text " .. t)
			print("remaining " .. text)
		end

		while text:len() > 0 do
			-- Find end of command
			local commandEnd = FWML.findCommandEnd(text)
			if not commandEnd then
				error("Mismatched command brakets ('[' and ']')")
			end

			-- Get the command, and cut it out of the text
			local command = text:sub(1, commandEnd)
			text = text:sub(commandEnd + 1)
			print("command " .. command)
			print("remaining " .. text)
			table.insert(line, FWML.parseCommand(command))

			-- Find the start of the next command (or end of line)
			local commandStart = FWML.findCommandStart(text)
			if not commandStart then
				commandStart = text:len() + 1
			end

			-- Add the text up to the start of the next command
			local t = text:sub(1, commandStart - 1)
			text = text:sub(commandStart)
			print("ending text " .. t)
			print("remaining " .. text)
			if t:len() > 0 then
				table.insert(line, t)
			end
		end

		table.insert(commands, line)
	end

	return commands
end


function FWML.preprocess(contents)
	contents = contents:gsub("\n", "")

	-- Concat [br] inside a box into \n
	while true do
		local startS, startE = contents:find("%[%s*box.+%]")
		if startS then
			local endS, endE = contents:find("%[%s*/%s*box%s*%]", startE + 1)
			if not endS then
				error("Couldn't find matching [/box] for [box] tag")
			end

			local newContent = contents:sub(startS, endE):gsub("[br]", "\n")
			contents = contents:sub(1, startS - 1) .. newContent .. contents:sub(endE + 1)
		else
			break
		end
	end

	local lines = split(contents, "%[br%]")
	if lines[#lines] == "" then
		table.remove(lines, #lines)
	end

	return lines
end


function FWML.render(lines, scroll)
	local height = math.min(#lines, h)

	local state = {
		["bgColor"] = colors.black,
		["fgColor"] = colors.white,
		["alignment"] = "left",
		["links"] = {},
	}

	for y = 1, height do
		local line = lines[y]

		for _, command in pairs(line) do
			if command.type == "command" then
				if command.name == "bg" then

				elseif command.name == "fg" then

				elseif command.name == "left" or command.name == "right" or
						command.name == "center" then
					state.alignment = command.name
				elseif command.
			else

			end
		end
	end
end


function FWML.click(x, y, links)
	for _, link in pairs(links) do
		if x >= link.minX and x <= link.maxX and y == link.y then
			redirect(link.url)
		end
	end
end


function FWML.scroll(dir, data, scroll, height)
	local links, height

	if scroll - dir - h >= -pageHeight and scroll - dir <= 0 then
		scroll = scroll - dir
		clear(theme.background, theme.text)
		_, links, height = FWML.render(data, scroll)
	end

	return scroll, links, height
end


function FWML.key(key, data, scroll, height)
	local amount
	if key == keys.up then
		amount = 1
	elseif key == keys.down then
		amount = -1
	end

	local links, height
	if amount and scroll + amount - h >= -pageHeight and scroll + amount <= 0 then
		scroll = scroll + amount
		clear(theme.background, theme.text)
		_, links, height = render.render(data, currentScroll)
	end

	return scroll, links, height
end


function FWML.getExecutionFunction(contents)
	local fn = nil
	local data = nil
--	local _, err = pcall(function()
		data = FWML.parse(FWML.preprocess(contents))
--	end)

	if err then
		fn = InternalSites.helperPage("error", err)
	else
		fn = function()
			local scroll = 0
			local err, links, height = pcall(function()
				FWML.render(data, scroll)
			end)

			if not err then
				InternalSites.helperPage("error", err)()
			else
				while true do
					local event = {os.pullEvent()}

					if event[1] == "mouse_click" then
						FWML.click(event[3], event[4], links)
					elseif event[1] == "mouse_scroll" then
						local nscroll, nlinks, nheight =
							FWML.scroll(event[2], data, scroll, height)

						scroll = nscroll or scroll
						links = nlinks or links
						height = nheight or height
					elseif event[1] == "key" then
						local nscroll, nlinks, nheight =
							FWML.key(event[2], data, scroll, height)

						scroll = nscroll or scroll
						links = nlinks or links
						height = nheight or height
					end
				end
			end
		end
	end

	return fn
end


local test = [[
testmehh[bg red]mehmore[br]
lulz[br]
]]

local parsed = FWML.parse(FWML.preprocess(test))

print(textutils.serialize(parsed))
