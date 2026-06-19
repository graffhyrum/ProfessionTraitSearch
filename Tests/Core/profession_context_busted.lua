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
		saved[key] = _G.PerkLens.ProfessionContext[key]
		_G.PerkLens.ProfessionContext[key] = replacement
	end
	local ok, err = pcall(fn)
	for key, original in pairs(saved) do
		_G.PerkLens.ProfessionContext[key] = original
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
			local pl = load_addon.pl()
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
				local resolved = pl.ProfessionContext.ResolveForIndex(case.charDB, case.preferActive)
				if case.want == nil then
					assert.is_nil(resolved)
				else
					assert.is_true(resolved ~= nil)
					assert.are.equal(case.want, resolved.skillLineID)
				end
			end)
		end)
	end
end)

describe("Controller ViewMode", function()
	before_each(function()
		load_addon.reset()
		_G.PerkLensDB = nil
		load_addon.load_core()
	end)

	it("embedded view mode prefers active profession context", function()
		local pl = load_addon.pl()
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
			pl.Controller:SetViewMode("embedded")
			pl.Controller:GetCharDB().lastSkillLineID = 2002
			pl.Controller:RebuildIndex()
			assert.are.equal(2001, pl.Controller:GetContext().skillLineID)
		end)
	end)

	it("closed view mode prefers saved skill line over active", function()
		local pl = load_addon.pl()
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
			pl.Controller:SetViewMode("closed")
			pl.Controller:GetCharDB().lastSkillLineID = 2002
			pl.Controller:RebuildIndex()
			assert.are.equal(2002, pl.Controller:GetContext().skillLineID)
		end)
	end)

	it("does not call ProfessionsHook for context policy", function()
		local pl = load_addon.pl()
		pl.ProfessionsHook = {
			IsIndexMode = function()
				error("core must not call ProfessionsHook:IsIndexMode")
			end,
		}
		pl.Controller:SetViewMode("embedded")
		pl.Controller:RebuildIndex()
	end)
end)
