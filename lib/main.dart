import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'checkers_theme.dart';
import 'screens/splash_screen.dart';
import 'services/tavern_audio.dart';
import 'services/tavern_settings.dart';
import 'theme/tavern_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = TavernSettings();
  await settings.load();
  final audio = TavernAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(CheckersApp(settings: settings, audio: audio));
}

class CheckersApp extends StatefulWidget {
  final TavernSettings settings;
  final TavernAudio audio;
  const CheckersApp({super.key, required this.settings, required this.audio});

  @override
  State<CheckersApp> createState() => _CheckersAppState();
}

class _CheckersAppState extends State<CheckersApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their controllers.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Checkers',
        debugShowCheckedModeBanner: false,
        theme: Tavern.appTheme(
            TavernThemes.byId(widget.settings.themeId)),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
