/* ============================================================
   olta — app.js
   Vanilla ES2020, no modules, no dependencies.
   Sections: helpers / mock backend / API layer / theme / toasts /
             info card / jobs list / downloads / saved playlists /
             settings / polling / init
   Mock mode (?mock=1) swaps the data source only; prod logic
   is identical and works from file:// or the C backend.
   ============================================================ */
"use strict";

/* ---------------- Helpers ---------------- */

var $ = function (id) { return document.getElementById(id); };

var MOCK = /[?&]mock=1/.test(location.search);

function fmtDuration(sec) {
  if (sec == null || isNaN(sec)) return "";
  sec = Math.round(sec);
  var h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60;
  var pad = function (n) { return String(n).padStart(2, "0"); };
  return h ? h + ":" + pad(m) + ":" + pad(s) : m + ":" + pad(s);
}

function fmtEta(sec) {
  return sec == null ? "" : fmtDuration(sec);
}

function fmtDate(ts) {
  if (ts == null) return "";
  try {
    return new Date(ts * 1000).toLocaleDateString("tr-TR", { day: "numeric", month: "short", year: "numeric" });
  } catch (e) { return ""; }
}

function fmtPercent(p) {
  return Number(p).toLocaleString("tr-TR", { maximumFractionDigits: 1 }) + "%";
}

function jobTime(ts) {
  try {
    return new Date(ts * 1000).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" });
  } catch (e) { return ""; }
}

var STATE_CHIP = {
  queued: "Sırada", running: "İndiriliyor", done: "Tamamlandı",
  error: "Hata", canceled: "İptal"
};

/* Inline SVG placeholder used when a thumbnail cannot load (e.g. offline). */
var PLACEHOLDER_THUMB = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 360'%3E%3Crect width='640' height='360' fill='%23141c27'/%3E%3Cpath d='M295 130l90 50-90 50z' fill='%23222e3d'/%3E%3C/svg%3E";

/* ---------------- Mock backend ----------------
   Canned data + a 500 ms tick that advances running jobs,
   mirroring the real contract responses. */

var mockJobs = [];
var mockSeq = 3; /* m-1 and m-2 are used by the initial sample jobs */
var mockTimer = null;

function mockInitJobs() {
  var now = Math.floor(Date.now() / 1000);
  mockJobs = [
    {
      id: "m-err", url: "https://example.com/vip-clip", title: "Yalnızca Üyelere Özel Klip",
      kind: "video", state: "error", progress: 0, speed: null, eta: null,
      filepath: null, error: "Video kullanılamıyor: yalnızca üyelere açık",
      created_at: now - 540
    },
    {
      id: "m-2", url: "https://example.com/podcast-42", title: "Podcast #42 — Gece Sohbeti",
      kind: "audio", state: "queued", progress: 0, speed: null, eta: null,
      filepath: null, error: null, created_at: now - 120
    },
    {
      id: "m-1", url: "https://example.com/mountains", title: "Dağların Ardında — Belgesel",
      kind: "video", state: "running", progress: 12.4, speed: "2.31MiB/s", eta: 214,
      filepath: null, error: null, created_at: now - 90
    }
  ];
}

function mockTick() {
  var running = 0, i, j;
  for (i = 0; i < mockJobs.length; i++) if (mockJobs[i].state === "running") running++;
  for (i = 0; i < mockJobs.length; i++) {
    j = mockJobs[i];
    if (j.state === "queued" && running < 2) { j.state = "running"; running++; }
    if (j.state !== "running") continue;
    j.progress = Math.min(100, j.progress + 1.5 + Math.random() * 3.5);
    j.speed = (1 + Math.random() * 4).toFixed(2) + "MiB/s";
    j.eta = Math.max(0, Math.round((100 - j.progress) * 2));
    if (j.playlist && j.pl_total > 1 && j.pl_index < j.pl_total &&
        j.progress >= (j.pl_index / j.pl_total) * 100) {
      j.pl_index = Math.min(j.pl_total, j.pl_index + 1);
    }
    if (j.progress >= 100) {
      j.state = "done"; j.progress = 100; j.speed = null; j.eta = null;
      j.filepath = "/home/dat/Downloads/olta/" + j.title.replace(/[^\w\sçğıöşüÇĞİÖŞÜ-]/g, "") +
        (j.kind === "audio" ? ".mp3" : ".mkv");
    }
  }
}

var mockPlaylists = [];

