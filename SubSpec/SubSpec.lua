local L = SubSpecGlobal.L

local mainFrame = nil

local eventFrame = CreateFrame("Frame", "SubSpec_EventFrame", UIParent)
eventFrame:Show()

local function GetCurrentTalents()
	local ret = {}
	for tier = 1, 7 do
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
	ret["bar"] = {}
	return ret
end

local function SaveProfiles()
	local specId = GetSpecialization()
	if specId then
		local spec = select(2, GetSpecializationInfo(specId))
		if not SubSpecStorage then SubSpecStorage = {}; end
		SubSpecStorage[spec] = {}
		for i = 1, mainFrame.visibleProfiles do
			table.insert(SubSpecStorage[spec], {name = mainFrame.profiles[i].buttonBackground:GetText(), data = mainFrame.profiles[i].data})
		end
	end
end

local waitTable = {};
local waitFrame = nil;
local function Wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

function SubSpec_Delay()
	debugprofilestart()
	while debugprofilestop() < 250 do
	end
end

local _placeActionDelayedProfileIndex = 0
function SubSpec_PlaceActionsDelayed()
	local barData = mainFrame.profiles[_placeActionDelayedProfileIndex].data["bar"]
	if not barData then return; end
	for talentId, actionData in pairs(barData) do
		local slots = {}
		for i, slotId in ipairs(actionData["slots"]) do
			local actionType, spellId = GetActionInfo(slotId)
			if not actionType or actionType ~= "spell" or spellId ~= actionData["spellId"] then
				table.insert(slots, slotId)
			end
		end
		if #slots > 0 then
			for i, slotId in ipairs(slots) do
				PickupTalent(talentId)
				PlaceAction(slotId)
				ClearCursor()
			end
		end
	end
end
function SubSpec_PlaceActions(profileIndex)
	_placeActionDelayedProfileIndex = profileIndex
	Wait(0.5, SubSpec_PlaceActionsDelayed)
end

local function CreateNewProfileButton(parent, text, data)
	local ret = CreateFrame("Frame", nil, parent)
	ret.data = data
	ret:Show()

	ret.buttonBackground = CreateFrame("Button", nil, ret, "UIPanelButtonTemplate")
	ret.buttonBackground:Show()
	ret.buttonBackground:SetText(text)
	ret.buttonBackground:SetPoint("TOPLEFT", 5, -2)
	ret.buttonBackground:SetPoint("BOTTOMRIGHT", -20, 2)

	ret.button = CreateFrame("Button", nil, ret.buttonBackground, "SecureActionButtonTemplate")
	ret.button:Show()
	ret.button:SetAllPoints()
	ret.button.background = ret.buttonBackground
	ret.button.profileFrame = ret
	ret.button:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then self.background:SetButtonState("PUSHED", true) end
	end)
	ret.button:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then self.background:SetButtonState("NORMAL", false) end
	end)
	ret.button:SetScript("OnEnter", function(self)
		self.background:LockHighlight()
		mainFrame.menuButton:ShowOn(self.profileFrame)

		local text = ""
		for tier = 1, 7 do
			if self.profileFrame.data[tier]["name"] then
				text = text..self.profileFrame.data[tier]["name"].."\n"
			end
		end
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(text)
		GameTooltip:Show()
	end)
	ret.button:SetScript("OnLeave", function(self)
		self.background:UnlockHighlight()
		GameTooltip:Hide()
	end)

	ret.button:SetAttribute("type", "macro")

	ret.button:SetScript("PreClick", function(self)
		if InCombatLockdown() then return; end
		local talentsToLearn = {}

		local currentData = GetCurrentTalents()
		for tier = 1, GetMaxTalentTier() do
			if self.profileFrame.data and self.profileFrame.data[tier] and self.profileFrame.data[tier]["id"] and self.profileFrame.data[tier]["id"] > 0 then
				local selfId = self.profileFrame.data[tier]["id"]
				local currId = currentData[tier]["id"]
				if currId == 0 then
					talentsToLearn[tier] = self.profileFrame.data[tier]["column"]
				elseif currId ~= selfId then
					talentsToLearn[tier] = self.profileFrame.data[tier]["column"]
				end
			end
		end

		local macrotext = "/stopmacro [combat]\n"
		for row, column in pairs(talentsToLearn) do
			macrotext = macrotext..
				"/click PlayerTalentFrameTalentsTalentRow"..row.."Talent"..column.."\n"..
				"/run SubSpec_Delay()\n"
		end
		self:SetAttribute("macrotext", macrotext..
			"/run SubSpec_PlaceActions("..self.profileFrame.index..")")
	end)

	ret.index = 0
	ret:SetScript("OnEnter", function(self) mainFrame.menuButton:ShowOn(self); end)
	ret.CopyFrom = function(self, frame)
		self.data = frame.data
		self.buttonBackground:SetText( frame.buttonBackground:GetText() )
	end
	return ret
end

local function UpdateScrollWidth()
	mainFrame.profilesFrame:SetWidth(10 + mainFrame.visibleProfiles*150)
end

