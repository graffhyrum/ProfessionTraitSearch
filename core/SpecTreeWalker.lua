local PTS = _G.ProfessionTraitSearch

local SpecTreeWalker = {}
PTS.SpecTreeWalker = SpecTreeWalker

local PATH_LOCKED = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Locked or 0
local PATH_PROGRESSING = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Progressing or 1
local PATH_COMPLETED = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Completed or 2
local PERK_EARNED = Enum and Enum.ProfessionsSpecPerkState and Enum.ProfessionsSpecPerkState.Earned or 2

local function pathIsAccessible(configID, pathID, pathState)
	if pathState == PATH_COMPLETED then
		return false
	end
	if pathState == PATH_LOCKED then
		local unlockEntry = C_ProfSpecs.GetUnlockEntryForPath(pathID)
		return unlockEntry and C_Traits.CanPurchaseRank(configID, pathID, unlockEntry)
	end
	if pathState == PATH_PROGRESSING then
		local spendEntry = C_ProfSpecs.GetSpendEntryForPath(pathID)
		return spendEntry and C_Traits.CanPurchaseRank(configID, pathID, spendEntry)
	end
	return false
end

local function talentNameFromEntry(configID, entryID)
	if not entryID or not TalentUtil then
		return ""
	end
	local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
	local definitionID = entryInfo and entryInfo.definitionID
	local defInfo = definitionID and C_Traits.GetDefinitionInfo(definitionID)
	if defInfo then
		return TalentUtil.GetTalentName(defInfo.overrideName, defInfo.spellID) or ""
	end
	return ""
end

local function talentNameForPath(configID, pathID, nodeInfo)
	if not TalentUtil then
		return ""
	end
	nodeInfo = nodeInfo or C_Traits.GetNodeInfo(configID, pathID)
	local activeEntryID = nodeInfo and nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
	local name = talentNameFromEntry(configID, activeEntryID)
	if name ~= "" then
		return name
	end
	name = talentNameFromEntry(configID, C_ProfSpecs.GetSpendEntryForPath(pathID))
	if name ~= "" then
		return name
	end
	return talentNameFromEntry(configID, C_ProfSpecs.GetUnlockEntryForPath(pathID))
end

local function walkPathNode(configID, skillLineID, tabTreeID, tabName, pathID, depth, parentPathID)
	local nodeInfo = C_Traits.GetNodeInfo(configID, pathID)
	local description = C_ProfSpecs.GetDescriptionForPath(pathID) or ""
	local perks = C_ProfSpecs.GetPerksForPath(pathID) or {}
	local perkNodes = {}

	for _, perk in ipairs(perks) do
		local perkDescription = C_ProfSpecs.GetDescriptionForPerk(perk.perkID) or ""
		local perkState = C_ProfSpecs.GetStateForPerk(perk.perkID, configID)
		perkNodes[#perkNodes + 1] = {
			perkID = perk.perkID,
			description = perkDescription,
			state = perkState,
			isMajorPerk = perk.isMajorPerk == true,
			unlockRank = C_ProfSpecs.GetUnlockRankForPerk(perk.perkID),
			isEarned = perkState == PERK_EARNED,
		}
	end

	local currRank, maxRanks = PTS.RankUtil.GetDisplayRanks(configID, pathID, nodeInfo)
	local pathState = C_ProfSpecs.GetStateForPath(pathID, configID)
	local childNodes = {}
	for _, childID in ipairs(C_ProfSpecs.GetChildrenForPath(pathID) or {}) do
		childNodes[#childNodes + 1] = walkPathNode(configID, skillLineID, tabTreeID, tabName, childID, depth + 1, pathID)
	end

	return {
		pathID = pathID,
		tabTreeID = tabTreeID,
		tabName = tabName,
		depth = depth,
		parentPathID = parentPathID,
		name = talentNameForPath(configID, pathID, nodeInfo),
		description = description,
		state = pathState,
		currentRank = currRank,
		maxRanks = maxRanks,
		sourceText = C_ProfSpecs.GetSourceTextForPath(pathID, configID),
		isCompleted = pathState == PATH_COMPLETED,
		isAccessible = pathIsAccessible(configID, pathID, pathState),
		perks = perkNodes,
		children = childNodes,
	}
end

function SpecTreeWalker.Walk(context)
	if not context or not context.configID or not context.skillLineID then
		return nil
	end

	local configID = context.configID
	local skillLineID = context.skillLineID
	local tabIDs = C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID) or {}
	local tabs = {}

	for _, tabTreeID in ipairs(tabIDs) do
		local tabInfo = C_ProfSpecs.GetTabInfo(tabTreeID)
		if tabInfo then
			tabs[#tabs + 1] = {
				tabTreeID = tabTreeID,
				name = tabInfo.name,
				description = tabInfo.description or "",
				rootPath = walkPathNode(configID, skillLineID, tabTreeID, tabInfo.name, tabInfo.rootNodeID, 1, nil),
			}
		end
	end

	return {
		skillLineID = skillLineID,
		configID = configID,
		tabs = tabs,
	}
end
