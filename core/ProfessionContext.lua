local PL = _G.PerkLens

local ProfessionContext = {}
PL.ProfessionContext = ProfessionContext

local function hasSpec(skillLineID)
	return skillLineID and C_ProfSpecs.SkillLineHasSpecialization(skillLineID)
end

function ProfessionContext.ResolveSkillLineID(skillLineID)
	if hasSpec(skillLineID) then
		return skillLineID
	end
	return C_ProfSpecs.GetDefaultSpecSkillLine()
end

function ProfessionContext.GetContextForSkillLine(skillLineID)
	if not hasSpec(skillLineID) then
		return nil
	end
	local configID = C_ProfSpecs.GetConfigIDForSkillLine(skillLineID)
	if not configID or configID == 0 then
		return nil
	end
	local info = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
	return {
		skillLineID = skillLineID,
		configID = configID,
		professionName = (info and info.professionName) or "Profession",
		parentProfessionID = info and info.parentProfessionID,
	}
end

function ProfessionContext.GetActiveContext()
	local skillLineID
	if ProfessionsFrame and ProfessionsFrame.GetProfessionInfo then
		local pinfo = ProfessionsFrame:GetProfessionInfo()
		if pinfo and pinfo.professionID then
			skillLineID = ProfessionContext.ResolveSkillLineID(pinfo.professionID)
		end
	end
	if not skillLineID then
		skillLineID = C_ProfSpecs.GetDefaultSpecSkillLine()
	end
	return ProfessionContext.GetContextForSkillLine(skillLineID)
end

function ProfessionContext.ListSpecSkillLines()
	local out = {}
	if not C_TradeSkillUI or not C_TradeSkillUI.GetAllProfessionTradeSkillLines then
		return out
	end
	for _, skillLine in ipairs(C_TradeSkillUI.GetAllProfessionTradeSkillLines()) do
		local ctx = ProfessionContext.GetContextForSkillLine(skillLine)
		if ctx then
			out[#out + 1] = ctx
		end
	end
	table.sort(out, function(a, b)
		return (a.professionName or "") < (b.professionName or "")
	end)
	return out
end

function ProfessionContext.GetKnowledgeAvailable(skillLineID)
	local info = C_ProfSpecs.GetCurrencyInfoForSkillLine(skillLineID)
	return info and info.numAvailable or 0
end
