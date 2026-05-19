# shellcheck shell=sh
# bin-utils/lib/common.sh — shared helpers for ZTE F50 Magisk modules.
#
# Source from any module's service.sh:
#     . /data/adb/modules/bin-utils/lib/common.sh
#
# A module may also fall back to inline definitions if this file is
# missing — see the Phase 2 "soft requirement" pattern:
#
#     if [ -r /data/adb/modules/bin-utils/lib/common.sh ]; then
#         . /data/adb/modules/bin-utils/lib/common.sh
#     else
#         log_line() { echo "[$(date)] $*" >> "$LOG"; }
#         # ... module-specific fallbacks ...
#     fi
#
# All functions are POSIX-compatible (toybox sh works). The caller is
# responsible for setting any variables documented per function.

# ─── log_line — append a timestamped line to $LOG ─────────────────────────
# Required env: $LOG  (path; parent dir is auto-created)
log_line() {
    [ -n "$LOG" ] || return 1
    mkdir -p "$(dirname "$LOG")" 2>/dev/null
    echo "[$(date)] $*" >> "$LOG"
}

# ─── log_rotate — move $LOG to $LOG.1 if it exceeds $1 bytes ──────────────
# Required env: $LOG
# Arg 1: max bytes (default 524288 = 512 KB)
log_rotate() {
    [ -n "$LOG" ] || return 1
    [ -f "$LOG" ] || return 0
    local max
    max="${1:-524288}"
    local sz
    sz=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
    if [ "$sz" -gt "$max" ] 2>/dev/null; then
        mv "$LOG" "$LOG.1"
    fi
}

# ─── find_bash — echo path to a static bash binary ────────────────────────
# Tries /system/bin/bash, then bin-utils live + staged paths.
# Returns 0 on success (path on stdout), 1 if not found.
find_bash() {
    local p
    for p in /system/bin/bash \
             /data/adb/modules/bin-utils/system/bin/bash \
             /data/adb/modules_update/bin-utils/system/bin/bash; do
        if [ -x "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

# ─── find_ca_bundle — echo path to a PEM CA bundle ────────────────────────
# Used by Go binaries that need SSL_CERT_FILE (cloudflared, AdGuardHome, ...).
# Returns 0 on success, 1 if no bundle is readable anywhere.
find_ca_bundle() {
    local p
    for p in /data/adb/modules/bin-utils/system/etc/cacert.pem \
             /system/etc/cacert.pem \
             /system/etc/security/cacerts.bks; do
        if [ -r "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

# ─── wait_for_file — block until $1 is readable or timeout ────────────────
# Arg 1: path
# Arg 2: timeout in seconds (default 300)
# Arg 3: poll interval in seconds (default 5)
# Returns 0 if file appeared, 1 on timeout.
wait_for_file() {
    local path="$1"
    local timeout="${2:-300}"
    local poll="${3:-5}"
    local elapsed=0
    while [ ! -s "$path" ]; do
        if [ "$elapsed" -ge "$timeout" ]; then
            return 1
        fi
        sleep "$poll"
        elapsed=$((elapsed + poll))
    done
    return 0
}

# ─── wait_for_iface — block until network interface $1 exists ─────────────
# Arg 1: interface name (e.g. "br0", "wlan0", "tailscale0")
# Arg 2: timeout seconds (default 90)
# Arg 3: poll seconds (default 3)
# Returns 0 if up, 1 on timeout.
wait_for_iface() {
    local iface="$1"
    local timeout="${2:-90}"
    local poll="${3:-3}"
    local elapsed=0
    while ! ip link show "$iface" >/dev/null 2>&1; do
        if [ "$elapsed" -ge "$timeout" ]; then
            return 1
        fi
        sleep "$poll"
        elapsed=$((elapsed + poll))
    done
    return 0
}

# ─── ensure_iptables_redirect — idempotently insert at PREROUTING pos 1 ───
# Some vendor firmware (ZTE) adds its own DNAT rules at the top of
# nat PREROUTING, which would shadow an `-A`-appended rule. We always
# `-I PREROUTING 1` and delete any prior copy first to avoid duplicates.
#
# Arg 1: input interface (e.g. "br0")
# Arg 2: protocol ("udp" or "tcp")
# Arg 3: matching dport (e.g. 53)
# Arg 4: target redirect port (e.g. 5353)
# Returns 0 on success.
ensure_iptables_redirect() {
    local iface="$1" proto="$2" dport="$3" toport="$4"
    iptables -t nat -D PREROUTING -i "$iface" -p "$proto" --dport "$dport" \
             -j REDIRECT --to-ports "$toport" 2>/dev/null
    iptables -t nat -I PREROUTING 1 -i "$iface" -p "$proto" --dport "$dport" \
             -j REDIRECT --to-ports "$toport" 2>/dev/null
}

# ─── ensure_iptables_redirect_remove — delete every copy of a rule ────────
# Mirror of the install function for use in uninstall.sh. Loops until
# the rule is gone (the keepalive loop may have inserted several copies
# across reboots).
ensure_iptables_redirect_remove() {
    local iface="$1" proto="$2" dport="$3" toport="$4"
    while iptables -t nat -D PREROUTING -i "$iface" -p "$proto" --dport "$dport" \
                   -j REDIRECT --to-ports "$toport" 2>/dev/null; do :; done
}

# ─── supervisor_loop — run a command forever with restart delay ───────────
# Forks into the background. The caller's script returns immediately.
# Arg 1: command to run (passed to `sh -c "$1"`)
# Arg 2: restart delay seconds (default 10)
# Arg 3: optional log rotation threshold; pass 0 to disable (default 524288)
# Required env: $LOG
supervisor_loop() {
    local cmd="$1"
    local delay="${2:-10}"
    local rotate_bytes="${3:-524288}"
    [ -n "$LOG" ] || { echo "supervisor_loop: \$LOG must be set" >&2; return 1; }
    (
        while true; do
            [ "$rotate_bytes" -gt 0 ] 2>/dev/null && log_rotate "$rotate_bytes"
            log_line "supervisor: starting"
            sh -c "$cmd" >> "$LOG" 2>&1
            log_line "supervisor: child exited rc=$?, restarting in ${delay}s"
            sleep "$delay"
        done
    ) &
}
