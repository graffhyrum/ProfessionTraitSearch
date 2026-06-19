local PL = _G.PerkLens

local ProfessionsHook = {}
PL.ProfessionsHook = ProfessionsHook

local hooked = {}
local indexMode = false
local specTabID
local indexTab
local pendingNav
local navFrame

local TAB_ICON = "Interface\\Icons\\INV_Misc_Book_09"
local TAB_ANCHOR_X = 0
local TAB_ANCHOR_Y = -128

local SPEC_CORE_KEYS = {
	"TreeView",
	"DetailedView",
	"ButtonsParent",
	"VerticalDivider",
	"TopDivider",
	"PanelFooter",
	"ApplyButton",
	"UnlockTabButton",
	"UndoButton",
	"FxModelScene",
}

local SPEC_STATEFUL_KEYS = {
	"TreePreview",
	"ViewTreeButton",
	"BackToPreviewButton",
	"ViewPreviewButton",
	"BackToFullTreeButton",
}

local function isSpecTabActive()
	if not ProfessionsFrame or not specTabID then
		return false
	end
	return ProfessionsFrame.GetTab and ProfessionsFrame:GetTab() == specTabID
end

local function getSpecPage()
	return ProfessionsFrame and ProfessionsFrame.SpecPage
end

local function setFrameShown(frame, visible)
	if frame then
		frame:SetShown(visible)
	end
end

local function forEachPoolEntry(pool, fn)
	if not pool or not pool.EnumerateActive then
		return
	end
	for entry in pool:EnumerateActive() do
		fn(entry)
	end
end

local function setBlizzardSpecChromeVisible(visible)
	local specPage = getSpecPage()
	if not specPage then
		return
	end

	if visible then
		for i = 1, #SPEC_CORE_KEYS do
			setFrameShown(specPage[SPEC_CORE_KEYS[i]], true)
		end
		for i = 1, #SPEC_STATEFUL_KEYS do
			setFrameShown(specPage[SPEC_STATEFUL_KEYS[i]], false)
		end
	else
		for i = 1, #SPEC_CORE_KEYS do
			setFrameShown(specPage[SPEC_CORE_KEYS[i]], false)
		end
		for i = 1, #SPEC_STATEFUL_KEYS do
			setFrameShown(specPage[SPEC_STATEFUL_KEYS[i]], false)
		end
	end

	forEachPoolEntry(specPage.tabsPool, function(tab)
		tab:SetShown(visible)
	end)
	forEachPoolEntry(specPage.perksPool, function(perk)
		perk:SetShown(visible)
	end)
end

local function selectSpecTab(specPage, tabTreeID)
	if EventRegistry and EventRegistry.TriggerEvent then
		EventRegistry:TriggerEvent("ProfessionsSpecializations.TabSelected", tabTreeID)
	elseif specPage.SetSelectedTab then
		specPage:SetSelectedTab(tabTreeID)
	end
end

local function selectSpecPath(specPage, tabTreeID, pathID)
	if specPage.SetDefaultPath then
		specPage:SetDefaultPath(pathID)
	end
	if specPage.SetDefaultTab then
		specPage:SetDefaultTab(tabTreeID)
	end
	if EventRegistry and EventRegistry.TriggerEvent then
		EventRegistry:TriggerEvent("ProfessionsSpecializations.PathSelected", pathID, true)
	elseif specPage.SetDetailedPanel then
		specPage:SetDetailedPanel(pathID)
	end
end

local function restoreBlizzardSpecToCurrentTab()
	local specPage = getSpecPage()
	if not specPage then
		return
	end

	setBlizzardSpecChromeVisible(true)

	local treeID = specPage.GetTalentTreeID and specPage:GetTalentTreeID()
	if treeID then
		selectSpecTab(specPage, treeID)
		return
	end

	if specPage.UpdateSelectedTabState then
		specPage:UpdateSelectedTabState()
	end
end

local function restoreBlizzardSpecUI()
	restoreBlizzardSpecToCurrentTab()
end

local function exitIndexOverlay()
	indexMode = false
	PL.SpecBrowser:SetEmbeddedVisible(false)
	updateIndexTab()
end

local function updateIndexTab()
	if not indexTab then
		return
	end
	local show = ProfessionsFrame and ProfessionsFrame:IsShown() and isSpecTabActive()
	indexTab:SetShown(show)
	if indexTab.SelectedTexture then
		indexTab.SelectedTexture:SetShown(indexMode)
	end
end

local function specPageMatchesTarget(specPage, target)
	if not specPage or not specPage.GetProfessionID or not target then
		return false
	end
	return specPage:GetProfessionID() == target.skillLineID
end

local function applySpecNavigation(target)
	local specPage = getSpecPage()
	if not specPageMatchesTarget(specPage, target) then
		return false
	end

	setBlizzardSpecChromeVisible(true)
	selectSpecTab(specPage, target.tabTreeID)
	if target.pathID then
		selectSpecPath(specPage, target.tabTreeID, target.pathID)
	end
	return true
