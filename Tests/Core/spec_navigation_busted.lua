dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("SpecNavigation", function()
	before_each(function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		load_addon.load("core/SpecNavigation.lua")
	end)

	it("resolves tab row without pathID", function()
		local PTS = load_addon.pts()
		local target = PTS.SpecNavigation.ResolveTarget({
			kind = "tab",
			skillLineID = 2881,
			tabTreeID = 100,
		})
		assert.is_true(target ~= nil)
		assert.are.equal(2881, target.skillLineID)
		assert.are.equal(100, target.tabTreeID)
		assert.is_nil(target.pathID)
	end)

	it("resolves path row with pathID", function()
		local PTS = load_addon.pts()
		local target = PTS.SpecNavigation.ResolveTarget({
			kind = "path",
			skillLineID = 2881,
			tabTreeID = 100,
			pathID = 301,
		})
		assert.are.equal(301, target.pathID)
	end)

	it("resolves perk row using parent pathID", function()
		local PTS = load_addon.pts()
		local target = PTS.SpecNavigation.ResolveTarget({
			kind = "perk",
			skillLineID = 2881,
			tabTreeID = 100,
			pathID = 301,
			perkID = 501,
		})
		assert.are.equal(301, target.pathID)
	end)

	it("returns nil when navigation IDs missing", function()
		local PTS = load_addon.pts()
		assert.is_nil(PTS.SpecNavigation.ResolveTarget({ kind = "path", pathID = 301 }))
		assert.is_nil(PTS.SpecNavigation.ResolveTarget(nil))
	end)
end)

describe("SpecIndex navigation fields", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("adds skillLineID and tabTreeID to all rows", function()
		local PTS = load_addon.pts()
		local ctx = PTS.ProfessionContext.GetContextForSkillLine(2881)
		local rows = PTS.SpecIndex.Build(ctx)
		for i = 1, #rows do
			local row = rows[i]
			assert.are.equal(2881, row.skillLineID, row.rowKey)
			assert.is_true(row.tabTreeID ~= nil, row.rowKey)
		end
	end)
end)