function mockInitPlaylists() {
  var now = Math.floor(Date.now() / 1000);
  var day = 86400;
  mockPlaylists = [
    {
      url: "https://example.com/list/anadolu-turkuleri",
      title: "Anadolu Türküleri — Derleme",
      added_at: now - 9 * day, last_downloaded_at: now - 2 * day
    },
    {
      url: "https://example.com/list/konser-arsivi",
      title: "Konser Arşivi",
      added_at: now - 21 * day, last_downloaded_at: now - 4 * day
    },
    {
      url: "https://example.com/list/belgesel-notlari",
      title: "Belgesel Notları",
      added_at: now - 40 * day, last_downloaded_at: null
    }
  ];
}

var MOCK_HEALTH = { ok: true, ffmpeg: true, yt_dlp: "2026.09.14" };

var MOCK_INFO = {
  title: "Dağların Ardında — Belgesel",
  uploader: "Anadolu Belgesel",
  channel: "Kanal Örneği",
  duration: 754,
  is_playlist: false,
  /* Data URI so the mock works fully offline from file://. */
  thumbnail: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 360'%3E%3Cdefs%3E%3ClinearGradient id='g' x1='0' y1='0' x2='1' y2='1'%3E%3Cstop offset='0' stop-color='%230f2e3d'/%3E%3Cstop offset='1' stop-color='%23164650'/%3E%3C/linearGradient%3E%3C/defs%3E%3Crect width='640' height='360' fill='url(%23g)'/%3E%3Cpath d='M262 118l150 62-150 62z' fill='%2322d3ee' opacity='.85'/%3E%3C/svg%3E",
  formats: [
    { id: "620", ext: "mp4", height: 2160, fps: 30, vcodec: "vp9.2", acodec: "opus", filesize: 2140000000 },
    { id: "137", ext: "mp4", height: 1080, fps: 30, vcodec: "avc1.64002a", acodec: "mp4a.40.2", filesize: 734003200 },
    { id: "136", ext: "mp4", height: 720, fps: 30, vcodec: "avc1.64001f", acodec: "mp4a.40.2", filesize: 367001600 },
    { id: "135", ext: "mp4", height: 480, fps: 30, vcodec: "avc1.64001e", acodec: "mp4a.40.2", filesize: 184000000 }
  ],
  subtitles: { "tr": ["srt", "vtt"], "en": ["srt", "vtt"] }
};

/* Playlist variant so ?mock=1 can exercise the whole save flow: URLs
 * containing "list=" resolve to this canned playlist info. */
var MOCK_INFO_PL = {
  title: "Anadolu Türküleri — Derleme",
  uploader: "Anadolu Arşiv",
  channel: "Kanal Örneği",
  is_playlist: true,
  /* Data URI so the mock works fully offline from file://. */
  thumbnail: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 360'%3E%3Cdefs%3E%3ClinearGradient id='g' x1='0' y1='0' x2='1' y2='1'%3E%3Cstop offset='0' stop-color='%230f3a4d'/%3E%3Cstop offset='1' stop-color='%23155e56'/%3E%3C/linearGradient%3E%3C/defs%3E%3Crect width='640' height='360' fill='url(%23g)'/%3E%3Cpath d='M236 126h120M236 162h160M236 198h96' stroke='%2322d3ee' stroke-width='14' stroke-linecap='round' opacity='.85'/%3E%3C/svg%3E",
  formats: [
    { id: "620", ext: "mp4", height: 2160, fps: 30, vcodec: "vp9.2", acodec: "opus", filesize: 2140000000 },
    { id: "137", ext: "mp4", height: 1080, fps: 30, vcodec: "avc1.64002a", acodec: "mp4a.40.2", filesize: 734003200 },
    { id: "136", ext: "mp4", height: 720, fps: 30, vcodec: "avc1.64001f", acodec: "mp4a.40.2", filesize: 367001600 }
  ],
  subtitles: { "tr": ["srt", "vtt"], "en": ["srt"] }
};

var MOCK_CONFIG = { download_dir: "/home/dat/Videolar/olta", max_concurrent: 2 };

/* ---------------- API layer ---------------- */

function apiGet(path) { return api("GET", path, null); }
function apiPost(path, body) { return api("POST", path, body); }
function apiDelete(path) { return api("DELETE", path, null); }

