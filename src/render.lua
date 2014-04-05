doc = [[
[<]
This is a left justified paragraph
[br]
[>]
This is a right justified paragraph

[br]
[=]

This is a center justified paragraph
[br]

[c red]

This text will be in red[br]
[bg white]The background c of this will be white[br]\[escaping brackets\][br]

text text text
stil on the same line!
[bg white][c yellow]
[br][br][right]This is a test[br]
sentence that is [c blue]used for[c yellow] testing,[br]
and is quite long[br]
[<]
[c red]r[c orange]a[c yellow]i[c lime]n[c green]
b[c lightBlue]o[c blue]w[c purple]s
[br]
[br]
[newlink rdnt://google.com]
[c lime]This is a link!
[endlink][br][marker back][br]
[c black]
[br]
[<]
[offset 0]
This is a test
[offset 26]
This is a test
[br]
[br]
[offset 0]
Back to normal!
[box lightBlue right 4 22 0]
[offset -2]
[>]
[br]
I'm writing in the[br]
box, pretty well.
]]

term.clear()

function parse(original)
	local data = original
	local function getLine(loc)
		local _, changes = original:sub(1,loc):gsub("\n","")
		if not changes then
			return 1
		else
			return changes+1
		end
	end

	local commands = {}
	local searchPos = 1
	--print(lineNum,": ",line)
	while #data > 0 do
		local sCmd, eCmd = data:find("%[[^%]]+%]",searchPos)
		if sCmd then
			sCmd = sCmd + 1
			eCmd = eCmd - 1
			if (sCmd > 2) then
				if data:sub(sCmd-2,sCmd-2) == "\\" then
					-- If it isn't the start, and is actually a string
					local t = data:sub(searchPos,sCmd-1):gsub("\n",""):gsub("\\%[","%["):gsub("\\%]","%]")
					if #t > 0 then
						if type(commands[#commands][1]) == "string" then
							commands[#commands][1] = commands[#commands][1]..t
						else
							table.insert(commands,{t})
						end
					end
					-- Ommit up to the escape string
					searchPos = sCmd
				else
					-- If it isn't the start and is a command
					-- Insert the first bit of data before the command
					local t = data:sub(searchPos,sCmd-2):gsub("\n",""):gsub("\\%[","%["):gsub("\\%]","%]")
					if #t > 0 then
						if type(commands[#commands][1]) == "string" then
							commands[#commands][1] = commands[#commands][1]..t
						else
							table.insert(commands,{t})
						end
					end
					-- Insert the command data
					t = data:sub(sCmd,eCmd):gsub("\n","")
					table.insert(commands,{getLine(sCmd),t})
					-- Ommit the first part and the command
					searchPos = eCmd+2
				end
			else
				-- Command is at the start
				local t = data:sub(sCmd,eCmd):gsub("\n","")
				table.insert(commands,{getLine(sCmd),t})
				-- Ommit just the command part
				searchPos = eCmd+2
			end
		else
			local t = data:sub(searchPos,-1):gsub("\n",""):gsub("\\%[","%["):gsub("\\%]","%]")
			if #t > 0 then
				if type(commands[#commands][1]) == "string" then
					commands[#commands][1] = commands[#commands][1]..t
				else
					table.insert(commands,{t})
				end
			end
			break
		end
	end

	searchIndex = 0
	while searchIndex < #commands do
		searchIndex = searchIndex+1
		local length = 0
		local origin = searchIndex
		if type(commands[searchIndex][1]) == "string" then
			length = length+#commands[searchIndex][1]
			local endIndex = origin
			for i = origin+1, #commands do
				if commands[i][2] and not((commands[i][2]:sub(1,2) == "c ") or
				(commands[i][2]:sub(1,3) == "bg ") or (commands[i][2]:sub(1,8) == "newlink ") or
				(commands[i][2] == "endlink")) then
					endIndex = i
					break
				elseif commands[i][2] then

				else
					length = length+#commands[i][1]
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

local function render(data,startScroll)
	local scroll
	local maxScroll
	if startScroll == nil then
		startScroll = 0
	end
	scroll = startScroll+1
	maxScroll = scroll

	local wid, hi = term.getSize()
	local childWidth = wid
	local collumn = 0

	local function left(text,_,length,offset)
		local x,y = term.getCursorPos()
		if (length) then
			term.setCursorPos(1+offset,scroll)
			term.write(text)
			return 1+offset
		else
			term.setCursorPos(x,scroll)
			term.write(text)
			return x
		end
	end
	local function right(text,width,length,offset)
		local x,y = term.getCursorPos()
		if (length) then
			term.setCursorPos((width-length+1)+offset,scroll)
			term.write(text)
			return (width-length+1)+offset
		else
			term.setCursorPos(x,scroll)
			term.write(text)
			return x
		end
	end
	local function center(text,_,length,offset,center)
		local x,y = term.getCursorPos()
		if (length) then
			term.setCursorPos(math.ceil(center-length/2)+offset,scroll)
			term.write(text)
			return math.ceil(center-length/2)+offset
		else
			term.setCursorPos(x,scroll)
			term.write(text)
			return x
		end
	end
	local align = left

	local linkData = {}

	-- Offset for offsetting from the left or right (make sure to also modify width where applicable)
	-- center is only for the center point of the center function Ex. for the entire screen, wid/2
	-- Right alignation requires a width to calculate the offset of the left (automatically)
	local function display(text,width,length,offset,center)
		if not offset then offset = 0 end
		return align(text,width,length,offset,center);
	end

	local blockLength = 0
	local link = false
	local linkStart = false
	local markers = {}
	local currentOffset = 0
	for k,v in pairs(data) do
		--if type(v) == "table" then
			if type(v[2]) ~= "string" then
				if v[2] then
					blockLength = v[2]
					if link and not linkStart then
						linkStart = display(v[1],childWidth,blockLength,currentOffset,wid/2)
					else
						display(v[1],childWidth,blockLength,currentOffset,wid/2)
					end
				else
					if link and not linkStart then
						linkStart = display(v[1],childWidth,nil,currentOffset,wid/2)
					else
						display(v[1],childWidth,nil,currentOffset,wid/2)
					end
				end
			elseif (v[2] == "<") or (v[2] == "left") then
				align = left
			elseif (v[2] == ">") or (v[2] == "right") then
				align = right
			elseif (v[2] == "=") or (v[2] == "center") then
				align = center
			elseif v[2] == "br" then
				if link then
					return "Cannot insert new line within a link on line "..v[1]
				end
				scroll = scroll+1
				maxScroll = math.max(scroll, maxScroll)
			elseif v[2]:sub(1,2) == "c " then
				local sColor = v[2]:sub(3,-1)
				if colors[sColor] then
					term.setTextColor(colors[sColor])
				else
					return "Invalid color: \""..sColor.."\" on line "..v[1]
				end
			elseif v[2]:sub(1,3) == "bg " then
				local sColor = v[2]:sub(4,-1)
				if colors[sColor] then
					term.setBackgroundColor(colors[sColor])
				else
					return "Invalid color: \""..sColor.."\" on line "..v[1]
				end
			elseif v[2]:sub(1,8) == "newlink " then
				link = v[2]:sub(9,-1)
				linkStart = false
			elseif v[2] == "endlink" then
				local linkEnd = term.getCursorPos()-1
				table.insert(linkData,{linkStart,linkEnd,scroll,link})
				link = false
				linkStart = false
			elseif v[2]:sub(1,7) == "offset " then
				local offset = tonumber(v[2]:sub(8,-1))
				if offset then
					currentOffset = offset
				else
					return "Invalid offset value: \""..v[2]:sub(8,-1).."\" on line "..v[1]
				end
			elseif v[2]:sub(1,7) == "marker " then
				markers[v[2]:sub(8,-1)] = scroll
			elseif v[2]:sub(1,5) == "goto " then
				local location = v[2]:sub(6,-1)
				if markers[location] then
					scroll = markers[location]
				else
					return "No such location: \""..v[2]:sub(6-1).."\" on line "..v[1]
				end
			elseif v[2]:sub(1,4) == "box " then
				local color, align, height, width, offset, url = v[2]:match("^box (%a+) (%a+) (%-?%d+) (%-?%d+) (%-?%d+) ?([^ ]*)")
				if not color then
					return "Invalid box syntax on line "..v[1]
				end
				local x,y = term.getCursorPos()
				local startX
				if (align == "center") or (align == "centre") then
					startX = math.ceil((wid/2)-width/2)+offset
				elseif align == "left" then
					startX = 1+offset
				elseif align == "right" then
					startX = (wid-width+1)+offset
				else
					return "Invalid align option for box on line "..v[1]
				end
				if not colors[color] then
					return "Invalid color: \""..sColor.."\" for box on line "..v[1]
				end
				term.setBackgroundColor(colors[color])
				for i = 0, height-1 do
					term.setCursorPos(startX, scroll+i)
					term.write(string.rep(" ",width))
					if url then
						table.insert(linkData,{startX,startX+width,scroll+i,url})
					end
				end
				maxScroll = math.max(scroll+height-1, maxScroll)
				term.setCursorPos(x,y)
			else
				return "Non-existent tag: \""..v[2].."\" on line "..v[1]
			end
		--end
	end

	return linkData, maxScroll-startScroll
end

local ret, length = render(parse(doc),0)
if type(ret) == "string" then
	printError(ret)
else
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
end
os.pullEvent("key")
print("")
print(length)
