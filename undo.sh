#!/bin/bash

FILE="/usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm"
BACKUP="/usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm.bak"

echo "Reverting Proxmox ZFS Native Encryption Patch..."

if [ -f "$BACKUP" ]; then
    # Method 1: Restore from the backup file created by the patch script
    mv "$BACKUP" "$FILE"
    echo "✅ Success: Restored from backup file."
else
    # Method 2: Manual search and replace if backup is missing
    echo "⚠️ Backup file not found. Attempting manual revert..."
    sed -i "s/my \$cmd = \['zfs', 'send', '-Rpvw'\];/my \$cmd = \['zfs', 'send', '-Rpv'\];/" "$FILE"
    sed -i "/eval { run_command(\['zfs', 'load-key', \$zfspath\]) };/d" "$FILE"
    echo "✅ Success: Manual revert completed."
fi

# Restart services to apply changes
echo "🔄 Restarting Proxmox services..."
systemctl restart pvedaemon pveproxy pvestatd

echo "Done. Your ZFS storage plugin is back to stock settings."
