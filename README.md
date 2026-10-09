# Checkers — Tavern Oak & Brass

Classic American/English draughts in a Victorian-parlor "Tavern Oak & Brass"
art direction. Part of Wajiha's 100-game collection
(`com.gameswajiha.checkers`).

## Rules

Authoritative rules: `~/workspace/game-factory/stitch-batch1/checkers/RULES.md`
(Stitch design: `DESIGN.md` in the same folder).

- Red moves first; captures are forced; multi-jump chains; crowning ends the turn.
- Win by capturing all enemy pieces or blocking every move.
- Draws: agreement (2-player), 40-move rule, threefold repetition.

## Architecture

- `lib/engine/checkers_engine.dart` — pure rules core (`CheckersRules`:
  move generation, captures, minimax bot) plus `CheckersController`, which
  owns the turn state machine (`awaitingMove` / `botThinking` / `animating` /
  `over`) and a 3-second watchdog that recovers any phase found without a
  live timer. Stuck states are impossible by construction; the UI only renders.
- `lib/services/tavern_audio.dart` — synthesized, cached WAV clips with a
  busy guard serializing play/stop; `pause()`/`resume()` on lifecycle;
  prewarmed on the splash screen.
- `lib/services/tavern_settings.dart` — persisted settings: audio, renameable
  Red/Black player slots, theme + disc style, mode setup (vs bot with bot
  side + Easy/Medium/Hard, or 2-human pass-and-play), lifetime tallies.
- `lib/services/iap_service.dart` — real Play Billing store
  (`CheckersStore`): `checkerspro` one-time non-consumable Pro unlock,
  `checkerscoffee` / `checkerschocolate` consumable tips; degrades
  gracefully ("Available after store setup") until products exist in
  Play Console.
- `lib/screens/pro_screen.dart` — Free-vs-Pro comparison table, real
  store prices, restore purchases, tip jar.
- `lib/theme/tavern_themes.dart` — 9 board themes + 5 disc styles.
- `lib/screens/` — splash (WAJIHA company splash → game splash), menu,
  game (per-side trays, animated bot turns with narration), settings.

## Tests

`flutter test` — 22 tests covering RULES.md §13 (forced captures,
multi-jumps, crowning, king movement, blocked wins, 40-move rule,
threefold repetition, undo, invalid taps), bot legality across 200
simulated games, and the engine-owned state machine (bot-vs-bot completes,
bot-first kickoff, pause/resume watchdog recovery).
