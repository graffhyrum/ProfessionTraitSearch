local PTS = _G.ProfessionTraitSearch

local Debounce = {}
PTS.Debounce = Debounce

local pending = {}

function Debounce.After(key, fn)
	if pending[key] then
		pending[key]:Cancel()
	end
	pending[key] = C_Timer.NewTimer(0, function()
		pending[key] = nil
		fn()
	end)
end
