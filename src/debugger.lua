local startClock = os.clock()

local f = io.open("debug","w")
f:write("-- Session Start --")
f:close()

local debug = function(...)
	local f = io.open("debug","a")
	local data = ""
	local args = {...}
	for k,v in pairs(args) do
		if type(v) == "table" then
			data = data.."\n"..os.clock()-startClock.." ".."table"
		else
			data = data.."\n"..os.clock()-startClock.." "..tostring(v)
		end
	end
	f:write(data)
	f:close()
end