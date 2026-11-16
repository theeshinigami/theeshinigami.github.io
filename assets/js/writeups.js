/* writeups.js — list page: fetch, filter, render */

(function () {
  'use strict';

  var allWriteups = [];
  var activeOS = null;
  var activeDifficulty = null;

  var OS_VALUES = ['Linux', 'Windows', 'Other'];
  var DIFFICULTIES = ['Easy', 'Medium', 'Hard', 'Insane', 'Unknown'];

  var searchInput, listEl, countEl, clearBtn, osBar, diffBar, noMatch;

  function init() {
    searchInput = document.getElementById('wu-search');
    listEl = document.getElementById('wu-list');
    countEl = document.getElementById('wu-count');
    clearBtn = document.getElementById('wu-clear');
    osBar = document.getElementById('wu-os-bar');
    diffBar = document.getElementById('wu-diff-bar');
    noMatch = document.getElementById('wu-no-match');

    renderFilterChips();
    bindEvents();
    loadData();
  }

  function loadData() {
    fetchJSON('data/writeups.json')
      .then(function (data) {
        allWriteups = (data.writeups || []).sort(function (a, b) {
          return b.date.localeCompare(a.date);
        });
        render();
      })
      .catch(function () {
        listEl.innerHTML = '<li class="error-state">Could not load writeups. Try refreshing.</li>';
      });
  }

  function renderFilterChips() {
    osBar.innerHTML = '<span class="filter-bar__label">OS</span>' +
      OS_VALUES.map(function (o) {
        return '<button type="button" class="filter-chip" data-os="' + o + '">' + o + '</button>';
      }).join('');

    diffBar.innerHTML = '<span class="filter-bar__label">Difficulty</span>' +
      DIFFICULTIES.map(function (d) {
        return '<button type="button" class="filter-chip" data-diff="' + d + '">' + (d === 'Unknown' ? '\u2014' : d) + '</button>';
      }).join('');
  }

  function bindEvents() {
    searchInput.addEventListener('input', function () { render(); });

    osBar.addEventListener('click', function (e) {
      var chip = e.target.closest('[data-os]');
      if (!chip) return;
      activeOS = activeOS === chip.dataset.os ? null : chip.dataset.os;
      updateChipStates();
      render();
    });

    diffBar.addEventListener('click', function (e) {
      var chip = e.target.closest('[data-diff]');
      if (!chip) return;
      activeDifficulty = activeDifficulty === chip.dataset.diff ? null : chip.dataset.diff;
      updateChipStates();
      render();
    });

    clearBtn.addEventListener('click', function () {
      searchInput.value = '';
      activeOS = null;
      activeDifficulty = null;
      updateChipStates();
      render();
      searchInput.focus();
    });
  }

  function updateChipStates() {
    osBar.querySelectorAll('[data-os]').forEach(function (el) {
      el.classList.toggle('filter-chip--active', el.dataset.os === activeOS);
    });
    diffBar.querySelectorAll('[data-diff]').forEach(function (el) {
      el.classList.toggle('filter-chip--active', el.dataset.diff === activeDifficulty);
    });
  }

  function render() {
    var query = searchInput.value.trim().toLowerCase();
    var terms = query ? query.split(/\s+/) : [];

    var filtered = allWriteups.filter(function (w) {
      if (activeOS && w.os !== activeOS) return false;
      if (activeDifficulty && w.difficulty !== activeDifficulty) return false;
      if (terms.length) {
        var haystack = (w.title + ' ' + w.tags.join(' ') + ' ' + w.summary).toLowerCase();
        if (!terms.every(function (t) { return haystack.indexOf(t) !== -1; })) return false;
      }
      return true;
    });

    countEl.textContent = filtered.length + ' of ' + allWriteups.length + ' writeups';
    clearBtn.style.display = (terms.length || activeOS || activeDifficulty) ? '' : 'none';
    noMatch.style.display = filtered.length === 0 ? '' : 'none';

    if (filtered.length === 0) {
      listEl.innerHTML = '';
      return;
    }

    listEl.innerHTML = filtered.map(function (w) {
      var diffClass = '';
      if (w.difficulty === 'Hard' || w.difficulty === 'Insane') diffClass = ' chip--difficulty-' + w.difficulty.toLowerCase();
      var diffLabel = w.difficulty === 'Unknown' ? '\u2014' : w.difficulty;

      var statusBadge = '';
      if (w.status === 'stub' || w.status === 'partial') {
        statusBadge = '<span class="chip chip--status-' + w.status + '">' + w.status + '</span>';
      }

      var tags = w.tags.slice(0, 6).map(function (t) {
        return '<span class="chip">' + escapeHTML(t) + '</span>';
      }).join('');

      var dateStr = w.date;

      return '<a class="writeup-item" href="writeup.html?slug=' + encodeURIComponent(w.slug) + '">' +
        '<div class="writeup-item__header">' +
          '<span class="writeup-item__title">' + escapeHTML(w.title) + '</span>' +
          '<span class="writeup-item__badges">' +
            '<span class="chip chip--os">' + escapeHTML(w.os) + '</span>' +
            '<span class="chip' + diffClass + '">' + diffLabel + '</span>' +
            statusBadge +
          '</span>' +
          '<span class="writeup-item__date">' + dateStr + '</span>' +
        '</div>' +
        '<div class="writeup-item__summary">' + escapeHTML(w.summary) + '</div>' +
        '<div class="writeup-item__tags">' + tags + '</div>' +
      '</a>';
    }).join('');
  }

  document.addEventListener('DOMContentLoaded', init);
})();
