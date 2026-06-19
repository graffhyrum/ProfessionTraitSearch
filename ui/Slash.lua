local STL = _G.SpecTraitLens

local Slash = {}
STL.Slash = Slash

local HASH_KEYS = { "/STL", "/SPECTRAITLENS" }

local function printHelp()
	DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99Spec Trait Lens|r — /stl, /stl search <term>, /stl status")
end

local function dispatchSlash(msg)
	msg = strtrim(msg or "")
	local lower = msg:lower()
	if lower == "status" then
		local ctx = STL.Controller:GetContext()
		local name = ctx and ctx.professionName or "none"
		local count = #(STL.Controller:GetVisibleRows())
		DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99Spec Trait Lens|r " .. name .. " — " .. count .. " visible rows")
		return
	end
	if lower:match("^search ") then
		local term = msg:sub(8)
		STL.TraitBrowser:ShowStandalone(term)
		return
	end
	if lower == "help" then
		printHelp()
		return
	end
	STL.TraitBrowser:ToggleStandalone()
end

local function onSlash(msg)
	local ok, err = pcall(dispatchSlash, msg)
	if not ok then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Spec Trait Lens error:|r " .. tostring(err))
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
		RegisterNewSlashCommand(onSlash, "stl", "spectraitlens")
	else
		SLASH_SPECTRAITLENS1 = "/stl"
		SLASH_SPECTRAITLENS2 = "/spectraitlens"
		SlashCmdList["SPECTRAITLENS"] = onSlash
	end

	mirrorHash()
end

Slash:Init()
