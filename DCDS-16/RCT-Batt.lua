--[[
	---------------------------------------------------------
    Battery Percentage application converts capacity used (mAh)
	to percentage-range 100-0% from full to empty battery. 
	
	This is a slimmed down version for DC/DS-16.
	
	Possibility to define a 2-position switch to select between
	2 different size packs. If no switch is defined only battery
	1 is used.
	
	App makes a LUA control (switch) that can be used as
	any other switch, voices, alarms etc.
	
	Telemetry-screen on main-screen with Battery-symbol. 
	Symbol is realtime - Charge gets lower on use.
	
	Localisation-file has to be as /Apps/Lang/RCT-Batt.jsn
	
	French translation courtesy from Daniel Memim
	---------------------------------------------------------
	Battery Percentage is part of RC-Thoughts Jeti Tools.
	---------------------------------------------------------
	Released under MIT-license by Tero @ RC-Thoughts.com 2016
	---------------------------------------------------------
--]]
--------------------------------------------------------------------------------
-- Locals for the application
local sens, sensid, senspa, telVal, alarm1, alarm2
local alarm1Tr, alarm2Tr, res, Sw1, Sw2
local sensorLalist = {"..."}
local sensorIdlist = {"..."}
local sensorPalist = {"..."}
local tSet1, tSet2 = 0,0
--------------------------------------------------------------------------------
-- Function for translation file-reading
local function readFile(path) 
	local f = io.open(path,"r")
	local lines={}
	if(f) then
		while 1 do 
			local buf=io.read(f,512)
			if(buf ~= "")then 
				lines[#lines+1] = buf
				else
				break   
			end   
		end 
		io.close(f)
		return table.concat(lines,"") 
	end
end 
--------------------------------------------------------------------------------
-- Read translations
local function setLanguage()	
	local lng=system.getLocale();
	local file = readFile("Apps/Lang/RCT-Batt.jsn")
	local obj = json.decode(file)  
	if(obj) then
		trans = obj[lng] or obj[obj.default]
	end
end
--------------------------------------------------------------------------------
-- Read available sensors for user to select
local sensors = system.getSensors()
for i,sensor in ipairs(sensors) do
	if (sensor.label ~= "") then
		table.insert(sensorLalist, string.format("%s", sensor.label))
		table.insert(sensorIdlist, string.format("%s", sensor.id))
		table.insert(sensorPalist, string.format("%s", sensor.param))
	end
end
--------------------------------------------------------------------------------
-- Draw the telemetry windows
local function printTelem()
	if (telVal == "-") then
		lcd.drawRectangle(5,9,26,55)                                          
		lcd.drawFilledRectangle(12,6,12,4)
		lcd.drawText(145 - lcd.getTextWidth(FONT_MAXI,"-%"),10,"-%",FONT_MAXI)
		lcd.drawText(145 - lcd.getTextWidth(FONT_MINI,"RC-Thoughts.com"),54,"RC-Thoughts.com",FONT_MINI)
		else
		lcd.drawRectangle(5,9,26,55)                                          
		lcd.drawFilledRectangle(12,6,12,4)
		chgY = (65-(telVal*0.54))
		chgH = ((telVal*0.54)-1)
		lcd.drawFilledRectangle(6,chgY,24,chgH)
		lcd.drawText(145 - lcd.getTextWidth(FONT_MAXI,string.format("%s%%",telVal)),10,string.format("%s%%",telVal),FONT_MAXI)
		lcd.drawText(145 - lcd.getTextWidth(FONT_MINI,"RC-Thoughts.com"),53,"RC-Thoughts.com",FONT_MINI)
	end
end
--------------------------------------------------------------------------------
-- Store settings when changed by user
local function sensorChanged(value)
	sens=value
	system.pSave("sens",value)
	sensid = string.format("%s", sensorIdlist[sens])
	senspa = string.format("%s", sensorPalist[sens])
	if (sensid == "...") then
		sensid = 0
		senspa = 0
	end
	system.pSave("sensid",sensid)
	system.pSave("senspa",senspa)
end
-----------------
local function SwChanged1(value)
	Sw1 = value
	system.pSave("Sw1",value)
end
local function SwChanged2(value)
	Sw2 = value
	system.pSave("Sw2",value)
end
-----------------
local function capa1Changed(value)
	capa1=value
	system.pSave("capa1",value)
end
local function capa2Changed(value)
	capa2=value
	system.pSave("capa2",value)
end
-----------------
local function alarm1Changed(value)
	alarm1=value
	system.pSave("alarm1",value)
	alarm1Tr = string.format("%.1f", alarm1)
	system.pSave("alarm1Tr", alarm1Tr)
end
local function alarm2Changed(value)
	alarm2=value
	system.pSave("alarm2",value)
	alarm2Tr = string.format("%.1f", alarm2)
	system.pSave("alarm2Tr", alarm2Tr)
end
--------------------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm(subform)
	if(subform == 1) then
		form.setButton(1,":tools",ENABLED)
		
		form.addRow(1)
		form.addLabel({label="---    RC-Thoughts Jeti Tools     ---",font=FONT_BIG})
		
		form.addRow(1)
		form.addLabel({label=trans.Label,font=FONT_BOLD})
		
		form.addRow(2)
		form.addLabel({label=trans.Sensor})
		form.addSelectbox(sensorLalist,sens,true,sensorChanged)
		
		form.addRow(1)
		form.addLabel({label=trans.Settings1,font=FONT_BOLD})
		
		form.addRow(2)
		form.addLabel({label=trans.Switch})
		form.addInputbox(Sw1,true,SwChanged1)
		
		form.addRow(2)
		form.addLabel({label=trans.Capa,width=180})
		form.addIntbox(capa1,0,32767,0,0,1,capa1Changed)
		
		form.addRow(2)
		form.addLabel({label=trans.AlmVal})
		form.addIntbox(alarm1,0,100,0,0,1,alarm1Changed)
		
		form.addRow(1)
		form.addLabel({label=trans.Settings2,font=FONT_BOLD})
		
		form.addRow(2)
		form.addLabel({label=trans.Switch})
		form.addInputbox(Sw2,true,SwChanged2)
		
		form.addRow(2)
		form.addLabel({label=trans.Capa,width=180})
		form.addIntbox(capa2,0,32767,0,0,1,capa2Changed)
		
		form.addRow(2)
		form.addLabel({label=trans.AlmVal})
		form.addIntbox(alarm2,0,100,0,0,1,alarm2Changed)
		
		form.addRow(1)
		form.addLabel({label="Powered by RC-Thoughts.com - v."..battVersion.." ",font=FONT_MINI, alignRight=true})
		
		form.setFocusedRow (1)
		formID = 1
	end
end
---------------------------------------------------------------------------------
-- Runtime functions, read sensor, convert to percentage, keep percentage between 0 and 100 at all times
-- Display on main screen the selected battery and values, take care of correct alarm-value
local function loop()
	local sensor = system.getSensorByID(sensid, senspa)
	local Sw1, Sw2 = system.getInputsVal(Sw1, Sw2)
	-----------------
	if(sensor and sensor.valid) then
		if (Sw1 == 1) then
			if(tSet1 == 0) then
				tStmp = system.getTime()
				tCur = tStmp
				tStr = tStmp + 5
				tSet1 = 1
				tSet2 = 0
				else
				tCur = system.getTime()
			end
			res = (((capa1 - sensor.value) * 100) / capa1)
			if(alarm1Tr == 0) then
				system.setControl(3,0,0,0)
				tStr = 0
				else
				if(res <= alarm1) then
					if(tStr <= tCur and tSet1 == 1) then
						system.setControl(3,1,0,0)
					end
					else
					system.setControl(3,0,0,0)
				end
			end
		end
		if (Sw2 == 1) then
			if(tSet2 == 0) then
				tStmp = system.getTime()
				tCur = tStmp
				tStr = tStmp + 5
				tSet1 = 0
				tSet2 = 1
				else
				tCur = system.getTime()
			end
			res = (((capa2 - sensor.value) * 100) / capa2) 
			if(alarm2Tr == 0) then
				system.setControl(3,0,0,0)
				tStr = 0
				else
				if(res <= alarm2) then
					if(tStr <= tCur and tSet2 == 1) then
						system.setControl(3,1,0,0)
					end
					else
					system.setControl(3,0,0,0)
				end
			end
		end
		-- Format
		if (res and res < 0) then
			res = 0
			elseif (res and res > 100) then
			res = 100
		end
		if(res) then
			telVal = string.format("%.1f", res)
		end
		else
		telVal = "-"
		tSet1 = 0
		tSet2 = 0
	end
end
--------------------------------------------------------------------------------
-- Application initialization
local function init()
	telVal = "-"
	sens = system.pLoad("sens",0)
	sensid = system.pLoad("sensid",0)
	senspa = system.pLoad("senspa",0)
	capa1 = system.pLoad("capa1",0)
	capa2 = system.pLoad("capa2",0)
	alarm1 = system.pLoad("alarm1",0)
	alarm2 = system.pLoad("alarm2",0)
	alarm1Tr = system.pLoad("alarm1Tr",0)
	alarm2Tr = system.pLoad("alarm2Tr",0)
	Sw1 = system.pLoad("Sw1")
	Sw2 = system.pLoad("Sw2")
	system.registerTelemetry(1,trans.wLabel,2,printTelem)
	system.registerControl(3,trans.battSw,trans.battSw)
	system.registerForm(1,MENU_APPS,trans.appName,initForm,keyPressed)
end
--------------------------------------------------------------------------------
battVersion = "1.8"
setLanguage()
return {init=init, loop=loop, author="RC-Thoughts", version=battVersion, name=trans.appName} 					