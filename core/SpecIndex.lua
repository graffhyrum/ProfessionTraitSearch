local PTS = _G.ProfessionTraitSearch

local SpecIndex = {}
PTS.SpecIndex = SpecIndex

function SpecIndex.Build(context)
	local snapshot = PTS.SpecTreeWalker.Walk(context)
	return PTS.RowBuilder.Build(snapshot)
end
