local L = SubSpecGlobal.L

local mainFrame = nil

local eventFrame = CreateFrame("Frame", "SubSpec_EventFrame", UIParent)
eventFrame:Show()

local updateTalentsFrame = CreateFrame("Frame", "SubSpec_UpdateTalentsFrame", UIParent)
updateTalentsFrame:Show()


local function GetCurrentTalents()
	local ret = {}
	for tier = 1, GetMaxTalentTier() do
		ret[tier] = {}
		for column = 1, 3 do
			local id, name, texture, selected, available = GetTalentInfo(tier, column, GetActiveSpecGroup())
			if selected then
				ret[tier]["column"] = column
				ret[tier]["id"] = id
				ret[tier]["name"] = name
				break
			end
		end
	end
	return ret
end

local chatFilterMatches = {
	"^"..ERR_SPELL_UNLEARNED_S:gsub("%%s", "(.+)"),
	"^"..ERR_LEARN_PASSIVE_S:gsub("%%s", "(.+)"),
	"^"..ERR_LEARN_SPELL_S:gsub("%%s", "(.+)"),
	"^"..ERR_LEARN_ABILITY_S:gsub("%%s", "(.+)")
}
local function ChatFilter(self, event, msg, ...)
	for _, m in pairs(chatFilterMatches) do
		if msg:match(m) then return true; end
	end
	return false, msg, ...
end
local function StartChatFiltering()
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)
end
local function StopChatFiltering()
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", ChatFilter)
end

local elapsedTime = -1
local talents = {}
local changesCount = 0
local function OnUpdateChangeTalents(self, elapsed)
	if elapsedTime >= 0.2 then
		local currentData = GetCurrentTalents()
		local changed = false
		for i = 1, #talents do
			local tier = talents[i][1]
			local selfId = talents[i][2]
			local currId = currentData[tier]["id"]
			if currId == 0 or currId ~= selfId then
				LearnTalents(selfId)
				changed = true
			end
		end
		
		changesCount = changesCount + 1
		if changed == false or changesCount >= 20 then
			updateTalentsFrame:SetScript("OnUpdate", nil)
			StopChatFiltering()
		end
		elapsedTime = 0
	else
		elapsedTime = elapsedTime + elapsed
	end
end

local function CheckCurrentProfile()
	local current = GetCurrentTalents()
	for i = 1, mainFrame.visibleProfiles do
		local profileData = mainFrame.profiles[i].data
		local match = true
		for tier = 1, GetMaxTalentTier() do
			if (current[tier] and not profileData[tier])
				or (not current[tier] and profileData[tier])
				or (current[tier] and profileData[tier] and current[tier]["id"] ~= profileData[tier]["id"]) then
				match = false
				break
			end
		end
		if match then
			mainFrame.currentButton:ShowOn(mainFrame.profiles[i].button)
			return
		end
	end
	mainFrame.currentButton:Hide()
end

local function SaveProfiles()
	local specId = GetSpecialization()
	if specId then
		if not SubSpecStorage then SubSpecStorage = {}; end
		local class = UnitClass("player")
		local spec = select(2, GetSpecializationInfo(specId))
		if class and spec then
			local specName = class.." "..spec
			SubSpecStorage[specName] = {}
			for i = 1, mainFrame.visibleProfiles do
				table.insert(SubSpecStorage[specName], {name = mainFrame.profiles[i].button:GetText(), data = mainFrame.profiles[i].data})
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFffff00SubSpec:|r |cFFffc0c0Can not save profiles|r")
		end
	end
end

