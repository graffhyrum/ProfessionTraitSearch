local PTS = _G.ProfessionTraitSearch

local ProfessionsHook = {}
PTS.ProfessionsHook = ProfessionsHook

local hooked = {}
local indexMode = false
local recipesTabID
local specTabID
local craftingOrdersTabID
local indexTab
local updateIndexTab

local TAB_ICON = PTS.ADDON_ICON
local TAB_ANCHOR_X = 0
local TAB_ANCHOR_Y = -128

local function isHostTab(tabID)
	return tabID == recipesTabID or tabID == specTabID or tabID == craftingOrdersTabID
end

local function isSpecTab(tabID)
	return tabID and tabID == specTabID
end

local function isHostTabActive()
	if not ProfessionsFrame or not ProfessionsFrame.GetTab then
		return false
	end
	return isHostTab(ProfessionsFrame:GetTab())
end

local function layoutIndexTab()
	if not indexTab or not ProfessionsFrame then
		return
	end
	local anchorFrame = ProfessionsFrame
	if indexMode then
		local popout = PTS.SpecBrowser.popout
		if popout and popout:IsShown() then
			anchorFrame = popout
		end
	end
	indexTab:ClearAllPoints()
	indexTab:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", TAB_ANCHOR_X, TAB_ANCHOR_Y)
end

updateIndexTab = function()
	if not indexTab then
		return
	end
	local show = ProfessionsFrame and ProfessionsFrame:IsShown() and isHostTabActive()
	indexTab:SetShown(show)
	layoutIndexTab()
	if indexTab.SetChecked then
		indexTab:SetChecked(indexMode)
	elseif indexTab.SelectedTexture then
		indexTab.SelectedTexture:SetShown(indexMode)
	end
end

local function refreshPopout()
	local popout = PTS.SpecBrowser.popout
	if not popout or not popout:IsShown() then
		return
	end
	PTS.Controller:InvalidateIndex()
	PTS.Controller:Refresh()
	PTS.SpecBrowser:Update(popout)
end

local function syncViewMode()
	if indexMode then
		PTS.Controller:SetViewMode("embedded")
	elseif PTS.SpecBrowser.standalone and PTS.SpecBrowser.standalone:IsShown() then
		PTS.Controller:SetViewMode("standalone")
	else
		PTS.Controller:SetViewMode("closed")
	end
end

local function syncListening()
	local listen = ProfessionsFrame and ProfessionsFrame:IsShown()
	if not listen then
		local standalone = PTS.SpecBrowser.standalone
		if standalone and standalone:IsShown() then
			listen = true
		end
	end
	if not listen then
		local popout = PTS.SpecBrowser.popout
		if popout and popout:IsShown() then
			listen = true
		end
	end
	PTS.Controller:SetListening(listen)
end

local function syncLifecycle()
	syncViewMode()
	syncListening()
end

local function applyIndexMode(enabled)
	indexMode = enabled == true
	if indexMode and not isHostTabActive() then
		indexMode = false
	end

	syncViewMode()

	if indexMode then
		local active = PTS.ProfessionContext.GetActiveContext()
		if active then
			PTS.Controller:SetSkillLine(active.skillLineID)
		else
			PTS.Controller:InvalidateIndex()
			PTS.Controller:Refresh()
		end
	end

	PTS.SpecBrowser:SetPopoutVisible(indexMode)
	syncListening()
	updateIndexTab()
end

local function onTabSet(_, frame, tabID)
	if frame ~= ProfessionsFrame then
		return
	end

	if not isHostTab(tabID) then
		if indexMode then
			applyIndexMode(false)
		else
			updateIndexTab()
		end
		return
	end

	updateIndexTab()
	if indexMode then
		refreshPopout()
	elseif isSpecTab(tabID) then
		PTS.Controller:InvalidateIndex()
		PTS.Controller:Refresh()
	end
end

local function onProfessionsOpen()
	syncListening()
	updateIndexTab()
end

local function onProfessionsClose()
	applyIndexMode(false)
	updateIndexTab()
end

local function createIndexSideTab(professionsFrame)
	if indexTab then
		return indexTab
	end
	local tab = CreateFrame("Frame", nil, professionsFrame, "LargeSideTabButtonTemplate")
	tab:SetFrameStrata("HIGH")
	tab:SetFrameLevel(20)
	tab.tooltipText = "Specialization Index"
	tab.Icon:SetTexture(TAB_ICON)
	tab.Icon:SetSize(24, 24)
	tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
		if button == "LeftButton" and upInside then
			applyIndexMode(not indexMode)
		end
	end)
	indexTab = tab
	return tab
end

local function setupProfessionsFrame(frame)
	if hooked[frame] then
		return
	end
	hooked[frame] = true

	frame:HookScript("OnShow", onProfessionsOpen)
	frame:HookScript("OnHide", onProfessionsClose)

	if EventRegistry and EventRegistry.RegisterCallback then
		EventRegistry:RegisterCallback("ProfessionsFrame.TabSet", onTabSet, frame)
	end

	createIndexSideTab(frame)
	PTS.SpecBrowser:CreatePopout(frame)
	updateIndexTab()

	if frame.recipesTabID then
		recipesTabID = frame.recipesTabID
	end
	if frame.specializationsTabID then
		specTabID = frame.specializationsTabID
	end
	if frame.craftingOrdersTabID then
		craftingOrdersTabID = frame.craftingOrdersTabID
	end
end

function ProfessionsHook:Init()
	PTS.ProfessionsNavigator:SetBeforeNavigate(function()
		if indexMode then
			applyIndexMode(false)
		end
	end)

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(_, event, name)
		if event ~= "ADDON_LOADED" or name ~= "Blizzard_Professions" then
			return
		end
		if ProfessionsFrame then
			setupProfessionsFrame(ProfessionsFrame)
		end
	end)

	if C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_Professions") and ProfessionsFrame then
		setupProfessionsFrame(ProfessionsFrame)
	end
end

function ProfessionsHook:IsIndexMode()
	return indexMode
end

function ProfessionsHook:NotifyBrowserShown()
	syncLifecycle()
end

function ProfessionsHook:NotifyBrowserHidden()
	syncLifecycle()
end
