/* Shared plumbing for the printable sheet pages: saved settings, the settings form,
   the scaled A4 preview and the Print button. Each page supplies a build(state) function. */
(() => {
  "use strict";

  // A4 in millimetres. Everything on a sheet is laid out in mm so print matches the preview.
  const PAGE = { W: 210, H: 297, PAD_X: 16, PAD_Y: 14 };
  PAGE.CONTENT_W = PAGE.W - PAGE.PAD_X * 2;
  PAGE.CONTENT_H = PAGE.H - PAGE.PAD_Y * 2 - 1;
  const HEAD_H = 12;
  const PX_PER_MM = 96 / 25.4;

  const r2 = (n) => Math.round(n * 100) / 100;
  const plural = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`;

  function esc(text) {
    return String(text).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  function chunk(list, size) {
    const out = [];
    for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
    return out;
  }

  function hasHead(state) {
    return Boolean(state.name.trim() || state.title.trim());
  }

  // Small name and title line across the top of a sheet.
  function sheetHead(state) {
    if (!hasHead(state)) return "";
    return `<header class="sheet-head" style="height:${HEAD_H}mm"><span>${esc(state.name.trim())}</span><span>${esc(state.title.trim())}</span></header>`;
  }

  // build(state) returns { pages, summary, font?, empty? }. A page is an HTML string,
  // or { html, label } to add a note such as "Answers" to its preview label.
  function start({ storeKey, defaults, build }) {
    const form = document.getElementById("controls");
    const preview = document.getElementById("preview");
    const sheetsEl = document.getElementById("sheets");
    const printBtn = document.getElementById("printBtn");
    const summaryEl = document.getElementById("summary");
    const state = load();

    function load() {
      try {
        const saved = JSON.parse(localStorage.getItem(storeKey) || "null");
        if (saved && typeof saved === "object") return { ...defaults, ...saved };
      } catch (e) { /* storage unavailable: use defaults */ }
      return { ...defaults };
    }

    function save() {
      try { localStorage.setItem(storeKey, JSON.stringify(state)); } catch (e) { /* not saved, still works */ }
    }

    // Controls marked data-show="key:value value" only appear while state[key] is one of the values.
    function syncVisibility() {
      document.querySelectorAll("[data-show]").forEach((el) => {
        const [key, values] = el.dataset.show.split(":");
        el.hidden = !values.split(" ").includes(String(state[key]));
      });
    }

    function render() {
      syncVisibility();
      const result = build(state);
      if (result.font) sheetsEl.style.setProperty("--sheet-font", result.font);
      summaryEl.textContent = result.summary || "";

      const pages = result.pages || [];
      if (!pages.length) {
        sheetsEl.innerHTML = `<p class="empty">${esc(result.empty || "Nothing to print yet.")}</p>`;
        printBtn.disabled = true;
        printBtn.textContent = "Print";
        return;
      }

      sheetsEl.innerHTML = pages
        .map((page, i) => {
          const { html, label } = typeof page === "string" ? { html: page, label: "" } : page;
          return `<div class="page">
            <p class="page-label">Page ${i + 1} of ${pages.length}${label ? ` · ${esc(label)}` : ""}</p>
            <div class="sheet-wrap"><div class="sheet">${html}</div></div>
          </div>`;
        })
        .join("");
      printBtn.disabled = false;
      printBtn.textContent = `Print ${plural(pages.length, "page")}`;
    }

    function fitPreview() {
      const available = preview.clientWidth - 48;
      const zoom = Math.max(0.2, Math.min(0.85, available / (PAGE.W * PX_PER_MM)));
      preview.style.setProperty("--z", zoom.toFixed(3));
    }

    function fillControls() {
      for (const el of form.elements) {
        if (!el.name || !(el.name in state)) continue;
        if (el.type === "radio") el.checked = String(state[el.name]) === el.value;
        else if (el.type === "checkbox") el.checked = Boolean(state[el.name]);
        else el.value = state[el.name];
      }
    }

    function onChange(e) {
      const el = e.target;
      if (!el.name || !(el.name in state)) return;
      if (el.type === "radio") { if (el.checked) state[el.name] = el.value; }
      else if (el.type === "checkbox") state[el.name] = el.checked;
      else state[el.name] = el.value;
      save();
      render();
    }

    form.addEventListener("input", onChange);
    form.addEventListener("change", onChange);
    form.addEventListener("submit", (e) => e.preventDefault());

    printBtn.addEventListener("click", async () => {
      try { await document.fonts.ready; } catch (e) { /* print anyway */ }
      window.print();
    });

    if ("ResizeObserver" in window) new ResizeObserver(fitPreview).observe(preview);
    else window.addEventListener("resize", fitPreview);

    fillControls();
    fitPreview();
    return { state, render, save, form };
  }

  window.SheetApp = { PAGE, HEAD_H, r2, plural, esc, chunk, hasHead, sheetHead, start };
})();
