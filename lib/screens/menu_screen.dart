import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../checkers_theme.dart';
import '../engine/checkers_engine.dart';
import '../services/iap_service.dart';
import '../services/tavern_audio.dart';
import '../services/tavern_settings.dart';
import '../theme/tavern_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — Tavern Oak & Brass edition.
/// Logo, PLAY, mode setup (vs bot / 2 players, bot side, difficulty),
/// theme + piece-style picker, player renaming, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final TavernAudio audio;
  final TavernSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final CheckersStore _store = CheckersStore();

  TavernSettings get _s => widget.settings;
  TavernThemeDef get _t => TavernThemes.byId(_s.themeId);

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Tavern.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  void _play() {
    widget.audio.gameStart();
    // Flush any in-progress rename edit: the focus-loss commit runs
    // synchronously, so settings carry the fresh names below.
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = CheckersController(
      players: [
        CkPlayer(
            name: _s.redName, isBot: _s.vsBot && _s.botIsRed, isRed: true),
        CkPlayer(
            name: _s.blackName, isBot: _s.vsBot && !_s.botIsRed, isRed: false),
      ],
      difficulty: _s.difficulty,
    );
    widget.audio.stopMusic();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => CheckersGameScreen(
        controller: controller,
        audio: widget.audio,
        settings: _s,
        store: _store,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  /// Real share sheet with the Play Store link.
  Future<void> _share() async {
    widget.audio.click();
    await Share.share(
      'Play Checkers with me! https://play.google.com/store/apps/details?id=com.gameswajiha.checkers',
    );
  }

  /// Real in-app review; falls back to the store listing when the
  /// review flow is unavailable.
  Future<void> _rate() async {
    widget.audio.click();
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Never crash the menu over a rating prompt.
    }
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: widget.audio,
        settings: _s,
        store: _store,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return TavernBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/checkers_logo.webp',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Checkers', style: Tavern.display(46, theme: t)),
                  Text(
                    'THE TAVERN CLASSIC',
                    style: Tavern.label(12, theme: t),
                  ),
                  const SizedBox(height: 22),
                  PlaqueButton(
                      label: '▶  Play', onTap: _play, theme: t),
                  const SizedBox(height: 22),
                  _ModeCard(theme: t),
                  const SizedBox(height: 14),
                  _StyleCard(theme: t),
                  const SizedBox(height: 14),
                  _NamesCard(theme: t),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: _share,
                      ),
                      const SizedBox(width: 18),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: _rate,
                      ),
                      const SizedBox(width: 18),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.workspace_premium,
                        label: _s.isPro ? 'PRO ✓' : 'PRO',
                        onTap: _openPro,
                      ),
                      const SizedBox(width: 18),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                              store: _store,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 18),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.gamesPlayed > 0)
                    Text(
                      'Red ${_s.redWins}   •   Black ${_s.blackWins}   •   Draws ${_s.draws}${_s.bestMoves > 0 ? '   •   Best: ${_s.bestMoves} moves' : ''}',
                      style: Tavern.label(12, theme: t),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Tavern.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, TavernThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [t.woodMid, t.woodDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play', style: Tavern.display(24, theme: t)),
                const SizedBox(height: 12),
                for (final line in [
                  '• Red moves first. Tap one of your discs, then a glowing square.',
                  '• Captures are FORCED — if you can jump, you must.',
                  '• Chain every jump you can in one turn.',
                  '• Reach the far rank to be crowned a king (turn ends).',
                  '• Kings move and capture in all four diagonal directions.',
                  '• Capture all enemy discs — or block every move — to win.',
                  '• In 2-player mode you can offer a draw on your turn.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line, style: Tavern.body(14, theme: t)),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: PlaqueButton(
                    label: 'Got it!',
                    fontSize: 16,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MenuIcon extends StatelessWidget {
  final TavernThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.woodMid, theme.woodDeep],
              ),
              border: Border.all(color: theme.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: theme.accentLight, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: Tavern.label(12, theme: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Mode setup: vs bot (bot side + difficulty) or 2-human pass-and-play.
class _ModeCard extends StatelessWidget {
  final TavernThemeDef theme;
  const _ModeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    return TavernCard(
      theme: theme,
      title: 'Game Mode',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TavernChip(
                theme: theme,
                label: '🤖 Vs Bot',
                selected: s.vsBot,
                onTap: () {
                  audio.click();
                  s.setSetup(
                      vsBot: true,
                      botIsRed: s.botIsRed,
                      difficulty: s.difficulty);
                },
              ),
              TavernChip(
                theme: theme,
                label: '👥 2 Players',
                selected: !s.vsBot,
                onTap: () {
                  audio.click();
                  s.setSetup(
                      vsBot: false,
                      botIsRed: false,
                      difficulty: s.difficulty);
                },
              ),
            ],
          ),
          if (s.vsBot) ...[
            const SizedBox(height: 12),
            Text('Bot plays as:', style: Tavern.body(15, theme: theme)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TavernChip(
                  theme: theme,
                  label: '⬛ Black',
                  selected: !s.botIsRed,
                  onTap: () {
                    audio.click();
                    s.setSetup(
                        vsBot: true,
                        botIsRed: false,
                        difficulty: s.difficulty);
                  },
                ),
                TavernChip(
                  theme: theme,
                  label: '🟥 Red',
                  selected: s.botIsRed,
                  onTap: () {
                    audio.click();
                    s.setSetup(
                        vsBot: true,
                        botIsRed: true,
                        difficulty: s.difficulty);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Bot skill:', style: Tavern.body(15, theme: theme)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int d = 0; d < 3; d++)
                  TavernChip(
                    theme: theme,
                    label: d == 2 && !s.isPro
                        ? '🔒 ${TavernSettings.difficulties[d]}'
                        : TavernSettings.difficulties[d],
                    selected: s.difficulty == d,
                    onTap: () {
                      audio.click();
                      if (d == 2 && !s.isPro) {
                        // Hard bot is Pro-only — show the Pro screen.
                        screen._openPro();
                        return;
                      }
                      s.setSetup(
                          vsBot: true,
                          botIsRed: s.botIsRed,
                          difficulty: d);
                    },
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Pass-and-play on this device.\nDraw offers allowed on your turn.',
              style: Tavern.body(13,
                  theme: theme,
                  color: theme.ivory.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Theme + piece-style picker.
class _StyleCard extends StatelessWidget {
  final TavernThemeDef theme;
  const _StyleCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    return TavernCard(
      theme: theme,
      title: 'Tavern Style',
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final th in TavernThemes.all)
                GestureDetector(
                  onTap: () {
                    audio.click();
                    if (!s.isPro && TavernThemes.isProTheme(th.id)) {
                      screen._openPro();
                      return;
                    }
                    s.setTheme(th.id);
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: th.woodDeep.withValues(alpha: 0.7),
                          border: Border.all(
                            color: s.themeId == th.id
                                ? th.accentLight
                                : th.accent.withValues(alpha: 0.35),
                            width: s.themeId == th.id ? 3 : 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: th.redDisc,
                                    border: Border.all(
                                        color: th.accentLight, width: 1),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: th.blackDisc,
                                    border: Border.all(
                                        color: th.accentLight, width: 1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              th.name,
                              style: Tavern.label(10, theme: th),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!s.isPro && TavernThemes.isProTheme(th.id))
                        Positioned(
                          top: 4,
                          right: 6,
                          child: Icon(Icons.lock,
                              size: 14,
                              color: th.accentLight
                                  .withValues(alpha: 0.9)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child:
                Text('Disc style:', style: Tavern.body(15, theme: theme)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < PieceStyles.names.length; i++)
                TavernChip(
                  theme: theme,
                  label: (!s.isPro && PieceStyles.isProStyle(i))
                      ? '🔒 ${PieceStyles.names[i]}'
                      : PieceStyles.names[i],
                  selected: s.pieceStyle == i,
                  onTap: () {
                    audio.click();
                    if (!s.isPro && PieceStyles.isProStyle(i)) {
                      screen._openPro();
                      return;
                    }
                    s.setPieceStyle(i);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Rename the two player slots.
class _NamesCard extends StatelessWidget {
  final TavernThemeDef theme;
  const _NamesCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    return TavernCard(
      theme: theme,
      title: 'Player Names',
      child: Column(
        children: [
          _NameRow(
            theme: theme,
            discColor: theme.redDisc,
            discHi: theme.redDiscHi,
            label: 'Red',
            initial: s.redName,
            fallback: TavernSettings.defaultRedName,
            onDone: (v) => s.setRedName(v),
          ),
          const SizedBox(height: 8),
          _NameRow(
            theme: theme,
            discColor: theme.blackDisc,
            discHi: theme.blackDiscHi,
            label: 'Black',
            initial: s.blackName,
            fallback: TavernSettings.defaultBlackName,
            onDone: (v) => s.setBlackName(v),
          ),
          const SizedBox(height: 8),
          Text(
            'Names show on the side trays, turn banners and the winner plaque.',
            style: Tavern.body(12,
                theme: theme, color: theme.ivory.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NameRow extends StatefulWidget {
  final TavernThemeDef theme;
  final Color discColor;
  final Color discHi;
  final String label;
  final String initial;
  final String fallback;
  final ValueChanged<String> onDone;
  const _NameRow({
    required this.theme,
    required this.discColor,
    required this.discHi,
    required this.label,
    required this.initial,
    required this.fallback,
    required this.onDone,
  });

  @override
  State<_NameRow> createState() => _NameRowState();
}

class _NameRowState extends State<_NameRow> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  /// Last value actually committed to settings. Guards against double
  /// commits (keyboard done + focus loss fire back-to-back).
  late String _committed;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    _committed = widget.initial;
    _focus = FocusNode();
    // Commit when the user taps away / presses Play without hitting the
    // keyboard's done button. Previously the typed name lived only in the
    // controller in that case: it LOOKED saved but never reached
    // SharedPreferences and was lost on restart.
    _focus.addListener(() {
      if (!_focus.hasFocus) _commitIfChanged();
    });
  }

  @override
  void didUpdateWidget(covariant _NameRow old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial) {
      _committed = widget.initial;
      if (_c.text != widget.initial) _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    // Flush a pending edit if the row goes away while focused.
    _commitIfChanged();
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  /// Write the field to settings iff it differs from the last committed
  /// value. Blank input falls back to the default name.
  void _commitIfChanged() {
    final t = _c.text.trim();
    final value = t.isEmpty ? widget.fallback : t;
    if (value != _committed) {
      _committed = value;
      widget.onDone(_c.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.discHi, widget.discColor],
            ),
            border: Border.all(color: widget.theme.accentLight, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(widget.label,
              style: Tavern.body(14, theme: widget.theme)),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                  color: widget.theme.accent.withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: _c,
              focusNode: _focus,
              style: Tavern.body(15, theme: widget.theme),
              maxLength: 14,
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: widget.label,
                hintStyle: Tavern.body(14,
                    theme: widget.theme,
                    color: widget.theme.ivory.withValues(alpha: 0.4)),
              ),
              onSubmitted: (v) {
                _commitIfChanged();
                _focus.unfocus();
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
/// Tip jar (IAP).
class _SupportCard extends StatelessWidget {
  final TavernThemeDef theme;
  final CheckersStore store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final audio = screen.widget.audio;
    return TavernCard(
      theme: theme,
      title: 'Support Wajiha',
      child: Column(
        children: [
          Text(
            'Checkers is 100% free. If it made you smile, a small tip keeps the tavern open!',
            style: Tavern.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Tavern.body(13,
                  theme: theme,
                  color: theme.ivory.withValues(alpha: 0.6)),
            )
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in store.products)
                  if (p.id != CheckersStore.proId)
                    TavernChip(
                      theme: theme,
                      label: p.id == CheckersStore.chocolateId
                          ? '🍫 ${p.price}'
                          : '☕ ${p.price}',
                      selected: false,
                      onTap: () {
                        audio.click();
                        store.buyTip(p);
                      },
                    ),
              ],
            ),
        ],
      ),
    );
  }
}
