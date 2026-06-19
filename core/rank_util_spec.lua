local PL = _G.PerkLens

describe("RankUtil (sandbox)", function()
	it("subtracts unlock rank from display ranks", function()
		_G.C_ProfSpecs = {
			GetUnlockEntryForPath = function()
				return 901
			end,
		}
		_G.C_Traits = {
			GetEntryInfo = function()
				return { maxRanks = 1 }
			end,
		}
		local nodeInfo = { currentRank = 3, maxRanks = 5 }
		local curr, max = PL.RankUtil.GetDisplayRanks(101, 301, nodeInfo)
		assert.equals(2, curr)
		assert.equals(4, max)
	end)
end)
