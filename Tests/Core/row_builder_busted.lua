dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")
local snapshots = require("Tests.fixtures.row_builder_snapshots")

local function findRow(rows, predicate)
	for i = 1, #rows do
		if predicate(rows[i]) then
			return rows[i]
		end
	end
	return nil
end

local function rowKinds(rows)
	local kinds = {}
	for i = 1, #rows do
		kinds[#kinds + 1] = rows[i].kind
	end
	return kinds
end

describe("RowBuilder", function()
	before_each(function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		load_addon.load("core/RowBuilder.lua")
	end)

	it("returns empty rows for nil snapshot", function()
		local rows = load_addon.pts().RowBuilder.Build(nil)
		assert.are.same({}, rows)
	end)

	it("builds tab row with searchable tab text", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.miningTree())
		local tab = rows[1]
		assert.are.equal("tab", tab.kind)
		assert.are.equal("tab:201", tab.rowKey)
		assert.are.equal(0, tab.depth)
		assert.are.equal(2881, tab.skillLineID)
		assert.are.equal("Over-LODED", tab.name)
		assert.are.equal("Over-LODED\nMaster unexpected mining.", tab.searchableText)
	end)

	it("walks nested paths with depth and parentPathID", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.miningTree())
		assert.are.same({ "tab", "path", "perk", "path", "perk" }, rowKinds(rows))

		local rootPath = findRow(rows, function(row)
			return row.pathID == 301
		end)
		local childPath = findRow(rows, function(row)
			return row.pathID == 302
		end)
		assert.is_true(rootPath ~= nil)
		assert.is_true(childPath ~= nil)
		assert.are.equal(1, rootPath.depth)
		assert.is_nil(rootPath.parentPathID)
		assert.are.equal(2, childPath.depth)
		assert.are.equal(301, childPath.parentPathID)
		assert.are.equal("Deep Veins", childPath.name)
	end)

	it("emits perk rows after their path with incremented depth", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.miningTree())
		local rootPerk = findRow(rows, function(row)
			return row.perkID == 401
		end)
		local deepPerk = findRow(rows, function(row)
			return row.perkID == 402
		end)
		assert.are.equal("perk:401", rootPerk.rowKey)
		assert.are.equal(2, rootPerk.depth)
		assert.are.equal(301, rootPerk.pathID)
		assert.are.equal(301, rootPerk.parentPathID)
		assert.are.equal("Minor bonus", rootPerk.name)
		assert.are.equal("Minor bonus", rootPerk.searchableText)
		assert.is_true(deepPerk.isMajorPerk)
		assert.are.equal(20, deepPerk.unlockRank)
	end)

	it("rolls perk descriptions into path searchableText", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.miningTree())
		local deepPath = findRow(rows, function(row)
			return row.pathID == 302
		end)
		assert.is_true(deepPath.searchableText:find("Grants bonuses while mining deep veins.", 1, true) ~= nil)
		assert.is_true(deepPath.searchableText:find("Multicraft", 1, true) ~= nil)
		assert.is_false(deepPath.name:find("Multicraft", 1, true) ~= nil)
	end)

	it("uses path description alone when path has no perks", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.pathWithoutPerks())
		local path = findRow(rows, function(row)
			return row.pathID == 604
		end)
		assert.are.equal("Only path text.", path.searchableText)
	end)

	it("uses first line of multiline perk description as perk name", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.multilinePerkPath())
		local perkRow = findRow(rows, function(row)
			return row.perkID == 901
		end)
		assert.are.equal("Visible Title", perkRow.name)
		assert.are.equal("Visible Title\nHidden body text", perkRow.description)
	end)

	it("marks lowest-rank unearned perk as next with parentPathRank", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.nextPerkPath())
		local nextPerk = findRow(rows, function(row)
			return row.perkID == 702
		end)
		local earnedPerk = findRow(rows, function(row)
			return row.perkID == 701
		end)
		local laterPerk = findRow(rows, function(row)
			return row.perkID == 703
		end)
		assert.is_true(nextPerk.isNextPerk)
		assert.are.equal(3, nextPerk.parentPathRank)
		assert.is_false(earnedPerk.isNextPerk)
		assert.is_false(laterPerk.isNextPerk)
	end)

	it("marks no perk as next when all perks are earned", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.allPerksEarnedPath())
		for i = 1, #rows do
			if rows[i].kind == "perk" then
				assert.is_false(rows[i].isNextPerk)
			end
		end
	end)

	it("propagates skillLineID and tab metadata to descendant rows", function()
		local rows = load_addon.pts().RowBuilder.Build(snapshots.miningTree())
		for i = 2, #rows do
			assert.are.equal(2881, rows[i].skillLineID)
			assert.are.equal(201, rows[i].tabTreeID)
			assert.are.equal("Over-LODED", rows[i].tabName)
		end
	end)
end)
