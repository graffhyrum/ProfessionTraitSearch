local PTS = _G.ProfessionTraitSearch

local RowProgress = {}
PTS.RowProgress = RowProgress

function RowProgress.IsUnearned(row)
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

function RowProgress.IsCompleted(row)
	if not row or row.kind ~= "path" then
		return false
	end
	return row.isCompleted == true
end

function RowProgress.IsEarned(row)
	if not row or row.kind ~= "perk" then
		return false
	end
	return row.isEarned == true
end
