# Build Instructions — theeshinigami HTB Knowledge Base

**Audience:** the coding agent (Opus) building this site. Follow this plan end to
end. All content already exists in `data/` and `assets/`. Your job is to build the
pages and the styling around that content. Do **not** rewrite the writeup prose or
the command data — only format and present it.

---

## 1. Goal

A fast, static, three-section personal site:

1. **Writeups** — read the migrated HTB box writeups. List view + single view.
2. **Commands** — a searchable, tag-filterable reference of 200 commands/scripts.
   Type a service (e.g. "smb", "kerberos"), a tool (e.g. "mimikatz"), or part of a
   command, and matches surface instantly.
3. **About** — intentionally a near-empty stub for the owner to fill in later.

Owner/handle: **theeshinigami**.

## 2. Hard constraints (do not violate)

- **No build step, no framework, no bundler.** Plain `.html`, `.css`, `.js`.
- **Fully client-side and static.** It must run by opening the files or via GitHub
  Pages. No server, no API calls to anything external.
- **Offline / zero CDN.** The only runtime dependency is the already-vendored
  `assets/vendor/marked.min.js` (global `marked`). Do not add CDN `<script>`/`<link>`
  tags. Style code blocks with CSS (no highlight.js).
- **Relative paths only** (`assets/...`, `data/...`), so the site works both at a
  repo subpath (`/htb-notes/`) and at a domain root. Never use leading-slash
  absolute paths.
- Must degrade gracefully: if a `fetch` fails, show a readable empty/error state,
  never a blank screen.

## 3. Data contracts (already on disk — read, don't change)

### `data/writeups.json`
```jsonc
{
  "writeups": [
    {
      "slug": "haze",              // unique; used as ?slug= and for the md filename
      "title": "Haze",
      "file": "haze.md",           // body-only Markdown under data/writeups/
      "os": "Windows",             // "Linux" | "Windows" | "Other"
      "difficulty": "Hard",        // "Easy|Medium|Hard|Insane|Unknown"
      "date": "2026-03-22",        // ISO; sort newest-first by default
      "status": "complete",        // "complete" | "partial" | "stub"
      "tags": ["active-directory", "splunk", "..."],
      "summary": "One-line description."
    }
  ]
}
```
There are 20 entries. The writeup `.md` files are **body only** (no front-matter):
fetch the file and render it with `marked.parse()`. All display metadata (title,
tags, os, difficulty, date, status, summary) comes from `writeups.json`, not the
Markdown.

### `data/commands.json`
```jsonc
{
  "count": 200,
  "commands": [
    {
      "id": "sudo-l",
      "name": "sudo -l",                       // may be a literal command OR a technique name
      "category": "Privilege Escalation",      // one of 6 categories (see below)
      "os": "Linux",                           // "Linux" | "Windows" | "Both"
      "tool": "sudo",                          // comma-separated tool string
      "useCase": "Check sudo privileges",
      "tags": ["Linux", "Privilege Escalation", "sudo"]  // category + os + tool tokens
    }
  ]
}
```
Categories: `Enumeration`, `Exploitation`, `Privilege Escalation`, `File Transfer`,
`Persistence`, `Lateral Movement`. (Distribution is roughly Exploitation 76,
Enumeration 41, Priv Esc 39, Lateral 26, File Transfer 9, Persistence 9.)

## 4. Design system — "Blueprint", light technical, **red** accent

The look is a polished technical-documentation / blueprint feel: ink on warm
off-white, a hairline structural grid, and a single disciplined **red** accent.
Red is not decoration — spend it on meaning: the active nav item, matched search
terms, CVE/exploit tags, difficulty = Insane/Hard, and primary actions. Everything
else stays quiet.

### Color tokens (CSS custom properties)
```css
:root{
  --bg:          #FAFAF7;   /* warm off-white page */
  --surface:     #FFFFFF;   /* cards, code blocks, panels */
  --ink:         #1A1A1A;   /* primary text */
  --ink-2:       #4A4A4A;   /* secondary text */
  --ink-3:       #7A7A7A;   /* muted/meta */
  --line:        #E3E1DA;   /* hairline rules / grid */
  --line-strong: #C9C6BC;   /* stronger dividers */
  --accent:      #C81E27;   /* signal red — primary accent */
  --accent-ink:  #8F1419;   /* darker red for hover/active/links-on-hover */
  --accent-tint: #FBE9E9;   /* pale red wash: active rows, highlighted tags, <mark> */
  --code-bg:     #F4F2EC;   /* code block background (slightly deeper than page) */
}
```
Do not introduce a second bright hue. OS/category can be encoded with weight,
small glyphs, or neutral chips — not a rainbow. A tiny neutral set for chips is
fine (e.g. Linux vs Windows shown with a subtle label, not saturated color).

