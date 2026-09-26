local PTS = _G.ProfessionTraitSearch

local SpecNavigation = {}
PTS.SpecNavigation = SpecNavigation

local ProfessionOpenStrategy = {}
PTS.ProfessionOpenStrategy = ProfessionOpenStrategy

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

function ProfessionOpenStrategy.Classify(skillLineID, viewMode, session)
	if not skillLineID or not session then
		return "invalid"
	end
	if session:GetChildSkillLineID() == skillLineID then
		return "same_child"
	end
	if session:IsOnTargetParentProfession(skillLineID) then
		if viewMode == "standalone" then
			return "same_parent_full"
		end
		return "same_parent_light"
	end
	return "different_parent"
end

function ProfessionOpenStrategy.Resolve(skillLineID, viewMode, session)
	local forceFull = viewMode == "standalone"
	return {
		skillLineID = skillLineID,
		forceFull = forceFull,
		openSpecTab = true,
		scenario = ProfessionOpenStrategy.Classify(skillLineID, viewMode, session),
	}
end
