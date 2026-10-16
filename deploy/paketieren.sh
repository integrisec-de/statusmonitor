#!/usr/bin/env bash
# Schnürt das interne Auslieferungs-Paket "statusmonitor-intern" aus den App-Dateien.
# Aufruf:  bash deploy/paketieren.sh
# Ergebnis: deploy/build/statusmonitor-intern/  (App + Konfig, ohne Caddy-Binary)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(dirname "$here")"
out="$here/build/statusmonitor-intern"
site="$out/site"

rm -rf "$out"
mkdir -p "$site"

# index.html -> site/ mit data-ansicht="intern" als Default
sed 's#<html lang="de" data-theme="light">#<html lang="de" data-theme="light" data-ansicht="intern">#' \
	"$repo/index.html" > "$site/index.html"

# übrige App-Dateien -> site/
cp "$repo/admin.html" "$site/"
cp -r "$repo/assets" "$site/"
cp "$repo/status-intern.json" "$repo/status-public-local.json" "$site/"

# Konfig + Doku -> Paket-Wurzel
cp "$here/Caddyfile" "$here/statusmonitor.service" "$here/dns.env.example" \
   "$here/README.md" "$here/ANLEITUNG.md" "$out/"

# ---- Öffentliches Bundle (DMZ / Selbsthosting der öffentlichen Seite, identisch zur Cloud) ----
outP="$here/build/statusmonitor-public"
siteP="$outP/site"
rm -rf "$outP"
mkdir -p "$siteP"
# Inhalt identisch zur Cloudflare-Auslieferung: index.html (public-Default), status.json, badge.js, assets/
cp "$repo/index.html" "$repo/status.json" "$repo/badge.js" "$siteP/"
cp -r "$repo/assets" "$siteP/"
cp "$here/Caddyfile.public" "$outP/Caddyfile"
cp "$here/statusmonitor-public.service" "$here/README.md" "$here/ANLEITUNG.md" "$outP/"

# ---- Lizenzen mitgelieferter Fremdkomponenten ----
# Bei Weitergabe verpflichtend: Caddy steht unter Apache-2.0 und verlangt LICENSE
# und NOTICE im Paket. Die Outfit-Schriften unter site/assets/fonts/ stehen unter
# der SIL Open Font License 1.1, die ebenfalls mitgeliefert werden muss.
# Caddy-Dateien einmalig unter deploy/lizenzen/caddy/ ablegen; die Schrift-Lizenz
# liegt im Repo bereits bei den Fonts. Beides landet in jedem gebauten Paket.
lizenzquelle="$here/lizenzen"
lizenz_fehlt=0

lizenz_beilegen() {
	komponente="$1"
	datei="$2"
	quelle="$lizenzquelle/$komponente/$datei"
	if [ -f "$quelle" ]; then
		for ziel in "$out" "$outP"; do
			mkdir -p "$ziel/licenses/$komponente"
			cp "$quelle" "$ziel/licenses/$komponente/$datei"
		done
		echo "  ok:    licenses/$komponente/$datei"
	else
		echo "  FEHLT: deploy/lizenzen/$komponente/$datei"
		lizenz_fehlt=1
	fi
}

echo "Lizenzdateien:"

# Eigene Lizenz: Apache-2.0 verlangt bei jeder Weitergabe eine Kopie der Lizenz
# (Abschnitt 4a) und die Weitergabe der NOTICE-Inhalte (Abschnitt 4d). Das Paket
# ist Weitergabe, daher beides in die Paketwurzel - licenses/ bleibt den
# Fremdkomponenten vorbehalten.
for eigen in LICENSE NOTICE; do
	quelle="$repo/$eigen"
	if [ -f "$quelle" ]; then
		for ziel in "$out" "$outP"; do cp "$quelle" "$ziel/$eigen"; done
		echo "  ok:    $eigen"
	else
		echo "  FEHLT: $eigen"
		lizenz_fehlt=1
	fi
done
# Caddy liefert selbst KEIN NOTICE aus (nur LICENSE). Apache-2.0 Abschnitt 4(d)
# verlangt die Weitergabe eines NOTICE nur dann, wenn das Werk eines enthaelt.
lizenz_beilegen caddy LICENSE

