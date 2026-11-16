You run an nmap scan and get a basic return of ports 22, 80 and 3000 open.

> **Screenshot:** place the nmap output image at `assets/images/writeups/secret-nmap.png` (it was an inline screenshot in the original Notion page).

An `-sV` scan on port 3000 gives you the service running on the port, which is **Node.js**.

> **Screenshot:** `assets/images/writeups/secret-nodejs.png`

Navigating to the website or running a directory buster, you find a `files.zip` which contains the source code for the website. Download and unzip it (7z or anything you want) and you find a `local-web` directory. Running `ls -la` shows a `.git` directory. This is important: whenever you see a `.git` directory, you run git commands such as `git log`, `git show <commit>`, `git diff <commit>`, etc. Running `git log` shows some interesting stuff.

> **Screenshot:** `assets/images/writeups/secret-gitlog.png`

> The Notion page trails off here — treat this as a partial walkthrough to be continued.
