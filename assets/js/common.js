/* common.js — shared shell: header, footer, nav, fetch helper */

(function () {
  'use strict';

  /* --- Render header --- */
  function renderHeader(currentPage) {
    const header = document.getElementById('site-header');
    if (!header) return;

    const navItems = [
      { label: 'Home', href: 'index.html', page: 'home' },
      { label: 'Writeups', href: 'writeups.html', page: 'writeups' },
      { label: 'Commands', href: 'commands.html', page: 'commands' },
      { label: 'About', href: 'about.html', page: 'about' },
    ];

    const navLinks = navItems.map(function (item) {
      var aria = item.page === currentPage ? ' aria-current="page"' : '';
      return '<a href="' + item.href + '"' + aria + '>' + item.label + '</a>';
    }).join('');

    header.innerHTML =
      '<div class="container site-header__inner">' +
        '<a href="index.html" class="wordmark">theeshinigami</a>' +
        '<button class="nav-toggle" aria-label="Toggle navigation" aria-expanded="false">&#9776;</button>' +
        '<nav class="site-nav" aria-label="Main navigation">' + navLinks + '</nav>' +
      '</div>';

    // Mobile toggle
    var toggle = header.querySelector('.nav-toggle');
    var nav = header.querySelector('.site-nav');
    if (toggle && nav) {
      toggle.addEventListener('click', function () {
        var open = nav.classList.toggle('site-nav--open');
        toggle.setAttribute('aria-expanded', String(open));
      });
    }
  }

  /* --- Render footer --- */
  function renderFooter() {
    var footer = document.getElementById('site-footer');
    if (!footer) return;
    footer.innerHTML =
      '<div class="container site-footer__inner">' +
        '<span>theeshinigami &mdash; HTB field notes</span>' +
        '<a href="https://github.com/theeshinigami" target="_blank" rel="noopener">github</a>' +
      '</div>';
  }

  /* --- Fetch JSON helper with error handling --- */
  window.fetchJSON = function (url) {
    return fetch(url).then(function (r) {
      if (!r.ok) throw new Error('Fetch failed: ' + r.status);
      return r.json();
    });
  };

  /* --- Escape HTML --- */
  window.escapeHTML = function (str) {
    var el = document.createElement('span');
    el.textContent = str;
    return el.innerHTML;
  };

  /* --- Highlight matching text with <mark> --- */
  window.highlightText = function (text, terms) {
    if (!terms || !terms.length) return escapeHTML(text);
    var escaped = escapeHTML(text);
    terms.forEach(function (term) {
      if (!term) return;
      var re = new RegExp('(' + term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')', 'gi');
      escaped = escaped.replace(re, '<mark>$1</mark>');
    });
    return escaped;
  };

  /* --- Init shell on DOMContentLoaded --- */
  document.addEventListener('DOMContentLoaded', function () {
    var page = document.documentElement.getAttribute('data-page') || '';
    renderHeader(page);
    renderFooter();
  });
})();