function api(method, path, body) {
  if (MOCK) return mockApi(method, path, body);
  var opts = { method: method, headers: {} };
  if (body !== null && body !== undefined) {
    opts.headers["Content-Type"] = "application/json";
    opts.body = JSON.stringify(body);
  }
  return fetch(path, opts).then(function (res) {
    return res.json().catch(function () { return {}; }).then(function (data) {
      if (!res.ok) throw new Error(data && data.error ? data.error : "Sunucu hatası (" + res.status + ")");
      return data;
    });
  }, function () {
    throw new Error("Sunucuya bağlanılamadı. olta çalışıyor mu?");
  });
}

/* Mock router: same shapes as the contract. */
function mockApi(method, path, body) {
  return new Promise(function (resolve, reject) {
    setTimeout(function () {
      if (method === "GET" && path === "/api/health") return resolve(MOCK_HEALTH);
      if (method === "GET" && path === "/api/jobs") return resolve({ jobs: mockJobs.slice() });
      if (method === "GET" && path === "/api/config") return resolve(Object.assign({}, MOCK_CONFIG));
      if (method === "POST" && path === "/api/info") {
        if (!body || !body.url || !/^https?:\/\//i.test(body.url.trim())) {
          return reject(new Error("Geçerli bir bağlantı girin."));
        }
        /* "list=" (or /list/) URLs resolve to the canned playlist info so the
         * save flow is fully testable in mock mode. */
        return resolve(/list=|\/list\//.test(body.url) ? MOCK_INFO_PL : MOCK_INFO);
      }
      if (method === "POST" && path === "/api/download") {
        var now = Math.floor(Date.now() / 1000);
        var isPl = !!(body && body.playlist);
        var plTotal = isPl ? 12 : 0;
        var job = {
          id: "m-" + (mockSeq++), url: body.url, title: body.title || "Bilinmeyen başlık",
          kind: body.kind || "video", state: "queued", progress: 0, speed: null, eta: null,
          playlist: isPl, archive: isPl ? !!body.archive : false,
          pl_index: 0, pl_total: plTotal,
          filepath: null, error: null, created_at: now
        };
        mockJobs.unshift(job);
        return resolve({ id: job.id });
      }
      if (method === "GET" && path === "/api/playlists") {
        return resolve({ playlists: mockPlaylists.slice() });
      }
      if (method === "POST" && path === "/api/playlists") {
        var pUrl = body && String(body.url || "").trim();
        var pTitle = body && String(body.title || "").trim();
        if (!pUrl || !/^https?:\/\//i.test(pUrl)) {
          return reject(new Error("Geçerli bir bağlantı girin."));
        }
        for (var pi = 0; pi < mockPlaylists.length; pi++) {
          if (mockPlaylists[pi].url === pUrl) {
            return resolve({ ok: true, duplicate: true, playlist: mockPlaylists[pi] });
          }
        }
        var nowPl = Math.floor(Date.now() / 1000);
        var newPl = { url: pUrl, title: pTitle || "Bilinmeyen başlık", added_at: nowPl, last_downloaded_at: null };
        mockPlaylists.unshift(newPl);
        return resolve({ ok: true, playlist: newPl });
      }
      var mPlDel = path.match(/^\/api\/playlists\?url=([^&]+)$/);
      if (method === "DELETE" && mPlDel) {
        var delUrl = decodeURIComponent(mPlDel[1]);
        var before = mockPlaylists.length;
        mockPlaylists = mockPlaylists.filter(function (x) { return x.url !== delUrl; });
        if (mockPlaylists.length === before) return reject(new Error("Liste bulunamadı."));
        return resolve({ ok: true });
      }
      var m = path.match(/^\/api\/jobs\/([^/]+)\/(cancel|remove)$/);
      if (method === "POST" && m) {
        var found = null;
        for (var i = 0; i < mockJobs.length; i++) if (mockJobs[i].id === m[1]) found = mockJobs[i];
        if (!found) return reject(new Error("İş bulunamadı."));
        if (m[2] === "cancel") {
          if (found.state === "running" || found.state === "queued") found.state = "canceled";
        } else {
          mockJobs = mockJobs.filter(function (x) { return x !== found; });
        }
        return resolve({ ok: true });
      }
      if (method === "POST" && path === "/api/config") {
        var dir = String(body.download_dir || "").trim();
        var max = Number(body.max_concurrent);
        if (!dir) return reject(new Error("Klasör boş olamaz."));
        if (!dir.startsWith("/")) return reject(new Error("Klasör mutlak bir yol olmalı."));
        if (!(max >= 1 && max <= 8)) return reject(new Error("En fazla indirme 1-8 arasında olmalı."));
        MOCK_CONFIG = { download_dir: dir, max_concurrent: Math.round(max) };
        return resolve(Object.assign({}, MOCK_CONFIG));
      }
      reject(new Error("Bilinmeyen istek: " + path));
    }, 120);
  });
}

/* ---------------- Theme ---------------- */

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  var btn = $("themeBtn");
  btn.setAttribute("aria-pressed", String(theme === "light"));
  btn.setAttribute("title", theme === "dark" ? "Açık temaya geç" : "Koyu temaya geç");
}