local function AddProfileButton(text, data)
	if mainFrame.visibleProfiles == #mainFrame.profiles then
		local newButtonFrame = CreateNewProfileButton(mainFrame.profilesFrame, text, data)
		newButtonFrame:SetSize(150, mainFrame.profilesFrame:GetHeight())
		newButtonFrame.index = #mainFrame.profiles + 1
		newButtonFrame:SetPoint("TOPLEFT", #mainFrame.profiles*150, 0)
		table.insert(mainFrame.profiles, newButtonFrame)
		mainFrame.visibleProfiles = mainFrame.visibleProfiles + 1
	else
		mainFrame.visibleProfiles = mainFrame.visibleProfiles + 1
		local frame = mainFrame.profiles[mainFrame.visibleProfiles]
		frame.buttonBackground:SetText(text)
		frame.data = data
		frame:Show()
	end

	UpdateScrollWidth()
	SaveProfiles()
end

local function MenuRename()
	if mainFrame.menuButton.index > 0 then
		StaticPopup_Show("SubSpec_RenameDialog")
		StaticPopup3EditBox:SetMaxLetters(20)
		StaticPopup3EditBox:SetText( mainFrame.profiles[mainFrame.menuButton.index].buttonBackground:GetText() );
		StaticPopup3EditBox:HighlightText()
	end
end
local function MenuRenameApply()
	if mainFrame.menuButton.index > 0 then
		mainFrame.profiles[mainFrame.menuButton.index].buttonBackground:SetText( StaticPopup3EditBox:GetText() )
		SaveProfiles()
	end
end

local function MenuSave()
	if mainFrame.menuButton.index > 0 then
		local profile = mainFrame.profiles[mainFrame.menuButton.index]
		profile.data = GetCurrentTalents()

		local interestSpellIds = {}
		for tier = 1, 7 do
			local talentName = profile.data[tier]["name"]
			local name, rank, icon, castingTime, minRange, maxRange, spellId = GetSpellInfo(talentName)
			if name and spellId then
				interestSpellIds[spellId] = profile.data[tier]["id"]
			end
		end
		local barData = {}
		for slotId = 1, 120 do
			local actionType, spellId = GetActionInfo(slotId)
			if actionType and actionType == "spell" and interestSpellIds[spellId] then
				if not barData[interestSpellIds[spellId]] then barData[interestSpellIds[spellId]] = {["spellId"] = spellId, slots = {}}; end
				table.insert(barData[interestSpellIds[spellId]]["slots"], slotId)
			end
		end
		profile.data["bar"] = barData
		SaveProfiles()
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
	end
end

local function MenuMoveLeft()
	if mainFrame.menuButton.index > 1 then
		local leftFrame = mainFrame.profiles[mainFrame.menuButton.index-1]
		local rightFrame = mainFrame.profiles[mainFrame.menuButton.index]
		local data = leftFrame.data
		local text = leftFrame.buttonBackground:GetText()
		leftFrame:CopyFrom(rightFrame)
		rightFrame.data = data
		rightFrame.buttonBackground:SetText(text)
		SaveProfiles()
		mainFrame.menuButton:Hide()
	end
end

local function MenuMoveRight()
	if mainFrame.menuButton.index > 0 and mainFrame.menuButton.index < mainFrame.visibleProfiles then
		local leftFrame = mainFrame.profiles[mainFrame.menuButton.index]
		local rightFrame = mainFrame.profiles[mainFrame.menuButton.index+1]
		local data = leftFrame.data
		local text = leftFrame.buttonBackground:GetText()
		leftFrame:CopyFrom(rightFrame)
		rightFrame.data = data
		rightFrame.buttonBackground:SetText(text)
		SaveProfiles()
		mainFrame.menuButton:Hide()
	end
end

local function LoadSpecData()
	if not SubSpecStorage then SubSpecStorage = {}; end
	local specId = GetSpecialization()
	if specId then
		mainFrame.createButton:Show()
		local spec = select(2, GetSpecializationInfo(specId))
		if spec and SubSpecStorage[spec] then
			for _, profile in ipairs(SubSpecStorage[spec]) do
				AddProfileButton(profile["name"], profile["data"])
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
		self:SetPoint("TOPLEFT", profileFrame.buttonBackground, "TOPRIGHT", 1, -7)
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

	--data:
	mainFrame.profiles = {}
	mainFrame.visibleProfiles = 0
	LoadSpecData()
end

local startTime = -1
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
local function OnEvent(self, event, ...)
	if event == "PLAYER_LOGIN" then
		startTime = GetTime()
	elseif (event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED") and mainFrame then
		for i = 1, mainFrame.visibleProfiles do
			mainFrame.profiles[i]:Hide()
		end
		mainFrame.visibleProfiles = 0
		LoadSpecData()
	end
end
eventFrame:SetScript("OnEvent", OnEvent)

local function OnUpdate(self, elapsed)
	if startTime >= 0 and GetTime() - startTime > 2 and IsAddOnLoaded("Blizzard_TalentUI") then
		eventFrame:SetScript("OnUpdate", nil)
		startTime = nil
		CreateUi()
	end
end
eventFrame:SetScript("OnUpdate", OnUpdate)
