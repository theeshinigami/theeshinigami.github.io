# theeshinigami — HTB Knowledge Base

A static site for Hack The Box writeups and a searchable command/script reference.
No build step, no framework — plain HTML/CSS/JS that reads JSON + Markdown data
files. Designed to be unzipped and pushed straight to GitHub Pages.

> **Status:** this package contains all the *content* (migrated from Notion) plus
> a full build plan. The pages themselves (`index.html`, the CSS/JS, etc.) are
> built by following **[`BUILD_INSTRUCTIONS.md`](BUILD_INSTRUCTIONS.md)**.

## What's here

```
theeshinigami-htb/
├── BUILD_INSTRUCTIONS.md        # Front-to-end plan for building the site (read this)
├── README.md                    # You are here
├── data/
│   ├── writeups.json            # Index + metadata for all 20 writeups (source of truth)
│   ├── writeups/*.md            # 20 body-only Markdown writeups
│   └── commands.json            # 200 command/script reference entries with tags
├── assets/
│   ├── vendor/marked.min.js     # Markdown renderer (MIT) — only runtime dependency
│   └── images/writeups/         # Drop writeup screenshots here
└── _build/gen_commands.py       # One-off generator that produced commands.json
```

The site files (`index.html`, `writeups.html`, `writeup.html`, `commands.html`,
`about.html`, `assets/css/`, `assets/js/`) are added by the build step.

## Content summary

- **20 writeups** — Haze, Armageddon, Nibbles, TwoMillion, Backdoor, Tabby, Secret,
  Gem, EvilCUPS, Swagshop, Alert, Blunder, Academy, Wallet, Analytical, Crossfit,
  WingData, BlueEdge, Thing, Gallery. A few are short/stub (flagged `status` in
  `writeups.json`) and ready for you to expand.
- **200 commands** across Enumeration, Exploitation, Privilege Escalation, File
  Transfer, Persistence and Lateral Movement, tagged by category, OS and tool.

## Deploy to GitHub Pages

1. Create a new repository (e.g. `htb-notes`) and unzip this package into it.
2. Commit and push to `main`.
3. In the repo: **Settings → Pages → Build and deployment → Source: Deploy from a
   branch**, branch `main`, folder `/ (root)`. Save.
4. Your site goes live at `https://<username>.github.io/<repo>/` within a minute or two.

Because everything is relative-path and client-side, it works both at a repo
subpath (`/htb-notes/`) and at a user/org root (`<username>.github.io`).

## Adding content later (no build needed)

- **New writeup:** drop `data/writeups/<slug>.md` (body only) and add an entry to
  `data/writeups.json`.
- **New command:** add an object to the `commands` array in `data/commands.json`
  (or add a row to `_build/gen_commands.py` and re-run it).

## Identity

Site handle: **theeshinigami**. The About page is intentionally a stub to fill in later.
