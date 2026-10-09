import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../checkers_theme.dart';
import '../engine/checkers_engine.dart';
import '../services/iap_service.dart';
import '../services/tavern_audio.dart';
import '../services/tavern_settings.dart';
import '../theme/tavern_themes.dart';
import 'settings_screen.dart';

/// Checkers game screen — exemplar edition.
///
/// - Every side has its OWN tray: Black on top, Red on the bottom. The
///   active side highlights; bot turns narrate ("Omar is thinking…") and
///   play out with real-time hop-by-hop piece animations.
/// - The controller owns the turn state machine; the UI only renders.
class CheckersGameScreen extends StatefulWidget {
  final CheckersController controller;
  final TavernAudio audio;
  final TavernSettings settings;
  final CheckersStore store;

  const CheckersGameScreen({
    super.key,
    required this.controller,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<CheckersGameScreen> createState() => _CheckersGameScreenState();
}

class _CheckersGameScreenState extends State<CheckersGameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animCtrl;
  CkMoveAnim? _shownAnim;
  bool _paused = false;
  bool _gameOverRecorded = false;
  bool _drawDialogShown = false;

  CheckersController get _c => widget.controller;
  TavernThemeDef get _t => TavernThemes.byId(widget.settings.themeId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animCtrl = AnimationController(vsync: this);
    _c.onEvent = _onEngineEvent;
    _c.addListener(_onControllerChanged);
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animCtrl.dispose();
    _c.removeListener(_onControllerChanged);
    _c.onEvent = null;
    _c.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
      if (!_c.over && mounted) {
        setState(() {
          _paused = true;
          _c.setPaused(true);
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final anim = _c.moveAnim;
    if (anim != null && !identical(anim, _shownAnim)) {
      _shownAnim = anim;
      _animCtrl.duration = Duration(milliseconds: max(anim.totalMs, 1));
      _animCtrl.forward(from: 0);
    } else if (anim == null) {
      _shownAnim = null;
    }
    setState(() {});
    if (_c.over && !_gameOverRecorded) {
      _gameOverRecorded = true;
      _onGameOver();
    }
    if (_c.drawOffered && !_drawDialogShown) {
      _drawDialogShown = true;
      _showDrawOffer();
    }
    if (!_c.drawOffered && _drawDialogShown && !_c.over) {
      _drawDialogShown = false;
    }
  }

  Future<void> _onEngineEvent(CkEvent event) async {
    final a = widget.audio;
    switch (event) {
      case CkEvent.select:
        await a.click();
        break;
      case CkEvent.move:
        await a.move();
        break;
      case CkEvent.capture:
        await a.capture();
        break;
      case CkEvent.crown:
        await a.crown();
        break;
      case CkEvent.invalid:
        await a.invalid();
        break;
      case CkEvent.botThinking:
        break; // narration covers it
      case CkEvent.humanWon:
        await a.win();
        break;
      case CkEvent.botWon:
        await a.lose();
        break;
      case CkEvent.draw:
        await a.lose();
        break;
    }
  }

  Future<void> _onGameOver() async {
    await widget.settings.recordGame(
      winnerRed: _c.winnerIsRed,
      moves: _c.moveCount,
    );
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || _c.phase != CkPhase.over) return;
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameOverDialog(
        controller: _c,
        audio: widget.audio,
        settings: widget.settings,
        theme: _t,
      ),
    );
    if (!mounted) return;
    if (again == true) {
      setState(() => _gameOverRecorded = false);
      _c.restart();
      widget.audio.startGameMusic();
    } else {
      widget.audio.stopMusic();
      Navigator.of(context).pop();
    }
  }

  Future<void> _showDrawOffer() async {
    final offerer = _c.drawOfferedByRed ? _c.red : _c.black;
    final other = _c.drawOfferedByRed ? _c.black : _c.red;
    if (!mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [_t.woodMid, _t.woodDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: _t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Draw Offer', style: Tavern.display(24, theme: _t)),
              const SizedBox(height: 10),
              Text(
                '${offerer.name} offers a draw.\n${other.name}, do you accept?',
                style: Tavern.body(15, theme: _t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: PlaqueButton(
                      label: 'Accept',
                      fontSize: 16,
                      theme: _t,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PlaqueButton(
                      label: 'Decline',
                      fontSize: 16,
                      theme: _t,
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (accept == true) {
      _c.acceptDraw();
    } else {
      _c.declineDraw();
    }
    _drawDialogShown = false;
  }

  void _togglePause() {
    widget.audio.click();
    setState(() {
      _paused = !_paused;
      _c.setPaused(_paused);
      if (_paused) {
        widget.audio.onAppPaused();
      } else {
        widget.audio.onAppResumed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return TavernBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause,
                color: t.accentLight),
            onPressed: _togglePause,
          ),
          title: Text('Checkers', style: Tavern.title(22, theme: t)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: t.accentLight),
              onPressed: () async {
                widget.audio.click();
                final wasPaused = _paused;
                if (!wasPaused) {
                  setState(() {
                    _paused = true;
                    _c.setPaused(true);
                  });
                }
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    audio: widget.audio,
                    settings: widget.settings,
                    store: widget.store,
                  ),
                ));
                widget.audio.configure(
                  musicOn: widget.settings.musicOn,
                  sfxOn: widget.settings.sfxOn,
                  volume: widget.settings.volume,
                );
                if (mounted && !wasPaused) {
                  setState(() {
                    _paused = false;
                    _c.setPaused(false);
                  });
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Black tray (top).
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    child: _SideTray(
                      controller: _c,
                      theme: t,
                      isRed: false,
                      pieceStyle: widget.settings.pieceStyle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Narration banner.
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _paused
                          ? 'Paused — tap resume to continue'
                          : _c.banner,
                      style: Tavern.body(13.5,
                          theme: t,
                          color:
                              t.accentLight.withValues(alpha: 0.9)),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Board.
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [t.woodMid, t.woodDeep],
                              ),
                              border: Border.all(
                                  color: t.accentDark
                                      .withValues(alpha: 0.5),
                                  width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 22,
                                    offset: Offset(0, 10)),
                              ],
                            ),
                            child: LayoutBuilder(
                              builder: (ctx, constraints) =>
                                  AnimatedBuilder(
                                animation: _animCtrl,
                                builder: (_, _) => Stack(
                                  children: [
                                    _BoardGrid(
                                      controller: _c,
                                      theme: t,
                                      pieceStyle:
                                          widget.settings.pieceStyle,
                                      onTap: (s) {
                                        if (!_paused) {
                                          _c.tapSquare(s);
                                        }
                                      },
                                    ),
                                    _MoveOverlay(
                                      controller: _c,
                                      theme: t,
                                      pieceStyle:
                                          widget.settings.pieceStyle,
                                      progress: _shownAnim != null
                                          ? _animCtrl.value
                                          : 0,
                                      boardSize: constraints.maxWidth,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Red tray (bottom).
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    child: _SideTray(
                      controller: _c,
                      theme: t,
                      isRed: true,
                      pieceStyle: widget.settings.pieceStyle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Controls.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TokenButton(
                          theme: t,
                          icon: Icons.undo,
                          onTap: () {
                            widget.audio.click();
                            _c.undo();
                          },
                        ),
                        const SizedBox(width: 20),
                        TokenButton(
                          theme: t,
                          icon: Icons.refresh,
                          onTap: () {
                            widget.audio.click();
                            _confirmRestart();
                          },
                        ),
                        const SizedBox(width: 20),
                        if (_c.canOfferDraw)
                          TokenButton(
                            theme: t,
                            icon: Icons.handshake_outlined,
                            onTap: () {
                              _c.offerDraw();
                            },
                          )
                        else
                          TokenButton(
                            theme: t,
                            icon: Icons.flag_outlined,
                            onTap: () {
                              widget.audio.click();
                              _confirmResign();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_paused && !_c.over)
              _PauseOverlay(
                theme: t,
                onResume: _togglePause,
                onRestart: () {
                  setState(() => _paused = false);
                  _c.restart();
                },
                onQuit: () {
                  widget.audio.stopMusic();
                  Navigator.of(context).pop();
                },
                audio: widget.audio,
              ),
          ],
        ),
      ),
    );
  }

  void _confirmRestart() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [_t.woodMid, _t.woodDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: _t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start over?',
                  style: Tavern.display(22, theme: _t)),
              const SizedBox(height: 16),
              PlaqueButton(
                label: 'Restart game',
                fontSize: 16,
                theme: _t,
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _paused = false);
                  _c.restart();
                },
              ),
              const SizedBox(height: 10),
              PlaqueButton(
                label: 'Keep playing',
                fontSize: 16,
                theme: _t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmResign() {
    final me = _c.current;
    if (me.isBot || _c.over) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [_t.woodMid, _t.woodDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: _t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${me.name}, resign?',
                  style: Tavern.display(22, theme: _t)),
              const SizedBox(height: 8),
              Text('The other side takes the game.',
                  style: Tavern.body(14, theme: _t)),
              const SizedBox(height: 16),
              PlaqueButton(
                label: 'Resign',
                fontSize: 16,
                theme: _t,
                onTap: () {
                  Navigator.of(ctx).pop();
                  // Resign = opponent wins. Route through the engine by
                  // finishing with the other side as winner.
                  _c.resign();
                },
              ),
              const SizedBox(height: 10),
              PlaqueButton(
                label: 'Keep playing',
                fontSize: 16,
                theme: _t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Per-side tray: each side owns its piece tray/controls. The active side
/// highlights; bot sides narrate their thinking with animated dots.
class _SideTray extends StatelessWidget {
  final CheckersController controller;
  final TavernThemeDef theme;
  final bool isRed;
  final int pieceStyle;
  const _SideTray({
    required this.controller,
    required this.theme,
    required this.isRed,
    required this.pieceStyle,
  });

  @override
  Widget build(BuildContext context) {
    final player = isRed ? controller.red : controller.black;
    final isCurrent =
        controller.redTurn == isRed && !controller.over;
    final thinking = isCurrent &&
        controller.phase == CkPhase.botThinking &&
        player.isBot;
    final captured =
        isRed ? controller.capturedByRed : controller.capturedByBlack;
    final discColor = isRed ? theme.redDisc : theme.blackDisc;
    final discHi = isRed ? theme.redDiscHi : theme.blackDiscHi;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isCurrent
            ? discColor.withValues(alpha: 0.22)
            : theme.woodDeep.withValues(alpha: 0.6),
        border: Border.all(
          color: isCurrent
              ? theme.accentLight
              : theme.accent.withValues(alpha: 0.3),
          width: isCurrent ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: theme.accent.withValues(alpha: 0.35),
              blurRadius: 10,
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [discHi, discColor],
              ),
              border: Border.all(color: theme.accentLight, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        style: Tavern.label(14, theme: theme),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.isBot)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black
                                .withValues(alpha: 0.35),
                            border: Border.all(
                                color: theme.accent
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Text('BOT',
                              style: Tavern.label(9, theme: theme)),
                        ),
                      ),
                  ],
                ),
                if (thinking)
                  _ThinkingDots(theme: theme)
                else
                  Text(
                    isCurrent
                        ? (player.isBot
                            ? 'thinking…'
                            : (controller.mustCapture
                                ? 'must capture!'
                                : 'to move'))
                        : '${12 - captured.length} discs',
                    style: Tavern.body(12,
                        theme: theme,
                        color: theme.ivory.withValues(alpha: 0.65)),
                  ),
              ],
            ),
          ),
          // Captured-by-this-side mini discs.
          if (captured.isNotEmpty)
            SizedBox(
              width: min(captured.length, 6) * 14.0 + 8,
              height: 22,
              child: Stack(
                children: [
                  for (int i = 0;
                      i < min(captured.length, 6);
                      i++)
                    Positioned(
                      left: i * 14.0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: captured[i] > 0
                                ? [
                                    theme.redDiscHi,
                                    theme.redDisc
                                  ]
                                : [
                                    theme.blackDiscHi,
                                    theme.blackDisc
                                  ],
                          ),
                          border: Border.all(
                              color: Colors.black
                                  .withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  if (captured.length > 6)
                    Positioned(
                      left: 6 * 14.0,
                      top: 2,
                      child: Text('+${captured.length - 6}',
                          style: Tavern.label(11, theme: theme)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  final TavernThemeDef theme;
  const _ThinkingDots({required this.theme});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 4, top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.theme.accentLight.withValues(
                    alpha: 0.35 +
                        0.65 *
                            (0.5 +
                                0.5 *
                                    sin(_c.value * 2 * pi -
                                        i * 2.1))),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// The 64 squares + static pieces. The moving piece is drawn by
/// [_MoveOverlay] on top while a move animates.
class _BoardGrid extends StatelessWidget {
  final CheckersController controller;
  final TavernThemeDef theme;
  final int pieceStyle;
  final void Function(int sq) onTap;
  const _BoardGrid({
    required this.controller,
    required this.theme,
    required this.pieceStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final anim = controller.moveAnim;
    final animDest = anim?.waypoints.last;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
      itemCount: 64,
      itemBuilder: (_, s) {
        final r = s ~/ 8, c = s % 8;
        final dark = (r + c) % 2 == 1;
        final isSel = s == controller.selected;
        final dest =
            controller.selectionMoves.any((m) => m.to == s);
        // During a move animation, the destination piece is drawn by the
        // overlay; captured squares are empty already (logical board).
        final hideForAnim = anim != null && s == animDest;
        final p = hideForAnim ? 0 : controller.board[s];
        return GestureDetector(
          onTap: () => onTap(s),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [theme.sqDark, theme.sqDarkLo]
                    : [theme.sqLightHi, theme.sqLight],
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                          color: theme.accent
                              .withValues(alpha: 0.6),
                          blurRadius: 10)
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (p != 0)
                  DiscWidget(
                    piece: p,
                    theme: theme,
                    pieceStyle: pieceStyle,
                    selected: isSel,
                    size: 40,
                  ),
                if (dest)
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.accent.withValues(alpha: 0.9),
                      boxShadow: [
                        BoxShadow(
                            color: theme.accent
                                .withValues(alpha: 0.6),
                            blurRadius: 8)
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
/// Animated overlay: slides the moving piece hop-by-hop along its waypoints,
/// pops captured pieces as the jumper passes over them, and crowns at the end.
class _MoveOverlay extends StatelessWidget {
  final CheckersController controller;
  final TavernThemeDef theme;
  final int pieceStyle;
  final double progress; // 0..1 of the current move animation
  final double boardSize;
  const _MoveOverlay({
    required this.controller,
    required this.theme,
    required this.pieceStyle,
    required this.progress,
    required this.boardSize,
  });

  Offset _center(int sq, double cell) =>
      Offset((sq % 8 + 0.5) * cell, (sq ~/ 8 + 0.5) * cell);

  @override
  Widget build(BuildContext context) {
    final anim = controller.moveAnim;
    if (anim == null) return const SizedBox.shrink();
    final cell = boardSize / 8;
    final n = anim.waypoints.length;
    final p = progress.clamp(0.0, 1.0);

    // Piece position: interpolate hop by hop with an ease + hop arc.
    var from = anim.from;
    Offset pos = _center(from, cell);
    double hopT = 0;
    int hopIdx = (p * n).floor().clamp(0, n - 1);
    if (p >= 1) {
      pos = _center(anim.waypoints.last, cell);
      hopT = 1;
    } else {
      for (int i = 0; i < n; i++) {
        final a = _center(i == 0 ? anim.from : anim.waypoints[i - 1], cell);
        final b = _center(anim.waypoints[i], cell);
        if (i == hopIdx) {
          final t = (p * n - i).clamp(0.0, 1.0);
          final e = t < 0.5
              ? 2 * t * t
              : 1 - pow(-2 * t + 2, 2) / 2; // easeInOutQuad
          final isJump = (anim.waypoints[i] -
                      (i == 0 ? anim.from : anim.waypoints[i - 1]))
                  .abs() >
              9;
          final lift =
              isJump ? sin(pi * t) * cell * 0.28 : 0.0;
          pos = Offset(
            a.dx + (b.dx - a.dx) * e,
            a.dy + (b.dy - a.dy) * e - lift,
          );
          hopT = t;
          from = anim.waypoints[i];
          break;
        }
      }
    }

    // The logical board already holds the final piece; render it from the
    // mover's perspective (crown glyph appears near the end of the slide).
    final moverPiece = anim.moverRed ? 1 : -1;
    final showKing = anim.crowns && p > 0.85;

    return Stack(
      children: [
        // Captured pieces pop out as the jumper passes over them.
        for (int i = 0; i < anim.capturedSquares.length; i++)
          _CapturePop(
            square: anim.capturedSquares[i],
            cell: cell,
            // Each capture belongs to a hop; fade it as its hop progresses.
            fade: _captureFade(anim, i, p),
            piece:
                _capturedPieceAt(anim, controller.board, i),
            theme: theme,
            pieceStyle: pieceStyle,
          ),
        // The moving piece.
        Positioned(
          left: pos.dx - 20,
          top: pos.dy - 20,
          child: DiscWidget(
            piece: showKing ? moverPiece * 2 : moverPiece,
            theme: theme,
            pieceStyle: pieceStyle,
            selected: false,
            size: 40,
            lift: hopT > 0 && hopT < 1 ? 0.06 : 0,
          ),
        ),
      ],
    );
  }

  /// Fade (1 = fully visible → 0 = gone) for captured piece [i].
  double _captureFade(CkMoveAnim anim, int i, double p) {
    // Captures happen in hop order; find this capture's hop index.
    int hop = 0;
    int seen = 0;
    int sq = anim.from;
    for (int h = 0; h < anim.waypoints.length; h++) {
      final land = anim.waypoints[h];
      if ((sq - land).abs() > 9) {
        if (seen == i) {
          hop = h;
          break;
        }
        seen++;
      }
      sq = land;
    }
    final n = anim.waypoints.length;
    final start = hop / n;
    final end = start + 0.35 / n;
    if (p <= start) return 1;
    if (p >= end) return 0;
    return 1 - (p - start) / (end - start);
  }

  /// The captured piece value (king or man) for rendering the pop.
  int _capturedPieceAt(
      CkMoveAnim anim, List<int> board, int i) {
    // The logical board has it removed; recover from the trays: the mover's
    // captured list grew by this move's captures, in hop order.
    final tray =
        anim.moverRed ? controller.capturedByRed : controller.capturedByBlack;
    final idx = tray.length - anim.capturedSquares.length + i;
    if (idx >= 0 && idx < tray.length) return tray[idx];
    return anim.moverRed ? -1 : 1;
  }
}

class _CapturePop extends StatelessWidget {
  final int square;
  final double cell;
  final double fade;
  final int piece;
  final TavernThemeDef theme;
  final int pieceStyle;
  const _CapturePop({
    required this.square,
    required this.cell,
    required this.fade,
    required this.piece,
    required this.theme,
    required this.pieceStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (fade <= 0) return const SizedBox.shrink();
    final c = Offset(
        (square % 8 + 0.5) * cell, (square ~/ 8 + 0.5) * cell);
    return Positioned(
      left: c.dx - 20,
      top: c.dy - 20,
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.4 * fade,
          child: DiscWidget(
            piece: piece,
            theme: theme,
            pieceStyle: pieceStyle,
            selected: false,
            size: 40,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// A physical game disc. Styles: 0 Bakelite, 1 Turned Wood, 2 Brass Ring,
/// 3 Ivory, 4 Marble. Kings show a crown glyph.
class DiscWidget extends StatelessWidget {
  final int piece; // 1/-1 men, 2/-2 kings
  final TavernThemeDef theme;
  final int pieceStyle;
  final bool selected;
  final double size;
  final double lift; // extra shadow when hopping
  const DiscWidget({
    super.key,
    required this.piece,
    required this.theme,
    required this.pieceStyle,
    required this.selected,
    this.size = 40,
    this.lift = 0,
  });

  @override
  Widget build(BuildContext context) {
    final red = piece > 0;
    final king = piece.abs() == 2;
    final base = red ? theme.redDisc : theme.blackDisc;
    final hi = red ? theme.redDiscHi : theme.blackDiscHi;
    final lo = red ? theme.redDiscLo : theme.blackDiscLo;

    List<Color> colors;
    List<double>? stops;
    switch (pieceStyle) {
      case 1: // Turned Wood: matte, warm mid-tone
        colors = [hi.withValues(alpha: 0.85), base, lo];
        break;
      case 3: // Ivory: pale discs, side-colored core
        colors = [
          const Color(0xFFF7F0DC),
          const Color(0xFFE8DCC0),
          base.withValues(alpha: 0.55)
        ];
        stops = const [0.0, 0.55, 1.0];
        break;
      case 4: // Marble: pale swirl over side color
        colors = [const Color(0xFFFFFFFF), hi, base, lo];
        stops = const [0.0, 0.25, 0.6, 1.0];
        break;
      default: // 0 Bakelite glossy, 2 Brass Ring base
        colors = [hi, base, lo];
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: colors,
          stops: stops,
        ),
        border: Border.all(
          color: pieceStyle == 2
              ? theme.accentLight
              : selected
                  ? theme.accentLight
                  : Colors.black.withValues(alpha: 0.35),
          width: pieceStyle == 2
              ? 3.5
              : selected
                  ? 3
                  : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black54,
              blurRadius: 5 + lift * 60,
              offset: Offset(0, 3 + lift * 60)),
          const BoxShadow(
              color: Color(0x33FFFFFF),
              blurRadius: 2,
              offset: Offset(-1, -2)),
          if (selected)
            BoxShadow(
                color: theme.accent.withValues(alpha: 0.7),
                blurRadius: 12),
        ],
      ),
      child: Center(
        child: king
            ? Text('♛',
                style: TextStyle(
                    color: theme.crown,
                    fontSize: size * 0.52,
                    shadows: const [
                      Shadow(
                          color: Colors.black87,
                          offset: Offset(0, 1),
                          blurRadius: 2)
                    ]))
            : pieceStyle == 1
                ? Container(
                    // turned-wood growth ring
                    width: size * 0.55,
                    height: size * 0.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: lo.withValues(alpha: 0.8), width: 2),
                    ),
                  )
                : Container(
                    width: size * 0.32,
                    height: size * 0.32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _PauseOverlay extends StatelessWidget {
  final TavernThemeDef theme;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  final TavernAudio audio;
  const _PauseOverlay({
    required this.theme,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(26),
          decoration: Tavern.plaqueDeco(theme, radius: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: Tavern.display(28, theme: theme)),
              const SizedBox(height: 18),
              PlaqueButton(
                  label: 'Resume', fontSize: 17, theme: theme, onTap: onResume),
              const SizedBox(height: 12),
              PlaqueButton(
                  label: 'Restart', fontSize: 17, theme: theme, onTap: onRestart),
              const SizedBox(height: 12),
              PlaqueButton(
                  label: 'Quit to Menu',
                  fontSize: 17,
                  theme: theme,
                  onTap: () {
                    audio.click();
                    onQuit();
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _GameOverDialog extends StatelessWidget {
  final CheckersController controller;
  final TavernAudio audio;
  final TavernSettings settings;
  final TavernThemeDef theme;
  const _GameOverDialog({
    required this.controller,
    required this.audio,
    required this.settings,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final draw = controller.winnerIsRed == null;
    final winnerRed = controller.winnerIsRed ?? false;
    final winner = winnerRed ? controller.red : controller.black;
    final headline = draw ? 'A Noble Draw' : '${winner.name} Triumphs';
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
              colors: [theme.woodMid, theme.woodDeep],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          border: Border.all(color: theme.accent, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Colors.black87, blurRadius: 24, offset: Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.accentLight,
                    theme.accent,
                    theme.accentDark
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 12,
                      offset: Offset(0, 6))
                ],
              ),
              child: Center(
                  child: Text(draw ? '🤝' : '🏆',
                      style: const TextStyle(fontSize: 52))),
            ),
            const SizedBox(height: 18),
            Text(headline,
                style: Tavern.display(34, theme: theme),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
                draw
                    ? 'Neither side yields.'
                    : 'The tavern erupts in applause.',
                style: Tavern.body(14,
                    theme: theme, color: theme.outline),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 14),
              decoration: Tavern.plaqueDeco(theme),
              child: Text(
                'Red ${settings.redWins}  ·  Black ${settings.blackWins}  ·  Draws ${settings.draws}\n${controller.moveCount} moves played',
                textAlign: TextAlign.center,
                style: Tavern.body(14, theme: theme),
              ),
            ),
            const SizedBox(height: 24),
            PlaqueButton(
              label: 'Play Again',
              theme: theme,
              onTap: () {
                audio.click();
                Navigator.of(context).pop(true);
              },
            ),
            const SizedBox(height: 12),
            PlaqueButton(
              label: 'Main Menu',
              fontSize: 17,
              theme: theme,
              onTap: () {
                audio.click();
                Navigator.of(context).pop(false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
