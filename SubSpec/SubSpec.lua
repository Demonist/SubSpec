local L = SubSpecGlobal.L

LoadAddOn('Blizzard_TalentUI')
local mainFrame = CreateFrame("Frame", "SubSpec_MainFrame", PlayerTalentFrame)
mainFrame:Hide()
SubSpecGlobal._mainFrame = mainFrame

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
				break
			end
		end
	end
	return ret
end

local function SaveProfiles()
	local class = UnitClass("player")
	if not SubSpecStorage then SubSpecStorage = {}; end
	SubSpecStorage[class] = {}
	for i = 1, mainFrame.visibleProfiles do
		table.insert(SubSpecStorage[class], {name = mainFrame.profiles[i].buttonBackground:GetText(), data = mainFrame.profiles[i].data})
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
SubSpec_TalentsToLearn = {}
function SubSpec_LearnTalentsDelayed()
	for tier, id in pairs(SubSpec_TalentsToLearn) do
		local currTalents = GetCurrentTalents()
		if currTalents[tier]["id"] ~= id then
			LearnTalents(id)
			SubSpec_TalentsToLearn[tier] = nil
			Wait(0.15, SubSpec_LearnTalentsDelayed)
		end
		break
	end
end
function SubSpec_LearnTalents()
	Wait(0.25, SubSpec_LearnTalentsDelayed)
end

function SubSpec_LearnDelayed(id)
	debugprofilestart()
	while debugprofilestop() < 250 do
	end
	LearnTalents(id)
end

local function CreateNewProfileButton(parent, text, data)
	local ret = CreateFrame("Frame", nil, parent)
	ret.data = data
	ret:Show()
	ret:SetFrameLevel(13)

	ret.buttonBackground = CreateFrame("Button", nil, ret, "UIPanelButtonTemplate")
	ret.buttonBackground:Show()
	ret.buttonBackground:SetFrameLevel(14)
	ret.buttonBackground:SetText(text)
	ret.buttonBackground:SetPoint("TOPLEFT", 5, -2)
	ret.buttonBackground:SetPoint("BOTTOMRIGHT", -20, 2)

	ret.button = CreateFrame("Button", nil, ret.buttonBackground, "SecureActionButtonTemplate")
	ret.button:Show()
	ret.button:SetFrameLevel(50)
	ret.button:SetAllPoints()
	ret.button.background = ret.buttonBackground
	ret.button.profileFrame = ret
	ret.button:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then self.background:SetButtonState("PUSHED", true) end
	end)
	ret.button:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then self.background:SetButtonState("NORMAL", false) end
	end)
	ret.button:SetScript("OnEnter", function(self) self.background:LockHighlight(); mainFrame.menuButton:ShowOn(self.profileFrame); end)
	ret.button:SetScript("OnLeave", function(self) self.background:UnlockHighlight(); end)

	ret.button:SetAttribute("type", "macro")

	ret.button:SetScript("PreClick", function(self)
		if InCombatLockdown() then return; end
		local talentsToRemove = {}
		SubSpec_TalentsToLearn = {}
		local currentData = GetCurrentTalents()
		for tier = 1, 7 do
			if self.profileFrame.data and self.profileFrame.data[tier] and self.profileFrame.data[tier]["id"] and self.profileFrame.data[tier]["id"] > 0 then
				local selfId = self.profileFrame.data[tier]["id"]
				local currId = currentData[tier]["id"]
				if currId == 0 then
					SubSpec_TalentsToLearn[tier] = selfId
				elseif currId ~= selfId then
					talentsToRemove[tier] = self.profileFrame.data[tier]["column"]
					SubSpec_TalentsToLearn[tier] = selfId
				end
			end
		end

		local macrotext = "/stopmacro [combat]\n"
		for row, column in pairs(talentsToRemove) do
			macrotext = macrotext..
				"/click PlayerTalentFrameTalentsTalentRow"..row.."Talent"..column.."\n"..
				"/click StaticPopup1Button1\n"..
				"/run SubSpec_LearnDelayed("..SubSpec_TalentsToLearn[row]..")\n"
		end
		self:SetAttribute("macrotext", macrotext.."/run SubSpec_LearnTalents()")
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
		mainFrame.profiles[mainFrame.menuButton.index].data = GetCurrentTalents()
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

local function CreateUi()
	local elvUi = IsAddOnLoaded("ElvUI")
	
	mainFrame:SetFrameLevel(10)
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
	mainFrame.createButton:SetFrameLevel(11)

	--scroll:
	local scroll = CreateFrame("ScrollFrame", "SubSpec_Scroll", mainFrame)
	scroll:Show()
	scroll:SetFrameLevel(11)
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
	scrollContainer:SetFrameLevel(12)
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
	menuButton:SetFrameLevel(50)
	menuButton:SetSize(15, 15)
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
	mainFrame.menuFrame:SetFrameLevel(16)
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
	if not SubSpecStorage then SubSpecStorage = {}; end
	local class = UnitClass("player")
	if SubSpecStorage[class] then
		for _, profile in ipairs(SubSpecStorage[class]) do
			AddProfileButton(profile["name"], profile["data"])
		end
	end
end

local startTime = -1
eventFrame:RegisterEvent("PLAYER_LOGIN")
local function OnEvent(self, event, ...)
	if event == "PLAYER_LOGIN" then
		startTime = GetTime()
	end
end
eventFrame:SetScript("OnEvent", OnEvent)

local function OnUpdate(self, elapsed)
	if startTime >= 0 and GetTime() - startTime > 2 then
		eventFrame:SetScript("OnUpdate", nil)
		startTime = nil
		CreateUi()
	end
end
eventFrame:SetScript("OnUpdate", OnUpdate)
