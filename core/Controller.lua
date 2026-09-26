local addonName = ...
local PTS = _G.ProfessionTraitSearch or {}
_G.ProfessionTraitSearch = PTS

local Controller = {}
PTS.Controller = Controller
PTS.ADDON_NAME = addonName
PTS.ADDON_ICON = "Interface\\AddOns\\ProfessionTraitSearch\\assets\\pts-icon-512.png"

local session

local function getSession()
	if not session then
		session = PTS.IndexSession:New()
	end
	return session
end

local listening = false
local viewMode = "closed"
local callbacks = {}
local eventFrame

local VIEW_MODES = {
	embedded = true,
	standalone = true,
	closed = true,
}

local INDEX_EVENTS = {
	"TRAIT_CONFIG_UPDATED",
	"TRAIT_NODE_CHANGED",
	"TRAIT_TREE_CURRENCY_INFO_UPDATED",
	"SKILL_LINE_SPECS_RANKS_CHANGED",
	"SKILL_LINES_CHANGED",
	"TRADE_SKILL_LIST_UPDATE",
}

local function charKey()
	return UnitGUID("player") or (UnitName("player") .. "-" .. (GetRealmName() or ""))
end

local function ensureSavedDB()
	if SpecTraitLensDB and not PerkLensDB then
		PerkLensDB = SpecTraitLensDB
	end
	if PerkLensDB and not ProfessionTraitSearchDB then
		ProfessionTraitSearchDB = PerkLensDB
	end
	if SpecTraitLensDB and not ProfessionTraitSearchDB then
		ProfessionTraitSearchDB = SpecTraitLensDB
	end
	ProfessionTraitSearchDB = ProfessionTraitSearchDB or {}
	return ProfessionTraitSearchDB
end

function Controller:GetSavedDB()
	return ensureSavedDB()
end

function Controller:GetCharDB()
	local db = ensureSavedDB()
	db.char = db.char or {}
	local key = charKey()
	local charDB = db.char[key]
	if not charDB then
		charDB = {
			searchText = "",
			majorPerksOnly = false,
			unearnedOnly = false,
			lastSkillLineID = nil,
			foldCollapsedBySkillLine = {},
		}
		db.char[key] = charDB
	elseif charDB.majorPipsOnly ~= nil and charDB.majorPerksOnly == nil then
		charDB.majorPerksOnly = charDB.majorPipsOnly == true
		charDB.majorPipsOnly = nil
	end
	return charDB
end

