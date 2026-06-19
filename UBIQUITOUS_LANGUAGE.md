# Ubiquitous Language

PerkLens domain: searchable index of WoW retail profession **Specializations**, **Sub-specializations**, and **Perks**.

## Naming seam

PerkLens spans Blizzard's player vocabulary and `C_ProfSpecs` implementation names. **Keep them separate.**

| Layer | Use when | Vocabulary source |
|-------|----------|-------------------|
| **Player-facing** | Tooltips, settings copy, filters, README, errors, chat | Blizzard UI strings and in-game hierarchy (below) |
| **Internal** | Lua modules, row `kind`, saved vars, tests, dev discussion | `C_ProfSpecs` / `C_Traits` names (below) |
| **Product** | Addon title, slash command, side-tab affordance | **PerkLens** — not a Blizzard term |

### Rules

1. **Player strings use Blizzard terms** for game content — never expose internal `tab`, `path`, or `trait` as nouns for specializations.
2. **Internal code keeps API-aligned row kinds and IDs** — `kind = "tab"`, `pathID`, `perkID`; module names use **Spec** prefix (`SpecIndex`, `SpecSearch`, `SpecBrowser`), not **Trait**.
3. **Row display goes through `RowDisplay`** — player-facing names and perk badges; index rows store Blizzard text only (empty string when missing, never internal nouns).
4. **Row display names come from Blizzard** — `GetTabInfo`, `GetDescriptionForPath`, `GetDescriptionForPerk`; PerkLens does not invent labels for tree content.
5. **PerkLens-branded chrome** may say "PerkLens" or "Specialization index"; describe *content* with Blizzard words.
6. When depth matters internally, use **path layer** (`Root`, `Primary`, `Secondary` — matches Blizzard `PathLayers` in `Blizzard_ProfessionsSpecializations.lua`).

### Midnight Mining example (player-facing)

| Player term | Example | Internal | API |
|-------------|---------|----------|-----|
| **Profession** | Mining | skill line context | `skillLineID`, `C_TradeSkillUI` |
| **Specialization** | Plentiful Ores, Meticulous Mining, Over-LODED | spec **tab** | `C_ProfSpecs.GetTabInfo`, `kind = "tab"` |
| **Sub-specialization** | Seams, Rich Deposits (under Meticulous Mining) | **path** | `C_ProfSpecs.GetDescriptionForPath`, `kind = "path"` |
| **Perk** / **pip** | Dial milestone bonus (major pip = capstone pip) | **perk** | `perkID`, `isMajorPerk`, `kind = "perk"` |
| **Knowledge** | Unspent spec currency | knowledge currency | `C_ProfSpecs.GetCurrencyInfoForSkillLine` |

Nested paths (deeper dials under a sub-specialization) are still **Sub-specializations** to the player and **paths** internally — same mapping at every path depth.

The tab **root path** (`tabInfo.rootNodeID`, path layer `Root`) is the unlock/spend dial for a **Specialization**; guides often call it the "root node" of that tree. It is a **path** row in the index, not a separate **tab** row.

---

## Player-facing vocabulary (Blizzard-aligned)

| Term | Definition | Aliases to avoid in UI |
|------|-----------|------------------------|
| **Profession** | A crafting skill (Mining, Blacksmithing, …) | Trade skill (when meaning the spec tree) |
| **Specialization** | A top-level branch of a profession spec tree (e.g. Plentiful Ores, Meticulous Mining, Over-LODED) | Tab, trait tree, spec page, branch |
| **Sub-specialization** | A spendable path dial under a Specialization (e.g. Seams, Rich Deposits) | Path, node, talent, skill, trait |
| **Perk** | Milestone bonus tied to ranks on a sub-specialization dial | Trait point, bonus node, rank bonus |
| **Pip** | Visual dial marker for a perk; **Major pip** = major perk (`isMajorPerk`) | Trait, bonus |
| **Knowledge** | Unspent specialization currency for a profession | Points, KP (except where Blizzard uses KP) |
| **Specializations** (page) | Professions frame tab listing spec trees (`PROFESSIONS_SPECIALIZATIONS_TAB_NAME`) | Spec tab, trait tab |
| **Specialization index** | PerkLens list/search of specializations, sub-specializations, and perks | Trait index, trait browser |

