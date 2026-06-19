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
local callbacks = {}
local eventFrame

local TRAIT_EVENTS = {
	"TRAIT_CONFIG_UPDATED",
	"TRAIT_NODE_CHANGED",
	"TRAIT_TREE_CURRENCY_INFO_UPDATED",
	"SKILL_LINE_SPECS_RANKS_CHANGED",
	"SKILL_LINES_CHANGED",
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

function Controller:GetCharDB()
	local db = ensureSavedDB()
	db.char = db.char or {}
	db.char[charKey()] = db.char[charKey()] or {
		searchText = "",
		majorPipsOnly = false,
		unearnedOnly = false,
		lastSkillLineID = nil,
	}
	return db.char[charKey()]
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
		majorPipsOnly = charDB.majorPipsOnly == true,
		unearnedOnly = charDB.unearnedOnly == true,
	}
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
		Controller:InvalidateIndex()
		Controller:Refresh()
	end)
	return eventFrame
end

function Controller:SetListening(active)
	listening = active == true
	local frame = ensureEventFrame()
	if listening then
		for i = 1, #TRAIT_EVENTS do
			frame:RegisterEvent(TRAIT_EVENTS[i])
		end
	else
		frame:UnregisterAllEvents()
	end
end

function Controller:InvalidateIndex()
	indexDirty = true
end

function Controller:RebuildIndex()
	local charDB = self:GetCharDB()
	if charDB.lastSkillLineID then
		context = PL.ProfessionContext.GetContextForSkillLine(charDB.lastSkillLineID)
	end
	if not context then
		context = PL.ProfessionContext.GetActiveContext()
	end
	if not context then
		local list = PL.ProfessionContext.ListSpecSkillLines()
		context = list[1]
	end
	if context then
		charDB.lastSkillLineID = context.skillLineID
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

function Controller:SetMajorPipsOnly(enabled)
	self:GetCharDB().majorPipsOnly = enabled == true
	self:Refresh()
end

function Controller:GetMajorPipsOnly()
	return self:GetCharDB().majorPipsOnly == true
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
	self:InvalidateIndex()
	self:Refresh()
end

function Controller:ListProfessions()
	return PL.ProfessionContext.ListSpecSkillLines()
end

function Controller:ApplyFromSaved()
	indexDirty = true
	self:Refresh()
end
