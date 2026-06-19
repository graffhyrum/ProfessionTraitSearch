dofile("Tests/bootstrap.lua")

describe("ProfessionsHook forward refs", function()
	it("exitIndexOverlay can call updateIndexTab after forward declaration", function()
		local updateIndexTab
		local called = false
		local exitIndexOverlay = function()
			updateIndexTab()
		end
		updateIndexTab = function()
			called = true
		end
		assert.has_no.errors(function()
			exitIndexOverlay()
		end)
		assert.is_true(called)
	end)
end)
