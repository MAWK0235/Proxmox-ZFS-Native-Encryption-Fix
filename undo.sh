#!/bin/bash
FILE="/usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm"
BACKUP="$FILE.bak"

echo "--- Proxmox ZFS Native Encryption Patch ---"

# 1. Ensure we have a clean backup
if [ ! -f "$BACKUP" ]; then
    cp "$FILE" "$BACKUP"
    echo "💾 Created backup: $BACKUP"
fi

# 2. Update the 'send' command flags
echo "Updating ZFS send command flags..."
sed -i "s/my \$cmd = \['zfs', 'send', '-Rpv'\];/my \$cmd = \['zfs', 'send', '-Rpvw'\];/g" "$FILE"

# 3. Inject load-key logic (Using $volname which is in scope)
if ! grep -q "load-key" "$FILE"; then
    echo "Injecting load-key command..."
    sed -i "/my \$cmd = \['zfs', 'send', '-Rpvw'\];/a \    eval { run_command(['zfs', 'load-key', \$volname]); };" "$FILE"
else
    echo "⚠️ load-key logic already exists."
fi

# 4. CRITICAL: Syntax Check
echo "Running Perl syntax verification..."
if perl -c "$FILE" 2>&1 | grep -q "syntax OK"; then
    echo "✅ Syntax check passed!"
    echo "🔄 Restarting services..."
    systemctl restart pvedaemon pveproxy pvestatd
    echo "Done."
else
    echo "❌ ERROR: Syntax check failed! Reverting changes."
    cp "$BACKUP" "$FILE"
    exit 1
fi
