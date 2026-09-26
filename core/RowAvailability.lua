local PTS = _G.ProfessionTraitSearch

local RowAvailability = {}
PTS.RowAvailability = RowAvailability

local PATH_LOCKED = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Locked or 0
local PATH_PROGRESSING = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Progressing or 1
local PATH_COMPLETED = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Completed or 2

local PERK_PENDING = Enum and Enum.ProfessionsSpecPerkState and Enum.ProfessionsSpecPerkState.Pending or 1

function RowAvailability.IsPathAccessible(row)
	if not row or row.kind ~= "path" then
		return false
	end
	return row.isAccessible == true
end

function RowAvailability.IsPathInaccessible(row)
	if not row or row.kind ~= "path" then
		return false
	end
	if row.isCompleted or row.state == PATH_COMPLETED then
		return false
	end
	return row.state == PATH_LOCKED and not row.isAccessible
end

function RowAvailability.IsNextPerk(row)
	if not row or row.kind ~= "perk" then
		return false
	end
	return row.isNextPerk == true and not PTS.IndexRow.IsEarned(row)
end

function RowAvailability.IsPerkAccessible(row)
	if not row or row.kind ~= "perk" or PTS.IndexRow.IsEarned(row) then
		return false
	end
	if RowAvailability.IsNextPerk(row) then
		return false
	end
	if row.state == PERK_PENDING then
		return true
	end
	local unlockRank = row.unlockRank or 0
	local parentRank = row.parentPathRank or 0
	return parentRank >= unlockRank
end

function RowAvailability.IsPerkInaccessible(row)
	if not row or row.kind ~= "perk" or PTS.IndexRow.IsEarned(row) then
		return false
	end
	if RowAvailability.IsNextPerk(row) then
		return false
	end
	return not RowAvailability.IsPerkAccessible(row)
end

function RowAvailability.ProgressSemantic(row)
	if not row then
		return "neutral"
	end
	if row.kind == "tab" then
		return "structural"
	end
	if PTS.IndexRow.IsCompleted(row) or PTS.IndexRow.IsEarned(row) then
		return "earned"
	end
	if row.kind == "perk" then
		if RowAvailability.IsNextPerk(row) then
			return "nextTrait"
		end
		if RowAvailability.IsPerkAccessible(row) then
			return "accessible"
		end
		if RowAvailability.IsPerkInaccessible(row) then
			return "inaccessible"
		end
		return "neutral"
	end
	if row.kind == "path" then
		if RowAvailability.IsPathAccessible(row) then
			return "accessible"
		end
		if RowAvailability.IsPathInaccessible(row) then
			return "inaccessible"
		end
		return "neutral"
	end
	return "neutral"
end