function initTheme() {
  applyTheme(document.documentElement.dataset.theme === "light" ? "light" : "dark");
  $("themeBtn").addEventListener("click", function () {
    var next = document.documentElement.dataset.theme === "light" ? "dark" : "light";
    try { localStorage.setItem("olta.theme", next); } catch (e) { /* private mode */ }
    applyTheme(next);
  });
}

/* ---------------- Toasts ---------------- */

function showToast(message, kind) {
  var el = document.createElement("div");
  el.className = "toast" + (kind === "error" ? " toast-error" : kind === "ok" ? " toast-ok" : "");
  el.textContent = message;
  $("toasts").appendChild(el);
  setTimeout(function () {
    el.classList.add("out");
    setTimeout(function () { el.remove(); }, 220);
  }, 3800);
}

/* ---------------- Info card ---------------- */

var state = { info: null, kind: "video", fetching: false };

function setInfoFetching(on) {
  state.fetching = on;
  $("infoBtn").disabled = on;
  $("infoSpinner").hidden = !on;
  $("infoBtnLabel").textContent = on ? "Alınıyor…" : "Bilgiyi Al";
}

function setKind(kind) {
  state.kind = kind;
  $("kindVideo").setAttribute("aria-checked", String(kind === "video"));
  $("kindAudio").setAttribute("aria-checked", String(kind === "audio"));
  /* Roving tabindex: only the checked radio is in the tab order. */
  $("kindVideo").tabIndex = kind === "video" ? 0 : -1;
  $("kindAudio").tabIndex = kind === "audio" ? 0 : -1;
  $("qualityField").hidden = kind !== "video";
  $("subsField").hidden = kind !== "video";
  $("audioField").hidden = kind !== "audio";
}

function fillSubsSelect(subs) {
  var sel = $("subsSel");
  sel.textContent = "";
  var langs = subs ? Object.keys(subs).sort() : [];
  var opt = function (value, label, disabled) {
    var o = document.createElement("option");
    o.value = value;
    o.textContent = disabled ? label + " (yok)" : label;
    o.disabled = !!disabled;
    sel.appendChild(o);
  };
  var langList = langs.length ? " (" + langs.join(", ") + ")" : "";
  opt("none", "Yok", false);
  opt("embed", "Gömülü" + langList, !langs.length);
  opt("file", "Dosya" + langList, !langs.length);
}

/* Disable quality options above the best available height. */
function capQualityOptions(formats) {
  var maxH = 0, i;
  for (i = 0; formats && i < formats.length; i++) {
    if (formats[i].height && formats[i].height > maxH) maxH = formats[i].height;
  }
  var order = ["2160", "1440", "1080", "720", "480", "360"];
  for (i = 0; i < order.length; i++) {
    $("qualitySel").querySelector('option[value="' + order[i] + '"]')
      .disabled = maxH > 0 && Number(order[i]) > maxH;
  }
}

function renderInfo(info) {
  state.info = info;
  $("infoTitle").textContent = info.title || "Bilinmeyen başlık";
  var meta = [];
  if (info.uploader) meta.push(info.uploader);
  if (info.channel) meta.push("Kanal: " + info.channel);
  if (info.duration) meta.push(fmtDuration(info.duration));
  $("infoMeta").textContent = meta.join(" · ");

  var thumb = $("infoThumb");
  if (info.thumbnail) {
    thumb.src = info.thumbnail;
    thumb.hidden = false;
  } else {
    thumb.hidden = true;
  }

  var isPl = !!info.is_playlist;
  $("playlistField").hidden = !isPl;
  if (isPl) {
    $("playlistChk").checked = true;
    $("archiveChk").checked = true;
  }
  updateArchiveVisibility();
  $("savePlBtn").hidden = !isPl;
  if (isPl) updateSavePlBtn();
  $("downloadBtn").disabled = false;
  $("downloadBtnLabel").textContent = "İndir";

  fillSubsSelect(info.subtitles);
  capQualityOptions(info.formats);
  $("infoCard").hidden = false;
  setKind(state.kind);
}