end

local function applyPendingNav()
	local target = pendingNav
	if not target or not ProfessionsFrame or not specTabID then
		return false
	end

	if applySpecNavigation(target) then
		pendingNav = nil
		return true
	end
	return false
end

local function ensureSpecTabSelected()
	if ProfessionsFrame and ProfessionsFrame.SetTab and specTabID then
		ProfessionsFrame:SetTab(specTabID, true)
	end
end

local function ensureNavFrame()
	if navFrame then
		return navFrame
	end
	navFrame = CreateFrame("Frame")
	navFrame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	navFrame:SetScript("OnEvent", function()
		applyPendingNav()
	end)
	return navFrame
end

local function schedulePendingNav()
	ensureNavFrame()
	RunNextFrame(function()
		if applyPendingNav() then
			return
		end
		RunNextFrame(applyPendingNav)
	end)
end

function ProfessionsHook:NavigateToRow(row)
	local target = PL.SpecNavigation and PL.SpecNavigation.ResolveTarget(row)
	if not target then
		return
	end

	if indexMode then
		exitIndexOverlay()
	end

	if C_AddOns and C_AddOns.LoadAddOn and not C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
		C_AddOns.LoadAddOn("Blizzard_Professions")
	end

	if not ProfessionsFrame then
		return
	end

	pendingNav = target
	ensureSpecTabSelected()

	local specPage = getSpecPage()
	local needsProfessionSwitch = not specPageMatchesTarget(specPage, target)

	if not ProfessionsFrame:IsShown() or needsProfessionSwitch then
		if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
			C_TradeSkillUI.OpenTradeSkill(target.skillLineID)
		end
		if not ProfessionsFrame:IsShown() and ShowUIPanel then
			ShowUIPanel(ProfessionsFrame)
		end
		ensureSpecTabSelected()
	end

	schedulePendingNav()
end

local function applyIndexMode(enabled)
	local wasIndexMode = indexMode
	indexMode = enabled == true
	if not isSpecTabActive() then
		indexMode = false
	end

	if indexMode then
		setBlizzardSpecChromeVisible(false)
		local active = PL.ProfessionContext.GetActiveContext()
		if active then
			PL.Controller:SetSkillLine(active.skillLineID)
		else
			PL.Controller:InvalidateIndex()
			PL.Controller:Refresh()
		end
	else
		if wasIndexMode then
			restoreBlizzardSpecUI()
		else
			setBlizzardSpecChromeVisible(true)
		end
	end

	PL.SpecBrowser:SetEmbeddedVisible(indexMode)
	updateIndexTab()
end

local function onTabSet(_, frame, tabID)
	if frame ~= ProfessionsFrame then
		return
	end
	if tabID ~= specTabID then
		if indexMode then
			applyIndexMode(false)
		else
			updateIndexTab()
		end
		return
	end
	updateIndexTab()
	PL.Controller:InvalidateIndex()
	PL.Controller:Refresh()
	if PL.SpecBrowser.embedded and PL.SpecBrowser.embedded:IsShown() then
		PL.SpecBrowser:Update(PL.SpecBrowser.embedded)
	end
end

local function onProfessionsOpen()
	PL.Controller:SetListening(true)
	updateIndexTab()
end

local function onProfessionsClose()
	applyIndexMode(false)
	updateIndexTab()
	if not (PL.SpecBrowser.standalone and PL.SpecBrowser.standalone:IsShown()) then
		PL.Controller:SetListening(false)
	end
end

local function createIndexSideTab(professionsFrame)
	if indexTab then
		return indexTab
	end
	local tab = CreateFrame("Frame", nil, professionsFrame, "LargeSideTabButtonTemplate")
	tab:SetFrameStrata("HIGH")
	tab:SetPoint("TOPLEFT", professionsFrame, "TOPRIGHT", TAB_ANCHOR_X, TAB_ANCHOR_Y)
	tab.tooltipText = "Specialization Index"
	tab.Icon:SetTexture(TAB_ICON)
	tab.Icon:SetSize(24, 24)
	tab.SelectedTexture:SetShown(false)
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
	updateIndexTab()
	if frame.SpecPage then
		PL.SpecBrowser:CreateEmbedded(frame.SpecPage)
	end

	if frame.specializationsTabID then
		specTabID = frame.specializationsTabID
	end
end

function ProfessionsHook:Init()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(_, event, name)
		if event ~= "ADDON_LOADED" or name ~= "Blizzard_Professions" then
			return
		end
		if ProfessionsFrame then
			setupProfessionsFrame(ProfessionsFrame)
			if ProfessionsFrame.specializationsTabID then
				specTabID = ProfessionsFrame.specializationsTabID
			end
		end
	end)

	if C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_Professions") and ProfessionsFrame then
		setupProfessionsFrame(ProfessionsFrame)
		if ProfessionsFrame.specializationsTabID then
			specTabID = ProfessionsFrame.specializationsTabID
		end
	end
end

function ProfessionsHook:IsIndexMode()
	return indexMode
end
