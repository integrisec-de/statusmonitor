# integrisec Statusmonitor – Funktionsumfang

Statische Status-Page für die interne und externe Krisenkommunikation von Versorgern
und KRITIS-nahen Betreibern. Kommuniziert Betriebsstatus, Störungen, Wartungen und –
bei erheblichen Vorfällen – die NIS-2-Meldefristen. Ohne Server, ohne Build, ohne
externe Requests.

---

## Zwei autarke Welten aus einer Code-Basis
- Trennung nach **Personenbezug**, nicht nach Wichtigkeit (NIS-2 § 30, ISO 27001 A.5.14).
- **Öffentliche** Seite liegt außen (z. B. Cloudflare Pages) und bleibt erreichbar, auch
  wenn die interne Umgebung gestört ist.
- **Interne** Seite liegt im eigenen Netz und zeigt die Vollansicht; Daten verlassen das
  Netz nie.
- **Eine** `index.html` bedient drei Ansichten über `?ansicht=public|intern|demo`
  (ersatzweise `data-ansicht` am `<html>`, sonst `public`).

## Öffentliche Ansicht (bewusst minimal)
- Banner mit Gesamtstatus.
- **Aktuelle Störungen** mit Verlaufs-Updates und Zeitstempeln.
- **Geplante Wartungen**.
- Bewusst **ausgeblendet**: Komponentenliste, „Letzte Ereignisse", NIS-2-Box,
  interne Notizen, Namen – „nur darstellen, wenn etwas nicht geht".
- Footer „betrieben mit **integrisec**" (verlinkt auf integrisec.de) als Voreinstellung.
- **Defense-in-depth:** personenbezogene/interne Felder werden auch clientseitig vor dem
  Rendern entfernt.

## Interne Ansicht (Vollbild)
- Alle Komponenten und Gruppen, inkl. nur-intern gekennzeichneter Einträge.
- **NIS-2-Box mit Live-Countdown** je erheblichem Vorfall.
- **Interne Notizen**, **Verantwortlich** (pro Vorfall) und **Bearbeiter** (pro Update).
- **„Letzte Ereignisse"** (behobene Vorfälle + Chronik).

## NIS-2-Meldefristen
- Markierung „erheblicher Sicherheitsvorfall i. S. d. § 32 BSIG".
- Automatische Berechnung der Fristen ab Vorfallbeginn: **Erstmeldung +24 h**,
  **Folgemeldung +72 h**, **Abschlussmeldung +1 Monat**.
- **Countdown** mit Farbwechsel (offen / läuft / überschritten), Aktualisierung im Minutentakt.
- Erscheint ausschließlich intern.

## Vorfälle & Lebenszyklus
- Status **aktiv / behoben** (+ `behobenAm`); separates Feld für die Arbeits-**Phase**
  (erkannt, untersuchung, identifiziert, beobachtung, behoben).
- Aktive Vorfälle unter „Aktuelle Störungen", behobene dauerhaft unter „Letzte Ereignisse".
- **Öffentliche `status.json` = dauerhaftes, personenbezugsfreies Nachweisarchiv**
  (kein zeitbasiertes Entfernen).
- Schweregrad (geringfügig / erheblich), betroffene Komponenten, Verlaufs-Updates.

## Komponenten & Wartungen
- Komponenten mit Status **Betrieb / Eingeschränkt / Störung / Wartung**, in Gruppen.
- Sichtbarkeits-Flag **öffentlich/intern** je Komponente und je Vorfall.
- Geplante Wartungen mit Zeitfenster und Beschreibung.

## Editor (`admin.html`)
- Reiner Browser-Editor, integrisec-CI, **Hell-/Dunkel-Theme**; Tabs für Allgemein,
  Komponenten, Störungen, Wartungen, Historie.
- Pflege von Komponenten, Vorfällen, Updates, Wartungen, Chronik.
- **Öffentlich-sichtbar-Schalter**, **interne Notiz**, **Verantwortlich/Bearbeiter**.
- **NIS-2-Schalter** mit automatischer Fristberechnung.
- **Lebenszyklus-Umschalter** „Als behoben markieren".
- **Aufbewahrungsfristen** (nur personenbezogene Daten): bestätigungspflichtige Prüfung,
  die abgelaufene **öffentliche** Vorfälle **anonymisiert** (Eintrag bleibt) und rein
  **interne** löscht.
- **DSGVO-Hinweis** im Editor (keine Klarnamen in öffentlichen Meldungstexten).
- Demo-Daten-Laden, JSON-Validierung.

## Export, Archiv & Logbuch
- **Zwei-Welten-Export:** öffentliche `status.json` (gefiltert) und interne
  `status-intern.json` (vollständig); die öffentliche Datei wird zugleich als
  `status-public-local.json` für die interne VM erzeugt.
