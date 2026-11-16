/* writeup.js — single writeup: fetch metadata + markdown, render */

(function () {
  'use strict';

  var headerEl, bodyEl, navEl, statusEl;

  function init() {
    headerEl = document.getElementById('writeup-header');
    bodyEl = document.getElementById('writeup-body');
    navEl = document.getElementById('writeup-nav');

    var params = new URLSearchParams(window.location.search);
    var slug = params.get('slug');

    if (!slug) {
      bodyEl.innerHTML = '<div class="error-state">No writeup specified. <a href="writeups.html">Browse all writeups</a>.</div>';
      return;
    }

    fetchJSON('data/writeups.json')
      .then(function (data) {
        var writeups = (data.writeups || []).sort(function (a, b) {
          return b.date.localeCompare(a.date);
        });
        var idx = -1;
        for (var i = 0; i < writeups.length; i++) {
          if (writeups[i].slug === slug) { idx = i; break; }
        }
        if (idx === -1) {
          bodyEl.innerHTML = '<div class="error-state">Writeup not found. <a href="writeups.html">Browse all writeups</a>.</div>';
          return;
        }

        var w = writeups[idx];
        document.title = w.title + ' — theeshinigami';
        renderHeader(w);
        renderNav(writeups, idx);
        return loadMarkdown(w.file);
      })
      .catch(function () {
        bodyEl.innerHTML = '<div class="error-state">Could not load writeup data. Try refreshing.</div>';
      });
  }

  function renderHeader(w) {
    var diffClass = '';
    if (w.difficulty === 'Hard' || w.difficulty === 'Insane') diffClass = ' chip--difficulty-' + w.difficulty.toLowerCase();
    var diffLabel = w.difficulty === 'Unknown' ? '\u2014' : w.difficulty;

    var tags = w.tags.map(function (t) {
      return '<span class="chip">' + escapeHTML(t) + '</span>';
    }).join('');

    var statusNote = '';
    if (w.status === 'stub') {
      statusNote = '<div class="writeup-status-note">Stub \u2014 notes to be added.</div>';
    } else if (w.status === 'partial') {
      statusNote = '<div class="writeup-status-note">Short notes \u2014 to be expanded.</div>';
    }

    headerEl.innerHTML =
      '<h1 class="writeup-header__title">' + escapeHTML(w.title) + '</h1>' +
      '<div class="writeup-header__meta">' +
        '<span class="chip chip--os">' + escapeHTML(w.os) + '</span>' +
        '<span class="chip' + diffClass + '">' + diffLabel + '</span>' +
        '<span style="font-family:var(--font-mono);font-size:0.8rem;color:var(--ink-3);">' + w.date + '</span>' +
      '</div>' +
      '<div class="writeup-header__tags">' + tags + '</div>' +
      statusNote;
  }

  function renderNav(writeups, idx) {
    var prev = idx < writeups.length - 1 ? writeups[idx + 1] : null;
    var next = idx > 0 ? writeups[idx - 1] : null;

    var html = '<a href="writeups.html">&larr; All writeups</a>';
    var pnHTML = '';
    if (prev) {
      pnHTML += '<a href="writeup.html?slug=' + encodeURIComponent(prev.slug) + '">&larr; ' + escapeHTML(prev.title) + '</a>';
    }
    if (next) {
      if (pnHTML) pnHTML += ' ';
      pnHTML += '<a href="writeup.html?slug=' + encodeURIComponent(next.slug) + '">' + escapeHTML(next.title) + ' &rarr;</a>';
    }
    if (pnHTML) html += '<span>' + pnHTML + '</span>';

    navEl.innerHTML = html;
  }

  function loadMarkdown(file) {
    return fetch('data/writeups/' + file)
      .then(function (r) {
        if (!r.ok) throw new Error('Fetch failed');
        return r.text();
      })
      .then(function (md) {
        if (typeof marked !== 'undefined') {
          marked.setOptions({ gfm: true, breaks: false });
          bodyEl.innerHTML = marked.parse(md);
        } else {
          // Fallback: show raw markdown in a pre
          bodyEl.innerHTML = '<pre>' + escapeHTML(md) + '</pre>';
        }

        // Post-process: external links open in new tab
        bodyEl.querySelectorAll('a').forEach(function (a) {
          var href = a.getAttribute('href') || '';
          if (href.indexOf('http') === 0) {
            a.setAttribute('target', '_blank');
            a.setAttribute('rel', 'noopener');
          }
        });

        // Post-process: missing images graceful handling
        bodyEl.querySelectorAll('img').forEach(function (img) {
          img.addEventListener('error', function () {
            img.style.display = 'none';
          });
        });
      })
      .catch(function () {
        bodyEl.innerHTML = '<div class="error-state">Could not load writeup content. The file may not exist yet.</div>';
      });
  }

  document.addEventListener('DOMContentLoaded', init);
})();
