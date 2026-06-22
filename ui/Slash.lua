local PTS = _G.ProfessionTraitSearch

local Slash = {}
PTS.Slash = Slash

local HASH_KEYS = { "/PTS", "/PROFESSIONTRAITSEARCH" }

local function printHelp()
	DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99Profession Trait Search|r — /pts, /pts search <term>, /pts status")
end

local function dispatchSlash(msg)
	msg = strtrim(msg or "")
	local lower = msg:lower()
	if lower == "status" then
		local ctx = PTS.Controller:GetContext()
		local name = ctx and ctx.professionName or "none"
		local count = #(PTS.Controller:GetVisibleRows())
		DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99Profession Trait Search|r " .. name .. " — " .. count .. " visible rows")
		return
	end
	if lower:match("^search ") then
		local term = msg:sub(8)
		PTS.SpecBrowser:ShowStandalone(term)
		return
	end
	if lower == "help" then
		printHelp()
		return
	end
	PTS.SpecBrowser:ToggleStandalone()
end

local function onSlash(msg)
	local ok, err = pcall(dispatchSlash, msg)
	if not ok then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Profession Trait Search error:|r " .. tostring(err))
	end
end

local function mirrorHash()
	if not hash_SlashCmdList then
		return
	end
	for i = 1, #HASH_KEYS do
		hash_SlashCmdList[HASH_KEYS[i]] = onSlash
	end
end

function Slash:Init()
	if self.registered then
		return
	end
	self.registered = true

	if RegisterNewSlashCommand then
		RegisterNewSlashCommand(onSlash, "pts", "professiontraitsearch")
	else
		SLASH_PROFESSIONTRAITSEARCH1 = "/pts"
		SLASH_PROFESSIONTRAITSEARCH2 = "/professiontraitsearch"
		SlashCmdList["PROFESSIONTRAITSEARCH"] = onSlash
	end

	mirrorHash()
end

Slash:Init()
