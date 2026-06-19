# Mechanic setup

[Mechanic](https://github.com/Falkicon/Mechanic) powers offline tests, lint, format, and the in-game dev dashboard.

## Install (this machine)

| Component | Location |
|-----------|----------|
| Mechanic repo | `C:\Tools\Mechanic` |
| `mech` CLI | `pip install -e C:\Tools\Mechanic\desktop` |
| Lua 5.1 | `C:\Tools\Mechanic\desktop\bin\lua.exe` |
| LuaRocks | `C:\Tools\LuaRocks` |
| Busted | `C:\Tools\LuaRocks\tree\bin\busted.bat` |
| Config | `%USERPROFILE%\.mechanic\config.json` |

Fresh install:

```bash
git clone https://github.com/Falkicon/Mechanic.git C:\Tools\Mechanic
cd C:\Tools\Mechanic\desktop
pip install -e .
```

### Mechanic repo junction (required for sandbox)

Sandbox stub generation reads `AddOns/Mechanic/UI/APIDefs/`. On this machine:

```powershell
just link-mechanic C:\Tools\Mechanic
```

Or manually:

```powershell
New-Item -ItemType Junction `
  -Path "G:\World of Warcraft\_retail_\Interface\AddOns\Mechanic" `
  -Target "C:\path\to\Mechanic"
```

### In-game addon

Copy or junction `!Mechanic/` from the Mechanic repo into:

```
World of Warcraft\_retail_\Interface\AddOns\!Mechanic\
```

## Path config

Addon lives in `Interface/AddOns/` (not `_dev_/`). Create `~/.mechanic/config.json`:

```json
{
  "wow_root": "G:/World of Warcraft",
  "dev_path": "G:/World of Warcraft/_retail_/Interface/AddOns",
  "addon_search_paths": [
    "G:/World of Warcraft/_retail_/Interface/AddOns/NoMoreWorldQuests"
  ],
  "flavors": ["_retail_"]
}
```

Adjust `wow_root` and paths for your install.

## Bootstrap

```bash
just bootstrap
```

Runs `mech setup --skip-config`, `just restore-lua` (fixes bad lua download), `sandbox.generate`, `addon.sync`, and prints `env.status` / `tools.status`.

### Windows: Lua + Busted

Mechanic's `mech setup` SourceForge download can fail checksum validation and overwrite `lua.exe` with HTML. `just bootstrap` runs `just restore-lua` after setup. To fix manually:

```powershell
just restore-lua
```

Install LuaRocks + Busted (requires MinGW `x86_64-w64-mingw32-gcc` on PATH):

```powershell
# LuaRocks installer lives in C:\Tools\luarocks-src\install.bat
cmd /c "C:\Tools\luarocks-src\install.bat /P C:\Tools\LuaRocks /TREE C:\Tools\LuaRocks\tree /BIN C:\Tools\Mechanic\desktop\bin /INC C:\Tools\luarocks-src\win32\lua5.1\include /LIB C:\Tools\Mechanic\desktop\bin /FORCECONFIG /NOREG /NOADMIN /Q"
luarocks install busted
# Junction so Mechanic finds rocks:
cmd /c mklink /J %APPDATA%\luarocks C:\Tools\LuaRocks\tree
python -c "from mechanic.setup import generate_busted_bat; generate_busted_bat()"
```

## Daily commands

| Command | Purpose |
|---------|---------|
| `just test` | Sandbox + Busted |
| `just check` | TOC validate + Luacheck |
| `just format` | StyLua |
| `just reload` | Trigger in-game `/reload` |
| `just dashboard` | Mechanic UI at localhost:3100 |

After `/reload`, in-game test results appear in Mechanic → Tests when `!Mechanic` is enabled.

## Verified on this machine (2026-06-09)

| Check | Result |
|-------|--------|
| `just test-sandbox` | 3 passed |
| `just test-busted` | 14 passed |
| `just lint` | 0 errors |
| `just validate` | TOC files OK; interface `120007` flagged outdated by Mechanic (expected until validator catches up) |

Junctions:

- `AddOns\Mechanic` → `C:\Tools\Mechanic`
- `AddOns\!Mechanic` → `C:\Tools\Mechanic\!Mechanic`
- `%APPDATA%\luarocks` → `C:\Tools\LuaRocks\tree`

Sandbox requires `C:\Tools\Mechanic\sandbox\generated\test_framework.lua` (not shipped by upstream `sandbox.generate` yet).
