local PL = _G.PerkLens



local Slash = {}

PL.Slash = Slash



local HASH_KEYS = { "/PL", "/PERKLENS" }



local function printHelp()

	DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99PerkLens|r — /pl, /pl search <term>, /pl status")

end



local function dispatchSlash(msg)

	msg = strtrim(msg or "")

	local lower = msg:lower()

	if lower == "status" then

		local ctx = PL.Controller:GetContext()

		local name = ctx and ctx.professionName or "none"

		local count = #(PL.Controller:GetVisibleRows())

		DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99PerkLens|r " .. name .. " — " .. count .. " visible rows")

		return

	end

	if lower:match("^search ") then

		local term = msg:sub(8)

		PL.SpecBrowser:ShowStandalone(term)

		return

	end

	if lower == "help" then

		printHelp()

		return

	end

	PL.SpecBrowser:ToggleStandalone()

end



local function onSlash(msg)

	local ok, err = pcall(dispatchSlash, msg)

	if not ok then

		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000PerkLens error:|r " .. tostring(err))

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

		RegisterNewSlashCommand(onSlash, "pl", "perklens")

	else

		SLASH_PERKLENS1 = "/pl"

		SLASH_PERKLENS2 = "/perklens"

		SlashCmdList["PERKLENS"] = onSlash

	end



	mirrorHash()

end



Slash:Init()

