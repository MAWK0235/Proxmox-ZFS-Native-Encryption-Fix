# Proxmox-ZFS-Native-Encryption-Fix
🔴 The Problem

By default, Proxmox VE does not support native ZFS encryption during replication or migration. When you try to move an encrypted Container (LXC) or VM (ZVOL), you encounter two major "stoppers":

    The "Raw" Flag Error: ZFS refuses to send an encrypted stream with properties unless the -w (raw) flag is used. Proxmox defaults to -Rpv, causing the task to fail instantly.

    The "Key Not Loaded" Error: Even if you manually send the data, the target node doesn't "load" the encryption key into RAM. When Proxmox tries to start the guest, it fails because the disk is locked.

🟢 The Fix

This tool applies a surgical patch to /usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm to:

    Modify the Send Command: Adds the -w flag to all ZFS send operations, allowing encrypted streams to be transferred intact.

    Automate Key Loading: Injects a zfs load-key trigger immediately after the volume is imported on the target node.

🚀 Installation

Run this one-liner on all nodes in your cluster:
Bash

curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/Proxmox-ZFS-Native-Encryption-Fix/main/patch.sh | bash

Alternatively, copy-paste your existing script:
Bash

sed -i.bak "s/my \$cmd = \['zfs', 'send', '-Rpv'\];/my \$cmd = \['zfs', 'send', '-Rpvw'\];/" /usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm
sed -i "/return \$storeid . ':' . \$dataset;/i \    eval { run_command(['zfs', 'load-key', \$zfspath]) };" /usr/share/perl5/PVE/Storage/ZFSPoolPlugin.pm
systemctl restart pvedaemon pveproxy pvestatd

🛠 Usage & Workflow
1. Same Key / Passphrase

For the best experience, ensure your destination node uses the same encryption passphrase or keyfile as the source.
2. Migration Behavior

    With Keyfile: If you use a keyfile stored in /etc/pve/priv/, migration is 100% automatic.

    With Passphrase: The migration task will "pause" at the very end. You must open the Node Shell on the target node, where you will see a prompt to enter your passphrase. Once entered, the container/VM will start automatically.

⚠️ Important Notes

    Updates: Proxmox updates will overwrite these changes. You should re-run the patch after updating libpve-storage-perl.

    Security: This patch does not bypass encryption; it simply allows Proxmox to handle the encrypted stream and triggers the standard ZFS prompt for the key.

🤝 Contributing

Feel free to open issues or pull requests if you find ways to make this even more robust (e.g., adding a dpkg hook to make the patch survive updates automatically).
