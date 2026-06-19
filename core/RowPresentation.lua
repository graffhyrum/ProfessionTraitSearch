local PL = _G.PerkLens

local RowPresentation = {}
PL.RowPresentation = RowPresentation

local ROW_MIN = { tab = 36, path = 44, perk = 28 }
local ROW_TINT = {
	tab = { 0.75, 0.6, 0.1, 0.14 },
	path = { 1, 1, 1, 0.05 },
	perk = { 0, 0, 0, 0.04 },
}

local FONT_OBJECT = {
	tab = "GameFontNormalLarge",
	path = "GameFontHighlight",
	perk = "GameFontHighlightSmall",
}

function RowPresentation.RowTint(row)
	return ROW_TINT[row and row.kind] or ROW_TINT.perk
end

function RowPresentation.MinHeight(row)
	return ROW_MIN[row and row.kind] or ROW_MIN.perk
end

function RowPresentation.FontObject(row)
	return FONT_OBJECT[row and row.kind] or FONT_OBJECT.perk
end

function RowPresentation.PathRankBadge(row)
	if not row or row.kind ~= "path" then
		return nil
	end
	if not row.maxRanks or row.maxRanks <= 0 then
		return nil
	end
	return string.format("%d / %d", row.currentRank or 0, row.maxRanks)
end

function RowPresentation.TitleColor(row)
	if not row then
		return 1, 1, 1
	end
	if row.kind == "perk" then
		if PL.RowProgress.IsEarned(row) then
			return 1, 0.82, 0
		end
		if row.isMajorPerk then
			return 1, 0.72, 0.35
		end
		return 0.82, 0.82, 0.82
	end
	if PL.RowProgress.IsCompleted(row) then
		return 0.45, 1, 0.45
	end
	if row.kind == "tab" then
		return 1, 0.82, 0
	end
	return 1, 1, 1
end

function RowPresentation.BadgeColor(row)
	if not row or row.kind ~= "perk" then
		return nil
	end
	if PL.RowProgress.IsEarned(row) then
		return 0.45, 1, 0.45
	end
	if row.isMajorPerk then
		return 1, 0.72, 0.35
	end
	return 0.55, 0.78, 1
end
