#!/system/bin/sh

ui_print ""
ui_print "=================================="
ui_print "  bin-utils v1.3.0"
ui_print "  curl 8.20.0 + wget(busybox) + jq 1.8.1"
ui_print "  bash 5.2.015 (static) + sendat"
ui_print "  + lib/common.sh — shared helpers"
ui_print "=================================="
ui_print ""
ui_print "[*] /system/bin/{curl,wget,jq,busybox,bash,sendat}"
ui_print "[*] /system/etc/cacert.pem"
ui_print "[*] lib/common.sh (source from any module's service.sh)"
ui_print ""

# wget is a symlink to busybox (busybox detects applet from argv[0])
ln -sf busybox "$MODPATH/system/bin/wget"

# Permissions for all bundled binaries
set_perm "$MODPATH/system/bin/curl"    0 2000 0755
set_perm "$MODPATH/system/bin/jq"      0 2000 0755
set_perm "$MODPATH/system/bin/busybox" 0 2000 0755
set_perm "$MODPATH/system/bin/sendat"  0 2000 0755
set_perm "$MODPATH/system/bin/bash"    0 2000 0755
set_perm "$MODPATH/system/etc/cacert.pem" 0 0 0644

# Shared helper library — modules source this from service.sh.
# Lives under MODPATH/lib (not system/), so no overlay-mount; sourced
# directly from /data/adb/modules/bin-utils/lib/common.sh.
set_perm "$MODPATH/lib/common.sh" 0 0 0644

ui_print "[OK] Installation complete."
ui_print ""
ui_print "Usage examples:"
ui_print "  curl --cacert /system/etc/cacert.pem https://..."
ui_print "  echo '{...}' | jq ."
ui_print "  bash -c 'declare -A m; m[k]=v; echo \${m[k]}'"
ui_print ""
