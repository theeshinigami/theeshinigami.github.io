#!/usr/bin/env bash
#
# ctf-autoflag.sh — Automated CTF service scanner & flag hunter
#
# Usage:
#   ./ctf-autoflag.sh <service> <target_ip> <flag_prefix> [port] [options]
#   ./ctf-autoflag.sh --list
#
# The flag_prefix is REQUIRED. If flags look like csaw{...}, pass "csaw".
# The script builds the regex automatically: <prefix>\{[^}]+\}
#
# Supported services: http, ftp, ssh, smb, telnet, dns, smtp, mysql, redis, snmp
#
# Options:
#   -u <user>       Username (for services that need auth)
#   -p <pass>       Password (for services that need auth)
#   -w <wordlist>   Wordlist for directory busting (http) or brute force
#   -d <domain>     Domain name (required for dns)
#   -o <dir>        Output directory (default: ./treasure)

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
BLU='\033[0;34m'
CYN='\033[0;36m'
RST='\033[0m'

# ─── Defaults ─────────────────────────────────────────────────────────────────
TARGET=""
SERVICE=""
FLAG_PREFIX=""
FLAG_REGEX=""
PORT=""
USERNAME=""
PASSWORD=""
WORDLIST=""
DOMAIN=""
OUTPUT_DIR="./treasure"
TREASURE_FILE=""

SUPPORTED_SERVICES=("http" "ftp" "ssh" "smb" "telnet" "dns" "smtp" "mysql" "redis" "snmp")

declare -A DEFAULT_PORTS=(
    [http]=80
    [ftp]=21
    [ssh]=22
    [smb]=445
    [telnet]=23
    [dns]=53
    [smtp]=25
    [mysql]=3306
    [redis]=6379
    [snmp]=161
)

# ─── Helpers ──────────────────────────────────────────────────────────────────
info()    { echo -e "${BLU}[*]${RST} $*"; }
success() { echo -e "${GRN}[+]${RST} $*"; }
warn()    { echo -e "${YLW}[!]${RST} $*"; }
fail()    { echo -e "${RED}[-]${RST} $*"; }
banner()  {
    echo -e "\n${CYN}════════════════════════════════════════${RST}"
    echo -e "${CYN}  $*${RST}"
    echo -e "${CYN}════════════════════════════════════════${RST}\n"
}

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 && -n "$TREASURE_FILE" ]]; then
        treasure_write ""
        treasure_write "[!] Script exited with code ${exit_code}"
    fi
    exit "$exit_code"
}
trap cleanup EXIT

treasure_init() {
    mkdir -p "$OUTPUT_DIR"
    TREASURE_FILE="${OUTPUT_DIR}/${SERVICE}_${TARGET}_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "═══════════════════════════════════════════════"
        echo "  CTF Auto-Flag Treasure Report"
        echo "  Service: ${SERVICE^^} | Target: ${TARGET}:${PORT}"
        echo "  Flag format: ${FLAG_PREFIX}{...}"
        echo "  Date: $(date)"
        echo "═══════════════════════════════════════════════"
        echo ""
    } > "$TREASURE_FILE"
    info "Treasure file: ${TREASURE_FILE}"
}

treasure_write() {
    echo "$*" >> "$TREASURE_FILE"
}

treasure_section() {
    {
        echo ""
        echo "--- $* ---"
    } >> "$TREASURE_FILE"
}

# Search text for flags matching the user-provided prefix
hunt_flags() {
    local text="$1"
    local source="${2:-unknown}"
    local found
    found=$(echo "$text" | grep -oEi "$FLAG_REGEX" | sort -u) || true
    if [[ -n "$found" ]]; then
        success "FLAG(S) FOUND in ${source}!"
        echo "$found" | while IFS= read -r f; do
            success "  >>> $f"
            treasure_write "[FLAG] $f  (source: ${source})"
        done
        return 0
    fi
    return 1
}

require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        fail "Required tool '${1}' is not installed."
        exit 1
    fi
}

check_port() {
    if ! timeout 5 bash -c "echo >/dev/tcp/${TARGET}/${PORT}" 2>/dev/null; then
        fail "Port ${PORT} on ${TARGET} appears closed or filtered."
        exit 1
    fi
    success "Port ${PORT} is open on ${TARGET}"
}

# ─── Usage / List ─────────────────────────────────────────────────────────────

usage() {
    cat <<'USAGE'

  ╔═══════════════════════════════════════════════════════════════╗
  ║              ctf-autoflag.sh — CTF Flag Hunter               ║
  ╚═══════════════════════════════════════════════════════════════╝

SYNTAX
  ctf-autoflag.sh <service> <target_ip> <flag_prefix> [port] [options]
  ctf-autoflag.sh --list              List supported services
  ctf-autoflag.sh --help              Show this help page
  ctf-autoflag.sh --help-service <s>  Show detailed help for one service

REQUIRED ARGUMENTS
  <service>       The service to attack (see --list for all 10)
  <target_ip>     IP address of the target machine
  <flag_prefix>   The letters before the {} in the flag format.
                  This is REQUIRED so the script knows what to look for.

                  If flags look like:    You pass:
                    flag{...}              flag
                    picoCTF{...}           picoCTF
                    csaw{...}              csaw
                    HTB{...}               HTB

                  The script builds the regex automatically:
                    <prefix>\{[^}]+\}

OPTIONAL ARGUMENTS
  [port]          Override the default port for the service.
                  Must come right after flag_prefix if used.

OPTIONS
  -u <user>       Username for services that support authentication.
                  Used by: ftp, ssh, smb, mysql

  -p <pass>       Password for services that support authentication.
                  Used by: ftp, ssh, smb, mysql, redis
                  For empty passwords, use: -p ""

  -w <wordlist>   Path to a wordlist file for directory busting.
                  Used by: http
                  Uses gobuster if installed, falls back to dirb, then curl.

  -d <domain>     Domain name for DNS queries.
                  Used by: dns (REQUIRED for zone transfers and record queries)
                  Without -d, DNS only does a reverse lookup on the target IP.

  -o <dir>        Output directory for treasure files and downloads.
                  Default: ./treasure
                  Structure:
                    ./treasure/<service>_<ip>_<timestamp>.txt   (reports)
                    ./treasure/downloads/<service>_<ip>/        (files)

QUICK EXAMPLES
  ./ctf-autoflag.sh http 10.10.10.1 flag
  ./ctf-autoflag.sh http 10.10.10.1 flag -w /usr/share/wordlists/dirb/common.txt
  ./ctf-autoflag.sh ftp 10.10.10.1 picoCTF 2121
  ./ctf-autoflag.sh ftp 10.10.10.1 picoCTF -u admin -p secret
  ./ctf-autoflag.sh ssh 10.10.10.1 HTB -u root -p toor
  ./ctf-autoflag.sh smb 10.10.10.1 flag -u guest -p ""
  ./ctf-autoflag.sh dns 10.10.10.1 ctf -d challenge.ctf
  ./ctf-autoflag.sh mysql 10.10.10.1 FLAG -u root -p ""
  ./ctf-autoflag.sh redis 10.10.10.1 flag -p secretpass
  ./ctf-autoflag.sh snmp 10.10.10.1 flag

OUTPUT
  Every run creates a treasure file at:
    ./treasure/<service>_<ip>_<timestamp>.txt

  This file contains all findings: banners, listings, file contents,
  and any captured flags marked with [FLAG]. At the end of each run,
  the script prints a summary of all flags found.

  Services that download files (ftp, smb) save them to:
    ./treasure/downloads/<service>_<ip>/

  You will be prompted (y/n) before any file downloads begin.

USAGE
    exit 0
}

help_service() {
    local svc="${1,,}"
    case "$svc" in
    http)
        cat <<'EOF'

  ═══ HTTP (port 80) ═══

  What it does:
    1. Fetches the homepage and all HTTP response headers
    2. Checks ~35 common CTF paths:
       /flag.txt, /robots.txt, /.git/HEAD, /.env, /admin, /backup,
       /api/flag, /console, /config.php, /uploads, and more
    3. Extracts HTML comments (<!-- ... -->) from the homepage
    4. Optional directory busting with a wordlist (-w)

  Required tools: curl
  Optional tools: gobuster, dirb (for wordlist dir busting)

  Options used:
    -w <wordlist>   Enable directory busting with this wordlist file

  Examples:
    ./ctf-autoflag.sh http 10.10.10.1 flag
    ./ctf-autoflag.sh http 10.10.10.1 flag 8080
    ./ctf-autoflag.sh http 10.10.10.1 flag -w /usr/share/wordlists/dirb/common.txt

  Tips:
    - Flags commonly hide in HTTP headers (X-Flag, X-Secret), HTML
      comments, /robots.txt, and .git leaks
    - If the target runs HTTPS, change the port but note this script
      uses http:// — for HTTPS you may need to test manually
EOF
        ;;
    ftp)
        cat <<'EOF'

  ═══ FTP (port 21) ═══

  What it does:
    1. Tests anonymous login (anonymous:anonymous@)
    2. If anonymous works: shows file listing, asks (y/n) to download
    3. If -u/-p supplied: tests those credentials too
    4. Downloaded files are scanned for flags automatically
    5. Files saved to ./treasure/downloads/ftp_<ip>/

  Required tools: curl

  Options used:
    -u <user>   Username to test
    -p <pass>   Password to test

  Examples:
    ./ctf-autoflag.sh ftp 10.10.10.1 flag
    ./ctf-autoflag.sh ftp 10.10.10.1 flag 2121
    ./ctf-autoflag.sh ftp 10.10.10.1 picoCTF -u ftpuser -p letmein

  Tips:
    - Anonymous FTP is the #1 CTF FTP vector
    - Flags hide in innocent-looking files (readme.txt, backup.bak, .hidden)
    - You will be prompted before downloading — say no if file count is huge
