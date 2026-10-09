import 'dart:math';
import 'package:flutter/material.dart';
import 'audio.dart';
import 'settings.dart';
import 'checkers_theme.dart';
import 'main.dart' show TavernBackdrop;

// ==================== ENGINE (kept, rules per RULES.md) ====================

class CkMove {
  final int from;
  final List<int> landings;
  CkMove(this.from, this.landings);
  int get to => landings.last;
  bool get isCapture => _capCount > 0;
  int _capCount = 0;
}

class CheckersEngine {
  List<int> board = List.filled(64, 0);
  bool redTurn = true; // red (bottom) moves first

  void reset() {
    board = List.filled(64, 0);
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) board[r * 8 + c] = -1;
      }
    }
    for (int r = 5; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) board[r * 8 + c] = 1;
      }
    }
    redTurn = true;
  }

  static int _r(int s) => s ~/ 8;
  static int _c(int s) => s % 8;
  static bool _on(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  static List<List<int>> _dirs(int piece) {
    final king = piece.abs() == 2;
    if (king) return const [[-1, -1], [-1, 1], [1, -1], [1, 1]];
    return piece > 0 ? const [[-1, -1], [-1, 1]] : const [[1, -1], [1, 1]];
  }

  static int _promoRow(bool red) => red ? 0 : 7;

  List<CkMove> legalMoves() => _movesFor(board, redTurn);

  static List<CkMove> _movesFor(List<int> bd, bool red) {
    final caps = <CkMove>[];
    for (int s = 0; s < 64; s++) {
      final p = bd[s];
      if (p == 0 || (p > 0) != red) continue;
      _jumpsStatic(bd, s, s, p, [], {}, caps);
    }
    if (caps.isNotEmpty) return caps;
    final quiet = <CkMove>[];
    for (int s = 0; s < 64; s++) {
      final p = bd[s];
      if (p == 0 || (p > 0) != red) continue;
      for (final d in _dirs(p)) {
        final nr = _r(s) + d[0], nc = _c(s) + d[1];
        if (!_on(nr, nc)) continue;
        if (bd[nr * 8 + nc] == 0) {
          final mv = CkMove(s, [nr * 8 + nc]);
          mv._capCount = 0;
          quiet.add(mv);
        }
      }
    }
    return quiet;
  }

  static void _jumpsStatic(List<int> bd, int from, int sq, int piece,
      List<int> path, Set<int> taken, List<CkMove> out) {
    // static forwarder for minimax use
    final eng = _JumpsHelper();
    eng.run(bd, from, sq, piece, path, taken, out);
  }

  int pieceCount(bool red) =>
      board.where((p) => p != 0 && (p > 0) == red).length;

  int kingCount(bool red) =>
      board.where((p) => p.abs() == 2 && (p > 0) == red).length;

  static void applyRaw(List<int> bd, CkMove m, bool red) {
    int sq = m.from;
    final piece = bd[sq];
    bd[sq] = 0;
    for (final land in m.landings) {
      final mr = (_r(sq) + _r(land)) ~/ 2, mc = (_c(sq) + _c(land)) ~/ 2;
      if ((sq - land).abs() > 9) bd[mr * 8 + mc] = 0;
      sq = land;
    }
    var p = piece;
    if (p.abs() == 1 && _r(sq) == _promoRow(red)) p = red ? 2 : -2;
    bd[sq] = p;
  }

  /// Applies move; returns 1 if mover won, -1 if draw by blocking impossible (n/a), 0 otherwise.
  bool doMove(CkMove m) {
    applyRaw(board, m, redTurn);
    redTurn = !redTurn;
    if (pieceCount(redTurn) == 0) return true;
    return _movesFor(board, redTurn).isEmpty;
  }
}