# Schriften: OFL.txt und FONTS.md liegen im Repo direkt bei den Fonts und wandern
# ueber "cp -r assets" ohnehin nach site/assets/fonts/. Zusaetzlich werden sie nach
# licenses/fonts/ gespiegelt, damit alle Fremdlizenzen an einer Stelle liegen.
for schriftdatei in OFL.txt FONTS.md; do
	quelle="$repo/assets/fonts/$schriftdatei"
	if [ -f "$quelle" ]; then
		for ziel in "$out" "$outP"; do
			mkdir -p "$ziel/licenses/fonts"
			cp "$quelle" "$ziel/licenses/fonts/$schriftdatei"
		done
		echo "  ok:    licenses/fonts/$schriftdatei"
	else
		echo "  FEHLT: assets/fonts/$schriftdatei"
		lizenz_fehlt=1
	fi
done

# ---- Caddy-Binary und Bestandsnachweis ----
# Die Binary liegt nicht im Repo (deploy/.gitignore). Wird sie unter deploy/caddy
# bzw. deploy/caddy.exe bereitgelegt, wandert sie in beide Pakete, und Version,
# Groesse und Pruefsumme landen in VERSIONEN.txt. Damit laesst sich spaeter
# beantworten, welcher Caddy-Stand bei welchem Kunden liegt - etwa wenn eine
# Schwachstelle gemeldet wird.
caddy_quelle=""
for kandidat in "$here/caddy" "$here/caddy.exe"; do
	[ -f "$kandidat" ] && { caddy_quelle="$kandidat"; break; }
done

sm_version="$(git -C "$repo" describe --tags --always --dirty 2>/dev/null || echo unbekannt)"

for ziel in "$out" "$outP"; do
	{
		echo "Bestandteile dieses Pakets"
		echo "Erzeugt:       $(date -u '+%Y-%m-%d %H:%M UTC')"
		echo
		echo "Statusmonitor: $sm_version"
	} > "$ziel/VERSIONEN.txt"
done

if [ -n "$caddy_quelle" ]; then
	caddy_datei="$(basename "$caddy_quelle")"
	caddy_hash="$(sha256sum "$caddy_quelle" | cut -d' ' -f1)"
	caddy_groesse="$(wc -c < "$caddy_quelle" | tr -d ' ')"
	# Die Version laesst sich nur auslesen, wenn die Binary zur Bauplattform passt
	# (haeufig wird unter Windows fuer einen Linux-Server gepackt).
	caddy_version="$("$caddy_quelle" version 2>/dev/null | head -1)"
	[ -n "$caddy_version" ] || caddy_version="nicht auslesbar (Binary fuer andere Plattform)"
	for ziel in "$out" "$outP"; do
		cp "$caddy_quelle" "$ziel/$caddy_datei"
		{
			echo "Caddy:         $caddy_version"
			echo "  Datei        $caddy_datei ($caddy_groesse Bytes)"
			echo "  SHA-256      $caddy_hash"
		} >> "$ziel/VERSIONEN.txt"
	done
	echo "Caddy-Binary:  $caddy_datei uebernommen - $caddy_version"
	caddy_fehlt=0
else
	for ziel in "$out" "$outP"; do
		echo "Caddy:         FEHLT - Binary einlegen und hier nachtragen" >> "$ziel/VERSIONEN.txt"
	done
	echo "Caddy-Binary:  nicht gefunden unter deploy/caddy bzw. deploy/caddy.exe"
	caddy_fehlt=1
fi

echo "Pakete erstellt:"
echo "  intern:      $out"
echo "  oeffentlich: $outP"
echo "Noch erledigen:"
if [ "$caddy_fehlt" -ne 0 ]; then
	echo "  - Caddy-Binary nach deploy/caddy bzw. deploy/caddy.exe legen und neu bauen"
	echo "    -> https://caddyserver.com/download (intern mit DNS-Plugin)"
fi
echo "  - Internes Caddyfile: Editor-Login setzen (caddy hash-password)"
echo "  - Hostnamen in beiden Caddyfiles anpassen"
if [ "$lizenz_fehlt" -ne 0 ]; then
	echo "  - FEHLENDE Lizenzdateien nachlegen (siehe Liste oben):"
	echo "      Caddy:  LICENSE aus https://github.com/caddyserver/caddy"
	echo "    Ohne diese Dateien darf das Paket nicht weitergegeben werden."
fi
