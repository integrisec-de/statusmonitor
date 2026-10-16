# Schriften in diesem Verzeichnis

## Outfit

- **Copyright:** Copyright 2021 The Outfit Project Authors
- **Lizenz:** SIL Open Font License, Version 1.1 (vollständiger Text: [OFL.txt](OFL.txt))
- **Reserved Font Name:** keiner. Outfit wird ohne Reserved Font Name veröffentlicht,
  Änderungen dürfen den Namen daher behalten.

### Herkunft

Ursprünglich von Google Fonts geladen und aus dem integrisec-Bestand in dieses
Projekt übernommen. Spezimen: <https://fonts.google.com/specimen/Outfit>

### Fassung

Es liegen **subsettete woff2-Fassungen** vor, keine vollständigen Originaldateien.
Der Zeichenvorrat ist auf den in dieser Anwendung benötigten Umfang reduziert, das
woff2-Format ist Brotli-komprimiert. Damit sind es im Sinne der OFL modifizierte
Fassungen der Originaldateien - zulässig, da Outfit keinen Reserved Font Name führt.

Da die Metadaten der Originaldateien beim Subsetting nicht erhalten geblieben sind,
lässt sich die genaue Ausgangsversion aus den Dateien selbst nicht mehr auslesen.

### Vorhandene Schnitte

| Datei | Schnitt | Stil | Größe |
|---|---|---|---|
| `outfit-400.woff2` | 400 (Regular) | normal | 17.536 Bytes |
| `outfit-500.woff2` | 500 (Medium) | normal | 16.740 Bytes |
| `outfit-600.woff2` | 600 (SemiBold) | normal | 17.704 Bytes |
| `outfit-700.woff2` | 700 (Bold) | normal | 17.612 Bytes |
| `outfit-800.woff2` | 800 (ExtraBold) | normal | 17.620 Bytes |

Eingebunden per `@font-face` in `index.html` und `admin.html` (sowie `demo/index.html`,
das ebenfalls auf `/assets/fonts/` verweist).

### Weitergabe

Die OFL verlangt, dass Copyright-Hinweis und Lizenztext jeder weitergegebenen Kopie
der Schriften beiliegen. `deploy/paketieren.sh` kopiert `OFL.txt` und `FONTS.md`
deshalb zusätzlich nach `licenses/fonts/` in beide Kundenpakete.