EOF
        ;;
    ssh)
        cat <<'EOF'

  ═══ SSH (port 22) ═══

  What it does:
    1. Grabs the SSH version banner (via nc, ncat, or /dev/tcp)
    2. If -u/-p supplied and sshpass is installed:
       - Logs in and cats common flag paths:
         /flag*, /home/*/flag*, /root/flag*, /tmp/flag*, /opt/flag*
       - Lists directory contents of /, /home/, /root/, /tmp/, /opt/
    3. If sshpass is not installed: shows the manual ssh command

  Required tools: nc or ncat (for banner), sshpass (for auto-login)
  Install sshpass: sudo apt install sshpass

  Options used:
    -u <user>   SSH username
    -p <pass>   SSH password

  Examples:
    ./ctf-autoflag.sh ssh 10.10.10.1 flag
    ./ctf-autoflag.sh ssh 10.10.10.1 HTB 2222 -u root -p password123

  Tips:
    - Without -u/-p, this only grabs the banner
    - sshpass is needed for automated login — without it you get
      a manual command to copy-paste
    - CTF SSH flags are usually in /root/flag.txt or /home/<user>/flag.txt
EOF
        ;;
    smb)
        cat <<'EOF'

  ═══ SMB (port 445) ═══

  What it does:
    1. Lists shares with anonymous (null session) access
    2. For each readable share: recursive file listing
    3. Asks (y/n) per share before downloading files
    4. If -u/-p supplied: repeats with those credentials
    5. Runs enum4linux if installed (users, groups, policies)
    6. Files saved to ./treasure/downloads/smb_<ip>/<share>/

  Required tools: smbclient
  Optional tools: enum4linux
  Install: sudo apt install smbclient

  Options used:
    -u <user>   SMB username
    -p <pass>   SMB password (use -p "" for empty password)

  Examples:
    ./ctf-autoflag.sh smb 10.10.10.1 flag
    ./ctf-autoflag.sh smb 10.10.10.1 HTB -u guest -p ""
    ./ctf-autoflag.sh smb 10.10.10.1 flag -u admin -p admin

  Tips:
    - Null sessions (anonymous) are very common in CTFs
    - Look for shares named "backup", "secret", "files", "data"
    - System shares (IPC$, ADMIN$, C$) are usually not accessible
    - enum4linux gives bonus info but is not required
EOF
        ;;
    telnet)
        cat <<'EOF'

  ═══ Telnet (port 23) ═══

  What it does:
    1. Connects and captures the banner / welcome message
    2. Scans the banner for flags
    3. Reports connection status (open/closed)
    4. If -u/-p supplied: shows the manual telnet command with creds

  Telnet is fully interactive — the script captures what it can
  non-interactively and tells you how to connect manually.

  Required tools: nc or ncat (or falls back to /dev/tcp)

  Options used:
    -u <user>   Shown in manual connect instructions
    -p <pass>   Shown in manual connect instructions

  Examples:
    ./ctf-autoflag.sh telnet 10.10.10.1 flag
    ./ctf-autoflag.sh telnet 10.10.10.1 flag 1337
    ./ctf-autoflag.sh telnet 10.10.10.1 flag -u admin -p admin

  Tips:
    - Some CTF telnet services dump the flag in the banner immediately
    - Custom ports (1337, 9999, etc.) are common for telnet-style challenges
    - If the banner is empty, the service may need you to type something first
      — connect manually with: telnet <ip> <port>
EOF
        ;;
    dns)
        cat <<'EOF'

  ═══ DNS (port 53) ═══

  What it does:
    1. Zone transfer (AXFR) — dumps every record on the server
    2. Queries all standard record types: A, AAAA, MX, TXT, NS, CNAME, SOA, SRV
    3. Brute-forces 15 common CTF subdomains:
       flag, secret, hidden, admin, internal, dev, test, staging,
       key, ctf, private, backup, old, debug, shell
    4. For each found subdomain, also grabs its TXT records
    5. Reverse DNS lookup on the target IP (always runs)

  Required tools: dig
  Install: sudo apt install dnsutils

  IMPORTANT: Use -d <domain> to specify the domain name.
  Without -d, only the reverse lookup runs.

  Options used:
    -d <domain>   Domain to query (REQUIRED for most DNS checks)

  Examples:
    ./ctf-autoflag.sh dns 10.10.10.1 flag -d challenge.ctf
    ./ctf-autoflag.sh dns 10.10.10.1 flag 5353 -d example.com

  Tips:
    - Zone transfers are the #1 DNS CTF technique
    - TXT records are the most common place to hide flags
    - If AXFR fails, check the individual record types — especially TXT
    - The subdomain brute uses the target as the DNS resolver, so it
      only finds records that server knows about
EOF
        ;;
    smtp)
        cat <<'EOF'

  ═══ SMTP (port 25) ═══

  What it does:
    1. Connects and sends EHLO to get the banner + supported extensions
    2. VRFY user enumeration — tests 12 common usernames:
       root, admin, flag, ctf, user, test, guest, mail,
       postmaster, www-data, ubuntu, secret
    3. EXPN mailing list expansion on: root, admin, flag, all, postmaster
    4. All responses are scanned for flags

  SMTP is interactive — the script probes what it can and gives
  you the manual nc command for further exploration.

  Required tools: nc or ncat

  Options used: none (SMTP doesn't use -u/-p/-w/-d)

  Examples:
    ./ctf-autoflag.sh smtp 10.10.10.1 flag
    ./ctf-autoflag.sh smtp 10.10.10.1 flag 587

  Tips:
    - VRFY tells you which users exist on the system
    - Flags sometimes appear in the EHLO banner itself
    - If VRFY is disabled (most real servers), try RCPT TO enumeration
      manually: MAIL FROM:<a@b.com> then RCPT TO:<user@target>
    - For manual access: nc <ip> 25, then type EHLO test
EOF
        ;;
    mysql)
        cat <<'EOF'

  ═══ MySQL (port 3306) ═══

  What it does:
    1. Tries root login with no password (classic CTF misconfiguration)
    2. If -u/-p supplied: tries those credentials
    3. If logged in: lists all databases, skipping system ones
       (information_schema, performance_schema, mysql, sys)
    4. For each user database: shows tables, asks (y/n) to dump data
    5. Table dumps are limited to 100 rows each

  Required tools: mysql (client)
  Install: sudo apt install mysql-client

  Options used:
    -u <user>   MySQL username (default attempts: root)
    -p <pass>   MySQL password (use -p "" for empty password)

  Examples:
    ./ctf-autoflag.sh mysql 10.10.10.1 flag
    ./ctf-autoflag.sh mysql 10.10.10.1 flag -u root -p ""
    ./ctf-autoflag.sh mysql 10.10.10.1 flag -u admin -p secret
    ./ctf-autoflag.sh mysql 10.10.10.1 flag 3307 -u root -p toor

  Tips:
    - root with no password is attempted automatically — no need for -u/-p
    - Flags usually live in a database named "ctf", "flag", or "challenge"
    - Check table names too — sometimes the flag IS the table name
    - You will be prompted per-database before dumping (tables can be large)
EOF
        ;;
    redis)
        cat <<'EOF'

  ═══ Redis (port 6379) ═══

  What it does:
    1. Tests unauthenticated access with INFO command
    2. If auth required and -p supplied: retries with password
    3. Lists all keys (KEYS *) in the default database (DB 0)
    4. Asks (y/n) before dumping key values
    5. Handles all Redis data types correctly:
       string (GET), list (LRANGE), set (SMEMBERS),
       hash (HGETALL), zset (ZRANGE)
    6. Checks databases 1-15 for hidden keys (auto-dumps these)
    7. Falls back to nc if redis-cli is not installed

  Note: Redis auth uses only a password, no username.
  Use -p <pass>, not -u.

  Required tools: redis-cli (preferred) or nc/ncat (limited)
  Install: sudo apt install redis-tools

  Options used:
    -p <pass>   Redis AUTH password

  Examples:
    ./ctf-autoflag.sh redis 10.10.10.1 flag
    ./ctf-autoflag.sh redis 10.10.10.1 flag -p supersecret
    ./ctf-autoflag.sh redis 10.10.10.1 flag 6380

  Tips:
    - Many CTF Redis instances have no auth at all
    - CTF authors hide flags in databases 1-15 because most people
      only check DB 0 — this script checks all of them
    - Key names themselves can be flags (e.g. a key named "flag")
    - Without redis-cli, the nc fallback can only do basic checks
EOF
        ;;
    snmp)
        cat <<'EOF'

  ═══ SNMP (port 161) ═══

  What it does:
    1. Brute-forces community strings (SNMP v2c passwords):
       public, private, community, admin, manager, secret,
       default, snmp, monitor, test
    2. If a string works, walks four targeted OID subtrees:
       - System info: hostname, description, contact, location
       - Running processes: process names (flags hide here)
       - Network interfaces: IPs and interface names
       - Installed software: package list
    3. Asks (y/n) before doing a full snmpwalk of the entire tree
    4. Falls back to onesixtyone if snmpwalk is not installed

  Required tools: snmpwalk (preferred) or onesixtyone (limited)
  Install: sudo apt install snmp

  Options used: none (community strings are brute-forced automatically)

  Examples:
    ./ctf-autoflag.sh snmp 10.10.10.1 flag
    ./ctf-autoflag.sh snmp 10.10.10.1 flag 1161

  Tips:
    - "public" is the default community string on almost everything
    - Flags often hide in sysDescr, sysContact, or sysLocation fields
    - Running process names are another common flag hiding spot
    - The full walk can be thousands of lines but catches everything
    - onesixtyone only finds community strings — install snmp for full enum
EOF
        ;;
    *)
        fail "Unknown service: ${svc}"
        echo "Run --list to see supported services"
        ;;
    esac
    exit 0
}

list_services() {
    cat <<'EOF'

  Supported CTF Services:
  ──────────────────────────────────────────────────────────────
  #   Service   Default Port   What it does
  ──────────────────────────────────────────────────────────────
  1   http      80             Web: path enum, source scraping, dir busting
  2   ftp       21             Anonymous login, file download
  3   ssh       22             Banner grab, credential test
  4   smb       445            Share enum, file download, enum4linux
  5   telnet    23             Banner grab, connection check
  6   dns       53             Zone transfer, record queries, subdomain brute
  7   smtp      25             EHLO banner, VRFY/EXPN user enum
  8   mysql     3306           No-password root, DB enumeration, data dump
  9   redis     6379           Unauth access, key dump across all 16 DBs
  10  snmp      161            Community string brute, OID walks
  ──────────────────────────────────────────────────────────────

  For detailed help on a specific service:
    ./ctf-autoflag.sh --help-service <service>

  Example:
    ./ctf-autoflag.sh --help-service http

EOF
    exit 0
}

# ─── Service: HTTP ────────────────────────────────────────────────────────────

attack_http() {
    banner "HTTP Flag Hunt — ${TARGET}:${PORT}"
    require_cmd curl

    local base_url="http://${TARGET}:${PORT}"

    # --- Step 1: Homepage + headers ---
    # Flags sometimes hide in custom HTTP headers (X-Flag, etc.) or the page body
    info "Fetching homepage and headers..."
    treasure_section "HTTP Headers"
    local headers
    headers=$(curl -sS -I --max-time 10 "$base_url" 2>&1) || true
    treasure_write "$headers"
    hunt_flags "$headers" "HTTP headers" || true

    treasure_section "Homepage Body"
    local body
    body=$(curl -sS --max-time 10 "$base_url" 2>&1) || true
    treasure_write "$body"
    hunt_flags "$body" "homepage body" || true

    # --- Step 2: Common CTF paths ---
    # These are the classic low-hanging-fruit paths that CTF authors love to use
    info "Checking common CTF paths..."
    treasure_section "Path Enumeration"
    local paths=(
        "/robots.txt" "/flag.txt" "/flag" "/secret" "/hidden"
        "/.git/HEAD" "/.env" "/admin" "/backup" "/debug"
        "/console" "/shell" "/cmd" "/flag.html" "/index.php"
        "/sitemap.xml" "/.htaccess" "/.htpasswd" "/wp-login.php"
        "/api" "/api/flag" "/api/v1" "/graphql"
        "/source" "/src" "/dev" "/test" "/tmp"
        "/.svn/entries" "/.DS_Store" "/config" "/config.php"
        "/login" "/upload" "/uploads" "/files"
    )

    for path in "${paths[@]}"; do
        local code
        code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 5 "${base_url}${path}" 2>/dev/null) || continue
        if [[ "$code" != "404" && "$code" != "000" ]]; then
            local content
            content=$(curl -sS --max-time 5 "${base_url}${path}" 2>/dev/null) || continue
            success "Found: ${path} (HTTP ${code})"
            treasure_write "[${code}] ${path}"
            if [[ "$code" == "200" ]]; then
                treasure_write "$content"
                hunt_flags "$content" "path:${path}" || true
            fi
        fi
    done

    # --- Step 3: HTML comments ---
    # Classic CTF move: hide flags or hints in <!-- comments -->
    info "Checking HTML source comments..."
    treasure_section "HTML Comments"
    local comments
    comments=$(echo "$body" | grep -oP '<!--.*?-->' 2>/dev/null) || true
    if [[ -n "$comments" ]]; then
        success "Found HTML comments:"
        echo "$comments" | head -20
        treasure_write "$comments"
        hunt_flags "$comments" "HTML comments" || true
    fi

    # --- Step 4: Optional wordlist dir bust ---
    # Only runs if the user supplies -w <wordlist>
    if [[ -n "$WORDLIST" ]]; then
        if [[ ! -f "$WORDLIST" ]]; then
            warn "Wordlist not found: ${WORDLIST}"
        else
            info "Running wordlist dir bust with ${WORDLIST}..."
            treasure_section "Wordlist Dir Bust"

            if command -v gobuster &>/dev/null; then
                local gobuster_out
                gobuster_out=$(gobuster dir -u "$base_url" -w "$WORDLIST" -q -t 20 --timeout 5s 2>/dev/null) || true
                treasure_write "$gobuster_out"
                hunt_flags "$gobuster_out" "gobuster" || true
            elif command -v dirb &>/dev/null; then
                local dirb_out
                dirb_out=$(dirb "$base_url" "$WORDLIST" -S -r 2>/dev/null) || true
                treasure_write "$dirb_out"
                hunt_flags "$dirb_out" "dirb" || true
            else
                # No fancy tools — just curl each line from the wordlist
                info "No gobuster/dirb found, falling back to curl loop (slower)..."
                while IFS= read -r word; do
                    [[ -z "$word" || "$word" == \#* ]] && continue
                    local rc
                    rc=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 3 "${base_url}/${word}" 2>/dev/null) || continue
                    if [[ "$rc" == "200" || "$rc" == "301" || "$rc" == "302" ]]; then
                        success "Hit: /${word} (${rc})"
                        treasure_write "[${rc}] /${word}"
                        if [[ "$rc" == "200" ]]; then
                            local c
                            c=$(curl -sS --max-time 5 "${base_url}/${word}" 2>/dev/null) || continue
                            hunt_flags "$c" "dirbust:/${word}" || true
                        fi
                    fi
                done < "$WORDLIST"
            fi
        fi
    fi

    success "HTTP scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: FTP ─────────────────────────────────────────────────────────────

attack_ftp() {
    banner "FTP Flag Hunt — ${TARGET}:${PORT}"
    require_cmd curl

    local ftp_url="ftp://${TARGET}:${PORT}"

    # --- Step 1: Anonymous login ---
    # Most common CTF FTP vector — anonymous:anonymous@ is enabled by default on many boxes
    info "Testing anonymous FTP login..."
    treasure_section "FTP Anonymous Login"
    local anon_listing
    anon_listing=$(curl -sS --max-time 10 "${ftp_url}/" --user "anonymous:anonymous@" --list-only 2>&1) || true

    if echo "$anon_listing" | grep -qiE "refused|denied|530|Login incorrect|failed|Access denied"; then
        warn "Anonymous login DENIED"
        treasure_write "[DENIED] Anonymous FTP login refused"
        info "Anonymous access is not available on this server."
    elif [[ -z "$anon_listing" ]]; then
        warn "Anonymous login returned empty response (likely denied)"
        treasure_write "[INFO] Anonymous FTP login: empty response"
    else
        success "Anonymous login SUCCESSFUL!"
        treasure_write "[SUCCESS] Anonymous FTP login: ALLOWED"
        treasure_write ""
        treasure_write "Directory listing:"
        treasure_write "$anon_listing"
        hunt_flags "$anon_listing" "FTP directory listing" || true

        # --- Step 2: Ask user if they want to download ---
        local file_count
        file_count=$(echo "$anon_listing" | grep -cv '/$' 2>/dev/null) || file_count=0
        echo ""
        info "Found ${file_count} file(s). Download and scan for flags? (y/n)"
        read -r dl_choice
        if [[ "${dl_choice,,}" == "y" ]]; then
            local dl_dir="${OUTPUT_DIR}/downloads/ftp_${TARGET}"
            mkdir -p "$dl_dir"
            info "Saving files to ${dl_dir}/"
            treasure_section "FTP File Contents (anonymous)"
            while IFS= read -r fname; do
                [[ -z "$fname" || "$fname" == */ ]] && continue
                local dl_path="${dl_dir}/${fname}"
                curl -sS --max-time 10 "${ftp_url}/${fname}" --user "anonymous:anonymous@" -o "$dl_path" 2>/dev/null || continue
                if [[ -f "$dl_path" ]]; then
                    success "Downloaded: ${fname} -> ${dl_path}"
                    local fcontent
                    fcontent=$(cat "$dl_path" 2>/dev/null) || true
                    treasure_write "[FILE] ${fname}:"
                    treasure_write "$fcontent"
                    treasure_write ""
                    hunt_flags "$fcontent" "FTP file: ${fname}" || true
                fi
            done <<< "$anon_listing"
        else
            info "Skipping file downloads."
            treasure_write "[INFO] User skipped file downloads"
        fi
    fi

    # --- Step 3: Test supplied credentials ---
    # If user passed -u/-p, try those as well
    if [[ -n "$USERNAME" ]]; then
        info "Testing supplied credentials: ${USERNAME}..."
        treasure_section "FTP Authenticated Login"
        local auth_listing
        auth_listing=$(curl -sS --max-time 10 "${ftp_url}/" --user "${USERNAME}:${PASSWORD}" --list-only 2>&1) || true

        if echo "$auth_listing" | grep -qiE "refused|denied|530|Login incorrect|failed|Access denied"; then
            warn "Login as '${USERNAME}' DENIED"
            treasure_write "[DENIED] FTP login as '${USERNAME}': refused"
        elif [[ -z "$auth_listing" ]]; then
            warn "Login as '${USERNAME}' returned empty response"
            treasure_write "[INFO] FTP login as '${USERNAME}': empty response"
        else
            success "Login as '${USERNAME}' SUCCESSFUL!"
            treasure_write "[SUCCESS] FTP login as '${USERNAME}': ALLOWED"
            treasure_write "$auth_listing"
            hunt_flags "$auth_listing" "FTP auth listing" || true

            # Ask before downloading authenticated files too
            local auth_file_count
            auth_file_count=$(echo "$auth_listing" | grep -cv '/$' 2>/dev/null) || auth_file_count=0
            echo ""
            info "Found ${auth_file_count} file(s) as '${USERNAME}'. Download and scan for flags? (y/n)"
            read -r dl_auth_choice
            if [[ "${dl_auth_choice,,}" == "y" ]]; then
                local dl_dir="${OUTPUT_DIR}/downloads/ftp_${TARGET}"
                mkdir -p "$dl_dir"
                info "Saving files to ${dl_dir}/"
                treasure_section "FTP File Contents (${USERNAME})"
                while IFS= read -r fname; do
                    [[ -z "$fname" || "$fname" == */ ]] && continue
                    local dl_path="${dl_dir}/${fname}"
                    curl -sS --max-time 10 "${ftp_url}/${fname}" --user "${USERNAME}:${PASSWORD}" -o "$dl_path" 2>/dev/null || continue
                    if [[ -f "$dl_path" ]]; then
                        success "Downloaded: ${fname} -> ${dl_path}"
                        local fcontent
                        fcontent=$(cat "$dl_path" 2>/dev/null) || true
                        treasure_write "[FILE] ${fname}:"
                        treasure_write "$fcontent"
                        treasure_write ""
                        hunt_flags "$fcontent" "FTP auth file: ${fname}" || true
                    fi
                done <<< "$auth_listing"
            else
                info "Skipping file downloads."
                treasure_write "[INFO] User skipped authenticated file downloads"
            fi
        fi
    fi

    # --- Remind user about interactive access ---
    echo ""
    info "For interactive FTP access, connect manually:"
    info "  ftp ${TARGET} ${PORT}"

    success "FTP scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: SSH ─────────────────────────────────────────────────────────────

