local PTS = _G.ProfessionTraitSearch

local RowDisplay = {}
PTS.RowDisplay = RowDisplay

-- Player-facing fallbacks when Blizzard provides no name (never tab/path/trait).
local FALLBACK_NAME = {
	tab = "Specialization",
	path = "Sub-specialization",
	perk = "Perk",
}

function RowDisplay.FallbackName(kind)
	return FALLBACK_NAME[kind] or ""
end

function RowDisplay.DisplayName(row)
	if not row then
		return ""
	end
	local name = row.name
	if name and name ~= "" then
		return name
	end
	return RowDisplay.FallbackName(row.kind)
end

function RowDisplay.PerkBadgeParts(row)
	local parts = {}
	if row.isMajorPerk then
		parts[#parts + 1] = "Major perk"
	end
	if row.unlockRank then
		parts[#parts + 1] = "Rank " .. row.unlockRank
	end
	if PTS.RowProgress.IsEarned(row) then
		parts[#parts + 1] = "Earned"
	end
	return parts
end

function RowDisplay.PerkBadgeText(row)
	return table.concat(RowDisplay.PerkBadgeParts(row), " · ")
end
