local PTS = _G.ProfessionTraitSearch

local SpecNavigation = {}
PTS.SpecNavigation = SpecNavigation

function SpecNavigation.ResolveTarget(row)
	if not row or not row.kind or not row.skillLineID or not row.tabTreeID then
		return nil
	end
	if row.kind == "tab" then
		return {
			skillLineID = row.skillLineID,
			tabTreeID = row.tabTreeID,
		}
	end
	if row.kind == "path" or row.kind == "perk" then
		if not row.pathID then
			return nil
		end
		return {
			skillLineID = row.skillLineID,
			tabTreeID = row.tabTreeID,
			pathID = row.pathID,
		}
	end
	return nil
end
