#!/usr/bin/env python3
"""Generate data/commands.json from the raw Notion command-reference export.

Each record: name | category | os | tool | useCase
We derive: id (slug), and a `tags` array = [category, os, ...tool tokens]
so the front-end can render filter chips + full-text search without a build step.
"""
import json, re, os

RAW = """
Rail on Ruby Directory Traversal|Exploitation|Linux|burpsuite|Certain versions of Rails on Ruby are vulnerable to Directory Traversal
Ruby YAML Dep Script|Privilege Escalation|Linux|ruby,yaml|Trying to take advantage of an update dependancies
Clear event logs|Exploitation|Windows|wevtutil, PowerShell|Indicator Removal - Clear Windows Event Logs
SSH key enumeration|Enumeration|Linux|find, ssh|Private Keys - SSH key discovery
On-target compilation|Exploitation|Both|gcc, csc.exe|Compile After Delivery - Build on target
evil-winrm - WinRM lateral movement|Lateral Movement|Windows|evil-winrm|Remote Services - Windows Remote Management
LFI - PHP filter base64|Exploitation|Both|curl, PHP filters|Local File Inclusion - Read PHP source
DCSync attack|Privilege Escalation|Windows|impacket, mimikatz|OS Credential Dumping - DCSync domain credentials
Chisel - SOCKS proxy tunneling|Lateral Movement|Both|chisel|Protocol Tunneling - Dynamic port forwarding
Burp Suite techniques|Enumeration|Both|Burp Suite|Application Layer Protocol - Web request manipulation
ssh -L <local>:<remote>:<port> user@host|Lateral Movement|Both|ssh|Local port forwarding
Invoke-Obfuscation - AV evasion|Exploitation|Windows|Invoke-Obfuscation|Obfuscated Files or Information - PowerShell obfuscation
Wireless attacks - aircrack-ng|Exploitation|Linux|aircrack-ng|Wireless Network Exploitation
Rubeus - Kerberos attacks|Exploitation|Windows|Rubeus|Steal or Forge Kerberos Tickets - Multiple attacks
nc file transfer|File Transfer|Both|netcat|Ingress Tool Transfer - Simple file transfer
Backdoor user creation|Persistence|Both|useradd, net user|Create Account - Backdoor users
Windows reverse shells - PowerShell|Exploitation|Windows|PowerShell|Command and Scripting - Windows reverse shells
Regsvr32 - Squiblydoo|Exploitation|Windows|regsvr32|LOLBin - Regsvr32 bypass
ARP spoofing - MitM|Exploitation|Linux|bettercap, arpspoof, ettercap|Man-in-the-Middle - ARP poisoning
Advanced WinRM usage|Lateral Movement|Windows|PowerShell, evil-winrm|Remote Services - WinRM command execution
Subdomain enumeration|Enumeration|Both|subfinder, amass|Active Scanning - Subdomain discovery
Linux /etc/passwd exploitation|Privilege Escalation|Linux|openssl, john|OS Credential Dumping - Writable passwd file
Keylogging techniques|Exploitation|Both|logkeys, PowerShell|Input Capture - Keylogging
Kerberoasting - GetUserSPNs|Exploitation|Windows|impacket, Rubeus|Steal or Forge Kerberos Tickets - Kerberoasting
LSA secrets dumping|Privilege Escalation|Windows|impacket, mimikatz|OS Credential Dumping - LSA secrets and cached creds
find / -perm -4000 2>/dev/null|Privilege Escalation|Linux|find|Find SUID binaries
URL parameter fuzzing|Enumeration|Both|wfuzz, arjun|Active Scanning - Parameter discovery
AD CS exploitation - Certipy|Privilege Escalation|Windows|certipy|Domain Policy Modification - AD CS abuse
gobuster dir -u <URL> -w <wordlist>|Enumeration|Both|gobuster|Directory brute forcing
LaZagne credential harvester|Privilege Escalation|Both|LaZagne|OS Credential Dumping - Multi-source credential extraction
Network packet capture - tcpdump|Enumeration|Both|tcpdump|Network Sniffing - Packet capture
SSH key theft and abuse|Privilege Escalation|Linux|ssh-keygen, ssh2john|Private Keys - SSH key exploitation
Screen capture techniques|Exploitation|Both|scrot, PowerShell|Screen Capture - Screenshots
PATH hijacking|Privilege Escalation|Linux|export|PATH Hijacking - Environment variable abuse
Hash cracking - hashcat|Exploitation|Both|hashcat|Credential Access - Password cracking
Group Policy abuse - GPP|Privilege Escalation|Windows|PowerView, gpp-decrypt|Domain Policy Modification - GPP password extraction
ldapdomaindump - AD enum|Enumeration|Windows|ldapdomaindump|Account Discovery - Comprehensive AD enumeration
Git repository disclosure|Enumeration|Both|git, git-dumper|Git Disclosure - Extract repository contents
Impacket lateral movement suite|Lateral Movement|Windows|impacket|Remote Services - Various SMB lateral movement
Process injection techniques|Exploitation|Windows|PowerSploit, donut|Process Injection - Inject into running processes
plink - SSH tunneling (Windows)|Lateral Movement|Windows|plink|Protocol Tunneling - SSH tunneling from Windows
chisel server -p <PORT> --reverse|Lateral Movement|Both|chisel|Setup chisel server for pivoting
Shell upgrade techniques|Exploitation|Linux|python, script, socat|Shell stabilization and upgrade
Redis enumeration & exploitation|Exploitation|Both|redis-cli|Database Exploitation - Redis RCE
Proxy and pivoting setup|Lateral Movement|Both|ssh, proxychains, chisel|Internal Proxy - Pivot through networks
WebSocket attacks|Exploitation|Both|wscat, Burp|WebSocket Exploitation
Linux cron persistence|Persistence|Linux|crontab, pspy|Scheduled Task/Job - Cron persistence
Linux password cracking|Privilege Escalation|Linux|john, hashcat|Credential Dumping - /etc/shadow
Advanced web shells|Exploitation|Both|PHP|Server Software Component - Advanced web shells
NanoDump - stealth LSASS dump|Privilege Escalation|Windows|nanodump, pypykatz|OS Credential Dumping - Evasive LSASS dumping
Email collection - local clients|Enumeration|Both|find, PowerShell|Email Collection - Local email extraction
HTTP request smuggling|Exploitation|Both|Burp, curl|HTTP Smuggling - Bypass security controls
Windows CMD enumeration|Enumeration|Windows|cmd|Windows Enumeration - CMD commands
FTP server setup|File Transfer|Both|pyftpdlib, pure-ftpd|File Transfer Protocols - FTP file transfer
RDP session hijacking|Lateral Movement|Windows|tscon, reg|Remote Desktop Protocol - Session hijacking
Base64 exfiltration|File Transfer|Both|base64, certutil|Exfiltration - Encode data for text-based exfil
Scheduled tasks - persistence|Persistence|Both|schtasks, cron|Scheduled Task/Job - Create persistence mechanism
CrackMapExec database|Enumeration|Windows|crackmapexec|Account Discovery - Track compromised credentials
Group Policy Preferences - cpassword|Privilege Escalation|Windows|PowerShell, Get-GPPPassword|GPP Credentials - Extract from SYSVOL
procdump + mimikatz - LSASS dump|Privilege Escalation|Windows|procdump, mimikatz|OS Credential Dumping - Stealth LSASS extraction
NetExec - next-gen CME|Lateral Movement|Both|netexec|Multi-protocol network exploitation
NFS enumeration and mounting|Enumeration|Linux|showmount, mount|Network Service Discovery - NFS shares
crackmapexec - mass exploitation|Lateral Movement|Windows|crackmapexec|Remote Services - Multi-protocol network attack
XXE - Extract files|Exploitation|Both|curl, Burp|XML External Entity - File extraction
SSTI - Server-Side Template Injection|Exploitation|Both|curl, Python|Server-Side Template Injection - RCE via templates
Container escape techniques|Privilege Escalation|Linux|docker, kubectl|Container Escape - Docker/Kubernetes breakout
Zip archive - data staging|File Transfer|Both|7z, zip, tar|Archive Collected Data - Compress before exfil
Web service C2 channels|Exploitation|Both|curl|Web Service - Legitimate service abuse
System information gathering|Enumeration|Both|systeminfo, uname|System Discovery - Comprehensive enumeration
Python library hijacking|Privilege Escalation|Linux|python|Command and Scripting Interpreter - Python privesc
Advanced Bash techniques|Exploitation|Linux|bash|Unix Shell - Advanced shell techniques
NTLM relay attacks|Lateral Movement|Windows|impacket-ntlmrelayx|Man-in-the-Middle - NTLM relay
UAC bypass techniques|Privilege Escalation|Windows|PowerShell|Abuse Elevation Control - UAC bypass
RDP access techniques|Lateral Movement|Windows|xfreerdp, rdesktop|Valid Accounts - RDP lateral movement
NoSQL injection|Exploitation|Both|MongoDB|Exploit Public-Facing Application - NoSQL injection
Kerbrute - AD password spray|Exploitation|Windows|kerbrute|Brute Force - Kerberos password spraying
MSFVenom payload generation|Exploitation|Both|msfvenom|Obfuscated Files or Information - Generate payloads
Advanced timestomping|Exploitation|Both|touch, PowerShell|Timestomp - Advanced timestamp manipulation
Virtualization detection|Enumeration|Linux|systemd-detect-virt|Environment Detection - Identify VMs/containers
Windows DLL Hijacking|Privilege Escalation|Windows|PowerShell|Hijack Execution Flow - DLL Search Order Hijacking
certutil - file download|File Transfer|Windows|certutil|Ingress Tool Transfer - Download files using LOLBin
Multi-hop pivoting|Lateral Movement|Both|ssh|Multi-hop Proxy - Chain pivots
Automated Windows privesc check|Privilege Escalation|Windows|winPEAS, PowerUp, PrivescCheck|Automated privilege escalation enumeration
LDAP enumeration - ldapsearch|Enumeration|Windows|ldapsearch|Remote System Discovery - Active Directory enumeration
Web fuzzing - gobuster/ffuf|Enumeration|Both|gobuster, ffuf, wfuzz|Exploit Public-Facing Application - Directory/parameter fuzzing
SSH tunneling and pivoting|Lateral Movement|Both|ssh|SSH Tunneling - Port forwarding
Delegation abuse - S4U2Self|Privilege Escalation|Windows|Rubeus, PowerView, impacket|Kerberos Delegation - Constrained/unconstrained delegation
Exfiltration over C2 channel|File Transfer|Both|curl, Invoke-WebRequest|Exfiltration Over C2 Channel - Upload via HTTP
PowerShell history enumeration|Enumeration|Windows|PowerShell|Command History - Extract PowerShell history
Linux reverse shells|Exploitation|Linux|bash, nc, python|Command and Scripting Interpreter - Reverse shells
Rootkit detection|Enumeration|Linux|chkrootkit, rkhunter|Rootkit Detection - Defensive checks
HTTP file servers|File Transfer|Both|python, php, uploadserver|Ingress Tool Transfer - HTTP file transfer
Mimikatz - credential dumping|Privilege Escalation|Windows|mimikatz|OS Credential Dumping - Extract credentials from memory
NFS enumeration and exploitation|Privilege Escalation|Linux|showmount, nmap|Network Service Discovery - NFS no_root_squash exploit
DNS exfiltration and tunneling|Exploitation|Both|dnscat2, iodine|DNS Exfiltration - Covert channel
SSTI payloads|Exploitation|Both|Various frameworks|Exploit Public-Facing Application - Template injection
Windows credential extraction - LaZagne|Privilege Escalation|Windows|lazagne, SessionGopher|Credential Access - Multiple sources
Sensitive file discovery|Enumeration|Both|find, PowerShell|File Discovery - Locate sensitive data
GTFOBins - SUID exploitation|Privilege Escalation|Linux|find, various|SUID Binary Exploitation - GTFOBins techniques
LD_PRELOAD exploitation|Privilege Escalation|Linux|gcc|Library Hijacking - LD_PRELOAD/LD_LIBRARY_PATH
Cloud metadata exploitation - AWS|Exploitation|Both|curl, aws cli|Cloud Instance Metadata API - AWS credentials
Ngrok - reverse proxy|Lateral Movement|Both|ngrok|Acquire Infrastructure - Expose services publicly
MSSQL enumeration & exploitation|Exploitation|Windows|impacket-mssqlclient|Database Exploitation - MSSQL command execution
crackmapexec smb <IP> -u <user> -p <pass>|Enumeration|Windows|crackmapexec|SMB enumeration and authentication
BloodHound Cypher queries|Enumeration|Windows|BloodHound, Neo4j|Permission Groups Discovery - AD analysis queries
Create hidden accounts|Persistence|Windows|net, PowerShell|Create Account - Hidden local/domain accounts
socat - port forwarding|Lateral Movement|Both|socat|Protocol Tunneling - Port forwarding relay
LAPS abuse|Privilege Escalation|Windows|PowerView, CrackMapExec|Valid Accounts - LAPS password extraction
Race condition exploitation|Exploitation|Both|Burp Turbo Intruder|Race Condition - Timing attacks
SSH tunneling techniques|Lateral Movement|Both|ssh|Remote Services - SSH port forwarding and tunneling
DNS zone transfer - dig/fierce|Enumeration|Both|dig, fierce|Active Scanning - DNS zone transfer
Windows PowerShell reverse shells|Exploitation|Windows|PowerShell|Command and Scripting Interpreter - Windows reverse shells
DNS tunneling - C2|Lateral Movement|Both|dnscat2, iodine|Application Layer Protocol - DNS C2 channel
LFI to RCE - Log poisoning|Exploitation|Linux|netcat, curl|Local File Inclusion - Escalate to RCE
Rundll32 execution - LOLBin|Exploitation|Windows|rundll32|LOLBin - Rundll32 abuse
SSH keys - authorized_keys|Persistence|Linux|ssh-keygen|Account Manipulation - SSH Authorized Keys
Windows Token Impersonation|Privilege Escalation|Windows|PowerShell, incognito|Access Token Manipulation - Impersonate privileged tokens
AMSI bypass - PowerShell|Exploitation|Windows|PowerShell|Impair Defenses - Bypass AMSI
Registry persistence - Run keys|Persistence|Windows|reg|Boot or Logon Autostart - Registry Run keys
Cron job exploitation|Privilege Escalation|Linux|crontab, pspy|Cron - Scheduled job abuse
Proxychains configuration|Lateral Movement|Linux|proxychains|Proxy - Pivot through compromised hosts
SSRF - Internal network access|Exploitation|Both|curl, Burp|Server-Side Request Forgery - Access internal services
python3 -m http.server 8000|File Transfer|Linux|python|Quick HTTP server for file transfer
Advanced nmap techniques|Enumeration|Both|nmap|Active Scanning - Fast comprehensive port scanning
nc -lvnp <PORT>|Exploitation|Both|netcat|Setup listener for reverse shell
sudo -l|Privilege Escalation|Linux|sudo|Check sudo privileges
SNMP enumeration - snmpwalk|Enumeration|Both|snmpwalk, onesixtyone|Network Service Discovery - SNMP information gathering
Malicious service creation|Persistence|Windows|sc, PowerShell|Windows Services - Persistence
AS-REP Roasting - GetNPUsers|Exploitation|Windows|impacket, Rubeus|Steal or Forge Kerberos Tickets - AS-REP Roasting
Timestomping - modify timestamps|Exploitation|Both|PowerShell, touch|Indicator Removal - Timestomp
Java deserialization - ysoserial|Exploitation|Both|ysoserial|Deserialization - Java RCE
DCOM lateral movement|Lateral Movement|Windows|PowerShell, impacket|DCOM - Distributed Component Object Model
CSRF token bypass|Exploitation|Both|Burp, curl|Cross-Site Request Forgery
Windows Registry enumeration|Enumeration|Windows|reg, PowerShell|Query Registry - Find credentials and config
JWT attacks - Signature bypass|Exploitation|Both|jwt_tool, Python|JWT - Forge tokens and bypass authentication
Packet capture - tcpdump/tshark|Enumeration|Linux|tcpdump, tshark, wireshark|Network Sniffing - Capture and analyze traffic
Linux capabilities exploitation|Privilege Escalation|Linux|getcap, python|Capabilities - CAP_SETUID and others
Windows credential files|Enumeration|Windows|PowerShell, cmdkey|Credentials from Files - Extract saved credentials
Windows Defender - disable/bypass|Exploitation|Windows|PowerShell|Impair Defenses - Disable Windows Defender
GraphQL enumeration & exploitation|Exploitation|Both|curl, graphql-cop|API Exploitation - GraphQL introspection
Password spraying - automation|Exploitation|Windows|crackmapexec, kerbrute|Brute Force - Password spraying
impacket-psexec - lateral movement|Lateral Movement|Windows|impacket|Remote Services - SMB/Admin Share lateral movement
Living off the land - LOLBins|Exploitation|Windows|certutil, mshta, regsvr32|Defense Evasion - Living off the land binaries
Responder - LLMNR/NBT-NS poisoning|Exploitation|Windows|Responder|Man-in-the-Middle - Network credential capture
nslookup / dig - DNS enumeration|Enumeration|Both|nslookup, dig|Active Scanning - DNS queries for infrastructure mapping
SMB enumeration - enum4linux|Enumeration|Windows|enum4linux, smbclient|Network Service Discovery - SMB/CIFS enumeration
Hide files and artifacts|Exploitation|Both|attrib, chattr|Hidden Files - Conceal malware
Linux reverse shells - one-liners|Exploitation|Linux|bash, python, perl|Command and Scripting - Reverse shells
Linux credential hunting|Enumeration|Linux|grep, find|Credentials In Files - Find passwords on Linux
AD enumeration - native tools|Enumeration|Windows|net, nltest, PowerShell|Remote System Discovery - Active Directory recon
ligolo-ng - advanced pivoting|Lateral Movement|Both|ligolo-ng|Protocol Tunneling - Network pivoting
Windows Clipboard stealing|Enumeration|Windows|PowerShell|Clipboard Data - Extract clipboard contents
nmap -sC -sV -oA scan <IP>|Enumeration|Both|nmap|Default script scan with version detection
NoSQL injection - MongoDB|Exploitation|Both|curl, Burp|NoSQL Injection - MongoDB bypass
AlwaysInstallElevated exploit|Privilege Escalation|Windows|msfvenom, PowerShell|Abuse Elevation Control - MSI package privilege escalation
Force NTLM authentication|Exploitation|Windows|Responder, SCF files|Forced Authentication - Capture NTLM hashes
Domain fronting techniques|Exploitation|Both|curl|Domain Fronting - C2 obfuscation
Email enumeration - SMTP|Enumeration|Both|smtp-user-enum|Email Account Discovery
MySQL enumeration & exploitation|Exploitation|Both|mysql|Database Exploitation - MySQL command execution
Golden/Silver ticket attacks|Privilege Escalation|Windows|mimikatz, impacket|Steal or Forge Kerberos Tickets - Golden/Silver tickets
PowerShell download cradle|Exploitation|Windows|PowerShell|Command and Scripting Interpreter - Download and execute
MSSQL exploitation|Exploitation|Windows|impacket-mssqlclient|Exploitation of Remote Services - MSSQL command execution
python3 -c 'import pty;pty.spawn("/bin/bash")'|Exploitation|Linux|python|Upgrade to TTY shell
LFI exploitation techniques|Exploitation|Both|curl|Exploit Public-Facing Application - LFI to RCE
Automated data collection|Exploitation|Both|bash, PowerShell|Automated Collection - Data gathering
WordPress enumeration - wpscan|Enumeration|Both|wpscan|CMS Enumeration - WordPress
Password brute force - Hydra|Exploitation|Both|hydra, medusa|Brute Force - Multiple protocols
Meterpreter payloads - msfvenom|Exploitation|Both|msfvenom|Payload Generation - Meterpreter shells
PowerView - AD enumeration|Enumeration|Windows|PowerView|Domain Trust Discovery - PowerShell AD enumeration
Privilege escalation checks - automated|Privilege Escalation|Both|LinEnum, winPEAS|Automated privilege escalation enumeration
Python post-exploitation|Exploitation|Both|python|Python - Reverse shells and file operations
Directory fuzzing - web content|Enumeration|Both|ffuf, feroxbuster|Active Scanning - Directory/file discovery
Malicious Office macros|Exploitation|Windows|msfvenom, VBA|Visual Basic - Macro payload delivery
ARP spoofing - arpspoof/ettercap|Exploitation|Linux|arpspoof, ettercap|Man-in-the-Middle - ARP poisoning
Web shells and backdoors|Exploitation|Both|PHP, ASP, JSP|Command and Scripting Interpreter - Web shell deployment
BloodHound - AD enumeration|Enumeration|Windows|BloodHound, SharpHound|Domain Trust Discovery - Active Directory attack paths
Windows Service exploitation|Privilege Escalation|Windows|sc, PowerShell|Service Exploitation - Modify/create services
API key enumeration|Enumeration|Both|grep, trufflehog|Credentials from Files - API keys
Startup folder persistence|Persistence|Windows|PowerShell, cmd|Startup - Autorun persistence
GTFOBins - sudo exploitation|Privilege Escalation|Linux|sudo, various|Sudo Abuse - GTFOBins techniques
VNC enumeration and access|Lateral Movement|Both|vncviewer, nmap|VNC - Remote access
Flask session cookie decoding|Exploitation|Both|flask-unsign|Session Hijacking - Flask cookie manipulation
Hash cracking - hashcat/john|Exploitation|Both|hashcat, john|Brute Force - Crack password hashes
Anti-forensics - file deletion|Exploitation|Both|shred, wevtutil|Indicator Removal - Cover tracks
bitsadmin - file download|File Transfer|Windows|bitsadmin|Ingress Tool Transfer - Background file download
NTDS.dit extraction|Privilege Escalation|Windows|vssadmin, impacket|OS Credential Dumping - Extract NTDS.dit
Hydra - multi-protocol brute force|Exploitation|Both|hydra, crowbar|Brute Force - Password attacks on services
Python pickle deserialization|Exploitation|Both|python|Deserialization - Python RCE
Steganography detection|Enumeration|Both|steghide, stegseek|Data from Information Repositories - Hidden data
Payload encoding techniques|Exploitation|Both|base64, xxd|Obfuscation - Encode payloads
Windows Defender bypass - AMSI|Exploitation|Windows|PowerShell|Defense Evasion - AMSI bypass techniques
Linux kernel exploit suggester|Privilege Escalation|Linux|linux-exploit-suggester|Exploitation for Privilege Escalation - Kernel exploits
RPC enumeration - rpcclient|Enumeration|Windows|rpcclient|RPC Enumeration - Windows domain info
SUID binary privilege escalation|Privilege Escalation|Linux|find, GTFOBins|Abuse Elevation Control - SUID exploitation
Advanced Kerberoasting|Exploitation|Windows|Rubeus, impacket, PowerView|Steal or Forge Kerberos Tickets - Kerberoasting
HTTPS exfiltration|Exploitation|Both|curl, PowerShell|HTTPS Exfil - Encrypted exfiltration
Pass-the-Ticket|Lateral Movement|Windows|mimikatz, Rubeus, impacket|Use Alternate Authentication Material - Pass the Ticket
WMI persistence|Persistence|Windows|wmic, PowerShell|Event Triggered Execution - WMI Event Subscription
Docker container escape|Privilege Escalation|Linux|docker|Exploitation for Privilege Escalation - Docker escape
RDP enumeration and access|Lateral Movement|Windows|xfreerdp, rdesktop|Remote Desktop Protocol
"""

