dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("ProfessionsNavigator navigation seam", function()
	it("test double records resolved target without CreateFrame", function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		load_addon.load("core/SpecNavigation.lua")
		local pl = load_addon.pl()
		local recorded = {}
		local testNav = {
			Navigate = function(_, row)
				recorded[#recorded + 1] = pl.SpecNavigation.ResolveTarget(row)
			end,
		}
		testNav:Navigate({
			kind = "tab",
			skillLineID = 2881,
			tabTreeID = 100,
		})
		assert.are.equal(1, #recorded)
		assert.are.equal(2881, recorded[1].skillLineID)
		assert.are.equal(100, recorded[1].tabTreeID)
		assert.is_nil(recorded[1].pathID)
	end)
end)

describe("ProfessionsNavigator.Navigate", function()
	local specTabID = 2
	local recipesTabID = 1
	local tabCalls
	local openTradeSkillCalls
	local showUIPanelCalls
	local openRecipeResponseCalls
	local childSkillLineID
	local baseProfessionID
	local professionSelectedCalls
	local setProfessionInfoCalls

	local createdFrames

	local function makeSpecPage(professionID)
		return {
			GetProfessionID = function()
				return professionID
			end,
			SetDefaultPath = function() end,
			SetDefaultTab = function() end,
		}
	end

	local function makeProfessionsFrame(specPageProfessionID, shown)
		local specPage = makeSpecPage(specPageProfessionID)
		return {
			IsShown = function()
				return shown == true
			end,
			recipesTabID = recipesTabID,
			specializationsTabID = specTabID,
			SpecPage = specPage,
			SetTab = function(_, tabID)
				tabCalls[#tabCalls + 1] = tabID
			end,
			SetOpenRecipeResponse = function(_, skillLineID, recipeID, openSpecTab)
				openRecipeResponseCalls[#openRecipeResponseCalls + 1] = {
					skillLineID = skillLineID,
					recipeID = recipeID,
					openSpecTab = openSpecTab,
				}
			end,
			SetProfessionInfo = function(_, professionInfo, useLastSkillLine)
				setProfessionInfoCalls[#setProfessionInfoCalls + 1] = {
					professionInfo = professionInfo,
					useLastSkillLine = useLastSkillLine,
				}
			end,
			HookScript = function() end,
		}
	end

	before_each(function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		load_addon.load("core/SpecNavigation.lua")
		tabCalls = {}
		openTradeSkillCalls = {}
		showUIPanelCalls = {}
		openRecipeResponseCalls = {}
		professionSelectedCalls = {}
		setProfessionInfoCalls = {}
		childSkillLineID = 2881
		baseProfessionID = 186
		createdFrames = {}

		_G.CreateFrame = function()
			local frame = {
				RegisterEvent = function(self, event)
					self.event = event
				end,
				SetScript = function(self, name, fn)
					self[name] = fn
				end,
			}
			createdFrames[#createdFrames + 1] = frame
			return frame
		end
		_G.RunNextFrame = function(fn)
			fn()
		end
		_G.C_AddOns = {
			IsAddOnLoaded = function()
				return true
			end,
			LoadAddOn = function() end,
		}
		_G.C_TradeSkillUI = {
			OpenTradeSkill = function(skillLineID)
				openTradeSkillCalls[#openTradeSkillCalls + 1] = skillLineID
			end,
			IsDataSourceChanging = function()
				return false
			end,
			GetChildProfessionInfo = function()
				return { professionID = childSkillLineID }
			end,
			GetBaseProfessionInfo = function()
				return { professionID = baseProfessionID }
			end,
			GetProfessionInfoBySkillLineID = function(skillLineID)
				return {
					parentProfessionID = 186,
					professionName = "Profession " .. tostring(skillLineID),
				}
			end,
			SetProfessionChildSkillLineID = function(skillLineID)
				childSkillLineID = skillLineID
			end,
		}
		_G.ShowUIPanel = function(frame)
			showUIPanelCalls[#showUIPanelCalls + 1] = frame
		end
		_G.EventRegistry = {
			TriggerEvent = function(_, event, payload)
				if event == "Professions.ProfessionSelected" then
					professionSelectedCalls[#professionSelectedCalls + 1] = payload
				end
			end,
			RegisterCallback = function() end,
		}
		_G.Professions = {
			GetProfessionInfo = function()
				return {
					professionID = childSkillLineID,
					parentProfessionID = baseProfessionID,
				}
			end,
		}

		load_addon.load("core/TradeSkillSession.lua")
		load_addon.load("ui/ProfessionsNavigator.lua")
		_G.ProfessionsFrame = makeProfessionsFrame(2881, false)
	end)

	after_each(function()
		_G.ProfessionsFrame = nil
	end)

	it("uses Blizzard deferred open for a different profession", function()
		baseProfessionID = 999
		local pl = load_addon.pl()
		pl.ProfessionsNavigator:Navigate({
			kind = "tab",
			skillLineID = 2883,
			tabTreeID = 100,
		})

		assert.are.equal(1, #openRecipeResponseCalls)
		assert.are.equal(2883, openRecipeResponseCalls[1].skillLineID)
		assert.is_true(openRecipeResponseCalls[1].openSpecTab)
		assert.are.equal(1, #openTradeSkillCalls)
		assert.are.equal(186, openTradeSkillCalls[1])
		assert.are.equal(0, #showUIPanelCalls)
		assert.are.equal(0, #tabCalls)
	end)

	it("selects spec tab after profession switch completes", function()
		local pl = load_addon.pl()
		pl.ProfessionsNavigator:Navigate({
			kind = "tab",
			skillLineID = 2883,
			tabTreeID = 100,
		})

		_G.ProfessionsFrame.SpecPage.GetProfessionID = function()
			return 2883
		end

		local navFrame
		for i = 1, #createdFrames do
			if createdFrames[i].event == "TRADE_SKILL_LIST_UPDATE" then
				navFrame = createdFrames[i]
				break
			end
		end
		assert.is_true(navFrame ~= nil)
		navFrame:OnEvent("TRADE_SKILL_LIST_UPDATE")

		assert.are.equal(specTabID, tabCalls[#tabCalls])
	end)

	it("switches expansion within the same parent profession", function()
		childSkillLineID = 2881
		baseProfessionID = 186
		local pl = load_addon.pl()

		pl.ProfessionsNavigator:Navigate({
			kind = "tab",
			skillLineID = 2883,
			tabTreeID = 100,
		})

		assert.are.equal(0, #openRecipeResponseCalls)
		assert.are.equal(0, #openTradeSkillCalls)
		assert.are.equal(1, #professionSelectedCalls)
		assert.is_true(professionSelectedCalls[1].openSpecTab)
		assert.are.equal(2883, childSkillLineID)
	end)

	it("navigates immediately when frame is shown for same profession", function()
		childSkillLineID = 2881
		_G.ProfessionsFrame = makeProfessionsFrame(2881, true)
		local pl = load_addon.pl()

		pl.ProfessionsNavigator:Navigate({
			kind = "tab",
			skillLineID = 2881,
			tabTreeID = 100,
		})

		assert.are.equal(0, #openTradeSkillCalls)
		assert.are.equal(0, #showUIPanelCalls)
		assert.are.equal(0, #openRecipeResponseCalls)
		assert.are.equal(specTabID, tabCalls[1])
	end)

	it("standalone uses synchronous expansion refresh for same parent profession", function()
		childSkillLineID = 2881
		baseProfessionID = 186
		load_addon.load("core/TradeSkillSession.lua")
		load_addon.load("core/Controller.lua", "PerkLens")
		local pl = load_addon.pl()
		pl.Controller:SetViewMode("standalone")

		pl.ProfessionsNavigator:Navigate({
			kind = "tab",
			skillLineID = 2883,
			tabTreeID = 100,
		})

		assert.are.equal(2883, childSkillLineID)
		assert.are.equal(0, #openRecipeResponseCalls)
		assert.are.equal(0, #openTradeSkillCalls)
		assert.are.equal(0, #professionSelectedCalls)
		assert.are.equal(1, #setProfessionInfoCalls)
		assert.is_false(setProfessionInfoCalls[1].useLastSkillLine)
		assert.is_true(setProfessionInfoCalls[1].professionInfo.openSpecTab)
	end)
end)
