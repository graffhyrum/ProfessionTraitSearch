local PTS = _G.ProfessionTraitSearch

local IndexRow = {}
PTS.IndexRow = IndexRow

local FALLBACK_NAME = {
	tab = "Specialization",
	path = "Sub-specialization",
	perk = "Perk",
}

local ROW_MIN = { tab = 36, path = 44, perk = 28 }

local FONT_OBJECT = {
	tab = "GameFontNormalLarge",
	path = "GameFontHighlight",
	perk = "GameFontHighlightSmall",
}

local function fontRGB(fontColor, r, g, b)
	if fontColor and fontColor.GetRGB then
		return fontColor:GetRGB()
	end
	return r, g, b
end

local SEMANTIC_RGB = {
	earned = { fontRGB(GREEN_FONT_COLOR, 0.1, 1, 0.1) },
	inaccessible = { fontRGB(GRAY_FONT_COLOR, 0.5, 0.5, 0.5) },
	nextTrait = { 0.55, 0.78, 1 },
	accessible = { 1, 0.82, 0 },
	neutral = { 1, 1, 1 },
	structural = { 1, 1, 1 },
	muted = { 0.72, 0.72, 0.72 },
}

local SEMANTIC_TINT = {
	earned = { 0.1, 0.45, 0.1, 0.10 },
	nextTrait = { 0.2, 0.4, 0.65, 0.12 },
	accessible = { 0.75, 0.6, 0.1, 0.14 },
	inaccessible = { 0.35, 0.35, 0.35, 0.08 },
	neutral = { 1, 1, 1, 0.05 },
	structural = { 0.75, 0.6, 0.1, 0.14 },
}

function IndexRow.IsUnearned(row)
	if not row then
		return false
	end
	if row.kind == "tab" then
		return false
	end
	if row.kind == "path" then
		return row.isCompleted ~= true
	end
	if row.kind == "perk" then
		return row.isEarned ~= true
	end
	return false
end

function IndexRow.IsCompleted(row)
	if not row or row.kind ~= "path" then
		return false
	end
	return row.isCompleted == true
end

function IndexRow.IsEarned(row)
	if not row or row.kind ~= "perk" then
		return false
	end
	return row.isEarned == true
end

function IndexRow.FallbackName(kind)
	return FALLBACK_NAME[kind] or ""
end

local function displayName(row)
	if not row then
		return ""
	end
	local name = row.name
	if name and name ~= "" then
		return name
	end
	return IndexRow.FallbackName(row.kind)
end

local function perkBadgeParts(row)
	local parts = {}
	if row.isMajorPerk then
		parts[#parts + 1] = "Major perk"
	end
	if row.unlockRank then
		parts[#parts + 1] = "Rank " .. row.unlockRank
	end
	if IndexRow.IsEarned(row) then
		parts[#parts + 1] = "Earned"
	end
	return parts
end

local function perkBadgeText(row)
	return table.concat(perkBadgeParts(row), " · ")
end

local function pathRankBadge(row)
	if not row or row.kind ~= "path" then
		return nil
	end
	if not row.maxRanks or row.maxRanks <= 0 then
		return nil
	end
	return string.format("%d / %d", row.currentRank or 0, row.maxRanks)
end

local function progressSemantic(row)
	return PTS.RowAvailability.ProgressSemantic(row)
end

local function titleRGB(row)
	local key = progressSemantic(row)
	local rgb = SEMANTIC_RGB[key] or SEMANTIC_RGB.neutral
	return rgb[1], rgb[2], rgb[3], key
end

local function badgeRGB(row)
	if not row then
		return nil
	end
	if row.kind == "perk" then
		local r, g, b = titleRGB(row)
		return r, g, b
	end
	if row.kind == "path" and pathRankBadge(row) then
		local r, g, b = titleRGB(row)
		return r, g, b
	end
	return nil
end

function IndexRow.HeaderColor()
	local rgb = SEMANTIC_RGB.accessible
	return rgb[1], rgb[2], rgb[3]
end

function IndexRow.DetailColor()
	local rgb = SEMANTIC_RGB.muted
	return rgb[1], rgb[2], rgb[3]
end

function IndexRow.KnowledgeLabelColor(available)
	if available and available > 0 then
		return IndexRow.HeaderColor()
	end
	return IndexRow.DetailColor()
end

function IndexRow.BuildView(row)
	if not row then
		return nil
	end

	local tr, tg, tb = titleRGB(row)
	local semantic = progressSemantic(row)
	local tint = SEMANTIC_TINT[semantic] or SEMANTIC_TINT.neutral
	local br, bg, bb = badgeRGB(row)
	local pathBadge = pathRankBadge(row)

	return {
		isUnearned = IndexRow.IsUnearned(row),
		isCompleted = IndexRow.IsCompleted(row),
		isEarned = IndexRow.IsEarned(row),
		displayName = displayName(row),
		perkBadgeText = row.kind == "perk" and perkBadgeText(row) or "",
		pathRankBadge = pathBadge,
		badgeText = pathBadge or (row.kind == "perk" and perkBadgeText(row) or ""),
		progressSemantic = semantic,
		titleColor = { tr, tg, tb },
		tint = tint,
		minHeight = ROW_MIN[row.kind] or ROW_MIN.perk,
		fontObject = FONT_OBJECT[row.kind] or FONT_OBJECT.perk,
		badgeColor = br and { br, bg, bb } or nil,
	}
end

PTS.RowProgress = {
	IsUnearned = IndexRow.IsUnearned,
	IsCompleted = IndexRow.IsCompleted,
	IsEarned = IndexRow.IsEarned,
}

PTS.RowDisplay = {
	FallbackName = IndexRow.FallbackName,
	DisplayName = function(row)
		local view = IndexRow.BuildView(row)
		return view and view.displayName or ""
	end,
	PerkBadgeParts = perkBadgeParts,
	PerkBadgeText = function(row)
		local view = IndexRow.BuildView(row)
		return view and view.perkBadgeText or ""
	end,
}

PTS.RowPresentation = {
	ProgressSemantic = progressSemantic,
	ProgressColor = function(row)
		local r, g, b, key = titleRGB(row)
		return r, g, b, key
	end,
	HeaderColor = IndexRow.HeaderColor,
	DetailColor = IndexRow.DetailColor,
	KnowledgeLabelColor = IndexRow.KnowledgeLabelColor,
	RowTint = function(row)
		local view = IndexRow.BuildView(row)
		return view and view.tint or SEMANTIC_TINT.neutral
	end,
	MinHeight = function(row)
		local view = IndexRow.BuildView(row)
		return view and view.minHeight or ROW_MIN.perk
	end,
	FontObject = function(row)
		local view = IndexRow.BuildView(row)
		return view and view.fontObject or FONT_OBJECT.perk
	end,
	PathRankBadge = pathRankBadge,
	TitleColor = function(row)
		local view = IndexRow.BuildView(row)
		if not view then
			return 1, 1, 1
		end
		return view.titleColor[1], view.titleColor[2], view.titleColor[3]
	end,
	BadgeColor = function(row)
		local view = IndexRow.BuildView(row)
		if not view or not view.badgeColor then
			return nil
		end
		return view.badgeColor[1], view.badgeColor[2], view.badgeColor[3]
	end,
}
