![Profession Trait Search](assets/pts-logo-banner.svg)

# Profession Trait Search

Searchable profession specialization index for WoW retail.
Domain terms: see [UBIQUITOUS_LANGUAGE.md](UBIQUITOUS_LANGUAGE.md) (player-facing vs internal naming).

## Features

- Tree list of specializations, sub-specializations, and perks with descriptions visible at once
- Text search (e.g. find Multicraft)
- Filters: major perks only, unearned only
- Standalone panel (`/pts`) and embedded toggle on the Professions Specializations page

## Development

```bash
just bootstrap   # first time (installs commit-msg hook via bun)
just test
just check
```

Commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) (e.g. `feat(ui): add search filter`). Re-run `just setup-hooks` if hooks are missing after clone.

See [docs/mechanic-setup.md](docs/mechanic-setup.md).

## Brand assets

Source artwork lives in `assets/*.svg`. WoW needs raster textures — regenerate PNGs after editing SVGs:

```bash
just render-assets
```

| File | Purpose |
|------|---------|
| `assets/pts-icon.svg` | Canonical square icon (edit this) |
| `assets/pts-logo-banner.svg` | README / CurseForge banner |
| `assets/pts-icon-512.png` | In-game minimap, tab, addon list |
| `assets/pts-icon-64.png` | Optional small export |
