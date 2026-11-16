Annoying box, but it gave me two new scripts and vulnerabilities to look out for on Ruby on Rails, so all's well that ends well. You start off with a normal box: nmap the IP and find port 3000 open. Go to the page and you're greeted by a bare-bones website.

> **Screenshot:** `assets/images/writeups/gem-home.png`

You can try signing up for an account, but you'll quickly realize it's pretty pointless. The real vulnerability is `CVE-2019-5418`, a directory path traversal vulnerability. It affects certain versions of Ruby on Rails; all you need is to find somewhere the webpage calls a file. Using feroxbuster, we see it has a `readme` subdirectory — perfect. Send that page to Burp Suite and manually exploit this, since finding PoCs for an exploit this easy is useless. Just put your path in the Accept header:

> **Screenshot:** `assets/images/writeups/gem-burp.png`

Yes, the `{{` at the end is important — look up the CVE if you care why. Now we just `ssh -i` with the private key, and we're in as **ruby**.

The next step is local privesc: becoming **pearl**, then **root**. If you look in the `payroll/db` directory, you have some sqlite3 databases. The box doesn't have sqlite3 installed, so I did the lazy way: base64-encoded all three files (you only really need `development`) and decoded them on my own box to read them. `development` has the credentials for all users. You don't care for ruby (you're already ruby), and root has much higher protection than pearl, so we crack pearl's password, which is `diamond1`. We `su pearl`.

The most annoying part was finding the program pearl has access to. Unlike more forgiving boxes, this program doesn't have anything special like an SUID bit or special permissions, so it took longer than expected. How I found it: looking up deserialized YAML stuff, I found they usually have `YAML.load` in them. So I grepped the whole system for that and found `/usr/bin/updatedep` (or similar). This loads in your `dependencies.yml` in your files directory, which you can upload a script to for root access. I pulled this script from another similar box's writeup.

You can finally run `/bin/bash -p` to get root. For some reason I had to run `/bin/bash` first, then `/bin/bash -p` to get root.
