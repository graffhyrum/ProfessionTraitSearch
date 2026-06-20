local PL = _G.PerkLens

local TradeSkillSession = {}
PL.TradeSkillSession = TradeSkillSession

local function getChildSkillLineID()
	local child = C_TradeSkillUI and C_TradeSkillUI.GetChildProfessionInfo and C_TradeSkillUI.GetChildProfessionInfo()
	return child and child.professionID
end

local function getParentProfessionID(skillLineID)
	local info = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID and C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
	return info and info.parentProfessionID
end

local function syncProfessionsFrameFilterCache()
	if not ProfessionsFrame or not Professions or not Professions.GetCurrentFilterSet then
		return
	end
	local filterSet = Professions.GetCurrentFilterSet()
	if ProfessionsFrame.recipesFilters ~= nil then
		ProfessionsFrame.recipesFilters = filterSet
	end
	local ordersFilters = ProfessionsFrame.craftingOrdersFilters
	if ordersFilters and ordersFilters.professionInfo then
		ordersFilters.professionInfo = filterSet.professionInfo
	end
end

local function showProfessionsFrame()
	if ProfessionsFrame and not ProfessionsFrame:IsShown() and ShowUIPanel then
		ShowUIPanel(ProfessionsFrame)
	end
end

local function ensureSpecTabSelected()
	local specTabID = ProfessionsFrame and ProfessionsFrame.specializationsTabID
	if ProfessionsFrame and ProfessionsFrame.SetTab and specTabID then
		ProfessionsFrame:SetTab(specTabID, true)
	end
end

local function showProfessionsOnSpecTab()
	showProfessionsFrame()
	ensureSpecTabSelected()
end

local function getChildProfessionInfo()
	if not C_TradeSkillUI or not C_TradeSkillUI.GetChildProfessionInfo then
		return nil
	end
	return C_TradeSkillUI.GetChildProfessionInfo()
end

local function triggerProfessionSelected(child, openSpecTab)
	if not child or not EventRegistry or not EventRegistry.TriggerEvent then
		return
	end
	if openSpecTab ~= nil then
		child.openSpecTab = openSpecTab
	end
	EventRegistry:TriggerEvent("Professions.ProfessionSelected", child)
end

local function openDifferentProfession(skillLineID, openSpecTab)
	if ProfessionsFrame and ProfessionsFrame.SetOpenRecipeResponse then
		ProfessionsFrame:SetOpenRecipeResponse(skillLineID, nil, openSpecTab)
	end
	local openID = getParentProfessionID(skillLineID) or skillLineID
	if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
		C_TradeSkillUI.OpenTradeSkill(openID)
	end
end

function TradeSkillSession:DataReady()
	if C_TradeSkillUI and C_TradeSkillUI.IsDataSourceChanging then
		return not C_TradeSkillUI.IsDataSourceChanging()
	end
	return true
end

function TradeSkillSession:GetChildSkillLineID()
	return getChildSkillLineID()
end

function TradeSkillSession:IsOnTargetParentProfession(skillLineID)
	local info = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
	local parentID = info and info.parentProfessionID
	if not parentID then
		return false
	end
	local base = C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
	return base and base.professionID == parentID
end

function TradeSkillSession:EnsureSpecTabSelected()
	ensureSpecTabSelected()
end

function TradeSkillSession:LoadChildSkillLine(skillLineID, options)
	options = options or {}
	if not skillLineID or getChildSkillLineID() == skillLineID then
		return false
	end
	if not C_TradeSkillUI or not C_TradeSkillUI.SetProfessionChildSkillLineID then
		return false
	end
	if not self:IsOnTargetParentProfession(skillLineID) then
		return false
	end
	C_TradeSkillUI.SetProfessionChildSkillLineID(skillLineID)
	if options.fireProfessionSelected ~= false then
		triggerProfessionSelected(getChildProfessionInfo())
	end
	return true
end

function TradeSkillSession:SyncProfessionFrame(skillLineID, options)
	options = options or {}
	local openSpecTab = options.openSpecTab == true
	if not skillLineID or not self:DataReady() then
		return false
	end
	if not ProfessionsFrame or not ProfessionsFrame.SetProfessionInfo then
		return false
	end
	if not Professions or not Professions.GetProfessionInfo then
		return false
	end
	if C_TradeSkillUI and C_TradeSkillUI.SetProfessionChildSkillLineID and self:IsOnTargetParentProfession(skillLineID) then
		C_TradeSkillUI.SetProfessionChildSkillLineID(skillLineID)
	end
	local professionInfo = Professions.GetProfessionInfo()
	if not professionInfo or professionInfo.professionID == 0 or professionInfo.professionID ~= skillLineID then
		return false
	end
	professionInfo.openRecipeID = nil
	professionInfo.openSpecTab = openSpecTab
	ProfessionsFrame:SetProfessionInfo(professionInfo, false)
	syncProfessionsFrameFilterCache()
	return true
end

function TradeSkillSession:OpenForSkillLine(skillLineID, options)
	options = options or {}
	local forceFull = options.forceFull == true
	local openSpecTab = options.openSpecTab == true

	if not forceFull and self:GetChildSkillLineID() == skillLineID then
		showProfessionsFrame()
		return
	end

	if not forceFull and self:IsOnTargetParentProfession(skillLineID) then
		self:LoadChildSkillLine(skillLineID, { fireProfessionSelected = false })
		triggerProfessionSelected(getChildProfessionInfo(), openSpecTab)
		showProfessionsFrame()
		return
	end

	if forceFull and self:IsOnTargetParentProfession(skillLineID) then
		if self:SyncProfessionFrame(skillLineID, { openSpecTab = openSpecTab }) then
			showProfessionsOnSpecTab()
			return
		end
		openDifferentProfession(skillLineID, openSpecTab)
		showProfessionsFrame()
		return
	end

	openDifferentProfession(skillLineID, openSpecTab)
end
