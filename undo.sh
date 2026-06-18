#!/bin/bash
FILE="/usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm"
BACKUP="$FILE.bak"

echo "Reverting Proxmox ZFS Native Encryption Patch..."

if [ -f "$BACKUP" ]; then
    # Method 1: Restore from backup (always safe & complete)
    cp "$BACKUP" "$FILE"
    echo "✅ Restored from backup: $BACKUP"
else
    # Method 2: Try to revert common patterns (fallback)
    echo "⚠️ Backup missing. Attempting manual revert..."
    sed -i "s/'zfs', 'send', '-RpvUw'/'zfs', 'send', '-RpvU'/g" "$FILE"
    sed -i "s/'zfs', 'send', '-RpvU'/'zfs', 'send', '-Rpv'/g" "$FILE"  # handle legacy -RpvU
    sed -i "/eval { run_command(\['zfs', 'load-key', \$zfspath\]) };/d" "$FILE"
    echo "✅ Manual revert attempted."
fi

# Double-check revert worked
grep -q "load-key" "$FILE" && echo "❌ load-key still present!" || echo "✅ load-key removed"
grep -q "'-RpvUw'" "$FILE" && echo "❌ -RpvUw still present!" || echo "✅ -RpvUw removed"

echo "🔄 Restarting services..."
systemctl restart pvedaemon pveproxy pvestatd

echo "Done. Back to stock encryption behavior."
