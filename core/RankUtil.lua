local PTS = _G.ProfessionTraitSearch

local RankUtil = {}
PTS.RankUtil = RankUtil

function RankUtil.GetDisplayRanks(configID, nodeID, nodeInfo)
	if not nodeInfo then
		return 0, 0
	end
	local unlockEntry = C_ProfSpecs.GetUnlockEntryForPath(nodeID)
	local entryInfo = unlockEntry and C_Traits.GetEntryInfo(configID, unlockEntry)
	local numUnlock = (entryInfo and entryInfo.maxRanks) or 0
	local curr = (nodeInfo.currentRank > 0) and (nodeInfo.currentRank - numUnlock) or nodeInfo.currentRank
	return curr, nodeInfo.maxRanks - numUnlock
end
