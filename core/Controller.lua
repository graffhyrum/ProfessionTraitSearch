local addonName = ...
local PL = _G.PerkLens or {}
_G.PerkLens = PL

local Controller = {}
PL.Controller = Controller
PL.ADDON_NAME = addonName

local context
local allRows = {}
local visibleRows = {}
local indexDirty = true
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
	PerkLensDB = PerkLensDB or {}
	return PerkLensDB
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

local function refreshProfessionsFrameForSelection()
	local charDB = Controller:GetCharDB()
	if not charDB.lastSkillLineID then
		return
	end
	PL.TradeSkillSession:SyncProfessionFrame(charDB.lastSkillLineID, { openSpecTab = false })
end

local function ensureEventFrame()
	if eventFrame then
		return eventFrame
	end
	eventFrame = CreateFrame("Frame")
	eventFrame:SetScript("OnEvent", function(_, event)
		if event == "SKILL_LINES_CHANGED" then
			indexDirty = true
			if listening then
				eventFrame:UnregisterEvent(event)
			end
			Controller:Refresh()
			return
		end
		if event == "TRADE_SKILL_LIST_UPDATE" then
			if not PL.TradeSkillSession:DataReady() then
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
	indexDirty = true
end

function Controller:RebuildIndex()
	local charDB = self:GetCharDB()
	-- Embedded index mode prefers active profession context (ProfessionsFrame in-game).
	local preferActive = viewMode == "embedded"
	local requestedSkillLineID = charDB.lastSkillLineID
	context = PL.ProfessionContext.ResolveForIndex(charDB, preferActive)
	if context then
		charDB.lastSkillLineID = context.skillLineID
	elseif requestedSkillLineID and viewMode == "standalone" then
		charDB.lastSkillLineID = requestedSkillLineID
	end
	allRows = context and PL.SpecIndex.Build(context) or {}
	visibleRows = PL.SpecSearch.Filter(allRows, filterOptions())
	indexDirty = false
end

function Controller:Refresh()
	PL.Debounce.After("index", function()
		if indexDirty then
			Controller:RebuildIndex()
		else
			visibleRows = PL.SpecSearch.Filter(allRows, filterOptions())
		end
		fireCallbacks()
	end)
end

function Controller:GetContext()
	if indexDirty then
		self:RebuildIndex()
	end
	return context
end

function Controller:GetVisibleRows()
	if indexDirty then
		self:RebuildIndex()
	end
	return visibleRows
end

function Controller:GetKnowledgeAvailable()
	local ctx = self:GetContext()
	if not ctx then
		return 0
	end
	return PL.ProfessionContext.GetKnowledgeAvailable(ctx.skillLineID)
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

function Controller:SetSkillLine(skillLineID)
	self:GetCharDB().lastSkillLineID = skillLineID
	PL.TradeSkillSession:LoadChildSkillLine(skillLineID)
	self:InvalidateIndex()
	if PL.TradeSkillSession:DataReady() then
		self:Refresh()
	end
end

function Controller:ListProfessions()
	return PL.ProfessionContext.ListSpecSkillLines()
end

function Controller:ApplyFromSaved()
	indexDirty = true
	self:Refresh()
end
