import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central audio for Checkers: SFX + looping music, persisted toggles/volume.
class CkAudio {
  CkAudio._();
  static final CkAudio instance = CkAudio._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  bool _ready = false;
  String? _currentTrack;

  Future<void> init() async {
    if (_ready) return;
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool('ck_music') ?? true;
    sfxOn = p.getBool('ck_sfx') ?? true;
    volume = p.getDouble('ck_vol') ?? 0.8;
    await _music.setReleaseMode(ReleaseMode.loop);
    _ready = true;
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ck_music', musicOn);
    await p.setBool('ck_sfx', sfxOn);
    await p.setDouble('ck_vol', volume);
  }

  Future<void> setMusic(bool v) async { musicOn = v; await _save(); if (!v) { await _music.stop(); _currentTrack = null; } }
  Future<void> setSfx(bool v) async { sfxOn = v; await _save(); }
  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0); await _save();
    await _music.setVolume(volume * 0.6);
  }

  Future<void> playMusic(String asset) async {
    if (!musicOn) return;
    if (_currentTrack == asset) return;
    _currentTrack = asset;
    try {
      await _music.setVolume(volume * 0.6);
      await _music.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> stopMusic() async { _currentTrack = null; try { await _music.stop(); } catch (_) {} }

  Future<void> _play(String asset, {double vol = 1.0}) async {
    if (!sfxOn) return;
    try {
      await _sfx.setVolume((volume * vol).clamp(0.0, 1.0));
      await _sfx.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> click() => _play('audio/click.wav');
  Future<void> move() => _play('audio/move.wav');
  Future<void> capture() => _play('audio/capture.wav');
  Future<void> crown() => _play('audio/crown.wav');
  Future<void> start() => _play('audio/start.wav');
  Future<void> win() => _play('audio/win.wav');
  Future<void> lose() => _play('audio/lose.wav');
  Future<void> invalid() => _play('audio/invalid.wav', vol: 0.7);

  void dispose() { _sfx.dispose(); _music.dispose(); }
}