attack_ssh() {
    banner "SSH Recon — ${TARGET}:${PORT}"

    # --- Step 1: Banner grab ---
    # SSH servers send their version string on connect. CTF authors sometimes
    # customize the banner or pre-auth message to hide flags/hints.
    info "Grabbing SSH banner..."
    treasure_section "SSH Banner"
    local ssh_banner=""

    if command -v nc &>/dev/null; then
        ssh_banner=$(timeout 5 nc -w 3 "$TARGET" "$PORT" </dev/null 2>/dev/null) || true
    elif command -v ncat &>/dev/null; then
        ssh_banner=$(timeout 5 ncat -w 3 "$TARGET" "$PORT" </dev/null 2>/dev/null) || true
    else
        # Fallback: bash /dev/tcp
        ssh_banner=$(timeout 5 bash -c "cat </dev/tcp/${TARGET}/${PORT}" 2>/dev/null) || true
    fi

    if [[ -n "$ssh_banner" ]]; then
        success "SSH Banner: ${ssh_banner}"
        treasure_write "$ssh_banner"
        hunt_flags "$ssh_banner" "SSH banner" || true
    else
        info "No banner captured"
        treasure_write "[INFO] No SSH banner received"
    fi

    # --- Step 2: Test supplied credentials ---
    # sshpass lets us pass a password non-interactively. If it's not installed,
    # we just tell the user to try manually — no point failing hard.
    if [[ -n "$USERNAME" && -n "$PASSWORD" ]]; then
        info "Testing credentials: ${USERNAME}:${PASSWORD}..."
        treasure_section "SSH Auth Test"

        if command -v sshpass &>/dev/null; then
            # Common flag locations in CTFs
            local flag_cmd="cat /flag* /flag.txt /home/*/flag* /root/flag* /tmp/flag* /opt/flag* 2>/dev/null; echo '===DIR==='; ls -la / /home/ /root/ /tmp/ /opt/ 2>/dev/null"
            local ssh_out
            ssh_out=$(timeout 15 sshpass -p "$PASSWORD" ssh \
                -o StrictHostKeyChecking=no \
                -o ConnectTimeout=5 \
                -o BatchMode=no \
                -p "$PORT" \
                "${USERNAME}@${TARGET}" \
                "$flag_cmd" 2>/dev/null) || true

            if [[ -n "$ssh_out" ]]; then
                success "SSH login as '${USERNAME}' SUCCESSFUL!"
                treasure_write "[SUCCESS] SSH login as '${USERNAME}': worked"
                treasure_write ""
                treasure_write "$ssh_out"
                hunt_flags "$ssh_out" "SSH remote exec" || true
            else
                warn "SSH login as '${USERNAME}' failed or returned no output"
                treasure_write "[DENIED] SSH login as '${USERNAME}': failed or empty"
            fi
        else
            warn "sshpass is not installed — cannot test password auth non-interactively"
            treasure_write "[INFO] sshpass not available, cannot automate password login"
            info "Install with: sudo apt install sshpass"
            echo ""
            info "Try manually:"
            info "  ssh -p ${PORT} ${USERNAME}@${TARGET}"
        fi
    else
        info "No credentials supplied (-u / -p). Skipping auth test."
        treasure_write "[INFO] No credentials supplied for SSH"
    fi

    # --- Always show manual connect hint ---
    echo ""
    info "For interactive SSH access:"
    if [[ -n "$USERNAME" ]]; then
        info "  ssh -p ${PORT} ${USERNAME}@${TARGET}"
    else
        info "  ssh -p ${PORT} <user>@${TARGET}"
    fi

    success "SSH scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: SMB ─────────────────────────────────────────────────────────────

# Helper: given creds string and a label, enumerate shares and optionally download
_smb_enumerate() {
    local creds="$1"      # e.g. "-N" or "-U user%pass"
    local label="$2"      # e.g. "anonymous" or "user 'admin'"

    info "Listing SMB shares (${label})..."
    treasure_section "SMB Shares (${label})"
    local shares_raw
    shares_raw=$(smbclient -L "//${TARGET}" -p "$PORT" $creds 2>&1) || true
    treasure_write "$shares_raw"
    hunt_flags "$shares_raw" "SMB share list (${label})" || true

    # Parse out share names — look for lines with "Disk" type
    local share_names
    share_names=$(echo "$shares_raw" | awk '/Disk/ {print $1}') || true

    if [[ -z "$share_names" ]]; then
        warn "No accessible disk shares found (${label})"
        treasure_write "[INFO] No disk shares found for ${label}"
        return
    fi

    success "Found disk shares:"
    echo "$share_names"

    # Try to list files in each share
    treasure_section "SMB Share Contents (${label})"
    while IFS= read -r share; do
        [[ -z "$share" ]] && continue
        info "Browsing: //${TARGET}/${share} ..."
        local ls_out
        ls_out=$(smbclient "//${TARGET}/${share}" -p "$PORT" $creds -c "recurse ON; ls" 2>&1) || true

        if echo "$ls_out" | grep -qiE "ACCESS_DENIED|NT_STATUS_ACCESS_DENIED|LOGON_FAILURE"; then
            warn "Access denied: ${share}"
            treasure_write "[DENIED] ${share}: access denied"
            continue
        fi

        success "Readable share: ${share}"
        treasure_write "[SHARE] ${share}:"
        treasure_write "$ls_out"
        hunt_flags "$ls_out" "SMB listing: ${share}" || true

        # Count files (lines that have a size, skip directories marked with D)
        local file_lines
        file_lines=$(echo "$ls_out" | grep -vE '^\s*\.' | grep -cE '[0-9]+ [A-Z]' 2>/dev/null) || file_lines=0

        echo ""
        info "Share '${share}' has ~${file_lines} entries. Download files and scan for flags? (y/n)"
        read -r smb_dl_choice
        if [[ "${smb_dl_choice,,}" == "y" ]]; then
            local dl_dir="${OUTPUT_DIR}/downloads/smb_${TARGET}/${share}"
            mkdir -p "$dl_dir"
            info "Downloading to ${dl_dir}/ ..."
            treasure_section "SMB Downloaded Files (${share})"

            # Use smbclient prompt off + recurse + mget to pull everything
            smbclient "//${TARGET}/${share}" -p "$PORT" $creds \
                -c "prompt OFF; recurse ON; lcd ${dl_dir}; mget *" 2>/dev/null || true

            # Scan every downloaded file for flags
            local dl_count=0
            while IFS= read -r -d '' dlfile; do
                [[ -f "$dlfile" ]] || continue
                dl_count=$((dl_count + 1))
                local fname="${dlfile#${dl_dir}/}"
                local fcontent
                fcontent=$(cat "$dlfile" 2>/dev/null) || true
                if [[ -n "$fcontent" ]]; then
                    treasure_write "[FILE] ${share}/${fname}:"
                    treasure_write "$fcontent"
                    treasure_write ""
                    hunt_flags "$fcontent" "SMB file: ${share}/${fname}" || true
                fi
            done < <(find "$dl_dir" -type f -print0 2>/dev/null)
            success "Downloaded ${dl_count} file(s) from ${share}"
        else
            info "Skipping downloads for ${share}"
            treasure_write "[INFO] User skipped downloads for share: ${share}"
        fi
    done <<< "$share_names"
}

attack_smb() {
    banner "SMB Flag Hunt — ${TARGET}:${PORT}"

    if ! command -v smbclient &>/dev/null; then
        fail "smbclient is not installed (needed for SMB enumeration)"
        info "Install with: sudo apt install smbclient"
        exit 1
    fi

    # --- Step 1: Anonymous access ---
    _smb_enumerate "-N" "anonymous"

    # --- Step 2: Supplied credentials ---
    if [[ -n "$USERNAME" ]]; then
        echo ""
        _smb_enumerate "-U ${USERNAME}%${PASSWORD}" "user '${USERNAME}'"
    fi

    # --- Step 3: enum4linux bonus round ---
    if command -v enum4linux &>/dev/null; then
        echo ""
        info "Running enum4linux for extra recon..."
        treasure_section "enum4linux Output"
        local enum_out
        enum_out=$(timeout 60 enum4linux -a "$TARGET" 2>/dev/null) || true
        if [[ -n "$enum_out" ]]; then
            treasure_write "$enum_out"
            hunt_flags "$enum_out" "enum4linux" || true
        fi
    else
        info "enum4linux not installed — skipping (optional)"
    fi

    # --- Manual hint ---
    echo ""
    info "For interactive SMB access:"
    info "  smbclient -L //${TARGET} -p ${PORT} -N"
    info "  smbclient //${TARGET}/<share> -p ${PORT} -N"

    success "SMB scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: Telnet ──────────────────────────────────────────────────────────

attack_telnet() {
    banner "Telnet Recon — ${TARGET}:${PORT}"

    # --- Step 1: Banner grab ---
    # Telnet services often dump a banner, MOTD, or login prompt on connect.
    # Some CTF challenges put the flag right in the banner or require no auth.
    info "Grabbing telnet banner..."
    treasure_section "Telnet Banner"
    local banner_text=""

    # Send an empty line + short wait to trigger any welcome message
    if command -v nc &>/dev/null; then
        banner_text=$(timeout 8 bash -c '(echo ""; sleep 3) | nc -w 5 '"${TARGET} ${PORT}"' 2>/dev/null') || true
    elif command -v ncat &>/dev/null; then
        banner_text=$(timeout 8 bash -c '(echo ""; sleep 3) | ncat -w 5 '"${TARGET} ${PORT}"' 2>/dev/null') || true
    else
        # /dev/tcp fallback — can only read, can't easily send + read
        banner_text=$(timeout 5 bash -c 'cat </dev/tcp/'"${TARGET}/${PORT}"'' 2>/dev/null) || true
    fi

    if [[ -n "$banner_text" ]]; then
        success "Telnet banner captured:"
        echo "$banner_text"
        treasure_write "$banner_text"
        hunt_flags "$banner_text" "Telnet banner" || true
    else
        warn "No banner received (server may wait for input)"
        treasure_write "[INFO] No telnet banner received"
    fi

    # --- Step 2: Connection status report ---
    treasure_section "Connection Info"
    success "Telnet port ${PORT} is OPEN and accepting connections"
    treasure_write "[SUCCESS] Telnet connection: OPEN on port ${PORT}"

    # --- Step 3: Credential info ---
    # Telnet login is fully interactive (username prompt, then password prompt).
    # Automating this without expect is fragile, so we just report and suggest.
    if [[ -n "$USERNAME" && -n "$PASSWORD" ]]; then
        info "Credentials supplied: ${USERNAME} / ${PASSWORD}"
        treasure_write "[INFO] Supplied credentials: ${USERNAME} / ${PASSWORD}"
        echo ""
        info "Telnet auth is interactive — test manually:"
        info "  telnet ${TARGET} ${PORT}"
        info "  Username: ${USERNAME}"
        info "  Password: ${PASSWORD}"
    else
        info "No credentials supplied."
        echo ""
        info "Connect manually:"
        info "  telnet ${TARGET} ${PORT}"
    fi

    treasure_write "[INFO] Manual command: telnet ${TARGET} ${PORT}"
    success "Telnet scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: DNS ─────────────────────────────────────────────────────────────

attack_dns() {
    banner "DNS Flag Hunt — ${TARGET}:${PORT}"
    require_cmd dig

    # --- Step 1: Zone transfer ---
    # AXFR dumps every record the server knows. CTF DNS challenges almost always
    # have this enabled — it's the first thing to try. Requires a domain name.
    if [[ -n "$DOMAIN" ]]; then
        info "Attempting zone transfer (AXFR) for ${DOMAIN}..."
        treasure_section "Zone Transfer (AXFR)"
        local axfr_out
        axfr_out=$(dig @"${TARGET}" -p "$PORT" "$DOMAIN" AXFR 2>&1) || true

        if echo "$axfr_out" | grep -qiE "Transfer failed|connection timed out|REFUSED"; then
            warn "Zone transfer DENIED or timed out"
            treasure_write "[DENIED] AXFR for ${DOMAIN}: refused/failed"
        elif [[ -n "$axfr_out" ]]; then
            success "Zone transfer SUCCESSFUL!"
            echo "$axfr_out"
            treasure_write "$axfr_out"
            hunt_flags "$axfr_out" "DNS zone transfer" || true
        fi

        # --- Step 2: Standard record queries ---
        # TXT records are the #1 flag hiding spot. But we check everything —
        # flags can be in hostnames (CNAME), mail servers (MX), or SRV targets.
        info "Querying standard record types..."
        local record_types=("A" "AAAA" "MX" "TXT" "NS" "CNAME" "SOA" "SRV")
        for rtype in "${record_types[@]}"; do
            treasure_section "DNS ${rtype} Records"
            local dns_out
            dns_out=$(dig @"${TARGET}" -p "$PORT" "$DOMAIN" "$rtype" +noall +answer 2>&1) || true
            if [[ -n "$dns_out" ]]; then
                success "${rtype}: found records"
                echo "$dns_out"
                treasure_write "$dns_out"
                hunt_flags "$dns_out" "DNS ${rtype}" || true
            else
                treasure_write "[EMPTY] No ${rtype} records"
            fi
        done

        # --- Step 3: Common CTF subdomains ---
        # Short wordlist of names CTF authors love to use as subdomains.
        info "Checking common CTF subdomains..."
        treasure_section "Subdomain Enumeration"
        local subs=(
            "flag" "secret" "hidden" "admin" "internal"
            "dev" "test" "staging" "key" "ctf"
            "private" "backup" "old" "debug" "shell"
        )
        local found_subs=0
        for sub in "${subs[@]}"; do
            local sub_out
            sub_out=$(dig @"${TARGET}" -p "$PORT" "${sub}.${DOMAIN}" +short 2>&1) || true
            # dig +short returns empty on NXDOMAIN, so non-empty = found something
            if [[ -n "$sub_out" ]]; then
                success "Subdomain hit: ${sub}.${DOMAIN} -> ${sub_out}"
                treasure_write "${sub}.${DOMAIN} -> ${sub_out}"
                hunt_flags "$sub_out" "subdomain: ${sub}.${DOMAIN}" || true
                found_subs=$((found_subs + 1))

                # Also grab TXT for discovered subdomains — common flag spot
                local sub_txt
                sub_txt=$(dig @"${TARGET}" -p "$PORT" "${sub}.${DOMAIN}" TXT +short 2>/dev/null) || true
                if [[ -n "$sub_txt" ]]; then
                    success "  TXT for ${sub}.${DOMAIN}: ${sub_txt}"
                    treasure_write "  TXT: ${sub_txt}"
                    hunt_flags "$sub_txt" "subdomain TXT: ${sub}.${DOMAIN}" || true
                fi
            fi
        done
        if [[ "$found_subs" -eq 0 ]]; then
            info "No common subdomains resolved"
            treasure_write "[INFO] No common CTF subdomains found"
        fi

    else
        warn "No domain specified (-d). Skipping zone transfer and record queries."
        warn "DNS is much more useful with: -d <domain>"
        treasure_write "[INFO] No domain supplied — limited to reverse lookup only"
    fi

    # --- Step 4: Reverse DNS ---
    # Always worth trying — sometimes the PTR record itself contains a flag
    info "Attempting reverse DNS lookup on ${TARGET}..."
    treasure_section "Reverse DNS"
    local rev_out
    rev_out=$(dig @"${TARGET}" -p "$PORT" -x "$TARGET" +short 2>&1) || true
    if [[ -n "$rev_out" ]]; then
        success "Reverse DNS: ${TARGET} -> ${rev_out}"
        treasure_write "${TARGET} -> ${rev_out}"
        hunt_flags "$rev_out" "reverse DNS" || true
    else
        info "No PTR record for ${TARGET}"
        treasure_write "[INFO] No reverse DNS for ${TARGET}"
    fi

    # --- Manual hints ---
    echo ""
    info "Useful manual commands:"
    if [[ -n "$DOMAIN" ]]; then
        info "  dig @${TARGET} -p ${PORT} ${DOMAIN} AXFR"
        info "  dig @${TARGET} -p ${PORT} ${DOMAIN} ANY"
    fi
    info "  dig @${TARGET} -p ${PORT} -x ${TARGET}"

    success "DNS scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: SMTP ────────────────────────────────────────────────────────────

attack_smtp() {
    banner "SMTP Recon — ${TARGET}:${PORT}"

    # We need nc or ncat to talk SMTP line-by-line
    local nc_cmd=""
    if command -v nc &>/dev/null; then
        nc_cmd="nc"
    elif command -v ncat &>/dev/null; then
        nc_cmd="ncat"
    else
        fail "nc or ncat required for SMTP — neither found"
        exit 1
    fi

    # --- Step 1: Banner + EHLO ---
    # EHLO tells us the server name, supported extensions, and sometimes flags.
    # We capture everything the server sends back on connect + after EHLO.
    info "Grabbing SMTP banner and EHLO response..."
    treasure_section "SMTP Banner / EHLO"
    local smtp_banner
    smtp_banner=$(timeout 8 bash -c '(echo "EHLO ctfscanner"; sleep 2; echo "QUIT") | '"${nc_cmd}"' -w 5 '"${TARGET} ${PORT}"' 2>/dev/null') || true

    if [[ -n "$smtp_banner" ]]; then
        success "SMTP response:"
        echo "$smtp_banner"
        treasure_write "$smtp_banner"
        hunt_flags "$smtp_banner" "SMTP banner/EHLO" || true
    else
        warn "No SMTP response received"
        treasure_write "[INFO] No SMTP response"
    fi

    # --- Step 2: VRFY user enumeration ---
    # VRFY asks the server if a user exists. 2xx = yes, 5xx = no/disabled.
    # CTF boxes often leave this enabled. Finding users like "flag" or "admin"
    # tells us where to look next.
    info "Enumerating users via VRFY..."
    treasure_section "SMTP User Enumeration (VRFY)"
    local users=("root" "admin" "flag" "ctf" "user" "test" "guest" "mail" "postmaster" "www-data" "ubuntu" "secret")
    local found_users=0

    for u in "${users[@]}"; do
        local vrfy_out
        vrfy_out=$(timeout 5 bash -c '(echo "EHLO ctfscanner"; sleep 0.5; echo "VRFY '"${u}"'"; sleep 0.5; echo "QUIT") | '"${nc_cmd}"' -w 3 '"${TARGET} ${PORT}"' 2>/dev/null') || true

        # 252 = can't verify but will accept, 250 = confirmed exists
        if echo "$vrfy_out" | grep -qE "^(250|252).*"; then
            success "Valid user: ${u}"
            treasure_write "[USER] ${u}: exists"
            hunt_flags "$vrfy_out" "SMTP VRFY ${u}" || true
            found_users=$((found_users + 1))
        fi
    done

    if [[ "$found_users" -eq 0 ]]; then
        info "No users confirmed (VRFY may be disabled)"
        treasure_write "[INFO] VRFY returned no valid users (possibly disabled)"
    fi

    # --- Step 3: EXPN ---
    # EXPN expands mailing list members. Rarely enabled, but when it is,
    # it can reveal hidden users or flag text.
    info "Trying EXPN..."
    treasure_section "SMTP EXPN"
    local expn_targets=("root" "admin" "flag" "all" "postmaster")
    for et in "${expn_targets[@]}"; do
        local expn_out
        expn_out=$(timeout 5 bash -c '(echo "EHLO ctfscanner"; sleep 0.5; echo "EXPN '"${et}"'"; sleep 0.5; echo "QUIT") | '"${nc_cmd}"' -w 3 '"${TARGET} ${PORT}"' 2>/dev/null') || true

        if echo "$expn_out" | grep -qE "^(250|252)"; then
            success "EXPN ${et} returned data"
            treasure_write "[EXPN] ${et}:"
            treasure_write "$expn_out"
            hunt_flags "$expn_out" "SMTP EXPN ${et}" || true
        fi
    done

    # --- Manual hint ---
    echo ""
    info "For interactive SMTP access:"
    info "  ${nc_cmd} ${TARGET} ${PORT}"
    info "  Then: EHLO test / VRFY <user> / MAIL FROM / RCPT TO / etc."

    success "SMTP scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: MySQL ───────────────────────────────────────────────────────────

# Helper: given a mysql command prefix and label, enumerate DBs and optionally dump
_mysql_enumerate() {
    local mysql_cmd="$1"   # e.g. "mysql -h 10.0.0.1 -P 3306 -u root"
    local label="$2"       # e.g. "root (no password)" or "admin"

    info "Attempting login as ${label}..."
    treasure_section "MySQL Login (${label})"

    local db_list
    db_list=$(${mysql_cmd} -e "SHOW DATABASES;" 2>&1) || true

    if echo "$db_list" | grep -qiE "Access denied|ERROR|Can't connect"; then
        warn "Login as ${label} FAILED"
        treasure_write "[DENIED] MySQL login as ${label}: failed"
        treasure_write "$db_list"
        return 1
    fi

    if [[ -z "$db_list" ]]; then
        warn "Login as ${label} returned empty response"
        treasure_write "[INFO] MySQL login as ${label}: empty response"
        return 1
    fi

    success "MySQL login as ${label} SUCCESSFUL!"
    echo "$db_list"
    treasure_write "[SUCCESS] MySQL login as ${label}"
    treasure_write "$db_list"
    hunt_flags "$db_list" "MySQL database list" || true

    # Filter out system databases — we only care about user/CTF databases
    local user_dbs
    user_dbs=$(echo "$db_list" | tail -n +2 | grep -vE "^(information_schema|performance_schema|mysql|sys)$") || true

    if [[ -z "$user_dbs" ]]; then
        info "No user databases found (only system DBs)"
        treasure_write "[INFO] Only system databases present"
        return 0
    fi

    # Enumerate each user database
    while IFS= read -r db; do
        [[ -z "$db" ]] && continue
        info "Enumerating database: ${db}"
        treasure_section "MySQL DB: ${db}"

        local tables
        tables=$(${mysql_cmd} -e "SHOW TABLES FROM \`${db}\`;" 2>/dev/null) || true

        if [[ -z "$tables" ]]; then
            treasure_write "[EMPTY] No tables in ${db}"
            continue
        fi

        success "Tables in ${db}:"
        echo "$tables"
        treasure_write "$tables"
        hunt_flags "$tables" "MySQL tables in ${db}" || true

        local table_count
        table_count=$(echo "$tables" | tail -n +2 | wc -l)

        echo ""
        info "Database '${db}' has ${table_count} table(s). Dump contents? (y/n)"
        info "(Each table limited to 100 rows)"
        read -r mysql_dl_choice
        if [[ "${mysql_dl_choice,,}" == "y" ]]; then
            treasure_section "MySQL Data Dump: ${db}"
            local tbl_names
            tbl_names=$(echo "$tables" | tail -n +2) || true
            while IFS= read -r tbl; do
                [[ -z "$tbl" ]] && continue
                info "  Dumping ${db}.${tbl}..."
                local dump
                dump=$(${mysql_cmd} -e "SELECT * FROM \`${db}\`.\`${tbl}\` LIMIT 100;" 2>/dev/null) || true
                if [[ -n "$dump" ]]; then
                    treasure_write "[TABLE] ${db}.${tbl}:"
                    treasure_write "$dump"
                    treasure_write ""
                    hunt_flags "$dump" "MySQL ${db}.${tbl}" || true
                fi
            done <<< "$tbl_names"
        else
            info "Skipping dump for ${db}"
            treasure_write "[INFO] User skipped data dump for ${db}"
        fi
    done <<< "$user_dbs"

    return 0
}

attack_mysql() {
    banner "MySQL Flag Hunt — ${TARGET}:${PORT}"

    if ! command -v mysql &>/dev/null; then
        fail "mysql client is not installed"
        info "Install with: sudo apt install mysql-client"
        exit 1
    fi

    local got_in=false

    # --- Step 1: Try no-password root ---
    # The classic CTF misconfiguration — MySQL root with no password.
    local root_cmd="mysql -h ${TARGET} -P ${PORT} -u root --connect-timeout=5"
    if _mysql_enumerate "$root_cmd" "root (no password)"; then
        got_in=true
    fi

    # --- Step 2: Try supplied credentials ---
    if [[ -n "$USERNAME" ]]; then
        local auth_cmd="mysql -h ${TARGET} -P ${PORT} -u ${USERNAME} --connect-timeout=5"
        if [[ -n "$PASSWORD" ]]; then
            auth_cmd="${auth_cmd} -p${PASSWORD}"
        fi

        # Skip if we already got in as this same user with no password
        if [[ "$USERNAME" == "root" && "$got_in" == true ]]; then
            info "Already connected as root — skipping duplicate auth test"
        else
            echo ""
            if _mysql_enumerate "$auth_cmd" "${USERNAME}"; then
                got_in=true
            fi
        fi
    fi

    if [[ "$got_in" == false ]]; then
        fail "Could not authenticate to MySQL"
        info "Try different credentials with -u <user> -p <pass>"
    fi

    # --- Manual hint ---
    echo ""
    info "For interactive MySQL access:"
    info "  mysql -h ${TARGET} -P ${PORT} -u root"

    success "MySQL scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: Redis ───────────────────────────────────────────────────────────

attack_redis() {
    banner "Redis Flag Hunt — ${TARGET}:${PORT}"

    # redis-cli is ideal, but we can fall back to nc for basic checks
    local has_cli=false
    if command -v redis-cli &>/dev/null; then
        has_cli=true
    fi

    # Build auth arg — Redis uses -a <password>, no username
    local auth_arg=""
    if [[ -n "$PASSWORD" ]]; then
        auth_arg="-a ${PASSWORD}"
    fi

    # --- Step 1: Test access ---
    # Try INFO command — if it works, we're in. If we get NOAUTH, auth is required.
    info "Testing Redis access (unauthenticated)..."
    treasure_section "Redis Connection Test"

    if [[ "$has_cli" == true ]]; then
        local info_out
        info_out=$(timeout 5 redis-cli -h "$TARGET" -p "$PORT" INFO 2>&1) || true

        if echo "$info_out" | grep -qi "NOAUTH\|Authentication required"; then
            warn "Redis requires authentication"
            treasure_write "[INFO] Redis: authentication required"

            if [[ -n "$PASSWORD" ]]; then
                info "Retrying with supplied password..."
                info_out=$(timeout 5 redis-cli -h "$TARGET" -p "$PORT" $auth_arg INFO 2>&1) || true
            else
                fail "No password supplied (-p). Cannot authenticate."
                treasure_write "[DENIED] No password supplied for authenticated Redis"
                echo ""
                info "Try with: -p <password>"
                info "Manual: redis-cli -h ${TARGET} -p ${PORT}"
                success "Redis scan complete. Results in ${TREASURE_FILE}"
                return
            fi
        fi

        if ! echo "$info_out" | grep -qi "redis_version"; then
            fail "Cannot access Redis"
            treasure_write "[DENIED] Redis: not accessible"
            treasure_write "$info_out"
            echo ""
            info "Manual: redis-cli -h ${TARGET} -p ${PORT}"
            success "Redis scan complete. Results in ${TREASURE_FILE}"
            return
        fi

        # We're in
        success "Redis access GRANTED!"
        treasure_write "[SUCCESS] Redis: accessible"

        # Show server version for context
        local version
        version=$(echo "$info_out" | grep "redis_version:" | head -1) || true
        if [[ -n "$version" ]]; then
            info "Server: ${version}"
            treasure_write "$version"
        fi
        hunt_flags "$info_out" "Redis INFO" || true

        # --- Step 2: Enumerate keys in DB 0 ---
        info "Listing keys in default database (DB 0)..."
        treasure_section "Redis Keys (DB 0)"
        local keys
        keys=$(timeout 10 redis-cli -h "$TARGET" -p "$PORT" $auth_arg KEYS "*" 2>/dev/null) || true

        if [[ -z "$keys" ]]; then
            info "No keys in DB 0"
            treasure_write "[INFO] DB 0: empty"
        else
            local key_count
            key_count=$(echo "$keys" | wc -l)
            success "Found ${key_count} key(s) in DB 0:"
            echo "$keys"
            treasure_write "$keys"
            hunt_flags "$keys" "Redis key names (DB 0)" || true

            # --- Step 3: Ask before dumping values ---
            echo ""
            info "${key_count} key(s) found. Dump all values? (y/n)"
            read -r redis_dl_choice
            if [[ "${redis_dl_choice,,}" == "y" ]]; then
                treasure_section "Redis Key Values (DB 0)"
                while IFS= read -r key; do
                    [[ -z "$key" ]] && continue
                    local ktype
                    ktype=$(timeout 3 redis-cli -h "$TARGET" -p "$PORT" $auth_arg TYPE "$key" 2>/dev/null) || true

                    local val=""
                    case "$ktype" in
                        string)
                            val=$(timeout 3 redis-cli -h "$TARGET" -p "$PORT" $auth_arg GET "$key" 2>/dev/null) || true
                            ;;
                        list)
                            val=$(timeout 3 redis-cli -h "$TARGET" -p "$PORT" $auth_arg LRANGE "$key" 0 -1 2>/dev/null) || true
                            ;;
                        set)
                            val=$(timeout 3 redis-cli -h "$TARGET" -p "$PORT" $auth_arg SMEMBERS "$key" 2>/dev/null) || true
                            ;;
                        hash)
                            val=$(timeout 3 redis-cli -h "$TARGET" -p "$PORT" $auth_arg HGETALL "$key" 2>/dev/null) || true
                            ;;
                        zset)
                            val=$(timeout 3 redis-cli -h "$TARGET" -p "$PORT" $auth_arg ZRANGE "$key" 0 -1 WITHSCORES 2>/dev/null) || true
                            ;;
                        *)
                            val="[unknown type: ${ktype}]"
                            ;;
                    esac

                    if [[ -n "$val" ]]; then
                        success "  [${ktype}] ${key}"
                        treasure_write "[${ktype}] ${key} = ${val}"
                        hunt_flags "$val" "Redis key: ${key}" || true
                    fi
                done <<< "$keys"
            else
                info "Skipping value dump"
                treasure_write "[INFO] User skipped key value dump"
            fi
        fi

        # --- Step 4: Check other databases (1-15) ---
        # Most people only check DB 0. CTF authors know this.
        info "Checking databases 1-15 for keys..."
        treasure_section "Redis Other Databases"
        for dbnum in $(seq 1 15); do
            local dbsize
            dbsize=$(timeout 3 redis-cli -h "$TARGET" -p "$PORT" $auth_arg -n "$dbnum" DBSIZE 2>/dev/null) || true

            # DBSIZE returns something like "1" or "(integer) 3"
            local count
            count=$(echo "$dbsize" | grep -oE '[0-9]+') || true
            if [[ -n "$count" && "$count" -gt 0 ]]; then
                success "DB ${dbnum} has ${count} key(s)!"
                local dbkeys
                dbkeys=$(timeout 5 redis-cli -h "$TARGET" -p "$PORT" $auth_arg -n "$dbnum" KEYS "*" 2>/dev/null) || true
                treasure_write "[DB ${dbnum}] ${count} key(s): ${dbkeys}"
                hunt_flags "$dbkeys" "Redis DB ${dbnum} keys" || true

                # Dump values from non-default DBs automatically since they're
                # usually small and intentionally hidden
                while IFS= read -r key; do
                    [[ -z "$key" ]] && continue
                    local val
                    val=$(timeout 3 redis-cli -h "$TARGET" -p "$PORT" $auth_arg -n "$dbnum" GET "$key" 2>/dev/null) || true
                    if [[ -n "$val" ]]; then
                        treasure_write "[DB ${dbnum}] ${key} = ${val}"
                        hunt_flags "$val" "Redis DB ${dbnum} key: ${key}" || true
                    fi
                done <<< "$dbkeys"
            fi
        done

    else
        # --- Fallback: nc-based basic check ---
        warn "redis-cli not found — using netcat fallback (limited)"
        info "Install with: sudo apt install redis-tools"
        treasure_section "Redis (netcat fallback)"

        local nc_cmd=""
        if command -v nc &>/dev/null; then nc_cmd="nc"
        elif command -v ncat &>/dev/null; then nc_cmd="ncat"
        else
            fail "Neither redis-cli, nc, nor ncat found"
            exit 1
        fi

        local nc_out
        nc_out=$(timeout 5 bash -c '(echo "INFO"; sleep 2) | '"${nc_cmd}"' -w 3 '"${TARGET} ${PORT}"' 2>/dev/null') || true

        if echo "$nc_out" | grep -qi "NOAUTH"; then
            warn "Redis requires auth — cannot proceed without redis-cli"
            treasure_write "[DENIED] Redis requires auth, redis-cli needed"
        elif [[ -n "$nc_out" ]]; then
            success "Got response from Redis (limited view):"
            treasure_write "$nc_out"
            hunt_flags "$nc_out" "Redis via nc" || true

            # Try KEYS * via nc
            local nc_keys
            nc_keys=$(timeout 5 bash -c '(echo "KEYS *"; sleep 2) | '"${nc_cmd}"' -w 3 '"${TARGET} ${PORT}"' 2>/dev/null') || true
            if [[ -n "$nc_keys" ]]; then
                treasure_write "$nc_keys"
                hunt_flags "$nc_keys" "Redis keys via nc" || true
            fi
        else
            fail "No response from Redis"
            treasure_write "[ERROR] No response from Redis"
        fi
    fi

    # --- Manual hint ---
    echo ""
    info "For interactive Redis access:"
    info "  redis-cli -h ${TARGET} -p ${PORT}"

    success "Redis scan complete. Results in ${TREASURE_FILE}"
}

