local PL = _G.PerkLens

local Settings = {}
PL.Settings = Settings

local frame

local function buildFrame()
	if frame then
		return frame
	end
	frame = CreateFrame("Frame", "PerkLensSettings", UIParent, "BackdropTemplate")
	frame:SetSize(360, 200)
	frame:SetPoint("CENTER")
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:Hide()
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText("PerkLens")

	local about = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	about:SetPoint("TOPLEFT", 24, -52)
	about:SetWidth(312)
	about:SetJustifyH("LEFT")
	about:SetText(
		"Searchable specialization index for profession specs. "
			.. "Open with /pl or the minimap button. "
			.. "Toggle Specialization Index on the Professions Specializations page."
	)

	local openBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	openBtn:SetSize(140, 24)
	openBtn:SetPoint("BOTTOM", 0, 24)
	openBtn:SetText("Open Browser")
	openBtn:SetScript("OnClick", function()
		PL.SpecBrowser:ShowStandalone()
	end)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	return frame
end

function Settings:Toggle()
	buildFrame()
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

function Settings:Hide()
	if frame then
		frame:Hide()
	end
end
