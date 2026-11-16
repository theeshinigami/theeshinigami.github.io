It starts very casual, but ramps up to commands and places I didn't even know.

To start off, you do basic stuff like nmap to find port 22 and 80 are open. You don't do anything with port 22, so you'll focus on port 80 for the entirety of this lab. You should add the IP address to your `/etc/hosts` so you can navigate to it (I did not do that). The command to do that is simply:

```bash
sudo vim /etc/hosts
```

and then you add your IP address and domain name.

Now that you know port 80 is open, your first instinct should be to do some directory fuzzing. Doing this using **dirsearch** (which is way faster than gobuster or dirbuster) gives me `admin.php`, `login.php` and `register.php`. Looking at `register.php` with Burp Suite or inspect tools, you see that there is something called `roleid` which is set to 0 — that's probably how the website tracks if you're an admin or a user. You can use Burp Suite to intercept your traffic and send it over with the `roleid` set to 1. Using that account you can log onto the `admin.php` page.

You see there is a subdomain that is not fully developed, so you need to add that to your `/etc/hosts` again to navigate to it. There, you find that the PHP framework being used is Laravel, which has a CVE vulnerability. Using Metasploit, you are able to get into the system. I learned a handy command to spawn a `/bin/bash` shell:

```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```

After looking around the system, you find a password `mySup3rP4s5w0rd!!` which — if you SSH from another machine using the user **cry0l1t3** — gets you onto the machine with that user. You can now run a `wget` to get `linpeas.sh` from a server running on your local machine. After you run LinPEAS, you can find mrb3n's password, which is a sudo user. If you run `sudo -l`, you can see which commands he can run, which is `/usr/share/composer`. There's a website — [gtfobins.github.io/gtfobins/composer](https://gtfobins.github.io/gtfobins/composer/) — which has privesc on this very command. After you run the commands on the website and run `whoami`, you see that you are finally root. A shell spawn and a little digging later, you finally find the root flag.
