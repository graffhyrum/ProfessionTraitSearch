dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("SpecIndex", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("builds rows for fixture profession", function()
		local pl = load_addon.pl()
		local ctx = pl.ProfessionContext.GetContextForSkillLine(2881)
		local rows = pl.SpecIndex.Build(ctx)
		assert.is_true(#rows >= 4)
		assert.are.equal("tab", rows[1].kind)
	end)

	it("aggregates perk text into path searchableText", function()
		local pl = load_addon.pl()
		local rows = pl.SpecIndex.Build(pl.ProfessionContext.GetContextForSkillLine(2881))
		local deepPath
		for i = 1, #rows do
			if rows[i].pathID == 302 then
				deepPath = rows[i]
				break
			end
		end
		assert.is_true(deepPath ~= nil)
		assert.is_true(deepPath.searchableText:find("Multicraft", 1, true) ~= nil)
	end)
end)

describe("SpecSearch", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	local function allRows()
		local pl = load_addon.pl()
		return pl.SpecIndex.Build(pl.ProfessionContext.GetContextForSkillLine(2881))
	end

	it("matches Multicraft through searchableText", function()
		local pl = load_addon.pl()
		local filtered = pl.SpecSearch.Filter(allRows(), { searchText = "multicraft" })
		assert.is_true(#filtered >= 2)
	end)

	it("filters major pips with ancestor promotion", function()
		local pl = load_addon.pl()
		local filtered = pl.SpecSearch.Filter(allRows(), { majorPipsOnly = true })
		local perks = 0
		for i = 1, #filtered do
			if filtered[i].kind == "perk" then
				perks = perks + 1
				assert.is_true(filtered[i].isMajorPerk)
			end
		end
		assert.are.equal(1, perks)
		assert.is_true(#filtered > 1)
	end)
end)

describe("RowDisplay", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("uses player-facing fallbacks when name is missing", function()
		local pl = load_addon.pl()
		assert.are.equal("Specialization", pl.RowDisplay.DisplayName({ kind = "tab", name = "" }))
		assert.are.equal("Sub-specialization", pl.RowDisplay.DisplayName({ kind = "path", name = "" }))
		assert.are.equal("Perk", pl.RowDisplay.DisplayName({ kind = "perk", name = "" }))
	end)

	it("prefers Blizzard name over fallback", function()
		local pl = load_addon.pl()
		assert.are.equal("Seams", pl.RowDisplay.DisplayName({ kind = "path", name = "Seams" }))
	end)
end)

describe("RankUtil", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("subtracts unlock entry ranks", function()
		local curr, max = load_addon.pl().RankUtil.GetDisplayRanks(101, 301, { currentRank = 3, maxRanks = 5 })
		assert.are.equal(2, curr)
		assert.are.equal(4, max)
	end)
end)
