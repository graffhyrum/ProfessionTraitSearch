dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("Controller saved DB", function()
	before_each(function()
		load_addon.reset()
		_G.PerkLensDB = nil
		_G.SpecTraitLensDB = nil
		load_addon.load_core()
	end)

	it("creates PerkLensDB when missing", function()
		local pl = load_addon.pl()
		local db = pl.Controller:GetSavedDB()
		assert.is_true(db ~= nil)
		assert.are.equal(_G.PerkLensDB, db)
	end)

	it("migrates SpecTraitLensDB to PerkLensDB", function()
		_G.SpecTraitLensDB = { minimap = { hide = true } }
		local pl = load_addon.pl()
		local db = pl.Controller:GetSavedDB()
		assert.are.equal(_G.SpecTraitLensDB, db)
		assert.are.equal(_G.PerkLensDB, db)
		assert.is_true(db.minimap.hide)
	end)
end)
