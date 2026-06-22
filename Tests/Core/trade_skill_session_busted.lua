dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("TradeSkillSession", function()
	before_each(function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		load_addon.load("core/TradeSkillSession.lua")
	end)

describe("SyncProfessionFrame", function()

	it("syncs cached recipe filters after a successful frame update", function()
		local PTS = load_addon.pts()
		local activeChild = 2881
		local setProfessionInfoCalls = 0

		_G.Professions = {
			GetProfessionInfo = function()
				return { professionID = activeChild, parentProfessionID = 186 }
			end,
			GetCurrentFilterSet = function()
				return { professionInfo = { professionID = activeChild } }
			end,
		}
		_G.ProfessionsFrame = {
			recipesFilters = { professionInfo = { professionID = 2881 } },
			craftingOrdersFilters = { professionInfo = { professionID = 2881 } },
			SetProfessionInfo = function()
				setProfessionInfoCalls = setProfessionInfoCalls + 1
			end,
		}
		_G.C_TradeSkillUI = {
			IsDataSourceChanging = function()
				return false
			end,
			GetBaseProfessionInfo = function()
				return { professionID = 186 }
			end,
			GetChildProfessionInfo = function()
				return { professionID = activeChild }
			end,
			SetProfessionChildSkillLineID = function(skillLineID)
				activeChild = skillLineID
			end,
			GetProfessionInfoBySkillLineID = function(skillLineID)
				return { parentProfessionID = 186, sourceCounter = skillLineID == 2883 and 1 or 3 }
			end,
		}

		local ok = PTS.TradeSkillSession:SyncProfessionFrame(2883, { openSpecTab = false })

		assert.is_true(ok)
		assert.are.equal(1, setProfessionInfoCalls)
		assert.are.equal(2883, _G.ProfessionsFrame.recipesFilters.professionInfo.professionID)
		assert.are.equal(2883, _G.ProfessionsFrame.craftingOrdersFilters.professionInfo.professionID)
	end)
end)

describe("LoadChildSkillLine", function()

	it("switches child skill line within the same parent profession", function()
		local PTS = load_addon.pts()
		local activeChild = 2881
		local professionSelected = false

		_G.EventRegistry = {
			TriggerEvent = function(_, event)
				if event == "Professions.ProfessionSelected" then
					professionSelected = true
				end
			end,
		}
		_G.C_TradeSkillUI = {
			GetChildProfessionInfo = function()
				return { professionID = activeChild }
			end,
			GetBaseProfessionInfo = function()
				return { professionID = 186 }
			end,
			GetProfessionInfoBySkillLineID = function()
				return { parentProfessionID = 186 }
			end,
			SetProfessionChildSkillLineID = function(skillLineID)
				activeChild = skillLineID
			end,
		}

		local ok = PTS.TradeSkillSession:LoadChildSkillLine(2883)

		assert.is_true(ok)
		assert.is_true(professionSelected)
		assert.are.equal(2883, activeChild)
	end)

	it("returns false when already on target child skill line", function()
		local PTS = load_addon.pts()

		_G.C_TradeSkillUI = {
			GetChildProfessionInfo = function()
				return { professionID = 2881 }
			end,
		}

		assert.is_false(PTS.TradeSkillSession:LoadChildSkillLine(2881))
	end)
end)

describe("OpenForSkillLine", function()

	it("opens parent trade skill for a different profession", function()
		local PTS = load_addon.pts()
		local openTradeSkillCalls = {}
		local openRecipeResponseCalls = {}
		local childSkillLineID = 2881
		local baseProfessionID = 999

		_G.ProfessionsFrame = {
			IsShown = function()
				return false
			end,
			SetOpenRecipeResponse = function(_, skillLineID, recipeID, openSpecTab)
				openRecipeResponseCalls[#openRecipeResponseCalls + 1] = {
					skillLineID = skillLineID,
					openSpecTab = openSpecTab,
				}
			end,
		}
		_G.C_TradeSkillUI = {
			GetChildProfessionInfo = function()
				return { professionID = childSkillLineID }
			end,
			GetBaseProfessionInfo = function()
				return { professionID = baseProfessionID }
			end,
			GetProfessionInfoBySkillLineID = function(skillLineID)
				return { parentProfessionID = 186 }
			end,
			OpenTradeSkill = function(skillLineID)
				openTradeSkillCalls[#openTradeSkillCalls + 1] = skillLineID
			end,
		}

		PTS.TradeSkillSession:OpenForSkillLine(2883, { forceFull = false, openSpecTab = true })

		assert.are.equal(1, #openRecipeResponseCalls)
		assert.are.equal(2883, openRecipeResponseCalls[1].skillLineID)
		assert.is_true(openRecipeResponseCalls[1].openSpecTab)
		assert.are.equal(1, #openTradeSkillCalls)
		assert.are.equal(186, openTradeSkillCalls[1])
	end)

	it("forceFull syncs frame for same parent profession", function()
		local PTS = load_addon.pts()
		local activeChild = 2881
		local setProfessionInfoCalls = 0

		_G.Professions = {
			GetProfessionInfo = function()
				return { professionID = activeChild, parentProfessionID = 186 }
			end,
		}
		_G.ProfessionsFrame = {
			specializationsTabID = 2,
			IsShown = function()
				return false
			end,
			SetTab = function() end,
			SetProfessionInfo = function(_, professionInfo)
				setProfessionInfoCalls = setProfessionInfoCalls + 1
				assert.is_true(professionInfo.openSpecTab)
			end,
		}
		_G.C_TradeSkillUI = {
			IsDataSourceChanging = function()
				return false
			end,
			GetChildProfessionInfo = function()
				return { professionID = activeChild }
			end,
			GetBaseProfessionInfo = function()
				return { professionID = 186 }
			end,
			GetProfessionInfoBySkillLineID = function()
				return { parentProfessionID = 186 }
			end,
			SetProfessionChildSkillLineID = function(skillLineID)
				activeChild = skillLineID
			end,
		}

		PTS.TradeSkillSession:OpenForSkillLine(2883, { forceFull = true, openSpecTab = true })

		assert.are.equal(2883, activeChild)
		assert.are.equal(1, setProfessionInfoCalls)
	end)
end)
end)
