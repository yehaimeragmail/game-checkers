import 'package:flutter/material.dart';
import 'audio.dart';
import 'settings.dart';
import 'checkers_theme.dart';
import 'game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CkAudio.instance.init();
  await CkSettings.instance.init();
  runApp(const CheckersApp());
}

class CheckersApp extends StatelessWidget {
  const CheckersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: CkTheme.walnut,
        fontFamily: CkTheme.bodyFamily,
      ),
      home: const MainMenu(),
    );
  }
}

/// Warm vignette backdrop used across screens.
class TavernBackdrop extends StatelessWidget {
  final Widget child;
  const TavernBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.35),
          radius: 1.25,
          colors: [Color(0xFF2A1C12), CkTheme.walnut, CkTheme.walnutDeep],
        ),
      ),
      child: child,
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CkAudio.instance.playMusic('audio/music_menu.wav');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause music when backgrounded; resume handled by screens.
    if (state == AppLifecycleState.paused) CkAudio.instance.stopMusic();
    if (state == AppLifecycleState.resumed) CkAudio.instance.playMusic('audio/music_menu.wav');
  }

  void _play(bool vsBot) {
    CkAudio.instance.click();
    CkAudio.instance.playMusic('audio/music_game.wav');
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CheckersGameScreen(vsBot: vsBot),
    )).then((_) => CkAudio.instance.playMusic('audio/music_menu.wav'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TavernBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decorative discs row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _MenuDisc(red: true), SizedBox(width: 14),
                      _MenuDisc(red: false), SizedBox(width: 14),
                      _MenuDisc(red: true, king: true),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('CHECKERS', style: CkTheme.title, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('The Tavern Classic', style: CkTheme.body.copyWith(color: CkTheme.brassDeep, fontSize: 16, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 34),
                  PlaqueButton(label: 'Play vs Bot', onTap: () => _play(true)),
                  const SizedBox(height: 16),
                  PlaqueButton(label: 'Two Players', onTap: () => _play(false)),
                  const SizedBox(height: 16),
                  PlaqueButton(
                    label: 'Settings',
                    fontSize: 17,
                    onTap: () {
                      CkAudio.instance.click();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Red ${CkSettings.instance.redWins}  ·  Black ${CkSettings.instance.blackWins}  ·  Draws ${CkSettings.instance.draws}',
                    style: CkTheme.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuDisc extends StatelessWidget {
  final bool red;
  final bool king;
  const _MenuDisc({required this.red, this.king = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54, height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: red ? [CkTheme.redDiscHi, CkTheme.redDisc] : [CkTheme.blackDiscHi, CkTheme.blackDisc],
        ),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Center(
        child: king
            ? const Text('♛', style: TextStyle(color: CkTheme.brassDeep, fontSize: 26))
            : Container(
                width: 20, height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.22)),
              ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final audio = CkAudio.instance;
    final set = CkSettings.instance;
    return Scaffold(
      body: TavernBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            children: [
              Row(
                children: [
                  TokenButton(icon: Icons.arrow_back, onTap: () { audio.click(); Navigator.of(context).pop(); }, size: 46),
                  const SizedBox(width: 14),
                  Text('Parlor Settings', style: CkTheme.plaqueTitle.copyWith(fontSize: 26)),
                ],
              ),
              const SizedBox(height: 20),
              _plaqueRow('Music', BrassLever(value: audio.musicOn, onChanged: (v) async {
                await audio.setMusic(v);
                if (v) audio.playMusic('audio/music_menu.wav');
                setState(() {});
              })),
              _plaqueRow('Sound FX', BrassLever(value: audio.sfxOn, onChanged: (v) async {
                await audio.setSfx(v); setState(() {});
              })),
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: CkTheme.plaqueDeco(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume', style: CkTheme.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                    Slider(
                      value: audio.volume,
                      activeColor: CkTheme.brass,
                      inactiveColor: CkTheme.bark,
                      onChanged: (v) async { await audio.setVolume(v); setState(() {}); },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: CkTheme.plaqueDeco(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bot Difficulty', style: CkTheme.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(3, (i) {
                        final selected = set.difficulty == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () async { await set.setDifficulty(i); audio.click(); setState(() {}); },
                            child: Container(
                              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: selected ? CkTheme.brass : CkTheme.brassDeep.withValues(alpha: 0.35),
                                    width: selected ? 2 : 1),
                                color: selected ? CkTheme.brass.withValues(alpha: 0.16) : CkTheme.walnutDeep,
                              ),
                              child: Center(
                                child: Text(CkSettings.difficulties[i],
                                    style: CkTheme.body.copyWith(
                                        color: selected ? CkTheme.brass : CkTheme.outline,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: CkTheme.plaqueDeco(),
                child: Text(
                  'Captures are forced — if you can jump, you must. Reach the far rank to be crowned. Win by capturing all enemy pieces or blocking every move.',
                  style: CkTheme.body.copyWith(fontSize: 13.5, color: CkTheme.parchment.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plaqueRow(String label, Widget trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: CkTheme.plaqueDeco(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CkTheme.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
          trailing,
        ],
      ),
    );
  }
}
