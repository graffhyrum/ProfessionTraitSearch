local PL = _G.PerkLens

local SpecSearch = {}
PL.SpecSearch = SpecSearch

local function lower(s)
	return (s or ""):lower()
end

local function rowMatches(row, query)
	if query == "" then
		return true
	end
	local hay = lower(row.searchableText) .. "\n" .. lower(row.name)
	return hay:find(query, 1, true) ~= nil
end

local function promoteTab(rows, visible, tabName)
	for i = 1, #rows do
		local tabRow = rows[i]
		if tabRow.kind == "tab" and tabRow.tabName == tabName then
			visible[tabRow.rowKey] = true
			return
		end
	end
end

local function promotePathChain(rows, visible, pathID)
	if not pathID then
		return
	end
	for i = 1, #rows do
		local row = rows[i]
		if row.kind == "path" and row.pathID == pathID then
			visible[row.rowKey] = true
			if row.parentPathID then
				promotePathChain(rows, visible, row.parentPathID)
			else
				promoteTab(rows, visible, row.tabName)
			end
			return
		end
	end
end

local function promoteAncestors(rows, visible, rowIndex)
	local row = rows[rowIndex]
	if not row then
		return
	end
	visible[row.rowKey] = true
	if row.kind == "perk" and row.parentPathID then
		promotePathChain(rows, visible, row.parentPathID)
	elseif row.kind == "path" then
		if row.parentPathID then
			promotePathChain(rows, visible, row.parentPathID)
		else
			promoteTab(rows, visible, row.tabName)
		end
	end
end

function SpecSearch.Filter(rows, options)
	options = options or {}
	local query = lower(options.searchText)
	local majorOnly = options.majorPerksOnly == true
	local unearnedOnly = options.unearnedOnly == true
	local visible = {}
	local out = {}

	for i = 1, #rows do
		local row = rows[i]
		local ok = true
		if majorOnly and (row.kind ~= "perk" or not row.isMajorPerk) then
			ok = false
		end
		if ok and unearnedOnly and not PL.RowProgress.IsUnearned(row) then
			ok = false
		end
		if ok and query ~= "" and not rowMatches(row, query) then
			ok = false
		end
		if ok then
			visible[row.rowKey] = true
			if query ~= "" or majorOnly or unearnedOnly then
				promoteAncestors(rows, visible, i)
			end
		end
	end

	if query == "" and not majorOnly and not unearnedOnly then
		return rows
	end

	for i = 1, #rows do
		local row = rows[i]
		if visible[row.rowKey] then
			out[#out + 1] = row
		end
	end
	return out
end
