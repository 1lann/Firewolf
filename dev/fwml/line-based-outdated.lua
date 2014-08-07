
local w, h = term.getSize()



--    FWML


local FWML = {}


function FWML.split(str, separator)
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



FWML.Line = {}
FWML.Line.__index = FWML.Line


function FWML.Line.new()
	local self = setmetatable({}, FWML.Line)
	self:setup()
	return self
end


function FWML.Line:setup()
	self.text = (" "):rep(w)
	self.bg = ("0"):rep(w)
	self.fg = ("f"):rep(w)
end


function FWML.Line:apply(line, pos, value)
	if pos <= line:len() then
		line = line:sub(1, x - 1) .. text .. line:sub(x + 1)
	end

	return line
end


function FWML.Line:set(x, text, fg, bg)
	self.text = self:apply(self.text, x, text)
	self.bg = self:apply(self.bg, x, bg)
	self.fg = self:apply(self.fg, x, fg)
end


function FWML.Line:setBg(x, bg)
	self.bg = self:apply(self.bg, x, bg)
end


function FWML.Line:at(x)
	return self.text:sub(x, x), self.fg:sub(x, x), self.bg:sub(x, x)
end



FWML.Color = {}


function FWML.Color.fromSymbol(symbol)
	if symbol and symbol:find("^[0-9a-f]$") then
		return 2 ^ (15 - tonumber(symbol, 16))
	else
		error("Invalid color")
	end
end


function FWML.Color.represent(color)
	local representations = {
		["white"] = "f",
		["orange"] = "e",
		["magenta"] = "d",
		["lightBlue"] = "c",
		["yellow"] = "b",
		["lime"] = "a",
		["pink"] = "9",
		["gray"] = "8",
		["lightGray"] = "7",
		["cyan"] = "6",
		["purple"] = "5",
		["blue"] = "4",
		["brown"] = "3",
		["green"] = "2",
		["red"] = "1",
		["black"] = "0",
	}

	return representations[color]
end



function FWML.applyColor(lines, var, x, y, color)
	local color = FWML.Color.represent(color)
	local num = FWML.Color.fromSymbol(color)

	if num <= colors.black and num >= colors.white then
		local line = lines[y]
		print(y, var, line, tostring(line[var]), textutils.serialize(line))

		local len = line[var]:len() - x + 1
		lines[y][var] = line[var]:sub(1, x - 1) .. color:rep(len)
	else
		error("Invalid color")
	end

	return lines
end



FWML.commands = {
	["c"] = function(lines, x, y, ...)
		return FWML.applyColor(lines, "fg", x, y, ...)
	end,

	["color"] = function(lines, x, y, ...)
		return FWML.applyColor(lines, "fg", x, y, ...)
	end,

	["bg"] = function(lines, x, y, ...)
		return FWML.applyColor(lines, "bg", x, y, ...)
	end,

	["background"] = function(lines, x, y, ...)
		return FWML.applyColor(lines, "bg", x, y, ...)
	end,

	["box"] = function(lines, x, y, color, startX, startY, width, height)
		local actualColor = FWML.Color.represent(color)
		if not actualColor then
			error("Invalid color")
		end

		for bx = startX, startX + width - 1 do
			for by = startY, startY + height - 1 do
				lines[y]:setBg(bx, color)
			end
		end

		return lines
	end,
}



function FWML.extractCommandsFromLine(y, line)
	local actualLine = line:gsub("%[.-%]", "")
	local err = nil
	local removedSpacing = 0
	local commands = {}

	local pos = 1
	while pos <= line:len() do
		local startX, endX = line:find("%[.-%]", pos)
		if startX and endX then
			local command = line:sub(startX + 1, endX - 1)
			local parts = FWML.split(command, "%s+")

			if FWML.commands[parts[1]] then
				local actualX = startX - removedSpacing
				local name = parts[1]
				table.remove(parts, 1)

				local cmd = {
					["name"] = name,
					["x"] = actualX,
					["args"] = parts,
				}

				table.insert(commands, cmd)
			else
				err = "Unrecognised command on line:\n" .. line
				commands = nil
				actualLine = nil
				break
			end

			removedSpacing = removedSpacing + (endX - startX + 1)
			pos = endX + 1
		else
			break
		end
	end

	return commands, actualLine, err
end


function FWML.parse(contents)
	contents = contents:gsub("\n", "")
	if contents:sub(-4, -1) == "[br]" then
		contents = contents:sub(1, -5)
	end

	local textLines = FWML.split(contents, "%[br%]")
	local lines = {}
	local data = {}
	local err = nil

	for y = 1, h do
		local line = FWML.Line.new()
		table.insert(lines, line)
	end

	for y, text in pairs(textLines) do
		local commands, text, err = FWML.extractCommandsFromLine(y, text)
		if err then
			break
		end

		local line = FWML.Line.new()
		line.text = text
		line.commands = commands

		lines[y] = line
	end

	for y, line in pairs(lines) do
		if line.commands then
			for i, command in pairs(line.commands) do
				lines = FWML.commands[command.name](lines, command.x, y, unpack(command.args))
			end
		end
	end

	return lines
end


function FWML.render(lines, scroll)
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)

	for y, line in pairs(lines) do
		local actualY = y - scroll
		if actualY >= 1 and actualY <= h then
			term.setCursorPos(1, actualY)

			for x = 1, w do
				local letter, fg, bg = line:at(x)

				term.setTextColor(FWML.Color.fromSymbol(fg))
				term.setBackgroundColor(FWML.Color.fromSymbol(bg))
				term.write(letter)
			end
		end
	end
end


function FWML.getExecutionFunction(contents)

end



local text = [[
he[bg white]llo the[c red]r[c orange]e[br]
mehhh[br]
lulz
[box lightBlue 5 3 2 2]
]]

local lines = FWML.parse(text)
FWML.render(lines, 0)
os.pullEvent("key")
