local L = SubSpecGlobal.L

LoadAddOn('Blizzard_TalentUI')
local mainFrame = CreateFrame("Frame", "SubSpec_MainFrame", PlayerTalentFrame)
mainFrame:Hide()
SubSpecGlobal._mainFrame = mainFrame

local eventFrame = CreateFrame("Frame", "SubSpec_EventFrame", UIParent)
eventFrame:Show()

function GetCurrentTalents()
	local ret = {}
	ret["specGroup"] = GetActiveSpecGroup()
	ret["talents"] = {}
	for tier = 1, 7 do
		ret["talents"][tier] = {}
		for column = 1, 3 do
			local id, name, texture, selected, available = GetTalentInfo(tier, column, ret["specGroup"])
			ret["talents"][tier][column] = {["id"] = id, ["name"] = name, ["texture"] = texture, ["selected"] = selected, ["available"] = available}
		end
	end
	return ret
end

-- btn:SetAttribute("macrotext",
-- 				"/stopmacro [combat]\n"..
-- 				"/click QuickTalentsOpener\n".. -- ensures the talent frame is ready for interaction
-- 				"/click PlayerTalentFrameTalentsTalentRow"..ceil(i/3).."Talent"..((i-1)%3+1).."\n".. -- only way(?) to get the unlearn popup without taint
-- 				"/click StaticPopup1Button1\n".. -- confirm unlearn (TODO: what if popup1 is not the talent prompt)
-- 				"/run QuickTalents:Learn("..i..")\n" -- queue new talents for learn
-- 			);

-- profileButton:SetScript("OnClick", function() ToggleDropDownMenu(1, nil, PC._settings.profileMenuFrame, PC._settings.profileMenuFrame, 0, 0, PC._settings.profileMenu, nil, nil); end)
-- self.profileMenuFrame = CreateFrame("Frame", "PartyMarkers_ProfileMenu", self.frame, "UIDropDownMenuTemplate")
-- UIDropDownMenu_Initialize(PC._settings.profileMenuFrame, EasyMenu_Initialize, "MENU", nil, PC._settings.profileMenu)



CreateFrame("BUTTON", "SubSpecTalentsOpener", self, "SecureActionButtonTemplate"):SetAttribute("type", "macro")
SubSpecTalentsOpener:SetAttribute("macrotext",
	"/click TalentMicroButton\n"..
	"/click [spec:1] PlayerSpecTab1\n"..
	"/click [spec:2] PlayerSpecTab2\n"..
	"/click PlayerTalentFrameTab3\n"..
	"/click PlayerTalentFrameTab2\n"..
	"/click TalentMicroButton"
)
SubSpecTalentsOpener:Hide()

local function CreateProfileButton(parent, name, data)
	local ret = CreateFrame("Frame", nil, parent)
	ret.data = data
	ret:Show()

	ret.buttonBackground = CreateFrame("Button", nil, ret, "UIPanelButtonTemplate")
	ret.buttonBackground:Show()
	ret.buttonBackground:SetText(name)
	ret.buttonBackground:SetPoint("TOPLEFT", 5, -2)
	ret.buttonBackground:SetPoint("BOTTOMRIGHT", -20, 2)

	ret.button = CreateFrame("Button", nil, ret.buttonBackground, "SecureActionButtonTemplate")
	ret.button:Show()
	ret.button:SetAllPoints()
	ret.button.background = ret.buttonBackground
	ret.button:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then self.background:SetButtonState("PUSHED", true) end
	end)
	ret.button:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then self.background:SetButtonState("NORMAL", false) end
	end)
	ret.button:SetScript("OnEnter", function(self) self.background:LockHighlight() end)
	ret.button:SetScript("OnLeave", function(self) self.background:UnlockHighlight() end)

	ret.button:SetAttribute("type", "macro")
	ret.button:SetAttribute("macrotext", "/click SpellbookMicroButton")

	ret.menu = CreateFrame("Button", nil, ret)
	ret.menu:Show()
	ret.menu:SetPoint("TOPLEFT", ret.buttonBackground, "TOPRIGHT", 1, -7)
	ret.menu:SetSize(15, 15)
	ret.menu:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
	ret.menu:SetPushedTexture("Interface\\Buttons\\Arrow-Down-Down")

	ret.index = 0
	ret.UpdatePos = function(self) self:SetPoint("TOPLEFT", (self.index - 1)*150, 0); end
	return ret
end

local function UpdateScrollWidth()
	mainFrame.profilesFrame:SetWidth(10 + #mainFrame.profiles*150)
end

local function CreateProfile()
	local newButtonFrame = CreateProfileButton(mainFrame.profilesFrame, L["new"], {})
	newButtonFrame:SetSize(150, mainFrame.profilesFrame:GetHeight())
	newButtonFrame.index = #mainFrame.profiles + 1
	newButtonFrame:UpdatePos()
	table.insert(mainFrame.profiles, newButtonFrame)
	UpdateScrollWidth()
end

local function CreateUi()
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
	mainFrame.createButton:SetScript("OnClick", CreateProfile)

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
	scrollContainer:SetPoint("TOPLEFT")
	scrollContainer:SetWidth(scroll:GetWidth())
	scrollContainer:SetHeight(scroll:GetHeight())
	scrollContainer:Show()
	scroll:SetScrollChild(scrollContainer)
	mainFrame.scrollContainer = scrollContainer

	mainFrame.profilesFrame = CreateFrame("Frame", nil, scrollContainer)
	mainFrame.profilesFrame:SetPoint("TOPLEFT")
	mainFrame.profilesFrame:SetSize(10, scrollContainer:GetHeight())

	mainFrame.profiles = {}
	if not SubSpecStorage then SubSpecStorage = {}; end
	
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
		CreateUi()
		eventFrame:SetScript("OnUpdate", nil)
		startTime = nil
	end
end
eventFrame:SetScript("OnUpdate", OnUpdate)