local function CreateNewProfileButton(parent, text, data)
	local ret = CreateFrame("Frame", nil, parent)
	ret.data = data
	ret:Show()

	ret.button = CreateFrame("Button", nil, ret, "UIPanelButtonTemplate")
	ret.button:Show()
	ret.button:SetText(text)
	ret.button:SetPoint("TOPLEFT", 5, -2)
	ret.button:SetPoint("BOTTOMRIGHT", -20, 2)
	ret.button.profileFrame = ret
	ret.button:SetScript("OnEnter", function(self)
		mainFrame.menuButton:ShowOn(self.profileFrame)

		local text = ""
		for tier = 1, GetMaxTalentTier() do
			if self.profileFrame.data[tier]["name"] then
				text = text..self.profileFrame.data[tier]["name"].."\n"
			end
		end
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(text)
		GameTooltip:Show()
	end)
	ret.button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	ret.button:SetAttribute("type", "macro")

	ret.button:SetScript("OnClick", function(self)
		if InCombatLockdown() then return; end
		talents = {}
		mainFrame.currentButton:ShowOn(self)
		local currentData = GetCurrentTalents()
		StartChatFiltering()
		for tier = 1, GetMaxTalentTier() do
			if self.profileFrame.data and self.profileFrame.data[tier] and self.profileFrame.data[tier]["id"] and self.profileFrame.data[tier]["id"] > 0 then
				local selfId = self.profileFrame.data[tier]["id"]
				local currId = currentData[tier]["id"]
				if currId == 0 or currId ~= selfId then
					LearnTalents(selfId)
					
					table.insert(talents, {tier, selfId})
					elapsedTime = 0
					changesCount = 0
					updateTalentsFrame:SetScript("OnUpdate", OnUpdateChangeTalents)
				end
			end
		end
		if #talents == 0 then StopChatFiltering(); end
	end)

	ret.index = 0
	ret:SetScript("OnEnter", function(self) mainFrame.menuButton:ShowOn(self); end)
	ret.CopyFrom = function(self, frame)
		self.data = frame.data
		self.button:SetText( frame.button:GetText() )
	end
	return ret
end

local function UpdateScrollWidth()
	mainFrame.profilesFrame:SetWidth(10 + mainFrame.visibleProfiles*145)
end

