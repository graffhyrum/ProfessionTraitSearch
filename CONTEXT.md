# Profession Trait Search

WoW **retail** addon: searchable **specialization index** for profession spec trees.

Full glossary and player/internal naming rules: **`UBIQUITOUS_LANGUAGE.md`**.

## Language (quick reference)

**Specialization** (player) / **spec tab** (internal):
Top-level branch (e.g. Plentiful Ores, Meticulous Mining, Over-LODED). `C_ProfSpecs.GetTabInfo`; row `kind = "tab"`.
_Avoid in UI_: tab, trait tree

**Sub-specialization** (player) / **path** (internal):
Spendable dial under a specialization (e.g. Seams, Rich Deposits). `pathID` via `C_ProfSpecs`; row `kind = "path"`.
_Avoid in UI_: path, node, talent, trait

**Perk**:
Milestone on a sub-specialization rank dial. `isMajorPerk` → major perk.
_Avoid in UI_: trait point, rank bonus

**Specialization index** (player) / **spec index** (internal):
Flat list from `C_ProfSpecs` + `C_Traits` via `SpecIndex.Build`.
_Avoid in UI_: trait index, trait browser

**RowProgress**:
Progress seam — `IsUnearned`, `IsCompleted`, and `IsEarned` centralize earned/completed semantics for index rows.

**RowDisplay**:
UI seam — `DisplayName` and `PerkBadgeText` map row kinds to player-facing labels.

**RowPresentation**:
Presentation seam — frame-agnostic colors, tints, fonts, min heights, and path rank badge text for index rows.

**ViewMode**:
Controller surface for index context policy — `embedded` (Professions spec-tab overlay), `standalone` (`/pts` window), or `closed`. UI sets mode; `embedded` prefers active profession context when rebuilding the index.

**Profession context**:
Resolved scope for the **spec index** — `{ skillLineID, configID, professionName }` from `ProfessionContext` (`ResolveForIndex`, `GetActiveContext`, listing, **Knowledge**). Domain resolution only; no `C_TradeSkillUI` load/sync.

**Trade skill session**:
I/O seam — `TradeSkillSession` owns child skill line load, data-ready gating, profession frame sync, and open strategy (`C_TradeSkillUI`, `ProfessionsFrame`, `EventRegistry`). Callers pass explicit options; session does not read **ViewMode**.

**Searchable text**:
Path description plus perk descriptions on that path — powers keyword search.
_Avoid_: search index

**Knowledge**:
Unspent spec currency from `C_ProfSpecs.GetCurrencyInfoForSkillLine`.
_Avoid in UI_: points (unless Blizzard does)

## Example dialogue

> "Search for Multicraft in Midnight Mining specs."
> → Open `/pts` or the **Specialization index** on the Professions **Specializations** page; type `Multicraft`; matching sub-specializations and perks appear with parent context.

> "Show only major perks I haven't earned yet."
> → Enable **Major perks only** + **Unearned only**.
