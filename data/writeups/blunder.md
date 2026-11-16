So you start with your basic nmap scan per usual, and find SSH and HTTP open per usual. You navigate to the website to find a simple webpage, so you should just run some directory enumeration on it. You'll find some interesting things such as login pages and a `todo.txt` file. Going to this path, you find the version of CMS and that it has not been updated yet, meaning there's likely a vulnerability with the CMS version currently being used.

Since the version is 3.9.2, you can look up what vulnerabilities it has on Google (nothing came up on Metasploit). You can find a lot of scripts bypassing brute force protocols. I couldn't find the one I personally used, but there's another approach that might work better.

> **Linked script:** a `bruteforce.py` was referenced here in the original notes.

If you use **cewl**, it also makes a password list from everything on the website and builds a wordlist for you.

After you use the right script, you'll find the password is `RolandDesChain`. You'll use that to log in and be taken to a dashboard page, where you'll use another CVE. If you use Metasploit, just search `bludit` and use the file upload vulnerability. Once you get a shell, you need to find hugo's credentials.

If you look for the config file and then databases for Bludit 3.9.2, you'll find there isn't much there since admin and fergus are both salted. But if you look at the other version of Bludit, you'll find hugo isn't salted, so he's your way in. If you use CrackStation, you'll find hugo's password is `Password120`. Since SSH isn't open, you'll have to switch users on the shell you got. Switch to hugo and then set up a reverse shell on your own box from the Metasploit box.

Make it look pretty and you'll find that after you run `sudo -l`, you can run `/bin/bash` as everyone besides root. You might think you just have to run `sudo /bin/bash`, but since you can't run it as root, you need to find another way in. There's a third CVE that exploits this to get root:

- [Bludit 3.9.2 Auth Bruteforce Bypass — CVE-2019-17240](https://github.com/0xDTC/Bludit-3.9.2-Auth-Bruteforce-Bypass-CVE-2019-17240/blob/master/CVE-2019-17240)

**What I learned from this box:** always do writeups. I redid this box yet couldn't crack it easily because I already forgot it. It also showed me how important it is not to go down red herrings and to learn when to pivot. When rockyou doesn't work, maybe use cewl. If the script doesn't work, find another one. If your hashes aren't getting cracked, find easier ones. If you can't get an easy `/bin/bash` privesc, find a different avenue. It's always important to learn how to pivot.
