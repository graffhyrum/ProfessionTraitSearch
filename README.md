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
just bootstrap   # first time
just test
just check
```

See [docs/mechanic-setup.md](docs/mechanic-setup.md).
