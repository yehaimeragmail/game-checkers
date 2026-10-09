import 'package:shared_preferences/shared_preferences.dart';

/// Persisted settings + match tally for Checkers.
class CkSettings {
  CkSettings._();
  static final CkSettings instance = CkSettings._();

  /// 0 = easy, 1 = medium, 2 = hard
  int difficulty = 1;
  int redWins = 0;
  int blackWins = 0;
  int draws = 0;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    final p = await SharedPreferences.getInstance();
    difficulty = p.getInt('ck_difficulty') ?? 1;
    redWins = p.getInt('ck_red_wins') ?? 0;
    blackWins = p.getInt('ck_black_wins') ?? 0;
    draws = p.getInt('ck_draws') ?? 0;
    _ready = true;
  }

  Future<void> setDifficulty(int v) async {
    difficulty = v.clamp(0, 2);
    (await SharedPreferences.getInstance()).setInt('ck_difficulty', difficulty);
  }

  /// result: 1 = red wins, -1 = black wins, 0 = draw
  Future<void> recordResult(int result) async {
    final p = await SharedPreferences.getInstance();
    if (result == 1) { redWins++; await p.setInt('ck_red_wins', redWins); }
    else if (result == -1) { blackWins++; await p.setInt('ck_black_wins', blackWins); }
    else { draws++; await p.setInt('ck_draws', draws); }
  }

  static const difficulties = ['Easy', 'Medium', 'Hard'];
}
