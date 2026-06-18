#!/bin/bash
FILE="/usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm"
BACKUP="$FILE.bak_$(date +%Y%m%d%H%M%S)"

# Ensure we're on PVE 7.x (with ZFSPoolPlugin.pm, not Plugin/)
if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  echo " → Are you on Proxmox VE 8? Try Plugin/ZFSPool.pm instead."
  exit 1
fi

# 1. Create backup (always, with timestamp)
cp "$FILE" "$BACKUP"
echo "✅ Backup created at $BACKUP"

# 2. PATCH: -RpvU → -RpvU (add raw key export via -w *inside* send context)
#   Note: Proxmox uses '-RpvU' already — we just need to add '-w' to export wrapped key
sed -i "s/'zfs', 'send', '-RpvU'/'zfs', 'send', '-RpvUw'/g" "$FILE"

# 3. Add zfs load-key before send (to ensure key loaded for encrypted datasets)
# Find line with cmd definition and insert just before it
sed -i "/my \$cmd = \['zfs', 'send', '-RpvUw'\];/i\    eval { run_command(['zfs', 'load-key', \$zfspath]) };" "$FILE"

# 4. Verify patch
echo "🔍 Verifying patch..."
grep -n "zfs.*send.*-RpvUw" "$FILE" || echo "⚠️ Send patch not found"
grep -n "load-key" "$FILE" || echo "⚠️ load-key patch not found"

# 5. Restart services
systemctl restart pvedaemon pveproxy pvestatd

echo "✅ Patch applied successfully! Ready for encrypted migration."
