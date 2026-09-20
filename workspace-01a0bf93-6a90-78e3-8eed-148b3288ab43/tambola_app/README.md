# Tambola / Housie Board & Number Generator

A landscape-first mobile app (Flutter) that works as a **digital Housie board** for
Tambola: 1–90 grid, voice calling, auto-play, history, and a custom
**Delayed Call Queue** that lets the caller pre-select numbers two calls ahead.

| Layer | Where |
|---|---|
| Game rules / state | `lib/state/tambola_controller.dart` |
| UI | `lib/screens/`, `lib/widgets/` |
| Speech + platform services | `lib/services/` |
| Colours, sizing, theme | `lib/theme/app_theme.dart` |
| Tests | `test/` |

---

## 1. Run it

```bash
flutter pub get
flutter run                 # phones / tablets, landscape
flutter test                # 15 unit + widget tests
flutter build apk --release # or: flutter build ios --release
```

`main.dart` locks the app to landscape (the layout is responsive, so removing
`SystemChrome.setPreferredOrientations` also works in portrait).

---

## 2. Screen layout (landscape)

```
┌───────────────────────────────────────────────┬──────────────────────────┐
│                                               │  Voice English ⌄   🔊  ⇪ │
│      9 x 10 BOARD  (numbers 1 … 90)          ├──────────────────────────┤
│                                               │  Auto [Pro]   Speed 3s   │
│  uncalled = light green                       ├──────────────────────────┤
│  queued   = amber + "IN 2" / "NEXT"           │        Reset             │
│  called   = red                               ├──────────────────────────┤
│  latest   = red + thick black outline         │      ◯  CURRENT 54       │
│                                               ├──────────────────────────┤
│                                               │      Generate            │
│                                               ├──────────────────────────┤
│                                               │      History             │
└───────────────────────────────────────────────┴──────────────────────────┘
```

The board gets ~78 % of the width; the control column is clamped to
210–360 px so it stays usable from a 5" phone to a 13" tablet. Tile size is
computed from the available space (`NumberGrid`), so the grid never scrolls and
never overflows. Panel row heights are proportional to the available height, so
a 600 px-tall landscape phone and a 1000 px-tall tablet both look balanced.

---

## 3. Custom feature — Delayed Call Queue (2-call delay)

> **Discreet by default.** The queue is a *private caller tool*: queued numbers
> are painted exactly like uncalled numbers, so nobody watching the board can
> tell what is coming next. There is no amber tile, no "IN 2" / "NEXT" badge,
> no snack bar, and the reset dialog does not mention the queue either.
> The caller's only confirmation is a haptic tick (two pulses for "queued",
> one soft pulse for "cancelled").
>
> ```dart
> TambolaController()                            // discreet (default)
> TambolaController(showQueueHints: true)         // amber markers visible
> controller.setShowQueueHints(true);             // flip at runtime
> ```
>
> Nothing else changes between the two modes — the delay logic, the guaranteed
> call order and the history are identical.

Tap any **uncalled** tile to pre-select it; tap again to cancel. Internally:

```
tap 54            queue = {54: 2}          board: unchanged (light green)
Generate (random) queue = {54: 1}          board: unchanged
Generate (random) queue = {54: 0}          board: unchanged
Generate          → call 54 (guaranteed)   board: red + black outline
```

With `showQueueHints: true` the same run shows `IN 2 → IN 1 → NEXT` on an amber
tile instead.

Rules implemented in `TambolaController.callNextNumber()` / `_pickNextNumber()`:

* **Step A – who is called now?**
  1. the oldest queued number whose `delayCounter <= 0` is called (guaranteed), else
  2. a random **uncalled** number — queued numbers are excluded from the pool,
     unless *every* remaining number is queued (then the pool falls back to the
     queued ones so the game never deadlocks).
* **Step B – advance the rest:** every number still in the queue gets
  `delayCounter - 1`, and the badge re-renders (`IN 2 → IN 1 → NEXT`).

Extra safety rules: a number that has already been called can never be queued,
and the queue is cleared by **Reset**.

Test coverage: `test/delayed_queue_test.dart` verifies the badge counters, the
guaranteed call order, pool exclusion, multi-number ordering and the deadlock
fallback.

