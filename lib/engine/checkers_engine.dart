import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Pure rules core (no UI, no timers): American/English draughts per RULES.md.
// Board: 64 squares, index = row * 8 + col. Row 0 is Black's back rank,
// row 7 is Red's back rank. Pieces: 0 empty, 1 red man, 2 red king,
// -1 black man, -2 black king. Red moves first.
// ---------------------------------------------------------------------------

/// A complete move: either one quiet step or a full capture sequence.
/// [landings] holds every landing square in order (multi-jump chains).
class CkMove {
  final int from;
  final List<int> landings;
  final int captures; // number of jumped pieces

  const CkMove(this.from, this.landings, this.captures);

  int get to => landings.last;
  bool get isCapture => captures > 0;
}

class CheckersRules {
  static int _r(int s) => s ~/ 8;
  static int _c(int s) => s % 8;
  static bool _on(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  /// Legal directions for a piece: kings all four diagonals, men forward.
  /// Red moves toward row 0, black toward row 7.
  static List<List<int>> dirs(int piece) {
    if (piece.abs() == 2) {
      return const [
        [-1, -1],
        [-1, 1],
        [1, -1],
        [1, 1]
      ];
    }
    return piece > 0
        ? const [
            [-1, -1],
            [-1, 1]
          ]
        : const [
            [1, -1],
            [1, 1]
          ];
  }

  static int promoRow(bool red) => red ? 0 : 7;

  /// All legal moves for [red]'s side. Captures are forced (RULES.md §6):
  /// if any capture exists, ONLY captures are returned.
  static List<CkMove> movesFor(List<int> board, bool red) {
    final caps = <CkMove>[];
    for (int s = 0; s < 64; s++) {
      final p = board[s];
      if (p == 0 || (p > 0) != red) continue;
      _jumps(board, s, s, p, const [], <int>{}, caps);
    }
    if (caps.isNotEmpty) return caps;
    final quiet = <CkMove>[];
    for (int s = 0; s < 64; s++) {
      final p = board[s];
      if (p == 0 || (p > 0) != red) continue;
      for (final d in dirs(p)) {
        final nr = _r(s) + d[0], nc = _c(s) + d[1];
        if (!_on(nr, nc)) continue;
        if (board[nr * 8 + nc] == 0) {
          quiet.add(CkMove(s, [nr * 8 + nc], 0));
        }
      }
    }
    return quiet;
  }

  /// Recursive multi-jump enumeration. A man that lands on the promotion
  /// row stops immediately (RULES.md §7: the turn ends, even mid-sequence).
  static void _jumps(List<int> bd, int from, int sq, int piece,
      List<int> path, Set<int> taken, List<CkMove> out) {
    bool any = false;
    final red = piece > 0;
    for (final d in dirs(piece)) {
      final mr = _r(sq) + d[0], mc = _c(sq) + d[1];
      final lr = _r(sq) + 2 * d[0], lc = _c(sq) + 2 * d[1];
      if (!_on(lr, lc)) continue;
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
        if (piece.abs() == 1 && lr == promoRow(red)) {
          // Crowning ends the jump sequence immediately.
          out.add(CkMove(from, np, nt.length));
        } else {
          _jumps(nb, from, land, piece, np, nt, out);
        }
      }
    }
    if (!any && path.isNotEmpty) {
      out.add(CkMove(from, path, taken.length));
    }
  }

  /// Applies [m] to [bd] in place: hops through every landing, removes
  /// jumped pieces, crowns men that finish on the far rank.
  static void applyRaw(List<int> bd, CkMove m, bool red) {
    int sq = m.from;
    final piece = bd[sq];
    bd[sq] = 0;
    for (final land in m.landings) {
      if ((sq - land).abs() > 9) {
        // A jump: remove the piece in the middle square.
        final mr = (_r(sq) + _r(land)) ~/ 2;
        final mc = (_c(sq) + _c(land)) ~/ 2;
        bd[mr * 8 + mc] = 0;
      }
      sq = land;
    }
    var p = piece;
    if (p.abs() == 1 && _r(sq) == promoRow(red)) p = red ? 2 : -2;
    bd[sq] = p;
  }