# ─── Service: SNMP ────────────────────────────────────────────────────────────

attack_snmp() {
    banner "SNMP Flag Hunt — ${TARGET}:${PORT}"

    # --- Step 1: Community string brute ---
    # SNMP v1/v2c uses "community strings" as passwords. "public" is the default
    # read-only string on almost everything. CTF boxes rarely change it.
    local communities=("public" "private" "community" "admin" "manager" "secret" "default" "snmp" "monitor" "test")
    local working_comm=""

    if command -v snmpwalk &>/dev/null; then
        info "Brute-forcing community strings with snmpwalk..."
        treasure_section "SNMP Community String Discovery"

        for comm in "${communities[@]}"; do
            # Quick check: grab sysDescr (single OID) to test if the string works
            local test_out
            test_out=$(timeout 5 snmpwalk -v2c -c "$comm" "${TARGET}:${PORT}" 1.3.6.1.2.1.1.1.0 2>&1) || true

            if [[ -n "$test_out" ]] && ! echo "$test_out" | grep -qiE "Timeout|No Response|No Such"; then
                success "Community string '${comm}' WORKS!"
                treasure_write "[SUCCESS] Community string: '${comm}'"
                treasure_write "  sysDescr: ${test_out}"
                hunt_flags "$test_out" "SNMP sysDescr (${comm})" || true
                working_comm="$comm"
                break
            fi
        done

        if [[ -z "$working_comm" ]]; then
            fail "No working community string found"
            treasure_write "[DENIED] None of the tested community strings worked"
            treasure_write "[INFO] Tried: ${communities[*]}"
            echo ""
            info "Try a custom string with: snmpwalk -v2c -c <string> ${TARGET}:${PORT}"
            success "SNMP scan complete. Results in ${TREASURE_FILE}"
            return
        fi

        # --- Step 2: Targeted OID walks ---
        # These specific OIDs contain the most useful info. We walk each one
        # separately so the output is organized and not one giant blob.
        info "Walking targeted OIDs with community '${working_comm}'..."

        # System info (sysDescr, sysName, sysContact, sysLocation)
        treasure_section "SNMP System Info"
        local sys_out
        sys_out=$(timeout 15 snmpwalk -v2c -c "$working_comm" "${TARGET}:${PORT}" 1.3.6.1.2.1.1 2>/dev/null) || true
        if [[ -n "$sys_out" ]]; then
            success "System info retrieved"
            echo "$sys_out"
            treasure_write "$sys_out"
            hunt_flags "$sys_out" "SNMP system info" || true
        fi

        # Running processes — flags sometimes hide in process names or arguments
        treasure_section "SNMP Running Processes"
        local proc_out
        proc_out=$(timeout 15 snmpwalk -v2c -c "$working_comm" "${TARGET}:${PORT}" 1.3.6.1.2.1.25.4.2.1.2 2>/dev/null) || true
        if [[ -n "$proc_out" ]]; then
            local proc_count
            proc_count=$(echo "$proc_out" | wc -l)
            success "Found ${proc_count} running process(es)"
            treasure_write "$proc_out"
            hunt_flags "$proc_out" "SNMP processes" || true
        fi

        # Network interfaces — shows IPs, interface names
        treasure_section "SNMP Network Interfaces"
        local net_out
        net_out=$(timeout 15 snmpwalk -v2c -c "$working_comm" "${TARGET}:${PORT}" 1.3.6.1.2.1.2.2.1.2 2>/dev/null) || true
        if [[ -n "$net_out" ]]; then
            success "Network interfaces:"
            echo "$net_out"
            treasure_write "$net_out"
            hunt_flags "$net_out" "SNMP interfaces" || true
        fi

        # Installed software — package names can contain hints
        treasure_section "SNMP Installed Software"
        local sw_out
        sw_out=$(timeout 15 snmpwalk -v2c -c "$working_comm" "${TARGET}:${PORT}" 1.3.6.1.2.1.25.6.3.1.2 2>/dev/null) || true
        if [[ -n "$sw_out" ]]; then
            local sw_count
            sw_count=$(echo "$sw_out" | wc -l)
            success "Found ${sw_count} installed package(s)"
            treasure_write "$sw_out"
            hunt_flags "$sw_out" "SNMP software" || true
        fi

        # --- Step 3: Full walk (optional) ---
        # A complete snmpwalk of the entire tree can be thousands of lines.
        # Useful for thoroughness but noisy — let the user decide.
        echo ""
        info "Targeted walks complete. Run a FULL snmpwalk of the entire tree? (y/n)"
        info "(This can be large but catches flags in unusual OIDs)"
        read -r snmp_full_choice
        if [[ "${snmp_full_choice,,}" == "y" ]]; then
            info "Running full snmpwalk (this may take a minute)..."
            treasure_section "SNMP Full Walk"
            local full_out
            full_out=$(timeout 120 snmpwalk -v2c -c "$working_comm" "${TARGET}:${PORT}" 1 2>/dev/null) || true
            if [[ -n "$full_out" ]]; then
                local oid_count
                oid_count=$(echo "$full_out" | wc -l)
                success "Full walk returned ${oid_count} OID(s)"
                treasure_write "$full_out"
                hunt_flags "$full_out" "SNMP full walk" || true
            fi
        else
            info "Skipping full walk"
            treasure_write "[INFO] User skipped full snmpwalk"
        fi

    elif command -v onesixtyone &>/dev/null; then
        # --- Fallback: onesixtyone ---
        # Can only discover community strings, not walk OIDs
        warn "snmpwalk not found — using onesixtyone (community string discovery only)"
        info "Install snmp for full enumeration: sudo apt install snmp"
        treasure_section "SNMP Community Strings (onesixtyone)"

        # Write community list to temp file
        local tmp_comm="/tmp/ctf_snmp_comm_$$"
        printf '%s\n' "${communities[@]}" > "$tmp_comm"

        local one_out
        one_out=$(onesixtyone "$TARGET" -c "$tmp_comm" 2>&1) || true
        rm -f "$tmp_comm"

        if [[ -n "$one_out" ]]; then
            success "onesixtyone results:"
            echo "$one_out"
            treasure_write "$one_out"
            hunt_flags "$one_out" "onesixtyone" || true
        else
            fail "No working community strings found"
            treasure_write "[DENIED] onesixtyone found nothing"
        fi

        info "Install snmp tools for full enumeration: sudo apt install snmp"
    else
        fail "Neither snmpwalk nor onesixtyone found"
        info "Install with: sudo apt install snmp"
        exit 1
    fi

    # --- Manual hint ---
    echo ""
    info "Useful manual commands:"
    if [[ -n "$working_comm" ]]; then
        info "  snmpwalk -v2c -c ${working_comm} ${TARGET}:${PORT}"
    fi
    info "  snmpwalk -v2c -c public ${TARGET}:${PORT}"
    info "  onesixtyone ${TARGET} public private community"

    success "SNMP scan complete. Results in ${TREASURE_FILE}"
}

