/*!
 * integrisec Statusmonitor – Status-Badge
 * Eigenständiges Snippet zum Einbinden auf einer beliebigen Website.
 * Lädt die öffentliche status.json und zeigt DAUERHAFT den Systemstatus –
 * als Vertrauens- und Informationselement. Drei Zustände (Ampel):
 *   NORMAL  (grün)      keine aktive Störung – Standardanzeige
 *   STÖRUNG (bernstein) mindestens eine aktive Störung (informativ)
 *   KRITISCH(rot)       gesamtstatus "stoerung" UND aktiver Vorfall
 *                       mit schweregrad "erheblich"
 *
 * Statisch, kein Tracking, keine externen Requests außer dem Laden der status.json.
 * Konfiguration über data-Attribute am einbindenden <script>-Tag:
 *   data-status-url  Pfad/URL zur öffentlichen status.json (Default "status.json")
 *   data-page-url    Link zur vollständigen Status-Seite ("Details", optional)
 *   data-variant     dot | bar | block   (Default: bar)
 *   data-target      CSS-Selektor eines Zielcontainers (optional)
 *   data-label       nur block: Kopfzeile statt "Systemstatus" (z. B. White-Label)
 */
(function () {
  "use strict";

  var script = document.currentScript || (function () {
    var s = document.getElementsByTagName("script");
    return s[s.length - 1];
  })();

  // Nur http/https und relative Pfade zulassen. Ein javascript:-URL in
  // data-page-url wuerde sonst beim Klick auf "Details" im Kontext der
  // einbindenden Website ausgefuehrt. Geprueft wird eine von Steuerzeichen und
  // Leerraum bereinigte Fassung, zurueckgegeben der unveraenderte Originalwert.
  function sichereUrl(roh) {
    var geprueft = String(roh || "").replace(/[\u0000-\u001F\u007F\s]/g, "");
    if (!geprueft) return "";
    var schema = geprueft.match(/^([a-z][a-z0-9+.-]*):/i);
    if (schema && !/^https?$/i.test(schema[1])) return "";
    return roh;
  }

  var cfg = {
    statusUrl: (script && script.getAttribute("data-status-url")) || "status.json",
    pageUrl:   sichereUrl(script && script.getAttribute("data-page-url")),
    variant:   ((script && script.getAttribute("data-variant")) || "bar").toLowerCase(),
    target:    (script && script.getAttribute("data-target")) || "",
    label:     (script && script.getAttribute("data-label")) || "Systemstatus"
  };
  if (["dot", "bar", "block"].indexOf(cfg.variant) === -1) cfg.variant = "bar";

  // Dezente Ampel-Paletten (kein Neon, ruhig auf fremden Seiten).
  // fg = Text/Border (dunkel), akzent = Punkt/Linie (mittel), bg = Fläche (hell).
  var ZUSTAND = {
    normal:   { fg: "#085041", akzent: "#1D9E75", bg: "#E1F5EE", label: "Alle Systeme verfügbar",
                bar: "Es liegen aktuell keine Störungen vor", detail: false, aria: "Systemstatus: alle Systeme verfügbar" },
    stoerung: { fg: "#633806", akzent: "#BA7517", bg: "#FAEEDA", label: "Aktuelle Störung",
                bar: "Aktuelle Störung", detail: true, aria: "Systemstatus: aktuelle Störung" },
    kritisch: { fg: "#791F1F", akzent: "#A32D2D", bg: "#FCEBEB", label: "Schwerwiegende Störung",
                bar: "Schwerwiegende Störung", detail: true, aria: "Systemstatus: schwerwiegende Störung" }
  };
  var FONT = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif";

  function el(tag, style, text) {
    var e = document.createElement(tag);
    if (style) e.setAttribute("style", style);
    if (text != null) e.textContent = text;
    return e;
  }
  function dotSpan(color, size) {
    var s = el("span", "width:" + size + "px;height:" + size + "px;border-radius:50%;background:" + color + ";flex:0 0 " + size + "px;display:inline-block;");
    s.setAttribute("aria-hidden", "true");
    return s;
  }
  function link(href, style, text) {
    var a = el("a", style, text);
    a.href = href;
    a.setAttribute("rel", "noopener");
    return a;
  }

  function container() {
    if (cfg.target) {
      var t = document.querySelector(cfg.target);
      if (t) return t;
    }
    var c = document.createElement("div");
    if (script && script.parentNode && script.parentNode.nodeName !== "HEAD") {
      script.parentNode.insertBefore(c, script.nextSibling);
    } else {
      document.body.appendChild(c);
    }
    return c;
  }

  // Ampel-Zustand aus status.json ableiten.
  function ermittleZustand(data) {
    var gs = data && data.gesamtstatus;
    if (!gs || gs === "betrieb") return "normal";
    var aktivErheblich = (data.incidents || []).some(function (i) {
      return i && i.status === "aktiv" && i.schweregrad === "erheblich";
    });
    if (gs === "stoerung" && aktivErheblich) return "kritisch";
    return "stoerung";
  }

  function render(data) {
    var z = ZUSTAND[ermittleZustand(data)];
    var host = container();
    var href = cfg.pageUrl;

    if (cfg.variant === "dot") {
      // Minimal: nur der Punkt trägt Farbe, Text erbt die Seiten-Farbe (dark/light-sicher).
      var d = el("span", "display:inline-flex;align-items:center;gap:6px;flex-wrap:wrap;max-width:100%;font-family:" + FONT + ";font-size:13px;color:inherit;");
      d.setAttribute("role", "status");
      d.setAttribute("aria-label", z.aria);
      d.appendChild(dotSpan(z.akzent, 9));
      d.appendChild(el("span", null, z.label));
      if (z.detail && href) {
        d.appendChild(el("span", "opacity:.6;", "·"));
        d.appendChild(link(href, "color:inherit;text-decoration:underline;", "Details"));
      }
      host.appendChild(d);
      return;
    }

    if (cfg.variant === "block") {
      var b = el("div", "font-family:" + FONT + ";border:1px solid " + z.akzent + ";background:" + z.bg + ";color:" + z.fg + ";border-radius:10px;padding:12px 14px;max-width:520px;");
      b.setAttribute("role", "status");
      b.setAttribute("aria-label", z.aria);
      var head = el("div", "display:flex;align-items:center;gap:8px;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.04em;opacity:.85;");
      head.appendChild(dotSpan(z.akzent, 9));
      head.appendChild(el("span", null, cfg.label));
      b.appendChild(head);
      var body = el("div", "font-weight:600;font-size:15px;margin-top:4px;");
      body.appendChild(document.createTextNode(z.label));
      if (z.detail && href) {
        body.appendChild(el("span", "opacity:.55;font-weight:400;", " · "));
        body.appendChild(link(href, "color:" + z.fg + ";font-size:14px;text-decoration:underline;font-weight:400;white-space:nowrap;", "Details ansehen"));
      }
      b.appendChild(body);
      host.appendChild(b);
      return;
    }

    // bar (Default): kompakter Kasten mit eigener Fläche (auf hellen wie dunklen Seiten ok).
    var bar = el("div", "font-family:" + FONT + ";border:1px solid " + z.akzent + ";background:" + z.bg + ";color:" + z.fg + ";border-radius:8px;padding:8px 12px;display:inline-flex;align-items:center;gap:6px 8px;flex-wrap:wrap;max-width:100%;font-size:13px;");
    bar.setAttribute("role", "status");
    bar.setAttribute("aria-label", z.aria);
    bar.appendChild(dotSpan(z.akzent, 9));
    bar.appendChild(el("span", "font-weight:600;", z.bar));
    if (z.detail && href) {
      bar.appendChild(el("span", "opacity:.55;", "·"));
      bar.appendChild(link(href, "color:" + z.fg + ";text-decoration:underline;white-space:nowrap;", "Details"));
    }
    host.appendChild(bar);
  }

  function load() {
    try {
      fetch(cfg.statusUrl, { cache: "no-store" })
        .then(function (r) { return r.ok ? r.json() : null; })
        .then(function (data) { if (data) render(data); })
        .catch(function () { /* bei Fehler bewusst nichts anzeigen */ });
    } catch (e) { /* noop */ }
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", load);
  else load();
})();