local function AddProfileButton(text, data)
	if mainFrame.visibleProfiles == #mainFrame.profiles then
		local newButtonFrame = CreateNewProfileButton(mainFrame.profilesFrame, text, data)
		newButtonFrame:SetSize(145, mainFrame.profilesFrame:GetHeight())
		newButtonFrame.index = #mainFrame.profiles + 1
		newButtonFrame:SetPoint("TOPLEFT", #mainFrame.profiles*145, 0)
		table.insert(mainFrame.profiles, newButtonFrame)
		mainFrame.visibleProfiles = mainFrame.visibleProfiles + 1
	else
		mainFrame.visibleProfiles = mainFrame.visibleProfiles + 1
		local frame = mainFrame.profiles[mainFrame.visibleProfiles]
		frame.button:SetText(text)
		frame.data = data
		frame:Show()
	end

	UpdateScrollWidth()
	SaveProfiles()
	CheckCurrentProfile()
end

local function MenuRename()
	if mainFrame.menuButton.index > 0 then
		StaticPopup_Show("SubSpec_RenameDialog")
		StaticPopup3EditBox:SetMaxLetters(20)
		StaticPopup3EditBox:SetText( mainFrame.profiles[mainFrame.menuButton.index].button:GetText() );
		StaticPopup3EditBox:HighlightText()
	end
end
local function MenuRenameApply()
	if mainFrame.menuButton.index > 0 then
		mainFrame.profiles[mainFrame.menuButton.index].button:SetText( StaticPopup3EditBox:GetText() )
		SaveProfiles()
	end
end

local function MenuSave()
	if mainFrame.menuButton.index > 0 then
		local profile = mainFrame.profiles[mainFrame.menuButton.index]
		profile.data = GetCurrentTalents()

		local interestSpellIds = {}
		for tier = 1, GetMaxTalentTier() do
			local talentName = profile.data[tier]["name"]
			local name, rank, icon, castingTime, minRange, maxRange, spellId = GetSpellInfo(talentName)
			if name and spellId then
				interestSpellIds[spellId] = profile.data[tier]["id"]
			end
		end

		SaveProfiles()
		mainFrame.currentButton:ShowOn(profile.button)
	end
end

local function MenuRemove()
	if mainFrame.menuButton.index > 0 then
		for i = mainFrame.menuButton.index + 1, mainFrame.visibleProfiles do
			local leftFrame = mainFrame.profiles[i-1]:CopyFrom(mainFrame.profiles[i])
		end
		mainFrame.profiles[mainFrame.visibleProfiles]:Hide()
		mainFrame.visibleProfiles = mainFrame.visibleProfiles - 1
		UpdateScrollWidth()
		SaveProfiles()
		mainFrame.menuButton:Hide()
		CheckCurrentProfile()
	end
end

local function MenuMoveLeft()
	if mainFrame.menuButton.index > 1 then
		local leftFrame = mainFrame.profiles[mainFrame.menuButton.index-1]
		local rightFrame = mainFrame.profiles[mainFrame.menuButton.index]
		local data = leftFrame.data
		local text = leftFrame.button:GetText()
		leftFrame:CopyFrom(rightFrame)
		rightFrame.data = data
		rightFrame.button:SetText(text)
		SaveProfiles()
		mainFrame.menuButton:Hide()
		CheckCurrentProfile()
	end
end

local function MenuMoveRight()
	if mainFrame.menuButton.index > 0 and mainFrame.menuButton.index < mainFrame.visibleProfiles then
		local leftFrame = mainFrame.profiles[mainFrame.menuButton.index]
		local rightFrame = mainFrame.profiles[mainFrame.menuButton.index+1]
		local data = leftFrame.data
		local text = leftFrame.button:GetText()
		leftFrame:CopyFrom(rightFrame)
		rightFrame.data = data
		rightFrame.button:SetText(text)
		SaveProfiles()
		mainFrame.menuButton:Hide()
		CheckCurrentProfile()
	end
end

local function LoadSpecData()
	if not SubSpecStorage then SubSpecStorage = {}; end
	local specId = GetSpecialization()
	if specId then
		mainFrame.createButton:Show()
		local class = UnitClass("player")
		local spec = select(2, GetSpecializationInfo(specId))
		if class and spec then
			local specName = class.." "..spec
			local storage = SubSpecStorage[specName] or SubSpecStorage[spec]
			if storage then
				for _, profile in ipairs(storage) do
					AddProfileButton(profile["name"], profile["data"])
				end
			end

			if not SubSpecStorage[specName] and SubSpecStorage[spec] then
				SubSpecStorage[specName] = {}
				for _, profile in ipairs(SubSpecStorage[spec]) do
					table.insert(SubSpecStorage[specName], {name = profile["name"], data = profile["data"]})
				end
			end
		end
	else
		mainFrame.createButton:Hide()
		mainFrame.menuButton:Hide()
	end
end

local function CreateUi()
	mainFrame = CreateFrame("Frame", "SubSpec_MainFrame", PlayerTalentFrameTalents)
	mainFrame:Hide()
	SubSpecGlobal._mainFrame = mainFrame

	local elvUi = IsAddOnLoaded("ElvUI")
	
	mainFrame.texture = mainFrame:CreateTexture(nil, "ARTWORK")
	mainFrame.texture:SetPoint("TOPLEFT")
	if elvUi then
		mainFrame:SetSize(635, 50)
		mainFrame:SetPoint("TOPLEFT", PlayerTalentFrame, "TOPLEFT", 5, -20)
		mainFrame.texture:SetTexture("Interface\\AddOns\\SubSpec\\Images\\BackgroundElvUI.tga")
	else
		mainFrame:SetSize(585, 50)
		mainFrame:SetPoint("TOPLEFT", PlayerTalentFrame, "TOPLEFT", 52, -20)
		mainFrame.texture:SetTexture("Interface\\AddOns\\SubSpec\\Images\\BackgroundStandard.tga")
	end
	mainFrame:Show()

	--legion version check:
	local version = tonumber(string.sub(GetBuildInfo(), 1, 1))
	if version < 7 then
		local text = mainFrame:CreateFontString(nil, nil, "GameFontNormalLeft")
		text:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
		text:SetPoint("CENTER")
		text:SetTextColor(0.7, 0.1, 0)
		text:SetText(L["versionError"])
		return
	end

	--create button:
	mainFrame.createButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
	mainFrame.createButton:SetText("+")
	mainFrame.createButton:SetPoint("TOPLEFT", 20, -16)
	mainFrame.createButton:SetSize(20, 18)
	mainFrame.createButton:SetScript("OnClick", function() AddProfileButton(L["new"], GetCurrentTalents()); end)

	--scroll:
	local scroll = CreateFrame("ScrollFrame", "SubSpec_Scroll", mainFrame)
	scroll:Show()
	scroll:SetPoint("TOPLEFT", 50, -13)
	scroll:SetPoint("BOTTOMRIGHT", -10, 13)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local range = self:GetHorizontalScrollRange()
		local scroll = self:GetHorizontalScroll()
		if delta < 0 then
			scroll = scroll + 20
			if scroll < range then
				self:SetHorizontalScroll(scroll)
			else
				self:SetHorizontalScroll(range)
			end
		else
			scroll = scroll - 20
			if scroll > 0 then
				self:SetHorizontalScroll(scroll)
			else
				self:SetHorizontalScroll(0)
			end
		end
	end)
	mainFrame.scroll = scroll

	local scrollContainer = CreateFrame("Frame", nil, scroll)
	scrollContainer:Show()
	scrollContainer:SetPoint("TOPLEFT")
	scrollContainer:SetWidth(scroll:GetWidth())
	scrollContainer:SetHeight(scroll:GetHeight())
	scroll:SetScrollChild(scrollContainer)
	mainFrame.scrollContainer = scrollContainer

	mainFrame.profilesFrame = CreateFrame("Frame", nil, scrollContainer)
	mainFrame.profilesFrame:SetPoint("TOPLEFT")
	mainFrame.profilesFrame:SetSize(10, scrollContainer:GetHeight())

	--menu button:
	local menuButton = CreateFrame("Button", nil, mainFrame.profilesFrame)
	menuButton:Hide()
	menuButton:SetSize(15, 15)
	menuButton:SetFrameLevel(mainFrame.profilesFrame:GetFrameLevel() + 3)
	menuButton:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
	menuButton:SetPushedTexture("Interface\\Buttons\\Arrow-Down-Down")
	menuButton.index = -1
	menuButton.ShowOn = function(self, profileFrame)
		self:SetPoint("TOPLEFT", profileFrame.button, "TOPRIGHT", 1, -7)
		if self.index ~= profileFrame.index then
			self.index = profileFrame.index
			if UIDROPDOWNMENU_OPEN_MENU == mainFrame.menuFrame then DropDownList1:Hide(); end
		end
		self:Show()
	end
	mainFrame.menuButton = menuButton

	mainFrame.menuFrame = CreateFrame("Frame", "SubSpec_MenuFrame", menuButton, "UIDropDownMenuTemplate")
	mainFrame.menuFrame:Hide()
	mainFrame.menuFrame.displayMode = "MENU"
	menuTexts = {
		{text = L["save"], notCheckable = true, func = MenuSave},
		{text = L["rename"], notCheckable = true, func = MenuRename},
		{text = L["moveLeft"], notCheckable = true, func = MenuMoveLeft},
		{text = L["moveRight"], notCheckable = true, func = MenuMoveRight},
		{text = L["remove"], notCheckable = true, func = MenuRemove}
	}
	UIDropDownMenu_Initialize(mainFrame.menuFrame, EasyMenu_Initialize, "MENU", nil, menuTexts)
	menuButton:SetScript("OnClick", function() ToggleDropDownMenu(1, nil, mainFrame.menuFrame, menuButton, 0, 0, menuTexts, nil, nil); end)
	menuButton:SetScript("OnHide", function(self)
		self.index = 0
		if UIDROPDOWNMENU_OPEN_MENU == mainFrame.menuFrame then DropDownList1:Hide(); end
	end)
	StaticPopupDialogs["SubSpec_RenameDialog"] = {
		text = L["renameText"],
		button1 = L["rename"],
		button2 = L["cancel"],
		OnAccept = MenuRenameApply,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		hasEditBox = true,
		enterClicksFirstButton  = true
	}

	mainFrame:SetScript("OnHide", function(self)
		if UIDROPDOWNMENU_OPEN_MENU == mainFrame.menuFrame then DropDownList1:Hide(); end
		self.menuButton:Hide()
		StaticPopup_Hide("SubSpec_RenameDialog")
	end)

	--current button:
	local currentButton = CreateFrame("Frame", nil, mainFrame.profilesFrame)
	currentButton:Hide()
	currentButton:SetSize(15, 15)
	currentButton:SetFrameLevel(mainFrame.profilesFrame:GetFrameLevel() + 4)
	currentButton.texture = currentButton:CreateTexture(nil, "ARTWORK")
	currentButton.texture:SetAllPoints()
	currentButton.texture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	currentButton.ShowOn = function(self, profileButton)
		self:SetPoint("TOPLEFT", profileButton, "TOPLEFT", 0, 4)
		self:Show()
	end
	mainFrame.currentButton = currentButton

	--data:
	mainFrame.profiles = {}
	mainFrame.visibleProfiles = 0
	LoadSpecData()
