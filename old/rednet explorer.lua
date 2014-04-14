local x,y = term.getSize()
rednet.open("top")
local EditingValue = "";

function rednetV()
	return "2.4.1"
end

title = "Rednet Explorer " ..rednetV() --Add title = "name" to change the webpage's title!
local website = "home";
if fs.exists(".cache") then fs.delete(".cache") end
if fs.exists(".websiteedited") then fs.delete(".websiteedited") end
fs.makeDir(".cache")

local cPrint = function(text)
	local x2,y2 = term.getCursorPos()
	term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)

	print(text)
end

function reDirect(url)
	website = url
	loadWebpage()
end

function createSite(websitename) --OPENNEXISGATES
					fs.delete("startup")
					startup = fs.open("startup", "w")
					startup.writeLine("websitename = \"" ..websitename.. "\"")
					servercode = [[

						local enableSearching = true --Change to false if you don't want bots to search your site
						local password = os.getComputerID() --Change if you want a custom password

						function record(text)
							print(text)
							log = fs.open("rednet.log", "w")
							log.writeLine(text)
							log.close()
						end

						local x,y = term.getSize()
						local cPrint = function(text)
							local x2,y2 = term.getCursorPos()
							term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), y2)

							print(text)
						end

						rednet.open("top")
						term.clear()
						cPrint("Hosting " ..websitename.. "...\n")
						cPrint("Go to " ..websitename.. "/editor to edit it! (PASS: " ..os.getComputerID().. ")\n")
						test = fs.open(websitename, "r")
						fileContents = test:readAll()
						test.close()
						while true do
							sleep(0)
							id, message = rednet.receive()
							if message == websitename then
								record("   [" ..os.time().."] [" ..id.. "] Pinged Website.")
								rednet.send(id, fileContents)
								record("   [" ..os.time().."] [" ..id.. "] Received Data")
							elseif message == websitename.. "/editor" then
								rednet.send(id, "EditorMode")
								rednet.send(id, tostring(password))
								rednet.send(id, fileContents)
							elseif message == "rednet.api.ping.searchengine" and enableSearching == true then
								rednet.send(id, websitename)
								record("   [" ..os.time().."] [" ..id.. "] Searched by &e0!") --I made it fail on purpose :P
							elseif message == websitename.. "/editor EDITED COMPLED!" then
								id, message = rednet.receive(0.001)
								fs.delete(websitename)
								webpage = fs.open(websitename, "w")
								webpage.write(message)
								webpage.close()


								test = fs.open(websitename, "r")
								fileContents = test:readAll()
								test.close()
								record("   [" ..os.time().."] [" ..id.. "] Updated Website!")
							end
						end
					]]

					startup.writeLine(servercode)
					startup.close()
					os.reboot()
end

local Address = function()
	text = "rdnt://"
	term.setCursorPos(math.ceil((x / 2) - (text:len() / 2)), 2)
	term.clearLine()

	write("rdnt://")
	website = read()
	loadWebpage()
end

function done()
	term.setCursorPos(1, y)
	name = "F5 = Refresh"
	write("Press CTRL to travel the web! :D")
	term.setCursorPos(x - name:len(), y)
	write(name)

	while true do
		sleep(0) -- stop crashing
		e, k = os.pullEvent("key")
		if k == 63 then
			loadWebpage()
			break
		elseif k == 29 then
			Address()
			break
		end
	end
end


loadWebpage = function()
	term.clear()
	term.setCursorPos(1,1)
	cPrint(title)
	cPrint("rdnt://" ..website.. "\n")
	if website == "home" then
		print("Welcome to RedNet explorer (2.0)! This requires you to have a wireless modem on your computer.")
		print("Host a website at:                ")
		print("rdnt://newsite!            ")
		print("   -ComputerCraftFan11    ")
	elseif website == "newsite" then
		print("Are you sure you would like to make this PC a server?")
		cPrint("Y = Yes N = No")
		while true do
			e, k = os.pullEvent("char")
			if k == "y" or k == "n" then
				break
			end
		end

		if k == "y" then
			term.clear()
			term.setCursorPos(1,1)
			title = "Rednet Servers " ..rednetV()
			cPrint(title)
			print("Welcome to the Rednet Servers. Please enter the website name: ")
			websitename = read()
			rednet.broadcast(websitename)
			i, me = rednet.receive(0.001)
			if me == nil then
				print("Thank you! This website will be running off of the file:\n" ..websitename.. "\n")
				write("Are you sure? (Y = Continue, V = Edit)")
				input = read()
				if input == "Y" or input == "y" then
					if fs.exists(websitename) == false then
						print("Please create " ..websitename.. " first!")
						sleep(0.5)
						shell.run("edit", websitename)
					end
					term.clear()
					term.setCursorPos(1,1)
					createSite(websitename)
				elseif input == "V" or input == "v" then
					shell.run("edit", websitename)
					term.clear()
					term.setCursorPos(1,1)
					createSite(websitename)
				end
			else
				print("I'm sorry, this domain name is taken.")
			end
		end
	else
		title = "Rednet Explorer " ..rednetV()
		rednet.broadcast(website)
		print("Connecting...")
		website1 = ".depagecrash"
		id, message = rednet.receive(0.1)
		if message == nil then
			print("Unable to load webpage.")
		elseif message == "EditorMode" then
			id, password = rednet.receive(0.1)
			id, EditingValue = rednet.receive(0.1)
			 write("Password: ")
			input = read("*")
			if tostring(password) == input then
				fs.delete(".cache/" ..website1)
				editor = fs.open(".websiteedited", "w")
				if editor then
					editor.writeLine(EditingValue)
				end
				editor.close()

				shell.run("edit", ".websiteedited")

				edited = fs.open(".websiteedited", "r")
				editwebpage = edited.readAll()
				edited.close()

				rednet.broadcast(website.. " EDITED COMPLED!")
				rednet.broadcast(editwebpage)
				website = "home"
				loadWebpage()

			else

				website = "home"
				loadWebpage()

			end
		else
			if fs.exists(".cache/" ..website1) then fs.delete(".cache/" ..website1) end
			webpage = fs.open(".cache/" ..website1, "w")
			webpage.write(message)
			webpage.close()
			term.clear()
			term.setCursorPos(1,1)
			cPrint(title)
			cPrint("rdnt://" ..website.. "\n")
			shell.run(".cache/" ..website1)
		end
	end

	done()
end

loadWebpage()
