The box started off simple, but had a lot of little things that threw me off. It started with a simple nmap scan showing port 80 and 8080 running. On port 80 you'd find a website called **megahosting**, and after clicking around you could find a **Local File Inclusion** vulnerability through the `news.php?file=` parameter. You can access things like `/etc/passwd`, but it has nothing of use.

If you read the docs on the 8080 website, you'll find the password for the manager role is usually in the `tomcat-users.xml` file. I spent a long time looking for where it was — lots of red herrings like `CATALINA_BASE` and `CATALINA_HOME` and other environment variables. I eventually searched up the list of packages on tomcat9: [Debian — file list of package tomcat9/bullseye/all](https://packages.debian.org/bullseye/all/tomcat9/filelist). This gave me the path to `tomcat-users.xml` at `/usr/share/tomcat9/etc/tomcat-users.xml`. Back to Occam's Razor — the simplest solution is likely the right one.

Finding `tomcat-users.xml` gives you the password `$3cureP4s5w0rd123!` and username `tomcat`, which gets you to the manager webpage. Through the deploy command at `/manager/text/deploy`, you can upload a webshell to get a reverse shell. I used the one at [Exploiting Apache Tomcat Manager](https://medium.com/@cyb0rgs/exploiting-apache-tomcat-manager-script-role-974e4307cd00), but ippsec's [webshell repo](https://github.com/tennc/webshell) has a lot more to choose from. After you curl the path you made, you gain a foothold.

You do some enumeration and find a `backup.zip` file in `/var/www/html` belonging to **ash**. If you scp or base64-encode the file and decode it, you'll have a password-protected zip. Using `zip2john`, you find the hash. Sending that to john gives you the password `admin@it`, which is ash's password. You can `cat user.txt`.

You can also make an SSH key by making a `.ssh` directory in ash's home and passing `id_rsa.pub > authorized_keys`, letting you SSH as ash with the generated private key.

Now, if you check the groups ash is part of, she's in the **lxd** group, which allows a root-privileged container. I used HackTricks ([lxd privilege escalation](https://book.hacktricks.wiki/en/linux-hardening/privilege-escalation/interesting-groups-linux-pe/lxd-privilege-escalation.html)); method 2 worked better for me:

```bash
# build a simple alpine image
git clone https://github.com/saghul/lxd-alpine-builder
cd lxd-alpine-builder
sed -i 's,yaml_path="latest-stable/releases/$apk_arch/latest-releases.yaml",yaml_path="v3.8/releases/$apk_arch/latest-releases.yaml",' build-alpine
sudo ./build-alpine -a i686

# import the image (do this from YOUR HOME directory on the victim, or it may fail)
lxc image import ./alpine*.tar.gz --alias myimage

# start and configure the lxd storage pool as default
lxd init

# run the image
lxc init myimage mycontainer -c security.privileged=true

# mount / into the image
lxc config device add mycontainer mydevice disk source=/ path=/mnt/root recursive=true
```

```bash
lxc start mycontainer
lxc exec mycontainer /bin/sh
# cd /mnt/root  -> the host filesystem is mounted here
```

Going to where the root filesystem is mounted gives you access to the root home directory and the root flag.
