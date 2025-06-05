local debugEnabled = true
local originalGetCategorySet = C_CooldownViewer.GetCooldownViewerCategorySet
local addon_name = "CDM Buff Bar Editor"
local copyDB = {}
local spellDBcopy = {}
local checkBoxNames = {}
local isLoaded = false

----------- DEBUG HELPERS ----------
local function debug(text) 
	if debugEnabled then 
		print(text) 
	end
end

local function printTable(table)
	for key, value in pairs(table) do
		debug(key .. ", " .. tostring(value))
	end
end

------ INIT DB and copyDB --------
local function loadSavedVariables() 
	if nil == cdmbbeDB then
		cdmbbeDB = {}
		debug("new spell names")
	end

	if nil == cdmbbe_spellDB then
		cdmbbe_spellDB = {}
		debug("new cooldown IDs")
	end
	copyDB = cdmbbeDB
	spellDBcopy = cdmbbe_spellDB
	debug("saved vars table loaded")
end

------ FUNCTIONS --------
local function UpdateCooldownViewerCategorySet(category)
	local catSet = originalGetCategorySet(category)

	if category == 3 then
		catSet = {}
		for key, value in pairs(spellDBcopy) do
			if copyDB[key] then
				table.insert(catSet, value)
			end
		end
	end

	return catSet
end

local function createCheckbox(panel, label, key)
	local checkBox = CreateFrame("CheckButton", addon_name .. "Check" .. label, panel, "InterfaceOptionsCheckButtonTemplate")
	checkBox:SetChecked(copyDB[key])
	checkBox:SetScript("OnClick", function(self)
		cdmbbeDB[key] = self:GetChecked()
		copyDB[key] = self:GetChecked()
	end)
	checkBox.Text:SetText(label)
	return checkBox
 end
 
 local function generateOptionsFromCategory(parent, titleFrame, index, category)
	local cdIds = originalGetCategorySet(category)
	for _, cdId in pairs(cdIds) do
		local cdInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(cdId)
		if cdInfo["selfAura"] or category == 3 then
			local spellName = C_Spell.GetSpellName(cdInfo["spellID"])
			local spellKey = spellName:gsub("%s+", "")
			
			if nil == copyDB[spellKey] or nil == spellDBcopy[spellKey] then
				spellDBcopy[spellKey] = cdId
				copyDB[spellKey] = (category == 3)
				debug("Adding spell: " .. spellName)
			end
			
			if not checkBoxNames[spellKey] then
				local checkbox = createCheckbox(parent, spellName , spellKey)
				local yOffset = -1 * (checkbox:GetHeight() + 5) * index
				checkbox:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, yOffset - 5)
				index = index + 1
				checkBoxNames[spellKey] = true
			end
		end
	end
	return index
 end
 
 local function OnFrameHide()
	BuffBarCooldownViewer:RefreshData()			
	--Color changes need to be applied here
	
	--Make the event handler write to DB before Logout Event?
	cdmbbe_spellDB = spellDBcopy
	cdmbbeDB = copyDB
	debug("refreshed")
 end

local function create_options_category()
	local scroll
	if not isLoaded then
		local frame = CreateFrame("Frame")
		frame.name = addon_name
		frame:SetScript("OnHide", OnFrameHide)

		local settings_category, _ = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
		settings_category.ID = frame.name
		Settings.RegisterAddOnCategory(settings_category)
	
		scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 3, -4)
		scroll:SetPoint("BOTTOMRIGHT", -27, 4)
		
		isLoaded = true
	end

	local container = CreateFrame("Frame")
	scroll:SetScrollChild(container)
	container:SetWidth(SettingsPanel.Container:GetWidth()-25)
	container:SetHeight(1) 

	local name = container:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
	name:SetPoint("TOPLEFT", 16, -16)
	name:SetText(addon_name)
	
	index = 0
	index = generateOptionsFromCategory(container, name, index, 0)
	index = generateOptionsFromCategory(container, name, index, 1)
	index = generateOptionsFromCategory(container, name, index, 2)
	index = generateOptionsFromCategory(container, name, index, 3)
end

local function loadOptions() 
	if C_CooldownViewer.IsCooldownViewerAvailable() then
		create_options_category()
		C_CooldownViewer.GetCooldownViewerCategorySet = UpdateCooldownViewerCategorySet
	else
		debug("Cooldown Mananger must be enabled")
	end
end

--5686 Time Warp
--16864 Bloodlust

debug("functions loaded")

------- SLASH COMMANDS --------

SLASH_CDMBBE1 = '/cdmbbe'
local function handler(msg, editBox)
	local command, rest = msg:match("^(%S*)%s*(.-)$")
	if command == "child" then
		--BuffBarCooldownViewer:GetItemFrames()[2]:GetBarFrame():SetStatusBarColor(1.0, 0.0, 1.0, 1.0)
		printTable(BuffBarCooldownViewer:GetItemFrames()[1])
	elseif command == "refresh" then
		BuffBarCooldownViewer:RefreshData()
		debug("refreshed")
	elseif command == "enable" then
		loadOptions()
	else
		print("Cooldown Manager Buff Bar Editor" .. "- Commands:")
        print("/cdmbbe child - Lists Children of the BuffBarCooldownViewer object")
        print("/cdmbbe refresh - Refreshes the buff bar")
        print("/cdmbbe enable - Override the Buff Bar with new spells")
	end
end
SlashCmdList["CDMBBE"] = handler

debug("slash command loaded")

local main = CreateFrame("frame")
main:RegisterEvent("PLAYER_LOGIN")
main:RegisterEvent("ADDON_LOADED")
main:RegisterEvent("SELECTED_LOADOUT_CHANGED")
main:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
main:RegisterEvent("PLAYER_TALENT_UPDATE")
main:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "MyFirstAddon" then
		loadSavedVariables()
	elseif event == "PLAYER_LOGIN" or event == "SELECTED_LOADOUT_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
		debug("Event trigger: " .. event)
		loadOptions()
		BuffBarCooldownViewer:RefreshData()	
	end
end)
