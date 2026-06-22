dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

local function ctx(skillLineID, name)
	return {
		skillLineID = skillLineID,
		configID = skillLineID * 10,
		professionName = name or ("Profession " .. tostring(skillLineID)),
	}
end

local function withStubs(stubMap, fn)
	local saved = {}
	for key, replacement in pairs(stubMap) do
		saved[key] = _G.ProfessionTraitSearch.ProfessionContext[key]
		_G.ProfessionTraitSearch.ProfessionContext[key] = replacement
	end
	local ok, err = pcall(fn)
	for key, original in pairs(saved) do
		_G.ProfessionTraitSearch.ProfessionContext[key] = original
	end
	if not ok then
		error(err)
	end
end

describe("ProfessionContext.ResolveForIndex", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	local cases = {
		{
			name = "preferActive uses active context first",
			preferActive = true,
			charDB = { lastSkillLineID = 2002 },
			active = ctx(2001, "Active"),
			saved = ctx(2002, "Saved"),
			list = { ctx(2003, "Listed") },
			want = 2001,
		},
		{
			name = "preferActive falls back to saved skill line",
			preferActive = true,
			charDB = { lastSkillLineID = 2002 },
			active = nil,
			saved = ctx(2002, "Saved"),
			list = { ctx(2003, "Listed") },
			want = 2002,
		},
		{
			name = "standalone prefers saved skill line over active",
			preferActive = false,
			charDB = { lastSkillLineID = 2002 },
			active = ctx(2001, "Active"),
			saved = ctx(2002, "Saved"),
			list = { ctx(2003, "Listed") },
			want = 2002,
		},
		{
			name = "no saved uses active context",
			preferActive = false,
			charDB = {},
			active = ctx(2001, "Active"),
			saved = nil,
			list = { ctx(2003, "Listed") },
			want = 2001,
		},
		{
			name = "falls back to first listed profession",
			preferActive = false,
			charDB = {},
			active = nil,
			saved = nil,
			list = { ctx(2003, "Listed") },
			want = 2003,
		},
		{
			name = "preferActive retries active after saved miss",
			preferActive = true,
			charDB = { lastSkillLineID = 9999 },
			active = ctx(2001, "Active"),
			saved = nil,
			list = { ctx(2003, "Listed") },
			want = 2001,
		},
		{
			name = "returns nil when no context sources",
			preferActive = false,
			charDB = {},
			active = nil,
			saved = nil,
			list = {},
			want = nil,
		},
	}

	for i = 1, #cases do
		local case = cases[i]
		it(case.name, function()
			local PTS = load_addon.pts()
			withStubs({
				GetActiveContext = function()
					return case.active
				end,
				GetContextForSkillLine = function(skillLineID)
					if case.charDB.lastSkillLineID == skillLineID then
						return case.saved
					end
					return nil
				end,
				ListSpecSkillLines = function()
					return case.list
				end,
			}, function()
				local resolved = PTS.ProfessionContext.ResolveForIndex(case.charDB, case.preferActive)
				if case.want == nil then
					assert.is_nil(resolved)
				else
					assert.is_true(resolved ~= nil)
					assert.are.equal(case.want, resolved.skillLineID)
				end
			end)
		end)
	end

	it("ignores saved skill line when profession was switched away", function()
		local PTS = load_addon.pts()
		local active = ctx(2872, "Midnight Blacksmithing")
		local stale = ctx(2871, "Midnight Alchemy")
		withStubs({
			GetActiveContext = function()
				return active
			end,
			GetContextForSkillLine = function(skillLineID)
				if skillLineID == 2871 then
					return stale
				end
				if skillLineID == 2872 then
					return active
				end
				return nil
			end,
			ListSpecSkillLines = function()
				return { active }
			end,
			IsTrainedSkillLine = function(skillLineID)
				return skillLineID ~= 2871
			end,
		}, function()
			local resolved = PTS.ProfessionContext.ResolveForIndex({ lastSkillLineID = 2871 }, false)
			assert.are.equal(2872, resolved.skillLineID)
		end)
	end)
end)

