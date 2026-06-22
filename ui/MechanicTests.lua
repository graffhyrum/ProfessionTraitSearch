local PTS = _G.ProfessionTraitSearch

local MechanicTests = {}
PTS.MechanicTests = MechanicTests

local tests = {
	{
		id = "context_available",
		name = "Profession context",
		category = "Core",
		type = "auto",
		description = "Resolve a profession specialization context.",
	},
	{
		id = "index_builds",
		name = "Specialization index builds",
		category = "Core",
		type = "auto",
		description = "Build specialization index rows for the active context.",
	},
}

function MechanicTests:GetAll()
	return tests
end

function MechanicTests:GetResult(id)
	if id == "context_available" then
		local ctx = PTS.ProfessionContext.GetActiveContext()
		local ok = ctx ~= nil and ctx.configID ~= nil
		return {
			passed = ok,
			message = ok and (ctx.professionName or "context OK") or "No context",
		}
	end
	if id == "index_builds" then
		local ctx = PTS.ProfessionContext.GetActiveContext()
		if not ctx then
			return { passed = false, message = "No context" }
		end
		local rows = PTS.SpecIndex.Build(ctx)
		local ok = #rows > 0
		return {
			passed = ok,
			message = ok and (#rows .. " rows") or "Empty index",
		}
	end
	return { passed = false, message = "Unknown test: " .. tostring(id) }
end

function MechanicTests:Run(id)
	return self:GetResult(id)
end

local MechanicLib = LibStub and LibStub("MechanicLib-1.0", true)
if MechanicLib then
	local version = "0.1.0"
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		version = C_AddOns.GetAddOnMetadata("ProfessionTraitSearch", "Version") or version
	end
	MechanicLib:Register("ProfessionTraitSearch", {
		version = version,
		tests = {
			getAll = function()
				return MechanicTests:GetAll()
			end,
			getCategories = function()
				return { "Core" }
			end,
			run = function(id)
				return MechanicTests:Run(id)
			end,
			getResult = function(id)
				return MechanicTests:GetResult(id)
			end,
		},
	})
end
