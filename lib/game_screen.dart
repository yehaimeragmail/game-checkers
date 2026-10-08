import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Checkers (English draughts): forced captures, multi-jump chains,
/// kings move both ways, crowned on the far row.
class CkMove {
  final int from;
  final List<int> landings; // full jump path (or single quiet step)
  CkMove(this.from, this.landings);
  int get to => landings.last;
  bool get isCapture => _capCount > 0;
  int _capCount = 0;
}

class CheckersEngine {
  List<int> board = List.filled(64, 0);
  bool whiteTurn = true;

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
    whiteTurn = true;
  }

  static int _r(int s) => s ~/ 8;
  static int _c(int s) => s % 8;
  static bool _on(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  static List<List<int>> _dirs(int piece) {
    final king = piece.abs() == 2;
    if (king) return const [[-1, -1], [-1, 1], [1, -1], [1, 1]];
    return piece > 0 ? const [[-1, -1], [-1, 1]] : const [[1, -1], [1, 1]];
  }

  static int _promoRow(bool white) => white ? 0 : 7;

  void _jumps(List<int> bd, int from, int sq, int piece, List<int> path,
      Set<int> taken, List<CkMove> out) {
    bool any = false;
    final white = piece > 0;
    for (final d in _dirs(piece)) {
      final mr = _r(sq) + d[0], mc = _c(sq) + d[1];
      final lr = _r(sq) + 2 * d[0], lc = _c(sq) + 2 * d[1];
      if (!_on(lr, lc)) continue;
      final mid = mr * 8 + mc, land = lr * 8 + lc;
      final mp = bd[mid];
      if (mp != 0 && (mp > 0) != white && bd[land] == 0 && !taken.contains(mid)) {
        any = true;
        final nb = List<int>.from(bd);
        nb[land] = nb[sq];
        nb[sq] = 0;
        nb[mid] = 0;
        final nt = Set<int>.from(taken)..add(mid);
        final np = [...path, land];
        // crowning ends the jump sequence
        if (piece.abs() == 1 && lr == _promoRow(white)) {
          final mv = CkMove(from, np);
          mv._capCount = nt.length;
          out.add(mv);
        } else {
          _jumps(nb, from, land, piece, np, nt, out);
        }
      }
    }
    if (!any && path.isNotEmpty) {
      final mv = CkMove(from, path);
      mv._capCount = taken.length;
      out.add(mv);
    }
  }

  List<CkMove> legalMoves() => _movesFor(board, whiteTurn);

  List<CkMove> _movesFor(List<int> bd, bool white) {
    final caps = <CkMove>[];
    for (int s = 0; s < 64; s++) {
      final p = bd[s];
      if (p == 0 || (p > 0) != white) continue;
      _jumps(bd, s, s, p, [], {}, caps);
    }
    if (caps.isNotEmpty) return caps;
    final quiet = <CkMove>[];
    for (int s = 0; s < 64; s++) {
      final p = bd[s];
      if (p == 0 || (p > 0) != white) continue;
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

  bool opponentHasMovesAfter(CkMove m) {
    final nb = List<int>.from(board);
    _applyRaw(nb, m, whiteTurn);
    return _movesFor(nb, !whiteTurn).isNotEmpty;
  }

  int pieceCount(bool white) =>
      board.where((p) => p != 0 && (p > 0) == white).length;

  void _applyRaw(List<int> bd, CkMove m, bool white) {
    int sq = m.from;
    final piece = bd[sq];
    bd[sq] = 0;
    for (final land in m.landings) {
      final mr = (_r(sq) + _r(land)) ~/ 2, mc = (_c(sq) + _c(land)) ~/ 2;
      if ((sq - land).abs() > 9) bd[mr * 8 + mc] = 0; // jumped piece
      sq = land;
    }
    var p = piece;
    if (p.abs() == 1 && _r(sq) == _promoRow(white)) p = white ? 2 : -2;
    bd[sq] = p;
  }

  /// Returns true if the mover won (opponent has no pieces or no moves).
  bool doMove(CkMove m) {
    _applyRaw(board, m, whiteTurn);
    whiteTurn = !whiteTurn;
    if (pieceCount(whiteTurn) == 0) return true;
    return _movesFor(board, whiteTurn).isEmpty;
  }
}

// ---------- UI ----------
class CheckersScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const CheckersScreen({super.key, required this.players, required this.callbacks});

  @override
  State<CheckersScreen> createState() => _CheckersScreenState();
}

class _CheckersScreenState extends State<CheckersScreen> {
  final _rand = Random();
  final eng = CheckersEngine();
  int sel = -1;
  List<CkMove> selMoves = [];
  List<CkMove> allLegal = [];
  int lastTo = -1;
  bool over = false;
  bool mustCapture = false;

  @override
  void initState() {
    super.initState();
    _reset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  void _reset() {
    eng.reset();
    sel = -1;
    selMoves = [];
    lastTo = -1;
    over = false;
    _refreshLegal();
    widget.callbacks.setActivePlayer(0);
  }

  void _refreshLegal() {
    allLegal = eng.legalMoves();
    mustCapture = allLegal.isNotEmpty && allLegal.first.isCapture;
  }

  bool get _botTurn => widget.players[eng.whiteTurn ? 0 : 1].isBot;

  void _tapSq(int s) {
    if (over || _botTurn) return;
    final p = eng.board[s];
    if (sel != -1) {
      final mv = selMoves.where((m) => m.to == s).toList();
      if (mv.isNotEmpty) {
        _doMove(mv.first);
        return;
      }
    }
    if (p != 0 && (p > 0) == eng.whiteTurn) {
      setState(() {
        sel = s;
        selMoves = allLegal.where((m) => m.from == s).toList();
      });
      Sfx.click();
    } else {
      setState(() {
        sel = -1;
        selMoves = [];
      });
    }
  }

  void _doMove(CkMove m) {
    final moverIdx = eng.whiteTurn ? 0 : 1;
    final wasCapture = m.isCapture;
    final crowned = eng.board[m.from].abs() == 1 &&
        CheckersEngine._r(m.to) == CheckersEngine._promoRow(eng.whiteTurn);
    setState(() {
      final won = eng.doMove(m);
      lastTo = m.to;
      sel = -1;
      selMoves = [];
      if (won) {
        over = true;
      }
    });
    if (wasCapture) {
      Sfx.move();
    } else {
      Sfx.tap();
    }
    if (crowned) Sfx.click();
    if (over) {
      final w = widget.players[moverIdx];
      w.score += 1;
      widget.callbacks.refreshHud();
      Sfx.win();
      widget.callbacks.finish(
          winner: w,
          headline: '${w.name} sweeps the board! 🧹',
          subline: wasCapture ? 'What a capture spree! 🔥' : 'Total domination!');
      return;
    }
    _refreshLegal();
    widget.callbacks.setActivePlayer(eng.whiteTurn ? 0 : 1);
    _maybeBot();
  }

  // ---------- bot: longest capture chain, else safe-ish moves ----------
  void _maybeBot() {
    if (over || !_botTurn) return;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || over) return;
      final moves = List<CkMove>.from(allLegal);
      if (moves.isEmpty) return;
      CkMove pick;
      if (_rand.nextDouble() < 0.2) {
        pick = moves[_rand.nextInt(moves.length)];
      } else if (moves.first.isCapture) {
        moves.sort((a, b) => b.landings.length.compareTo(a.landings.length));
        pick = moves.first; // longest chain 💪
      } else {
        pick = _bestQuiet(moves);
      }
      _doMove(pick);
    });
  }

  CkMove _bestQuiet(List<CkMove> moves) {
    final white = eng.whiteTurn;
    CkMove best = moves.first;
    int bestScore = -1 << 30;
    for (final m in moves) {
      int score = _rand.nextInt(20);
      final r = CheckersEngine._r(m.to);
      // advance toward crowning
      score += white ? (7 - r) * 6 : r * 6;
      // prefer center columns
      final c = CheckersEngine._c(m.to);
      score += 4 - (c - 3.5).abs().round() * 2;
      // safety: don't hang the piece (can enemy capture it next?)
      final nb = List<int>.from(eng.board);
      eng._applyRaw(nb, m, white);
      bool hanging = false;
      outer:
      for (int s = 0; s < 64; s++) {
        final p = nb[s];
        if (p == 0 || (p > 0) == white) continue;
        for (final d in CheckersEngine._dirs(p)) {
          final mr = CheckersEngine._r(s) + d[0], mc = CheckersEngine._c(s) + d[1];
          final lr = CheckersEngine._r(s) + 2 * d[0], lc = CheckersEngine._c(s) + 2 * d[1];
          if (mr < 0 || mr > 7 || mc < 0 || mc > 7 || lr < 0 || lr > 7 || lc < 0 || lc > 7) continue;
          if (mr * 8 + mc == m.to && nb[lr * 8 + lc] == 0) {
            hanging = true;
            break outer;
          }
        }
      }
      if (hanging) score -= 60;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final cur = widget.players[eng.whiteTurn ? 0 : 1];
    final wCount = eng.pieceCount(true);
    final bCount = eng.pieceCount(false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          if (!over)
            TurnBanner(
                player: cur,
                action: mustCapture
                    ? ' MUST capture! ⚔️'
                    : (cur.isBot ? ' is thinking… 🤖' : ', your move! ⚫')),
          const SizedBox(height: 8),
          Text('${widget.players[0].emoji} $wCount  vs  $bCount ${widget.players[1].emoji}',
              style: TextStyle(color: t.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: t.radius,
                    boxShadow: [
                      BoxShadow(
                          color: t.primary.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                    itemCount: 64,
                    itemBuilder: (_, s) => _square(s, t),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(mustCapture ? 'Captures are forced — jump away! 🐸' : 'Tap a piece, then a glowing square ✨',
              style: TextStyle(color: t.muted, fontSize: 12)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _square(int s, GameTheme t) {
    final r = CheckersEngine._r(s), c = CheckersEngine._c(s);
    final dark = (r + c) % 2 == 1;
    final isSel = s == sel;
    final isLast = s == lastTo;
    final dest = selMoves.any((m) => m.to == s);
    final p = eng.board[s];
    final isKing = p.abs() == 2;

    Color bg = dark ? t.primary.withValues(alpha: 0.35) : t.surface;
    if (isLast) bg = t.secondary.withValues(alpha: 0.5);
    if (isSel) bg = t.accent.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: () => _tapSq(s),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (p != 0)
              TweenAnimationBuilder<double>(
                key: ValueKey('p$s$p'),
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 180),
                curve: Curves.elasticOut,
                builder: (_, sc, child) => Transform.scale(
                  scale: sc,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (p > 0 ? widget.players[0] : widget.players[1]).color,
                      border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isKing
                        ? const Text('👑', style: TextStyle(fontSize: 18))
                        : Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.35)),
                          ),
                  ),
                ),
              ),
            if (dest)
              Container(
                width: 14,
                height: 14,
                decoration:
                    BoxDecoration(color: t.accent.withValues(alpha: 0.9), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
