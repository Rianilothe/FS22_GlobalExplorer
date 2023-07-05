
GlobalExplorer={}
GlobalExplorer.debug=false
GlobalExplorer.configFolder=''
GlobalExplorer.historyFilename=''
GlobalExplorer.globalFilename=''
GlobalExplorer.favoritesFilename=''
local GlobalExplorer_mt = Class(GlobalExplorer)
g_globalExplorerUIFilename=g_currentModDirectory..'resources/ui_icons.dds'
g_globalExplorerUIFilename2=g_currentModDirectory..'resources/ui_icons2.dds'

function printdebug(s)
	if GlobalExplorer.debug==true then print(s) end
end

function GlobalExplorer.new()
	local self = setmetatable({},GlobalExplorer_mt)
	self.modDirectory=g_currentModDirectory
	printdebug("GlobalExplorer: new="..tostring(self))
	printdebug("GlobalExplorer: g_currentModDirectory="..g_currentModDirectory)
	return self
end

function GlobalExplorer:load(mission)
	-- create/format save files & dirs
    local modSettingsFolder = getUserProfileAppPath() .. "modSettings/"
    createFolder(modSettingsFolder)
    self.configFolder = modSettingsFolder .. "FS22_GlobalExplorer/"
    createFolder(self.configFolder)	
	self.historyFilename=self.configFolder..'history.xml'
	self.globalFilename=self.configFolder..'global.xml'
	self.favoritesFilename=self.configFolder..'favorites.xml'
	
	self.ui = GlobalExplorerUI.new()
	g_gui:loadProfiles(self.modDirectory .. "gui/geProfiles.xml")
	g_gui:loadGui(self.modDirectory .. "gui/geGui.xml","GeScreen",self.ui)
end

function GlobalExplorer:unload(mission)
	-- called when game exiting
	printdebug('GlobalExplorer: unload')
end

function GlobalExplorer:isActive()
	return GlobalExplorer ~= nil
end

function GlobalExplorer:registerActionEvents(mission)
	-- called to allow mods to registed event handlers
    if GlobalExplorer:isActive() and mission ~= nil then
        GlobalExplorer:onRegisterActionEvents(mission, mission.inputManager)
    end
end

function GlobalExplorer:unregisterActionEvents(mission)
	printdebug('GlobalExplorer: unregisterActionEvents, isActive='..tostring(GlobalExplorer:isActive())..', mission='..tostring(mission))
	if GlobalExplorer:isActive() and mission ~= nil then
        GlobalExplorer:onUnregisterActionEvents(mission, mission.inputManager)
    end
end

function GlobalExplorer:onRegisterActionEvents(mission, inputManager)
	printdebug('GlobalExplorer: onRegisterActionEvents')
    local _, eventId = inputManager:registerActionEvent(InputAction.GE_FRAME, self, self.onInputOpenMenu, false, true, false, true)
    inputManager:setActionEventTextVisibility(eventId, false)
    self.eventIdOpenMenu = eventId
end

function GlobalExplorer:onUnregisterActionEvents(mission, inputManager)
	printdebug('GlobalExplorer: onUnregisterActionEvents')
    inputManager:removeActionEventsByTarget(self)
    self.eventIdOpenMenu = nil
end

