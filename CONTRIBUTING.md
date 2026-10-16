# Mitwirken

Danke für das Interesse. Ein paar Dinge vorab, die bei diesem Projekt anders sind als
üblich.

## Kein Build, keine Abhängigkeiten

Es gibt keinen Paketmanager, keinen Build-Schritt und keine Laufzeit-Abhängigkeiten.
HTML, CSS und JavaScript liegen in den Dateien, CSS und JS bewusst inline. Wer eine
Änderung machen will, öffnet die Datei und ändert sie.

Das ist Absicht: Die Seite soll in zehn Jahren noch funktionieren und sich ohne
Werkzeugkette prüfen lassen.

## Lokal testen

Die Seiten laden ihre Daten per `fetch`. Über `file://` schlägt das fehl, es braucht
einen lokalen Webserver:

```
python -m http.server 8080
```

Dann `http://localhost:8080/` für die öffentliche Ansicht, `?ansicht=intern` für die
interne und `admin.html` für den Editor.

## Konventionen

- **Sprache:** Oberfläche, Dokumentation und Kommentare auf Deutsch.
- **Zeilenenden:** LF.
- **Keine externen Requests.** Keine CDNs, keine Webfonts von außen, kein Tracking,
  keine Analytics. Das ist eine Kernzusage des Projekts, kein Stilwunsch.
- **Keine Abhängigkeiten.** Kein Framework, keine Bibliothek.
- **Demo-Daten bleiben erkennbar fiktiv** – Namen im Stil von „A. Muster",
  „M. Beispiel" oder „Service-Desk (Demo)", Organisationen im Stil von
  „Stadtwerke Musterstadt". Keine echten Personen, keine echten Kunden.

## Vor einem Pull Request

- JSON-Dateien müssen valide sein.
- `bash -n deploy/paketieren.sh` muss durchlaufen.
- Die öffentliche Ansicht darf keine internen Felder zeigen. Dafür zuständig sind
  `filterPublic()` in `index.html` und die Sicherheitsprüfung in `admin.html` – wer ein
  Feld hinzufügt, das nicht nach außen darf, muss es an beiden Stellen eintragen.
- Keine neuen externen Requests.

## Was gut passt und was nicht

Die öffentliche Ansicht ist **bewusst minimal**: „nur darstellen, wenn etwas nicht
geht". Vorschläge, die dort mehr Information unterbringen wollen, haben es schwer –
nicht weil sie schlecht wären, sondern weil sie dem Zweck widersprechen.

Gut passen: Korrekturen, Barrierefreiheit, Robustheit in älteren Browsern,
Präzisierungen an den NIS-2- und ISO-Bezügen, Verbesserungen an der Dokumentation.

## Sicherheitslücken

Nicht als Issue, sondern vertraulich – siehe [`SECURITY.md`](SECURITY.md).
