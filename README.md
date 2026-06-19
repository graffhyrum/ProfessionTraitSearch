# PerkLens

Searchable profession specialization index for WoW retail.

Domain terms: see [UBIQUITOUS_LANGUAGE.md](UBIQUITOUS_LANGUAGE.md) (player-facing vs internal naming).

## Features

- Tree list of specializations, sub-specializations, and perks with descriptions visible at once
- Text search (e.g. find Multicraft)
- Filters: major pips only, unearned only
- Standalone panel (`/pl`) and embedded toggle on the Professions Specializations page

## Development

```bash
just bootstrap   # first time (installs commit-msg hook via bun)
just test
just check
```

Commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) (e.g. `feat(ui): add search filter`). Re-run `just setup-hooks` if hooks are missing after clone.

See [docs/mechanic-setup.md](docs/mechanic-setup.md).
