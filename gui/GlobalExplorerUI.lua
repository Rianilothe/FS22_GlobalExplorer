--[[

	GlobalExplorerUI - UI functions

]]

GlobalExplorerUI = {}
local GlobalExplorerUI_mt = Class(GlobalExplorerUI,YesNoDialog)

TestElement = {}
local TestElement_mt = Class({})

GlobalExplorerUI.CONTROLS = { 'listItemTemplate', 'geValueList','yesButton','textInputElement', 'currentValue', 'currentVar', 
		'upButton', 'gButton', 'hButton','fButton','favButton','geLayoutBox','allButton','geGlobalList','geGlobalBox','geListBox',
		'listItemText','globalItemText','globalItemTemplate' }
GlobalExplorerUI.currentObject ={}
GlobalExplorerUI.currentObjectName =nil
GlobalExplorerUI.globalsList ={}
GlobalExplorerUI.historyList ={}
GlobalExplorerUI.historyMax=5
GlobalExplorerUI.favoritesList ={}
GlobalExplorerUI.repopulating=0
GlobalExplorerUI.colorMainUI='0.0227 0.5346 0.8519 1.0'
GlobalExplorerUI.colorMainUIv={0.0227, 0.5346, 0.8519, 1.0}
GlobalExplorerUI.colorSelectedUIv={1,1,1,1}
GlobalExplorerUI.colorDisabledUIv={0.0227, 0.5346, 0.8519, 0.5}
GlobalExplorerUI.iconsFilename=g_currentModDirectory..'resources/plusSign.dds'
GlobalExplorerUI.lastIconElement=nil
GlobalExplorerUI.specTypes={'test1','test2'}

GlobalExplorerUI.iconsUV = {
    GLOBAL_LIST = {0, 0, 64, 64},
    HISTORY_LIST = {64, 0, 64, 64}
}

function GlobalExplorerUI.new ()
	printdebug("GlobalExplorerUI: start")
    dialog = YesNoDialog.new(nil, GlobalExplorerUI_mt)

	dialog:registerControls(GlobalExplorerUI.CONTROLS)
	GlobalExplorerUI.currentObject=dialog
	GlobalExplorerUI:loadGlobals()
	GlobalExplorerUI:historyListLoad()
	GlobalExplorerUI:favoritesListLoad()
	GuiOverlay.loadOverlay = GlobalExplorerUI.overwrittenStaticFunction(GuiOverlay.loadOverlay, GlobalExplorerUI.GuiOverlay_loadOverlay)
	
	printdebug("GlobalExplorerUI: self="..tostring(dialog))
    return dialog
end

