for i = 1, 3 do
	local response = http.get("https://raw.github.com/1lann/firewolf/master/server/server-cloudata.lua")
	if response then
		local data = response.readAll()
		response.close()
		local servFunc = loadstring(data)
		setfenv(servFunc, getfenv(0))
		servFunc()
		return true
	end
end
error("Could not load Firewolf Server Cloud/Lite")