function GlobalExplorer:onInputOpenMenu(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
	printdebug('GlobalExplorer: onInputOpenMenu')
    self.dialog=g_gui:showDialog("GeScreen")
	dialog.textInputElement.onFocusLeave=GlobalExplorerUI.onFocusLeave
end

-------------------------------------------------------------------------------------------

local indent='                                                                                                                                                     '
local expandList={}
local tupleList={}
local n=1
function GlobalExplorer:makeList(object, depthIn, prefixIn)
	local depth = depthIn or 0
	local prefix = (prefixIn == nil and "" or prefixIn)
	if depth==0 then n=1 tupleList={} end
	
	local otype=type(object)
	local oname=tostring(object)
	printdebug('GlobalExplorer:makeList for '..oname..'['..otype..']')
	
	-- parse object into tuples
    for i,j in pairs(object) do		
		local elementName=tostring(i)
		local type = type(j)
		local value = tostring(j)
		local fullName=''
		if string.match(elementName,'%a+')==nil then
			fullName=prefix..'['..elementName..']'
		else
			fullName=prefix..'.'..elementName
		end
		local table = (type=="table" and j or nil)
		local qty=(type~='table' and '' or '['..tostring(len(table))..']')
		local listText=string.sub(indent,1,depth*5)..elementName..' = '..tostring(value)..qty

		tupleList[n]={elementName=elementName,type=type,value=value,fullName=fullName,table=table, listText=listText}
		--print('FULLLIST: ['..tostring(n)..'] elementName='..elementName..',type='..tostring(type)..',value='..value..',fullName='..fullName..',table='..tostring(table)..', listText='..listText)
		n=n+1
		if(type=='table' and expandList[fullName]~=nil and expandList[fullName]==1) then
			printdebug('GlobalExplorer:makeList- expanding '..fullName)
			GlobalExplorer:makeList(table,depth+1, fullName)
		end			

	end
	printdebug('GlobalExplorer:makeList- sorting, len before='..tostring(len(tupleList)))
	-- sort tuple list
	table.sort(tupleList, function(left, right) 
		lfn = left==nil and "zzz" or left.fullName
		rfn = right==nil and "zzz" or right.fullName
		--print('tupleSort: left='..tostring(lfn)..', right='..tostring(rfn))
		return lfn < rfn end)
	printdebug('GlobalExplorer:makeList- sort done, len after='..tostring(len(tupleList)))
	return tupleList
end

function GlobalExplorer:expandElement(fullName)
	-- toggle expansion
	if expandList[fullName]~=nil and expandList[fullName]==1 then
		expandList[fullName]=0
	else
		expandList[fullName]=1
	end
    if GlobalExplorer.debug==true then for i,j in pairs(expandList) do printdebug('GlobalExplorer: '..tostring(i)) end end
end

function len(t)
	local n=0
	for i,j in pairs(t) do n=n+1 end
	return n
end

-------------------------------------------------------------------

local function load(mission)
	printdebug('GlobalExplorer: local load, mission='..tostring(mission))
	GlobalExplorer:load(mission)
end

local function unload(mission)
	printdebug('GlobalExplorer: local unload, mission='..tostring(mission))
	GlobalExplorer:unload(mission)
end

local function registerActionEvents(mission)
	printdebug('GlobalExplorer: local registerActionEvents, mission='..tostring(mission))
	GlobalExplorer:registerActionEvents(mission)
end

local function unregisterActionEvents(mission)
	printdebug('GlobalExplorer: local unregisterActionEvents, mission='..tostring(mission))
	GlobalExplorer:unregisterActionEvents(mission)
end
-------------------------------------------------------------------
local function start()
	GlobalExplorer = GlobalExplorer.new()
	-- this func is called when the mod is loaded and this script is executed (explicitly called below)
	printdebug('GlobalExplorer: start')
	source(GlobalExplorer.modDirectory.."gui/GlobalExplorerUI.lua")
	
	-- add mod functions to event system
	Mission00.load = Utils.prependedFunction(Mission00.load, load)
	FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, registerActionEvents)
	BaseMission.unregisterActionEvents = Utils.appendedFunction(BaseMission.unregisterActionEvents, unregisterActionEvents)
end
start()

function GlobalExplorer:createGlobalsFile()
	printdebug('GlobalExplorer:createGlobalsFile(): start')
	-- setup orig file
	local xmlFilename = GlobalExplorer.modDirectory .. "globalsList.xml"
	local xmlFile = loadXMLFile("globals_XML", xmlFilename)
	printdebug('GlobalExplorer:createGlobalsFile()- xmlFilename='..tostring(xmlFilename)..', xmlFile='..tostring(xmlFile))
	
	-- new modSettings file
	local newFilename = GlobalExplorer.globalFilename
	local globalsXML = createXMLFile("globals_XML", newFilename, 'globalList')
	printdebug('GlobalExplorer:createGlobalsFile()- newFilename='..tostring(newFilename)..', newFile='..tostring(newFile))

	-- read original, write modSettings
	local template='globalList.global(%d)#name'
	local i=0
	local global=''
	while true do
		-- read entry
		local key = string.format(template, i)
		if not hasXMLProperty(xmlFile, key) then
			break
		end
		global=getXMLString(xmlFile, key)
		printdebug('GlobalExplorer:createGlobalsFile()- ['..tostring(i)..']'..global..', key='..key)
		
		-- save entry
		setXMLString(globalsXML, key, global)		
		i = i + 1
	end
	saveXMLFile(globalsXML)
	delete(globalsXML)
	printdebug('GlobalExplorer:createGlobalsFile(): end')
end
