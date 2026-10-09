import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted settings + stats for Checkers. Survives app restarts.
///
/// Stores: audio toggles, renameable player slots (red / black), theme and
/// piece-style choices, mode setup (vs bot / 2 players, bot side,
/// difficulty), and lifetime tallies.
class TavernSettings extends ChangeNotifier {
  // Legacy keys (kept so existing installs keep their data).
  static const _kMusic = 'ck_music';
  static const _kSfx = 'ck_sfx';
  static const _kVolume = 'ck_vol';
  static const _kDifficulty = 'ck_difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kRedWins = 'ck_red_wins';
  static const _kBlackWins = 'ck_black_wins';
  static const _kDraws = 'ck_draws';
  // New keys.
  static const _kRedName = 'ck_red_name';
  static const _kBlackName = 'ck_black_name';
  static const _kTheme = 'ck_theme_id';
  static const _kPieceStyle = 'ck_piece_style'; // 0..4, see PieceStyles
  static const _kVsBot = 'ck_vs_bot';
  static const _kBotIsRed = 'ck_bot_is_red';
  static const _kGames = 'ck_games_played';
  static const _kBestMoves = 'ck_best_moves';

  static const defaultRedName = 'Scarlet';
  static const defaultBlackName = 'Onyx';
  static const difficulties = ['Easy', 'Medium', 'Hard'];

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int difficulty = 1; // medium default
  String redName = defaultRedName;
  String blackName = defaultBlackName;
  String themeId = 'classic';
  int pieceStyle = 0;
  bool vsBot = true;
  bool botIsRed = false; // bot plays black by default
  int redWins = 0;
  int blackWins = 0;
  int draws = 0;
  int gamesPlayed = 0;
  int bestMoves = 0; // fewest moves in a won game (0 = none yet)

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    redName = _clean(p.getString(_kRedName), defaultRedName);
    blackName = _clean(p.getString(_kBlackName), defaultBlackName);
    themeId = p.getString(_kTheme) ?? 'classic';
    pieceStyle = (p.getInt(_kPieceStyle) ?? 0).clamp(0, 4);
    vsBot = p.getBool(_kVsBot) ?? true;
    botIsRed = p.getBool(_kBotIsRed) ?? false;
    redWins = p.getInt(_kRedWins) ?? 0;
    blackWins = p.getInt(_kBlackWins) ?? 0;
    draws = p.getInt(_kDraws) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestMoves = p.getInt(_kBestMoves) ?? 0;
    notifyListeners();
  }

  static String _clean(String? v, String fallback) {
    final t = (v ?? '').trim();
    return t.isEmpty ? fallback : t;
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kRedName, redName);
    await p.setString(_kBlackName, blackName);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kPieceStyle, pieceStyle);
    await p.setBool(_kVsBot, vsBot);
    await p.setBool(_kBotIsRed, botIsRed);
    await p.setInt(_kRedWins, redWins);
    await p.setInt(_kBlackWins, blackWins);
    await p.setInt(_kDraws, draws);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestMoves, bestMoves);
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    difficulty = v.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  /// Full mode setup. [vsBot] false = 2-human pass-and-play. When vs bot,
  /// [botIsRed] chooses which side the bot plays.
  Future<void> setSetup({
    required bool vsBot,
    required bool botIsRed,
    required int difficulty,
  }) async {
    this.vsBot = vsBot;
    this.botIsRed = botIsRed;
    this.difficulty = difficulty.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  Future<void> setRedName(String v) async {
    redName = _clean(v, defaultRedName);
    notifyListeners();
    await _save();
  }

  Future<void> setBlackName(String v) async {
    blackName = _clean(v, defaultBlackName);
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setPieceStyle(int v) async {
    pieceStyle = v.clamp(0, 4);
    notifyListeners();
    await _save();
  }

  /// Record a finished game. [winnerRed] null = draw.
  Future<void> recordGame({required bool? winnerRed, required int moves}) async {
    gamesPlayed++;
    if (winnerRed == null) {
      draws++;
    } else if (winnerRed) {
      redWins++;
      if (bestMoves == 0 || moves < bestMoves) bestMoves = moves;
    } else {
      blackWins++;
      if (bestMoves == 0 || moves < bestMoves) bestMoves = moves;
    }
    notifyListeners();
    await _save();
  }
}