def slugify(s):
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")

records = []
seen = {}
for line in RAW.strip().splitlines():
    line = line.strip()
    if not line:
        continue
    parts = line.split("|")
    if len(parts) != 5:
        raise SystemExit(f"Bad line ({len(parts)} fields): {line}")
    name, category, os_, tool, use_case = [p.strip() for p in parts]
    base = slugify(name)
    seen[base] = seen.get(base, 0) + 1
    cid = base if seen[base] == 1 else f"{base}-{seen[base]}"
    tool_tokens = [t.strip() for t in re.split(r"[,/]", tool) if t.strip()]
    tags = sorted(set([category, os_] + tool_tokens), key=str.lower)
    records.append({
        "id": cid,
        "name": name,
        "category": category,
        "os": os_,
        "tool": tool,
        "useCase": use_case,
        "tags": tags,
    })

out_path = os.path.join(os.path.dirname(__file__), "..", "data", "commands.json")
with open(out_path, "w") as f:
    json.dump({"count": len(records), "commands": records}, f, indent=2, ensure_ascii=False)

print(f"Wrote {len(records)} commands to {os.path.normpath(out_path)}")
# Quick stats
from collections import Counter
print("By category:", dict(Counter(r["category"] for r in records)))
print("By OS:", dict(Counter(r["os"] for r in records)))
