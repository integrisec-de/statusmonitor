# Handbuch — integrisec Statusmonitor

Diese Anleitung führt durch Einrichtung und Betrieb des Statusmonitors. Sie ist in zwei
Teile gegliedert:

- **Teil A — Einrichtung (technisch):** für die IT, einmalig. Installation, Hosting,
  Zugriffsschutz.
- **Teil B — Pflege im Alltag (nicht-technisch):** für alle, die Störungen und Wartungen
  melden. Kein technisches Wissen nötig.

Am Ende: Datenschutz-Hinweise und ein kurzer Abschnitt zur NIS-2-Einordnung.

---

## Das Konzept in Kürze

Der Statusmonitor besteht aus zwei getrennten Welten:

**Die öffentliche Seite** liegt außerhalb Ihres Netzes (z. B. bei Cloudflare). Sie zeigt
Ihren Kunden, Bürgern und Partnern, ob Ihre Dienste laufen. Sie bleibt erreichbar, auch
wenn Ihre interne Umgebung gestört ist — genau dann, wenn man sie braucht.

**Die interne Seite** liegt in Ihrem eigenen Netz. Sie zeigt der IT und dem Krisenstab die
vollständige Lage: alle Komponenten, interne Notizen und die NIS-2-Meldefristen mit
Countdown. Diese Daten verlassen Ihr Netz nicht.

Gepflegt werden beide über denselben Editor (`admin.html`). Sie tragen die Daten einmal
ein und erzeugen daraus zwei Dateien — eine öffentliche (gefiltert) und eine interne
(vollständig).

---

# Teil A — Einrichtung (technisch)

Zielgruppe: IT / Administration. Dieser Teil wird einmalig durchgeführt.

## A.1 Voraussetzungen

- Die ausgelieferten Dateien (siehe `README.md` für die Übersicht).
- Für die öffentliche Seite: ein Cloudflare-Konto **oder** ein erreichbarer Webserver.
- Für die interne Seite: ein kleiner interner Server (Linux oder Windows). Ausgeliefert
  wird mit **Caddy** – einer einzelnen Binary, ohne Docker (Schritt für Schritt in
  `deploy/ANLEITUNG.md`).
- Ein moderner Browser zum Pflegen der Daten.