/* Archive recording only affects whole-playlist downloads, so the option is
 * shown only while "Tüm oynatma listesini indir" is checked. */
function updateArchiveVisibility() {
  var show = !!(state.info && state.info.is_playlist && $("playlistChk").checked);
  $("archiveRow").hidden = !show;
  $("archiveHint").hidden = !show;
}

function fetchInfo() {
  var url = $("urlInput").value.trim();
  if (!url) { showToast("Önce bir bağlantı yapıştır.", "error"); return; }
  if (state.fetching) return;
  setInfoFetching(true);
  apiPost("/api/info", { url: url })
    .then(function (info) {
      renderInfo(info);
      $("downloadBtn").focus({ preventScroll: true });
    })
    .catch(function (err) { showToast(err.message, "error"); })
    .finally(setInfoFetching.bind(null, false));
}

/* ---------------- Jobs list ----------------
   Keyed rows so the 500 ms poll updates in place
   (no focus loss, no re-created buttons). */

var jobRows = new Map(); // id -> {root, refs}

function buildJobRow(job) {
  var root = document.createElement("li");
  root.className = "card job";

  var head = document.createElement("div");
  head.className = "job-head";
  var title = document.createElement("span");
  title.className = "job-title";
  var chip = document.createElement("span");
  chip.className = "chip";
  var plChip = document.createElement("span");
  plChip.className = "chip chip-pl chip-plain";
  plChip.hidden = true;
  head.appendChild(title);
  head.appendChild(plChip);
  head.appendChild(chip);

  var progress = document.createElement("div");
  progress.className = "job-progress";
  var bar = document.createElement("div");
  bar.className = "bar";
  var fill = document.createElement("div");
  fill.className = "bar-fill";
  bar.appendChild(fill);
  var countChip = document.createElement("span");
  countChip.className = "chip chip-count chip-plain";
  countChip.hidden = true;
  var barRow = document.createElement("div");
  barRow.className = "bar-row";
  barRow.appendChild(bar);
  barRow.appendChild(countChip);
  var stats = document.createElement("div");
  stats.className = "job-stats";
  progress.appendChild(barRow);
  progress.appendChild(stats);

  var path = document.createElement("p");
  path.className = "job-path";
  path.innerHTML =
    '<svg class="ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg><span></span>';

  var errorLine = document.createElement("p");
  errorLine.className = "job-error";

  var actions = document.createElement("div");
  actions.className = "job-actions";
  var cancelBtn = document.createElement("button");
  cancelBtn.type = "button";
  cancelBtn.className = "btn btn-ghost btn-sm";
  cancelBtn.textContent = "İptal";
  cancelBtn.addEventListener("click", function () { cancelJob(job.id, cancelBtn); });
  var removeBtn = document.createElement("button");
  removeBtn.type = "button";
  removeBtn.className = "btn btn-ghost btn-sm";
  removeBtn.textContent = "Kaldır";
  removeBtn.addEventListener("click", function () { removeJob(job.id, removeBtn); });
  actions.appendChild(cancelBtn);
  actions.appendChild(removeBtn);

  root.appendChild(head);
  root.appendChild(progress);
  root.appendChild(path);
  root.appendChild(errorLine);
  root.appendChild(actions);

  return {
    root: root,
    title: title, chip: chip, plChip: plChip, countChip: countChip,
    fill: fill, stats: stats,
    progress: progress, path: path, pathText: path.querySelector("span"),
    error: errorLine, cancel: cancelBtn
  };
}

function updateJobRow(row, job) {
  var st = job.state;
  row.root.dataset.state = st;
  row.title.textContent = job.title || job.url || job.id;
  row.chip.className = "chip chip-" + st;
  row.chip.textContent = STATE_CHIP[st] || st;

  var showPl = !!job.playlist && (job.pl_total || 0) > 1;
  row.plChip.hidden = !showPl;
  row.countChip.hidden = !showPl;
  if (showPl) {
    row.countChip.textContent = (job.pl_index || 0) + "/" + job.pl_total;
  }

  row.fill.style.width = (st === "done" ? 100 : Math.max(0, Math.min(100, job.progress || 0))) + "%";

  var left = fmtPercent(job.progress || 0);
  var right = [job.speed, job.eta != null ? fmtEta(job.eta) : ""].filter(Boolean).join(" · ");
  if (st === "queued") { left = "Sırada"; right = jobTime(job.created_at); }
  if (st === "done") right = jobTime(job.created_at);
  row.stats.textContent = "";
  var l = document.createElement("span"); l.textContent = left;
  var r = document.createElement("span"); r.textContent = right;
  row.stats.appendChild(l);
  row.stats.appendChild(r);

  /* Bar shows for running and done; queued/error rows hide it. */
  row.progress.hidden = st === "error" || st === "queued";
  row.path.hidden = st !== "done" || !job.filepath;
  if (st === "done" && job.filepath) row.pathText.textContent = job.filepath;

  row.error.hidden = st !== "error" || !job.error;
  if (st === "error" && job.error) row.error.textContent = job.error;

  row.cancel.hidden = !(st === "running" || st === "queued");
  row.cancel.disabled = false;
}