describe("Controller ViewMode", function()
	before_each(function()
		load_addon.reset()
		_G.ProfessionTraitSearchDB = nil
		_G.UnitGUID = function()
			return "test-guid"
		end
		load_addon.load_core()
	end)

	it("embedded view mode prefers active profession context", function()
		local PTS = load_addon.pts()
		local active = ctx(2001, "Active")
		local saved = ctx(2002, "Saved")
		withStubs({
			GetActiveContext = function()
				return active
			end,
			GetContextForSkillLine = function(skillLineID)
				if skillLineID == 2002 then
					return saved
				end
				return nil
			end,
			ListSpecSkillLines = function()
				return { saved }
			end,
		}, function()
			PTS.Controller:SetViewMode("embedded")
			PTS.Controller:GetCharDB().lastSkillLineID = 2002
			PTS.Controller:RebuildIndex()
			assert.are.equal(2001, PTS.Controller:GetContext().skillLineID)
		end)
	end)

	it("closed view mode prefers saved skill line over active", function()
		local PTS = load_addon.pts()
		local active = ctx(2001, "Active")
		local saved = ctx(2002, "Saved")
		withStubs({
			GetActiveContext = function()
				return active
			end,
			GetContextForSkillLine = function(skillLineID)
				if skillLineID == 2002 then
					return saved
				end
				return nil
			end,
			ListSpecSkillLines = function()
				return { saved }
			end,
		}, function()
			PTS.Controller:SetViewMode("closed")
			PTS.Controller:GetCharDB().lastSkillLineID = 2002
			PTS.Controller:RebuildIndex()
			assert.are.equal(2002, PTS.Controller:GetContext().skillLineID)
		end)
	end)

	it("does not call ProfessionsHook for context policy", function()
		local PTS = load_addon.pts()
		PTS.ProfessionsHook = {
			IsIndexMode = function()
				error("core must not call ProfessionsHook:IsIndexMode")
			end,
		}
		PTS.Controller:SetViewMode("embedded")
		PTS.Controller:RebuildIndex()
	end)
end)