# ─── Argument Parsing ─────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    usage
fi

case "$1" in
    --list|-l) list_services ;;
    --help|-h) usage ;;
    --help-service)
        if [[ -z "${2:-}" ]]; then
            fail "Usage: --help-service <service>"
            echo "Example: --help-service http"
            exit 1
        fi
        help_service "$2"
        ;;
esac

SERVICE="${1,,}"  # lowercase
shift

# Validate service name
valid=false
for s in "${SUPPORTED_SERVICES[@]}"; do
    [[ "$s" == "$SERVICE" ]] && valid=true && break
done
if [[ "$valid" == false ]]; then
    fail "Unknown service: ${SERVICE}"
    echo "Supported: ${SUPPORTED_SERVICES[*]}"
    exit 1
fi

# Target IP — required
if [[ $# -lt 1 ]]; then
    fail "Missing target IP address"
    usage
fi
TARGET="$1"
shift

# Flag prefix — required
if [[ $# -lt 1 ]]; then
    fail "Missing flag prefix (e.g. 'flag', 'picoCTF', 'csaw')"
    fail "This tells the script what format flags look like: <prefix>{...}"
    usage
fi
FLAG_PREFIX="$1"
FLAG_REGEX="${FLAG_PREFIX}\\{[^}]+\\}"
shift

# Optional positional port (if next arg is numeric)
if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
    PORT="$1"
    shift
fi

# Named options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u) USERNAME="${2:?'-u requires a username'}"; shift 2 ;;
        -p) PASSWORD="${2-}"; shift 2 ;;
        -w) WORDLIST="${2:?'-w requires a wordlist path'}"; shift 2 ;;
        -d) DOMAIN="${2:?'-d requires a domain'}"; shift 2 ;;
        -o) OUTPUT_DIR="${2:?'-o requires a directory'}"; shift 2 ;;
        *)  fail "Unknown option: $1"; usage ;;
    esac