function Controller.RegisterCallback(fn)
	callbacks[#callbacks + 1] = fn
end

local function fireCallbacks()
	for i = 1, #callbacks do
		callbacks[i]()
	end
end

local function filterOptions()
	local charDB = Controller:GetCharDB()
	return {
		searchText = charDB.searchText or "",
		majorPerksOnly = charDB.majorPerksOnly == true,
		unearnedOnly = charDB.unearnedOnly == true,
	}
end

function Controller:GetFoldCollapsedForSkillLine(skillLineID)
	local charDB = self:GetCharDB()
	charDB.foldCollapsedBySkillLine = charDB.foldCollapsedBySkillLine or {}
	charDB.foldCollapsed = nil

	if not skillLineID then
		return {}
	end

	local scoped = charDB.foldCollapsedBySkillLine[skillLineID]
	if not scoped then
		scoped = {}
		charDB.foldCollapsedBySkillLine[skillLineID] = scoped
	end
	return scoped
end

local function sessionOptions()
	return {
		charDB = Controller:GetCharDB(),
		viewMode = viewMode,
		filterOptions = filterOptions(),
		resolveFoldCollapsed = function(skillLineID)
			return Controller:GetFoldCollapsedForSkillLine(skillLineID)
		end,
	}
end

local function refreshProfessionsFrameForSelection()
	local charDB = Controller:GetCharDB()
	if not charDB.lastSkillLineID then
		return
	end
	PTS.TradeSkillSession:SyncProfessionFrame(charDB.lastSkillLineID, { openSpecTab = false })
end

local function ensureEventFrame()
	if eventFrame then
		return eventFrame
	end
	eventFrame = CreateFrame("Frame")
	eventFrame:SetScript("OnEvent", function(_, event)
		if event == "SKILL_LINES_CHANGED" then
			getSession():Invalidate()
			if listening then
				eventFrame:UnregisterEvent(event)
			end
			Controller:Refresh()
			return
		end
		if event == "TRADE_SKILL_LIST_UPDATE" then
			if not PTS.TradeSkillSession:DataReady() then
				return
			end
			refreshProfessionsFrameForSelection()
			Controller:InvalidateIndex()
			Controller:Refresh()
			return
		end
		Controller:InvalidateIndex()
		Controller:Refresh()
	end)
	return eventFrame
end

function Controller:SetListening(active)
	listening = active == true
	local frame = ensureEventFrame()
	if listening then
		for i = 1, #INDEX_EVENTS do
			frame:RegisterEvent(INDEX_EVENTS[i])
		end
	else
		frame:UnregisterAllEvents()
	end
end

function Controller:SetViewMode(mode)
	if VIEW_MODES[mode] then
		viewMode = mode
	end
end

function Controller:GetViewMode()
	return viewMode
end

function Controller:InvalidateIndex()
	getSession():Invalidate()
end

function Controller:RebuildIndex()
	getSession():Rebuild(sessionOptions())
end

function Controller:Refresh()
	PTS.Debounce.After("index", function()
		getSession():Refresh(sessionOptions())
		fireCallbacks()
	end)
end

function Controller:GetContext()
	getSession():EnsureFresh(sessionOptions())
	return getSession():GetContext()
end

function Controller:GetVisibleRows()
	getSession():EnsureFresh(sessionOptions())
	return getSession():GetVisibleRows()
end

function Controller:GetKnowledgeAvailable()
	local ctx = self:GetContext()
	if not ctx then
		return 0
	end
	return PTS.ProfessionContext.GetKnowledgeAvailable(ctx.skillLineID)
end

function Controller:SetSearchText(text)
	local charDB = self:GetCharDB()
	charDB.searchText = text or ""
	self:Refresh()
end

function Controller:GetSearchText()
	return self:GetCharDB().searchText or ""
end

function Controller:SetMajorPerksOnly(enabled)
	self:GetCharDB().majorPerksOnly = enabled == true
	self:Refresh()
end

function Controller:GetMajorPerksOnly()
	return self:GetCharDB().majorPerksOnly == true
end

function Controller:SetUnearnedOnly(enabled)
	self:GetCharDB().unearnedOnly = enabled == true
	self:Refresh()
end

function Controller:GetUnearnedOnly()
	return self:GetCharDB().unearnedOnly == true
end

function Controller:GetFoldCollapsed()
	local ctx = self:GetContext()
	if not ctx or not ctx.skillLineID then
		return {}
	end
	return self:GetFoldCollapsedForSkillLine(ctx.skillLineID)
end

function Controller:IsFoldCollapsed(rowKey)
	return self:GetFoldCollapsed()[rowKey] == true
end

function Controller:ToggleFold(rowKey)
	if not rowKey then
		return
	end
	local collapsed = self:GetFoldCollapsed()
	if collapsed[rowKey] then
		collapsed[rowKey] = nil
	else
		collapsed[rowKey] = true
	end
	self:Refresh()
end

function Controller:IsFullyExpanded()
	return not next(self:GetFoldCollapsed())
end

function Controller:ExpandAll()
	local collapsed = self:GetFoldCollapsed()
	for key in pairs(collapsed) do
		collapsed[key] = nil
	end
	self:Refresh()
end

function Controller:CollapseAll()
	getSession():EnsureFresh(sessionOptions())
	local collapsed = self:GetFoldCollapsed()
	for k in pairs(collapsed) do
		collapsed[k] = nil
	end
	local allRows = getSession():GetAllRows()
	for i = 1, #allRows do
		local row = allRows[i]
		if row.kind == "tab" or row.kind == "path" then
			collapsed[row.rowKey] = true
		end
	end
	self:Refresh()
end

function Controller:GetFoldToggleLabel()
	if self:IsFullyExpanded() then
		return "Collapse all"
	end
	return "Expand all"
end

function Controller:ToggleFoldAll()
	if self:IsFullyExpanded() then
		self:CollapseAll()
	else
		self:ExpandAll()
	end
end

function Controller:SetSkillLine(skillLineID)
	self:GetCharDB().lastSkillLineID = skillLineID
	PTS.TradeSkillSession:LoadChildSkillLine(skillLineID)
	self:InvalidateIndex()
	if PTS.TradeSkillSession:DataReady() then
		self:Refresh()
	end
end

function Controller:ListProfessions()
	return PTS.ProfessionContext.ListSpecSkillLines()
end

function Controller:ApplyFromSaved()
	getSession():Invalidate()
	self:Refresh()
end

function Controller:GetIndexSession()
	return getSession()
end
