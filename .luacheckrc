std = "lua51"
max_line_length = 160

-- WoW event/method handlers use unused `self` / `event` arguments by convention.
ignore = {
	"212",
}

-- Frames, slash commands, and saved variables the addon assigns to or hooks.
globals = {
	"LibStub",
	"CreateFrame",
	"GetTime",
	"UnitGUID",
	"UnitName",
	"GetRealmName",
	"UIParent",
	"DEFAULT_CHAT_FRAME",
	"SLASH_PROFESSIONTRAITSEARCH1",
	"SLASH_PROFESSIONTRAITSEARCH2",
	"SLASH_PTS1",
	"SLASH_PTS2",
	"SlashCmdList",
	"hash_SlashCmdList",
	"RegisterNewSlashCommand",
	"GameTooltip",
	"ProfessionsFrame",
	"EventRegistry",
	"TalentUtil",
	"ProfessionTraitSearch",
	"ProfessionTraitSearchDB",
	"PerkLensDB",
	"SpecTraitLensDB",
	"strtrim",
	"hooksecurefunc",
	"InputBoxTemplate",
	"BackdropTemplate",
	"UIPanelButtonTemplate",
	"UICheckButtonTemplate",
	"UIPanelCloseButton",
	"UIPanelScrollFrameTemplate",
	"UIDropDownMenuTemplate",
	"UIDropDownMenu_AddButton",
	"UIDropDownMenu_CreateInfo",
	"UIDropDownMenu_Initialize",
	"UIDropDownMenu_SetSelectedValue",
	"UIDropDownMenu_SetText",
	"UIDropDownMenu_SetWidth",
}

-- Read-only WoW APIs and helpers. Declared explicitly (no std=wow blanket).
read_globals = {
	"C_AddOns",
	"C_Timer",
	"C_ProfSpecs",
	"C_Traits",
	"C_TradeSkillUI",
	"Enum",
	"Professions",
	"GREEN_FONT_COLOR",
	"GRAY_FONT_COLOR",
	"GetProfessions",
	"GetProfessionInfo",
	"ShowUIPanel",
	"RunNextFrame",
	"tinsert",
	"UISpecialFrames",
}

exclude_files = {
	"libs/**",
	"repos/**",
	"**/*_spec.lua",
	"Tests/**",
	"scripts/**",
}
