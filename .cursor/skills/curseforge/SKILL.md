---
name: curseforge
description: Interact programmatically with CurseForge for Profession Trait Search — REST search/read, TOC project ID, release uploads via BigWigs packager, and Bun scripts. Use when working with CurseForge API, CF_API_KEY, project ID, mod search, file uploads, game versions, or release workflows.
---

# CurseForge (Profession Trait Search)

## Project constants

| Constant | Value |
|----------|-------|
| WoW `gameId` | `432` |
| Project slug | `profession-trait-search` |
| Project ID (TOC) | `1584836` — `## X-Curse-Project-ID` in `ProfessionTraitSearch.toc` |
| Search name | `Profession Trait Search` |

## Two APIs (do not mix)

| API | Base URL | Auth header | Used for |
|-----|----------|-------------|----------|
| **Studios REST** | `https://api.curseforge.com/v1/` | `x-api-token` | Search mods, read project metadata |
| **Site / upload** | `https://wow.curseforge.com/api/` | `X-Api-Token` | Upload files, game versions, dependencies |

Same author token works for both. Official Studios docs say `x-api-key`; this repo's working pattern is `x-api-token` on the REST API (see `scripts/ensure-curseforge-project.ts`).

## Auth in this repo

```bash
export CF_API_KEY=...        # preferred locally and in CI
# or
export CURSEFORGE_API_KEY=...
```

- **GitHub Actions secret:** `CURSEFORGE_API_KEY` → mapped to `CF_API_KEY` in workflows
- **Generate token:** [CurseForge API tokens](https://authors.curseforge.com/account/api-tokens)
- Never commit tokens. Never log full keys.

## Existing automation

| Path | Role |
|------|------|
| `scripts/ensure-curseforge-project.ts` | Search CF for this mod; write `X-Curse-Project-ID` into TOC |
| `.github/workflows/resolve-curseforge-project.yml` | Manual dispatch → run script → commit TOC if changed |
| `.github/workflows/release.yml` | Tag `v*` → `BigWigsMods/packager@v2` uploads to CurseForge + GitHub Release |
| `scripts/publish-tag.ts` | Pushes `v{package.json version}` tag (triggers release workflow) |
| `scripts/trace-release.ts` | Prints the release chain. `--publish-untagged` pushes a missing tag before a version PR. `--check` fails on a gap. `--tagged` checks a tag checkout before packager upload. |

Release path: trace → publish untagged `package.json` version → changeset version PR → merge → `publish-tag` → tag push → trace tag → packager. A pending changeset does not block the untagged publish. Packager reads `CF_API_KEY` and `## X-Curse-Project-ID` from the TOC.

## Quick workflows

### Resolve / verify project ID

```bash
bun scripts/ensure-curseforge-project.ts
```

Idempotent: skips write if TOC already has an ID. Creates project manually if search finds nothing: [create WoW project](https://authors.curseforge.com/#/projects/create/432).

### REST search (Bun pattern)

Reuse `cfFetch` from `scripts/ensure-curseforge-project.ts`:

```typescript
const res = await fetch(url, {
  headers: { Accept: "application/json", "x-api-token": process.env.CF_API_KEY! },
});
```

Search this project:

```
GET https://api.curseforge.com/v1/mods/search?gameId=432&searchFilter=Profession%20Trait%20Search&pageSize=25
```

Get mod by ID:

```
GET https://api.curseforge.com/v1/mods/{modId}
```

List files:

```
GET https://api.curseforge.com/v1/mods/{modId}/files
```

### Manual file upload (site API)

Prefer CI packager for releases. For one-off uploads:

1. `GET https://wow.curseforge.com/api/game/versions` — resolve `gameVersions` IDs for target WoW build
2. `POST https://wow.curseforge.com/api/projects/1584836/upload-file` — `multipart/form-data` with `metadata` (JSON string) and `file` (zip)

```bash
curl -H "X-Api-Token: $CF_API_KEY" \
  -F 'metadata={"changelog":"...","changelogType":"markdown","displayName":"v1.0.3","releaseType":"release","gameVersions":[...]}' \
  -F "file=@ProfessionTraitSearch-v1.0.3.zip" \
  "https://wow.curseforge.com/api/projects/1584836/upload-file"
```

`releaseType`: `alpha` | `beta` | `release`. Beta if tag contains `-b`.

## Adding new scripts

- Run with **Bun** (`/// <reference types="bun" />`), same as other `scripts/`
- Read token via `process.env.CF_API_KEY ?? process.env.CURSEFORGE_API_KEY`; exit 1 with clear message if missing
- Use `Accept: application/json` on REST calls
- Exit non-zero on HTTP errors; print status and body snippet on failure
- Import/export functions for testability; `if (import.meta.main)` for CLI entry

## TOC contract

Packager and `ensure-curseforge-project.ts` expect:

```
## X-Curse-Project-ID: <numeric id>
```

Insert after `## Category-enUS: Professions` if missing. Do not remove or rename without updating workflows.

## Additional resources

- Endpoint catalog and response shapes: [reference.md](reference.md)
- Upload API (official): https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api
- Studios REST docs: https://docs.curseforge.com/rest-api/
