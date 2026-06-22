dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("SpecIndex", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("builds rows for fixture profession", function()
		local PTS = load_addon.pts()
		local ctx = PTS.ProfessionContext.GetContextForSkillLine(2881)
		local rows = PTS.SpecIndex.Build(ctx)
		assert.is_true(#rows >= 4)
		assert.are.equal("tab", rows[1].kind)
	end)

	it("aggregates perk text into path searchableText", function()
		local PTS = load_addon.pts()
		local rows = PTS.SpecIndex.Build(PTS.ProfessionContext.GetContextForSkillLine(2881))
		local deepPath
		for i = 1, #rows do
			if rows[i].pathID == 302 then
				deepPath = rows[i]
				break
			end
		end
		assert.is_true(deepPath ~= nil)
		assert.are.equal("Deep Veins", deepPath.name)
		assert.is_false(deepPath.name:find("Grants bonuses", 1, true) ~= nil)
		assert.is_true(deepPath.searchableText:find("Multicraft", 1, true) ~= nil)
	end)
end)

describe("SpecSearch", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	local function allRows()
		local PTS = load_addon.pts()
		return PTS.SpecIndex.Build(PTS.ProfessionContext.GetContextForSkillLine(2881))
	end

	it("matches Multicraft through searchableText", function()
		local PTS = load_addon.pts()
		local filtered = PTS.SpecSearch.Filter(allRows(), { searchText = "multicraft" })
		assert.is_true(#filtered >= 2)
	end)

	it("filters major perks with ancestor promotion", function()
		local PTS = load_addon.pts()
		local filtered = PTS.SpecSearch.Filter(allRows(), { majorPerksOnly = true })
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

	it("filters unearned rows with ancestor promotion", function()
		local PTS = load_addon.pts()
		local rows = allRows()
		local filtered = PTS.SpecSearch.Filter(rows, { unearnedOnly = true })
		assert.are.equal(#rows, #filtered)

		for i = 1, #filtered do
			local row = filtered[i]
			if row.kind == "perk" or row.kind == "path" then
				assert.is_true(PTS.RowProgress.IsUnearned(row))
			end
		end

		local hasTab = false
		for i = 1, #filtered do
			if filtered[i].kind == "tab" then
				hasTab = true
				break
			end
		end
		assert.is_true(hasTab)

		for i = 1, #rows do
			if rows[i].perkID == 402 then
				rows[i].isEarned = true
				break
			end
		end
		filtered = PTS.SpecSearch.Filter(rows, { unearnedOnly = true })
		local earnedMajorVisible = false
		for i = 1, #filtered do
			if filtered[i].perkID == 402 then
				earnedMajorVisible = true
			end
		end
		assert.is_false(earnedMajorVisible)
		assert.is_true(#filtered > 0)
	end)
end)

describe("RowProgress", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("classifies unearned state per row kind", function()
		local PTS = load_addon.pts()
		local rp = PTS.RowProgress
		assert.is_false(rp.IsUnearned({ kind = "tab" }))
		assert.is_true(rp.IsUnearned({ kind = "path", isCompleted = false }))
		assert.is_true(rp.IsUnearned({ kind = "path", isCompleted = nil }))
		assert.is_false(rp.IsUnearned({ kind = "path", isCompleted = true }))
		assert.is_true(rp.IsUnearned({ kind = "perk", isEarned = false }))
		assert.is_false(rp.IsUnearned({ kind = "perk", isEarned = true }))
	end)

	it("classifies completed paths only", function()
		local PTS = load_addon.pts()
		local rp = PTS.RowProgress
		assert.is_false(rp.IsCompleted({ kind = "tab", isCompleted = true }))
		assert.is_false(rp.IsCompleted({ kind = "perk", isCompleted = true }))
		assert.is_false(rp.IsCompleted({ kind = "path", isCompleted = false }))
		assert.is_true(rp.IsCompleted({ kind = "path", isCompleted = true }))
	end)

	it("classifies earned perks only", function()
		local PTS = load_addon.pts()
		local rp = PTS.RowProgress
		assert.is_false(rp.IsEarned({ kind = "tab", isEarned = true }))
		assert.is_false(rp.IsEarned({ kind = "path", isEarned = true }))
		assert.is_false(rp.IsEarned({ kind = "perk", isEarned = false }))
		assert.is_true(rp.IsEarned({ kind = "perk", isEarned = true }))
	end)

	it("matches fixture index row progress flags", function()
		local PTS = load_addon.pts()
		local rows = PTS.SpecIndex.Build(PTS.ProfessionContext.GetContextForSkillLine(2881))
		local rp = PTS.RowProgress
		for i = 1, #rows do
			local row = rows[i]
			if row.kind == "tab" then
				assert.is_false(rp.IsUnearned(row))
				assert.is_false(rp.IsCompleted(row))
				assert.is_false(rp.IsEarned(row))
			elseif row.kind == "path" then
				assert.is_true(rp.IsUnearned(row))
				assert.is_false(rp.IsCompleted(row))
			elseif row.kind == "perk" then
				assert.is_true(rp.IsUnearned(row))
				assert.is_false(rp.IsEarned(row))
			end
		end
	end)
end)

describe("RowDisplay", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("uses player-facing fallbacks when name is missing", function()
		local PTS = load_addon.pts()
		assert.are.equal("Specialization", PTS.RowDisplay.DisplayName({ kind = "tab", name = "" }))
		assert.are.equal("Sub-specialization", PTS.RowDisplay.DisplayName({ kind = "path", name = "" }))
		assert.are.equal("Perk", PTS.RowDisplay.DisplayName({ kind = "perk", name = "" }))
	end)

	it("prefers Blizzard name over fallback", function()
		local PTS = load_addon.pts()
		assert.are.equal("Seams", PTS.RowDisplay.DisplayName({ kind = "path", name = "Seams" }))
	end)

	it("includes Earned in perk badge via RowProgress", function()
		local PTS = load_addon.pts()
		local earned = PTS.RowDisplay.PerkBadgeText({ kind = "perk", isEarned = true, isMajorPerk = false })
		local unearned = PTS.RowDisplay.PerkBadgeText({ kind = "perk", isEarned = false, isMajorPerk = false })
		assert.is_true(earned:find("Earned", 1, true) ~= nil)
		assert.is_false(unearned:find("Earned", 1, true) ~= nil)
	end)
end)

describe("RankUtil", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("subtracts unlock entry ranks", function()
		local curr, max = load_addon.pts().RankUtil.GetDisplayRanks(101, 301, { currentRank = 3, maxRanks = 5 })
		assert.are.equal(2, curr)
		assert.are.equal(4, max)
	end)
end)