class _JumpsHelper {
  void run(List<int> bd, int from, int sq, int piece, List<int> path,
      Set<int> taken, List<CkMove> out) {
    bool any = false;
    final red = piece > 0;
    for (final d in CheckersEngine._dirs(piece)) {
      final mr = CheckersEngine._r(sq) + d[0], mc = CheckersEngine._c(sq) + d[1];
      final lr = CheckersEngine._r(sq) + 2 * d[0], lc = CheckersEngine._c(sq) + 2 * d[1];
      if (!CheckersEngine._on(lr, lc)) continue;
      final mid = mr * 8 + mc, land = lr * 8 + lc;
      final mp = bd[mid];
      if (mp != 0 && (mp > 0) != red && bd[land] == 0 && !taken.contains(mid)) {
        any = true;
        final nb = List<int>.from(bd);
        nb[land] = nb[sq];
        nb[sq] = 0;
        nb[mid] = 0;
        final nt = Set<int>.from(taken)..add(mid);
        final np = [...path, land];
        if (piece.abs() == 1 && lr == CheckersEngine._promoRow(red)) {
          final mv = CkMove(from, np);
          mv._capCount = nt.length;
          out.add(mv);
        } else {
          run(nb, from, land, piece, np, nt, out);
        }
      }
    }
    if (!any && path.isNotEmpty) {
      final mv = CkMove(from, path);
      mv._capCount = taken.length;
      out.add(mv);
    }
  }
}

// ==================== BOT (minimax per RULES.md §11) ====================

class _Bot {
  static const _inf = 1 << 28;

  static int evaluate(List<int> bd, bool redPerspective) {
    int score = 0;
    for (int s = 0; s < 64; s++) {
      final p = bd[s];
      if (p == 0) continue;
      final red = p > 0;
      final king = p.abs() == 2;
      int v = king ? 140 : 100;
      final r = s ~/ 8, c = s % 8;
      if (!king) v += (red ? (7 - r) : r) * 3; // advancement
      if (c >= 2 && c <= 5 && r >= 2 && r <= 5) v += 5; // center
      if (!king && ((red && r == 7) || (!red && r == 0))) v += 8; // back-rank guard
      score += red == redPerspective ? v : -v;
    }
    // mobility
    final mine = CheckersEngine._movesFor(bd, redPerspective).length;
    final theirs = CheckersEngine._movesFor(bd, !redPerspective).length;
    score += (mine - theirs) * 2;
    return score;
  }

  static int _search(List<int> bd, bool red, int depth, int alpha, int beta,
      bool maximizing, int deadlineMs) {
    if (DateTime.now().millisecondsSinceEpoch > deadlineMs) return maximizing ? -_inf : _inf;
    final moves = CheckersEngine._movesFor(bd, red);
    if (moves.isEmpty) return maximizing ? -_inf + depth : _inf - depth;
    if (depth == 0) return evaluate(bd, maximizing ? red : !red);
    // move ordering: captures first
    moves.sort((a, b) => b._capCount.compareTo(a._capCount));
    if (maximizing) {
      int best = -_inf;
      for (final m in moves) {
        final nb = List<int>.from(bd);
        CheckersEngine.applyRaw(nb, m, red);
        best = max(best, _search(nb, !red, depth - 1, alpha, beta, false, deadlineMs));
        alpha = max(alpha, best);
        if (beta <= alpha) break;
      }
      return best;
    } else {
      int best = _inf;
      for (final m in moves) {
        final nb = List<int>.from(bd);
        CheckersEngine.applyRaw(nb, m, red);
        best = min(best, _search(nb, !red, depth - 1, alpha, beta, true, deadlineMs));
        beta = min(beta, best);
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  /// difficulty 0=easy (random), 1=medium (3-ply), 2=hard (5-ply, 1.5s cap)
  static CkMove pick(List<int> bd, bool red, int difficulty, Random rand) {
    final moves = CheckersEngine._movesFor(bd, red);
    if (moves.length == 1) return moves.first;
    if (difficulty == 0) return moves[rand.nextInt(moves.length)];
    final depth = difficulty == 1 ? 3 : 5;
    final deadline = DateTime.now().millisecondsSinceEpoch + 1500;
    moves.sort((a, b) => b._capCount.compareTo(a._capCount));
    CkMove best = moves.first;
    int bestVal = -_inf;
    for (final m in moves) {
      final nb = List<int>.from(bd);
      CheckersEngine.applyRaw(nb, m, red);
      final v = _search(nb, !red, depth - 1, -_inf, _inf, false, deadline);
      final jitter = rand.nextInt(difficulty == 1 ? 12 : 4);
      if (v + jitter > bestVal) { bestVal = v + jitter; best = m; }
      if (DateTime.now().millisecondsSinceEpoch > deadline) break;
    }
    return best;
  }
}

// ==================== GAME SCREEN ====================

class CheckersGameScreen extends StatefulWidget {
  final bool vsBot;
  const CheckersGameScreen({super.key, required this.vsBot});
  @override
  State<CheckersGameScreen> createState() => _CheckersGameScreenState();
}

class _UndoState {
  final List<int> board;
  final bool redTurn;
  final int quietHalves;
  final Map<String, int> positions;
  _UndoState(this.board, this.redTurn, this.quietHalves, this.positions);
}

class _CheckersGameScreenState extends State<CheckersGameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _rand = Random();
  final eng = CheckersEngine();
  int sel = -1;
  List<CkMove> selMoves = [];
  List<CkMove> allLegal = [];
  bool mustCapture = false;
  bool over = false;
  bool paused = false;
  bool botThinking = false;
  bool? winnerIsRed; // true=red, false=black, null=draw
  int quietHalves = 0;
  final Map<String, int> _positions = {};
  final List<_UndoState> _undoStack = [];
  int moveCount = 0;
  late AnimationController _shake;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    eng.reset();
    _refreshLegal();
    _recordPosition();
    CkAudio.instance.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shake.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !over && mounted) {
      setState(() => paused = true);
    }
  }

