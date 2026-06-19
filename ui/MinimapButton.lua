local PL = _G.PerkLens

local MinimapButton = {}
PL.MinimapButton = MinimapButton

local ICON = "Interface\\Icons\\INV_Misc_Book_09"

local function tooltipText(tooltip)
	if not tooltip or not tooltip.AddLine then
		return
	end
	tooltip:AddLine("PerkLens")
	tooltip:AddLine("Left-click: specialization index")
	tooltip:AddLine("Right-click: settings")
	local ctx = PL.Controller:GetContext()
	if ctx then
		tooltip:AddLine(ctx.professionName, 0.4, 1, 0.4)
	end
end

function MinimapButton:Init()
	if self.initialized then
		return
	end
	self.initialized = true

	local db = PL.Controller:GetSavedDB()
	db.minimap = db.minimap or { hide = false }

	local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("PerkLens", {
		type = "launcher",
		text = "PerkLens",
		icon = ICON,
		OnClick = function(_, button)
			if button == "RightButton" then
				PL.Settings:Toggle()
			else
				PL.SpecBrowser:ToggleStandalone()
			end
		end,
		OnTooltipShow = tooltipText,
	})

	local icon = LibStub("LibDBIcon-1.0")
	icon:Register("PerkLens", ldb, db.minimap)
	icon:Show("PerkLens")
end
