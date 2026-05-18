#!/system/bin/sh

ui_print ""
ui_print "=================================="
ui_print "  bin-utils v1.0.0"
ui_print "  curl 8.20.0 + wget(busybox) + jq 1.8.1"
ui_print "=================================="
ui_print ""
ui_print "[*] /system/bin/{curl,wget,jq,busybox}"
ui_print "[*] /system/etc/cacert.pem"
ui_print ""

# wget is a symlink to busybox (busybox detects applet from argv[0])
ln -sf busybox "$MODPATH/system/bin/wget"

# Set perms
set_perm "$MODPATH/system/bin/curl"    0 2000 0755
set_perm "$MODPATH/system/bin/jq"      0 2000 0755
set_perm "$MODPATH/system/bin/busybox" 0 2000 0755
set_perm "$MODPATH/system/bin/sendat"  0 2000 0755
set_perm "$MODPATH/system/etc/cacert.pem" 0 0 0644

ui_print "[OK] Kurulum tamamlandi."
ui_print ""
ui_print "Kullanim:"
ui_print "  curl --cacert /system/etc/cacert.pem https://..."
ui_print "  veya: export CURL_CA_BUNDLE=/system/etc/cacert.pem"
ui_print "  wget --no-check-certificate ..."
ui_print "  echo '{...}' | jq ."
ui_print ""
