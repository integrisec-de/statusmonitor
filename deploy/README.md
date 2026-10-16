# Interne Auslieferung mit Caddy (Kurzfassung)

Die **interne** Seite des Statusmonitors (intern-Ansicht + Editor) ist rein statisch
und wird im internen Netz mit **Caddy** ausgeliefert – einer einzelnen Binary, ohne
Docker und ohne Datenbank. HTTPS kommt automatisch und **im Browser grün** über
Let's Encrypt (DNS-Challenge).

> **Vollständige Schritt-für-Schritt-Anleitung: [`ANLEITUNG.md`](ANLEITUNG.md).**
> Funktionsumfang des Produkts: [`../FEATURES.md`](../FEATURES.md).

## In Kürze

1. **Paket bauen:** `pwsh deploy/paketieren.ps1` bzw. `bash deploy/paketieren.sh`
   → erzeugt **zwei** Bundles: `statusmonitor-intern/` (interne Seite + Editor) und
   `statusmonitor-public/` (öffentliche Seite + Badge, inhaltlich identisch zur
   Cloudflare-Auslieferung – nur nötig, wenn die öffentliche Seite **nicht** über
   Cloudflare, sondern selbst im DMZ läuft; Details in `ANLEITUNG.md`, Abschnitt 16).
   Die folgenden Schritte beziehen sich auf das interne Bundle.
2. **Caddy mit DNS-Plugin** besorgen (Download-Seite mit angehaktem Provider-Plugin
   oder `xcaddy build --with github.com/caddy-dns/<provider>`) und ins Paket legen.
3. **Anpassen:** im `Caddyfile` Hostname + `tls { dns <provider> }` + Editor-Hash
   (`caddy hash-password`); DNS-Token in `dns.env` (`chmod 600`).
4. **Starten:** Paket nach `/opt/statusmonitor` (Linux) bzw. `C:\statusmonitor`
   (Windows), als Dienst registrieren (`statusmonitor.service` / NSSM).

Aufruf: `https://<FQDN>/` = intern-Ansicht, `/admin.html` = Editor (Login).

**Daten aktualisieren:** im Editor exportieren → `status-intern.json` +
`status-public-local.json` ins `site/`-Verzeichnis kopieren. Fertig.

Kein FQDN/Internet am Server? Siehe Alternativen (interne CA / nur HTTP) in
[`ANLEITUNG.md`](ANLEITUNG.md), Abschnitt 10.
