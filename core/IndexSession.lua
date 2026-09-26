local PTS = _G.ProfessionTraitSearch

local IndexSession = {}
PTS.IndexSession = IndexSession

function IndexSession:New()
	return setmetatable({
		allRows = {},
		visibleRows = {},
		indexDirty = true,
		context = nil,
	}, { __index = IndexSession })
end

function IndexSession:Invalidate()
	self.indexDirty = true
end

function IndexSession:IsDirty()
	return self.indexDirty == true
end

function IndexSession:ApplyVisibleRows(filterOptions, foldCollapsed)
	local filtered = PTS.SpecSearch.Filter(self.allRows, filterOptions)
	self.visibleRows = PTS.SpecFold.Filter(filtered, self.allRows, foldCollapsed)
end

local function resolveFoldCollapsed(options, skillLineID)
	if options.resolveFoldCollapsed then
		return options.resolveFoldCollapsed(skillLineID)
	end
	return options.foldCollapsed or {}
end

function IndexSession:Rebuild(options)
	local charDB = options.charDB
	local viewMode = options.viewMode
	local preferActive = viewMode == "embedded"
	local requestedSkillLineID = charDB.lastSkillLineID

	self.context = PTS.ProfessionContext.ResolveForIndex(charDB, preferActive)
	if self.context then
		charDB.lastSkillLineID = self.context.skillLineID
	elseif requestedSkillLineID and viewMode == "standalone" then
		charDB.lastSkillLineID = requestedSkillLineID
	end

	self.allRows = self.context and PTS.SpecIndex.Build(self.context) or {}
	self.indexDirty = false

	local skillLineID = self.context and self.context.skillLineID or charDB.lastSkillLineID
	self:ApplyVisibleRows(options.filterOptions, resolveFoldCollapsed(options, skillLineID))
end

function IndexSession:Refresh(options)
	if self.indexDirty then
		self:Rebuild(options)
	else
		local skillLineID = self.context and self.context.skillLineID or options.charDB.lastSkillLineID
		self:ApplyVisibleRows(options.filterOptions, resolveFoldCollapsed(options, skillLineID))
	end
end

function IndexSession:EnsureFresh(options)
	if self.indexDirty then
		self:Rebuild(options)
	end
end

function IndexSession:GetContext()
	return self.context
end

function IndexSession:GetAllRows()
	return self.allRows
end

function IndexSession:GetVisibleRows()
	return self.visibleRows
end
