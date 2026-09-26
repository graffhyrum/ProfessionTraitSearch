local M = {}

local function perk(perkID, description, opts)
	opts = opts or {}
	return {
		perkID = perkID,
		description = description,
		state = opts.state or 1,
		isMajorPerk = opts.isMajorPerk == true,
		unlockRank = opts.unlockRank or 0,
		isEarned = opts.isEarned == true,
	}
end

local function pathNode(pathID, opts)
	opts = opts or {}
	return {
		pathID = pathID,
		tabTreeID = opts.tabTreeID or 201,
		tabName = opts.tabName or "Over-LODED",
		depth = opts.depth or 1,
		parentPathID = opts.parentPathID,
		name = opts.name or ("Path " .. tostring(pathID)),
		description = opts.description or "",
		state = opts.state or 2,
		currentRank = opts.currentRank or 0,
		maxRanks = opts.maxRanks or 1,
		sourceText = opts.sourceText or "",
		isCompleted = opts.isCompleted == true,
		isAccessible = opts.isAccessible == true,
		perks = opts.perks or {},
		children = opts.children or {},
	}
end

function M.miningTree()
	local deepVeins = pathNode(302, {
		depth = 2,
		parentPathID = 301,
		name = "Deep Veins",
		description = "Grants bonuses while mining deep veins.",
		currentRank = 0,
		maxRanks = 40,
		perks = {
			perk(402, "Grants Multicraft while mining", { isMajorPerk = true, unlockRank = 20 }),
		},
	})

	local rootPath = pathNode(301, {
		name = "Over-LODED Core",
		description = "Unlocks deeper mining techniques.",
		currentRank = 1,
		maxRanks = 2,
		perks = {
			perk(401, "Minor bonus", { unlockRank = 5 }),
		},
		children = { deepVeins },
	})

	return {
		skillLineID = 2881,
		configID = 101,
		tabs = {
			{
				tabTreeID = 201,
				name = "Over-LODED",
				description = "Master unexpected mining.",
				rootPath = rootPath,
			},
		},
	}
end

function M.nextPerkPath()
	return {
		skillLineID = 5000,
		configID = 500,
		tabs = {
			{
				tabTreeID = 501,
				name = "Test Spec",
				description = "Spec for next-perk marking.",
				rootPath = pathNode(601, {
					name = "Rank Dial",
					description = "Path with ordered perks.",
					currentRank = 3,
					maxRanks = 10,
					perks = {
						perk(701, "Earned early", { unlockRank = 5, isEarned = true }),
						perk(702, "Next unlock", { unlockRank = 10, isEarned = false }),
						perk(703, "Later unlock", { unlockRank = 15, isEarned = false }),
					},
				}),
			},
		},
	}
end

function M.allPerksEarnedPath()
	return {
		skillLineID = 5001,
		configID = 501,
		tabs = {
			{
				tabTreeID = 502,
				name = "Complete Spec",
				description = "",
				rootPath = pathNode(602, {
					name = "Finished Dial",
					description = "No pending perks.",
					currentRank = 10,
					perks = {
						perk(801, "Done A", { unlockRank = 5, isEarned = true }),
						perk(802, "Done B", { unlockRank = 10, isEarned = true }),
					},
				}),
			},
		},
	}
end

function M.multilinePerkPath()
	return {
		skillLineID = 5002,
		configID = 502,
		tabs = {
			{
				tabTreeID = 503,
				name = "Display Spec",
				description = "",
				rootPath = pathNode(603, {
					name = "Display Path",
					description = "Path description only.",
					perks = {
						perk(901, "Visible Title\nHidden body text", { unlockRank = 1 }),
					},
				}),
			},
		},
	}
end

function M.pathWithoutPerks()
	return {
		skillLineID = 5003,
		configID = 503,
		tabs = {
			{
				tabTreeID = 504,
				name = "Bare Spec",
				description = "Tab body.",
				rootPath = pathNode(604, {
					name = "Leaf Path",
					description = "Only path text.",
					perks = {},
				}),
			},
		},
	}
end

return M
