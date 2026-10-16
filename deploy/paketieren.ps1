# Schnürt das interne Auslieferungs-Paket "statusmonitor-intern" aus den App-Dateien.
# Aufruf:  pwsh deploy/paketieren.ps1
# Ergebnis: deploy/build/statusmonitor-intern/  (App + Konfig, ohne Caddy-Binary)
$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$out  = Join-Path $PSScriptRoot "build\statusmonitor-intern"
$site = Join-Path $out "site"

if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Path $site -Force | Out-Null

# index.html -> site/ mit data-ansicht="intern" als Default
$index = Get-Content (Join-Path $repo "index.html") -Raw
$index = $index -replace '<html lang="de" data-theme="light">', '<html lang="de" data-theme="light" data-ansicht="intern">'
Set-Content -Path (Join-Path $site "index.html") -Value $index -Encoding utf8 -NoNewline

# übrige App-Dateien -> site/
Copy-Item (Join-Path $repo "admin.html") $site
Copy-Item (Join-Path $repo "assets") $site -Recurse
Copy-Item (Join-Path $repo "status-intern.json") $site
Copy-Item (Join-Path $repo "status-public-local.json") $site

# Konfig + Doku -> Paket-Wurzel
Copy-Item (Join-Path $PSScriptRoot "Caddyfile") $out
Copy-Item (Join-Path $PSScriptRoot "statusmonitor.service") $out
Copy-Item (Join-Path $PSScriptRoot "dns.env.example") $out
Copy-Item (Join-Path $PSScriptRoot "README.md") $out
Copy-Item (Join-Path $PSScriptRoot "ANLEITUNG.md") $out

# ---- Öffentliches Bundle (DMZ / Selbsthosting der öffentlichen Seite, identisch zur Cloud) ----
$outP  = Join-Path $PSScriptRoot "build\statusmonitor-public"
$siteP = Join-Path $outP "site"
if (Test-Path $outP) { Remove-Item $outP -Recurse -Force }
New-Item -ItemType Directory -Path $siteP -Force | Out-Null
# Inhalt identisch zur Cloudflare-Auslieferung: index.html (public-Default), status.json, badge.js, assets/
Copy-Item (Join-Path $repo "index.html") $siteP
Copy-Item (Join-Path $repo "status.json") $siteP
Copy-Item (Join-Path $repo "badge.js") $siteP
Copy-Item (Join-Path $repo "assets") $siteP -Recurse
Copy-Item (Join-Path $PSScriptRoot "Caddyfile.public") (Join-Path $outP "Caddyfile")
Copy-Item (Join-Path $PSScriptRoot "statusmonitor-public.service") $outP
Copy-Item (Join-Path $PSScriptRoot "README.md") $outP
Copy-Item (Join-Path $PSScriptRoot "ANLEITUNG.md") $outP

# ---- Lizenzen mitgelieferter Fremdkomponenten ----
# Bei Weitergabe verpflichtend: Caddy steht unter Apache-2.0 und verlangt LICENSE
# und NOTICE im Paket. Die Outfit-Schriften unter site/assets/fonts/ stehen unter
# der SIL Open Font License 1.1, die ebenfalls mitgeliefert werden muss.
# Caddy-Dateien einmalig unter deploy/lizenzen/caddy/ ablegen; die Schrift-Lizenz
# liegt im Repo bereits bei den Fonts. Beides landet in jedem gebauten Paket.
$lizenzquelle = Join-Path $PSScriptRoot "lizenzen"
$lizenzFehlt  = $false

function Copy-Lizenz {
    param([string]$Komponente, [string]$Datei)
    $quelle = Join-Path $lizenzquelle (Join-Path $Komponente $Datei)
    if (Test-Path $quelle) {
        foreach ($ziel in @($out, $outP)) {
            $zielOrdner = Join-Path $ziel (Join-Path "licenses" $Komponente)
            New-Item -ItemType Directory -Path $zielOrdner -Force | Out-Null
            Copy-Item $quelle $zielOrdner
        }
        Write-Output "  ok:    licenses/$Komponente/$Datei"
    } else {
        Write-Output "  FEHLT: deploy/lizenzen/$Komponente/$Datei"
        $script:lizenzFehlt = $true
    }
}

Write-Output "Lizenzdateien:"

# Eigene Lizenz: Apache-2.0 verlangt bei jeder Weitergabe eine Kopie der Lizenz
# (Abschnitt 4a) und die Weitergabe der NOTICE-Inhalte (Abschnitt 4d). Das Paket
# ist Weitergabe, daher beides in die Paketwurzel - licenses/ bleibt den
# Fremdkomponenten vorbehalten.
foreach ($eigen in @("LICENSE", "NOTICE")) {
    $quelle = Join-Path $repo $eigen
    if (Test-Path $quelle) {
        foreach ($ziel in @($out, $outP)) { Copy-Item $quelle (Join-Path $ziel $eigen) }
        Write-Output "  ok:    $eigen"
    } else {
        Write-Output "  FEHLT: $eigen"
        $lizenzFehlt = $true
    }
}
# Caddy liefert selbst KEIN NOTICE aus (nur LICENSE). Apache-2.0 Abschnitt 4(d)
# verlangt die Weitergabe eines NOTICE nur dann, wenn das Werk eines enthaelt.
Copy-Lizenz -Komponente "caddy"  -Datei "LICENSE"

