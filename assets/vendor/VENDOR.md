# Vendored libraries

- **marked.min.js** — Marked v12.0.2 (UMD build). Markdown → HTML renderer.
  Source: https://github.com/markedjs/marked · License: MIT (see marked.LICENSE).
  Exposes a global `marked` (`marked.parse(mdString)`).

No other runtime dependencies. Code blocks are styled with CSS rather than a
syntax-highlighting library, to keep the site fully offline and build-free.
If you later want token highlighting, add highlight.js via CDN or a vendored
browser build and call `hljs.highlightAll()` after rendering.