end

local startTime = -1
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
local function OnEvent(self, event, ...)
	if event == "PLAYER_LOGIN" then
		startTime = GetTime()
	elseif (event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED") and mainFrame then
		for i = 1, mainFrame.visibleProfiles do
			mainFrame.profiles[i]:Hide()
		end
		mainFrame.visibleProfiles = 0
		LoadSpecData()
		CheckCurrentProfile()
	elseif event == "PLAYER_TALENT_UPDATE" and mainFrame then
		CheckCurrentProfile()
	end
end
eventFrame:SetScript("OnEvent", OnEvent)

local function OnUpdateInitialization(self, elapsed)
	if startTime >= 0 and GetTime() - startTime > 2 and IsAddOnLoaded("Blizzard_TalentUI") then
		eventFrame:SetScript("OnUpdate", nil)
		startTime = nil
		CreateUi()
		CheckCurrentProfile()
	end
end
eventFrame:SetScript("OnUpdate", OnUpdateInitialization)

SLASH_SUBSPEC1, SLASH_SUBSPEC2 = "/subspec", "/ss"
function SlashCmdList.SUBSPEC(msg)
	if msg == "version" then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFffff00SubSpec:|r Version - "..GetAddOnMetadata("SubSpec", "Version"))
	else
		local cmd = string.sub(msg, 1, 5)
		if cmd == "load " then
			local profile = string.sub(msg, 6)
			if mainFrame then
				for i = 1, mainFrame.visibleProfiles do
					if mainFrame.profiles[i].button:GetText() == profile then
						mainFrame.profiles[i].button:Click()
						return
					end
				end
			else
				local class = UnitClass("player")
				local specId = GetSpecialization()
				if specId then
					local spec = select(2, GetSpecializationInfo(specId))
					if class and spec then
						local specName = class.." "..spec
						local storage = SubSpecStorage[specName] or SubSpecStorage[spec]
						if storage then
							for _, storageProfile in ipairs(storage) do
								if storageProfile["name"] == profile then
									talents = {}
									StartChatFiltering()
									local profileData = storageProfile["data"]
									local currentData = GetCurrentTalents()
									for tier = 1, GetMaxTalentTier() do
										if profileData and profileData[tier] and profileData[tier]["id"] and profileData[tier]["id"] > 0
											and currentData and currentData[tier] and currentData[tier]["id"] then
											local selfId = profileData[tier]["id"]
											local currId = currentData[tier]["id"]
											if currId == 0 or currId ~= selfId then
												LearnTalents(selfId)
												
												table.insert(talents, {tier, selfId})
												elapsedTime = 0
												changesCount = 0
												updateTalentsFrame:SetScript("OnUpdate", OnUpdateChangeTalents)
											end
										end
									end
									if #talents == 0 then StopChatFiltering(); end
									return
								end
							end
						end
					end
				end
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cFFffff00SubSpec|r: Profile not found")
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cFFffff00SubSpec|r commands:")
			DEFAULT_CHAT_FRAME:AddMessage("   |cFFffff00/subspec load <profile name>|r - load the talents profile")
			DEFAULT_CHAT_FRAME:AddMessage("   |cFFffff00/subspec version|r - print the addon version")
		end
	end
end
