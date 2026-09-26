dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("ProfessionsNavigator navigation seam", function()
	it("test double records resolved target without CreateFrame", function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		load_addon.load("core/SpecNavigation.lua")
		local PTS = load_addon.pts()
		local recorded = {}
		local testNav = {
			Navigate = function(_, row)
				recorded[#recorded + 1] = PTS.SpecNavigation.ResolveTarget(row)
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
		local PTS = load_addon.pts()
		PTS.ProfessionsNavigator:Navigate({
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
		local PTS = load_addon.pts()
		PTS.ProfessionsNavigator:Navigate({
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
		local PTS = load_addon.pts()

		PTS.ProfessionsNavigator:Navigate({
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
		local PTS = load_addon.pts()

		PTS.ProfessionsNavigator:Navigate({
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
		load_addon.load("core/Controller.lua", "ProfessionTraitSearch")
		local PTS = load_addon.pts()
		PTS.Controller:SetViewMode("standalone")

		PTS.ProfessionsNavigator:Navigate({
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

describe("ProfessionsNavigator.GetNavState", function()
	local specTabID = 2
	local recipesTabID = 1
	local tabCalls
	local openTradeSkillCalls
	local openRecipeResponseCalls
	local childSkillLineID
	local baseProfessionID
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
			HookScript = function() end,
		}
	end

	before_each(function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		load_addon.load("core/SpecNavigation.lua")
		tabCalls = {}
		openTradeSkillCalls = {}
		openRecipeResponseCalls = {}
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
		_G.EventRegistry = {
			TriggerEvent = function() end,
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

	it("starts idle with no pending target", function()
		local PTS = load_addon.pts()
		assert.are.equal("idle", PTS.ProfessionsNavigator:GetNavState())
		assert.is_nil(PTS.ProfessionsNavigator:GetPendingNav())
	end)

	it("enters opening with pending target when navigation is deferred", function()
		baseProfessionID = 999
		local PTS = load_addon.pts()
		local row = {
			kind = "tab",
			skillLineID = 2883,
			tabTreeID = 100,
		}

		PTS.ProfessionsNavigator:Navigate(row)

		assert.are.equal("opening", PTS.ProfessionsNavigator:GetNavState())
		assert.are.same({
			skillLineID = 2883,
			tabTreeID = 100,
		}, PTS.ProfessionsNavigator:GetPendingNav())
	end)

	it("passes through applying while finishing deferred navigation", function()
		local PTS = load_addon.pts()
		local navStateDuringApply

		_G.ProfessionsFrame.SetTab = function(_, tabID)
			navStateDuringApply = PTS.ProfessionsNavigator:GetNavState()
			tabCalls[#tabCalls + 1] = tabID
		end

		PTS.ProfessionsNavigator:Navigate({
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
		navFrame:OnEvent("TRADE_SKILL_LIST_UPDATE")

		assert.are.equal("applying", navStateDuringApply)
		assert.are.equal("idle", PTS.ProfessionsNavigator:GetNavState())
		assert.is_nil(PTS.ProfessionsNavigator:GetPendingNav())
	end)

	it("returns idle after immediate same-profession navigation", function()
		childSkillLineID = 2881
		_G.ProfessionsFrame = makeProfessionsFrame(2881, true)
		local PTS = load_addon.pts()

		PTS.ProfessionsNavigator:Navigate({
			kind = "tab",
			skillLineID = 2881,
			tabTreeID = 100,
		})

		assert.are.equal("idle", PTS.ProfessionsNavigator:GetNavState())
		assert.is_nil(PTS.ProfessionsNavigator:GetPendingNav())
	end)
end)

describe("ProfessionsNavigator.SelectSpecPath", function()
	local registryEvents

	before_each(function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		registryEvents = {}
		_G.EventRegistry = {
			TriggerEvent = function(_, event, ...)
				registryEvents[#registryEvents + 1] = {
					event = event,
					args = { ... },
				}
			end,
		}
		load_addon.load("ui/ProfessionsNavigator.lua")
	end)

	it("calls SetDefaultPath, SetDefaultTab, and PathSelected", function()
		local PTS = load_addon.pts()
		local setDefaultPathCalls = {}
		local setDefaultTabCalls = {}
		local specPage = {
			SetDefaultPath = function(_, pathID)
				setDefaultPathCalls[#setDefaultPathCalls + 1] = pathID
			end,
			SetDefaultTab = function(_, tabTreeID)
				setDefaultTabCalls[#setDefaultTabCalls + 1] = tabTreeID
			end,
		}

		PTS.ProfessionsNavigator:SelectSpecPath(specPage, 100, 301)

		assert.are.equal(1, #setDefaultPathCalls)
		assert.are.equal(301, setDefaultPathCalls[1])
		assert.are.equal(1, #setDefaultTabCalls)
		assert.are.equal(100, setDefaultTabCalls[1])
		assert.are.equal(1, #registryEvents)
		assert.are.equal("ProfessionsSpecializations.PathSelected", registryEvents[1].event)
		assert.are.equal(301, registryEvents[1].args[1])
		assert.is_true(registryEvents[1].args[2])
	end)

	it("navigates path rows with TabSelected and PathSelected", function()
		local specTabID = 2
		local recipesTabID = 1
		local tabCalls = {}
		local setDefaultPathCalls = {}
		local setDefaultTabCalls = {}

		_G.CreateFrame = function()
			return {
				RegisterEvent = function() end,
				SetScript = function() end,
			}
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
			IsDataSourceChanging = function()
				return false
			end,
			GetChildProfessionInfo = function()
				return { professionID = 2881 }
			end,
			GetBaseProfessionInfo = function()
				return { professionID = 186 }
			end,
			GetProfessionInfoBySkillLineID = function()
				return { parentProfessionID = 186 }
			end,
		}
		_G.ProfessionsFrame = {
			IsShown = function()
				return true
			end,
			recipesTabID = recipesTabID,
			specializationsTabID = specTabID,
			SpecPage = {
				GetProfessionID = function()
					return 2881
				end,
				SetDefaultPath = function(_, pathID)
					setDefaultPathCalls[#setDefaultPathCalls + 1] = pathID
				end,
				SetDefaultTab = function(_, tabTreeID)
					setDefaultTabCalls[#setDefaultTabCalls + 1] = tabTreeID
				end,
			},
			SetTab = function(_, tabID)
				tabCalls[#tabCalls + 1] = tabID
			end,
			HookScript = function() end,
		}

		load_addon.load("core/SpecNavigation.lua")
		load_addon.load("core/TradeSkillSession.lua")

		local PTS = load_addon.pts()
		PTS.ProfessionsNavigator:Navigate({
			kind = "path",
			skillLineID = 2881,
			tabTreeID = 100,
			pathID = 301,
		})

		local tabSelected
		local pathSelected
		for i = 1, #registryEvents do
			local entry = registryEvents[i]
			if entry.event == "ProfessionsSpecializations.TabSelected" then
				tabSelected = entry.args[1]
			elseif entry.event == "ProfessionsSpecializations.PathSelected" then
				pathSelected = entry.args
			end
		end

		assert.are.equal(100, tabSelected)
		assert.are.same({ 301, true }, pathSelected)
		assert.are.equal(301, setDefaultPathCalls[1])
		assert.are.equal(100, setDefaultTabCalls[1])
		assert.are.equal(specTabID, tabCalls[1])
	end)
end)

describe("ProfessionsNavigator.SetBeforeNavigate", function()
	local specTabID = 2
	local recipesTabID = 1

	local function makeProfessionsFrame(professionID)
		return {
			IsShown = function()
				return true
			end,
			recipesTabID = recipesTabID,
			specializationsTabID = specTabID,
			SpecPage = {
				GetProfessionID = function()
					return professionID
				end,
				SetDefaultPath = function() end,
				SetDefaultTab = function() end,
			},
			SetTab = function() end,
			HookScript = function() end,
		}
	end

	before_each(function()
		load_addon.reset()
		load_addon.load("core/init.lua")
		load_addon.load("core/SpecNavigation.lua")
		_G.CreateFrame = function()
			return {
				RegisterEvent = function() end,
				SetScript = function() end,
			}
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
			IsDataSourceChanging = function()
				return false
			end,
			GetChildProfessionInfo = function()
				return { professionID = 2881 }
			end,
			GetBaseProfessionInfo = function()
				return { professionID = 186 }
			end,
			GetProfessionInfoBySkillLineID = function()
				return { parentProfessionID = 186 }
			end,
		}
		_G.EventRegistry = {
			TriggerEvent = function() end,
			RegisterCallback = function() end,
		}
		_G.ProfessionsFrame = makeProfessionsFrame(2881)
		load_addon.load("core/TradeSkillSession.lua")
		load_addon.load("ui/ProfessionsNavigator.lua")
	end)

	after_each(function()
		_G.ProfessionsFrame = nil
	end)

	it("invokes beforeNavigate with row and resolved target", function()
		local PTS = load_addon.pts()
		local hookCalls = {}
		local row = {
			kind = "path",
			skillLineID = 2881,
			tabTreeID = 100,
			pathID = 301,
		}

		PTS.ProfessionsNavigator:SetBeforeNavigate(function(receivedRow, target)
			hookCalls[#hookCalls + 1] = {
				row = receivedRow,
				target = target,
			}
		end)

		PTS.ProfessionsNavigator:Navigate(row)

		assert.are.equal(1, #hookCalls)
		assert.are.same(row, hookCalls[1].row)
		assert.are.same({
			skillLineID = 2881,
			tabTreeID = 100,
			pathID = 301,
		}, hookCalls[1].target)
	end)

	it("exits index mode via beforeNavigate hook on navigate", function()
		local PTS = load_addon.pts()
		local indexMode = true

		PTS.ProfessionsNavigator:SetBeforeNavigate(function()
			if indexMode then
				indexMode = false
			end
		end)

		PTS.ProfessionsNavigator:Navigate({
			kind = "tab",
			skillLineID = 2881,
			tabTreeID = 100,
		})

		assert.is_false(indexMode)
	end)

	it("ProfessionsHook exits index mode when navigating", function()
		local indexTab
		local popoutShown = false

		_G.CreateFrame = function(_, _, _, template)
			local frame = {
				RegisterEvent = function() end,
				SetScript = function() end,
				HookScript = function() end,
				SetFrameStrata = function() end,
				SetFrameLevel = function() end,
				SetPoint = function() end,
				ClearAllPoints = function() end,
				SetWidth = function() end,
				SetBackdrop = function() end,
				SetBackdropColor = function() end,
				Hide = function()
					popoutShown = false
				end,
				Show = function()
					popoutShown = true
				end,
				IsShown = function()
					return popoutShown
				end,
				SetShown = function(_, shown)
					popoutShown = shown == true
				end,
				SetChecked = function() end,
				Icon = {
					SetTexture = function() end,
					SetSize = function() end,
				},
				SetCustomOnMouseUpHandler = function(_, handler)
					frame._mouseUpHandler = handler
				end,
				tooltipText = nil,
			}
			if template == "LargeSideTabButtonTemplate" then
				indexTab = frame
			end
			return frame
		end

		_G.ProfessionsFrame = {
			IsShown = function()
				return true
			end,
			GetTab = function()
				return specTabID
			end,
			recipesTabID = recipesTabID,
			specializationsTabID = specTabID,
			craftingOrdersTabID = 3,
			SpecPage = {
				GetProfessionID = function()
					return 2881
				end,
				SetDefaultPath = function() end,
				SetDefaultTab = function() end,
			},
			SetTab = function() end,
			HookScript = function() end,
		}

		load_addon.load_core()
		load_addon.load("ui/ProfessionsNavigator.lua")
		load_addon.load("ui/ProfessionsHook.lua")

		local PTS = load_addon.pts()
		PTS.ProfessionsHook:Init()

		assert.is_not_nil(indexTab)
		indexTab:_mouseUpHandler(nil, "LeftButton", true)
		assert.is_true(PTS.ProfessionsHook:IsIndexMode())
		assert.is_true(popoutShown)

		PTS.ProfessionsNavigator:Navigate({
			kind = "tab",
			skillLineID = 2881,
			tabTreeID = 100,
		})

		assert.is_false(PTS.ProfessionsHook:IsIndexMode())
		assert.is_false(popoutShown)
	end)
end)
