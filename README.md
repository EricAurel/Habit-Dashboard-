# Habit Dashboard

Ein Habit Tracker für den Mac, der als Widget direkt auf dem Schreibtisch liegt. Nach einer Stunde aktiver Zeit am Rechner erinnert er dich an eine kurze Bewegungspause.

## Funktionen

- **Desktop-Widget:** liegt hinter allen Fenstern auf dem Schreibtisch, ist auf allen Spaces sichtbar und lässt sich mit der Maus verschieben (die Position wird gespeichert).
- **Tägliche Gewohnheiten:** abhaken per Klick auf die Box.
- **Streaks 🔥:**
  - pro Gewohnheit;
  - Gesamt-Streak für Tage, an denen *alle* Gewohnheiten erledigt sind;
  - Rekord-Streak im Editor;
  - ein heute noch offener Tag bricht den Streak nicht.
- **Heatmap** der letzten 15 Wochen.
- **Bewegungspausen:**
  - Es zählt nur aktive Zeit, also Maus- oder Tastatureingaben.
  - Nach 5 Min. Inaktivität, im Ruhezustand oder bei gesperrtem Bildschirm beginnt der Zähler neu.
  - Nach 60 Min. erscheint ein Popup mit zufälligen Übungen. Du kannst *Erledigt*, *Später* oder *Überspringen* wählen.
  - Erledigte Pausen werden gezählt und haben einen eigenen Streak.
- **Übungen eintragen:**
  - Im Popup trägst du ein, wie viele Wiederholungen oder Sekunden du geschafft hast.
  - Ein Häkchen zeigt, ob du das Ziel erreicht hast.
  - Die Übungen sind intensiv, z. B. Burpees, Mountain Climbers und Jump Squats.
- **Ruhezeiten:**
  - Während Vollbild-Apps und Video-Calls (Mikrofon oder Kamera aktiv) wird eine fällige Pause aufgehoben.
  - Sie erscheint danach, sobald du wieder frei bist. Beides lässt sich abschalten.
- **Statistik-Fenster:**
  - Erfüllung pro Tag als Diagramm über 7, 30 oder 90 Tage;
  - Quote, Streak und Rekord pro Gewohnheit;
  - Summen pro Übung.
- **Meilensteine** (dezent):
  - Abzeichen 🥉 7, 🥈 30, 🥇 100 und 🏆 365 Tage neben der Gewohnheit;
  - ein leiser Sound, sobald ein Meilenstein erreicht wird.
- **Menüleisten-Symbol** (kein Dock-Symbol):
  - Pause jetzt starten;
  - Widget ein- und ausblenden;
  - Einstellungen öffnen.
- **Autostart** beim Anmelden (optional).

Die Daten liegen als JSON in `~/Library/Application Support/HabitDashboard/habits.json`.

## Voraussetzungen

- macOS 14 (Sonoma) oder neuer
- Xcode 15+ oder die Command Line Tools (`xcode-select --install`)

## Starten

```bash
git clone <repo-url> && cd Habit-Dashboard-

# Schnell ausprobieren (läuft, solange das Terminal offen ist):
swift run

# Als richtige App bauen und nach /Applications installieren:
./scripts/build-app.sh --install
```

Danach erscheint oben rechts in der Menüleiste ein 👍 und das Widget auf dem Schreibtisch. Für den Autostart öffnest du über das Menü **Gewohnheiten & Einstellungen …** und aktivierst *Beim Anmelden automatisch starten*. Das funktioniert nur mit der installierten `.app`.

In Xcode entwickeln: `open Package.swift`, dann das Schema *HabitDashboard* starten.

## Projektstruktur

```
Sources/HabitCore/        Plattformunabhängige Logik (getestet)
  Day.swift               Kalendertage ohne Uhrzeit
  Models.swift            Gewohnheiten, Einstellungen, Abhak-Daten
  Streaks.swift           Streak-Berechnung + Heatmap-Raster
  Stats.swift             Statistik + Meilensteine
  ActiveTimeTracker.swift Zählt aktive Zeit bis zur Bewegungspause
  Exercises.swift         Übungskatalog
  Persistence.swift       JSON-Speicherung
Sources/HabitDashboard/   macOS-App (SwiftUI + AppKit)
  HabitDashboardApp.swift App, Menüleiste, AppDelegate
  AppState.swift          Beobachtbarer Zustand
  ActivityMonitor.swift   Misst Eingabe-Inaktivität, Ruhezustand
  QuietTime.swift         Erkennt Vollbild, Mikrofon, Kamera
  Windows.swift           Desktop-Panel + Popup-Fenster
  Views/                  Widget, Übungs-Popup, Statistik, Editor
Tests/HabitCoreTests/     Unit-Tests
```

## Tests

```bash
swift test
```

Die GitHub Action (`.github/workflows/ci.yml`) baut und testet bei jedem Push auf macOS und stellt die fertige `.app` als Artefakt bereit.