Es wird **keine** Datenbank, **kein** Node.js und **kein** PHP benötigt; die Seite ist
reines HTML/JavaScript. Die App selbst braucht **keine** Internetverbindung zur Laufzeit –
einzig das automatische HTTPS-Zertifikat (optional, Let's Encrypt) wird über das Internet
erneuert. Alternativen ohne Internet (interne CA, nur HTTP) stehen in `deploy/ANLEITUNG.md`.

## A.2 Die öffentliche Seite einrichten

Die öffentliche Seite soll außerhalb Ihrer eigenen Infrastruktur liegen, damit sie bei
einer internen Störung erreichbar bleibt. Empfohlen: Cloudflare Pages (kostenlos).

### Variante A1 — Cloudflare Pages (empfohlen)

1. Melden Sie sich bei Cloudflare an und öffnen Sie **Workers & Pages**.
2. **Create → Pages → Upload assets**. Vergeben Sie einen Projektnamen (z. B. `status`).
3. Laden Sie die Dateien hoch (mindestens `index.html`, `status.json`, der Ordner
   `assets/`; optional `badge.js`). Den Editor `admin.html` laden Sie ebenfalls hoch,
   wenn Sie ihn von außen erreichbar machen wollen (siehe A.4).
4. Verbinden Sie Ihre eigene Domain, z. B. `status.ihre-domain.de`
   (Pages-Projekt → Custom domains).

Alternativ per Kommandozeile (Wrangler), falls Sie das bevorzugen:
```
npx wrangler pages deploy . --project-name=status --branch=main --commit-dirty=true
```

Aktualisierungen erfolgen, indem Sie die geänderten Dateien (in der Regel `status.json`)
erneut hochladen.

### Variante A2 — klassischer Webserver

1. Kopieren Sie die Dateien in das Web-Verzeichnis (z. B. `/var/www/status`).
2. Stellen Sie sicher, dass `index.html` und `status.json` im selben Verzeichnis liegen.
3. Rufen Sie die Seite über die übliche URL auf.

> **Wichtig:** Öffnen Sie `index.html` nicht per Doppelklick aus dem Dateisystem
> (`file://`). Browser verbieten dann das Laden der `status.json` aus Sicherheitsgründen.
> Die Seite muss über einen Webserver (`http://` bzw. `https://`) ausgeliefert werden.
> Zum lokalen Testen genügt im Verzeichnis: `python -m http.server 8080`, dann
> `http://localhost:8080/`.

## A.3 Die interne Seite einrichten

Die interne Seite wird mit **Caddy** ausgeliefert (einzelne Binary, kein Docker). Die
vollständige Schritt-für-Schritt-Anleitung steht in **`deploy/ANLEITUNG.md`**; in Kürze:

1. Paket erstellen (`deploy/paketieren.ps1` bzw. `deploy/paketieren.sh`) und auf den
   internen Server legen (z. B. `/opt/statusmonitor` bzw. `C:\statusmonitor`).
2. Caddy als Dienst starten (systemd-Unit für Linux bzw. als Windows-Dienst liegen bei).
   Die Seite startet direkt in der **intern-Ansicht**.
3. Die internen Daten `status-intern.json` und die lokale Kopie `status-public-local.json`
   liegen im `site/`-Verzeichnis; beide erzeugt der Editor beim Export. So bleibt die
   interne Seite auch ohne Internetverbindung vollständig.
4. Aufruf: `https://<interner-hostname>/` (lädt direkt die Vollansicht), Editor unter
   `https://<interner-hostname>/admin.html`.
5. **HTTPS „grün":** Caddy holt automatisch ein öffentlich vertrautes Zertifikat über die
   DNS-Challenge (Let's Encrypt) – auch ohne dass der Server von außen erreichbar ist.
   Alternativen (interne CA, nur HTTP) siehe `deploy/ANLEITUNG.md`.
6. Begrenzen Sie den Zugriff auf das interne Netz (Firewall/IP-Beschränkung, VPN).

## A.4 Den Editor absichern

Der Editor (`admin.html`) darf nur von berechtigten Personen erreichbar sein.

- **Öffentlich erreichbarer Editor (für die Rolle „Kommunikation"):** Sichern Sie ihn mit
  **Cloudflare Access** (im kostenlosen Plan enthalten) ab — Anmeldung per
  Single-Sign-On und Zwei-Faktor. So kann die zuständige Person die öffentliche Meldung
  auch von unterwegs setzen, ohne dass Ihr internes Netz verfügbar sein muss.
- **Interner Editor (für die Rolle „IT"):** über die in Caddy hinterlegte **Basic-Auth**
  absichern (Login auf `admin.html`, siehe `deploy/ANLEITUNG.md`); zusätzlich Zugriff auf
  das interne Netz beschränken.

## A.5 Rollen (empfohlen)

Der Statusmonitor unterstützt eine saubere Trennung der Zuständigkeiten:

- **Kommunikation** pflegt die **öffentliche** Seite (Außenmeldungen).
- **IT** pflegt die **interne** Seite (vollständige Lage, NIS-2-Fristen).

Diese Trennung entspricht der Anforderung an getrennte interne und externe
Kommunikationswege und sorgt dafür, dass die Außenkommunikation unabhängig von der
internen Umgebung funktioniert.

## A.6 Schriften und Logo

Die Schriften (Outfit) werden lokal aus `assets/fonts/` ausgeliefert — es werden keine
externen Schriftdienste aufgerufen. Möchten Sie ein eigenes Logo oder eigene Farben,
lässt sich die Darstellung über den Farb-Editor in der Seite anpassen (Hell-/Dunkel-Theme
und Akzentfarben).

Outfit steht unter der SIL Open Font License 1.1, Copyright 2021 The Outfit Project
Authors. Der Lizenztext und die Angaben zur Herkunft liegen als `OFL.txt` und `FONTS.md`
direkt bei den Schriftdateien; bei einer Weitergabe müssen sie mitgeliefert werden.

## A.7 Status-Badge auf der eigenen Website einbinden

Das Badge (`badge.js`) ist ein kleines, eigenständiges Snippet für Ihre **normale
Website** (nicht Teil der Status-Seite selbst). Es lädt die öffentliche `status.json` und
zeigt **dauerhaft** den Systemstatus – als Vertrauens- und Informationselement mit drei
Ampelzuständen:

- **Normal (grün):** keine aktive Störung – „Alle Systeme verfügbar".
- **Störung (bernstein):** mindestens eine aktive Störung, mit „Details"-Link.
- **Kritisch (rot):** schwerwiegende Störung (`gesamtstatus: "stoerung"` und ein aktiver
  Vorfall mit Schweregrad „erheblich").

Statisch, ohne Tracking, ohne externe Requests außer dem Laden der `status.json`.

### Einbau (Copy-Paste)

Fügen Sie an der Stelle, an der das Badge erscheinen soll, ein:

```html
<script
  src="https://status.ihre-domain.de/badge.js"
  data-status-url="https://status.ihre-domain.de/status.json"
  data-page-url="https://status.ihre-domain.de/"
  data-variant="bar"
  defer></script>
```

Das Badge wird direkt nach dem `<script>`-Tag eingefügt. Alternativ steuern Sie mit
`data-target="#mein-container"` einen vorhandenen Container an.

### Optionen (data-Attribute)

| Attribut          | Pflicht   | Default        | Bedeutung |
|-------------------|-----------|----------------|-----------|
| `data-status-url` | empfohlen | `status.json`  | URL/Pfad zur öffentlichen `status.json`. |
| `data-page-url`   | optional  | –              | Link zur vollständigen Status-Seite (erzeugt „Details"-Link). |
| `data-variant`    | optional  | `bar`          | Darstellung: `dot`, `bar` oder `block`. |
| `data-target`     | optional  | –              | CSS-Selektor eines vorhandenen Zielcontainers. |
| `data-label`      | optional  | `Systemstatus` | Nur `block`: Kopfzeile, z. B. „Stadtwerke XY · Systemstatus" (White-Label). |

### Varianten

- **`dot`** – nur ein farbiger Ampelpunkt mit Kurztext (fügt sich minimal in fremde Designs).
- **`bar`** – kompakter Kasten mit Punkt, Kurztext und „Details"-Link (Standard).
- **`block`** – ausdrucksstarker Block mit Kopfzeile „Systemstatus", Zustandstext und
  „Details ansehen"-Link; optionales White-Label über `data-label`.

Jede Variante stellt alle drei Zustände dar. Die Farben sind dezent (grün/bernstein/rot,
kein Neon) und wirken auf hellen wie dunklen Seiten ruhig. Punkt **und** Text tragen den
Zustand (nicht nur Farbe; mit `role="status"`/`aria-label`). Die Schrift nutzt die
System-Schriftart der Website (kein Web-Font-Request).

### Hinweise

- Das Badge wertet nur den öffentlichen Gesamtstatus und den Schweregrad aktiver Vorfälle
  aus. Es greift nie auf interne Daten zu – `status.json` enthält keine personenbezogenen
  Inhalte.
- Schlägt das Laden der `status.json` fehl, zeigt das Badge bewusst nichts an (kein
  Fehlerkasten auf Ihrer Seite).
- Setzen Sie `data-status-url` möglichst auf die öffentlich gehostete `status.json`
  (z. B. Cloudflare Pages), damit das Badge auch dann aktuell ist, wenn Ihre Website auf
  einem anderen System liegt.

---

# Teil B — Pflege im Alltag (nicht-technisch)

Zielgruppe: alle, die Störungen und Wartungen melden. Kein technisches Wissen nötig.

## B.1 Den Editor öffnen

Öffnen Sie `admin.html` im Browser (die IT nennt Ihnen die Adresse). Sie sehen mehrere
Bereiche: Allgemein, Komponenten, Störungen, Wartungen, Historie.

## B.2 Eine Störung melden

1. Wechseln Sie in den Bereich **Störungen** und legen Sie eine neue Störung an.
2. Tragen Sie einen verständlichen **Titel** ein (z. B. „Störung beim E-Mail-Versand").
3. Wählen Sie den **Beginn** und den **Schweregrad**.
4. Geben Sie an, **welche Komponenten betroffen** sind.
5. Entscheiden Sie über **„öffentlich sichtbar"**:
   - **Haken gesetzt:** Die Störung erscheint auch auf der öffentlichen Seite. Wählen Sie
     dies, wenn Kunden/Bürger betroffen sind (z. B. Kundenportal nicht erreichbar).
   - **Haken nicht gesetzt:** Die Störung ist nur intern sichtbar. Wählen Sie dies bei
     rein internen Themen, die nach außen niemanden betreffen.
6. Schreiben Sie ein erstes **Update** — was ist passiert, was wird getan.
7. Tragen Sie unter **Verantwortlich** ein, wer den Vorfall betreut, und unter
   **Bearbeiter** beim jeweiligen Update, wer es verfasst hat. Diese Angaben sind **nur
   intern** sichtbar und erscheinen nie auf der öffentlichen Seite.

Im Verlauf fügen Sie weitere **Updates** hinzu (z. B. „Ursache identifiziert",
„behoben"). So entsteht eine lückenlose, nachvollziehbare Zeitleiste.

## B.3 NIS-2-Meldefristen

Markieren Sie einen Vorfall als **erheblichen Sicherheitsvorfall**, wenn er meldepflichtig
ist. Der Statusmonitor berechnet dann automatisch die Fristen und zeigt sie auf der
**internen** Seite mit Countdown an:

- **Erstmeldung** innerhalb von 24 Stunden
- **Folgemeldung** innerhalb von 72 Stunden
- **Abschlussmeldung** innerhalb eines Monats

Der Countdown wechselt die Farbe, je näher eine Frist rückt, und zeigt Überschreitungen
deutlich an. Diese Informationen erscheinen **nur intern** — auf der öffentlichen Seite
werden sie nie angezeigt.

## B.4 Eine Wartung ankündigen

Im Bereich **Wartungen** tragen Sie geplante Arbeiten mit Zeitraum und Beschreibung ein.
Diese erscheinen vorab auf der Seite, damit Betroffene Bescheid wissen.

## B.5 Eine Störung abschließen

Ist eine Störung behoben, markieren Sie sie als **behoben**. Sie verschwindet dann aus den
aktuellen Meldungen und erscheint unter **„Letzte Ereignisse"**. Der Vorfall bleibt im
Logbuch erhalten — gelöscht wird nichts vorschnell.

## B.6 Veröffentlichen

Wenn Sie fertig sind, **exportieren** Sie die Daten. Dafür gibt es zwei Schaltflächen:

- **„Öffentliche Datei (status.json)"** — erzeugt die öffentliche, gefilterte Datei
  `status.json` (geht nach außen) und zugleich eine identische `status-public-local.json`
  für die interne VM.
- **„Interne Datei (status-intern.json)"** — erzeugt die vollständige interne Datei, die
  im eigenen Netz bleibt.

Die öffentliche Datei enthält garantiert **keine** internen Notizen, **keine** Namen und
**keine** NIS-2-Details — diese werden beim Export automatisch entfernt.

## B.7 Logbuch exportieren (Nachweis)

Im Bereich **Störungen** erzeugen zwei Schaltflächen ein Logbuch als CSV-Tabelle aller
Vorfälle und Updates mit Zeitstempeln — geeignet zum Öffnen in Excel und als Nachweis für
Audits oder zur Dokumentation eines Sicherheitsvorfalls:

- **„Internes Logbuch (CSV)"** — vollständig, inklusive der Spalten Verantwortlich und
  Bearbeiter sowie der NIS-2-Fristen.
- **„Öffentliches Logbuch (CSV)"** — ohne personenbezogene Spalten.

---

# Datenschutz

Der Statusmonitor ist auf Datensparsamkeit ausgelegt. Einige Hinweise für den
rechtssicheren Betrieb:

- **Keine Klarnamen in öffentlich sichtbaren Meldungstexten.** Beschreiben Sie den
  Sachverhalt („E-Mail-System gestört"), nicht einzelne Personen. Namen gehören
  ausschließlich in die internen Felder (Verantwortlich/Bearbeiter) oder interne Notizen.
- **Trennung nach Personenbezug.** Die öffentliche Seite enthält nur Systemzustände und
  keine personenbezogenen Daten — sie darf daher dauerhaft als Kommunikationsnachweis
  bestehen bleiben. Personenbezogene Angaben (Namen, interne Notizen, NIS-2-Details)
  liegen ausschließlich intern.
- **Aufbewahrungsfrist.** Im Editor lässt sich eine Aufbewahrungsfrist einstellen
  (Voreinstellung: 3 Jahre für erhebliche Vorfälle, anpassbar). Über die Funktion
  „Abgelaufene interne Vorfälle prüfen" werden abgelaufene Daten nach Bestätigung
  bereinigt: bei öffentlichen Vorfällen werden nur die personenbezogenen Angaben entfernt
  (der öffentliche Eintrag bleibt als Nachweis erhalten), rein interne Vorfälle werden
  vollständig gelöscht. Diese Frist betrifft nur die internen, personenbezogenen Daten.
- **Keine externen Aufrufe.** Schriften werden lokal ausgeliefert, es werden keine
  externen Dienste, CDNs oder Tracker eingebunden.

> Die konkrete Aufbewahrungsfrist und die Behandlung personenbezogener Vorfalldaten
> sollten Sie mit Ihrer/Ihrem Datenschutzbeauftragten abstimmen. Die genannten Werte sind
> Voreinstellungen, keine Rechtsberatung.

---

# NIS-2-Einordnung (Kurzüberblick)

Der Statusmonitor unterstützt die Kommunikations- und Nachweispflichten rund um
Sicherheitsvorfälle:

- **Getrennte interne/externe Kommunikation** — entspricht der Anforderung an definierte
  Kommunikationswege.
- **Meldefristen-Übersicht** — die 24-Stunden-, 72-Stunden- und Ein-Monats-Frist werden
  intern mit Countdown sichtbar gemacht, damit keine Frist übersehen wird.
- **Lückenloses Logbuch** — jede Phase eines Vorfalls wird mit Zeitstempel und Bearbeiter
  dokumentiert und ist als CSV exportierbar — verwertbar als Nachweis im Audit.

> Der Statusmonitor ist ein Hilfsmittel zur Kommunikation und Dokumentation. Er ersetzt
> nicht die eigentliche Meldung an die zuständige Behörde und keinen
> Incident-Response-Prozess. Die Einbettung in Ihren Prozess unterstützen wir auf Anfrage.

---

© 2026 integrisec — Steven Mai. Fragen zur Einrichtung: status@integrisec.de
