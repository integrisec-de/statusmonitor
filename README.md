# integrisec Statusmonitor

Statische Status-Page für die Krisenkommunikation: knappe Information nach außen,
vollständige Lage mit NIS-2-Meldefristen nach innen, lückenloses Protokoll als
Audit-Nachweis. Ohne Server, ohne Datenbank, ohne externe Requests.

**[Live-Demo](https://status.integrisec.de/)** · Lizenz **Apache 2.0** ·
vollständige Anleitung in **[`HANDBUCH.md`](HANDBUCH.md)**

---

## Wofür

Wenn etwas ausfällt, passieren drei Dinge gleichzeitig: die gesetzliche Meldeuhr läuft,
das Telefon steht nicht still, und hinterher fehlt der Nachweis.

- **Keine Meldefrist übersehen.** Die NIS-2-Fristen nach § 32 BSIG laufen als
  Live-Countdown mit – frühe Erstmeldung 24 h und Meldung 72 h ab Kenntnis, Abschlussmeldung ein Monat nach Übermittlung der Meldung –
  und wechseln bei knapper Zeit die Farbe. Nur intern sichtbar.
- **Erreichbar, wenn es darauf ankommt.** Die öffentliche Seite liegt außerhalb der
  eigenen Infrastruktur und bleibt online, auch wenn intern alles steht
  (ISO 27001 A.5.29 / A.5.30).
- **Nachweis ohne Mehraufwand.** Jede Phase wird mit Zeitstempel und Bearbeiter
  festgehalten und als CSV exportiert – Vorfall-Management nach ISO 27001 A.5.24 ff.
  Der Nachweis fällt als Nebenprodukt der ohnehin nötigen Kommunikation an.

## Für wen

Betreiber kritischer Infrastrukturen und regulierte Betriebe mit Meldepflichten nach
§ 32 BSIG. Behörden, die Vorfälle revisionssicher dokumentieren müssen. Besonders
wichtige und wichtige Einrichtungen im Sinne des NIS2UmsuCG. IT-Abteilungen und
Dienstleister, die Störungen für die eigene Organisation oder für Mandanten
kommunizieren.

## Architektur in einem Satz

Zwei autarke Welten aus einer Code-Basis: die **öffentliche** Seite liegt außen
(z. B. Cloudflare Pages) und bleibt erreichbar, auch wenn die interne Umgebung
ausfällt; die **interne** Vollansicht liegt im eigenen Netz. Beide lesen statische
JSON-Dateien, die im Browser gerendert werden. Getrennt wird nach **Personenbezug**,
nicht nach Wichtigkeit (§ 30 BSIG, ISO 27001 A.5.14).

## Funktionen im Überblick

- Öffentliche Ansicht bewusst minimal – Gesamtstatus, aktive Störungen, geplante
  Wartungen. Komponentenliste, interne Notizen und Namen bleiben außen vor.
- Interne Vollansicht mit NIS-2-Countdown, Verantwortlichen und Bearbeitern.
- Browser-Editor (`admin.html`) ohne Server, mit Sicherheitsprüfung vor dem
  Public-Export: interne Felder können nicht nach außen gelangen.
- Vorfall-Logbuch als CSV-Export, das Archiv wird über die Vorfall-ID zusammengeführt.
- Einbettbares **Status-Badge** für die eigene Website, drei Varianten
  (`dot`, `bar`, `block`) und drei Zustände –
  [alle Zustände ansehen](https://status.integrisec.de/badge-demo).
- Hell-/Dunkel-Theme und anpassbare Akzentfarben.

Die vollständige Liste steht in [`FEATURES.md`](FEATURES.md).

## Was ist enthalten

| Datei | Zweck |
|-------|-------|
| `index.html` | Status-Page. Ansicht über `?ansicht=public\|intern\|demo` |
| `status.json` | Öffentliche Datenquelle (nur was nach außen darf) |
| `status-intern.json` | Interne Datenquelle (alle Komponenten, NIS-2, Notizen) |
| `status-public-local.json` | Lokale Kopie der öffentlichen Daten für die interne VM |
| `admin.html` | Browser-Editor zum Pflegen der Daten |
| `badge.js` | Einbettbarer Status-Hinweis für die eigene Website |
| `assets/fonts/` | Lokal ausgelieferte Schriften (Outfit, OFL 1.1) |
| `deploy/` | Paket für den internen Betrieb mit Caddy, inkl. Anleitung |
| `demo/` | Eigenständiges Demo-Bundle mit Beispieldaten |

## Schnellstart

**Variante A — Cloudflare Pages (öffentliche Seite):**
1. Dateien in ein Verzeichnis legen.
2. Über das Cloudflare-Dashboard (Workers & Pages → Create → Pages → Upload assets) oder
   per Wrangler hochladen:
   ```
   npx wrangler pages deploy . --project-name=status --branch=main --commit-dirty=true
   ```
3. Eigene Domain verbinden (z. B. `status.ihre-domain.de`).
4. Editor (`admin.html`) hinter Cloudflare Access (kostenloser Plan) mit MFA absichern.

**Variante B — interne Seite mit Caddy (kein Docker):**
1. Paket bauen (`deploy/paketieren.sh` bzw. `.ps1`) und die Caddy-Binary dazulegen.
2. Als Dienst starten – die Seite läuft direkt in der intern-Ansicht; HTTPS „grün"
   automatisch über Let's Encrypt (DNS-Challenge). Schritt für Schritt:
   [`deploy/ANLEITUNG.md`](deploy/ANLEITUNG.md).
3. Zugriff per Firewall aufs interne Netz beschränken, Editor per Basic-Auth.

Zum Ausprobieren genügt ein lokaler Webserver – die Seiten laden ihre Daten per
`fetch`, über `file://` funktioniert das nicht:

```
python -m http.server 8080
```

## Daten pflegen

`admin.html` im Browser öffnen → Daten eintragen → exportieren. Es werden zwei Dateien
erzeugt: `status.json` (öffentlich, gefiltert) und `status-intern.json` (vollständig).
Die öffentliche Datei kommt nach außen, die interne bleibt im eigenen Netz.
Details und Hinweise zum Datenschutz: [`HANDBUCH.md`](HANDBUCH.md).

## Wichtige Grundsätze

- **Rein statisch:** kein Server, keine Datenbank, keine externen Aufrufe.
- **Autark:** die öffentliche Seite hängt nie von der internen Umgebung ab.
- **Datentrennung:** interne Daten (NIS-2, Namen, Notizen) verlassen das eigene Netz nie.
- **Schriften lokal:** keine externen Font-Requests (DSGVO).
- **Kein Tracking**, keine Analytics, keine Cloud-Abhängigkeit.

## Dokumentation

| Datei | Inhalt |
|-------|--------|
| [`HANDBUCH.md`](HANDBUCH.md) | Einrichtung (Teil A) und Pflege im Alltag (Teil B) |
| [`FEATURES.md`](FEATURES.md) | vollständiger Funktionsumfang |
| [`deploy/ANLEITUNG.md`](deploy/ANLEITUNG.md) | interner Betrieb mit Caddy, DNS-Challenge |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Mitwirken, Konventionen, lokales Testen |
| [`SECURITY.md`](SECURITY.md) | Schwachstellen melden |

## Lizenz

Apache-Lizenz 2.0, siehe [`LICENSE`](LICENSE). Keine Lizenzgebühr, keine Cloud-Gebühr,
keine Staffelung nach Standorten oder Mandanten.

Bei Weitergabe müssen `LICENSE` und `NOTICE` beiliegen. Der Footer „betrieben mit
integrisec" ist davon unabhängig: er ist die Voreinstellung und kann im Quelltext
geändert oder entfernt werden. Fremdkomponenten sind in [`NOTICE`](NOTICE) aufgeführt,
eine Stückliste liegt als [`sbom.cdx.json`](sbom.cdx.json) bei.

## Unterstützung

Der Statusmonitor lässt sich vollständig selbst betreiben. Einführung, Anpassung an die
eigene Umgebung, Einbettung in den Incident-Response- oder ISMS-Prozess und Schulung des
Bereitschaftsteams bieten wir als Beratungsleistung nach Aufwand an:
**status@integrisec.de**

---
© 2026 integrisec — Steven Mai