  void _refreshLegal() {
    allLegal = eng.legalMoves();
    mustCapture = allLegal.isNotEmpty && allLegal.first.isCapture;
  }

  String _posKey() => '${eng.board.join(",")}|${eng.redTurn}';

  void _recordPosition() {
    final k = _posKey();
    _positions[k] = (_positions[k] ?? 0) + 1;
  }

  bool get _botTurn => widget.vsBot && !eng.redTurn && !over;

  void _tapSq(int s) {
    if (over || paused || _botTurn) return;
    final p = eng.board[s];
    if (sel != -1) {
      final mv = selMoves.where((m) => m.to == s).toList();
      if (mv.isNotEmpty) { _doMove(mv.first); return; }
    }
    if (p != 0 && (p > 0) == eng.redTurn) {
      final moves = allLegal.where((m) => m.from == s).toList();
      setState(() { sel = s; selMoves = moves; });
      CkAudio.instance.click();
    } else {
      if (sel != -1 || p != 0) {
        CkAudio.instance.invalid();
        _shake.forward(from: 0);
      }
      setState(() { sel = -1; selMoves = []; });
    }
  }

  void _pushUndo() {
    _undoStack.add(_UndoState(List<int>.from(eng.board), eng.redTurn, quietHalves, Map<String, int>.from(_positions)));
    if (_undoStack.length > 60) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty || over) { CkAudio.instance.invalid(); return; }
    CkAudio.instance.click();
    // In vs-bot mode, undo the full round trip (pop until it's red's turn again)
    _UndoState st = _undoStack.removeLast();
    if (widget.vsBot && _undoStack.isNotEmpty && st.redTurn == false) {
      st = _undoStack.removeLast();
    }
    setState(() {
      eng.board = st.board;
      eng.redTurn = st.redTurn;
      quietHalves = st.quietHalves;
      _positions..clear()..addAll(st.positions);
      sel = -1; selMoves = []; over = false; winnerIsRed = null;
      _refreshLegal();
    });
  }

  void _doMove(CkMove m) {
    _pushUndo();
    final wasCapture = m.isCapture;
    final piece = eng.board[m.from];
    final wasMan = piece.abs() == 1;
    final moverRed = eng.redTurn;
    final crowned = wasMan &&
        CheckersEngine._r(m.to) == CheckersEngine._promoRow(moverRed);

    setState(() {
      final won = eng.doMove(m);
      moveCount++;
      sel = -1; selMoves = [];
      if (!wasCapture && wasMan) { quietHalves++; } else { quietHalves = 0; }
      _recordPosition();
      if (won) {
        over = true;
        winnerIsRed = moverRed;
      } else if (_positions[_posKey()]! >= 3) {
        over = true; winnerIsRed = null; // threefold repetition
      } else if (quietHalves >= 40) {
        over = true; winnerIsRed = null; // 40-move rule
      }
    });

    if (wasCapture) { CkAudio.instance.capture(); } else { CkAudio.instance.move(); }
    if (crowned) Future.delayed(const Duration(milliseconds: 180), () => CkAudio.instance.crown());

    if (over) { _finishGame(); return; }
    _refreshLegal();
    _maybeBot();
  }

  Future<void> _finishGame() async {
    final result = winnerIsRed == null ? 0 : (winnerIsRed! ? 1 : -1);
    await CkSettings.instance.recordResult(result);
    if (winnerIsRed == null) {
      CkAudio.instance.lose();
    } else if (widget.vsBot) {
      if (winnerIsRed!) { CkAudio.instance.win(); } else { CkAudio.instance.lose(); }
    } else {
      CkAudio.instance.win();
    }
    if (mounted) setState(() {});
  }

  void _maybeBot() {
    if (over || paused || !_botTurn || botThinking) return;
    setState(() => botThinking = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || over || paused) { if (mounted) setState(() => botThinking = false); return; }
      final boardCopy = List<int>.from(eng.board);
      final red = eng.redTurn;
      final diff = CkSettings.instance.difficulty;
      Future(() => _Bot.pick(boardCopy, red, diff, _rand)).then((mv) {
        if (!mounted || over || paused) { if (mounted) setState(() => botThinking = false); return; }
        // re-validate against current legal moves (state may have changed)
        final legal = eng.legalMoves();
        final match = legal.where((m) => m.from == mv.from && m.to == mv.to).toList();
        setState(() => botThinking = false);
        _doMove(match.isNotEmpty ? match.first : legal.first);
      });
    });
  }

  void _restart() {
    CkAudio.instance.click();
    setState(() {
      eng.reset();
      sel = -1; selMoves = [];
      over = false; paused = false; winnerIsRed = null;
      quietHalves = 0; moveCount = 0; botThinking = false;
      _positions.clear(); _undoStack.clear();
      _refreshLegal();
      _recordPosition();
    });
    CkAudio.instance.start();
    _maybeBot();
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TavernBackdrop(
        child: SafeArea(
          child: over ? _buildGameOver() : _buildBoard(),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    final redCount = eng.pieceCount(true);
    final blackCount = eng.pieceCount(false);
    final turnRed = eng.redTurn;
    return Column(
      children: [
        const SizedBox(height: 8),
        // Top plaque: captured tally + turn indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: CkTheme.plaqueDeco(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tally(true, redCount),
                _turnIndicator(turnRed),
                _tally(false, blackCount),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Board in carved walnut tray with brass corners
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF2E1F14), Color(0xFF1B110B)],
                    ),
                    border: Border.all(color: CkTheme.brassDeep.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black87, blurRadius: 22, offset: Offset(0, 10)),
                      BoxShadow(color: Color(0x22F2BE71), blurRadius: 3, offset: Offset(0, -2)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                        itemCount: 64,
                        itemBuilder: (_, s) => _square(s),
                      ),
                      // brass corner protectors
                      for (final a in [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
                        Align(alignment: a, child: _brassCorner()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedBuilder(
            animation: _shake,
            builder: (_, child) {
              final dx = sin(_shake.value * pi * 5) * 6 * (1 - _shake.value);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Text(
              paused ? 'Paused — tap resume to continue'
              : botThinking ? 'Black is thinking…'
              : mustCapture ? 'Capture is forced — jump!' : (turnRed ? 'Red to move' : 'Black to move'),
              style: CkTheme.body.copyWith(color: CkTheme.brassDeep, fontSize: 13.5, fontStyle: FontStyle.italic),
            ),
          ),
        ),
        // Bottom token buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TokenButton(icon: paused ? Icons.play_arrow : Icons.pause, onTap: () {
                CkAudio.instance.click();
                setState(() => paused = !paused);
                if (!paused) _maybeBot();
              }),
              const SizedBox(width: 22),
              TokenButton(icon: Icons.refresh, onTap: _restart),
              const SizedBox(width: 22),
              TokenButton(icon: Icons.undo, onTap: _undo),
            ],
          ),
        ),
        if (paused) _pauseOverlay(),
      ],
    );
  }

  Widget _brassCorner() {
    return Container(
      width: 26, height: 26,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [CkTheme.brass, CkTheme.brassDeep],
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
      ),
    );
  }

  Widget _tally(bool red, int count) {
    return Row(
      children: [
        _miniDisc(red: red),
        const SizedBox(width: 6),
        Text('$count', style: CkTheme.body.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: CkTheme.parchment)),
      ],
    );
  }

  Widget _miniDisc({required bool red}) {
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: red ? [CkTheme.redDiscHi, CkTheme.redDisc] : [CkTheme.blackDiscHi, CkTheme.blackDisc],
        ),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
      ),
    );
  }

  Widget _turnIndicator(bool redTurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: CkTheme.walnutDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkTheme.brassDeep.withValues(alpha: 0.5)),
        boxShadow: CkTheme.insetShadow,
      ),
      child: Row(
        children: [
          _miniDisc(red: redTurn),
          const SizedBox(width: 8),
          Text(redTurn ? 'Red' : 'Black', style: CkTheme.body.copyWith(fontWeight: FontWeight.w700, color: CkTheme.brass)),
        ],
      ),
    );
  }

  Widget _square(int s) {
    final r = CheckersEngine._r(s), c = CheckersEngine._c(s);
    final dark = (r + c) % 2 == 1;
    final isSel = s == sel;
    final dest = selMoves.any((m) => m.to == s);
    final p = eng.board[s];
    final isKing = p.abs() == 2;

    return GestureDetector(
      onTap: () => _tapSq(s),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: dark
                ? [CkTheme.sqDark, CkTheme.sqDarkLo]
                : [CkTheme.sqLightHi, CkTheme.sqLight],
          ),
          boxShadow: isSel ? [const BoxShadow(color: Color(0x99F2BE71), blurRadius: 10)] : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (p != 0)
              TweenAnimationBuilder<double>(
                key: ValueKey('p$s$p'),
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                builder: (_, sc, child) => Transform.scale(
                  scale: isSel ? sc * 1.12 : sc,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.4),
                        radius: 1.1,
                        colors: (p > 0)
                            ? [CkTheme.redDiscHi, CkTheme.redDisc, const Color(0xFF7E1A14)]
                            : [CkTheme.blackDiscHi, CkTheme.blackDisc, const Color(0xFF0B0806)],
                      ),
                      border: isSel
                          ? Border.all(color: CkTheme.brass, width: 3)
                          : Border.all(color: Colors.black.withValues(alpha: 0.35), width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 3)),
                        BoxShadow(color: Color(0x33FFFFFF), blurRadius: 2, offset: Offset(-1, -2)),
                      ],
                    ),
                    child: Center(
                      child: isKing
                          ? const Text('♛', style: TextStyle(color: CkTheme.brassDeep, fontSize: 21,
                              shadows: [Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 2)]))
                          : Container(
                              width: 13, height: 13,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            if (dest)
              Container(
                width: 15, height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CkTheme.brass.withValues(alpha: 0.85),
                  boxShadow: const [BoxShadow(color: Color(0x99F2BE71), blurRadius: 8)],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return Expanded(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(26),
            decoration: CkTheme.plaqueDeco(radius: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Paused', style: CkTheme.plaqueTitle.copyWith(fontSize: 28)),
                const SizedBox(height: 18),
                PlaqueButton(label: 'Resume', fontSize: 17, onTap: () {
                  CkAudio.instance.click();
                  setState(() => paused = false);
                  _maybeBot();
                }),
                const SizedBox(height: 12),
                PlaqueButton(label: 'Restart', fontSize: 17, onTap: _restart),
                const SizedBox(height: 12),
                PlaqueButton(label: 'Quit to Menu', fontSize: 17, onTap: () {
                  CkAudio.instance.click();
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final draw = winnerIsRed == null;
    final headline = draw ? 'A Noble Draw' : (winnerIsRed! ? 'Red Triumphs' : 'Black Triumphs');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy on wooden pedestal
            Container(
              width: 110, height: 110,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [CkTheme.brass, CkTheme.brassDeep, Color(0xFF9A6B32)],
                ),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))],
              ),
              child: const Center(child: Text('🏆', style: TextStyle(fontSize: 52))),
            ),
            const SizedBox(height: 18),
            Text(headline, style: CkTheme.title.copyWith(fontSize: 36), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(draw ? 'Neither side yields.' : 'The tavern erupts in applause.',
                style: CkTheme.body.copyWith(fontStyle: FontStyle.italic, color: CkTheme.outline)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: CkTheme.plaqueDeco(),
              child: Text(
                'Red ${CkSettings.instance.redWins}  ·  Black ${CkSettings.instance.blackWins}  ·  Draws ${CkSettings.instance.draws}\n$moveCount moves played',
                textAlign: TextAlign.center,
                style: CkTheme.body.copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            PlaqueButton(label: 'Play Again', onTap: _restart),
            const SizedBox(height: 12),
            PlaqueButton(
              label: 'Main Menu', fontSize: 17,
              onTap: () { CkAudio.instance.click(); Navigator.of(context).pop(); },
            ),
          ],
        ),
      ),
    );
  }
}
