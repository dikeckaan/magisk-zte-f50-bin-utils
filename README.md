# bin-utils

Common CLI tools for Android arm64 devices — packaged as a Magisk module.

## What's inside

| Binary | Path | Source | Use |
|---|---|---|---|
| `curl` 8.20.0 | `/system/bin/curl` | [stunnel/static-curl](https://github.com/stunnel/static-curl) (musl static) | HTTPS, REST, file download |
| `wget` | `/system/bin/wget` → symlink to `busybox` | [busybox](https://busybox.net) applet | Simple HTTP file download |
| `busybox` | `/system/bin/busybox` | aarch64 build | wget + many other applets |
| `jq` 1.8.1 | `/system/bin/jq` | [jqlang/jq](https://github.com/jqlang/jq) | JSON parsing |
| `sendat` | `/system/bin/sendat` | UFI-TOOLS' [send_at.go](https://github.com/kanoqwq/UFI-TOOLS/blob/http-server-version/app/src/main/assets/shell/send_at.go) — UPX-packed static aarch64 | Send AT commands to the cellular modem |
| `bash` 5.2.015 | `/system/bin/bash` | [robxu9/bash-static](https://github.com/robxu9/bash-static) (musl static) | Modern shell with associative arrays, indirect expansion, `printf -v` — used by statusbot for i18n and other features |
| Mozilla CA bundle | `/system/etc/cacert.pem` | [curl.se/ca/cacert.pem](https://curl.se/ca/cacert.pem) | TLS root certificates for HTTPS |

## Why this is useful

Android's `/system/bin` ships with toybox which omits `curl`, `wget`, and `jq`. This module fills that gap with proven static builds so shell scripts and other Magisk modules can do HTTPS requests and JSON parsing without bundling their own binaries.

## Requirements

- Magisk 20.4+
- Android arm64 (`arm64-v8a` ABI)

## Installation

1. Flash `bin-utils.zip` from Magisk Manager.
2. Reboot.

After reboot the binaries live in `/system/bin` via Magisk's overlay; they're available to every shell, root or not.

## Usage examples

```sh
# HTTPS with TLS verification (CA bundle is at /system/etc/cacert.pem)
curl --cacert /system/etc/cacert.pem https://api.example.com/data

# Or set it globally
export CURL_CA_BUNDLE=/system/etc/cacert.pem
curl https://api.example.com/data

# wget (busybox-style; --no-check-certificate if no CA)
wget --no-check-certificate https://example.com/file.zip

# JSON parsing
curl -s https://api.github.com/repos/foo/bar | jq '.stargazers_count'

# bash features (statusbot uses these for i18n)
bash -c 'declare -A m; m[key]="value"; echo "${m[key]}"'
bash -c 'var=MSG_HELLO; MSG_HELLO=hi; echo "${!var}"'

# AT command to cellular modem (sendat -c <AT-cmd> -n <slot 0|1>)
sendat -c "AT+CSQ" -n 0          # signal quality
sendat -c "AT+CGSN" -n 0         # read IMEI
sendat -c "AT+COPS?" -n 0        # current operator
```

## Bootloop safety

This module only **adds** new files to `/system/bin` and `/system/etc`; no existing system file is replaced. There is no `service.sh`, `post-fs-data.sh`, or init script. Even if a binary turned out to be corrupt only its callers would fail — the boot sequence is not touched.

## File layout (after install)

```
/data/adb/modules/bin-utils/
├── module.prop
├── customize.sh                  # sets permissions, creates wget symlink
├── system/
│   ├── bin/
│   │   ├── curl
│   │   ├── jq
│   │   ├── busybox
│   │   ├── bash                  # static 5.2 (~2.3 MB)
│   │   ├── sendat
│   │   └── wget -> busybox       # busybox detects applet by argv[0]
│   └── etc/
│       └── cacert.pem
└── META-INF/com/google/android/...
```

## Uninstall

Remove from Magisk Manager and reboot. Nothing in `/data` is touched; binaries simply disappear from `/system/bin` on next boot.

## License

Each bundled binary keeps its own upstream license. This packaging is provided as-is.
