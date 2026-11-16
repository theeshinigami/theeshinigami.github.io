/* commands.js — search, filter, render */

(function () {
  'use strict';

  var allCommands = [];
  var totalCount = 0;
  var activeCategory = null;
  var activeOS = null;
  var searchTerms = [];
  var debounceTimer = null;

  var CATEGORIES = ['Enumeration', 'Exploitation', 'Privilege Escalation', 'File Transfer', 'Persistence', 'Lateral Movement', 'Hardening/Defense'];
  var OS_VALUES = ['Linux', 'Windows', 'Both'];

  var searchInput, listEl, countEl, clearBtn, catBar, osBar, noMatch;

  function init() {
    searchInput = document.getElementById('cmd-search');
    listEl = document.getElementById('cmd-list');
    countEl = document.getElementById('cmd-count');
    clearBtn = document.getElementById('cmd-clear');
    catBar = document.getElementById('cmd-cat-bar');
    osBar = document.getElementById('cmd-os-bar');
    noMatch = document.getElementById('cmd-no-match');

    renderFilterChips();
    bindEvents();
    readHash();
    updateChipStates();
    loadData();
  }

  function loadData() {
    fetchJSON('data/commands.json')
      .then(function (data) {
        allCommands = data.commands || [];
        totalCount = allCommands.length;
        render();
        searchInput.focus();
      })
      .catch(function () {
        listEl.innerHTML = '<li class="error-state">Could not load commands. Try refreshing.</li>';
      });
  }

  function renderFilterChips() {
    catBar.innerHTML = '<span class="filter-bar__label">Category</span>' +
      CATEGORIES.map(function (c) {
        return '<button type="button" class="filter-chip" data-cat="' + c + '">' + c + '</button>';
      }).join('');

    osBar.innerHTML = '<span class="filter-bar__label">OS</span>' +
      OS_VALUES.map(function (o) {
        return '<button type="button" class="filter-chip" data-os="' + o + '">' + o + '</button>';
      }).join('');
  }

  function bindEvents() {
    searchInput.addEventListener('input', function () {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(render, 80);
    });

    catBar.addEventListener('click', function (e) {
      var chip = e.target.closest('[data-cat]');
      if (!chip) return;
      activeCategory = activeCategory === chip.dataset.cat ? null : chip.dataset.cat;
      updateChipStates();
      render();
    });

    osBar.addEventListener('click', function (e) {
      var chip = e.target.closest('[data-os]');
      if (!chip) return;
      activeOS = activeOS === chip.dataset.os ? null : chip.dataset.os;
      updateChipStates();
      render();
    });

    clearBtn.addEventListener('click', function () {
      searchInput.value = '';
      activeCategory = null;
      activeOS = null;
      updateChipStates();
      render();
      searchInput.focus();
    });

    // Delegate tag clicks on results
    listEl.addEventListener('click', function (e) {
      var tagChip = e.target.closest('[data-filter-tag]');
      if (tagChip) {
        var val = tagChip.dataset.filterTag;
        // Try to match to category or OS
        if (CATEGORIES.indexOf(val) !== -1) {
          activeCategory = activeCategory === val ? null : val;
        } else if (OS_VALUES.indexOf(val) !== -1) {
          activeOS = activeOS === val ? null : val;
        } else {
          // Add to search
          searchInput.value = val;
        }
        updateChipStates();
        render();
        return;
      }

      // Copy button
      var copyBtn = e.target.closest('.copy-btn');
      if (copyBtn) {
        var text = copyBtn.dataset.copy;
        navigator.clipboard.writeText(text).then(function () {
          copyBtn.textContent = 'copied';
          copyBtn.classList.add('copy-btn--copied');
          setTimeout(function () {
            copyBtn.textContent = 'copy';
            copyBtn.classList.remove('copy-btn--copied');
          }, 1200);
        });
      }
    });
  }

  function updateChipStates() {
    catBar.querySelectorAll('[data-cat]').forEach(function (el) {
      el.classList.toggle('filter-chip--active', el.dataset.cat === activeCategory);
    });
    osBar.querySelectorAll('[data-os]').forEach(function (el) {
      el.classList.toggle('filter-chip--active', el.dataset.os === activeOS);
    });
  }

  function getSearchTerms() {
    var raw = searchInput.value.trim().toLowerCase();
    if (!raw) return [];
    return raw.split(/\s+/).filter(Boolean);
  }

  function matchesSearch(cmd, terms) {
    if (!terms.length) return true;
    var haystack = (cmd.name + ' ' + cmd.tool + ' ' + cmd.useCase + ' ' + cmd.category + ' ' + cmd.tags.join(' ')).toLowerCase();
    return terms.every(function (t) { return haystack.indexOf(t) !== -1; });
  }

  function render() {
    searchTerms = getSearchTerms();
    var filtered = allCommands.filter(function (cmd) {
      if (activeCategory && cmd.category !== activeCategory) return false;
      if (activeOS && cmd.os !== activeOS) return false;
      return matchesSearch(cmd, searchTerms);
    });

    countEl.textContent = filtered.length + ' of ' + totalCount;
    clearBtn.style.display = (searchTerms.length || activeCategory || activeOS) ? '' : 'none';
    noMatch.style.display = filtered.length === 0 ? '' : 'none';

    if (filtered.length === 0) {
      listEl.innerHTML = '';
      return;
    }

    var html = filtered.map(function (cmd) {
      var nameHTML = highlightText(cmd.name, searchTerms);
      var useCaseHTML = highlightText(cmd.useCase, searchTerms);
      var toolTokens = cmd.tool ? cmd.tool.split(/,\s*/) : [];
      var toolChips = toolTokens.map(function (t) {
        return '<span class="chip" data-filter-tag="' + escapeHTML(t.trim()) + '">' + highlightText(t.trim(), searchTerms) + '</span>';
      }).join('');

      return '<li class="cmd-item">' +
        '<div>' +
          '<div class="cmd-name">' + nameHTML + '</div>' +
          '<div class="cmd-usecase">' + useCaseHTML + '</div>' +
          '<div class="cmd-meta">' +
            '<span class="chip" data-filter-tag="' + escapeHTML(cmd.category) + '">' + escapeHTML(cmd.category) + '</span>' +
            '<span class="chip chip--os" data-filter-tag="' + escapeHTML(cmd.os) + '">' + escapeHTML(cmd.os) + '</span>' +
            toolChips +
          '</div>' +
        '</div>' +
        '<div class="cmd-actions">' +
          '<button type="button" class="copy-btn" data-copy="' + escapeHTML(cmd.name) + '">copy</button>' +
        '</div>' +
      '</li>';
    }).join('');

    listEl.innerHTML = html;

    // Update URL hash for deep-linking
    updateHash();
  }

  function updateHash() {
    var parts = [];
    if (searchInput.value.trim()) parts.push('q=' + encodeURIComponent(searchInput.value.trim()));
    if (activeCategory) parts.push('cat=' + encodeURIComponent(activeCategory));
    if (activeOS) parts.push('os=' + encodeURIComponent(activeOS));
    var hash = parts.length ? '#' + parts.join('&') : '';
    if (window.location.hash !== hash) {
      history.replaceState(null, '', hash || window.location.pathname);
    }
  }

  function readHash() {
    var hash = window.location.hash.slice(1);
    if (!hash) return;
    hash.split('&').forEach(function (pair) {
      var kv = pair.split('=');
      var key = kv[0];
      var val = decodeURIComponent(kv[1] || '');
      if (key === 'q') searchInput.value = val;
      if (key === 'cat' && CATEGORIES.indexOf(val) !== -1) activeCategory = val;
      if (key === 'os' && OS_VALUES.indexOf(val) !== -1) activeOS = val;
    });
    updateChipStates();
  }

  document.addEventListener('DOMContentLoaded', init);
})();
