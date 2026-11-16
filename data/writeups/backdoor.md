This box was extremely difficult and humbled me in terms of how I do boxes. The problem I have right now is that I don't yet know how to properly find exploits or privesc boxes. I simply follow patterns from other boxes, but when those patterns break down, I fail. This leads me to want to do two things:

- Watch this video on Linux Privilege Escalation: [Linux Privilege Escalation – Full Course (8+ Hours)](https://www.youtube.com/watch?v=5Un3ffzokJQ)
- And watch a basic penetration testing course: [Practical Ethical Hacking](https://www.youtube.com/watch?v=3FNYvj2U0HM)

These both give the basic tools needed to actually pwn boxes by myself. Now for the writeup.

First, you start with a basic nmap scan to see ports 22 and 80 open. This is where I made my first mistake: after the basic scan, I should always run a secondary longer scan on all ports to make sure I enumerate all services. This would have shown another service running on 1337. I got too comfortable with other boxes not having open ports outside the common ones, which is a critical error.

You navigate to the website and see it's a WordPress site (also shown by the `-sV` scan). I tried to exploit the Apache server, but that led nowhere, so I focused on WordPress. Here's where I should have applied Occam's Razor and gone for the simplest solution. I saw the website had an **ebook-download** plugin from running gobuster. I should have just looked up a vulnerability on that plugin, but instead I tried to look up vulnerabilities on the WordPress version and found nothing.

The vulnerability was **directory traversal** on the ebook-download plugin, which gave me the ability to read files, so I threw it into Burp and started looking. I knew they wanted me to exploit the gdbserver process running on the server, and the gdbserver was running on port 1337. In the `/proc` directory there are a bunch of PIDs, and it shows which PID goes with which service. A way to find it:

```bash
for i in $(seq 1 1000); do curl backdoor.htb/wp-content/ebook-download/filedownload.php?ebookdownloadurl=/proc/$i/cmdline; done
```

After doing this, you'll find it is gdb running on port 1337. You can use Metasploit to exploit this; just make sure you set the `rport` to 1337, not 80. This gets you a shell.

First thing on the box is trying `sudo -l`, but that doesn't work. However, if you look at the processes using `ps -ef --forest`, you'll see root is running a **screen** session. You can simply attach:

```bash
screen -r root
```

to connect to the screen and finish the box. You can also throw a reverse shell back to your machine from the Metasploit box to stabilize it.
