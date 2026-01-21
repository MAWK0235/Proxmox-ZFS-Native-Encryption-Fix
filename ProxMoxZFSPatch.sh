#!/bin/bash
FILE="/usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm"

# Create a backup only if one doesn't exist yet
if [ ! -f "$FILE.bak" ]; then
    cp "$FILE" "$FILE.bak"
    echo "Created backup at $FILE.bak"
fi

# 1. Patch the Send command (adds -w)
sed -i "s/my \$cmd = \['zfs', 'send', '-Rpv'\];/my \$cmd = \['zfs', 'send', '-Rpvw'\];/" "$FILE"

# 2. Patch the Import command (adds load-key)
# We use a check to make sure we don't add the line twice
if ! grep -q "zfs', 'load-key" "$FILE"; then
    sed -i "/return \$storeid . ':' . \$dataset;/i \    eval { run_command(['zfs', 'load-key', \$zfspath]) };" "$FILE"
fi

systemctl restart pvedaemon pveproxy pvestatd
echo "Patch applied successfully."
