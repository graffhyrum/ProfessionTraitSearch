local PL = _G.PerkLens

local ProfessionContext = {}
PL.ProfessionContext = ProfessionContext

local function hasSpec(skillLineID)
	return skillLineID and C_ProfSpecs.SkillLineHasSpecialization(skillLineID)
end

local function getTrainedParentProfessionIDs()
	if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then
		return nil
	end
	local ids = {}
	local prof1, prof2, arch, fish, cook = GetProfessions()
	for _, index in ipairs({ prof1, prof2, arch, fish, cook }) do
		if index then
			local _, _, rank, _, _, _, skillLine = GetProfessionInfo(index)
			if skillLine and rank and rank > 0 then
				ids[skillLine] = true
			end
		end
	end
	return ids
end

function ProfessionContext.IsTrainedSkillLine(skillLineID)
	if not skillLineID then
		return false
	end
	local trained = getTrainedParentProfessionIDs()
	if not trained then
		return true
	end
	local info = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
	local parentID = info and info.parentProfessionID
	if not parentID then
		return false
	end
	return trained[parentID] == true
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
		sourceCounter = info and info.sourceCounter or 0,
		expansionName = info and info.expansionName,
	}
end

local function compareSpecSkillLines(a, b)
	local aSource = a.sourceCounter or 0
	local bSource = b.sourceCounter or 0
	if aSource > 0 and bSource > 0 and aSource ~= bSource then
		return aSource < bSource
	end
	if aSource > 0 and bSource > 0 then
		local aIndex = a.listIndex or 0
		local bIndex = b.listIndex or 0
		if aIndex ~= bIndex then
			return aIndex < bIndex
		end
	elseif aSource == 0 and bSource == 0 then
		local aIndex = a.listIndex or 0
		local bIndex = b.listIndex or 0
		if aIndex ~= bIndex then
			return aIndex > bIndex
		end
	end
	if a.skillLineID ~= b.skillLineID then
		return a.skillLineID < b.skillLineID
	end
	return (a.professionName or "") < (b.professionName or "")
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
	local skillLines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
	for i, skillLine in ipairs(skillLines) do
		if ProfessionContext.IsTrainedSkillLine(skillLine) then
			local ctx = ProfessionContext.GetContextForSkillLine(skillLine)
			if ctx then
				ctx.listIndex = i
				out[#out + 1] = ctx
			end
		end
	end
	table.sort(out, compareSpecSkillLines)
	return out
end

function ProfessionContext.GetKnowledgeAvailable(skillLineID)
	local info = C_ProfSpecs.GetCurrencyInfoForSkillLine(skillLineID)
	return info and info.numAvailable or 0
end

function ProfessionContext.ResolveForIndex(charDB, preferActive)
	local resolved
	local savedSkillLineID = charDB and charDB.lastSkillLineID
	if preferActive then
		resolved = ProfessionContext.GetActiveContext()
	end
	if not resolved and savedSkillLineID then
		if ProfessionContext.IsTrainedSkillLine(savedSkillLineID) then
			PL.TradeSkillSession:LoadChildSkillLine(savedSkillLineID)
			resolved = ProfessionContext.GetContextForSkillLine(savedSkillLineID)
		end
	end
	if not resolved and (preferActive or not savedSkillLineID) then
		resolved = ProfessionContext.GetActiveContext()
	end
	if not resolved and not savedSkillLineID then
		local list = ProfessionContext.ListSpecSkillLines()
		resolved = list[1]
	end
	return resolved
end