### Typography
- **Mono** for anything that is code, a command, a tool name, a port, a path, a
  CVE id, and for the wordmark/section labels. Use a system mono stack:
  `ui-monospace, "SF Mono", "JetBrains Mono", "Cascadia Code", Menlo, Consolas, monospace`.
- **Body/headings:** a clean grotesk/sans system stack:
  `"Inter", system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif`.
  (If you want one webfont, you may self-host one into `assets/fonts/` — otherwise
  system stacks are fine and keep it build-free.)
- Two families max (mono + sans). Set a real type scale; keep body line length
  under ~74ch. Don't accent a single word in a heading with red just for effect —
  red is reserved for the meaning cases above.

### Layout & principles
- A visible but hairline **blueprint grid** or ruled structure is the signature:
  thin `--line` rules framing the content column, a persistent left-aligned column,
  generous margins. Left-aligned text throughout (no centered body copy).
- Numbered markers (01/02) only where content is a real sequence — writeups have an
  implicit order but are not steps, so don't number them.
- Motion: at most one restrained page-load settle; hover feedback on interactive
  elements only. Respect `prefers-reduced-motion`.
- Mobile: single column, the command search/filters collapse sensibly, tap targets
  ≥ 44px.

### Avoid (these read as generic/AI-made)
- The terracotta/clay accent `#D97757` family — we're using a true red, keep it red.
- Identical rounded cards with the same soft grey shadow on everything.
- Tracked-out ALL-CAPS eyebrow labels above every heading; meta joined with " · ";
  a "→" appended to every link; tinted-black instead of the real `--ink`.
- A hero that's just a big number + label.

### Hero / landing idea (make it specific to the subject)
Open on something characteristic of the owner's world — e.g. a blueprint-ruled
masthead with the `theeshinigami` wordmark in mono, a one-line mission, and two
live counts pulled from the JSON ("20 writeups · 200 commands") presented as part
of the ruled grid rather than a giant number. A subtle terminal-prompt motif
(`theeshinigami@htb:~$`) is on-brand if used once, with restraint — not on every
section.

## 5. Files to create

```
index.html            # landing / home
writeups.html         # writeups list + filters
writeup.html          # single writeup (reads ?slug=…)
commands.html         # command reference: search + tag/OS/category filters
about.html            # stub
assets/css/style.css  # one stylesheet, tokens + components
assets/js/common.js   # shared: header render, active-nav, fetch helper, theme bits
assets/js/writeups.js # list page logic
assets/js/writeup.js  # single page: fetch md, marked.parse, inject
assets/js/commands.js # search + filtering
404.html              # optional, same shell, "page not found" + link home
```
Keep CSS in one file and JS split per page (plus `common.js`). Share one header/
footer by rendering them from `common.js` (or copy the same markup into each page —
your call, but keep them identical).

## 6. Page specs

### Global shell (all pages)
- Header: `theeshinigami` wordmark (mono) linking home + nav: Home · Writeups ·
  Commands · About. The current section is marked with the **red** accent
  (underline or left-tick), not just bold. Include a real `:focus-visible` style.
- Footer: minimal — handle, a line like "HTB field notes", and a link to the GitHub
  repo (leave the URL as a clearly-marked placeholder for the owner to fill, e.g.
  `https://github.com/theeshinigami`).

### `index.html` — landing
- Masthead hero (section 4). Pull the live counts from `writeups.json` and
  `commands.json` so they never go stale.
- A compact "recent writeups" strip (newest 4–6 from `writeups.json`) linking into
  `writeup.html?slug=…`.
- A single clear entry into the Commands reference.

