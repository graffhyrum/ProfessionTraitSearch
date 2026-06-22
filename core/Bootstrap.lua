local addonName = ...
local PTS = _G.ProfessionTraitSearch
if not PTS or not PTS.Controller or not PTS.SpecBrowser then
	return
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
	if event ~= "ADDON_LOADED" or name ~= addonName then
		return
	end
	PTS.Controller:ApplyFromSaved()
	PTS.MinimapButton:Init()
	PTS.Slash:Init()
	PTS.ProfessionsHook:Init()
end)
