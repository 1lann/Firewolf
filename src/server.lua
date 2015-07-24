--
--  Firewolf Server
--  Made by 1lann and GravityScore
--

--  Networking API
	--  RC4
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


		local crypt = function(text, key)
			local resp, msg = pcall(cryptWrapper, text, key)
			if resp then
				return msg
			else
				return nil
			end
		end


	--  Base64
		--
		--  Base64 Encryption/Decryption
		--  By KillaVanilla
		--  http://www.computercraft.info/forums2/index.php?/topic/12450-killavanillas-various-apis/
		--  http://pastebin.com/rCYDnCxn
		--



		local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


		local function sixBitToBase64(input)
			return string.sub(alphabet, input+1, input+1)
		end


		local function base64ToSixBit(input)
			for i=1, 64 do
				if input == string.sub(alphabet, i, i) then
					return i-1
				end
			end
		end


		local function octetToBase64(o1, o2, o3)
			local shifted = bit.brshift(bit.band(o1, 0xFC), 2)
			local i1 = sixBitToBase64(shifted)
			local i2 = "A"
			local i3 = "="
			local i4 = "="
			if o2 then
				i2 = sixBitToBase64(bit.bor( bit.blshift(bit.band(o1, 3), 4), bit.brshift(bit.band(o2, 0xF0), 4) ))
				if not o3 then
					i3 = sixBitToBase64(bit.blshift(bit.band(o2, 0x0F), 2))
				else
					i3 = sixBitToBase64(bit.bor( bit.blshift(bit.band(o2, 0x0F), 2), bit.brshift(bit.band(o3, 0xC0), 6) ))
				end
			else
				i2 = sixBitToBase64(bit.blshift(bit.band(o1, 3), 4))
			end
			if o3 then
				i4 = sixBitToBase64(bit.band(o3, 0x3F))
			end

			return i1..i2..i3..i4
		end


		local function base64ToThreeOctet(s1)
			local c1 = base64ToSixBit(string.sub(s1, 1, 1))
			local c2 = base64ToSixBit(string.sub(s1, 2, 2))
			local c3 = 0
			local c4 = 0
			local o1 = 0
			local o2 = 0
			local o3 = 0
			if string.sub(s1, 3, 3) == "=" then
				c3 = nil
				c4 = nil
			elseif string.sub(s1, 4, 4) == "=" then
				c3 = base64ToSixBit(string.sub(s1, 3, 3))
				c4 = nil
			else
				c3 = base64ToSixBit(string.sub(s1, 3, 3))
				c4 = base64ToSixBit(string.sub(s1, 4, 4))
			end
			o1 = bit.bor( bit.blshift(c1, 2), bit.brshift(bit.band( c2, 0x30 ), 4) )
			if c3 then
				o2 = bit.bor( bit.blshift(bit.band(c2, 0x0F), 4), bit.brshift(bit.band( c3, 0x3C ), 2) )
			else
				o2 = nil
			end
			if c4 then
				o3 = bit.bor( bit.blshift(bit.band(c3, 3), 6), c4 )
			else
				o3 = nil
			end
			return o1, o2, o3
		end


		local function splitIntoBlocks(bytes)
			local blockNum = 1
			local blocks = {}
			for i=1, #bytes, 3 do
				blocks[blockNum] = {bytes[i], bytes[i+1], bytes[i+2]}
				blockNum = blockNum+1
			end
			return blocks
		end


		function base64Encode(bytes)
			local blocks = splitIntoBlocks(bytes)
			local output = ""
			for i=1, #blocks do
				output = output..octetToBase64( unpack(blocks[i]) )
			end
			return output
		end


		function base64Decode(str)
			local bytes = {}
			local blocks = {}
			local blockNum = 1

			for i=1, #str, 4 do
				blocks[blockNum] = string.sub(str, i, i+3)
				blockNum = blockNum+1
			end

			for i=1, #blocks do
				local o1, o2, o3 = base64ToThreeOctet(blocks[i])
				table.insert(bytes, o1)
				table.insert(bytes, o2)
				table.insert(bytes, o3)
			end

			return bytes
		end


	--  SHA-256
		--
		--  Adaptation of the Secure Hashing Algorithm (SHA-244/256)
		--  Found Here: http://lua-users.org/wiki/SecureHashAlgorithm
		--
		--  Using an adapted version of the bit library
		--  Found Here: https://bitbucket.org/Boolsheet/bslf/src/1ee664885805/bit.lua
		--



		local MOD = 2^32
		local MODM = MOD-1


		local function memoize(f)
			local mt = {}
			local t = setmetatable({}, mt)
			function mt:__index(k)
				local v = f(k)
				t[k] = v
				return v
			end
			return t
		end


		local function make_bitop_uncached(t, m)
			local function bitop(a, b)
				local res,p = 0,1
				while a ~= 0 and b ~= 0 do
					local am, bm = a % m, b % m
					res = res + t[am][bm] * p
					a = (a - am) / m
					b = (b - bm) / m
					p = p * m
				end
				res = res + (a + b) * p
				return res
			end

			return bitop
		end


		local function make_bitop(t)
			local op1 = make_bitop_uncached(t,2^1)
			local op2 = memoize(function(a)
				return memoize(function(b)
					return op1(a, b)
				end)
			end)
			return make_bitop_uncached(op2, 2 ^ (t.n or 1))
		end


		local customBxor1 = make_bitop({[0] = {[0] = 0,[1] = 1}, [1] = {[0] = 1, [1] = 0}, n = 4})

		local function customBxor(a, b, c, ...)
			local z = nil
			if b then
				a = a % MOD
				b = b % MOD
				z = customBxor1(a, b)
				if c then
					z = customBxor(z, c, ...)
				end
				return z
			elseif a then
				return a % MOD
			else
				return 0
			end
		end


		local function customBand(a, b, c, ...)
			local z
			if b then
				a = a % MOD
				b = b % MOD
				z = ((a + b) - customBxor1(a,b)) / 2
				if c then
					z = customBand(z, c, ...)
				end
				return z
			elseif a then
				return a % MOD
			else
				return MODM
			end
		end


		local function bnot(x)
			return (-1 - x) % MOD
		end


		local function rshift1(a, disp)
			if disp < 0 then
				return lshift(a, -disp)
			end
			return math.floor(a % 2 ^ 32 / 2 ^ disp)
		end


		local function rshift(x, disp)
			if disp > 31 or disp < -31 then
				return 0
			end
			return rshift1(x % MOD, disp)
		end


		local function lshift(a, disp)
			if disp < 0 then
				return rshift(a, -disp)
			end
			return (a * 2 ^ disp) % 2 ^ 32
		end


		local function rrotate(x, disp)
		    x = x % MOD
		    disp = disp % 32
		    local low = customBand(x, 2 ^ disp - 1)
		    return rshift(x, disp) + lshift(low, 32 - disp)
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
			return (string.gsub(s, ".", function(c)
				return string.format("%02x", string.byte(c))
			end))
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
			for i = i, i + 3 do
				n = n*256 + string.byte(s, i)
			end
			return n
		end


		local function preproc(msg, len)
			local extra = 64 - ((len + 9) % 64)
			len = num2s(8 * len, 8)
			msg = msg .. "\128" .. string.rep("\0", extra) .. len
			assert(#msg % 64 == 0)
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
			for j = 1, 16 do
				w[j] = s232num(msg, i + (j - 1)*4)
			end
			for j = 17, 64 do
				local v = w[j - 15]
				local s0 = customBxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
				v = w[j - 2]
				w[j] = w[j - 16] + s0 + w[j - 7] + customBxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
			end

			local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
			for i = 1, 64 do
				local s0 = customBxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
				local maj = customBxor(customBand(a, b), customBand(a, c), customBand(b, c))
				local t2 = s0 + maj
				local s1 = customBxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
				local ch = customBxor (customBand(e, f), customBand(bnot(e), g))
				local t1 = h + s1 + ch + k[i] + w[i]
				h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
			end

			H[1] = customBand(H[1] + a)
			H[2] = customBand(H[2] + b)
			H[3] = customBand(H[3] + c)
			H[4] = customBand(H[4] + d)
			H[5] = customBand(H[5] + e)
			H[6] = customBand(H[6] + f)
			H[7] = customBand(H[7] + g)
			H[8] = customBand(H[8] + h)
		end


		local function sha256(msg)
			msg = preproc(msg, #msg)
			local H = initH256({})
			for i = 1, #msg, 64 do
				digestblock(msg, i, H)
			end
			return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
				num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
		end


	local protocolName = "Firewolf"


	--  Cryptography
		local Cryptography = {}
		Cryptography.sha = {}
		Cryptography.base64 = {}
		Cryptography.aes = {}


		function Cryptography.bytesFromMessage(msg)
			local bytes = {}

			for i = 1, msg:len() do
				local letter = string.byte(msg:sub(i, i))
				table.insert(bytes, letter)
			end

			return bytes
		end


		function Cryptography.messageFromBytes(bytes)
			local msg = ""

			for i = 1, #bytes do
				local letter = string.char(bytes[i])
				msg = msg .. letter
			end

			return msg
		end


		function Cryptography.bytesFromKey(key)
			local bytes = {}

			for i = 1, key:len() / 2 do
				local group = key:sub((i - 1) * 2 + 1, (i - 1) * 2 + 1)
				local num = tonumber(group, 16)
				table.insert(bytes, num)
			end

			return bytes
		end


		function Cryptography.sha.sha256(msg)
			return sha256(msg)
		end


		function Cryptography.aes.encrypt(msg, key)
			return base64Encode(crypt(msg, key))
		end


		function Cryptography.aes.decrypt(msg, key)
			return crypt(base64Decode(msg), key)
		end


		function Cryptography.base64.encode(msg)
			return base64Encode(Cryptography.bytesFromMessage(msg))
		end


		function Cryptography.base64.decode(msg)
			return Cryptography.messageFromBytes(base64Decode(msg))
		end

		function Cryptography.channel(text)
			local hashed = Cryptography.sha.sha256(text)

			local total = 0

			for i = 1, hashed:len() do
				total = total + string.byte(hashed:sub(i, i))
			end

			return (total % 55530) + 10000
		end

		function Cryptography.sanatize(text)
			local sanatizeChars = {"%", "(", ")", "[", "]", ".", "+", "-", "*", "?", "^", "$"}

			for _, char in pairs(sanatizeChars) do
				text = text:gsub("%"..char, "%%%"..char)
			end
			return text
		end


	--  Modem
		local Modem = {}

		Modem.modems = {}

		function Modem.exists()
			Modem.exists = false
			for _, side in pairs(rs.getSides()) do
				if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
					Modem.exists = true

					if not Modem.modems[side] then
						Modem.modems[side] = peripheral.wrap(side)
					end
				end
			end

			return Modem.exists
		end


		function Modem.open(channel)
			if not Modem.exists then
				return false
			end

			for side, modem in pairs(Modem.modems) do
				modem.open(channel)
				rednet.open(side)
			end

			return true
		end


		function Modem.close(channel)
			if not Modem.exists then
				return false
			end

			for side, modem in pairs(Modem.modems) do
				modem.close(channel)
			end

			return true
		end


		function Modem.closeAll()
				if not Modem.exists then
					return false
				end

				for side, modem in pairs(Modem.modems) do
					modem.closeAll()
				end

				return true
		end


		function Modem.isOpen(channel)
			if not Modem.exists then
				return false
			end

			local isOpen = false
			for side, modem in pairs(Modem.modems) do
				if modem.isOpen(channel) then
					isOpen = true
					break
				end
			end

			return isOpen
		end


		function Modem.transmit(channel, msg)
			if not Modem.exists then
				return false
			end

			if not Modem.isOpen(channel) then
				Modem.open(channel)
			end

			for side, modem in pairs(Modem.modems) do
				modem.transmit(channel, channel, msg)
			end

			return true
		end


	--  Handshake
		local Handshake = {}

		Handshake.prime = 625210769
		Handshake.channel = 54569
		Handshake.base = -1
		Handshake.secret = -1
		Handshake.sharedSecret = -1
		Handshake.packetHeader = "["..protocolName.."-Handshake-Packet-Header]"
		Handshake.packetMatch = "%["..protocolName.."%-Handshake%-Packet%-Header%](.+)"

		function Handshake.exponentWithModulo(base, exponent, modulo)
			local remainder = base

			for i = 1, exponent-1 do
				remainder = remainder * remainder
				if remainder >= modulo then
					remainder = remainder % modulo
				end
			end

			return remainder
		end


		function Handshake.clear()
			Handshake.base = -1
			Handshake.secret = -1
			Handshake.sharedSecret = -1
		end

		function Handshake.generateInitiatorData()
			Handshake.base = math.random(10,99999)
			Handshake.secret = math.random(10,99999)
			return {
				type = "initiate",
				prime = Handshake.prime,
				base = Handshake.base,
				moddedSecret = Handshake.exponentWithModulo(Handshake.base, Handshake.secret, Handshake.prime)
			}
		end

		function Handshake.generateResponseData(initiatorData)
			local isPrimeANumber = type(initiatorData.prime) == "number"
			local isPrimeMatching = initiatorData.prime == Handshake.prime
			local isBaseANumber = type(initiatorData.base) == "number"
			local isInitiator = initiatorData.type == "initiate"
			local isModdedSecretANumber = type(initiatorData.moddedSecret) == "number"
			local areAllNumbersNumbers = isPrimeANumber and isBaseANumber and isModdedSecretANumber

			if areAllNumbersNumbers and isPrimeMatching then
				if isInitiator then
					Handshake.base = initiatorData.base
					Handshake.secret = math.random(10,99999)
					Handshake.sharedSecret = Handshake.exponentWithModulo(initiatorData.moddedSecret, Handshake.secret, Handshake.prime)
					return {
						type = "response",
						prime = Handshake.prime,
						base = Handshake.base,
						moddedSecret = Handshake.exponentWithModulo(Handshake.base, Handshake.secret, Handshake.prime)
					}, Handshake.sharedSecret
				elseif initiatorData.type == "response" and Handshake.base > 0 and Handshake.secret > 0 then
					Handshake.sharedSecret = Handshake.exponentWithModulo(initiatorData.moddedSecret, Handshake.secret, Handshake.prime)
					return Handshake.sharedSecret
				else
					return false
				end
			else
				return false
			end
		end

	--  Secure Connection
		local SecureConnection = {}
		SecureConnection.__index = SecureConnection


		SecureConnection.packetHeaderA = "["..protocolName.."-"
		SecureConnection.packetHeaderB = "-SecureConnection-Packet-Header]"
		SecureConnection.packetMatchA = "%["..protocolName.."%-"
		SecureConnection.packetMatchB = "%-SecureConnection%-Packet%-Header%](.+)"
		SecureConnection.connectionTimeout = 0.1
		SecureConnection.successPacketTimeout = 0.1


		function SecureConnection.new(secret, key, identifier, distance, isRednet)
			local self = setmetatable({}, SecureConnection)
			self:setup(secret, key, identifier, distance, isRednet)
			return self
		end


		function SecureConnection:setup(secret, key, identifier, distance, isRednet)
			local rawSecret

			if isRednet then
				self.isRednet = true
				self.distance = -1
				self.rednet_id = distance
				rawSecret = protocolName .. "|" .. tostring(secret) .. "|" .. tostring(identifier) ..
				"|" .. tostring(key) .. "|rednet"
			else
				self.isRednet = false
				self.distance = distance
				rawSecret = protocolName .. "|" .. tostring(secret) .. "|" .. tostring(identifier) ..
				"|" .. tostring(key) .. "|" .. tostring(distance)
			end

			self.identifier = identifier
			self.packetMatch = SecureConnection.packetMatchA .. Cryptography.sanatize(identifier) .. SecureConnection.packetMatchB
			self.packetHeader = SecureConnection.packetHeaderA .. identifier .. SecureConnection.packetHeaderB
			self.secret = Cryptography.sha.sha256(rawSecret)
			self.channel = Cryptography.channel(self.secret)

			if not self.isRednet then
				Modem.open(self.channel)
			end
		end


		function SecureConnection:verifyHeader(msg)
			if msg:match(self.packetMatch) then
				return true
			else
				return false
			end
		end


		function SecureConnection:sendMessage(msg, rednetProtocol)
			local rawEncryptedMsg = Cryptography.aes.encrypt(self.packetHeader .. msg, self.secret)
			local encryptedMsg = self.packetHeader .. rawEncryptedMsg

			if self.isRednet then
				rednet.send(self.rednet_id, encryptedMsg, rednetProtocol)
				return true
			else
				return Modem.transmit(self.channel, encryptedMsg)
			end
		end


		function SecureConnection:decryptMessage(msg)
			if self:verifyHeader(msg) then
				local encrypted = msg:match(self.packetMatch)

				local unencryptedMsg = nil
				pcall(function() unencryptedMsg = Cryptography.aes.decrypt(encrypted, self.secret) end)
				if not unencryptedMsg then
					return false, "Could not decrypt"
				end

				if self:verifyHeader(unencryptedMsg) then
					return true, unencryptedMsg:match(self.packetMatch)
				else
					return false, "Could not verify"
				end
			else
				return false, "Could not stage 1 verify"
			end
		end
-- END OF NETWORKING

dnsListenChannel = 9999
dnsResponseChannel = 9998

local config = {}
config.visibleLoggingLevel = 1
config.writtenLoggingLevel = 1
config.loggingLocation = "/fwserver-logs"
config.enableLogging = false
config.password = null
config.allowRednetConnections = true
config.repeatRednetMessages = false
config.lastDomain = nil
--config.actAsGPS = false
--config.gpsLocation = {}

local configLocation = "/.fwserver-config"
local serverLocation = "/fw_servers"
local serverAPILocation = "server_api"
local locked = false
local domain = ...
local responseStack = {}
local repeatStack = {}
local terminalLog = {}
local repeatedMessages = {}
local lastLogNum = 0
local servedRequests = 0
local serverChannel = 0
local requestMatch = ""
local maliciousMatch = ""
local responseHeader = ""
local pageRequestMatch = ""
local pageResposneHeader = ""
local renableRednet = nil
local handles = {}
local customCoroutines = {}
local globalHandler = nil
local closeMatch = ""
local connections = {}
local updateURL = "https://raw.githubusercontent.com/1lann/Firewolf/master/src/server.lua"

local version = "3.5.1"

local header = {}
header.dnsPacket = "[Firewolf-DNS-Packet]"
header.dnsHeader = "[Firewolf-DNS-Response]"
header.dnsHeaderMatch = "^%[Firewolf%-DNS%-Response%](.+)$"
header.rednetHeader = "[Firewolf-Rednet-Channel-Simulation]"
header.rednetMatch = "^%[Firewolf%-Rednet%-Channel%-Simulation%](%d+)$"
header.requestMatchA = "^%[Firewolf%-"
header.requestMatchB = "%-Handshake%-Request%](.+)$"
header.maliciousMatchA = "^%[Firewolf%-"
header.maliciousMatchB = "%-.+%-Handshake%-Response%](.+)$"
header.responseHeaderA = "[Firewolf-"
header.responseHeaderB = "-"
header.responseHeaderC = "-Handshake-Response]"
header.pageRequestMatchA = "^%[Firewolf%-"
header.pageRequestMatchB = "%-Page%-Request%](.+)$"
header.pageResponseHeaderA = "[Firewolf-"
header.pageResponseHeaderB = "-Page-Response][HEADER]"
header.pageResponseHeaderC = "[BODY]"
header.closeMatchA = "[Firewolf-"
header.closeMatchB = "-Connection-Close]"

local resetServerEvent = "firewolf-server-reset-event"

local theme = {}
theme.error = colors.red
theme.background = colors.gray
theme.text = colors.white
theme.notice = colors.white
theme.barColor = colors.red
theme.barText = colors.white
theme.inputColor = colors.white
theme.clock = colors.white
theme.lock = colors.orange
theme.userResponse = colors.orange

if not term.isColor() then
	theme.error = colors.white
	theme.background = colors.black
	theme.text = colors.white
	theme.notice = colors.white
	theme.barColor = colors.white
	theme.barText = colors.black
	theme.inputColor = colors.white
	theme.clock = colors.white
	theme.lock = colors.white
	theme.userResponse = colors.white
end

local w, h = term.getSize()

--  Utilities

local makeDirectory = function(path)
	fs.makeDir(path)
	local function createIndex(path)
		if not (fs.exists(path.."/index") or fs.exists(path.."/index.fwml"))  then
			f = io.open(path.."/index", "w")
			f:write("print('')\ncenter('Welcome to "..domain.."!')")
			f:close()
		end
	end
	pcall(function() createIndex(path) end)
end

local checkDomain = function(domain)
	if domain:find("/") or domain:find(":") or domain:find("%?") then
		return "symbols"
	end
	if #domain < 4 then
		return "short"
	else
		Modem.open(dnsListenChannel)
		Modem.open(dnsResponseChannel)
		Modem.transmit(dnsListenChannel, header.dnsPacket)
		Modem.close(dnsListenChannel)

		rednet.broadcast(header.dnsPacket, header.rednetHeader .. dnsListenChannel)
		local timer = os.startTimer(2)
		while true do
			local event, id, channel, protocol, message, dist = os.pullEventRaw()
			if event == "modem_message" and channel == dnsResponseChannel and message:match(header.dnsHeaderMatch) == domain then
				return "taken"
			elseif event == "rednet_message" and protocol and tonumber(protocol:match(header.rednetMatch)) == dnsResponseChannel and channel:match(header.dnsHeaderMatch) == domain then
				return "taken"
			elseif event == "timer" and id == timer then
				break
			end
		end
	end
	return "ok"
end

local checkConfig = function()
	local errorReport = {}
	if not config then
		table.insert(errorReport, "Corrupted configuration file!")
		return errorReport
	end
	if config.enableLogging then
		if fs.isReadOnly(config.loggingLocation) or fs.isDir(config.loggingLocation) then
			table.insert(errorReport, "Invalid logging location!")
		end
	end

	if #errorReport > 0 then
		return errorReport
	else
		return false
	end
end

local loadConfig = function()
	if fs.exists(configLocation) and not fs.isDir(configLocation) then
		local f = io.open(configLocation, "r")
		config = textutils.unserialize(f:read("*a"))
		if config then
			if type(config.actAsRednetRepeater) == "boolean" then
				config.actAsRednetRepeater = nil
			end
		end
		f:close()
	else
		config = nil
	end
end

local saveConfig = function()
	local f = io.open(configLocation, "w")
	f:write(textutils.serialize(config))
	f:close()
end

local center = function(text)
	local x, y = term.getCursorPos()
	term.setCursorPos(math.floor(w / 2 - text:len() / 2) + (text:len() % 2 == 0 and 1 or 0), y)
	term.write(text)
	term.setCursorPos(1, y + 1)
end

local writeLog = function(text, color, level)
	if not level then level = 0 end
	if not color then color = theme.text end
	if level >= config.visibleLoggingLevel then
		local time = textutils.formatTime(os.time(), true)
		if #time <= 4 then
			time = "0"..time
		end
		table.insert(terminalLog, {text, color, "["..time.."] "})
	end

	if config.enableLogging and level >= config.writtenLoggingLevel then
		if fs.isDir(config.loggingLocation) then
			fs.delete(config.loggingLocation)
		end
		if not fs.exists(config.loggingLocation) then
			local f = io.open(config.loggingLocation, "w")
			f:write("\n")
			f:close()
		end
		local time = textutils.formatTime(os.time(), true)
		if #time <= 4 then
			time = "0"..time
		end
		local f = io.open(config.loggingLocation, "a")
		f:write("["..time.."] "..text.."\n")
		f:close()
	end
end

local writeError = function(text)
	for i = 1, math.ceil(#text / (w - 8)) do
		writeLog(text:sub((i - 1) * (w - 8), i * (w - 8)), theme.error, math.huge)
	end
end

--  Message handling

local receiveDaemon = function()
	while true do
		local event, id, channel, protocol, message, dist = os.pullEventRaw()
		if event == "modem_message" then
			if channel == rednet.CHANNEL_REPEAT and config.repeatRednetMessages and type(message) == "table" and
				message.sProtocol and message.sProtocol:match(header.rednetMatch) then
				table.insert(repeatStack, {message = message, reply = protocol})
			elseif channel ~= rednet.CHANNEL_BROADCAST then
				table.insert(responseStack, {type = "direct", channel = channel, message = message, dist = dist, reply = protocol})
			end
		elseif event == "rednet_message" and protocol and protocol:match(header.rednetMatch) and config.allowRednetConnections then
			table.insert(responseStack, {type = "rednet", channel = tonumber(protocol:match(header.rednetMatch)), rednet_id = id, message = channel, dist = null})
		elseif event == "timer" and id == renableRednet then
			Modem.open(rednet.CHANNEL_REPEAT)
		end
	end
end

local getActiveConnection = function(channel, distance)
	for k, connection in pairs(connections) do
		if connection.channel == channel then
			if (not distance) then
				if connection.isRednet then
					return connection
				else
					return false
				end
			else
				if connection.distance == distance then
					return connection
				else
					return false
				end
			end
		end
	end
end

local urlEncode = function(url)
	local result = url

	result = result:gsub("%%", "%%a")
	result = result:gsub(":", "%%c")
	result = result:gsub("/", "%%s")
	result = result:gsub("\n", "%%n")
	result = result:gsub(" ", "%%w")
	result = result:gsub("&", "%%m")
	result = result:gsub("%?", "%%q")
	result = result:gsub("=", "%%e")
	result = result:gsub("%.", "%%d")

	return result
end

local urlDecode = function(url)
	local result = url

	result = result:gsub("%%c", ":")
	result = result:gsub("%%s", "/")
	result = result:gsub("%%n", "\n")
	result = result:gsub("%%w", " ")
	result = result:gsub("%%&", "&")
	result = result:gsub("%%q", "%?")
	result = result:gsub("%%e", "=")
	result = result:gsub("%%d", "%.")
	result = result:gsub("%%m", "%%")

	return result
end

local getURLVars = function(url)
	local vars = {}
	if url then
		local firstVarIndex, firstVarVal = url:match("%?([^=]+)=([^&]+)")
		if not firstVarIndex then
			return
		else
			vars[urlDecode(firstVarIndex)] = urlDecode(firstVarVal)
			for index, val in url:gmatch("&([^=]+)=([^&]+)") do
				vars[urlDecode(index)] = urlDecode(val)
			end
			return vars
		end
	else
		return
	end
end

local fetchPage = function(page)
	local pageRequest = fs.combine("", page:match("^[^%?]+"))
	local varRequest = page:match("%?[^%?]+$")

	if (pageRequest:match("(.+)%.fwml$")) then
		pageRequest = pageRequest:match("(.+)%.fwml$")
	end

	pageRequest = pageRequest:gsub("%.%.", "")

	local handleResponse, respHeader

	if globalHandler then
		err, msg = pcall(function() handleResponse, respHeader = globalHandler(page, getURLVars(varRequest)) end)
		if not err then
			writeLog("Error when executing server API function", theme.error, math.huge)
			writeError("/: " .. tostring(msg))
		end
	end

	if handleResponse then
		if not respHeader then
			respHeader = "lua"
		end
		return handleResponse, respHeader, true
	end

	if pageRequest == serverAPILocation then
		-- Forbid accessing server api files
		return nil
	end

	for k,v in pairs(handles) do
		local startSearch, endSearch = pageRequest:find(k)
		if startSearch == 1 and ((endSearch == #pageRequest) or (pageRequest:sub(endSearch + 1, endSearch + 1) == "/")) then
			err, msg = pcall(function() handleResponse, respHeader = v(page, getURLVars(varRequest)) end)
			if not err then
				writeLog("Error when executing server API function", theme.error, math.huge)
				writeError(k .. ": " .. tostring(msg))
			end
		end
	end

	if handleResponse then
		if not respHeader then
			respHeader = "lua"
		end
		return handleResponse, respHeader, true
	end

	local path = serverLocation .. "/" .. domain .. "/" .. pageRequest
	if fs.exists(path) and not fs.isDir(path) then
		local f = io.open(path, "r")
		local contents = f:read("*a")
		f:close()

		return contents, "lua", false
	else
		if fs.exists(path..".fwml") and not fs.isDir(path..".fwml") then
			local f = io.open(path..".fwml", "r")
			local contents = f:read("*a")
			f:close()

			return contents, "fwml", false
		end
	end

	return nil
end

local sendPage = function(connection, body, head)
	if head == "fwml" then
		connection:sendMessage(pageResposneHeader..'{["language"]="Firewolf Markup"}'..header.pageResponseHeaderC..body, header.rednetHeader .. connection.channel)
	else
		connection:sendMessage(pageResposneHeader..'{["language"]="Lua"}'..header.pageResponseHeaderC..body, header.rednetHeader .. connection.channel)
	end
end

local defaultNotFound = [[
[br]
[br]
[=]
The page you requested could not be found!
[br]
Make sure you typed the URL correctly.
]]

local handlePageRequest = function(handler, index)
	local connection = getActiveConnection(handler.channel, handler.dist)
	if connection:verifyHeader(handler.message) then
		local resp, data = connection:decryptMessage(handler.message)
		if not resp then
			-- Decryption Error
			writeLog("Decryption error!", theme.notice, 0)
		else
			-- Process Request
			if data:match(pageRequestMatch) then
				local page = data:match(pageRequestMatch)
				if page == "" or page == "/" then
					page = "index"
				end
				local body, head, isAPI = fetchPage(page)
				if body then
					sendPage(connection, tostring(body), head)
					if isAPI then
						writeLog("API request: "..page:sub(1,25), theme.text, 0)
					else
						writeLog("Successful request: "..page:sub(1,20), theme.text, 1)
					end
				else
					body, head, isAPI = fetchPage("not-found")
					if body then
						sendPage(connection, body, head)
					else
						sendPage(connection, defaultNotFound, "fwml")
					end
					writeLog("Unsuccessful request: "..page:sub(1,20), theme.text, 1)
				end
			elseif data == closeMatch then
				writeLog("Secure connection closed", theme.text, 0)
				Modem.close(connection.channel)
				table.remove(connections, index)
			end
		end
	end
end

local handleHandshakeRequest = function(handler)
	local requestData = handler.message:match(requestMatch)
	if requestData and type(textutils.unserialize(requestData)) == "table" then
		local receivedHandshake = textutils.unserialize(requestData)
		local data, key = Handshake.generateResponseData(receivedHandshake)
		if type(data) == "table" then
			local connection

			if handler.type == "direct" then
				connection = SecureConnection.new(key, domain, domain, handler.dist)

				Modem.transmit(serverChannel, responseHeader .. tostring(handler.dist) .. header.responseHeaderC .. textutils.serialize(data))
			else
				connection = SecureConnection.new(key, domain, domain, handler.rednet_id, true)

				rednet.send(handler.rednet_id, responseHeader .. tostring(handler.rednet_id) .. header.responseHeaderC .. textutils.serialize(data), header.rednetHeader .. serverChannel)
			end

			writeLog("Secure connection opened", theme.text, 0)

			table.insert(connections, connection)

			if #connections >= 200 then
				Modem.close(connections[1].channel)
				table.remove(connections, 1)
			end
		end
	elseif handler.message:match(maliciousMatch) then
		-- Hijacking Detected
		writeLog("Warning: Connection Hijacking Detected", theme.error, 2)
	end
end

local responseDaemon = function()
	while true do
		os.pullEventRaw()

		for k, v in pairs(responseStack) do
			if v.channel then
				if v.channel == dnsListenChannel and v.message == header.dnsPacket then
					-- DNS Request
					if v.type == "rednet" then
						rednet.send(v.rednet_id, header.dnsHeader .. domain, header.rednetHeader .. dnsResponseChannel)
					else
						Modem.open(dnsResponseChannel)
						Modem.transmit(dnsResponseChannel, header.dnsHeader .. domain)
						Modem.close(dnsResponseChannel)
					end
				elseif v.channel == serverChannel and v.message then
					handleHandshakeRequest(v)
				elseif getActiveConnection(v.channel, v.dist) then
					handlePageRequest(v, k)
				end
			end
		end

		responseStack = {}

		if #repeatStack > 10 then
			Modem.close(rednet.CHANNEL_REPEAT)
			renableRednet = os.startTimer(2)
			repeatStack = {}
			writeLog("Thorttling Rednet Connections", theme.notice, 2)
		end

		for k, v in pairs(repeatStack) do
			if v.message.nMessageID and v.message.nRecipient then
				if (not repeatedMessages[v.message.nMessageID]) or (os.clock() - repeatedMessages[v.message.nMessageID]) > 10 then
					repeatedMessages[v.message.nMessageID] = os.clock()
					for side, modem in pairs(Modem.modems) do
						modem.transmit(rednet.CHANNEL_REPEAT, v.reply, v.message)
						modem.transmit(v.message.nRecipient, v.reply, v.message)
					end
				end
			end
		end

		repeatStack = {}
	end
end

--  Commands and Help

local commands = {}
local helpDocs = {}

commands["password"] = function(newPassword)
	if not newPassword or newPassword == "" then
		writeLog("Usage: password <new-password>", theme.userResponse, math.huge)
	else
		config.password = newPassword
		saveConfig()
		writeLog("New password set!", theme.userResponse, math.huge)
	end
end

commands["lock"] = function()
	if config.password then
		locked = true
		writeLog("Server locked", theme.userResponse, math.huge)
		os.queueEvent("firewolf-lock-state-update")
	else
		writeLog("No password has been set! Set a", theme.userResponse, math.huge)
		writeLog("password with: password <password>", theme.userResponse, math.huge)
	end
end

commands["exit"] = function()
	error("firewolf-exit")
end

commands["stop"] = commands["exit"]

commands["quit"] = commands["exit"]

commands["startup"] = function()
	if fs.exists("/startup") then
		if fs.exists("/old-startup") then
			fs.delete("/old-startup")
		end
		fs.move("/startup", "/old-startup")
	end
	local f = io.open("/startup", "w")
	f:write([[
	sleep(0.1)
	shell.run("]]..shell.getRunningProgram().." "..domain.."\")")
	f:close()
	writeLog("Server will now run on startup!", theme.userResponse, math.huge)
end

commands["rednet"] = function(set)
	if set == "on" then
		config.allowRednetConnections = true
		saveConfig()
		writeLog("Now allowing rednet connections", theme.userResponse, math.huge)
	elseif set == "off" then
		config.allowRednetConnections = false
		saveConfig()
		writeLog("Now dis-allowing rednet connections", theme.userResponse, math.huge)
	else
		if config.allowRednetConnections then
			writeLog("Rednet conn. are currently allowed", theme.userResponse, math.huge)
		else
			writeLog("Rednet conn. are currently dis-allowed", theme.userResponse, math.huge)
		end
	end
end

commands["restart"] = function()
	error("firewolf-restart")
end

commands["reboot"] = commands["restart"]

commands["reload"] = function()
	os.queueEvent(resetServerEvent)
end

commands["refresh"] = commands["reload"]

commands["repeat"] = function(set)
	if set == "on" then
		config.repeatRednetMessages = true
		saveConfig()
		writeLog("Rednet repeating is now on", theme.userResponse, math.huge)
	elseif set == "off" then
		config.repeatRednetMessages = false
		saveConfig()
		writeLog("Rednet repeating is now off", theme.userResponse, math.huge)
	else
		if config.repeatRednetMessages then
			writeLog("Rednet repeating is currently turned on", theme.userResponse, math.huge)
		else
			writeLog("Rednet repeating is currently turned off", theme.userResponse, math.huge)
		end
	end
end

commands["update"] = function()
	term.setCursorPos(1, h)
	term.clearLine()
	term.setTextColor(theme.userResponse)
	term.setCursorBlink(false)
	term.write("Updating...")
	local handle = http.get(updateURL)
	if not handle then
		writeLog("Failed to connect to update server!", theme.error, math.huge)
	else
		data = handle.readAll()
		if #data < 1000 then
			writeLog("Failed to update server!", theme.error, math.huge)
		else
			local f = io.open("/"..shell.getRunningProgram(), "w")
			f:write(data)
			f:close()
			error("firewolf-restart")
		end
	end
end

commands["edit"] = function()
	writeLog("Editing server files", theme.userResponse, math.huge)
	term.setBackgroundColor(colors.black)
	if term.isColor() then
		term.setTextColor(colors.yellow)
	else
		term.setTextColor(colors.white)
	end
	term.clear()
	term.setCursorPos(1, 1)
	print("Use exit to finish editing")
	shell.setDir(serverLocation .. "/" .. domain)
	shell.run("/rom/programs/shell")
	os.queueEvent(resetServerEvent)
end

commands["clear"] = function()
	terminalLog = {}
	term.clear()
	os.queueEvent("firewolf-lock-state-update")
end

helpDocs["password"] = {"Change the lock password", "Usage: password <new-password>"}
helpDocs["lock"] = {"Lock the server with a password"}
helpDocs["exit"] = {"Exits and stops Firewolf Server"}
helpDocs["quit"] = helpDocs["exit"]
helpDocs["stop"] = helpDocs["exit"]
helpDocs["restart"] = {"Fully restarts Firewolf Server"}
helpDocs["reboot"] = helpDocs["restart"]
helpDocs["reload"] = {"Reloads the server and Server API"}
helpDocs["refresh"] = helpDocs["reload"]
helpDocs["clear"] = {"Clears the displayed log"}
helpDocs["rednet"] = {"Whether to allow rednet connections", "Usage: rednet <on or off>"}
helpDocs["startup"] = {"Runs the server for the current domain", "on startup"}
helpDocs["repeat"] = {"Whether to repeat rednet messages", "Usage: repeat <on or off>"}
helpDocs["update"] = {"Updates Firewolf Server"}
helpDocs["edit"] = {"Opens shell in server directory"}

commands["help"] = function(command)
	if command then
		if helpDocs[command] then
			for _, v in pairs(helpDocs[command]) do
				writeLog(v, theme.userResponse, math.huge)
			end
		else
			writeLog("Command does not exist!", theme.userResponse, math.huge)
		end
	else
		writeLog("Use \"help <command>\" for more info", theme.userResponse, math.huge)
		writeLog("Wiki: http://bit.ly/firewolf-wiki", theme.userResponse, math.huge)
		writeLog("Commands: password, lock, exit, update,", theme.userResponse, math.huge)
		writeLog("restart, clear, rednet, repeat, startup,", theme.userResponse, math.huge)
		writeLog("edit, reload", theme.userResponse, math.huge)
	end
end

--  Display manager

local enteredText = ""
local history = {}
local scrollingHistory = false
local cursorPosition = 1
local offsetPosition = 1
local inputName = "> "
local lockTimer = 0
local lockedInputState = false

local lockArt = [[
  ####
 #    #
 #    #
########
--------
########
########

[LOCKED]
]]

local drawBar = function()
	term.setTextColor(theme.barText)
	term.setBackgroundColor(theme.barColor)
	term.setCursorPos(1,1)
	term.clearLine()
	term.write(" "..version)
	center("["..domain.."]")
	local time = textutils.formatTime(os.time(), true)
	term.setCursorPos(w - #time, 1)
	term.setTextColor(theme.clock)
	term.write(time)
end

local drawLogs = function()
	if locked and lastLogNum >= 0 then
		term.setBackgroundColor(theme.background)
		term.clear()
		lastLogNum = -1
		local lockX = math.ceil((w/2) - 4)
		local lineNum = 4
		term.setTextColor(theme.lock)
		for line in lockArt:gmatch("[^\n]+") do
			term.setCursorPos(lockX, lineNum)
			term.write(line)
			lineNum = lineNum + 1
		end
		inputName = "Password: "
	elseif not locked and lastLogNum ~= #terminalLog then
		term.setBackgroundColor(theme.background)
		term.clear()
		lastLogNum = #terminalLog
		lockedInputState = false
		if #terminalLog < h - 1 then
			term.setCursorPos(1, 2)
			for i = 1, #terminalLog do
				term.setTextColor(theme.clock)
				term.write(terminalLog[i][3])
				term.setTextColor(terminalLog[i][2])
				term.write(terminalLog[i][1])
				term.setCursorPos(1, i + 2)
			end
		else
			term.setCursorPos(1, 2)
			for i = 1, h - 1 do
				term.setTextColor(theme.clock)
				term.write(terminalLog[#terminalLog - (h - 1) + i][3])
				term.setTextColor(terminalLog[#terminalLog - (h - 1) + i][2])
				term.write(terminalLog[#terminalLog - (h - 1) + i][1])
				term.setCursorPos(1, i + 1)
			end
		end
	end
end

local drawInputBar = function()
	term.setCursorPos(1, h)
	term.setBackgroundColor(theme.background)
	term.clearLine()

	if lockedInputState then
		term.setCursorBlink(false)
		term.setTextColor(theme.error)
		term.write("Incorrect Password!")
	else
		term.setCursorBlink(true)
		term.setTextColor(theme.inputColor)
		term.write(inputName)
		width = w - #inputName
		if locked then
			term.write(string.rep("*", (#enteredText:sub(offsetPosition, offsetPosition + width))))
		else
			term.write(enteredText:sub(offsetPosition, offsetPosition + width))
		end
	end
end

local handleKeyEvents = function(event, key)
	if key == 14 then
		if enteredText ~= "" then
			enteredText = enteredText:sub(1, cursorPosition - 2) .. enteredText:sub(cursorPosition, -1)
			cursorPosition = cursorPosition-1
			if cursorPosition >= width then
				offsetPosition = offsetPosition - 1
			end
		end
	elseif key == 28 and enteredText ~= "" and locked then
		if enteredText == config.password then
			writeLog("Successful login", theme.userResponse, math.huge)
			inputName = "> "
			locked = false
			os.queueEvent("firewolf-lock-state-update")
		else
			writeLog("Failed login attempt", theme.userResponse, math.huge)
			lockedInputState = true
			lockTimer = os.startTimer(2)
			os.queueEvent("firewolf-lock-state-update")
		end
		enteredText = ""
		cursorPosition = 1
		offsetPosition = 1
	elseif key == 28 and enteredText ~= "" and not locked then
		local commandWord = false
		local arguments = {}
		for word in enteredText:gmatch("%S+") do
			if not commandWord then
				commandWord = word
			else
				table.insert(arguments, word)
			end
		end
		if commands[commandWord] then
			local err, msg = pcall(commands[commandWord], unpack(arguments))
			if not err and msg:find("firewolf-exit", nil, true) then
				error("firewolf-exit")
			elseif not err and msg:find("firewolf-restart", nil, true) then
				error("firewolf-restart")
			elseif not err then
				writeLog("An error occured when executing command", theme.error, math.huge)
				writeError(tostring(msg))
			end
		else
			writeLog("No such command!", theme.error, math.huge)
		end
		table.insert(history, enteredText)
		enteredText = ""
		offsetPosition = 1
		cursorPosition = 1
	elseif key == 203 then
		cursorPosition = cursorPosition - 1
		if cursorPosition < 1 then
			cursorPosition = 1
		end
		if cursorPosition >= width then
			offsetPosition = offsetPosition - 1
		end
	elseif key == 205 then
		cursorPosition = cursorPosition + 1
		if cursorPosition > #enteredText + 1 then
			cursorPosition = #enteredText + 1
		end
		if cursorPosition - offsetPosition >= width then
			offsetPosition = offsetPosition + 1
		end
	elseif key == 208 and #history > 0 then
		if type(scrollingHistory) == "number" then
			scrollingHistory = scrollingHistory - 1
			if scrollingHistory > 0 then
				enteredText = history[#history - scrollingHistory + 1]
				cursorPosition = #enteredText + 1
			else
				scrollingHistory = false
				enteredText = ""
				cursorPosition = 1
			end
		end
	elseif key == 200 and #history > 0 then
		if type(scrollingHistory) == "number" then
			scrollingHistory = scrollingHistory + 1
			if scrollingHistory > #history then
				scrollingHistory = #history
			end
			enteredText = history[#history - scrollingHistory + 1]
			cursorPosition = #enteredText + 1
			if cursorPosition > width then
				cursorPosition = 1
			end
		else
			scrollingHistory = 1
			enteredText = history[#history - scrollingHistory + 1]
			cursorPosition = #enteredText + 1
			if cursorPosition > width then
				cursorPosition = 1
			end
		end
	end
end


local terminalDaemon = function()
	local timer = os.startTimer(1)
	local lastTime = os.clock()

	while true do
		drawLogs()
		drawBar()
		drawInputBar()

		term.setCursorPos(cursorPosition - offsetPosition + #inputName + 1, h)

		local event, key = os.pullEventRaw()
		if event == "char" and not lockedInputState then
			enteredText = enteredText:sub(1, cursorPosition-1) .. key .. enteredText:sub(cursorPosition, -1)
			cursorPosition = cursorPosition + 1
			if cursorPosition - offsetPosition >= width then
				offsetPosition = offsetPosition + 1
			end
		elseif event == "key" and not lockedInputState then
			handleKeyEvents(event, key)
		elseif event == "timer" and key == timer then
			timer = os.startTimer(1)
			lastTime = os.clock()
		elseif event == "timer" and key == lockTimer then
			lockedInputState = false
		elseif event == "terminate" and not locked then
			error("firewolf-exit")
		end

		if (os.clock() - lastTime) > 1 then
			timer = os.startTimer(1)
			lastTime = os.clock()
		end
	end
end

--  Coroutine manager

local receiveThread, responseThread, terminalThread

local loadServerAPI = function()
	if fs.exists(serverLocation .. "/" .. domain .. "/" .. serverAPILocation) and not fs.isDir(serverLocation .. "/" .. domain .. "/" .. serverAPILocation) then
		local f = io.open(serverLocation .. "/" .. domain .. "/" .. serverAPILocation, "r")
		local apiData = f:read("*a")
		f:close()

		customCoroutines = {}

		local apiFunction, err = loadstring(apiData)
		if not apiFunction then
			writeLog("Error while loading server API", theme.error, math.huge)
			if err:match("%[string \"string\"%](.+)") then
				writeLog("server_api" .. err:match("%[string \"string\"%](.+)"), theme.error, math.huge)
			else
				writeLog(err, theme.error, math.huge)
			end
		else
			local global = getfenv(0)
			local env = {}

			for k,v in pairs(global) do
				env[k] = v
			end

			env["server"] = {}

			env["server"]["domain"] = domain

			env["server"]["modem"] = Modem

			env["server"]["handleRequest"] = function(index, func)
				if not(index and func and type(index) == "string" and type(func) == "function") then
					return error("index (string) and handler (function) expected")
				elseif #index:gsub("/", "") == 0 then
					return error("invalid index")
				end
				if index == "/" then
					globalHandler = func
					return
				end
				if index:sub(1, 1) == "/" then index = index:sub(2, -1) end
				if index:sub(-1, -1) == "/" then index = index:sub(1, -2) end
				if index:find(":") then
					return error("Handle index cannot contain \":\"s")
				end
				handles[index] = func
			end

			env["server"]["runCoroutine"] = function(func)
				local newThread = coroutine.create(func)
				local err, msg = coroutine.resume(newThread)
				if not err then
					return error(msg)
				end

				table.insert(customCoroutines, newThread)
			end

			env["server"]["applyTemplate"] = function(variables, template)
				local result
				if fs.exists(template) and not fs.isDir(template) then
					local f = io.open(template, "r")
					result = f:read("*a")
					f:close()
				else
					writeLog("Template file \"" .. template .. "\" does not exist!", theme.error, math.huge)
					writeLog("Template locations are relative to / (root)", theme.error, math.huge)
					return false
				end
				for k,v in pairs(variables) do
					result = result:gsub("{{"..Cryptography.sanatize(k).."}}", Cryptography.sanatize(v))
				end
				return result
			end

			env["server"]["log"] = function(text)
				writeLog(text, theme.notice, math.huge)
			end

			setfenv(apiFunction, env)
			local err, msg = pcall(apiFunction)

			if not err then
				writeLog("Error while executing server API", theme.error, math.huge)
				writeError(tostring(msg))
			else
				writeLog("Server API loaded", theme.notice, math.huge)
			end
		end
	end
end

local function resetServer()
	connections = {}
	repeatStack = {}
	responseStack = {}
	Modem.closeAll()
	Modem.open(serverChannel)
	Modem.open(dnsListenChannel)
	if config.repeatRednetMessages then
		Modem.open(rednet.CHANNEL_REPEAT)
	end

	loadServerAPI()

	responseThread = coroutine.create(function() responseDaemon() end)
	receiveThread = coroutine.create(receiveDaemon)
	coroutine.resume(responseThread)
	coroutine.resume(receiveThread)
	writeLog("The server has been reloaded", theme.userResponse, math.huge)

	os.queueEvent("firewolf-lock-state-update")
end

local function runThreads()
	while true do
		local shouldResetServer = false
		local events = {os.pullEventRaw()}

		err, msg = coroutine.resume(receiveThread, unpack(events))
		if not err then
			writeLog("Internal error!", theme.error, math.huge)
			writeError(tostring(msg))
			shouldResetServer = true
		end

		err, msg = coroutine.resume(responseThread)
		if not err then
			writeLog("Internal error!", theme.error, math.huge)
			writeError(tostring(msg))
			shouldResetServer = true
		end

		err, msg = coroutine.resume(terminalThread, unpack(events))
		if not err and msg:find("firewolf-exit", nil, true) then
			writeLog("Normal exit", theme.text, math.huge)
			Modem.closeAll()
			shell.setDir("")
			term.setBackgroundColor(colors.black)
			term.clear()
			term.setCursorPos(1, 1)
			term.setTextColor(colors.white)
			center("Thank you for using Firewolf Server")
			center("Made by 1lann and GravityScore")
			return
		elseif not err and msg:find("firewolf-restart", nil, true) then
			writeLog("Firewolf server restarting...", theme.text, math.huge)
			term.clear()
			error("firewolf-restart")
		elseif not err then
			term.clear()
			term.setCursorPos(1, 1)
			error("Restart required error: "..msg)
		end

		for k,v in pairs(customCoroutines) do
			if coroutine.status(v) ~= "dead" then
				local err, msg = coroutine.resume(v, unpack(events))
				if not err then
					writeLog("Server API coroutine error!", theme.error, math.huge)
					writeError(tostring(msg))
					shouldResetServer = true
				end
			end
		end

		if events[1] == resetServerEvent or shouldResetServer then
			resetServer()
		end
	end
end

local runOnDomain = function()
	serverChannel = Cryptography.channel(domain)
	requestMatch = header.requestMatchA .. Cryptography.sanatize(domain) .. header.requestMatchB
	responseHeader = header.responseHeaderA .. domain .. header.responseHeaderB
	pageRequestMatch = header.pageRequestMatchA .. Cryptography.sanatize(domain) .. header.pageRequestMatchB
	pageResposneHeader = header.pageResponseHeaderA .. domain .. header.pageResponseHeaderB
	closeMatch = header.closeMatchA .. domain .. header.closeMatchB
	maliciousMatch = header.maliciousMatchA .. Cryptography.sanatize(domain) .. header.maliciousMatchB

	Modem.open(serverChannel)
	Modem.open(dnsListenChannel)

	if config.repeatRednetMessages then
		Modem.open(rednet.CHANNEL_REPEAT)
	end

	writeLog("Firewolf Server "..version.." running" , theme.notice, math.huge)

	loadServerAPI()

	receiveThread = coroutine.create(receiveDaemon)
	responseThread = coroutine.create(responseDaemon)
	terminalThread = coroutine.create(terminalDaemon)

	coroutine.resume(receiveThread)
	coroutine.resume(responseThread)
	coroutine.resume(terminalThread)

	runThreads()
end

--  Server initialisation

local init = function()
	Modem.closeAll()
	term.setBackgroundColor(theme.background)
	term.setTextColor(theme.notice)
	term.clear()
	term.setCursorPos(1,1)
	term.setCursorBlink(false)
	term.setTextColor(theme.text)

	if not fs.exists(serverLocation .. "/" .. domain) then
		makeDirectory(serverLocation .. "/" .. domain)
	else
		if not fs.isDir(serverLocation .. "/" .. domain) then
			fs.delete(serverLocation .. "/" .. domain)
		end
		makeDirectory(serverLocation .. "/" .. domain)
	end

	local report = checkConfig()
	if report then
		term.setBackgroundColor(colors.black)
		term.setTextColor(theme.error)
		term.clear()
		term.setCursorPos(1, 1)
		print("There was an error loading your config file")
		print("The config file is located at: "..configLocation)
		print("-------------------------------------------------")
		for k,v in pairs(report) do
			print(v)
		end
		return
	end

	if config.password then
		locked = true
	end

	local err, msg = pcall(function()runOnDomain()end)
	if not err and msg:find("firewolf-restart", nil, true) then
		term.clear()
		term.setCursorPos(1, 1)
		return shell.run("/"..shell.getRunningProgram(), domain)
	elseif not err then
		term.setBackgroundColor(colors.black)
		term.clear()
		term.setCursorPos(1, 1)
		term.setTextColor(colors.red)
		print("Sorry, Firewolf Server has crashed! Error:")
		print(msg)
		print("Firewolf Server will reboot in 3 seconds...")
		sleep(3)
		return shell.run("/"..shell.getRunningProgram(), domain)
	end
end

if pocket or turtle then
	term.setTextColor(theme.error)
	print("Sorry, Firewolf Server can")
	print("only be ran on computers.")
	return
end

if not Modem.exists() then
	term.setTextColor(theme.error)
	print("Error: No modems found!")
	return
end

if fs.isDir(configLocation) then
	fs.delete(configLocation)
end

if not fs.exists(configLocation) then
	saveConfig()
end

loadConfig()

if not domain and config.lastDomain then
	domain = config.lastDomain
end

if domain then
	if term.isColor() then
		term.setTextColor(colors.yellow)
	else
		term.setTextColor(colors.white)
	end
	term.setCursorBlink(false)
	print("Initializing Firewolf Server...")
	local report = checkDomain(domain)
	term.setTextColor(theme.error)
	if report == "symbols" then
		print("Domain cannot contain \":\", \"/\" and \"?\"s")
	elseif report == "short" then
		print("Domain name too short!")
	elseif report == "taken" then
		print("Domain already taken!")
	else
		config.lastDomain = domain
		saveConfig()
		init()
	end
else
	term.setTextColor(colors.white)
	print("Usage: "..shell.getRunningProgram().." <domain>")
end