### `writeups.html` — list
- Fetch `writeups.json`, render newest-first.
- Each row/card shows: title, OS, difficulty, date, status (show a small marker for
  `partial`/`stub` so it's honest that some are short), tag chips, and the summary.
- **Filters:** by OS (Linux/Windows/Other), by difficulty, and a free-text filter
  over title + tags + summary. Keep filters as plain, accessible controls. Show a
  result count and a sensible empty state.
- `difficulty: "Insane"`/`"Hard"` may use the red accent on the difficulty label;
  `"Unknown"` renders as a muted "—".
- Clicking a row → `writeup.html?slug=<slug>`.

### `writeup.html` — single
- Read `slug` from the query string. Look it up in `writeups.json` for the metadata
  header (title, os, difficulty, date, status, tags). If `status` is `partial`/`stub`,
  show a small, non-alarming note ("Short notes — to be expanded").
- Fetch `data/writeups/<file>`, run `marked.parse()`, inject into the content column.
  - Configure marked for GFM. Render fenced code blocks as `<pre><code>` and style
    them (mono, `--code-bg`, hairline border, horizontal scroll on overflow, never
    wrap code). Inline code gets a subtle tint.
  - Make links inside writeups open in a new tab (`target="_blank" rel="noopener"`)
    since they point to external references — do this by post-processing the rendered
    DOM, not by trusting the Markdown.
  - Images in Markdown use paths like `assets/images/writeups/<name>.png`; just let
    them resolve relative to the site root. Missing images shouldn't break layout.
- Add a "← All writeups" link and prev/next within the date-sorted list if easy.
- **Security:** the Markdown is the owner's own trusted content, but still render
  into a dedicated container and do not `eval` anything. Do not enable `marked`'s
  deprecated raw-HTML passthrough beyond what's needed; sanitize defensively if
  trivial.

### `commands.html` — the reference (most important interaction)
- Fetch `commands.json` once.
- **Search box** (autofocus): case-insensitive, matches as the user types across
  `name`, `tool`, `useCase`, `category`, and `tags`. Multi-word queries should AND
  the terms. Debounce lightly. Matched substrings in `name`/`tool`/`useCase` are
  wrapped in `<mark>` using `--accent-tint`.
- **Tag/filter chips:** render a filter bar with the 6 categories and the 3 OS
  values as toggle chips. Active chip uses the red accent. Chips AND with the text
  search. Also allow clicking a tag on any result to add it as an active filter.
- Each result shows: `name` (mono, prominent — this is often the literal command),
  a one-line `useCase`, and small chips for category / OS / tool tokens. Include a
  **copy** button that copies `name` to the clipboard with a brief "copied" state.
- Show a live result count ("37 of 200"). Provide a clear "no matches" state and a
  "clear filters" affordance.
- Performance: 200 rows is tiny — plain DOM rendering/filtering is fine, no virtual
  list needed. Keep it instant.
- Deep-linking is a nice-to-have: reflect the query/filters in the URL hash so a
  search can be shared. Optional.

### `about.html` — stub
- Same shell. A short placeholder: handle `theeshinigami`, a sentence the owner can
  replace, and placeholder slots for links (GitHub, HTB profile). Keep it tasteful
  and obviously ready to edit. Do not invent biographical facts.

## 7. Accessibility & quality floor (non-negotiable, but quiet)

- Responsive to ~360px. Visible keyboard focus everywhere. Semantic landmarks
  (`header`/`nav`/`main`/`footer`), one `<h1>` per page.
- Color contrast ≥ WCAG AA for text; don't rely on red alone to convey state (pair
  with text/weight/icon).
- `prefers-reduced-motion` respected. Forms/controls are real, labelled elements.
- Copy voice: plain, active, sentence case. Empty states say what to do next.

## 8. Process (follow the frontend-design method)

1. Draft the token system + one hero concept as an ASCII wireframe; sanity-check it
   against section 4's "avoid" list and revise anything generic.
2. Build the shared shell + `style.css` tokens first.
3. Build `commands.html` (highest-value interaction) and get search/filter solid.
4. Build the writeups list + single-render.
5. Build `index.html` hero + `about.html` stub + `404.html`.
6. Self-review: open each page, check mobile, keyboard, reduced-motion, and that red
   is only carrying meaning. Remove one decorative thing at the end.

## 9. Acceptance checklist

- [ ] Opening `index.html` locally (file://) and via a static server both work.
- [ ] Counts on the landing page are read from the JSON (not hardcoded).
- [ ] All 20 writeups list and open; Markdown renders with styled code blocks;
      external links open in a new tab; stub/partial writeups are flagged.
- [ ] Commands: typing "kerberos", "smb", "mimikatz", "lfi", or "sudo -l" filters
      instantly; category + OS chips combine with search; copy button works; count
      updates; no-match state shows.
- [ ] No absolute paths; no external network requests; only `marked.min.js` is loaded.
- [ ] Keyboard-navigable; visible focus; AA contrast; reduced-motion respected.
- [ ] Deploys cleanly on GitHub Pages from `/` at a repo subpath.

## 10. Notes left for you

- Some writeups are intentionally short (`status: stub|partial` in `writeups.json`):
  TwoMillion (empty), Gallery, Thing, BlueEdge, Secret, Crossfit. Present them
  honestly; don't pad them.
- Screenshots for Secret and Gem are referenced in the Markdown but not included
  (Notion image URLs expire). The paths point to `assets/images/writeups/`; it's
  fine if they 404 until the owner adds the PNGs — don't let that break layout.
- OS / difficulty / tags on writeups were inferred during migration; they're editable
  in `writeups.json` and the owner may correct them.