function renderJobs(jobs) {
  var list = $("jobList");
  var i, row;
  /* New rows are appended in server order (newest first). */
  for (i = 0; i < jobs.length; i++) {
    if (!jobRows.has(jobs[i].id)) jobRows.set(jobs[i].id, buildJobRow(jobs[i]));
  }
  /* Reconcile DOM order with the server order and drop removed jobs. */
  var seen = new Set();
  for (i = 0; i < jobs.length; i++) {
    seen.add(jobs[i].id);
    row = jobRows.get(jobs[i].id);
    if (list.children[i] !== row.root) list.insertBefore(row.root, list.children[i] || null);
    updateJobRow(row, jobs[i]);
  }
  jobRows.forEach(function (r, id) {
    if (!seen.has(id)) { r.root.remove(); jobRows.delete(id); }
  });
  var empty = jobs.length === 0;
  list.hidden = empty;
  $("emptyState").hidden = !empty;
}

function cancelJob(id, btn) {
  btn.disabled = true;
  apiPost("/api/jobs/" + encodeURIComponent(id) + "/cancel")
    .catch(function (err) { showToast(err.message, "error"); btn.disabled = false; });
}

function removeJob(id, btn) {
  btn.disabled = true;
  apiPost("/api/jobs/" + encodeURIComponent(id) + "/remove")
    .catch(function (err) { showToast(err.message, "error"); btn.disabled = false; });
}

/* ---------------- Download action ---------------- */

function startDownload() {
  if (!state.info) return;
  var isPl = !!(state.info.is_playlist && !$("playlistField").hidden && $("playlistChk").checked);
  var payload = {
    url: $("urlInput").value.trim(),
    kind: state.kind,
    title: state.info.title
  };
  if (isPl) {
    payload.playlist = true;
    payload.archive = $("archiveChk").checked;
  }
  if (state.kind === "video") {
    payload.quality = $("qualitySel").value;
    payload.subtitles = $("subsSel").value;
  } else {
    payload.audio_format = $("audioSel").value;
  }
  var folder = $("folderInput").value.trim();
  if (folder) payload.folder = folder;

  /* Keep the playlist checkbox as-is after starting a download: the info
   * card still shows the same URL, and resetting it here would flash the
   * "single video only" note even though the playlist download just started.
   * The checkbox is reset on URL change (init listener). */
  $("downloadBtn").disabled = true;
  apiPost("/api/download", payload)
    .then(function () {
      showToast("İndirme başladı.", "ok");
      /* The next poll (≤500 ms) brings the new job in; jump to the list. */
      $("jobList").hidden = false;
      $("emptyState").hidden = true;
    })
    .catch(function (err) { showToast(err.message, "error"); })
    .finally(function () { $("downloadBtn").disabled = false; });
}

/* ---------------- Saved playlists ----------------
   No polling: refetched on init and after every mutation. */

var savedPlaylists = new Map(); // url -> playlist entry (mirror of GET /api/playlists)
var pendingDeleteUrl = null;

/* Saved state lives in savedPlaylists (loaded list), so the button flips to
 * "Kaydedildi" once the current URL is on record. */
function setSavePlBtn(saved) {
  $("savePlBtn").disabled = saved;
  $("savePlBtnLabel").textContent = saved ? "Kaydedildi" : "Kaydet";
}

function updateSavePlBtn() {
  if (!state.info || !state.info.is_playlist) return;
  setSavePlBtn(savedPlaylists.has($("urlInput").value.trim()));
}

