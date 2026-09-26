local PTS = _G.ProfessionTraitSearch

local SpecBrowser = {}
PTS.SpecBrowser = SpecBrowser

local FRAME_WIDTH = 540
local FRAME_HEIGHT = 660
local FRAME_MIN_WIDTH = 420
local FRAME_MIN_HEIGHT = 360
local FRAME_MAX_WIDTH = 960
local FRAME_MAX_HEIGHT = 900
local POPOUT_WIDTH = 380
local POPOUT_BACKDROP = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 11, top = 11, bottom = 11 },
}
local FILTER_GAP = 7
local CHECKBOX_GAP = 6
local SEARCH_LABEL_GAP = 8
local STANDALONE_SEARCH_WIDTH = 240
local PADDING_X = 14
local ROW_GAP = 6
local INDENT = 18
local FOLD_BTN_SIZE = 16
local FOLD_BTN_GAP = 4
local ROW_TEXT_OFFSET = FOLD_BTN_SIZE + FOLD_BTN_GAP
local FOLD_TOGGLE_WIDTH = 96
local FOLD_TOGGLE_GAP = 8
local EXPAND_TEX = "Interface\\Buttons\\UI-PlusButton-UP"
local COLLAPSE_TEX = "Interface\\Buttons\\UI-MinusButton-UP"
local TEXT_GAP = 3
local CONTENT_WIDTH = 460
local BADGE_GAP = 8
local MIN_TEXT_WIDTH = 48
local SCROLLBAR_GUTTER = 26

local instances = {}

local function initProfessionDropdown(_, level)
	if level ~= 1 then
		return
	end
	local ctx = PTS.Controller:GetContext()
	local currentID = ctx and ctx.skillLineID
	for _, prof in ipairs(PTS.Controller:ListProfessions()) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = prof.professionName
		info.value = prof.skillLineID
		info.checked = prof.skillLineID == currentID
		info.arg1 = prof.skillLineID
		info.func = function(_, skillLineID)
			PTS.Controller:SetSkillLine(skillLineID)
		end
		UIDropDownMenu_AddButton(info)
	end
end

local function refreshProfessionSelector(browser)
	if browser.isPopout then
		browser.profDropdown:Hide()
		browser.header:Show()
		local ctx = PTS.Controller:GetContext()
		if ctx then
			browser.header:SetText(ctx.professionName or "Profession")
		else
			browser.header:SetText("Specialization Index")
		end
		return
	end

	local professions = PTS.Controller:ListProfessions()
	local ctx = PTS.Controller:GetContext()

	if #professions <= 1 then
		browser.profDropdown:Hide()
		browser.header:Show()
		if ctx then
			browser.header:SetText(ctx.professionName or "Profession")
		elseif professions[1] then
			browser.header:SetText(professions[1].professionName or "Profession")
		else
			browser.header:SetText("No profession specialization available")
		end
		return
	end

	browser.header:Hide()
	browser.profDropdown:Show()
	local selectedID = ctx and ctx.skillLineID or professions[1].skillLineID
	local selectedName = ctx and ctx.professionName or professions[1].professionName
	UIDropDownMenu_SetSelectedValue(browser.profDropdown, selectedID)
	UIDropDownMenu_SetText(browser.profDropdown, selectedName)
end

