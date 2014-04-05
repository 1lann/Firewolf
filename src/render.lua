--    Running websites

local function getLine(loc, data)
	local _, changes = data:sub(1,loc):gsub("\n","")
	if not changes then
		return 1
	else
		return changes+1
	end
end

local function parseData(data)
	local commands = {}
	local searchPos = 1
	while #data > 0 do
		local sCmd, eCmd = data:find("%[[^%]]+%]",searchPos)
		if sCmd then
			sCmd = sCmd + 1
			eCmd = eCmd - 1
			if (sCmd > 2) then
				if data:sub(sCmd-2,sCmd-2) == "\\" then
					local t = data:sub(searchPos,sCmd-1):gsub("\n",""):gsub("\\%[","%["):gsub("\\%]","%]")
					if #t > 0 then
						if type(commands[#commands][1]) == "string" then
							commands[#commands][1] = commands[#commands][1]..t
						else
							table.insert(commands,{t})
						end
					end
					searchPos = sCmd
				else
					local t = data:sub(searchPos,sCmd-2):gsub("\n",""):gsub("\\%[","%["):gsub("\\%]","%]")
					if #t > 0 then
						if type(commands[#commands][1]) == "string" then
							commands[#commands][1] = commands[#commands][1]..t
						else
							table.insert(commands,{t})
						end
					end
					t = data:sub(sCmd,eCmd):gsub("\n","")
					table.insert(commands,{getLine(sCmd, data),t})
					searchPos = eCmd+2
				end
			else
				local t = data:sub(sCmd,eCmd):gsub("\n","")
				table.insert(commands,{getLine(sCmd, data),t})
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
	return commands
end

local function proccessData(commands)
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

local function parse(original)
	return proccessData(parseData(original))
end

local render = {}

render["variables"] = {
	scroll,
	maxScroll,
	align,
	linkData = {},
	blockLength,
	link,
	linkStart,
	markers,
	currentOffset
}

render["functions"] = {}
render["functions"]["public"] = {}
render["alignations"] = {}

render["functions"]["display"] = function(text,length,offset,center)
	if not offset then offset = 0 end
	return render.variables.align(text,length,w,offset,center);
end

render["functions"]["displayText"] = function(source)
	if source[2] then
		render.variables.blockLength = source[2]
		if render.variables.link and not render.variables.linkStart then
			render.variables.linkStart = render.functions.display(
				source[1],render.variables.blockLength,render.variables.currentOffset,w/2)
		else
			render.functions.display(source[1],render.variables.blockLength,render.variables.currentOffset,w/2)
		end
	else
		if render.variables.link and not render.variables.linkStart then
			render.variables.linkStart = render.functions.display(source[1],nil,render.variables.currentOffset,w/2)
		else
			render.functions.display(source[1],nil,render.variables.currentOffset,w/2)
		end
	end
end

render["functions"]["public"]["br"] = function(source)
	if render.variables.link then
		return "Cannot insert new line within a link on line "..source[1]
	end
	render.variables.scroll = render.variables.scroll+1
	render.variables.maxScroll = math.max(render.variables.scroll, render.variables.maxScroll)
end

render["functions"]["public"]["c "] = function(source)
	local sColor = source[2]:sub(3,-1)
	if colors[sColor] then
		term.setTextColor(colors[sColor])
	else
		return "Invalid color: \""..sColor.."\" on line "..source[1]
	end
end

render["functions"]["public"]["bg "] = function(source)
	local sColor = source[2]:sub(3,-1)
	if colors[sColor] then
		term.setBackgroundColor(colors[sColor])
	else
		return "Invalid color: \""..sColor.."\" on line "..source[1]
	end
end

render["functions"]["public"]["newlink "] = function(source)
	if render.variables.link then
		return "Cannot nest links on line "..source[1]
	end
	render.variables.link = source[2]:sub(9,-1)
	render.variables.linkStart = false
end

render["functions"]["public"]["endlink"] = function(source)
	if not render.variables.link then
		return "Cannot end a link without a link on line "..source[1]
	end
	local linkEnd = term.getCursorPos()-1
	table.insert(render.variables.linkData,{render.variables.linkStart,
		render.variables.linkEnd,render.variables.scroll,render.variables.link})
	render.variables.link = false
	render.variables.linkStart = false
end

render["functions"]["public"]["offset "] = function(source)
	local offset = tonumber(source[2]:sub(8,-1))
	if offset then
		render.variables.currentOffset = offset
	else
		return "Invalid offset value: \"" .. source[2]:sub(8,-1) .. "\" on line " .. source[1]
	end
end

render["functions"]["public"]["marker "] = function(source)
	render.variables.markers[source[2]:sub(8,-1)] = render.variables.scroll
end

render["functions"]["public"]["goto "] = function(source)
	local location = source[2]:sub(6,-1)
	if render.variables.markers[location] then
		render.variables.scroll = render.variables.markers[location]
	else
		return "No such location: \"" .. source[2]:sub(6-1) .. "\" on line " .. source[1]
	end
end

render["functions"]["public"]["box "] = function(source)
	local sColor, align, height, width, offset, url = source[2]:match("^box (%a+) (%a+) (%-?%d+) (%-?%d+) (%-?%d+) ?([^ ]*)")
	if not sColor then
		return "Invalid box syntax on line "..source[1]
	end
	local x,y = term.getCursorPos()
	local startX
	if (render.variables.align == "center") or (render.variables.align == "centre") then
		startX = math.ceil((w/2)-width/2)+offset
	elseif align == "left" then
		startX = 1+offset
	elseif align == "right" then
		startX = (w-width+1)+offset
	else
		return "Invalid align option for box on line "..source[1]
	end
	if not colors[sColor] then
		return "Invalid color: \""..sColor.."\" for box on line "..source[1]
	end
	term.setBackgroundColor(colors[sColor])
	for i = 0, height-1 do
		term.setCursorPos(startX, render.variables.scroll+i)
		term.write(string.rep(" ",width))
		if url then
			table.insert(render.variables.linkData,{startX,startX+width,render.variables.scroll+i,url})
		end
	end
	render.variables.maxScroll = math.max(render.variables.scroll+height-1, render.variables.maxScroll)
	term.setCursorPos(x,y)
end

render["alignations"]["left"] = function(text,length,_,offset)
	local x,y = term.getCursorPos()
	if (length) then
		term.setCursorPos(1+offset,render.variables.scroll)
		term.write(text)
		return 1+offset
	else
		term.setCursorPos(x,render.variables.scroll)
		term.write(text)
		return x
	end
end


render["alignations"]["right"] = function(text,length,width,offset)
	local x,y = term.getCursorPos()
	if (length) then
		term.setCursorPos((width-length+1)+offset,render.variables.scroll)
		term.write(text)
		return (width-length+1)+offset
	else
		term.setCursorPos(x,render.variables.scroll)
		term.write(text)
		return x
	end
end


render["alignations"]["center"] = function(text,length,_,offset,center)
	local x,y = term.getCursorPos()
	if (length) then
		term.setCursorPos(math.ceil(center-length/2)+offset,render.variables.scroll)
		term.write(text)
		return math.ceil(center-length/2)+offset
	else
		term.setCursorPos(x,render.variables.scroll)
		term.write(text)
		return x
	end
end

render["render"] = function(data,startScroll)
	if startScroll == nil then
		render.variables.startScroll = 0
	else
		render.variables.startScroll = startScroll
	end
	
	render.variables.scroll = startScroll+1
	render.variables.maxScroll = render.variables.scroll

	render.variables.linkData = {}

	render.variables.align = render.alignations.left

	render.variables.blockLength = 0
	render.variables.link = false
	render.variables.linkStart = false
	render.variables.markers = {}
	render.variables.currentOffset = 0

	for k,v in pairs(data) do
		if type(v[2]) ~= "string" then
			render.functions.displayText(v)
		elseif (v[2] == "<") or (v[2] == "left") then
			render.variables.align = render.alignations.left
		elseif (v[2] == ">") or (v[2] == "right") then
			render.variables.align = render.alignations.right
		elseif (v[2] == "=") or (v[2] == "center") then
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
				return "Non-existent tag: \""..v[2].."\" on line "..v[1]
			end
		end
	end

	return render.variables.linkData, render.variables.maxScroll-render.variables.startScroll
end