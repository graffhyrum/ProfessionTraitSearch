local PTS = _G.ProfessionTraitSearch

local ProfessionsNavigator = {}
PTS.ProfessionsNavigator = ProfessionsNavigator

local NAV_STATE = {
	idle = "idle",
	opening = "opening",
	applying = "applying",
}

local navState = NAV_STATE.idle
local pendingNav
local navFrame
local beforeNavigate

local function setNavState(nextState)
	navState = nextState
end

local function getSpecTabID()
	return ProfessionsFrame and ProfessionsFrame.specializationsTabID
end

local function getSpecPage()
	return ProfessionsFrame and ProfessionsFrame.SpecPage
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

	selectSpecTab(specPage, target.tabTreeID)
	if target.pathID then
		selectSpecPath(specPage, target.tabTreeID, target.pathID)
	end
	return true
end

local function resolveViewMode()
	if PTS.Controller and PTS.Controller.GetViewMode then
		return PTS.Controller:GetViewMode()
	end
	return "embedded"
end

local function openProfessionForTarget(target)
	local viewMode = resolveViewMode()
	local openOptions = PTS.ProfessionOpenStrategy and PTS.ProfessionOpenStrategy.Resolve(
		target.skillLineID,
		viewMode,
		PTS.TradeSkillSession
	)
	if not openOptions then
		PTS.TradeSkillSession:OpenForSkillLine(target.skillLineID, {
			forceFull = viewMode == "standalone",
			openSpecTab = true,
		})
		return
	end
	PTS.TradeSkillSession:OpenForSkillLine(target.skillLineID, {
		forceFull = openOptions.forceFull,
		openSpecTab = openOptions.openSpecTab,
	})
end

local function applyPendingNav()
	if navState ~= NAV_STATE.opening and navState ~= NAV_STATE.applying then
		return false
	end

	local target = pendingNav
	if not target or not ProfessionsFrame or not getSpecTabID() then
		return false
	end

	if not PTS.TradeSkillSession:DataReady() then
		return false
	end

	local specPage = getSpecPage()
	if not specPageMatchesTarget(specPage, target) then
		return false
	end

	setNavState(NAV_STATE.applying)
	PTS.TradeSkillSession:EnsureSpecTabSelected()

	if applySpecNavigation(target) then
		pendingNav = nil
		setNavState(NAV_STATE.idle)
		return true
	end

	setNavState(NAV_STATE.opening)
	return false
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

function ProfessionsNavigator:GetNavState()
	return navState
end

function ProfessionsNavigator:GetPendingNav()
	return pendingNav
end

function ProfessionsNavigator:SetBeforeNavigate(fn)
	beforeNavigate = fn
end

function ProfessionsNavigator:SelectSpecPath(specPage, tabTreeID, pathID)
	selectSpecPath(specPage, tabTreeID, pathID)
end

function ProfessionsNavigator:Navigate(row)
	local target = PTS.SpecNavigation and PTS.SpecNavigation.ResolveTarget(row)
	if not target then
		return
	end

	if beforeNavigate then
		beforeNavigate(row, target)
	end

	if C_AddOns and C_AddOns.LoadAddOn and not C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
		C_AddOns.LoadAddOn("Blizzard_Professions")
	end

	if not ProfessionsFrame then
		return
	end

	setNavState(NAV_STATE.opening)
	pendingNav = target
	openProfessionForTarget(target)
	if not applyPendingNav() then
		schedulePendingNav()
	end
end
