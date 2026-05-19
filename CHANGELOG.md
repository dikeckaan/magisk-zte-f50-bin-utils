# Changelog

## v1.3.0 — 2026-05-19
- **New**: `lib/common.sh` — shared POSIX-sh-compatible helpers that
  any other ZTE F50 Magisk module can source from `service.sh`:
  - `log_line` / `log_rotate` — uniform timestamped logging with
    parent-dir auto-mkdir and size-based rotation
  - `find_bash` / `find_ca_bundle` — locate static bash and CA pem
    across `/system/bin`, live and staged bin-utils paths
  - `wait_for_file` / `wait_for_iface` — boot-time bring-up helpers
  - `ensure_iptables_redirect` (+ `_remove`) — idempotent
    `-I PREROUTING 1` insertion that beats vendor DNS DNAT rules,
    with a matching cleanup helper for `uninstall.sh`
  - `supervisor_loop` — backgrounded "run forever, restart on exit"
- Source it with:
  `[ -r /data/adb/modules/bin-utils/lib/common.sh ] && . /data/adb/modules/bin-utils/lib/common.sh`
  Modules that fall back to inline definitions when this file is
  missing remain compatible with older bin-utils.
- No binary changes — the rest of bin-utils is identical to v1.2.0.

## v1.2.0
- Add bash 5.2.015 (static, ~2.3 MB) from [robxu9/bash-static](https://github.com/robxu9/bash-static)
- statusbot now uses bash for i18n (associative arrays + indirect expansion)

## v1.1.0
- Initial public release
- Bundled: curl, wget (busybox symlink), jq, sendat, busybox + CA bundle
- arm64 static binaries
