local wow_api = require("Tests.mocks.wow_api")

local M = {}

local loaded = {}

local function root()
	return os.getenv("PL_ROOT") or "."
end

local function loadfile_at(path)
	local chunk, err = loadfile(path)
	if not chunk then
		error(err or ("failed to load " .. path))
	end
	return chunk
end

function M.reset()
	wow_api.reset()
	wow_api.install()
	loaded = {}
	_G.PerkLens = nil
	for key in pairs(package.loaded) do
		if key:match("^core/") or key:match("^ui/") or key:match("^Tests%.") then
			package.loaded[key] = nil
		end
	end
end

function M.load(relativePath, ...)
	local path = root() .. "/" .. relativePath:gsub("\\", "/")
	if loaded[path] then
		return
	end
	local chunk = loadfile_at(path)
	chunk(...)
	loaded[path] = true
end

function M.load_core()
	M.load("core/init.lua")
	M.load("core/Debounce.lua")
	M.load("core/TradeSkillSession.lua")
	M.load("core/ProfessionContext.lua")
	M.load("core/RankUtil.lua")
	M.load("core/RowProgress.lua")
	M.load("core/RowDisplay.lua")
	M.load("core/RowPresentation.lua")
	M.load("core/SpecIndex.lua")
	M.load("core/SpecSearch.lua")
	M.load("core/SpecNavigation.lua")
	M.load("core/Controller.lua", "PerkLens")
end

function M.pl()
	return _G.PerkLens
end

return M
