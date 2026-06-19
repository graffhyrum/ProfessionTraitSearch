local PL = _G.PerkLens

local SpecIndex = {}
PL.SpecIndex = SpecIndex

local PATH_COMPLETED = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Completed or 3
local PERK_EARNED = Enum and Enum.ProfessionsSpecPerkState and Enum.ProfessionsSpecPerkState.Earned or 3

local function firstLine(text)
	if not text or text == "" then
		return ""
	end
	local line = text:match("^(.-)\n")
	return line or text
end

local function pathName(configID, pathID, description, nodeInfo)
	local name = firstLine(description)
	if name ~= "" then
		return name
	end
	if nodeInfo and nodeInfo.isVisible and TalentUtil then
		local spendEntry = C_ProfSpecs.GetSpendEntryForPath(pathID)
		local entryInfo = spendEntry and C_Traits.GetEntryInfo(configID, spendEntry)
		local defInfo = entryInfo and entryInfo.definitionID and C_Traits.GetDefinitionInfo(entryInfo.definitionID)
		if defInfo then
			return TalentUtil.GetTalentName(defInfo.overrideName, defInfo.spellID) or ""
		end
	end
	return ""
end

local function walkPath(rows, configID, skillLineID, tabTreeID, pathID, tabName, depth, parentPathID)
	local nodeInfo = C_Traits.GetNodeInfo(configID, pathID)
	local description = C_ProfSpecs.GetDescriptionForPath(pathID) or ""
	local perks = C_ProfSpecs.GetPerksForPath(pathID) or {}
	local perkDescParts = {}
	local perkRows = {}

	for _, perk in ipairs(perks) do
		local perkDescription = C_ProfSpecs.GetDescriptionForPerk(perk.perkID) or ""
		if perkDescription ~= "" then
			perkDescParts[#perkDescParts + 1] = perkDescription
		end
		perkRows[#perkRows + 1] = {
			kind = "perk",
			rowKey = "perk:" .. tostring(perk.perkID),
			skillLineID = skillLineID,
			tabTreeID = tabTreeID,
			tabName = tabName,
			depth = depth + 1,
			parentPathID = pathID,
			pathID = pathID,
			perkID = perk.perkID,
			name = firstLine(perkDescription),
			description = perkDescription,
			searchableText = perkDescription,
			state = C_ProfSpecs.GetStateForPerk(perk.perkID, configID),
			isMajorPerk = perk.isMajorPerk == true,
			unlockRank = C_ProfSpecs.GetUnlockRankForPerk(perk.perkID),
			isEarned = C_ProfSpecs.GetStateForPerk(perk.perkID, configID) == PERK_EARNED,
		}
	end

	local searchableText = description
	if #perkDescParts > 0 then
		searchableText = searchableText .. "\n" .. table.concat(perkDescParts, "\n")
	end

	local currRank, maxRanks = PL.RankUtil.GetDisplayRanks(configID, pathID, nodeInfo)
	local pathState = C_ProfSpecs.GetStateForPath(pathID, configID)

	rows[#rows + 1] = {
		kind = "path",
		rowKey = "path:" .. tostring(pathID),
		skillLineID = skillLineID,
		tabTreeID = tabTreeID,
		tabName = tabName,
		depth = depth,
		parentPathID = parentPathID,
		pathID = pathID,
		name = pathName(configID, pathID, description, nodeInfo),
		description = description,
		searchableText = searchableText,
		state = pathState,
		currentRank = currRank,
		maxRanks = maxRanks,
		sourceText = C_ProfSpecs.GetSourceTextForPath(pathID, configID),
		isCompleted = pathState == PATH_COMPLETED,
	}

	for i = 1, #perkRows do
		rows[#rows + 1] = perkRows[i]
	end

	for _, childID in ipairs(C_ProfSpecs.GetChildrenForPath(pathID) or {}) do
		walkPath(rows, configID, skillLineID, tabTreeID, childID, tabName, depth + 1, pathID)
	end
end

function SpecIndex.Build(context)
	if not context or not context.configID or not context.skillLineID then
		return {}
	end

	local rows = {}
	local configID = context.configID
	local skillLineID = context.skillLineID
	local tabIDs = C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID) or {}

	for _, tabTreeID in ipairs(tabIDs) do
		local tabInfo = C_ProfSpecs.GetTabInfo(tabTreeID)
		if tabInfo then
			rows[#rows + 1] = {
				kind = "tab",
				rowKey = "tab:" .. tostring(tabTreeID),
				skillLineID = skillLineID,
				tabName = tabInfo.name,
				tabTreeID = tabTreeID,
				depth = 0,
				name = tabInfo.name,
				description = tabInfo.description or "",
				searchableText = (tabInfo.name or "") .. "\n" .. (tabInfo.description or ""),
			}
			walkPath(rows, configID, skillLineID, tabTreeID, tabInfo.rootNodeID, tabInfo.name, 1, nil)
		end
	end

	return rows
end