local function detailAfterTitle(title, body)
	body = body or ""
	title = title or ""
	if body == "" or body == title then
		return nil
	end
	if body:sub(1, #title) == title then
		local rest = strtrim(body:sub(#title + 1))
		if rest:sub(1, 1) == "\n" then
			rest = strtrim(rest:sub(2))
		end
		if rest == "" then
			return nil
		end
		return rest
	end
	return body
end

local function setWrappedHeight(fontString, width, text)
	fontString:SetWidth(width)
	if text and text ~= "" then
		fontString:SetText(text)
		fontString:Show()
		return fontString:GetStringHeight() + TEXT_GAP
	end
	fontString:SetText("")
	fontString:Hide()
	return 0
end

local function createRow(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:EnableMouse(true)

	f.bg = f:CreateTexture(nil, "BACKGROUND")
	f.bg:SetPoint("TOPLEFT", 0, 0)
	f.bg:SetPoint("BOTTOMRIGHT", 0, 0)

	f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.name:SetPoint("TOPLEFT", PADDING_X, -6)
	f.name:SetJustifyH("LEFT")
	f.name:SetWordWrap(true)

	f.detail = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.detail:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -TEXT_GAP)
	f.detail:SetJustifyH("LEFT")
	f.detail:SetTextColor(PTS.IndexRow.DetailColor())
	f.detail:SetWordWrap(true)

	f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.badge:SetPoint("TOPRIGHT", -PADDING_X, -6)
	f.badge:SetJustifyH("RIGHT")
	f.badge:SetTextColor(1, 1, 1)

	local foldBtn = CreateFrame("Button", nil, f)
	foldBtn:SetSize(FOLD_BTN_SIZE, FOLD_BTN_SIZE)
	foldBtn:SetPoint("TOPLEFT", 0, -6)
	foldBtn.icon = foldBtn:CreateTexture(nil, "ARTWORK")
	foldBtn.icon:SetAllPoints()
	foldBtn:Hide()
	foldBtn:SetScript("OnClick", function(self)
		if self.rowKey then
			PTS.Controller:ToggleFold(self.rowKey)
		end
	end)
	f.foldBtn = foldBtn

	f:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and self.row then
			PTS.ProfessionsNavigator:Navigate(self.row)
		end
	end)
	f:SetScript("OnEnter", function(self)
		if not self.row then
			return
		end
		local view = PTS.IndexRow.BuildView(self.row)
		local tint = view.tint
		self.bg:SetColorTexture(
			math.min(tint[1] + 0.1, 1),
			math.min(tint[2] + 0.1, 1),
			math.min(tint[3] + 0.1, 1),
			math.min(tint[4] + 0.12, 0.4)
		)
	end)
	f:SetScript("OnLeave", function(self)
		if not self.row then
			return
		end
		local view = PTS.IndexRow.BuildView(self.row)
		local tint = view.tint
		self.bg:SetColorTexture(tint[1], tint[2], tint[3], tint[4])
	end)

	return f
end

local function measureBadgeReserve(badgeFontString)
	local text = badgeFontString:GetText()
	if not text or text == "" then
		return 0
	end
	return (badgeFontString:GetStringWidth() or 0) + BADGE_GAP
end

local function scrollContentWidth(scroll)
	local width = scroll and scroll:GetWidth()
	if not width or width <= 0 then
		return CONTENT_WIDTH
	end
	return math.max(width - SCROLLBAR_GUTTER - 8, MIN_TEXT_WIDTH + 80)
end

local function rowLineIndent(row)
	return (row.depth or 0) * INDENT
end

local function updateFoldButton(rowFrame, row)
	local foldBtn = rowFrame.foldBtn
	if row.kind ~= "tab" and row.kind ~= "path" then
		foldBtn:Hide()
		return
	end

	local lineIndent = rowLineIndent(row)
	foldBtn:ClearAllPoints()
	foldBtn:SetPoint("TOPLEFT", lineIndent, -6)
	foldBtn.rowKey = row.rowKey
	local collapsed = PTS.Controller:IsFoldCollapsed(row.rowKey)
	foldBtn.icon:SetTexture(collapsed and EXPAND_TEX or COLLAPSE_TEX)
	foldBtn:Show()
end

local function populateRow(rowFrame, row, innerWidth)
	local view = PTS.IndexRow.BuildView(row)
	local r, g, b = view.titleColor[1], view.titleColor[2], view.titleColor[3]
	local tint = view.tint

	rowFrame.bg:SetColorTexture(tint[1], tint[2], tint[3], tint[4])
	rowFrame.name:SetTextColor(r, g, b)
	rowFrame.badge:SetText("")

	local dr, dg, db = PTS.IndexRow.DetailColor()
	rowFrame.detail:SetTextColor(dr, dg, db)
	local nameText = view.displayName
	local detailText = detailAfterTitle(nameText, row.description)
	local minH = view.minHeight

	rowFrame.name:SetFontObject(view.fontObject)

	updateFoldButton(rowFrame, row)
	local textLeft = rowLineIndent(row) + ROW_TEXT_OFFSET

	if view.pathRankBadge then
		rowFrame.badge:SetText(view.pathRankBadge)
	elseif row.kind == "perk" then
		rowFrame.badge:SetText(view.perkBadgeText)
	end
	if view.badgeColor then
		rowFrame.badge:SetTextColor(view.badgeColor[1], view.badgeColor[2], view.badgeColor[3])
	end

	local badgeReserve = measureBadgeReserve(rowFrame.badge)
	local textWidth = innerWidth - textLeft - PADDING_X - badgeReserve
	textWidth = math.max(MIN_TEXT_WIDTH, textWidth)

	rowFrame.name:ClearAllPoints()
	rowFrame.name:SetPoint("TOPLEFT", textLeft, -6)
	rowFrame.name:SetWidth(textWidth)
	rowFrame.name:SetText(nameText)

	local nameH = rowFrame.name:GetStringHeight() + TEXT_GAP
	local detailH = 0
	if detailText then
		detailH = setWrappedHeight(rowFrame.detail, textWidth, detailText)
	else
		rowFrame.detail:Hide()
	end

	return math.max(minH, 6 + nameH + detailH + 6)
end

local function layoutRows(browser)
	local rows = PTS.Controller:GetVisibleRows()
	local content = browser.content
	local innerWidth = browser.contentWidth or CONTENT_WIDTH
	local y = 4
	local pool = browser.pool
	local used = 0

	content:SetWidth(innerWidth)

	for i = 1, #rows do
		used = used + 1
		local rowFrame = pool[used]
		if not rowFrame then
			rowFrame = createRow(content)
			pool[used] = rowFrame
		end

		local row = rows[i]
		local h = populateRow(rowFrame, row, innerWidth)

		rowFrame:ClearAllPoints()
		rowFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
		rowFrame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
		rowFrame:SetHeight(h)
		rowFrame:Show()
		rowFrame.row = row

		y = y + h + ROW_GAP
	end

	for i = used + 1, #pool do
		pool[i]:Hide()
	end

	content:SetHeight(math.max(y, 1))
end

local function layoutRowsWithContentWidth(browser)
	if browser.scroll then
		browser.contentWidth = scrollContentWidth(browser.scroll)
	end
	layoutRows(browser)
end

local function checkboxLabelWidth(checkbox)
	return 24 + (checkbox.text:GetStringWidth() or 0)
end

local function clampSize(width, height)
	local w = math.max(FRAME_MIN_WIDTH, math.min(FRAME_MAX_WIDTH, width or FRAME_WIDTH))
	local h = math.max(FRAME_MIN_HEIGHT, math.min(FRAME_MAX_HEIGHT, height or FRAME_HEIGHT))
	return w, h
end

local function saveStandaloneSize(browser)
	local charDB = PTS.Controller:GetCharDB()
	charDB.standaloneWidth = browser:GetWidth()
	charDB.standaloneHeight = browser:GetHeight()
end

local function layoutStandaloneFilters(browser)
	local frameWidth = browser:GetWidth() or FRAME_WIDTH
	local search = browser.search
	local major = browser.major
	local unearned = browser.unearned
	local foldToggle = browser.foldToggle
	local searchLabel = browser.searchLabel
	local rightInset = 36

	searchLabel:Show()
	searchLabel:ClearAllPoints()
	searchLabel:SetPoint("TOPLEFT", 18, -74)

	local labelWidth = searchLabel:GetStringWidth() + 8
	local filtersWidth = checkboxLabelWidth(major) + CHECKBOX_GAP + checkboxLabelWidth(unearned)
	local singleRowNeed = 18
		+ labelWidth
		+ SEARCH_LABEL_GAP
		+ STANDALONE_SEARCH_WIDTH
		+ FILTER_GAP
		+ filtersWidth
		+ FOLD_TOGGLE_GAP
		+ FOLD_TOGGLE_WIDTH
		+ rightInset
	local twoRow = frameWidth < singleRowNeed
	local availableSearch = frameWidth - 18 - rightInset - labelWidth - SEARCH_LABEL_GAP
	local searchWidth = math.max(120, math.min(STANDALONE_SEARCH_WIDTH, availableSearch))

	search:ClearAllPoints()
	search:SetSize(searchWidth, 22)
	search:SetPoint("LEFT", searchLabel, "RIGHT", SEARCH_LABEL_GAP, 0)

	foldToggle:ClearAllPoints()
	foldToggle:SetSize(FOLD_TOGGLE_WIDTH, 22)

	if twoRow then
		major:ClearAllPoints()
		major:SetPoint("TOPLEFT", 18, -98)
		unearned:ClearAllPoints()
		unearned:SetPoint("LEFT", major.text, "RIGHT", CHECKBOX_GAP, 0)
		foldToggle:SetPoint("LEFT", unearned.text, "RIGHT", FOLD_TOGGLE_GAP, 0)
		return 122
	end

	major:ClearAllPoints()
	major:SetPoint("LEFT", search, "RIGHT", FILTER_GAP, 0)
	unearned:ClearAllPoints()
	unearned:SetPoint("LEFT", major.text, "RIGHT", CHECKBOX_GAP, 0)
	foldToggle:SetPoint("LEFT", unearned.text, "RIGHT", FOLD_TOGGLE_GAP, 0)
	return 98
end

local function layoutPopoutFilters(browser)
	local search = browser.search
	local major = browser.major
	local unearned = browser.unearned
	local foldToggle = browser.foldToggle
	local searchLabel = browser.searchLabel

	searchLabel:Show()
	searchLabel:ClearAllPoints()
	searchLabel:SetPoint("TOPLEFT", 12, -52)

	local labelWidth = searchLabel:GetStringWidth() + 8
	local availableSearch = POPOUT_WIDTH - 24 - labelWidth - SEARCH_LABEL_GAP
	local searchWidth = math.max(120, availableSearch)

	search:ClearAllPoints()
	search:SetSize(searchWidth, 22)
	search:SetPoint("LEFT", searchLabel, "RIGHT", SEARCH_LABEL_GAP, 0)

	major:ClearAllPoints()
	major:SetPoint("TOPLEFT", 12, -76)
	unearned:ClearAllPoints()
	unearned:SetPoint("LEFT", major.text, "RIGHT", CHECKBOX_GAP, 0)

	foldToggle:ClearAllPoints()
	foldToggle:SetSize(FOLD_TOGGLE_WIDTH, 22)
	foldToggle:SetPoint("TOPLEFT", 12, -100)

	return 124
end

local function applyChromeLayout(browser)
	local search = browser.search
	local major = browser.major
	local unearned = browser.unearned
	local divider = browser.divider
	local scrollBg = browser.scrollBg
	local scroll = browser.scroll

	if browser.isPopout then
		local filterBottom = layoutPopoutFilters(browser)

		divider:ClearAllPoints()
		divider:SetPoint("TOPLEFT", 12, -(filterBottom + 2))
		divider:SetPoint("TOPRIGHT", -12, -(filterBottom + 2))
		divider:SetHeight(1)

		scrollBg:ClearAllPoints()
		scrollBg:SetPoint("TOPLEFT", 10, -(filterBottom + 6))
		scrollBg:SetPoint("BOTTOMRIGHT", -10, 10)

		scroll:ClearAllPoints()
		scroll:SetPoint("TOPLEFT", 14, -(filterBottom + 10))
		scroll:SetPoint("BOTTOMRIGHT", -30, 14)
		return
	end

	browser.kpLabel:Show()

	local filterBottom = layoutStandaloneFilters(browser)

	divider:ClearAllPoints()
	divider:SetPoint("TOPLEFT", 12, -(filterBottom + 2))
	divider:SetPoint("TOPRIGHT", -12, -(filterBottom + 2))
	divider:SetHeight(1)

	scrollBg:ClearAllPoints()
	scrollBg:SetPoint("TOPLEFT", 10, -(filterBottom + 6))
	scrollBg:SetPoint("BOTTOMRIGHT", -10, 36)

	scroll:ClearAllPoints()
	scroll:SetPoint("TOPLEFT", 14, -(filterBottom + 10))
	scroll:SetPoint("BOTTOMRIGHT", -30, 40)
end

local function buildChrome(browser)
	if browser.built then
		return
	end
	browser.built = true

	if not browser.isPopout then
		local headerBg = browser:CreateTexture(nil, "BACKGROUND", nil, 1)
		headerBg:SetColorTexture(0.04, 0.04, 0.06, 0.85)
		headerBg:SetPoint("TOPLEFT", 10, -10)
		headerBg:SetPoint("TOPRIGHT", -10, -10)
		headerBg:SetHeight(52)
		browser.headerBg = headerBg
	end

	local header = browser:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 18, -18)
	header:SetTextColor(PTS.IndexRow.HeaderColor())
	browser.header = header

	local profDropdown = CreateFrame("Frame", nil, browser, "UIDropDownMenuTemplate")
	profDropdown:SetPoint("TOPLEFT", 14, -12)
	UIDropDownMenu_SetWidth(profDropdown, 220)
	UIDropDownMenu_Initialize(profDropdown, initProfessionDropdown)
	profDropdown:Hide()
	browser.profDropdown = profDropdown

	local kpLabel = browser:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	kpLabel:SetPoint("TOPRIGHT", -36, -20)
	kpLabel:SetTextColor(PTS.IndexRow.DetailColor())
	browser.kpLabel = kpLabel

	local divider = browser:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(0.45, 0.38, 0.2, 0.55)
	divider:SetPoint("TOPLEFT", 12, -62)
	divider:SetPoint("TOPRIGHT", -12, -62)
	divider:SetHeight(1)
	browser.divider = divider

	local searchLabel = browser:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	searchLabel:SetPoint("TOPLEFT", 18, -74)
	searchLabel:SetText("Search")
	searchLabel:SetTextColor(PTS.IndexRow.DetailColor())
	browser.searchLabel = searchLabel

	local search = CreateFrame("EditBox", nil, browser, "InputBoxTemplate")
	search:SetSize(STANDALONE_SEARCH_WIDTH, 22)
	search:SetPoint("LEFT", searchLabel, "RIGHT", SEARCH_LABEL_GAP, 0)
	search:SetAutoFocus(false)
	search:SetScript("OnTextChanged", function(self)
		PTS.Controller:SetSearchText(self:GetText())
	end)
	search:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	browser.search = search

	local major = CreateFrame("CheckButton", nil, browser, "UICheckButtonTemplate")
	major:SetPoint("LEFT", search, "RIGHT", FILTER_GAP, 0)
	major.text = major:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	major.text:SetPoint("LEFT", major, "RIGHT", 0, 0)
	major.text:SetText("Major perks")
	major:SetScript("OnClick", function(self)
		PTS.Controller:SetMajorPerksOnly(self:GetChecked())
	end)
	browser.major = major

	local unearned = CreateFrame("CheckButton", nil, browser, "UICheckButtonTemplate")
	unearned:SetPoint("LEFT", major.text, "RIGHT", CHECKBOX_GAP, 0)
	unearned.text = unearned:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	unearned.text:SetPoint("LEFT", unearned, "RIGHT", 0, 0)
	unearned.text:SetText("Unearned")
	unearned:SetScript("OnClick", function(self)
		PTS.Controller:SetUnearnedOnly(self:GetChecked())
	end)
	browser.unearned = unearned

	local foldToggle = CreateFrame("Button", nil, browser, "UIPanelButtonTemplate")
	foldToggle:SetText("Collapse all")
	foldToggle:SetScript("OnClick", function()
		PTS.Controller:ToggleFoldAll()
	end)
	browser.foldToggle = foldToggle

	local scrollBg = browser:CreateTexture(nil, "BACKGROUND", nil, 0)
	scrollBg:SetColorTexture(0.02, 0.02, 0.03, 0.55)
	scrollBg:SetPoint("TOPLEFT", 10, -100)
	scrollBg:SetPoint("BOTTOMRIGHT", -10, 10)
	browser.scrollBg = scrollBg

	local scroll = CreateFrame("ScrollFrame", nil, browser, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 14, -104)
	scroll:SetPoint("BOTTOMRIGHT", -30, 14)
	browser.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	content:SetWidth(CONTENT_WIDTH)
	scroll:SetScrollChild(content)
	browser.content = content
	browser.contentWidth = CONTENT_WIDTH
	browser.pool = {}

	applyChromeLayout(browser)

	PTS.Controller.RegisterCallback(function()
		if browser:IsShown() then
			SpecBrowser:Update(browser)
		end
	end)
end

function SpecBrowser:Update(browser)
	buildChrome(browser)
	applyChromeLayout(browser)
	refreshProfessionSelector(browser)
	if browser.isPopout then
		browser.kpLabel:Hide()
	else
		local ctx = PTS.Controller:GetContext()
		local kp = PTS.Controller:GetKnowledgeAvailable()
		browser.kpLabel:Show()
		local kr, kg, kb = PTS.IndexRow.KnowledgeLabelColor(kp)
		browser.kpLabel:SetTextColor(kr, kg, kb)
		if ctx then
			browser.kpLabel:SetText("Knowledge available: " .. kp)
		else
			browser.kpLabel:SetText("")
		end
	end
	browser.search:SetText(PTS.Controller:GetSearchText())
	browser.major:SetChecked(PTS.Controller:GetMajorPerksOnly())
	browser.unearned:SetChecked(PTS.Controller:GetUnearnedOnly())
	browser.foldToggle:SetText(PTS.Controller:GetFoldToggleLabel())

	layoutRowsWithContentWidth(browser)
end

local function attachStandaloneSizer(browser)
	if browser.sizer then
		return
	end

	browser:SetResizable(true)
	local sizer = CreateFrame("Button", nil, browser)
	sizer:SetSize(16, 16)
	sizer:SetPoint("BOTTOMRIGHT", -10, 10)
	sizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	sizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	sizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	sizer:SetScript("OnMouseDown", function()
		browser:StartSizing("BOTTOMRIGHT")
	end)
	sizer:SetScript("OnMouseUp", function()
		browser:StopMovingOrSizing()
		saveStandaloneSize(browser)
	end)
	browser.sizer = sizer
end

function SpecBrowser:CreateStandalone()
	if self.standalone then
		return self.standalone
	end
	local f = CreateFrame("Frame", "ProfessionTraitSearchBrowser", UIParent, "BackdropTemplate")
	local charDB = PTS.Controller:GetCharDB()
	local initialWidth, initialHeight = clampSize(charDB.standaloneWidth, charDB.standaloneHeight)
	f:SetSize(initialWidth, initialHeight)
	f:SetPoint("CENTER")
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 11, top = 11, bottom = 11 },
	})
	f:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
	f:Hide()
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetScript("OnSizeChanged", function(self, width, height)
		local w, h = clampSize(width, height)
		if w ~= width or h ~= height then
			self:SetSize(w, h)
			return
		end
		if self:IsShown() then
			SpecBrowser:Update(self)
		end
	end)
	tinsert(UISpecialFrames, f:GetName())
	attachStandaloneSizer(f)
	f:SetScript("OnShow", function()
		PTS.ProfessionsHook:NotifyBrowserShown()
		PTS.Controller:Refresh()
		SpecBrowser:Update(f)
	end)
	f:SetScript("OnHide", function()
		PTS.ProfessionsHook:NotifyBrowserHidden()
	end)

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)

	f.isPopout = false
	self.standalone = f
	instances[#instances + 1] = f
	return f
end

function SpecBrowser:CreatePopout(professionsFrame)
	if self.popout then
		return self.popout
	end
	local f = CreateFrame("Frame", "ProfessionTraitSearchPopout", professionsFrame, "BackdropTemplate")
	f:SetWidth(POPOUT_WIDTH)
	f:SetPoint("TOPLEFT", professionsFrame, "TOPRIGHT", 0, 0)
	f:SetPoint("BOTTOMLEFT", professionsFrame, "BOTTOMRIGHT", 0, 0)
	f:SetBackdrop(POPOUT_BACKDROP)
	f:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(10)
	f:Hide()
	f.isPopout = true
	f:SetScript("OnShow", function()
		PTS.ProfessionsHook:NotifyBrowserShown()
		PTS.Controller:Refresh()
		SpecBrowser:Update(f)
	end)
	f:SetScript("OnHide", function()
		PTS.ProfessionsHook:NotifyBrowserHidden()
	end)
	self.popout = f
	instances[#instances + 1] = f
	return f
end

function SpecBrowser:ToggleStandalone()
	local f = self:CreateStandalone()
	if f:IsShown() then
		f:Hide()
	else
		self:Update(f)
		f:Show()
	end
end

function SpecBrowser:ShowStandalone(searchText)
	local f = self:CreateStandalone()
	if searchText then
		PTS.Controller:SetSearchText(searchText)
	end
	self:Update(f)
	f:Show()
end

function SpecBrowser:HideStandalone()
	if self.standalone then
		self.standalone:Hide()
	end
end

function SpecBrowser:SetPopoutVisible(visible)
	local popout = self.popout
	if not popout then
		return
	end
	if visible then
		self:Update(popout)
		popout:Show()
	else
		popout:Hide()
	end
end
