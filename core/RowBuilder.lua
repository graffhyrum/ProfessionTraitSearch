local PTS = _G.ProfessionTraitSearch

local RowBuilder = {}
PTS.RowBuilder = RowBuilder

local function firstLine(text)
	if not text or text == "" then
		return ""
	end
	local line = text:match("^(.-)\n")
	return line or text
end

local function markNextPerk(perkRows, parentRank)
	local nextPerkID
	local sorted = {}
	for i = 1, #perkRows do
		sorted[i] = perkRows[i]
	end
	table.sort(sorted, function(a, b)
		return (a.unlockRank or 0) < (b.unlockRank or 0)
	end)
	for i = 1, #sorted do
		if not sorted[i].isEarned then
			nextPerkID = sorted[i].perkID
			break
		end
	end
	for i = 1, #perkRows do
		perkRows[i].parentPathRank = parentRank
		perkRows[i].isNextPerk = perkRows[i].perkID == nextPerkID
	end
end

local function buildSearchableText(description, perks)
	local perkDescParts = {}
	for i = 1, #perks do
		local perkDescription = perks[i].description
		if perkDescription and perkDescription ~= "" then
			perkDescParts[#perkDescParts + 1] = perkDescription
		end
	end
	if #perkDescParts == 0 then
		return description
	end
	return description .. "\n" .. table.concat(perkDescParts, "\n")
end

local function appendPathRows(rows, pathNode, skillLineID)
	local perkRows = {}
	for i = 1, #pathNode.perks do
		local perk = pathNode.perks[i]
		local perkDescription = perk.description or ""
		perkRows[#perkRows + 1] = {
			kind = "perk",
			rowKey = "perk:" .. tostring(perk.perkID),
			skillLineID = skillLineID,
			tabTreeID = pathNode.tabTreeID,
			tabName = pathNode.tabName,
			depth = pathNode.depth + 1,
			parentPathID = pathNode.pathID,
			pathID = pathNode.pathID,
			perkID = perk.perkID,
			name = firstLine(perkDescription),
			description = perkDescription,
			searchableText = perkDescription,
			state = perk.state,
			isMajorPerk = perk.isMajorPerk,
			unlockRank = perk.unlockRank,
			isEarned = perk.isEarned,
		}
	end

	markNextPerk(perkRows, pathNode.currentRank)

	rows[#rows + 1] = {
		kind = "path",
		rowKey = "path:" .. tostring(pathNode.pathID),
		skillLineID = skillLineID,
		tabTreeID = pathNode.tabTreeID,
		tabName = pathNode.tabName,
		depth = pathNode.depth,
		parentPathID = pathNode.parentPathID,
		pathID = pathNode.pathID,
		name = pathNode.name,
		description = pathNode.description,
		searchableText = buildSearchableText(pathNode.description, pathNode.perks),
		state = pathNode.state,
		currentRank = pathNode.currentRank,
		maxRanks = pathNode.maxRanks,
		sourceText = pathNode.sourceText,
		isCompleted = pathNode.isCompleted,
		isAccessible = pathNode.isAccessible,
	}

	for i = 1, #perkRows do
		rows[#rows + 1] = perkRows[i]
	end

	for i = 1, #pathNode.children do
		appendPathRows(rows, pathNode.children[i], skillLineID)
	end
end

function RowBuilder.Build(snapshot)
	if not snapshot then
		return {}
	end

	local rows = {}
	local skillLineID = snapshot.skillLineID

	for i = 1, #snapshot.tabs do
		local tab = snapshot.tabs[i]
		rows[#rows + 1] = {
			kind = "tab",
			rowKey = "tab:" .. tostring(tab.tabTreeID),
			skillLineID = skillLineID,
			tabName = tab.name,
			tabTreeID = tab.tabTreeID,
			depth = 0,
			name = tab.name,
			description = tab.description,
			searchableText = (tab.name or "") .. "\n" .. (tab.description or ""),
		}
		if tab.rootPath then
			appendPathRows(rows, tab.rootPath, skillLineID)
		end
	end

	return rows
end