function GlobalExplorerUI:onOpen()
	printdebug('GlobalExplorerUI:onOpen()- '..tostring(GlobalExplorerUI.currentObjectName)..', historyQty='..tostring(#GlobalExplorerUI.historyList))
	if GlobalExplorerUI.currentObjectName == nil then
		if #GlobalExplorerUI.historyList>0 then
			GlobalExplorerUI.currentObjectName=GlobalExplorerUI.historyList[1]
		else
			GlobalExplorerUI.currentObjectName='g_currentMission' -- default
		end
	end
	dialog.textInputElement:setText(self.currentObjectName)
	GlobalExplorerUI:onFavIconClick()
	GlobalExplorerUI:onGlobalEnterPressed()
	-- save cursor state
	self.cursorBefore = g_inputBinding:getShowMouseCursor()
	g_inputBinding:setShowMouseCursor(true)
	self:populateList()
	--printdebug('GlobalExplorerUI:onOpen()- poplist done')
	
	GlobalExplorerUI:onListSelectionChanged(dialog.geValueList.selectedIndex)
	-- set background to black for list
	dialog.geGlobalList.elements[1].overlay.color[1]=0
	dialog.geGlobalList.elements[1].overlay.color[2]=0
	dialog.geGlobalList.elements[1].overlay.color[3]=0
	dialog.geGlobalList.elements[1].overlay.color[4]=1
	dialog.geGlobalList:setAlpha(1)
	dialog.geGlobalBox:setAlpha(1)
	printdebug('GlobalExplorerUI:onOpen()- loaded '..tostring(#GlobalExplorerUI.specTypes)..' specTypes')
	printdebug('GlobalExplorerUI:onOpen()- end')
end

function GlobalExplorerUI:onKeyEvent()
	printdebug('GlobalExplorerUI:onKeyEvent()')
end

function GlobalExplorerUI.onFocusLeave()
	printdebug('GlobalExplorerUI:onFocusLeave()')
end
function GlobalExplorerUI:onClose()
	printdebug("GlobalExplorerUI: onClose")
	-- restore cursor state
	g_inputBinding:setShowMouseCursor(self.cursorBefore)
end

function GlobalExplorerUI:onListSelectionChanged(rowIndex)
	if GlobalExplorerUI.repopulating==1 then return end
	if rowIndex==0 then rowIndex=1 end
	local d=dialog.tupleList[rowIndex]
	-- update value box
	printdebug('GlobalExplorerUI:onListSelectionChanged()- rowIndex='..tostring(rowIndex)..', d='..tostring(d))
	printdebug('GlobalExplorerUI:onListSelectionChanged()- elementName='..d.elementName..', type='..d.value)

	-- set var
	printdebug('       fullName='..d.fullName..', value = '..d.value)
	dialog.currentVar:setText(d.fullName)
	dialog.currentValue:setText(d.value)
	if d.type=='table' and string.match(d.fullName,'table: ')==nil then
		dialog.upButton.overlay.color[1]=0
		dialog.upButton.overlay.color[2]=1
		dialog.upButton.overlay.color[3]=0
		dialog.upButton.overlay.color[4]=1
		dialog.upButton:setDisabled(false)
	else
		dialog.upButton.overlay.color[1]=0.5
		dialog.upButton.overlay.color[2]=0.5
		dialog.upButton.overlay.color[3]=0.5
		dialog.upButton.overlay.color[4]=0.25
		dialog.upButton:setDisabled(true)
	end
end

function GlobalExplorerUI:onDoubleClick(rowIndex)
	-- save list top, selection
	-- drill down
	printdebug('GlobalExplorerUI:onDoubleClick()- rowIndex='..tostring(rowIndex))
	if rowIndex==0 then rowIndex=1 end
	local d=dialog.tupleList[rowIndex]
	printdebug('GlobalExplorerUI:onDoubleClick()- elementName='..d.elementName..',, fullName='..d.fullName)
	-- get fullname of item
	GlobalExplorer:expandElement(d.fullName)
	GlobalExplorerUI:populateList()
	-- restore list top, selection
end

function GlobalExplorerUI:onClickOk(id)
	printdebug('GlobalExplorerUI:onClickOk('..tostring(id)..')')
	
	-- toggle list/image
	local vl=dialog.geLayoutBox.visible
	local va=dialog.allButton.visible
	printdebug('GlobalExplorerUI:onClickOk- geLayoutBox='..tostring(vl)..', allButton='..tostring(va))
	if vl == true then
		dialog.geLayoutBox:setVisible(false)
		dialog.allButton:setVisible(true)
	else
		dialog.geLayoutBox:setVisible(true)
		dialog.allButton:setVisible(false)
	end
	vl=dialog.geLayoutBox.visible
	va=dialog.allButton.visible
	printdebug('                            geLayoutBox='..tostring(vl)..', allButton='..tostring(va))
end

--	G & H button click handler
function GlobalExplorerUI:onIconClick(element)
	printdebug('GlobalExplorerUI:onIconClick()- '..element.id)
	local v=dialog.geGlobalBox.visible
	printdebug('GlobalExplorerUI:onIconClick()- geGlobalBox='..tostring(v)..', geListBox='..tostring(w))

	local dropdownVisible=dialog.geGlobalBox.visible
	printdebug('GlobalExplorerUI:onIconClick()- dropdownVisible='..tostring(dropdownVisible)..', lastIconElement='..tostring(lastIconElement)..', element.id='..element.id)

	if element.id=='gButton' then
		others={dialog.hButton,dialog.fButton}
	elseif element.id=='hButton' then
		others={dialog.gButton,dialog.fButton}
	else -- fButton
		others={dialog.gButton,dialog.hButton}
	end
	if dropdownVisible and lastIconElement== element then		
		-- close it
		GlobalExplorerUI.lastIconElement= nil
		-- reset button colors
		element.overlay.color[1]=0.0227
		element.overlay.color[2]=0.5346
		element.overlay.color[3]=0.8519
		others[1].overlay.color[1]=0.0227
		others[1].overlay.color[2]=0.5346
		others[1].overlay.color[3]=0.8519
		others[1].overlay.color[4]=1
		others[2].overlay.color[1]=0.0227
		others[2].overlay.color[2]=0.5346
		others[2].overlay.color[3]=0.8519
		others[2].overlay.color[4]=1
		dialog.geGlobalBox.visible=false
		dialog.geListBox.visible=true
		dialog.geValueList:setSelectedIndex(dialog.geValueList.selectedIndex,1)
	else
		-- set list type
		lastIconElement= element
		-- populate list
		self:populateDropdown(element.id)
		-- adjust buttoncolors
		element.overlay.color[1]=1
		element.overlay.color[2]=1
		element.overlay.color[3]=0.4
		others[1].overlay.color[1]=0.0227
		others[1].overlay.color[2]=0.5346
		others[1].overlay.color[3]=0.8519
		others[1].overlay.color[4]=1
		others[2].overlay.color[1]=0.0227
		others[2].overlay.color[2]=0.5346
		others[2].overlay.color[3]=0.8519
		others[2].overlay.color[4]=1
		dialog.geGlobalBox.visible=true
		dialog.geListBox.visible=false
		GlobalExplorerUI.lastIconElement=element
	end
	local v=dialog.geGlobalBox.visible
	local w=dialog.geListBox.visible
	printdebug('                                geGlobalBox='..tostring(v)..', geListBox='..tostring(w))
	printdebug('GlobalExplorerUI:onIconClick()- icon element='..tostring(GlobalExplorerUI.lastIconElement))
end

function GlobalExplorerUI:onGlobalEnterPressed()
	printdebug('GlobalExplorerUI:onGlobalEnterPressed()- text='..dialog.textInputElement.text)
	local text=string.match(dialog.textInputElement.text,'[^()]*') -- strip function call decoration
	local f=loadstring("return "..tostring(text))
	local err=nil
	local err,object=pcall(f)
	local type=type(object)
	printdebug('GlobalExplorerUI:onGlobalEnterPressed()- err='..tostring(err)..', object='..tostring(object)..', type='..type)
	if object == nil then
		printdebug('GlobalExplorerUI:onGlobalEnterPressed()- global "'..text..'" is nil')
		dialog.textInputElement:setText(GlobalExplorerUI.currentObjectName,false,true)
		dialog.geValueList:setSelectedIndex(dialog.geValueList.selectedIndex,1)
	elseif type~='table' then
		printdebug('GlobalExplorerUI:onGlobalEnterPressed()- global "'..text..'" is '..type..'('..object..')')
		dialog.textInputElement:setText(GlobalExplorerUI.currentObjectName,false,true)
		dialog.geValueList:setSelectedIndex(dialog.geValueList.selectedIndex,1)
	elseif len(object) == 0 then
		printdebug('GlobalExplorerUI:onGlobalEnterPressed()- global "'..text..'" is empty table')
		dialog.textInputElement:setText(GlobalExplorerUI.currentObjectName,false,true)
		dialog.geValueList:setSelectedIndex(dialog.geValueList.selectedIndex,1)
	else
		-- clear var/val text fields
		dialog.currentVar:setText('')
		dialog.currentValue:setText('')		
		GlobalExplorerUI.currentObject=object
		GlobalExplorerUI.currentObjectName=text
		GlobalExplorerUI:populateList()
		dialog.geValueList:setSelectedIndex(1,true)
		GlobalExplorerUI:historyListAdd(text)
		printdebug('GlobalExplorerUI:onGlobalEnterPressed()- selection reset')
	end
	GlobalExplorerUI:onFavIconClick()
end

function GlobalExplorerUI:populateList()
	printdebug('GlobalExplorerUI:populateList() geValueList='..tostring(self.geValueList)..', self='..tostring(self)..', dialog='..tostring(dialog))
	local top=dialog.geValueList.firstVisibleItem
	local selected=dialog.geValueList.selectedIndex
	local scrollIndex=dialog.geValueList.sliderElement.currentValue
	GlobalExplorerUI.repopulating=1
	dialog.geValueList:deleteListItems()
	--printdebug('GlobalExplorerUI:populateList() delete complete')
	local d
	--printdebug('      before: top='..tostring(top)..', selected='..tostring(selected)..', current='..GlobalExplorerUI.currentObjectName)
	dialog.tupleList = GlobalExplorer:makeList(GlobalExplorerUI.currentObject,0,GlobalExplorerUI.currentObjectName)
	GlobalExplorerUI.listElements={}
	for i=1,#dialog.tupleList,1 do
        local new = dialog.listItemTemplate:clone(dialog.geValueList)
        new:setVisible(true)
		if dialog.tupleList[i].type=='table' then
			text=dialog.tupleList[i].listText..GlobalExplorerUI:getDescriptiveText(dialog.tupleList[i])
		else
			text=string.match(dialog.tupleList[i].listText,'[^\n]*')
		end
        new.elements[1]:setText(text)		
        new:updateAbsolutePosition()
	end	
	dialog.geValueList.firstVisibleItem=top
	dialog.geValueList.selectedIndex=selected
	dialog.geValueList:updateItemPositions()
	dialog.geValueList.sliderElement:setValue(scrollIndex)
	--printdebug('      after: top='..tostring(dialog.geValueList.firstVisibleItem)..', selected='..tostring(dialog.geValueList.selectedIndex))
	GlobalExplorerUI.repopulating=0
	printdebug('GlobalExplorerUI:populateList() end')
end

local idNames={'name','typeName','typeDesc','title','id','targetName'}
function GlobalExplorerUI:getDescriptiveText(tuple)
	printdebug('GlobalExplorerUI:getDescriptiveText('..tostring(tuple.fullName)..') start')
	local suffix=''
	for k,v in pairs(idNames) do
		if tuple.table[v] ~=nil then			
			suffix=' "'..tuple.table[v]..'"'
			--printdebug('suffix='..suffix)
			break
		end
	end
	printdebug('GlobalExplorerUI:getDescriptiveText() end')
	return suffix
end

function GlobalExplorerUI:populateDropdown(buttonID)
	printdebug('GlobalExplorerUI:populateDropdown() buttonID='..tostring(buttonID))
	dialog.geGlobalList:deleteListItems()
	local list=self.globalsList
	local from=1
	local inc=1
	local grayit=false
	if buttonID=='hButton' then
		list=GlobalExplorerUI.historyList
	elseif buttonID=='fButton' then
		list=GlobalExplorerUI.favoritesList
		printdebug('GlobalExplorerUI:populateDropdown() favoritesList='..tostring(GlobalExplorerUI.favoritesList))
	else -- gButton
		grayit=true
	end
	local to=#list
	for i=from,to,inc do
        local new = dialog.globalItemTemplate:clone(dialog.geGlobalList)
        new:setVisible(true)
        new.elements[1]:setText(list[i])
		if grayit==true and string.match(list[i],' ')~=nil then
			new.elements[1].textColor[1]=0.5
			new.elements[1].textColor[2]=0.5
			new.elements[1].textColor[3]=0.5
			new.elements[1].textColor[4]=0.25			
		end
        new:updateAbsolutePosition()
	end	
	printdebug('GlobalExplorerUI:populateDropdown() end')
end

function GlobalExplorerUI:loadGlobals()
	printdebug('GlobalExplorerUI:loadGlobals()')
	-- open local copy first
	if fileExists(GlobalExplorer.globalFilename)==false then
		GlobalExplorer:createGlobalsFile()
		xmlFile = loadXMLFile("globals_XML", GlobalExplorer.globalFilename)
		printdebug('GlobalExplorerUI:loadGlobals()- xmlFilename='..tostring(GlobalExplorer.globalFilename)..', xmlFile='..tostring(xmlFile))
	end
	local xmlFile = loadXMLFile("globals_XML", GlobalExplorer.globalFilename)
	--printdebug('GlobalExplorerUI:loadGlobals()- xmlFilename='..tostring(GlobalExplorer.globalFilename)..', xmlFile='..tostring(xmlFile))
	local template='globalList.global(%d)#name'
	local i=1
	self.globalsList={}
	while true do
		local key = string.format(template, i-1)
		if not hasXMLProperty(xmlFile, key) then
			break
		end
		local g=getXMLString(xmlFile, key)
		local f=loadstring('return '..g)
		local obj=f()
		local suffix=''
		if obj==nil then
			suffix=' (nil)'
		elseif type(obj)=='table' and len(obj)==0 then
			suffix=' (empty table)'
		elseif type(obj)~='table' then
			suffix=' ('..tostring(obj)..')'
		end
		--printdebug('    '..g..'='..tostring(f())..', suffix='..suffix)
		self.globalsList[i]=getXMLString(xmlFile, key)..suffix
		--printdebug('GlobalExplorerUI:loadGlobals()- ['..tostring(i)..']='..self.globalsList[i])
		i = i + 1
	end
--	for i=1,#self.globalsList,1 do
--		print('     ['..tostring(i)..'] '..self.globalsList[i])
--	end	
end

function GlobalExplorerUI:onGlobalDoubleClick(rowIndex)
	-- save list top, selection
	-- drill down
	printdebug('GlobalExplorerUI:onGlobalDoubleClick()- rowIndex='..tostring(rowIndex))
	if rowIndex==0 then rowIndex=1 end
	local d=dialog.geGlobalList:getSelectedElement()
	local g=d.elements[1].text
	printdebug('GlobalExplorerUI:onGlobalDoubleClick()- value='..g)
	if string.match(g,' ')~=nil then return end
	dialog.textInputElement:setText(g)
	GlobalExplorerUI:onGlobalEnterPressed(GlobalExplorerUI.lastIconElement)
	printdebug('GlobalExplorerUI:onGlobalDoubleClick()- icon element='..tostring(GlobalExplorerUI.lastIconElement))
	GlobalExplorerUI:onIconClick(GlobalExplorerUI.lastIconElement)
end

--
--	History list management
--
function GlobalExplorerUI:historyListAdd(item)
	printdebug('historyListAdd: start '..tostring(item))
	
	-- remove item if already in list
	for i,j in ipairs(GlobalExplorerUI.historyList) do
		if j==item then
			--printdebug('historyListAdd: remove '..item)
			table.remove(GlobalExplorerUI.historyList,i)
			break
		end
	end
	
	-- add at beginning
	--printdebug('historyListAdd: add')
	table.insert(GlobalExplorerUI.historyList,1,item)
	
	-- if len > max then remove last item
	--printdebug('historyListAdd: clip')
	while #GlobalExplorerUI.historyList>GlobalExplorerUI.historyMax do
		--printdebug('historyListAdd: clip '..GlobalExplorerUI.historyList[#GlobalExplorerUI.historyList])
		table.remove(GlobalExplorerUI.historyList,#GlobalExplorerUI.historyList)
	end

	--if GlobalExplorer.debug==true then for i,j in ipairs(GlobalExplorerUI.historyList) do printdebug('['..tostring(i)..'] '..j) end end
	GlobalExplorerUI:updateHistoryFile()
	printdebug('historyListAdd: end')
end

function GlobalExplorerUI:historyListLoad()
	printdebug('GlobalExplorerUI:historyListLoad()')
	-- open local copy first
	if fileExists(GlobalExplorer.historyFilename)==false then
		return
	end
	local xmlFile = loadXMLFile("history_XML", GlobalExplorer.historyFilename)
	--printdebug('GlobalExplorerUI:historyListLoad()- xmlFilename='..tostring(GlobalExplorer.historyFilename)..', xmlFile='..tostring(xmlFile))
	local template='historyList.historyItem(%d)#name'
	local i=1
	GlobalExplorerUI.historyList={}
	while true do
		local key = string.format(template, i-1)
		if not hasXMLProperty(xmlFile, key) then
			break
		end
		GlobalExplorerUI.historyList[i]=getXMLString(xmlFile, key)
		--printdebug('GlobalExplorerUI:historyListLoad()- ['..tostring(i)..']='..GlobalExplorerUI.historyList[i])
		i = i + 1
	end
end

function GlobalExplorerUI:updateHistoryFile()
	printdebug('GlobalExplorer:updateHistoryFile(): start')

	-- new modSettings file
	local historyXML = createXMLFile("history_XML", GlobalExplorer.historyFilename, 'historyList')
	--printdebug('GlobalExplorer:updateHistoryFile()- newFilename='..tostring(GlobalExplorer.historyFilename)..', historyXML='..tostring(historyXML))

	-- read original, write modSettings
	local template='historyList.historyItem(%d)#name'
	local history=''
	for i,j in ipairs(GlobalExplorerUI.historyList) do
		-- read entry
		local key = string.format(template, i-1)
		history=j
		--printdebug('GlobalExplorer:updateHistoryFile()- ['..tostring(i)..']'..history..', key='..key)		
		-- save entry
		setXMLString(historyXML, key, history)		
	end
	saveXMLFile(historyXML)
	delete(historyXML)
	printdebug('GlobalExplorer:updateHistoryFile(): end')
end

function GlobalExplorerUI:onFavIconClick(element)
	printdebug('GlobalExplorerUI:onFavIconClick(): start')
	-- get element from list
	local index = 0
	local updateFile=false
	local inlist = false
	for i,j in ipairs(GlobalExplorerUI.favoritesList) do
		if GlobalExplorerUI.currentObjectName==j then
			index=i
			inlist=true
			break
		end
	end
	--printdebug('GlobalExplorerUI:onFavIconClick(): inlist='..tostring(inlist))
	-- update list, reset status
	if element~=nil then 
		-- icon click
		if inlist then
			table.remove(GlobalExplorerUI.favoritesList,index)
			inlist=false
		else
			table.insert(GlobalExplorerUI.favoritesList,GlobalExplorerUI.currentObjectName)
			inlist=true
		end
		updateFile=true
	else
		-- initialization
		element=dialog.favButton
	end
	-- update icon
	if inlist then
		element.overlay.color[1]=0.0227
		element.overlay.color[2]=0.5346
		element.overlay.color[3]=0.8519
		element.overlay.color[4]=1
	else
		element.overlay.color[1]=0.5
		element.overlay.color[2]=0.5
		element.overlay.color[3]=0.5
		element.overlay.color[4]=0.25
	end
	table.sort(GlobalExplorerUI.favoritesList)
	if updateFile then GlobalExplorerUI:updateFavoritesFile() end
	printdebug('GlobalExplorerUI:onFavIconClick(): end')
end

function GlobalExplorerUI:updateFavoritesFile()
	printdebug('GlobalExplorer:updateFavoritesFile(): start')

	-- new modSettings file
	local favoritesXML = createXMLFile("favorites_XML", GlobalExplorer.favoritesFilename, 'favoritesList')
	--printdebug('GlobalExplorer:updateFavoritesFile()- newFilename='..tostring(GlobalExplorer.favoritesFilename)..', favoritesXML='..tostring(favoritesXML))

	-- read original, write modSettings
	local template='favoritesList.favoritesItem(%d)#name'
	local favorites=''
	for i,j in ipairs(GlobalExplorerUI.favoritesList) do
		-- read entry
		local key = string.format(template, i-1)
		favorites=j
		--printdebug('GlobalExplorer:updateFavoritesFile()- ['..tostring(i)..']'..favorites..', key='..key)		
		-- save entry
		setXMLString(favoritesXML, key, favorites)		
	end
	saveXMLFile(favoritesXML)
	delete(favoritesXML)
	printdebug('GlobalExplorer:updateFavoritesFile(): end')
end

function GlobalExplorerUI:favoritesListLoad()
	printdebug('GlobalExplorerUI:favoritesListLoad()')
	-- open local copy first
	if fileExists(GlobalExplorer.favoritesFilename)==false then
		return
	end
	local xmlFile = loadXMLFile("favorites_XML", GlobalExplorer.favoritesFilename)
	--printdebug('GlobalExplorerUI:favoritesListLoad()- xmlFilename='..tostring(GlobalExplorer.favoritesFilename)..', xmlFile='..tostring(xmlFile))
	local template='favoritesList.favoritesItem(%d)#name'
	local i=1
	GlobalExplorerUI.favoritesList={}
	while true do
		local key = string.format(template, i-1)
		if not hasXMLProperty(xmlFile, key) then
			break
		end
		GlobalExplorerUI.favoritesList[i]=getXMLString(xmlFile, key)
		--printdebug('GlobalExplorerUI:favoritesListLoad()- ['..tostring(i)..']='..GlobalExplorerUI.favoritesList[i])
		i = i + 1
	end
end

function GlobalExplorerUI:onUpIconClick(element)
	printdebug('GlobalExplorerUI:onUpIconClick()')
	local name=dialog.currentVar:getText()
	printdebug('GlobalExplorerUI:onUpIconClick(): '..name)
	dialog.textInputElement:setText(name)
	GlobalExplorerUI:onGlobalEnterPressed(GlobalExplorerUI.lastIconElement)
end

function GlobalExplorerUI.GuiOverlay_loadOverlay(superFunc, ...)
	local overlay = superFunc(...)
	if overlay == nil then
		return nil
	end

	if overlay.filename == "g_globalExplorerUIFilename" then
		overlay.filename = g_globalExplorerUIFilename
	elseif overlay.filename == "g_globalExplorerUIFilename2" then
		overlay.filename = g_globalExplorerUIFilename2
	end

	return overlay
end


function GlobalExplorerUI.overwrittenStaticFunction(oldFunc, newFunc)
	return function(...)
		return newFunc(oldFunc, ...)
	end
end