function savePlaylist() {
  if (!state.info) return;
  var url = $("urlInput").value.trim();
  if (!url) { showToast("Önce bir bağlantı yapıştır.", "error"); return; }
  var btn = $("savePlBtn");
  btn.disabled = true;
  apiPost("/api/playlists", { url: url, title: state.info.title || "Bilinmeyen başlık" })
    .then(function (res) {
      var dup = !!(res && res.duplicate);
      savedPlaylists.set(url, (res && res.playlist) || { url: url, title: state.info.title });
      setSavePlBtn(true);
      showToast(dup ? "Bu liste zaten kayıtlı." : "Liste kaydedildi.", dup ? undefined : "ok");
      loadPlaylists();
    })
    .catch(function (err) { showToast(err.message, "error"); btn.disabled = false; });
}

function plMetaText(pl) {
  return "Eklenme: " + fmtDate(pl.added_at);
}

function buildPlRow(pl) {
  var root = document.createElement("li");
  root.className = "card pl-row";
  var titleText = pl.title || pl.url;

  /* The whole text block is a button: clicking loads the URL into the top
   * input and fetches its info. The delete button stays a separate control. */
  var openBtn = document.createElement("button");
  openBtn.type = "button";
  openBtn.className = "pl-row-main";

  var title = document.createElement("span");
  title.className = "pl-row-title";
  title.textContent = titleText;

  var url = document.createElement("span");
  url.className = "pl-row-url";
  url.textContent = pl.url;
  url.title = pl.url;

  var meta = document.createElement("span");
  meta.className = "pl-row-meta";
  meta.textContent = plMetaText(pl);

  openBtn.appendChild(title);
  openBtn.appendChild(url);
  openBtn.appendChild(meta);
  openBtn.addEventListener("click", function () { loadIntoInput(pl.url, root); });

  var actions = document.createElement("div");
  actions.className = "pl-row-actions";

  var delBtn = document.createElement("button");
  delBtn.type = "button";
  delBtn.className = "btn btn-ghost btn-sm pl-del";
  delBtn.setAttribute("aria-label", "Listeyi sil");
  delBtn.title = "Listeyi sil";
  delBtn.innerHTML =
    '<svg class="ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M3 6h18"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><path d="M10 11v6M14 11v6"/></svg>';
  delBtn.addEventListener("click", function () { askDeletePl(pl.url, titleText); });

  actions.appendChild(delBtn);

  root.appendChild(openBtn);
  root.appendChild(actions);
  return root;
}

/* Row click → fill the top input, flash the row, scroll it into view,
 * then run the regular info flow. */
function loadIntoInput(url, row) {
  $("urlInput").value = url;
  if (row) {
    row.classList.add("flash");
    setTimeout(function () { row.classList.remove("flash"); }, 900);
  }
  var card = $("urlInput").closest("section");
  if (card && card.scrollIntoView) {
    var reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    card.scrollIntoView({ behavior: reduce ? "auto" : "smooth", block: "start" });
  }
  showToast("Liste bağlantısı üstteki alana kopyalandı.", "ok");
  fetchInfo();
}

function askDeletePl(url, title) {
  pendingDeleteUrl = url;
  $("plDeleteText").textContent =
    "“" + (title || url) + "” kayıtlı listelerden silinecek. İndirilen dosyalar silinmez.";
  $("plDeleteDlg").showModal();
}

function confirmDeletePl(ev) {
  ev.preventDefault();
  var url = pendingDeleteUrl;
  $("plDeleteDlg").close();
  if (!url) return;
  apiDelete("/api/playlists?url=" + encodeURIComponent(url))
    .then(function () {
      savedPlaylists.delete(url);
      showToast("Liste silindi.", "ok");
      updateSavePlBtn();
      loadPlaylists();
    })
    .catch(function (err) { showToast(err.message, "error"); });
}

function loadPlaylists() {
  apiGet("/api/playlists")
    .then(function (data) {
      var list = data.playlists || [];
      savedPlaylists.clear();
      for (var i = 0; i < list.length; i++) savedPlaylists.set(list[i].url, list[i]);
      renderPlaylists(list);
      updateSavePlBtn();
    })
    .catch(function () { /* backend offline: panel stays as-is */ });
}

function renderPlaylists(playlists) {
  var list = $("plList");
  list.textContent = "";
  for (var i = 0; i < playlists.length; i++) list.appendChild(buildPlRow(playlists[i]));
  var empty = playlists.length === 0;
  list.hidden = empty;
  $("plEmptyState").hidden = !empty;
}

/* ---------------- Settings dialog ---------------- */

