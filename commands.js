// Add your commands here. Copy one block, change the fields.
// name: short title, desc: what it does, tags: search words, cmd: the one-liner
const commands = [
  {
    name: "nmap full tcp scan",
    desc: "All ports, then default scripts + version detection.",
    tags: ["recon", "nmap", "ports"],
    cmd: "nmap -p- --min-rate 5000 -sC -sV -oN nmap.txt TARGET"
  },
  {
    name: "ffuf directory fuzz",
    desc: "Fuzz for directories on a web server.",
    tags: ["web", "fuzz", "dirs", "ffuf"],
    cmd: "ffuf -u http://TARGET/FUZZ -w /usr/share/wordlists/dirb/common.txt -mc 200,301,302,403"
  },
  {
    name: "python http server",
    desc: "Serve the current folder to grab files from the target.",
    tags: ["transfer", "python", "web"],
    cmd: "python3 -m http.server 8000"
  },
  {
    name: "netcat listener",
    desc: "Catch a reverse shell.",
    tags: ["shell", "listener", "nc"],
    cmd: "nc -lvnp 4444"
  },
  {
    name: "tty upgrade",
    desc: "Get a proper interactive shell. Then ctrl+z, stty raw -echo; fg",
    tags: ["shell", "tty", "python"],
    cmd: "python3 -c 'import pty; pty.spawn(\"/bin/bash\")'"
  },
  {
    name: "find suid binaries",
    desc: "Look for SUID files, then check them on GTFOBins.",
    tags: ["privesc", "linux", "suid"],
    cmd: "find / -perm -4000 -type f 2>/dev/null"
  },
  {
    name: "sudo rights",
    desc: "What can the current user run as root?",
    tags: ["privesc", "linux", "sudo"],
    cmd: "sudo -l"
  },
  {
    name: "john with rockyou",
    desc: "Crack a hash file.",
    tags: ["crack", "hash", "john", "passwords"],
    cmd: "john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt"
  }
];
