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

On merge to `main`, **Version Packages** (`version-packages.yml`) prints a release trace, then:

1. If `package.json` version has no `v*` tag, push that tag **before** any version PR. A pending changeset must not block this.
2. Open a **Version Packages** PR when pending changesets exist.
3. On merge of that PR (no changesets left), run `bun scripts/publish-tag.ts` → push `v{version}`.

The job summary lists each stage: `toc`, `changelog`, `tag`, `changesets`, `version-pr`. A missing tag or a missing version PR fails the check step.

Tag push triggers **Release** (`release.yml`). That workflow traces the tag against `package.json`, the TOC, and `CHANGELOG.md`, then uploads to CurseForge and GitHub via BigWigs packager.

`bun scripts/trace-release.ts --check` reports the same chain locally. `--publish-untagged` pushes the missing tag. `--tagged` checks the current tag checkout.

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

Trace the chain:

```bash
bun scripts/trace-release.ts --check
```
