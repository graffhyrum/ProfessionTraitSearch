# Changesets

Pending changelog entries for [Changesets](https://github.com/changesets/changesets).

`package.json` is the version source Changesets bumps; `@changesets/cli` is a devDependency — run via `bun run changeset`.

## Adding a changeset

After a user-facing change:

```bash
bun run changeset
```

Pick the semver bump and write a short summary. Commit the generated `.changeset/*.md` file with your PR.

PRs to `main` run the **Changesets** workflow (`changeset status --since=origin/main`).

## Releasing (automated)

On merge to `main`, **Version Packages** (`version-packages.yml`):

1. Opens a **Version Packages** PR when pending changesets exist.
2. On merge of that PR, runs `bun scripts/publish-tag.ts` → pushes `v{version}`.

Tag push triggers **Release** (`release.yml`) → CurseForge + GitHub Release via BigWigs packager.

## Local

Same version step as CI:

```bash
bun run version
```

Runs `changeset version`, updates `CHANGELOG.md` and `package.json`, syncs `ProfessionTraitSearch.toc`, removes consumed changeset files.

Tag locally (CI normally does this):

```bash
bun run publish:tag
```
