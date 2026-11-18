# 9Router Portable

Self-contained 9router (https://github.com/decolua/9router) in a single folder. Bundled Node.js (latest LTS), no global installs, no registry/PATH changes, no admin rights.

## Usage
- Windows: double-click `launch.bat`
- Linux: `chmod +x launch.sh scripts/setup.sh && ./launch.sh` (Node 26 needs libatomic: `apt install libatomic1`)
- Update 9router: `launch.bat update` / `./launch.sh update`

First run downloads Node (checksum-verified) and installs 9router, so internet is needed once. Then open http://localhost:20128 and choose Web UI.

Default dashboard password: `123456` (edit `data/initial-password.txt` to change it). It is only applied when 9router first creates its database; to reset, close it and delete `data\db`.

## Layout
- `runtime/node` bundled Node.js
- `app/npm` 9router install
- `data` database, secrets, provider tokens (treat like a password vault)
- `home`, `cache`, `temp` redirected HOME / APPDATA / npm cache / temp
- `scripts/sqlite-guard.js` runs before every launch; if better-sqlite3's native binary crashes on a PC, it disables it so 9router uses its built-in fallback instead of crash-looping

## Notes
- Windows may still keep traces outside the folder (Prefetch, Recent files, a firewall prompt on first run).
- The launchers bind 9router to 127.0.0.1 only (9router itself defaults to all interfaces), because the default password is weak. Remove `--host 127.0.0.1` from the launcher only if you want LAN access, and change the password first.
- For server logs when debugging, add `--log` to the last line of the launcher.
