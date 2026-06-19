std = "lua51"
max_line_length = 160

globals = {
	"LibStub",
	"CreateFrame",
	"GetTime",
	"UnitGUID",
	"UnitName",
	"GetRealmName",
	"UIParent",
	"DEFAULT_CHAT_FRAME",
	"SLASH_SPECTRAITLENS1",
	"SLASH_SPECTRAITLENS2",
	"SLASH_STL1",
	"SLASH_STL2",
	"SlashCmdList",
	"hash_SlashCmdList",
	"RegisterNewSlashCommand",
	"GameTooltip",
	"ProfessionsFrame",
	"EventRegistry",
	"TalentUtil",
	"SpecTraitLens",
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

read_globals = {
	"C_AddOns",
	"C_Timer",
	"C_ProfSpecs",
	"C_Traits",
	"C_TradeSkillUI",
	"Enum",
}

exclude_files = {
	"libs/**",
	"repos/**",
	"**/*_spec.lua",
	"Tests/**",
	"scripts/**",
}

ignore = {
	"212",
}