---

## 4. Controls

| Control | Behaviour |
|---|---|
| **Voice \<language\>** | TTS language: English, हिन्दी, తెలుగు, தமிழ், ಕನ್ನಡ, मराठी (falls back to the base language if the regional voice isn't installed). |
| **🔊 switch** | Mute/unmute. Muted games still record numbers, they just don't speak. |
| **⇪ Share** | Shares `Tambola / Housie — called numbers (n/90) …14 -> 60 -> 42…` via the native share sheet (clipboard fallback). |
| **Auto [Pro]** | Auto-plays a call every *Speed* seconds. Keeps the screen awake while running. |
| **Speed** | 1 s / 2 s / 3 s / 5 s. Changing it while Auto is running restarts the timer immediately. |
| **Reset** | Confirmation dialog → clears board, queue, history, current number and stops Auto. (In discreet mode the dialog does not mention queued numbers.) |
| **◯ Current number** | The big circle. Tap it to repeat the announcement. |
| **Generate** | Calls the next number (manual mode). Disables itself and reads "Board Full" when all 90 are called. |
| **History** | Modal with the full chain `14 -> 60 -> 42 -> 23` plus a Share button. |

Voice wording is configurable in `VoiceLanguage.announcement()` — currently
"Number 54" / "नंबर 54" (swap in "Five, Four, 54" style if you prefer).

---

## 5. Architecture notes

* **State**: `TambolaController extends ChangeNotifier` — zero third-party state
  packages, so it drops into Provider / Riverpod / GetX unchanged. The screen
  rebuilds through `ListenableBuilder`.
* **Services**: `TtsService` implements the `Announcer` interface (so tests use a
  `FakeAnnouncer` with no platform channels); `WakeLockService` keeps the screen
  on during Auto mode; `ShareService` wraps `share_plus` with a clipboard
  fallback. All three swallow platform failures so the board never crashes on a
  device without TTS.
* **Widgets** are stateless and take plain data (`state`, `number`, callbacks),
  which keeps rebuilds cheap and the grid at 60 fps.
* **Accessibility**: every tile has a `Semantics` label ("Number 54, queued,
  called after 2 more numbers"), and text scaling is clamped so the board keeps
  its proportions.

### Files

```
lib/
├── main.dart                       # landscape lock + bootstrap
├── app.dart                        # MaterialApp + text-scale clamp
├── models/
│   ├── cell_visual_state.dart       # uncalled | queued | queuedReady | called | latest
│   └── voice_language.dart          # TTS locales + announcement wording
├── services/
│   ├── announcer.dart               # interface the game depends on
│   ├── tts_service.dart             # flutter_tts implementation
│   ├── wake_lock_service.dart
│   └── share_service.dart
├── state/
│   └── tambola_controller.dart      # all game rules incl. the delayed queue
├── screens/
│   └── tambola_screen.dart          # landscape split + dialogs wiring
├── widgets/
│   ├── number_grid.dart             # responsive 9x10 board
│   ├── number_tile.dart             # tile + queue badge
│   ├── control_panel.dart           # right-hand column
│   ├── panel_pills.dart             # voice / auto / speed / sound / share
│   ├── action_button.dart
│   ├── current_number_display.dart
│   ├── history_dialog.dart
│   └── reset_dialog.dart
├── theme/app_theme.dart             # AppColors + AppMetrics
└── utils/feedback.dart              # haptics + snack bars
```

---

## 6. `tambola_board_preview.html`

A pixel-faithful, dependency-free browser twin of the app (same colours, same
layout maths, same queue algorithm, plus real `speechSynthesis` calling). Useful
for demoing the flow without a device, and for stakeholder sign-off.

The preview runs in the same discreet mode as the app: tapping tiles pre-selects
them with **no** visual change. On a desktop, a 5 px dot appears while the mouse
hovers a pre-selected tile (touch devices never render it), and `Q` toggles
between discreet and revealed markers so you can compare the two.

Keyboard shortcuts: `Space` Generate · `A` Auto · `R` Reset · `H` History ·
`Q` toggle queue markers · `F` toggle the FPS meter.