# Schriften: OFL.txt und FONTS.md liegen im Repo direkt bei den Fonts und wandern
# ueber Copy-Item assets ohnehin nach site/assets/fonts/. Zusaetzlich werden sie nach
# licenses/fonts/ gespiegelt, damit alle Fremdlizenzen an einer Stelle liegen.
foreach ($schriftdatei in @("OFL.txt", "FONTS.md")) {
    $quelle = Join-Path $repo (Join-Path "assets" (Join-Path "fonts" $schriftdatei))
    if (Test-Path $quelle) {
        foreach ($ziel in @($out, $outP)) {
            $zielOrdner = Join-Path $ziel (Join-Path "licenses" "fonts")
            New-Item -ItemType Directory -Path $zielOrdner -Force | Out-Null
            Copy-Item $quelle $zielOrdner
        }
        Write-Output "  ok:    licenses/fonts/$schriftdatei"
    } else {
        Write-Output "  FEHLT: assets/fonts/$schriftdatei"
        $lizenzFehlt = $true
    }
}

# ---- Caddy-Binary und Bestandsnachweis ----
# Die Binary liegt nicht im Repo (deploy/.gitignore). Wird sie unter deploy/caddy
# bzw. deploy/caddy.exe bereitgelegt, wandert sie in beide Pakete, und Version,
# Groesse und Pruefsumme landen in VERSIONEN.txt. Damit laesst sich spaeter
# beantworten, welcher Caddy-Stand bei welchem Kunden liegt.
$caddyQuelle = $null
foreach ($kandidat in @((Join-Path $PSScriptRoot "caddy"), (Join-Path $PSScriptRoot "caddy.exe"))) {
    if (Test-Path $kandidat) { $caddyQuelle = $kandidat; break }
}

$smVersion = "unbekannt"
try {
    $beschreibung = & git -C $repo describe --tags --always --dirty 2>$null
    if ($beschreibung) { $smVersion = "$beschreibung".Trim() }
} catch { }

foreach ($ziel in @($out, $outP)) {
    Set-Content -Path (Join-Path $ziel "VERSIONEN.txt") -Encoding utf8 -Value @(
        "Bestandteile dieses Pakets",
        ("Erzeugt:       " + [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm") + " UTC"),
        "",
        "Statusmonitor: $smVersion"
    )
}

if ($caddyQuelle) {
    $caddyDatei   = Split-Path $caddyQuelle -Leaf
    $caddyHash    = (Get-FileHash $caddyQuelle -Algorithm SHA256).Hash.ToLower()
    $caddyGroesse = (Get-Item $caddyQuelle).Length
    # Die Version laesst sich nur auslesen, wenn die Binary zur Bauplattform passt
    # (haeufig wird unter Windows fuer einen Linux-Server gepackt).
    $caddyVersion = $null
    try { $caddyVersion = (& $caddyQuelle version 2>$null | Select-Object -First 1) } catch { }
    if (-not $caddyVersion) { $caddyVersion = "nicht auslesbar (Binary fuer andere Plattform)" }
    foreach ($ziel in @($out, $outP)) {
        Copy-Item $caddyQuelle (Join-Path $ziel $caddyDatei)
        Add-Content -Path (Join-Path $ziel "VERSIONEN.txt") -Encoding utf8 -Value @(
            "Caddy:         $caddyVersion",
            "  Datei        $caddyDatei ($caddyGroesse Bytes)",
            "  SHA-256      $caddyHash"
        )
    }
    Write-Output "Caddy-Binary:  $caddyDatei uebernommen - $caddyVersion"
    $caddyFehlt = $false
} else {
    foreach ($ziel in @($out, $outP)) {
        Add-Content -Path (Join-Path $ziel "VERSIONEN.txt") -Encoding utf8 -Value "Caddy:         FEHLT - Binary einlegen und hier nachtragen"
    }
    Write-Output "Caddy-Binary:  nicht gefunden unter deploy/caddy bzw. deploy/caddy.exe"
    $caddyFehlt = $true
}

Write-Output "Pakete erstellt:"
Write-Output "  intern:      $out"
Write-Output "  oeffentlich: $outP"
Write-Output "Noch erledigen:"
if ($caddyFehlt) {
    Write-Output "  - Caddy-Binary nach deploy/caddy bzw. deploy/caddy.exe legen und neu bauen"
    Write-Output "    -> https://caddyserver.com/download (intern mit DNS-Plugin)"
}
Write-Output "  - Internes Caddyfile: Editor-Login setzen (caddy hash-password)"
Write-Output "  - Hostnamen in beiden Caddyfiles anpassen"
if ($lizenzFehlt) {
    Write-Output "  - FEHLENDE Lizenzdateien nachlegen (siehe Liste oben):"
    Write-Output "      Caddy:  LICENSE aus https://github.com/caddyserver/caddy"
    Write-Output "    Ohne diese Dateien darf das Paket nicht weitergegeben werden."
}