  static int pieceCount(List<int> board, bool red) =>
      board.where((p) => p != 0 && (p > 0) == red).length;

  // ------------------------------------------------------------ bot (RULES.md §11)
  static const _inf = 1 << 28;

  /// Material + positional evaluation from [redPerspective]'s side.
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
      if (c >= 2 && c <= 5 && r >= 2 && r <= 5) v += 5; // center control
      if (!king && ((red && r == 7) || (!red && r == 0))) v += 8; // back rank
      score += red == redPerspective ? v : -v;
    }
    final mine = movesFor(bd, redPerspective).length;
    final theirs = movesFor(bd, !redPerspective).length;
    score += (mine - theirs) * 2; // mobility
    return score;
  }

  static int _search(List<int> bd, bool red, int depth, int alpha, int beta,
      bool maximizing, int deadlineMs) {
    if (DateTime.now().millisecondsSinceEpoch > deadlineMs) {
      return maximizing ? -_inf : _inf;
    }
    final moves = movesFor(bd, red);
    if (moves.isEmpty) return maximizing ? -_inf + depth : _inf - depth;
    if (depth == 0) return evaluate(bd, maximizing ? red : !red);
    moves.sort((a, b) => b.captures.compareTo(a.captures)); // captures first
    if (maximizing) {
      int best = -_inf;
      for (final m in moves) {
        final nb = List<int>.from(bd);
        applyRaw(nb, m, red);
        best = max(
            best, _search(nb, !red, depth - 1, alpha, beta, false, deadlineMs));
        alpha = max(alpha, best);
        if (beta <= alpha) break;
      }
      return best;
    } else {
      int best = _inf;
      for (final m in moves) {
        final nb = List<int>.from(bd);
        applyRaw(nb, m, red);
        best =
            min(best, _search(nb, !red, depth - 1, alpha, beta, true, deadlineMs));
        beta = min(beta, best);
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  /// Picks a move for [red]'s side. difficulty: 0 easy (random legal),
  /// 1 medium (3-ply), 2 hard (5-ply). Thinking is capped at 1.5s.
  static CkMove pickBot(
      List<int> board, bool red, int difficulty, Random rand) {
    final moves = movesFor(board, red);
    if (moves.length == 1) return moves.first;
    if (difficulty <= 0) return moves[rand.nextInt(moves.length)];
    final depth = difficulty == 1 ? 3 : 5;
    final deadline = DateTime.now().millisecondsSinceEpoch + 1500;
    moves.sort((a, b) => b.captures.compareTo(a.captures));
    CkMove best = moves.first;
    int bestVal = -_inf;
    for (final m in moves) {
      final nb = List<int>.from(board);
      applyRaw(nb, m, red);
      final v = _search(nb, !red, depth - 1, -_inf, _inf, false, deadline);
      final jitter = rand.nextInt(difficulty == 1 ? 12 : 4);
      if (v + jitter > bestVal) {
        bestVal = v + jitter;
        best = m;
      }
      if (DateTime.now().millisecondsSinceEpoch > deadline) break;
    }
    return best;
  }
}

// ---------------------------------------------------------------------------
// Turn state machine, owned entirely by the controller (exemplar pattern).
// The UI only renders: it can never desync, and the watchdog recovers any
// phase found without a live timer — stuck states are impossible.
// ---------------------------------------------------------------------------

/// A player seat. Index 0 = red, 1 = black.
class CkPlayer {
  String name;
  final bool isBot;
  final bool isRed;
  CkPlayer({required this.name, required this.isBot, required this.isRed});
}

/// Engine-owned turn phases. The UI only renders.
enum CkPhase { awaitingMove, botThinking, animating, over }

/// UI hook events (sounds, narration side-effects live in the screen).
enum CkEvent {
  select,
  move,
  capture,
  crown,
  invalid,
  botThinking,
  humanWon,
  botWon,
  draw,
}

/// A move playing out on screen. The logical move is applied at once; the
/// UI interpolates the piece from [from] through every landing in
/// [waypoints], popping [capturedSquares] as it hops over them.
class CkMoveAnim {
  final int from;
  final List<int> waypoints;
  final List<int> capturedSquares;
  final bool crowns;
  final bool moverRed;
  final int totalMs;
  final DateTime startedAt = DateTime.now();

  CkMoveAnim({
    required this.from,
    required this.waypoints,
    required this.capturedSquares,
    required this.crowns,
    required this.moverRed,
    required this.totalMs,
  });

  double get progress {
    final e = DateTime.now().difference(startedAt).inMilliseconds;
    return (e / totalMs).clamp(0.0, 1.0);
  }
}

/// Undo snapshot: the exact prior state, including captured pieces,
/// king status, repetition history and quiet-move counter.
class _CkSnapshot {
  final List<int> board;
  final bool redTurn;
  final int quietHalves;
  final int moveCount;
  final Map<String, int> positions;
  final List<int> capturedByRed;
  final List<int> capturedByBlack;
  _CkSnapshot({
    required this.board,
    required this.redTurn,
    required this.quietHalves,
    required this.moveCount,
    required this.positions,
    required this.capturedByRed,
    required this.capturedByBlack,
  });
}

class CheckersController extends ChangeNotifier {
  final List<CkPlayer> players; // [red, black]
  final int difficulty; // 0 easy, 1 medium, 2 hard (bot seats)
  final Random _rand;

  List<int> board = List.filled(64, 0);
  bool redTurn = true; // red (bottom) moves first, RULES.md §3
  CkPhase phase = CkPhase.awaitingMove;
  CkMoveAnim? moveAnim;

  int selected = -1;
  List<CkMove> selectionMoves = [];
  List<CkMove> legal = [];
  bool mustCapture = false;

  bool over = false;
  bool? winnerIsRed; // null = draw
  bool paused = false;
  String banner = '';
  int quietHalves = 0; // half-moves without capture or man movement
  int moveCount = 0;

  /// Pieces each side has captured (for the per-side trays).
  final List<int> capturedByRed = []; // black piece codes
  final List<int> capturedByBlack = []; // red piece codes

  /// Draw by agreement (2-human mode only, RULES.md §10).
  bool drawOffered = false;
  bool drawOfferedByRed = true;

  final Map<String, int> _positions = {};
  final List<_CkSnapshot> _undo = [];

  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  int _gen = 0; // invalidates in-flight bot computations on undo/restart
  bool _botApplying = false;

  /// Test hook: collapse delays/animations so simulations run fast.
  bool fastMode = false;

  int get _botThinkMs => fastMode ? 5 : 750;
  int get _animPerHopMs => fastMode ? 5 : 130;

  /// UI hook for sounds. Set by the screen.
  void Function(CkEvent event)? onEvent;

  CkPlayer get current => players[redTurn ? 0 : 1];
  CkPlayer get red => players[0];
  CkPlayer get black => players[1];
  bool get awaitingHumanMove =>
      phase == CkPhase.awaitingMove && !current.isBot && !over && !paused;
  bool get botTurn => !over && current.isBot;
  bool get canOfferDraw =>
      !over && !players.any((p) => p.isBot) && !drawOffered;

  CheckersController({
    required this.players,
    this.difficulty = 1,
    Random? rand,
    this.fastMode = false,
  })  : assert(players.length == 2),
        _rand = rand ?? Random() {
    reset(silent: true);
    banner = current.isBot ? '${current.name} is up…' : '${current.name} to move';
    notifyListeners();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    _afterPhase();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------- internals
  void reset({bool silent = false}) {
    _timer?.cancel();
    _gen++;
    board = List.filled(64, 0);
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) board[r * 8 + c] = -1; // black top rows
      }
    }
    for (int r = 5; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) board[r * 8 + c] = 1; // red bottom rows
      }
    }
    redTurn = true;
    phase = CkPhase.awaitingMove;
    moveAnim = null;
    selected = -1;
    selectionMoves = [];
    legal = [];
    mustCapture = false;
    over = false;
    winnerIsRed = null;
    paused = false;
    quietHalves = 0;
    moveCount = 0;
    capturedByRed.clear();
    capturedByBlack.clear();
    drawOffered = false;
    _positions.clear();
    _undo.clear();
    _refreshLegal();
    _recordPosition();
    if (!silent) {
      banner = current.isBot ? '${current.name} is up…' : '${current.name} to move';
      notifyListeners();
      _afterPhase();
    }
  }

  void restart() {
    reset();
    onEvent?.call(CkEvent.select);
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress,
  /// recover. Stuck states are impossible by construction. Respects pause.
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    if (phase == CkPhase.botThinking) {
      _botCompute(_gen);
    } else if (phase == CkPhase.animating && moveAnim != null) {
      final anim = moveAnim!;
      final elapsed =
          DateTime.now().difference(anim.startedAt).inMilliseconds;
      final remain = (anim.totalMs - elapsed).clamp(50, anim.totalMs);
      _arm(Duration(milliseconds: remain), _afterMoveAnim);
    } else if (phase == CkPhase.animating) {
      _afterMoveAnim();
    } else if (phase == CkPhase.awaitingMove && current.isBot) {
      _afterPhase();
    }
  }

  void _refreshLegal() {
    legal = over ? [] : CheckersRules.movesFor(board, redTurn);
    mustCapture = legal.isNotEmpty && legal.first.isCapture;
  }

  String _posKey() => '${board.join(",")}|$redTurn';

  void _recordPosition() {
    final k = _posKey();
    _positions[k] = (_positions[k] ?? 0) + 1;
  }

  // ------------------------------------------------------------- human input
  /// All human taps funnel through here. Bots are driven by the engine.
  void tapSquare(int sq) {
    if (over || paused || phase != CkPhase.awaitingMove) return;
    if (current.isBot) return;
    final p = board[sq];
    if (selected != -1) {
      final mv =
          selectionMoves.where((m) => m.to == sq).toList(growable: false);
      if (mv.isNotEmpty) {
        _applyMove(mv.first);
        return;
      }
    }
    if (p != 0 && (p > 0) == redTurn) {
      final moves = legal.where((m) => m.from == sq).toList();
      if (moves.isEmpty) {
        onEvent?.call(CkEvent.invalid);
        selected = -1;
        selectionMoves = [];
      } else {
        selected = sq;
        selectionMoves = moves;
        onEvent?.call(CkEvent.select);
      }
      notifyListeners();
    } else {
      if (selected != -1 || p != 0) onEvent?.call(CkEvent.invalid);
      selected = -1;
      selectionMoves = [];
      notifyListeners();
    }
  }

  // ------------------------------------------------------------- move flow
  void _applyMove(CkMove m) {
    final botOk = !current.isBot || _botApplying;
    if (over ||
        (phase != CkPhase.awaitingMove && phase != CkPhase.botThinking) ||
        !botOk) {
      return;
    }
    final moverRed = redTurn;
    final mover = current;
    final piece = board[m.from];
    final wasMan = piece.abs() == 1;

    // Capture squares (and the captured piece values for the trays).
    final capturedSq = <int>[];
    final capturedVal = <int>[];
    int sq = m.from;
    for (final land in m.landings) {
      if ((sq - land).abs() > 9) {
        final mr = (sq ~/ 8 + land ~/ 8) ~/ 2;
        final mc = (sq % 8 + land % 8) ~/ 2;
        final cs = mr * 8 + mc;
        capturedSq.add(cs);
        capturedVal.add(board[cs]);
      }
      sq = land;
    }

    _pushUndo();
    CheckersRules.applyRaw(board, m, moverRed);
    for (final v in capturedVal) {
      (moverRed ? capturedByRed : capturedByBlack).add(v);
    }
    final crowned =
        wasMan && (m.to ~/ 8) == CheckersRules.promoRow(moverRed);
    moveCount++;
    // RULES.md §10: a half-move is "quiet" only if no capture and no man moved.
    if (m.isCapture || wasMan) {
      quietHalves = 0;
    } else {
      quietHalves++;
    }

    selected = -1;
    selectionMoves = [];
    redTurn = !redTurn;
    moveAnim = CkMoveAnim(
      from: m.from,
      waypoints: List<int>.from(m.landings),
      capturedSquares: capturedSq,
      crowns: crowned,
      moverRed: moverRed,
      totalMs: fastMode
          ? 1
          : (m.landings.length * _animPerHopMs + 220).clamp(300, 1600).toInt(),
    );
    phase = CkPhase.animating;

    if (m.isCapture) {
      banner = '${mover.name} captures!';
      onEvent?.call(CkEvent.capture);
    } else {
      banner = '${mover.name} moves';
      onEvent?.call(CkEvent.move);
    }
    if (crowned) onEvent?.call(CkEvent.crown);
    notifyListeners();
    _arm(Duration(milliseconds: moveAnim!.totalMs), _afterMoveAnim);
  }

  void _afterMoveAnim() {
    if (_disposed || over) return;
    moveAnim = null;
    _recordPosition();
    final moverRed = !redTurn;
    final moverName = players[moverRed ? 0 : 1].name;

    if (CheckersRules.pieceCount(board, redTurn) == 0) {
      _finish(moverRed); // all opponent pieces captured, RULES.md §9
      return;
    }
    if (CheckersRules.movesFor(board, redTurn).isEmpty) {
      _finish(moverRed); // opponent blocked, RULES.md §9
      return;
    }
    if ((_positions[_posKey()] ?? 0) >= 3) {
      _finish(null); // threefold repetition, RULES.md §10
      return;
    }
    if (quietHalves >= 40) {
      _finish(null); // 40-move rule, RULES.md §10
      return;
    }
    phase = CkPhase.awaitingMove;
    _refreshLegal();
    final me = current;
    banner = me.isBot
        ? '${me.name} is up…'
        : (mustCapture ? 'Jump! Capture is forced.' : '$moverName played — ${me.name} to move');
    notifyListeners();
    _afterPhase();
  }

  /// Called whenever we settle into awaitingMove: bots play themselves.
  void _afterPhase() {
    if (_disposed || over || paused || phase != CkPhase.awaitingMove) return;
    if (!current.isBot) return;
    phase = CkPhase.botThinking;
    banner = '${current.name} is thinking…';
    notifyListeners();
    onEvent?.call(CkEvent.botThinking);
    final gen = _gen;
    _arm(Duration(milliseconds: _botThinkMs), () => _botCompute(gen));
  }

  void _botCompute(int gen) {
    if (_disposed ||
        over ||
        paused ||
        gen != _gen ||
        phase != CkPhase.botThinking ||
        !current.isBot) {
      return;
    }
    final boardCopy = List<int>.from(board);
    final red = redTurn;
    Future(() => CheckersRules.pickBot(boardCopy, red, difficulty, _rand))
        .then((picked) {
      if (_disposed ||
          over ||
          paused ||
          gen != _gen ||
          phase != CkPhase.botThinking ||
          !current.isBot) {
        return;
      }
      // Re-validate against the live legal list (paranoia: state can't
      // have changed, but never apply a move we didn't verify).
      final live = CheckersRules.movesFor(board, redTurn);
      final match = live
          .where((m) => m.from == picked.from && m.to == picked.to)
          .toList(growable: false);
      _botApplying = true;
      try {
        _applyMove(match.isNotEmpty ? match.first : live.first);
      } finally {
        _botApplying = false;
      }
    });
  }

  void _finish(bool? winnerRed) {
    over = true;
    phase = CkPhase.over;
    winnerIsRed = winnerRed;
    moveAnim = null;
    selected = -1;
    selectionMoves = [];
    if (winnerRed == null) {
      banner = 'A noble draw.';
      onEvent?.call(CkEvent.draw);
    } else {
      final w = players[winnerRed ? 0 : 1];
      banner = '${w.name} wins!';
      onEvent?.call(w.isBot ? CkEvent.botWon : CkEvent.humanWon);
    }
    notifyListeners();
  }

  /// The side to move resigns; the other side wins. Human-only action.
  void resign() {
    if (over || current.isBot || paused) return;
    _timer?.cancel();
    _timer = null;
    _finish(!redTurn);
  }

  // ------------------------------------------------------------- draw offer
  /// 2-human mode: the side to move offers a draw (RULES.md §10).
  void offerDraw() {
    if (!canOfferDraw || phase != CkPhase.awaitingMove) return;
    drawOffered = true;
    drawOfferedByRed = redTurn;
    onEvent?.call(CkEvent.select);
    notifyListeners();
  }

  void acceptDraw() {
    if (!drawOffered) return;
    drawOffered = false;
    _finish(null);
  }

  void declineDraw() {
    drawOffered = false;
    onEvent?.call(CkEvent.select);
    notifyListeners();
  }

  // ------------------------------------------------------------- undo
  void _pushUndo() {
    _undo.add(_CkSnapshot(
      board: List<int>.from(board),
      redTurn: redTurn,
      quietHalves: quietHalves,
      moveCount: moveCount,
      positions: Map<String, int>.from(_positions),
      capturedByRed: List<int>.from(capturedByRed),
      capturedByBlack: List<int>.from(capturedByBlack),
    ));
    if (_undo.length > 80) _undo.removeAt(0);
  }

  /// Undo. In vs-bot mode this undoes the full round trip (your move AND
  /// the bot's reply); in 2-human mode it undoes a single move.
  /// RULES.md §12: restores captured pieces and king status exactly.
  void undo() {
    if (_undo.isEmpty ||
        over ||
        paused ||
        phase == CkPhase.animating ||
        phase == CkPhase.botThinking) {
      onEvent?.call(CkEvent.invalid);
      return;
    }
    var st = _undo.removeLast();
    final anyBot = players.any((p) => p.isBot);
    if (anyBot && _undo.isNotEmpty && players[st.redTurn ? 0 : 1].isBot) {
      // Popped the state from before the bot's move — also pop the
      // human move that preceded it (full round trip).
      st = _undo.removeLast();
    }
    _gen++; // invalidate any in-flight bot computation
    board = st.board;
    redTurn = st.redTurn;
    quietHalves = st.quietHalves;
    moveCount = st.moveCount;
    _positions
      ..clear()
      ..addAll(st.positions);
    capturedByRed
      ..clear()
      ..addAll(st.capturedByRed);
    capturedByBlack
      ..clear()
      ..addAll(st.capturedByBlack);
    drawOffered = false;
    moveAnim = null;
    selected = -1;
    selectionMoves = [];
    phase = CkPhase.awaitingMove;
    _refreshLegal();
    final me = current;
    banner = me.isBot ? '${me.name} is up…' : '${me.name} to move';
    onEvent?.call(CkEvent.select);
    notifyListeners();
    _afterPhase();
  }

  // ------------------------------------------------------------- test hooks
  /// Test hook: install an arbitrary position (clears selection,
  /// refreshes the legal list, records the position for repetition
  /// tracking). The game must not be over.
  @visibleForTesting
  void debugSetBoard(List<int> newBoard, bool redToMove) {
    assert(!over);
    _timer?.cancel();
    _timer = null;
    _gen++; // invalidate any in-flight bot computation
    board = List<int>.from(newBoard);
    redTurn = redToMove;
    moveAnim = null;
    selected = -1;
    selectionMoves = [];
    phase = CkPhase.awaitingMove;
    _refreshLegal();
    _recordPosition();
    notifyListeners();
    _afterPhase();
  }

  /// Drive one full bot-vs-bot game to completion through the real
  /// engine-owned state machine (timers, phases, watchdog). Returns
  /// 'red' / 'black' / 'draw' / 'timeout'. Used by RULES.md §13 test 12
  /// to prove stuck states are impossible by construction.
  @visibleForTesting
  Future<String> simulateBotGame({int maxHalfMoves = 300}) async {
    assert(players.every((p) => p.isBot), 'simulateBotGame needs two bots');
    fastMode = true;
    final startMoves = moveCount;
    int iters = 0;
    // ~10 event-loop iterations per half-move; cap iterations as a
    // backstop so a stuck engine reports 'timeout' instead of hanging.
    while (!over &&
        moveCount - startMoves < maxHalfMoves &&
        iters < 60000) {
      if (phase == CkPhase.awaitingMove) _afterPhase();
      await Future.delayed(const Duration(milliseconds: 1));
      iters++;
    }
    if (!over) return 'timeout';
    if (winnerIsRed == null) return 'draw';
    return winnerIsRed! ? 'red' : 'black';
  }
}