## Internal vocabulary (code & API)

| Term | Definition | Maps to player term |
|------|-----------|---------------------|
| **Spec tab** | `C_ProfSpecs.GetTabInfo` entry; row `kind = "tab"` | **Specialization** |
| **Path** | Spend/unlock node (`pathID`); row `kind = "path"` | **Sub-specialization** (any depth) |
| **Perk** | Dial milestone (`perkID`); row `kind = "perk"` | **Perk** / **pip** |
| **Path layer** | Tree depth class: `Root`, `Primary`, `Secondary` (Blizzard layout) | Root dial vs first fork vs deeper forks |
| **Skill line** | `skillLineID` scope for one spec config | **Profession** (spec-enabled line) |
| **configID** | Trait tree config for a skill line | (not player-visible) |
| **Spec index** | Flat row list from `SpecIndex.Build` | **Specialization index** (product) |
| **RowDisplay** | Player-facing row titles and perk badges (`DisplayName`, `PerkBadgeText`) | UI label seam |
| **Row** | Index entry: `tab`, `path`, or `perk` | One specialization, sub-specialization, or perk line |
| **Searchable text** | Concatenated descriptions for keyword search | (not player-visible) |
| **Visible rows** | Filtered index with ancestor promotion | (not player-visible) |
| **Profession context** | `{ skillLineID, configID, professionName }` | Active **Profession** scope |
| **Index mode** | Embedded index replacing Blizzard spec tree view | (PerkLens product behavior) |

## Filters and progress (player labels = Blizzard enums)

| Player label | Internal | Blizzard state |
|--------------|----------|----------------|
| Major pips only | `majorPipsOnly` | `isMajorPerk` |
| Unearned only | `unearnedOnly` | `ProfessionsSpecPerkState.Unearned`, incomplete paths |
| Earned | `isEarned` | `ProfessionsSpecPerkState.Earned` |
| Completed | `isCompleted` | `ProfessionsSpecPathState.Completed` |

## Relationships

- A **Profession** (skill line) has one **configID** and one **Spec index**.
- A **Specialization** (spec tab) contains a tree of **Paths**; each **Path** may have child **Paths** and **Perks**.
- A **Perk** belongs to one **Path**; every **Path** belongs to one **Specialization** (via `tabName` / tab tree).
- **Searchable text** on a **Path** includes that path's description and direct perk descriptions.
- **Knowledge** is per skill line, not per row.

## Example dialogue

> **Dev:** "In **Index mode**, if someone searches `Multicraft`, do we match **Perks** or **Sub-specializations**?"
> **Domain expert:** "Both. **Searchable text** on a **Path** rolls up perk descriptions, so a **Sub-specialization** can match without its title saying Multicraft. Hits still **promote** ancestor **Specializations** for context."
> **Dev:** "Player-facing copy for the Professions side tab?"
> **Domain expert:** "**Specialization index** or **PerkLens** — not 'Trait Index'. The rows already show Blizzard names like **Meticulous Mining** and **Seams**; we don't label them Tab or Path in the UI."
> **Dev:** "**Major pips only** plus **Unearned only** — still Blizzard-aligned?"
> **Domain expert:** "Yes. **Pip** matches dial art and sounds; **Unearned** matches `ProfessionsSpecPerkState`."

## Flagged ambiguities

- **"Specialization" overload** — Blizzard uses `PROFESSIONS_SPECIALIZATION` on path tooltips too (generic type label). In PerkLens **player copy**, reserve **Specialization** for top-level branches (spec tabs) and **Sub-specialization** for path dials. In **internal** discussion, say **path** to avoid collision with the tab level.
- **"Trait"** — Blizzard `C_Traits` / `TRAIT_*` events only. Do not use **trait** in module names or player-facing strings.
- **"Tab"** — `C_ProfSpecs` spec tab internally; player sees **Specialization**. Professions frame **Specializations** page is a different "tab" (UI chrome) — say **Specializations page** when meaning `ProfessionsFrame.specializationsTabID`.
- **Pip vs Perk** — **Perk** in API (`perkID`); **pip** in player filter labels and dial UI (matches Blizzard atlas/sound names).
- **SpecTraitLens** — legacy addon/db name; not used in new copy.
