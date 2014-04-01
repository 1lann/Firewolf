--    RDNT Protocol

local allowUnencryptedConnections = true

protocols["rdnt"] = {}


local calculateChannel = function(domain, distance)
	local total = 1
	
	if distance then
		if tostring(distance):find("%.") then
			local distProc = (tostring(distance):sub(1, tostring(distance):find("%.") + 1)):gsub("%.", "")
			total = tonumber(distProc)
		else
			total = distance
		end
	end

	for i = 1, #domain do
		total = total * string.byte(domain:sub(i, i))
		if total > 10000000000 then
			total = tonumber(tostring(total):sub(-5, -1))
		elseif tostring(total):sub(-1, -1) == "0" then
			total = tonumber(tostring(total):sub(1, -2))
		end
	end

	return (total % 50000) + 10000
end


protocols["rdnt"]["setup"] = function()
	for _, v in pairs(redstone.getSides()) do
		if peripheral.getType(v) == "modem" then
			local testModem = peripheral.wrap(v)
			if testModem.isWireless() then
				side = v
				modem = testModem
				return true
			end
		end
	end
	
	error("No modem found!")
end


protocols["rdnt"]["fetchAllSearchResults"] = function()
	local results = {}
	local toDelete = {}

	local checkResults = function(distance)
		local repeatedResults = {}
		for k, result in pairs(results) do
			if result == distance then
				if not repeatedResults[tostring(result)] then
					repeatedResults[tostring(result)] = 1
				elseif repeatedResults[tostring(result)] >= limitPerSerresulter - 1 then
					table.insert(toDelete, result)
					return false
				else
					repeatedResults[tostring(result)] = repeatedResults[tostring(result)] + 1
				end
			end
		end

		return true
	end

	modem.open(publicResponseChannel)
	modem.open(publicDNSChannel)

	if allowUnencryptedConnections then
		rednet.open(side)
		rednet.broadcast(listToken, listToken)
	end

	modem.transmit(publicDNSChannel, responseID, listToken)
	modem.close(publicDNSChannel)

	local timer = os.startTimer(searchResultTimeout)
	while true do
		local event, connectionSide, channel, verify, msg, distance = os.pullEvent()

		if event == "modem_message" and connectionSide == side and channel == publicResponseChannel and verify == responseID then
			if msg:match(DNSToken) and #msg:match(DNSToken) >= 4 and #msg:match(DNSToken) <= 30 then
				if checkResults(distance) then
					results[msg:match(DNSToken)] = distance
				end
			end
		elseif event == "rednet_message" and channel == listToken and allowUnencryptedConnections then
			if connectionSide:match(DNSToken) and #connectionSide:match(DNSToken) >= 4 and #connectionSide:match(DNSToken) <= 30 then
				results[connectionSide:match(DNSToken)] = -1
			end
		elseif event == "timer" and connectionSide == timer then
			local finalResult = {}
			for k, v in pairs(results) do
				local shouldDelete = false
				for b, n in pairs(toDelete) do
					if v > 0 and tostring(n) == tostring(v) then
						shouldDelete = true
					end
				end

				if not shouldDelete then
					table.insert(finalResult, k:lower())
				end
			end
			if allowUnencryptedConnections then
				rednet.close(side)
			end
			modem.close(publicResponseChannel)
			return finalResult
		end
	end
end


protocols["rdnt"]["fetchConnectionObject"] = function(url)
	local channel = calculateChannel(url)
	local results = {}
	local unencryptedResults = {}

	local checkDuplicate = function(distance)
		for k, v in pairs(results) do
			if v.dist == distance then
				return true
			end
		end

		return false
	end

	local checkRednetDuplicate = function(id)
		for k, v in pairs(unencryptedResults) do
			if v.id == id then
				return true
			end
		end

		return false
	end

	if allowUnencryptedConnections then
		rednet.open(side)
		local ret = {rednet.lookup(protocolToken .. url, initiateToken .. url)}
		for k,v in pairs(ret) do
			table.insert(unencryptedResults, {
				dist = v,
				channel = -1,
				url = url,
				encrypted = false,
				id = v,

				fetchPage = function(page)
					if not rednet.isOpen(side) then
						rednet.open(side)
					end

					local fetchTimer = os.startTimer(fetchTimeout)
					rednet.send(v, crypt(fetchToken .. url .. page, url .. tostring(os.getComputerID())), protocolToken .. url)
					
					while true do
						local event, fetchId, fetchMessage, fetchProtocol = os.pullEvent()
						if event == "rednet_message" and fetchId == v and fetchProtocol == (protocolToken .. url) then
							local data = crypt(textutils.unserialize(fetchMessage),url .. tostring(os.getComputerID())):match(receiveToken)
							if data then
								rednet.close(side)
								return data
							end
						elseif event == "timer" and fetchId == fetchTimer then
							rednet.close(side)
							return nil
						end
					end
				end,

				close = function()
					if not(rednet.isOpen(side)) then
						rednet.open(side)
					end
					rednet.send(v, crypt(disconnectToken, url .. tostring(os.getComputerID())), protocolToken .. url)
					rednet.close(side)
				end
			})
		end
	end

	modem.closeAll()
	modem.open(channel)
	modem.transmit(channel, responseID, initiateToken .. url)

	local timer = os.startTimer(initiationTimeout)
	while true do
		local event, connectionSide, connectionChannel, verify, msg, distance = os.pullEvent()

		if event == "modem_message" and connectionSide == side and connectionChannel == channel and verify == responseID then
			if crypt(textutils.unserialize(msg), tostring(distance) .. url):match(connectToken) == url and 
					not checkDuplicate(distance) then
				local calculatedChannel = calculateChannel(url, distance)
				table.insert(results, {
					dist = distance,
					channel = calculatedChannel,
					url = url,
					encrypted = true,

					fetchPage = function(page)
						if not modem.isOpen(calculatedChannel) then
							modem.open(calculatedChannel)
						end

						local fetchTimer = os.startTimer(fetchTimeout)
						modem.transmit(calculatedChannel, responseID, crypt(fetchToken .. url .. page, url .. tostring(distance)))
						
						while true do
							local event, fetchSide, fetchChannel, fetchVerify, fetchMessage, fetchDistance = os.pullEvent()
							
							if event == "modem_message" and fetchSide == side and fetchChannel == calculatedChannel and 
									fetchVerify == responseID and fetchDistance == distance then
								local data = crypt(textutils.unserialize(fetchMessage), url .. tostring(fetchDistance)):match(receiveToken)
								if data then
									modem.close(calculatedChannel)
									return data
								end
							elseif event == "timer" and fetchSide == fetchTimer then
								modem.close(calculatedChannel)
								return nil
							end
						end
					end,

					close = function()
						if not(modem.isOpen(calculatedChannel)) then
							modem.open(calculatedChannel)
						end
						modem.transmit(calculatedChannel, responseID, crypt(disconnectToken, url .. tostring(distance)))
						modem.close(calculatedChannel)
					end
				})
			end
		elseif event == "timer" and connectionSide == timer then
			modem.close(channel)

			if #results == 0 then
				if #unencryptedResults == 0 then
					return nil
				elseif #unencryptedResults == 1 then
					return unencryptedResults[1]
				else
					local finalResult = {multipleServers = true, servers = unencryptedResults}
					return finalResult
				end
			end
			elseif #results == 1 then
				return results[1]
			else
				local finalResult = {multipleServers = true, servers = results}
				return finalResult
			end
		end
	end
end