import 'package:checkers/engine/checkers_engine.dart';
import 'package:checkers/services/tavern_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the player-name persistence bug (2026-10-09):
///
/// Renaming a player on the menu appeared to work — the typed name stayed
/// visible in the text field — but the name was never written to
/// SharedPreferences unless the user pressed the keyboard's done button
/// (tapping Play or tapping away skipped the save entirely), so the rename
/// was lost on restart. The menu now commits on focus loss and flushes
/// pending edits before starting a game.
///
/// These tests cover the prefs round-trip (rename -> save -> simulated
/// restart -> reload) plus the engine reload path (setup screen + trays +
/// narration show the persisted names).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renamed players survive a simulated app restart', () async {
    SharedPreferences.setMockInitialValues({});
    final s = TavernSettings();
    await s.load();
    await s.setRedName('Wajiha');
    await s.setBlackName('Bot Omar');

    // Simulate app restart: a brand-new settings object reading the same
    // on-device store.
    final s2 = TavernSettings();
    await s2.load();
    expect(s2.redName, 'Wajiha');
    expect(s2.blackName, 'Bot Omar');
  });

  test('blank rename falls back to defaults and still persists', () async {
    SharedPreferences.setMockInitialValues({});
    final s = TavernSettings();
    await s.load();
    await s.setRedName('   ');
    expect(s.redName, TavernSettings.defaultRedName);

    final s2 = TavernSettings();
    await s2.load();
    expect(s2.redName, TavernSettings.defaultRedName);
  });

  test('engine rebuilt after "restart" shows the persisted names', () async {
    SharedPreferences.setMockInitialValues({});
    final s = TavernSettings();
    await s.load();
    await s.setRedName('Wajiha');
    await s.setBlackName('Bot Omar');

    // Simulate app restart, then the setup screen rebuilding the engine
    // from the persisted settings (as MenuScreen._play does).
    final s2 = TavernSettings();
    await s2.load();
    final c = CheckersController(players: [
      CkPlayer(name: s2.redName, isBot: false, isRed: true),
      CkPlayer(name: s2.blackName, isBot: true, isRed: false),
    ]);
    addTearDown(c.dispose);

    expect(c.red.name, 'Wajiha');
    expect(c.black.name, 'Bot Omar');
    // The rename reaches turn narration (engine banner).
    expect(c.banner, contains('Wajiha'));
  });
}
