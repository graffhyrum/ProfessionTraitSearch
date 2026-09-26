dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

-- IndexSession policy (issue #9):
--   Rebuild  — resolve profession context + SpecIndex.Build; clears indexDirty; re-filters visible rows.
--   Refresh  — Rebuild when dirty; otherwise only ApplyVisibleRows (filter/fold) on cached allRows.
--   EnsureFresh — Rebuild only when dirty; no re-filter when already clean.
--   Invalidate — sets indexDirty; next Refresh/EnsureFresh triggers Rebuild.

local function ctx(skillLineID)
	return {
		skillLineID = skillLineID,
		configID = skillLineID * 10,
		professionName = "Profession " .. tostring(skillLineID),
	}
end

local function sampleRows()
	return {
		{
			kind = "tab",
			name = "Alpha Tab",
			rowKey = "tab:1",
			searchableText = "Alpha Tab",
			skillLineID = 2881,
		},
		{
			kind = "perk",
			name = "Beta Perk",
			rowKey = "perk:2",
			searchableText = "Beta multicraft",
			isMajorPerk = true,
			skillLineID = 2881,
		},
		{
			kind = "perk",
			name = "Gamma Perk",
			rowKey = "perk:3",
			searchableText = "Gamma normal",
			isMajorPerk = false,
			skillLineID = 2881,
		},
	}
end

local function withIndexStubs(stubMap, fn)
	local PTS = load_addon.pts()
	local saved = {}
	for moduleName, replacements in pairs(stubMap) do
		for key, replacement in pairs(replacements) do
			local target = PTS[moduleName]
			saved[#saved + 1] = { moduleName = moduleName, key = key, original = target[key] }
			target[key] = replacement
		end
	end
	local ok, err = pcall(fn)
	for i = 1, #saved do
		local entry = saved[i]
		PTS[entry.moduleName][entry.key] = entry.original
	end
	if not ok then
		error(err)
	end
end

local function defaultOptions(overrides)
	local options = {
		charDB = { lastSkillLineID = 2881 },
		viewMode = "standalone",
		filterOptions = {
			searchText = "",
			majorPerksOnly = false,
			unearnedOnly = false,
		},
		foldCollapsed = {},
	}
	if overrides then
		for key, value in pairs(overrides) do
			options[key] = value
		end
	end
	return options
end

describe("IndexSession", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	describe("dirty flag", function()
		it("starts dirty and Rebuild clears dirty", function()
			local PTS = load_addon.pts()
			local session = PTS.IndexSession:New()
			assert.is_true(session:IsDirty())

			withIndexStubs({
				ProfessionContext = {
					ResolveForIndex = function()
						return ctx(2881)
					end,
				},
				SpecIndex = {
					Build = function()
						return sampleRows()
					end,
				},
			}, function()
				session:Rebuild(defaultOptions())
			end)

			assert.is_false(session:IsDirty())
		end)

		it("Invalidate marks dirty; Refresh rebuilds", function()
			local PTS = load_addon.pts()
			local session = PTS.IndexSession:New()
			local buildCalls = 0
			local resolveCalls = 0

			withIndexStubs({
				ProfessionContext = {
					ResolveForIndex = function()
						resolveCalls = resolveCalls + 1
						return ctx(2881)
					end,
				},
				SpecIndex = {
					Build = function()
						buildCalls = buildCalls + 1
						return sampleRows()
					end,
				},
			}, function()
				session:Rebuild(defaultOptions())
				assert.are.equal(1, buildCalls)
				assert.are.equal(1, resolveCalls)
				assert.is_false(session:IsDirty())

				session:Invalidate()
				assert.is_true(session:IsDirty())

				session:Refresh(defaultOptions())
				assert.are.equal(2, buildCalls)
				assert.are.equal(2, resolveCalls)
				assert.is_false(session:IsDirty())
			end)
		end)
	end)

	describe("Refresh when clean", function()
		it("re-filters only; allRows identity unchanged and rebuild not called", function()
			local PTS = load_addon.pts()
			local session = PTS.IndexSession:New()
			local buildCalls = 0
			local resolveCalls = 0
			local rows = sampleRows()

			withIndexStubs({
				ProfessionContext = {
					ResolveForIndex = function()
						resolveCalls = resolveCalls + 1
						return ctx(2881)
					end,
				},
				SpecIndex = {
					Build = function()
						buildCalls = buildCalls + 1
						return rows
					end,
				},
			}, function()
				session:Rebuild(defaultOptions())
				assert.are.equal(1, buildCalls)
				assert.are.equal(1, resolveCalls)
				assert.is_false(session:IsDirty())

				local cachedAllRows = session:GetAllRows()
				local initialVisibleCount = #session:GetVisibleRows()
				assert.are.equal(3, initialVisibleCount)

				session:Refresh(defaultOptions({
					filterOptions = {
						searchText = "",
						majorPerksOnly = true,
						unearnedOnly = false,
					},
				}))

				assert.are.equal(1, buildCalls, "SpecIndex.Build must not run when index is clean")
				assert.are.equal(1, resolveCalls, "ResolveForIndex must not run when index is clean")
				assert.are.equal(cachedAllRows, session:GetAllRows(), "allRows table identity must be preserved")
				assert.is_true(#session:GetVisibleRows() < initialVisibleCount, "visible rows must change after filter")
				assert.are.equal(1, #session:GetVisibleRows(), "majorPerksOnly keeps only the major perk row")
			end)
		end)
	end)

	describe("EnsureFresh", function()
		it("rebuilds only when dirty", function()
			local PTS = load_addon.pts()
			local session = PTS.IndexSession:New()
			local buildCalls = 0
			local resolveCalls = 0

			withIndexStubs({
				ProfessionContext = {
					ResolveForIndex = function()
						resolveCalls = resolveCalls + 1
						return ctx(2881)
					end,
				},
				SpecIndex = {
					Build = function()
						buildCalls = buildCalls + 1
						return sampleRows()
					end,
				},
			}, function()
				session:Rebuild(defaultOptions())
				assert.are.equal(1, buildCalls)
				assert.is_false(session:IsDirty())

				local cachedAllRows = session:GetAllRows()
				local cachedVisibleRows = session:GetVisibleRows()

				session:EnsureFresh(defaultOptions())
				assert.are.equal(1, buildCalls, "EnsureFresh must not rebuild when clean")
				assert.are.equal(1, resolveCalls)
				assert.are.equal(cachedAllRows, session:GetAllRows())
				assert.are.equal(cachedVisibleRows, session:GetVisibleRows())

				session:Invalidate()
				session:EnsureFresh(defaultOptions())
				assert.are.equal(2, buildCalls, "EnsureFresh must rebuild when dirty")
				assert.are.equal(2, resolveCalls)
				assert.is_false(session:IsDirty())
			end)
		end)
	end)
end)
