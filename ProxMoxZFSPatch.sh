#!/bin/bash
# 1. Patch the Send command (Raw flag)
sed -i.bak "s/my \$cmd = \['zfs', 'send', '-Rpv'\];/my \$cmd = \['zfs', 'send', '-Rpvw'\];/" /usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm

# 2. Patch the Import command (Auto-load trigger)
# We use a simpler match to avoid hidden character issues
sed -i "/return \$storeid . ':' . \$dataset;/i \    eval { run_command(['zfs', 'load-key', \$zfspath]) };" /usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm

# 3. Restart services once
systemctl restart pvedaemon pveproxy pvestatd
