local addonName = ...
local PL = _G.PerkLens
if not PL or not PL.Controller or not PL.SpecBrowser then
	return
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
	if event ~= "ADDON_LOADED" or name ~= addonName then
		return
	end
	PL.Controller:ApplyFromSaved()
	PL.MinimapButton:Init()
	PL.Slash:Init()
	PL.ProfessionsHook:Init()
end)
