dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("Controller saved DB", function()
	before_each(function()
		load_addon.reset()
		_G.ProfessionTraitSearchDB = nil
		_G.PerkLensDB = nil
		_G.SpecTraitLensDB = nil
		load_addon.load_core()
	end)

	it("creates ProfessionTraitSearchDB when missing", function()
		local pts = load_addon.pts()
		local db = pts.Controller:GetSavedDB()
		assert.is_true(db ~= nil)
		assert.are.equal(_G.ProfessionTraitSearchDB, db)
	end)

	it("migrates SpecTraitLensDB to ProfessionTraitSearchDB", function()
		_G.SpecTraitLensDB = { minimap = { hide = true } }
		local pts = load_addon.pts()
		local db = pts.Controller:GetSavedDB()
		assert.are.equal(_G.SpecTraitLensDB, db)
		assert.are.equal(_G.ProfessionTraitSearchDB, db)
		assert.is_true(db.minimap.hide)
	end)

	it("migrates PerkLensDB to ProfessionTraitSearchDB", function()
		_G.PerkLensDB = { minimap = { hide = true } }
		local pts = load_addon.pts()
		local db = pts.Controller:GetSavedDB()
		assert.are.equal(_G.PerkLensDB, db)
		assert.are.equal(_G.ProfessionTraitSearchDB, db)
		assert.is_true(db.minimap.hide)
	end)

	it("migrates majorPipsOnly to majorPerksOnly", function()
		_G.UnitGUID = function() return "test-guid" end
		_G.ProfessionTraitSearchDB = { char = { ["test-guid"] = { majorPipsOnly = true } } }
		local pts = load_addon.pts()
		local charDB = pts.Controller:GetCharDB()
		assert.is_true(charDB.majorPerksOnly)
		assert.is_nil(charDB.majorPipsOnly)
	end)
end)
