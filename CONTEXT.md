# PerkLens

WoW **retail** addon: searchable **specialization index** for profession spec trees.

Full glossary and player/internal naming rules: **`UBIQUITOUS_LANGUAGE.md`**.

## Language (quick reference)

**Specialization** (player) / **spec tab** (internal):
Top-level branch (e.g. Plentiful Ores, Meticulous Mining, Over-LODED). `C_ProfSpecs.GetTabInfo`; row `kind = "tab"`.
_Avoid in UI_: tab, trait tree

**Sub-specialization** (player) / **path** (internal):
Spendable dial under a specialization (e.g. Seams, Rich Deposits). `pathID` via `C_ProfSpecs`; row `kind = "path"`.
_Avoid in UI_: path, node, talent, trait

**Perk / pip**:
Milestone on a sub-specialization rank dial. `isMajorPerk` → major pip.
_Avoid in UI_: trait point, rank bonus

**Specialization index** (player) / **spec index** (internal):
Flat list from `C_ProfSpecs` + `C_Traits` via `SpecIndex.Build`.
_Avoid in UI_: trait index, trait browser

**RowProgress**:
Progress seam — `IsUnearned`, `IsCompleted`, and `IsEarned` centralize earned/completed semantics for index rows.

**RowDisplay**:
UI seam — `DisplayName` and `PerkBadgeText` map row kinds to player-facing labels.

**ViewMode**:
Controller surface for index context policy — `embedded` (Professions spec-tab overlay), `standalone` (`/pl` window), or `closed`. UI sets mode; `embedded` prefers active profession context when rebuilding the index.

**Searchable text**:
Path description plus perk descriptions on that path — powers keyword search.
_Avoid_: search index

**Knowledge**:
Unspent spec currency from `C_ProfSpecs.GetCurrencyInfoForSkillLine`.
_Avoid in UI_: points (unless Blizzard does)

## Example dialogue

> "Search for Multicraft in Midnight Mining specs."
> → Open `/pl` or the **Specialization index** on the Professions **Specializations** page; type `Multicraft`; matching sub-specializations and perks appear with parent context.

> "Show only major pips I haven't earned yet."
> → Enable **Major pips only** + **Unearned only**.
