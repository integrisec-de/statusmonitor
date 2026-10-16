# Statusmonitor – interne Installation (ausführliche Anleitung)

Diese Anleitung beschreibt die vollständige Einrichtung der **internen** Seite des
Statusmonitors mit **Caddy** – inklusive automatischem, im Browser **grünem**
HTTPS-Zertifikat. Sie richtet sich an die IT/Administration und wird einmalig
durchgeführt. Die Kurzfassung steht in [`README.md`](README.md).

**Grundsatz:** rein statisch – kein Docker, keine Datenbank, keine externen
Requests zur Laufzeit (außer der Zertifikats­erneuerung). Daten verlassen das
interne Netz nicht.

---

## Inhalt
1. [Überblick & Architektur](#1-überblick--architektur)
2. [Voraussetzungen](#2-voraussetzungen)
3. [Schritt 1 – Paket erstellen](#3-schritt-1--paket-erstellen)
4. [Schritt 2 – Caddy mit DNS-Plugin besorgen](#4-schritt-2--caddy-mit-dns-plugin-besorgen)
5. [Schritt 3 – Hostname & internes DNS](#5-schritt-3--hostname--internes-dns)
6. [Schritt 4 – DNS-API-Token hinterlegen](#6-schritt-4--dns-api-token-hinterlegen)
7. [Schritt 5 – Editor-Login setzen](#7-schritt-5--editor-login-setzen)
8. [Schritt 6 – Caddyfile anpassen](#8-schritt-6--caddyfile-anpassen)
9. [Schritt 7 – Als Dienst installieren](#9-schritt-7--als-dienst-installieren)
10. [Wie das HTTPS-Zertifikat funktioniert](#10-wie-das-https-zertifikat-funktioniert)
11. [Daten pflegen & aktualisieren](#11-daten-pflegen--aktualisieren)
12. [Zugriffsschutz](#12-zugriffsschutz)
13. [Betrieb & Wartung](#13-betrieb--wartung)
14. [Fehlerbehebung](#14-fehlerbehebung)
15. [Sicherheit & ISO-Bezug](#15-sicherheit--iso-bezug)
16. [Öffentliche Seite on-prem (DMZ)](#16-öffentliche-seite-on-prem-dmz)

---

## 1. Überblick & Architektur

Der Statusmonitor besteht aus zwei getrennten Welten:

- **Öffentlich** – liegt außerhalb des Netzes (z. B. Cloudflare Pages), zeigt nur
  freigegebene, personenbezugsfreie Informationen.
- **Intern** – diese Installation. Zeigt die Vollansicht (alle Komponenten,
  NIS-2-Countdown, interne Notizen, Verantwortlich/Bearbeiter) und enthält den
  Editor `admin.html`. Bleibt im internen Netz.

Caddy liefert die statischen Dateien aus dem Verzeichnis `site/` aus und kümmert
sich um HTTPS und den Editor-Login.

```
/opt/statusmonitor/            (bzw. C:\statusmonitor\)
├─ caddy                       Caddy-Binary (mit DNS-Plugin)
├─ Caddyfile                   Server-Konfiguration
├─ dns.env                     DNS-API-Token (Rechte 600, nicht im Repo)
├─ statusmonitor.service       systemd-Unit (Linux)
├─ VERSIONEN.txt               welche Staende in diesem Paket stecken
├─ LICENSE / NOTICE            Lizenz des Statusmonitors (Apache 2.0)
├─ licenses/                   Lizenzen der Fremdkomponenten (Caddy, Schriften)
└─ site/
   ├─ index.html               intern-Ansicht als Default
   ├─ admin.html               Editor (hinter Login)
   ├─ assets/                  Schriften
   ├─ status-intern.json       Lagedaten (vom Editor gepflegt)
   └─ status-public-local.json lokale Kopie der öffentlichen Daten
```

---

## 2. Voraussetzungen

- Ein interner Linux- oder Windows-Server (eine kleine VM genügt).
- **Ausgehender** Internetzugang vom Server zu Let's Encrypt und zur DNS-Provider-API
  (für Zertifikat und Erneuerung). **Kein** eingehender Zugang aus dem Internet nötig.
- Eine echte Domain, deren DNS bei einem von Caddy unterstützten Provider liegt
  (Cloudflare, Hetzner, Route53, Azure DNS, DigitalOcean … – Liste:
  <https://github.com/caddy-dns>), und ein API-Token dafür.
- Kein Docker, keine Datenbank, kein Webserver-Vorbau erforderlich.

> **Kein Internet am Server möglich?** Dann statt Let's Encrypt ein internes
> Zertifikat verwenden (siehe [Abschnitt 10](#10-wie-das-https-zertifikat-funktioniert)).

---

## 3. Schritt 1 – Paket erstellen

Auf einem Rechner mit dem Repo:

```
pwsh deploy/paketieren.ps1      # Windows
bash deploy/paketieren.sh       # Linux/macOS
```

Ergebnis: `deploy/build/statusmonitor-intern/` mit `site/` (intern-Ansicht als
Default), `Caddyfile`, `statusmonitor.service`, `dns.env.example`, `README.md`
und `ANLEITUNG.md`.

---

## 4. Schritt 2 – Caddy mit DNS-Plugin besorgen

Die **Standard-Caddy-Binary enthält keine DNS-Plugins** – für die DNS-Challenge
braucht es eine Binary, in die das Plugin des jeweiligen Providers eingebaut ist.
Zwei Wege:

**A) Offizielle Download-Seite (am einfachsten):**
<https://caddyserver.com/download> öffnen, Plattform wählen, unter „packages" das
DNS-Plugin des Providers anhaken (z. B. `dns.providers.cloudflare`), Binary
herunterladen. Das ist weiterhin **eine** Datei.

**B) Selbst bauen mit `xcaddy`:**
```
xcaddy build --with github.com/caddy-dns/cloudflare
# Provider tauschen: github.com/caddy-dns/<provider>
```

Die fertige Binary als `caddy` (Linux) bzw. `caddy.exe` (Windows) nach `deploy/`
legen – **vor** dem Paketieren. `paketieren.sh` bzw. `.ps1` nimmt sie dann in beide
Pakete auf und trägt Version, Größe und SHA-256 in `VERSIONEN.txt` ein. Prüfen,
ob das Plugin drin ist:
```
caddy list-modules | grep dns.providers
```

> **Getestet mit Caddy 2.11.x.** Neuere Fassungen laufen erfahrungsgemäß ohne
> Änderung, sind aber nicht geprüft. Welche Binary tatsächlich ausgeliefert wurde,
> steht in der `VERSIONEN.txt` des jeweiligen Pakets – wichtig, wenn zu Caddy eine
> Schwachstelle gemeldet wird und Sie wissen müssen, wer welchen Stand hat.

### Provider-Kurzreferenz

Die Direktive nach `dns` im Caddyfile entspricht dem Plugin-Namen
(`github.com/caddy-dns/<name>`). Bei **Ein-Token-Anbietern** kommt das Token wie in
dieser Anleitung aus `DNS_API_TOKEN` (Datei `dns.env`):

| Anbieter      | `dns …` / Plugin | Token anlegen – Berechtigung |
|---------------|------------------|------------------------------|
| Cloudflare    | `cloudflare`     | API-Token: *Zone → DNS → Edit* (+ *Zone → Read*) für die Zone |
| Hetzner DNS   | `hetzner`        | DNS-Console-API-Token (Lesen + Schreiben) |
| IONOS         | `ionos`          | API-Key im Format `prefix.secret` mit DNS-Schreibrecht |
| DigitalOcean  | `digitalocean`   | Personal Access Token mit Schreibrecht (*write*) |
| deSEC         | `desec`          | Token mit Schreibrecht auf die Domain |

**Mehrfeld-Anbieter** (kein einzelnes Token, sondern mehrere Zugangsdaten – den
`tls { dns … }`-Block bzw. die Umgebungsvariablen exakt nach Plugin-Doku setzen):

| Anbieter         | `dns …` / Plugin  | Zugang |
|------------------|-------------------|--------|
| AWS Route 53     | `route53`         | IAM-Schlüssel (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`); Rechte `route53:ChangeResourceRecordSets` + `ListHostedZonesByName` |
| Azure DNS        | `azure`           | Service Principal: Tenant-ID, Client-ID, Client-Secret, Subscription-ID |
| Google Cloud DNS | `googleclouddns`  | Service-Account-JSON (`GOOGLE_APPLICATION_CREDENTIALS`) |
| Netcup           | `netcup`          | Kundennummer + API-Key + API-Passwort |

Faustregel: Token/Zugang **immer so eng wie möglich** – nur das Bearbeiten der
DNS-Einträge (TXT) genau der einen Zone.

### Alle unterstützten Anbieter

Für **jeden** Anbieter gilt dasselbe Muster: Plugin = `github.com/caddy-dns/<name>`,
Caddyfile-Direktive = `dns <name>`, Zugangsdaten gemäß der README des jeweiligen
Plugins (`https://github.com/caddy-dns/<name>`). Findet sich euer Anbieter hier,
ist er unterstützt – einfach den passenden `<name>` verwenden.

Stand der Liste: **93 Anbieter** (Quelle: github.com/caddy-dns – wächst mit der Zeit):

```
acmedns        acmeproxy      alidns         all-inkl       arvancloud
autodns        azure          bluecat        bunny          civo
cloudflare     cloudns        conoha         ddnss          desec
digitalocean   dinahosting    directadmin    dnsexit        dnsimple
dnsmadeeasy    dnspod         dode           domainnameshop dreamhost
duckdns        dynu           dynv6          easydns        edgeone
exoscale       gandi          gcore          glesys         godaddy
googleclouddns he             hetzner        hexonet        hosttech
httpnet        huaweicloud    infomaniak     inwx           ionos
katapult       leaseweb       linode         loopia         luadns
mailinabox     metaname       mijnhost       mythicbeasts   namecheap
namedotcom     namesilo       nanelo         neoserv        netcup
netlify        netnod         nfsn           nicrudns       njalla
openstack-designate           oraclecloud    ovh            porkbun
powerdns       pph            regery         regfish        rfc2136
route53        scaleway       selectel       servercow      simplydotcom
spaceship      tecnocratica   tencentcloud   thelittlehost  timeweb
totaluptime    transip        unifi          vercel         volcengine
vultr          websupport     wedos          westcn
```

**Orientierung:**
- DACH-Region u. a.: `all-inkl`, `dode` (do.de), `httpnet` (http.net), `inwx`,
  `netcup`, `regfish`, `servercow`, `hosttech` (CH), `infomaniak` (CH).
- Kürzel: `he` = Hurricane Electric, `alidns` = Alibaba Cloud, `dnspod`/`tencentcloud` =
  Tencent, `nfsn` = NearlyFreeSpeech, `rfc2136` = generischer DNS-Update-Standard
  (z. B. BIND), `googleclouddns` = Google Cloud DNS, `oraclecloud` = Oracle Cloud.
- Hat euer Anbieter **keinen** eigenen Eintrag, aber unterstützt dynamische
  DNS-Updates (RFC 2136), funktioniert `rfc2136` als universeller Fallback.

---

## 5. Schritt 3 – Hostname & internes DNS

Wählen Sie einen echten FQDN, z. B. `status.intern.ihre-domain.de`.

- Im **internen DNS** (oder per `hosts`-Datei) zeigt dieser Name auf die LAN-IP des
  Servers, z. B. `10.0.0.5`. So erreichen die Clients die Seite intern.
- Im **öffentlichen DNS** der Domain ist **kein A-Record nötig** – die DNS-Challenge
  legt nur kurzzeitig einen TXT-Record `_acme-challenge.status...` an und entfernt
  ihn wieder. Der Server muss aus dem Internet nicht erreichbar sein.

---

## 6. Schritt 4 – DNS-API-Token hinterlegen

1. Beim DNS-Provider ein API-Token erstellen, **eng begrenzt** auf das Bearbeiten der
   DNS-Einträge (TXT) genau dieser Zone.
2. Auf dem Server `dns.env` anlegen (aus `dns.env.example`):
   ```
   cp dns.env.example dns.env
   chmod 600 dns.env
   ```
   Inhalt:
   ```
   DNS_API_TOKEN=das_token
   ```
   Die systemd-Unit lädt diese Datei automatisch (`EnvironmentFile`).

> Das Token gibt nur Schreibrechte auf TXT-Records – mehr braucht die Challenge nicht.

---

## 7. Schritt 5 – Editor-Login setzen

Der Editor `admin.html` ist mit Basic-Auth geschützt. Passwort-Hash erzeugen:

```
caddy hash-password
# Passwort eingeben, der ausgegebene $2a$… -Hash kommt ins Caddyfile (Benutzer: it)
```

---

## 8. Schritt 6 – Caddyfile anpassen

Im `Caddyfile`:
- `status.intern.example.de` → Ihren FQDN.
- `email it@example.de` → Kontaktadresse für Let's Encrypt.
- in `tls { dns cloudflare … }` den **Provider** auf Ihren DNS-Anbieter setzen
  (muss zum eingebauten Plugin aus Schritt 2 passen).
- im `basic_auth`-Block den Hash aus Schritt 5 eintragen.

Konfiguration prüfen:
```
caddy validate --config Caddyfile
```

---

## 9. Schritt 7 – Als Dienst installieren

**Linux (systemd):**
```
sudo useradd --system --no-create-home --shell /usr/sbin/nologin statusmonitor
sudo mkdir -p /opt/statusmonitor
sudo cp -r statusmonitor-intern/* /opt/statusmonitor/
sudo chown -R statusmonitor:statusmonitor /opt/statusmonitor
sudo chmod 600 /opt/statusmonitor/dns.env
sudo cp /opt/statusmonitor/statusmonitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now statusmonitor
sudo systemctl status statusmonitor
```

**Windows (Dienst, z. B. mit NSSM):**
```
nssm install Statusmonitor C:\statusmonitor\caddy.exe run --config C:\statusmonitor\Caddyfile
nssm set Statusmonitor AppDirectory C:\statusmonitor
nssm set Statusmonitor AppEnvironmentExtra DNS_API_TOKEN=das_token
nssm start Statusmonitor
```

Aufruf danach:
- Statusseite (intern): `https://status.intern.ihre-domain.de/`
- Editor: `https://status.intern.ihre-domain.de/admin.html` (Login)

---

## 10. Wie das HTTPS-Zertifikat funktioniert

- Caddy fordert das Zertifikat per **DNS-Challenge** bei Let's Encrypt an: es legt
  über die DNS-API kurz einen TXT-Record an, Let's Encrypt prüft ihn, Caddy entfernt
  ihn wieder. Ergebnis: ein **öffentlich vertrautes** Zertifikat – im Browser **grün**,
  auf jedem Gerät, ohne Root-Verteilung.
- **Erneuerung** läuft automatisch (Caddy erneuert ~30 Tage vor Ablauf). Dafür muss der
  Server dauerhaft ausgehend Let's Encrypt und die DNS-API erreichen.
- **Firewall (ausgehend):** `acme-v02.api.letsencrypt.org` (443) und die API des
  DNS-Providers (443). Eingehend nur intern (443/80 aus dem LAN).

**Alternativen ohne Let's Encrypt:**
- **Interne PKI vorhanden (AD CS):** Zertifikat dort für den FQDN ausstellen,
  `tls /pfad/cert.pem /pfad/key.pem` ins Caddyfile – grün auf verwalteten Clients,
  ganz ohne Internet.
- **Caddys interne CA:** `tls internal` – automatisch und offline, aber die Caddy-Root
  muss in die Trust-Stores der Clients verteilt werden (sonst Warnung).
- **Kein Zertifikat (Fallback):** HTTP-Block im Caddyfile (nur in vertrauenswürdigem,
  abgeschottetem Segment).

---

## 11. Daten pflegen & aktualisieren

1. Editor `admin.html` öffnen (Login), Komponenten/Störungen/Wartungen pflegen.
2. Exportieren – es entstehen **`status-intern.json`** (vollständig) und
   **`status-public-local.json`** (öffentliche Kopie).
3. Beide Dateien in das `site/`-Verzeichnis kopieren (überschreiben). Die Seite zeigt
   den neuen Stand **sofort** – kein Neustart nötig.

Die öffentliche `status.json` für die Außenseite wird separat exportiert und auf das
öffentliche Hosting (z. B. Cloudflare Pages) geladen.

---

## 12. Zugriffsschutz

- **Netz (primär):** Den Dienst per Firewall auf das interne Subnetz beschränken.
- **Editor:** zusätzlich Basic-Auth (im Caddyfile gesetzt). Optional die gesamte Seite
  schützen, indem der `basic_auth`-Block ohne den `@editor`-Matcher gesetzt wird.
- **Transport:** HTTPS (Let's Encrypt/intern). „Verschlüsseln, wo es geht."

---

## 13. Betrieb & Wartung

| Aufgabe | Befehl (Linux) |
|---|---|
| Status | `systemctl status statusmonitor` |
| Logs (Dienst) | `journalctl -u statusmonitor -f` |
| Zugriffs-Log | `tail -f /opt/statusmonitor/caddy-zugriff.log` |
| Konfig neu laden | `systemctl reload statusmonitor` |
| Konfig prüfen | `caddy validate --config Caddyfile` |

App-Update: neues Paket bauen, `site/` ersetzen (Daten-JSON ggf. behalten), Dienst neu
laden. Caddy-Update: neue Binary (mit DNS-Plugin) austauschen, Dienst neu starten.

---

## 14. Fehlerbehebung

- **„unknown directive: dns" / Plugin fehlt** → die Binary enthält das DNS-Plugin nicht.
  Schritt 2 (Download mit Plugin oder `xcaddy`) wiederholen; `caddy list-modules | grep dns`.
- **Zertifikat kommt nicht** → ausgehende Firewall zu Let's Encrypt/DNS-API prüfen;
  Token-Rechte (TXT in der richtigen Zone) prüfen; `journalctl -u statusmonitor` lesen.
- **Port 443 nicht bindbar (Linux, non-root)** → `AmbientCapabilities=CAP_NET_BIND_SERVICE`
  in der Unit muss gesetzt sein (ist es); ggf. `daemon-reload` + Neustart.
- **Browser-Warnung trotz HTTPS** → es wurde `tls internal` genutzt, aber die Root-CA
  ist nicht verteilt. Entweder verteilen oder auf Let's Encrypt/DNS-01 umstellen.
- **Editor lädt, aber „Daten nicht verfügbar"** → `status-intern.json` /
  `status-public-local.json` fehlen oder sind ungültig (JSON prüfen).

---

## 15. Sicherheit & ISO-Bezug

- **Getrennte interne/externe Kommunikation** (NIS-2 § 30, ISO 27001 A.5.14): die
  Außenseite funktioniert unabhängig vom internen Netz, interne Daten bleiben intern.
- **Datensparsamkeit** (Art. 5/25 DSGVO): personenbezogene Felder nur intern; die
  öffentliche Datei enthält keine Namen/internen Notizen.
- **Verschlüsselung im Transit** (HTTPS überall, „wo es geht").
- **Minimale Angriffsfläche**: rein statisch, kein aktiver Server-Code, keine Datenbank,
  keine externen Requests außer der Zertifikatsverwaltung.
- **Nachvollziehbarkeit**: Zugriffs-Log (Caddy) und das Vorfall-Logbuch (CSV-Export aus
  dem Editor) als Nachweis.

---

## 16. Öffentliche Seite on-prem (DMZ)

Standard für die öffentliche Seite ist **Cloudflare Pages** (HANDBUCH A.2). Wer die
öffentliche Seite **nicht** in der Cloud, sondern selbst betreiben will (z. B. im DMZ),
nutzt das zweite Bundle, das `paketieren.ps1`/`.sh` miterzeugt:
**`deploy/build/statusmonitor-public/`**.

Inhalt von `site/` ist **identisch zur Cloudflare-Auslieferung** – inklusive Status-Badge:
`index.html` (public-Default), `status.json`, `badge.js`, `assets/`. Damit sieht die
öffentliche Seite und der einbettbare Badge on-prem genauso aus wie in der Cloud.

Unterschiede zum internen Bundle:
- **Kein Editor, kein Login** – die Seite ist öffentlich.
- **Caddyfile** = `Caddyfile.public`: Ist der Server direkt aus dem Internet auf 80/443
  erreichbar, holt Caddy das Zertifikat automatisch per **HTTP-Challenge** – **kein
  DNS-Plugin und kein Token nötig** (Standard-Caddy-Binary genügt). Ist er nicht
  öffentlich erreichbar, die DNS-Challenge wie beim internen Bundle verwenden.
- **Dienst:** `statusmonitor-public.service` (Pfad `/opt/statusmonitor-public`).

**Installieren (Linux):**
```
sudo mkdir -p /opt/statusmonitor-public
sudo cp -r statusmonitor-public/* /opt/statusmonitor-public/
sudo chown -R statusmonitor:statusmonitor /opt/statusmonitor-public
# Hostname im Caddyfile anpassen, Caddy-Binary dazulegen
sudo cp /opt/statusmonitor-public/statusmonitor-public.service /etc/systemd/system/
sudo systemctl enable --now statusmonitor-public
```

**Daten aktualisieren:** die im Editor exportierte öffentliche `status.json` in das
`site/`-Verzeichnis kopieren (überschreiben) – wie bei Cloudflare, nur lokal.

> Hinweis: Damit die öffentliche Seite ihren Zweck erfüllt (erreichbar, wenn die interne
> Umgebung gestört ist), sollte das öffentliche Bundle **getrennt** von der internen
> Umgebung laufen – eigener Host/DMZ, nicht dieselbe Maschine wie der interne Dienst.