describe("ProfessionContext.ListSpecSkillLines", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	local function stubProfessionAPIs(skillLines, professionInfoBySkillLineID, trainedSkillLines)
		_G.C_TradeSkillUI.GetAllProfessionTradeSkillLines = function()
			return skillLines
		end
		_G.C_ProfSpecs.SkillLineHasSpecialization = function()
			return true
		end
		_G.C_ProfSpecs.GetConfigIDForSkillLine = function(skillLineID)
			return skillLineID
		end
		_G.C_TradeSkillUI.GetProfessionInfoBySkillLineID = function(skillLineID)
			return professionInfoBySkillLineID[skillLineID]
		end
		_G.GetProfessions = function()
			return 1, 2
		end
		local trained = trainedSkillLines or {}
		_G.GetProfessionInfo = function(index)
			local skillLine = trained[index]
			if not skillLine then
				return nil
			end
			return "Profession", nil, 1, 100, 0, 0, skillLine
		end
	end

	it("orders professions by expansion newest first (lower sourceCounter is newer)", function()
		local PTS = load_addon.pts()
		stubProfessionAPIs({ 2881, 2882, 2883 }, {
			[2881] = {
				professionName = "Dragon Isles Mining",
				sourceCounter = 3,
				parentProfessionID = 186,
			},
			[2882] = {
				professionName = "Khaz Algar Mining",
				sourceCounter = 2,
				parentProfessionID = 186,
			},
			[2883] = {
				professionName = "Midnight Mining",
				sourceCounter = 1,
				parentProfessionID = 186,
			},
		}, { [1] = 186 })

		local list = PTS.ProfessionContext.ListSpecSkillLines()
		assert.are.equal(3, #list)
		assert.are.equal(2883, list[1].skillLineID)
		assert.are.equal(2882, list[2].skillLineID)
		assert.are.equal(2881, list[3].skillLineID)
	end)

	it("orders mixed professions newest expansion first like the dropdown", function()
		local PTS = load_addon.pts()
		stubProfessionAPIs({ 2801, 2811, 2812, 2910, 2911 }, {
			[2801] = {
				professionName = "Dragon Isles Engineering",
				sourceCounter = 3,
				parentProfessionID = 202,
			},
			[2811] = {
				professionName = "Khaz Algar Mining",
				sourceCounter = 2,
				parentProfessionID = 186,
			},
			[2812] = {
				professionName = "Khaz Algar Engineering",
				sourceCounter = 2,
				parentProfessionID = 202,
			},
			[2910] = {
				professionName = "Midnight Mining",
				sourceCounter = 1,
				parentProfessionID = 186,
			},
			[2911] = {
				professionName = "Midnight Engineering",
				sourceCounter = 1,
				parentProfessionID = 202,
			},
		}, { [1] = 186, [2] = 202 })

		local list = PTS.ProfessionContext.ListSpecSkillLines()
		assert.are.equal(5, #list)
		assert.are.equal(2910, list[1].skillLineID)
		assert.are.equal(2911, list[2].skillLineID)
		assert.are.equal(2811, list[3].skillLineID)
		assert.are.equal(2812, list[4].skillLineID)
		assert.are.equal(2801, list[5].skillLineID)
	end)

	it("orders by API list position when sourceCounter is zero", function()
		local PTS = load_addon.pts()
		stubProfessionAPIs({ 2881, 2882, 2883 }, {
			[2881] = {
				professionName = "Dragon Isles Mining",
				sourceCounter = 0,
				parentProfessionID = 186,
			},
			[2882] = {
				professionName = "Khaz Algar Mining",
				sourceCounter = 0,
				parentProfessionID = 186,
			},
			[2883] = {
				professionName = "Midnight Mining",
				sourceCounter = 0,
				parentProfessionID = 186,
			},
		}, { [1] = 186 })

		local list = PTS.ProfessionContext.ListSpecSkillLines()
		assert.are.equal(2883, list[1].skillLineID)
		assert.are.equal(2882, list[2].skillLineID)
		assert.are.equal(2881, list[3].skillLineID)
	end)

	it("excludes skill lines from switched-away professions", function()
		local PTS = load_addon.pts()
		stubProfessionAPIs({ 2883, 2871, 2872 }, {
			[2883] = {
				professionName = "Midnight Mining",
				sourceCounter = 1,
				parentProfessionID = 186,
			},
			[2871] = {
				professionName = "Midnight Alchemy",
				sourceCounter = 1,
				parentProfessionID = 171,
			},
			[2872] = {
				professionName = "Midnight Blacksmithing",
				sourceCounter = 1,
				parentProfessionID = 164,
			},
		}, { [1] = 186, [2] = 164 })

		local list = PTS.ProfessionContext.ListSpecSkillLines()
		assert.are.equal(2, #list)
		assert.are.equal(2883, list[1].skillLineID)
		assert.are.equal(2872, list[2].skillLineID)
	end)
end)

describe("Controller standalone profession switch", function()
	before_each(function()
		load_addon.reset()
		_G.ProfessionTraitSearchDB = nil
		_G.UnitGUID = function()
			return "test-guid"
		end
		load_addon.load_core()
	end)

	it("SetSkillLine updates context in standalone view mode", function()
		local PTS = load_addon.pts()
		local mining = ctx(2883, "Midnight Mining")
		local alchemy = ctx(2871, "Midnight Alchemy")
		withStubs({
			IsTrainedSkillLine = function()
				return true
			end,
			GetActiveContext = function()
				return mining
			end,
			GetContextForSkillLine = function(skillLineID)
				if skillLineID == 2883 then
					return mining
				end
				if skillLineID == 2871 then
					return alchemy
				end
				return nil
			end,
			ListSpecSkillLines = function()
				return { mining, alchemy }
			end,
		}, function()
			PTS.Controller:SetViewMode("standalone")
			PTS.Controller:RebuildIndex()
			assert.are.equal(2883, PTS.Controller:GetContext().skillLineID)

			PTS.Controller:SetSkillLine(2871)
			assert.are.equal(2871, PTS.Controller:GetContext().skillLineID)
		end)
	end)

	it("switches expansion specs within the same parent profession", function()
		local PTS = load_addon.pts()
		local activeChild = 2911
		local configs = { [2911] = 111, [2801] = 101 }
		local tabs = {
			[2911] = { 501 },
			[2801] = { 502 },
		}
		local tabInfo = {
			[501] = { rootNodeID = 601, name = "Midnight Eng Spec", description = "" },
			[502] = { rootNodeID = 602, name = "Dragon Eng Spec", description = "" },
		}

		_G.GetProfessions = function()
			return 1
		end
		_G.GetProfessionInfo = function()
			return "Engineering", nil, 1, 100, 0, 0, 202
		end
		_G.ProfessionsFrame = {
			GetProfessionInfo = function()
				return { professionID = activeChild }
			end,
		}
		_G.C_TradeSkillUI.GetAllProfessionTradeSkillLines = function()
			return { 2911, 2801 }
		end
		_G.C_TradeSkillUI.GetChildProfessionInfo = function()
			return { professionID = activeChild }
		end
		_G.C_TradeSkillUI.GetBaseProfessionInfo = function()
			return { professionID = 202 }
		end
		_G.C_TradeSkillUI.SetProfessionChildSkillLineID = function(skillLineID)
			activeChild = skillLineID
		end
		_G.C_TradeSkillUI.GetProfessionInfoBySkillLineID = function(skillLineID)
			return {
				professionName = skillLineID == 2911 and "Midnight Engineering" or "Dragon Isles Engineering",
				parentProfessionID = 202,
				sourceCounter = skillLineID == 2911 and 1 or 3,
			}
		end
		_G.C_ProfSpecs.SkillLineHasSpecialization = function()
			return true
		end
		_G.C_ProfSpecs.GetConfigIDForSkillLine = function(skillLineID)
			if skillLineID == activeChild then
				return configs[skillLineID] or 0
			end
			return 0
		end
		_G.C_ProfSpecs.GetSpecTabIDsForSkillLine = function(skillLineID)
			return tabs[skillLineID] or {}
		end
		_G.C_ProfSpecs.GetTabInfo = function(tabID)
			return tabInfo[tabID]
		end
		_G.C_ProfSpecs.GetChildrenForPath = function()
			return {}
		end
		_G.C_ProfSpecs.GetPerksForPath = function()
			return {}
		end
		_G.C_ProfSpecs.GetDescriptionForPath = function()
			return ""
		end

		PTS.Controller:SetViewMode("standalone")
		PTS.Controller:RebuildIndex()
		assert.are.equal(2911, PTS.Controller:GetContext().skillLineID)
		assert.are.equal("Midnight Eng Spec", PTS.Controller:GetVisibleRows()[1].name)

		PTS.Controller:SetSkillLine(2801)
		assert.are.equal(2801, PTS.Controller:GetCharDB().lastSkillLineID)
		assert.are.equal(2801, PTS.Controller:GetContext().skillLineID)
		assert.are.equal("Dragon Eng Spec", PTS.Controller:GetVisibleRows()[1].name)
	end)

	it("defers expansion switch until TRADE_SKILL_LIST_UPDATE", function()
		local eventHandler
		_G.CreateFrame = function()
			local frame = {
				RegisterEvent = function() end,
				UnregisterEvent = function() end,
				UnregisterAllEvents = function() end,
				SetScript = function(_, name, fn)
					if name == "OnEvent" then
						eventHandler = fn
					end
				end,
			}
			return frame
		end

		load_addon.reset()
		_G.ProfessionTraitSearchDB = nil
		_G.UnitGUID = function()
			return "test-guid"
		end
		load_addon.load_core()

		local PTS = load_addon.pts()
		local activeChild = 2911
		local dataReady = true
		local configs = { [2911] = 111, [2801] = 101 }
		local tabs = {
			[2911] = { 501 },
			[2801] = { 502 },
		}
		local tabInfo = {
			[501] = { rootNodeID = 601, name = "Midnight Eng Spec", description = "" },
			[502] = { rootNodeID = 602, name = "Dragon Eng Spec", description = "" },
		}
		local professionSelected = false

		_G.GetProfessions = function()
			return 1
		end
		_G.GetProfessionInfo = function()
			return "Engineering", nil, 1, 100, 0, 0, 202
		end
		_G.EventRegistry = {
			TriggerEvent = function(_, event)
				if event == "Professions.ProfessionSelected" then
					professionSelected = true
				end
			end,
		}
		_G.ProfessionsFrame = {
			GetProfessionInfo = function()
				return { professionID = activeChild }
			end,
		}
		_G.C_TradeSkillUI.GetAllProfessionTradeSkillLines = function()
			return { 2911, 2801 }
		end
		_G.C_TradeSkillUI.GetChildProfessionInfo = function()
			return { professionID = activeChild }
		end
		_G.C_TradeSkillUI.GetBaseProfessionInfo = function()
			return { professionID = 202 }
		end
		_G.C_TradeSkillUI.IsDataSourceChanging = function()
			return not dataReady
		end
		_G.C_TradeSkillUI.SetProfessionChildSkillLineID = function(skillLineID)
			activeChild = skillLineID
			dataReady = false
		end
		_G.C_TradeSkillUI.GetProfessionInfoBySkillLineID = function(skillLineID)
			return {
				professionName = skillLineID == 2911 and "Midnight Engineering" or "Dragon Isles Engineering",
				parentProfessionID = 202,
				sourceCounter = skillLineID == 2911 and 1 or 3,
			}
		end
		_G.C_ProfSpecs.SkillLineHasSpecialization = function()
			return true
		end
		_G.C_ProfSpecs.GetConfigIDForSkillLine = function(skillLineID)
			if not dataReady then
				return 0
			end
			if skillLineID == activeChild then
				return configs[skillLineID] or 0
			end
			return 0
		end
		_G.C_ProfSpecs.GetSpecTabIDsForSkillLine = function(skillLineID)
			return tabs[skillLineID] or {}
		end
		_G.C_ProfSpecs.GetTabInfo = function(tabID)
			return tabInfo[tabID]
		end
		_G.C_ProfSpecs.GetChildrenForPath = function()
			return {}
		end
		_G.C_ProfSpecs.GetPerksForPath = function()
			return {}
		end
		_G.C_ProfSpecs.GetDescriptionForPath = function()
			return ""
		end

		PTS.Controller:SetViewMode("standalone")
		PTS.Controller:SetListening(true)
		PTS.Controller:RebuildIndex()
		assert.are.equal("Midnight Eng Spec", PTS.Controller:GetVisibleRows()[1].name)

		PTS.Controller:SetSkillLine(2801)
		assert.is_true(professionSelected)
		assert.are.equal(2801, PTS.Controller:GetCharDB().lastSkillLineID)
		assert.is_nil(PTS.Controller:GetContext())
		assert.are.equal(0, #PTS.Controller:GetVisibleRows())

		dataReady = true
		assert.is_true(eventHandler ~= nil)
		eventHandler("TRADE_SKILL_LIST_UPDATE")

		assert.are.equal(2801, PTS.Controller:GetContext().skillLineID)
		assert.are.equal("Dragon Eng Spec", PTS.Controller:GetVisibleRows()[1].name)
	end)

	it("standalone expansion switch resolves index after child skill line load", function()
		local PTS = load_addon.pts()
		local activeChild = 2911
		local configs = { [2911] = 111, [2801] = 101 }
		local tabs = {
			[2911] = { 501 },
			[2801] = { 502 },
		}
		local tabInfo = {
			[501] = { rootNodeID = 601, name = "Midnight Eng Spec", description = "" },
			[502] = { rootNodeID = 602, name = "Dragon Eng Spec", description = "" },
		}

		_G.GetProfessions = function()
			return 1
		end
		_G.GetProfessionInfo = function()
			return "Engineering", nil, 1, 100, 0, 0, 202
		end
		_G.Professions = {
			GetProfessionInfo = function()
				return { professionID = activeChild, parentProfessionID = 202 }
			end,
		}
		_G.ProfessionsFrame = {}
		_G.C_TradeSkillUI.GetAllProfessionTradeSkillLines = function()
			return { 2911, 2801 }
		end
		_G.C_TradeSkillUI.GetChildProfessionInfo = function()
			return { professionID = activeChild }
		end
		_G.C_TradeSkillUI.GetBaseProfessionInfo = function()
			return { professionID = 202 }
		end
		_G.C_TradeSkillUI.IsDataSourceChanging = function()
			return false
		end
		_G.C_TradeSkillUI.SetProfessionChildSkillLineID = function(skillLineID)
			activeChild = skillLineID
		end
		_G.C_TradeSkillUI.GetProfessionInfoBySkillLineID = function(skillLineID)
			return {
				professionName = skillLineID == 2911 and "Midnight Engineering" or "Dragon Isles Engineering",
				parentProfessionID = 202,
				sourceCounter = skillLineID == 2911 and 1 or 3,
			}
		end
		_G.C_ProfSpecs.SkillLineHasSpecialization = function()
			return true
		end
		_G.C_ProfSpecs.GetConfigIDForSkillLine = function(skillLineID)
			if skillLineID == activeChild then
				return configs[skillLineID] or 0
			end
			return 0
		end
		_G.C_ProfSpecs.GetSpecTabIDsForSkillLine = function(skillLineID)
			return tabs[skillLineID] or {}
		end
		_G.C_ProfSpecs.GetTabInfo = function(tabID)
			return tabInfo[tabID]
		end
		_G.C_ProfSpecs.GetChildrenForPath = function()
			return {}
		end
		_G.C_ProfSpecs.GetPerksForPath = function()
			return {}
		end
		_G.C_ProfSpecs.GetDescriptionForPath = function()
			return ""
		end

		PTS.Controller:SetViewMode("standalone")
		PTS.Controller:RebuildIndex()
		PTS.Controller:SetSkillLine(2801)

		assert.are.equal(2801, PTS.Controller:GetContext().skillLineID)
	end)
end)