function openSettings() {
  apiGet("/api/config")
    .then(function (cfg) {
      $("cfgDir").value = cfg.download_dir || "";
      $("cfgMax").value = cfg.max_concurrent || 2;
    })
    .catch(function (err) { showToast(err.message, "error"); });
  $("settingsDlg").showModal();
}

function saveSettings(ev) {
  ev.preventDefault();
  var body = {
    download_dir: $("cfgDir").value.trim(),
    max_concurrent: Number($("cfgMax").value)
  };
  $("settingsSave").disabled = true;
  apiPost("/api/config", body)
    .then(function (cfg) {
      $("cfgDir").value = cfg.download_dir;
      $("cfgMax").value = cfg.max_concurrent;
      $("settingsDlg").close();
      showToast("Ayarlar kaydedildi.", "ok");
    })
    .catch(function (err) { showToast(err.message, "error"); })
    .finally(function () { $("settingsSave").disabled = false; });
}

/* ---------------- Polling ---------------- */

function pollJobs() {
  apiGet("/api/jobs")
    .then(function (data) { renderJobs(data.jobs || []); })
    .catch(function () { /* backend offline: keep last state, retry next tick */ });
}

function startPolling() {
  if (MOCK) {
    mockInitJobs();
    mockInitPlaylists();
    mockTimer = setInterval(mockTick, 500);
  }
  pollJobs();
  setInterval(pollJobs, 500);
}

/* ---------------- Init ---------------- */

function init() {
  initTheme();

  $("infoBtn").addEventListener("click", fetchInfo);
  $("urlInput").addEventListener("keydown", function (e) {
    if (e.key === "Enter") { e.preventDefault(); fetchInfo(); }
  });
  /* Paste → fill, then fetch info automatically (Seal-style flow). */
  $("urlInput").addEventListener("paste", function () {
    setTimeout(function () {
      if (!state.fetching && /^https?:\/\//i.test($("urlInput").value.trim())) fetchInfo();
    }, 0);
  });

  $("kindVideo").addEventListener("click", function () { setKind("video"); });
  $("kindAudio").addEventListener("click", function () { setKind("audio"); });

  /* Archive recording only applies to whole-playlist downloads. */
  $("playlistChk").addEventListener("change", updateArchiveVisibility);

  /* URL changes reset transient form state. */
  $("urlInput").addEventListener("input", function () {
    $("playlistChk").checked = false;
    $("archiveChk").checked = true;
    $("savePlBtn").hidden = true;
    updateArchiveVisibility();
  });

  /* Arrow keys move within the kind radio group (WAI-ARIA pattern). */
  var segBtns = [$("kindVideo"), $("kindAudio")];
  segBtns.forEach(function (btn, idx) {
    btn.addEventListener("keydown", function (e) {
      var dir = (e.key === "ArrowRight" || e.key === "ArrowDown") ? 1 :
                (e.key === "ArrowLeft" || e.key === "ArrowUp") ? -1 : 0;
      if (!dir) return;
      e.preventDefault();
      var next = segBtns[(idx + dir + segBtns.length) % segBtns.length];
      next.focus();
      next.click();
    });
  });

  $("downloadBtn").addEventListener("click", startDownload);
  $("savePlBtn").addEventListener("click", savePlaylist);

  $("infoThumb").addEventListener("error", function () {
    this.src = PLACEHOLDER_THUMB;
  });

  $("settingsBtn").addEventListener("click", openSettings);
  $("settingsForm").addEventListener("submit", saveSettings);
  $("settingsCancel").addEventListener("click", function () { $("settingsDlg").close(); });

  $("plDeleteForm").addEventListener("submit", confirmDeletePl);
  $("plDeleteCancel").addEventListener("click", function () { $("plDeleteDlg").close(); });
  $("plDeleteDlg").addEventListener("close", function () { pendingDeleteUrl = null; });

  startPolling();
  loadPlaylists(); /* one-shot fetch: no 500 ms polling for saved playlists */

  /* Health check (prod only): warn about missing tools. */
  if (!MOCK) {
    apiGet("/api/health").then(function (h) {
      if (h && h.ok) {
        if (h.ffmpeg === false) showToast("ffmpeg bulunamadı; birleştirme/dönüştürme çalışmaz.", "error");
        if (!h.yt_dlp) showToast("yt-dlp bulunamadı; indirme çalışmaz.", "error");
      }
    }).catch(function () {
      showToast("Sunucuya bağlanılamadı. olta çalışıyor mu?", "error");
    });
  }
}

document.addEventListener("DOMContentLoaded", init);