- **Sicherheits-Check** beim Public-Export: garantiert kein `nis2`, `interneNotiz`,
  `verantwortlich`, `bearbeiter` und keine nicht-öffentlichen Einträge.
- **Archiv-Garantie:** beim Public-Export wird das vorhandene Archiv über die Vorfall-ID
  zusammengeführt (frische Fassung gewinnt, Archiv-Einträge gehen nicht verloren).
- **CSV-Logbuch** (Nachweis/Audit), UTF-8 mit BOM: internes Logbuch inkl. Spalten
  Verantwortlich/Bearbeiter und NIS-2-Fristen; öffentliches Logbuch ohne personenbezogene
  Spalten.

## Status-Badge (`badge.js`)
- Eigenständiges Snippet zum Einbinden auf einer beliebigen Website – **dauerhaft sichtbar**
  als Vertrauens- und Informationselement.
- **Drei Ampelzustände:** NORMAL (grün, „Alle Systeme verfügbar"), STÖRUNG (bernstein) und
  KRITISCH (rot, bei `gesamtstatus "stoerung"` + aktivem Vorfall mit Schweregrad
  „erheblich"). „Details" verlinkt die Status-Seite.
- Varianten **dot / bar / block** per `data`-Attribut; `block` mit optionalem White-Label
  (`data-label`).
- Barrierearm (Punkt + Text, `role="status"`/`aria-label`), dezent, fügt sich in helle wie
  dunkle Kundenseiten ein.
- Kein Tracking, keine externen Requests außer dem Laden der `status.json`.

## Branding
- Footer „betrieben mit integrisec" ist voreingestellt. Der Editor bietet keinen
  Schalter dafür; ändern oder entfernen lässt er sich im Quelltext der `index.html`.

## Darstellung
- **Hell-/Dunkel-Theme** und **Farbeditor** (Akzentfarben), lokal im Browser gespeichert.
- Schrift **Outfit lokal** ausgeliefert – keine externen Font-Requests.
- **Responsiv** bis zu sehr schmalen Displays (~280 px): kein horizontaler Overflow,
  Titel-Ellipsis, umbrechende Listen.

## Technik & Architektur
- **Rein statisch:** HTML/CSS/JS + JSON, **kein Build, kein Framework, kein Server,
  keine Datenbank**.
- **Keine externen Requests** zur Laufzeit (DSGVO) außer der TLS-Zertifikatsverwaltung
  im internen Betrieb.
- Daten per `fetch` aus JSON; interne Ansicht führt interne Datei + lokale öffentliche
  Kopie über die Vorfall-ID zusammen (autark, nie Nachladen übers Internet).

## Deployment
- **Öffentlich:** Cloudflare Pages (oder beliebiger Webserver). Die öffentliche
  Statusseite ist bewusst indexierbar. Ausgenommen ist nur der Editor
  (`admin.html`) – über Robots-Meta, `robots.txt` und `_headers` im Wurzel-
  verzeichnis. Der Demo-Ordner trägt zusätzlich ein eigenes Robots-Meta und eine
  eigene `robots.txt`.
- **Noindex ist kein Zugangsschutz.** Es hält Suchmaschinen fern, nicht jemanden,
  der die URL kennt. Der Editor braucht zusätzlich eine echte Absicherung – siehe
  `HANDBUCH.md` A.4 (Cloudflare Access bzw. Basic-Auth).
- **Intern:** **Caddy** als einzelne Binary (kein Docker), Auslieferung aus `deploy/`
  inkl. Paketier-Skript, systemd-Unit und Anleitung.
- **HTTPS im Browser grün** über Let's Encrypt (DNS-Challenge) – auch ohne öffentliche
  Erreichbarkeit; Alternativen: interne PKI oder nur HTTP im abgeschotteten Segment.
- **Zugriffsschutz:** Netz-/Firewall-Beschränkung + Basic-Auth auf den Editor.

## Datenschutz & Compliance
- **NIS-2 § 30 / ISO 27001 A.5.14:** getrennte interne/externe Kommunikationswege.
- **NIS-2 § 32 BSIG:** Fristen-Übersicht mit Countdown.
- **Art. 5/25 DSGVO:** Datensparsamkeit, personenbezogene Daten nur intern,
  einstellbare Löschfristen.
- **Verschlüsselung im Transit** (HTTPS), minimale Angriffsfläche, lückenloses
  Vorfall-Logbuch als Auditnachweis.

> Hinweis: Der Statusmonitor ist ein Hilfsmittel zur Kommunikation und Dokumentation.
> Er ersetzt nicht die eigentliche Meldung an die zuständige Behörde und keinen
> Incident-Response-Prozess.