done

# Default port if not specified
if [[ -z "$PORT" ]]; then
    PORT="${DEFAULT_PORTS[$SERVICE]}"
fi

# ─── Main ─────────────────────────────────────────────────────────────────────

banner "CTF Auto-Flag v1.0"
info "Target:  ${TARGET}:${PORT}"
info "Service: ${SERVICE^^}"
info "Flags:   ${FLAG_PREFIX}{...}"
echo ""

check_port
treasure_init

# Dispatch — only http for now, rest coming soon
case "$SERVICE" in
    http)   attack_http ;;
    ftp)    attack_ftp ;;
    ssh)    attack_ssh ;;
    smb)    attack_smb ;;
    telnet) attack_telnet ;;
    dns)    attack_dns ;;
    smtp)   attack_smtp ;;
    mysql)  attack_mysql ;;
    redis)  attack_redis ;;
    snmp)   attack_snmp ;;
esac

echo ""
banner "Hunt Complete!"
success "Treasure file: ${TREASURE_FILE}"

# Final flag summary
echo ""
if grep -q "\[FLAG\]" "$TREASURE_FILE" 2>/dev/null; then
    success "═══ FLAGS CAPTURED ═══"
    grep "\[FLAG\]" "$TREASURE_FILE"
else
    info "No flags auto-detected. Check treasure file for manual review."
fi

exit 0
