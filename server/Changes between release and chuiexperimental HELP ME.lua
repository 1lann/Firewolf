old	new	
...	...	@@ -1,4 +1,5 @@
1		-
	1	+local oldPullEvent = os.pullEvent
	2	+os.pullEvent = os.pullEventRaw
2	3	 --  
3	4	 --  Firewolf Server Software
4	5	 --  Created By GravityScore and 1lann
...	...	@@ -49,6 +50,8 @@ local dataLocation = ""
49	50	 local pages = {}
50	51	 local totalRecordLines = {}
51	52	 local recordLines = {}
	53	+local serverPassword = nil
	54	+local serverLocked = true
52	55	 
53	56	 -- Locations
54	57	 local rootFolder = "/.Firewolf_Data"
...	...	@@ -56,6 +59,7 @@ local serverFolder = rootFolder .. "/servers"
56	59	 local statsLocation = rootFolder .. "/" .. website .. "_stats"
57	60	 local themeLocation = rootFolder .. "/theme"
58	61	 local defaultThemeLocation = rootFolder .. "/default_theme"
	62	+local passwordDataLocation = rootFolder .. "/." .. website .. "_password"
59	63	 local serverSoftwareLocation = "/" .. shell.getRunningProgram()
60	64	 
61	65	 
...	...	@@ -728,11 +732,31 @@ local function interface()
728	732	 		print("")
729	733	 		term.setBackgroundColor(colors[theme["bottom-box"]])
730	734	 
731		-		local p1 = "Pause Server"
732	735	 		if enableResponse == false then p1 = "Unpause Server" end
733	736	 		term.setBackgroundColor(colors[theme["top-box"]])
734		-		local opt = prompt({{p1, 5, 4}, {"Edit", 5, 5}, {"Manage", w - 15, 4}, 
735		-			{"Stop", w - 13, 5}}, "vertical")
	737	+		if not serverLocked and not serverPassword then
	738	+			local opt = prompt({{"Lock Server", 5, 4}, {"Edit", 5, 5}, {"Manage", w - 15, 4}, 
	739	+				{"Stop", w - 13, 5}}, "vertical")
	740	+		elseif not serverLocked and serverPassword then
	741	+			local opt = prompt({{"Add Lock", 5, 4}, {"Edit", 5, 5}, {"Manage", w - 15, 4}, 
	742	+				{"Lock", 5, 5},{"Stop", w - 13, 5}}, "vertical")
	743	+		elseif serverLocked then
	744	+			term.setCursorPos(5,4)
	745	+			print("Enter Password:")
	746	+			term.slocal enteredPassword = read("*")
	747	+			if enteredPassword == serverPassword then
	748	+				term.setCursorPos(1, 2)
	749	+				print("")
	750	+				term.setTextColor(colors[theme["text-color"]])
	751	+				term.setBackgroundColor(colors[theme["top-box"]])
	752	+				centerPrint(string.rep(" ", 47))
	753	+				centerPrint(string.rep(" ", 47))
	754	+				centerPrint(string.rep(" ", 47))
	755	+				centerPrint(string.rep(" ", 47))
	756	+				term.setCursorPos
	757	+
	758	+
	759	+		end
736	760	 		if opt == p1 then
737	761	 			enableResponse = not(enableResponse)
738	762	 		elseif opt == "Manage" then
...	...	@@ -749,9 +773,10 @@ local function interface()
749	773	 				term.setCursorPos(5, 10)
750	774	 				write("Searches: " .. tostring(searches))
751	775	 
752		-				local opt = prompt({{"Manage Blocked IDs", 9, 12}, {"Delete Server", 9, 13}, 
753		-					{"Back", 9, 15}}, "vertical")
754		-				if opt == "Manage Blocked IDs" then
	776	+				local opt = prompt({{"Add/Remove Password Lock", 9, 12}, {"Manage Blocked IDs", 9, 13}, {"Delete Server", 9, 14}, 
	777	+					{"Back", 9, 16}}, "vertical")
	778	+				if opt == "Add/Remove Password Lock" then
	779	+				elseif opt == "Manage Blocked IDs" then
755	780	 					while true do
756	781	 						clearPage()
757	782	 						term.setCursorPos(1, 8)
...	...	@@ -1025,6 +1050,16 @@ else
1025	1050	 	if theme == nil then theme = defaultTheme end
1026	1051	 end
1027	1052	 
	1053	+-- Pasword
	1054	+if fs.exists(passwordDataLocation) then
	1055	+	local f = io.open(passwordDataLocation, "r")
	1056	+	serverPassword = f:read("*l")
	1057	+	f:close()
	1058	+	serverLocked = true
	1059	+else
	1060	+	serverLocked = false
	1061	+end
	1062	+
1028	1063	 -- Start
1029	1064	 startup()
1030	1065	 
