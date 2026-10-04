# Profession Trait Search — dev workflows (Mechanic + Changesets)
# Run `just --list` for all recipes.

set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

addon := "ProfessionTraitSearch"
root := justfile_directory()
root_json := replace(root, "\\", "/")
mech_json := '{\""addon\"":\""' + addon + '\""}'
mech_json_coverage := '{\""addon\"":\""' + addon + '\"",\""coverage\"":true}'

export PTS_ROOT := root_json

default:
    @just --list

link-mechanic MECHANIC_REPO:
    $target = (Resolve-Path '{{MECHANIC_REPO}}').Path; $addonsDir = Split-Path '{{root}}' -Parent; $link = Join-Path $addonsDir 'Mechanic'; if (Test-Path $link) { Remove-Item $link -Force -Recurse -ErrorAction SilentlyContinue }; New-Item -ItemType Junction -Path $link -Target $target | Out-Null; Write-Host "Linked $link -> $target"

setup-hooks:
    bun install

bootstrap MECHANIC_REPO="C:/Tools/Mechanic":
    @just setup-hooks
    @just _require-mech
    @just link-mechanic {{MECHANIC_REPO}}
    mech setup --skip-config
    @just restore-lua
    $mechanic = "{{MECHANIC_REPO}}"; $fw = "$mechanic/sandbox/generated/test_framework.lua"; $src = "{{root_json}}/scripts/sandbox-test-framework.lua"; New-Item -ItemType Directory -Force -Path (Split-Path $fw) | Out-Null; Copy-Item $src $fw -Force

restore-lua:
    & "{{root_json}}/scripts/restore-mechanic-lua.ps1"
    mech call sandbox.generate
    mech call addon.sync '{{mech_json}}'
    mech call env.status
    mech call tools.status

_require-mech:
    if (-not (Get-Command mech -ErrorAction SilentlyContinue)) { throw "mech not found. pip install -e C:/Tools/Mechanic/desktop" }

check: validate lint

validate:
    @just _require-mech
    mech call addon.validate '{{mech_json}}'

lint:
    @just _require-mech
    mech call addon.lint '{{mech_json}}'

format:
    @just _require-mech
    mech call addon.format '{{mech_json}}'

test: test-sandbox test-busted

test-sandbox:
    @just _require-mech
    mech call sandbox.test '{{mech_json}}'

test-busted:
    @just _require-mech
    mech call addon.test '{{mech_json}}'

test-coverage:
    @just _require-mech
    mech call addon.test '{{mech_json_coverage}}'

dashboard:
    @just _require-mech
    mech

reload:
    @just _require-mech
    mech reload

changeset:
    bun run changeset

version:
    bun run version

sync-toc:
    bun scripts/sync-toc-version.ts

# Live retail Interface vs TOC (JSON)
retail-status:
    bun scripts/retail-status.ts

# Write TOC Interface + patch version from Wow.exe. No git commit.
retail-bump:
    bun scripts/retail-bump.ts

# Preview retail-bump writes as JSON
retail-bump-dry:
    bun scripts/retail-bump.ts --dry-run

render-assets:
    bun install
    bun run render-assets

release TAG:
    git tag {{TAG}}
    git push origin {{TAG}}

publish-tag:
    bun run publish:tag

# Print the release chain. Exit 1 when a tag or version PR is missing.
trace-release:
    bun scripts/trace-release.ts --check

package-local:
    bun scripts/package-local.ts

# Pre-release gate
pre-release: check test test-scripts

# Bun unit tests for release scripts
test-scripts:
    bun test scripts
