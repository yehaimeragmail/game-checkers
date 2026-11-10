import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../checkers_theme.dart';
import '../services/iap_service.dart';
import '../services/tavern_audio.dart';
import '../services/tavern_settings.dart';
import '../theme/tavern_themes.dart';
import 'pro_screen.dart';

/// Settings — parlor drawer metaphor, theme-aware.
class SettingsScreen extends StatefulWidget {
  final TavernAudio audio;
  final TavernSettings settings;
  final CheckersStore store;
  const SettingsScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CheckersStore get _store => widget.store;

  TavernThemeDef get _t => TavernThemes.byId(widget.settings.themeId);

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Tavern.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: widget.audio,
        settings: widget.settings,
        store: _store,
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    // init() is idempotent; this just refreshes this screen once the
    // store finishes loading (the menu already kicked it off).
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final audio = widget.audio;
    return TavernBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Tavern.display(22, theme: t)),
          centerTitle: true,
        ),
        body: ListenableBuilder(
          listenable: s,
          builder: (_, _) => SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Checkers PRO', t),
                GestureDetector(
                  onTap: _openPro,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: Tavern.plaqueDeco(t),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium,
                            color: t.accentLight, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.isPro
                                    ? 'PRO active — everything unlocked'
                                    : 'Unlock PRO',
                                style: Tavern.body(16, theme: t).copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                s.isPro
                                    ? 'All 9 themes, 5 disc styles, Hard bot.'
                                    : 'Free-vs-Pro comparison, one-time purchase.',
                                style: Tavern.body(13,
                                    theme: t,
                                    color: t.ivory.withValues(alpha: 0.65)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: t.accentLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _SectionTitle('Sound', t),
                _SettingRow(
                  theme: t,
                  label: 'Music',
                  control: BrassLever(
                    theme: t,
                    value: s.musicOn,
                    onChanged: (v) async {
                      audio.click();
                      await s.setMusic(v);
                      audio.configure(
                          musicOn: s.musicOn,
                          sfxOn: s.sfxOn,
                          volume: s.volume);
                      if (v) {
                        audio.startMenuMusic();
                      } else {
                        audio.stopMusic();
                      }
                    },
                  ),
                ),
                _SettingRow(
                  theme: t,
                  label: 'Sound effects',
                  control: BrassLever(
                    theme: t,
                    value: s.sfxOn,
                    onChanged: (v) async {
                      await s.setSfx(v);
                      audio.configure(
                          musicOn: s.musicOn,
                          sfxOn: s.sfxOn,
                          volume: s.volume);
                      if (v) audio.click();
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text('Volume', style: Tavern.body(16, theme: t)),
                Slider(
                  value: s.volume,
                  activeColor: t.accent,
                  inactiveColor: t.plaqueDeep,
                  onChanged: (v) async {
                    await s.setVolume(v);
                    audio.configure(
                        musicOn: s.musicOn,
                        sfxOn: s.sfxOn,
                        volume: s.volume);
                  },
                ),
                const SizedBox(height: 10),
                _SectionTitle('Appearance', t),
                _SettingRow(
                  theme: t,
                  label: 'Theme',
                  control: Text(
                    TavernThemes.byId(s.themeId).name,
                    style: Tavern.label(14, theme: t),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final th in TavernThemes.all)
                      GestureDetector(
                        onTap: () async {
                          audio.click();
                          if (!s.isPro &&
                              TavernThemes.isProTheme(th.id)) {
                            _openPro();
                            return;
                          }
                          await s.setTheme(th.id);
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 64,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(colors: [
                                  th.sqLight,
                                  th.sqDark,
                                ]),
                                border: Border.all(
                                  color: s.themeId == th.id
                                      ? th.accentLight
                                      : th.accent.withValues(alpha: 0.3),
                                  width: s.themeId == th.id ? 3 : 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int i = 0; i < 2; i++)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: i == 0
                                            ? th.redDisc
                                            : th.blackDisc,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!s.isPro &&
                                TavernThemes.isProTheme(th.id))
                              Positioned(
                                top: 2,
                                right: 3,
                                child: Icon(Icons.lock,
                                    size: 12,
                                    color: th.accentLight.withValues(
                                        alpha: 0.9)),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Disc style', style: Tavern.body(16, theme: t)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 0;
                        i < PieceStyles.names.length;
                        i++)
                      TavernChip(
                        theme: t,
                        label: (!s.isPro && PieceStyles.isProStyle(i))
                            ? '🔒 ${PieceStyles.names[i]}'
                            : PieceStyles.names[i],
                        selected: s.pieceStyle == i,
                        onTap: () async {
                          audio.click();
                          if (!s.isPro && PieceStyles.isProStyle(i)) {
                            _openPro();
                            return;
                          }
                          await s.setPieceStyle(i);
                        },
                      ),
                  ],
                ),
                // Tips are Android-only: hidden on iOS (App Store).
                if (defaultTargetPlatform != TargetPlatform.iOS) ...[
                  const SizedBox(height: 10),
                  _SectionTitle('Support', t),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: t.woodDeep.withValues(alpha: 0.65),
                      border: Border.all(
                          color: t.accent.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Checkers is 100% free. Tips keep the tavern open!',
                          style: Tavern.body(14, theme: t),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        if (!_store.storeReady)
                          Text(
                            _store.error ?? 'Available after store setup.',
                            style: Tavern.body(13,
                                theme: t,
                                color:
                                    t.ivory.withValues(alpha: 0.6)),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final p in _store.products)
                                if (p.id != CheckersStore.proId)
                                  TavernChip(
                                    theme: t,
                                    label: p.id == CheckersStore.chocolateId
                                        ? '🍫 ${p.price}'
                                        : '☕ ${p.price}',
                                    selected: false,
                                    onTap: () {
                                      audio.click();
                                      _store.buyTip(p);
                                    },
                                  ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _SectionTitle('About', t),
                Text(
                  'Checkers — Tavern Oak & Brass edition.\nVersion 2.0.0',
                  style: Tavern.body(13,
                      theme: t,
                      color: t.ivory.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final TavernThemeDef theme;
  const _SectionTitle(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text, style: Tavern.display(19, theme: theme)),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final TavernThemeDef theme;
  final String label;
  final Widget control;
  const _SettingRow(
      {required this.theme, required this.label, required this.control});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: Tavern.plaqueDeco(theme),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Tavern.body(16, theme: theme)
                  .copyWith(fontWeight: FontWeight.w600)),
          control,
        ],
      ),
    );
  }
}
