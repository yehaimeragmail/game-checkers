import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkers/engine/checkers_engine.dart';

List<int> _empty() => List.filled(64, 0);

/// Standard initial position.
List<int> _initial() {
  final b = _empty();
  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < 8; c++) {
      if ((r + c) % 2 == 1) b[r * 8 + c] = -1;
    }
  }
  for (int r = 5; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      if ((r + c) % 2 == 1) b[r * 8 + c] = 1;
    }
  }
  return b;
}

CheckersController _humans() => CheckersController(players: [
      CkPlayer(name: 'Red', isBot: false, isRed: true),
      CkPlayer(name: 'Black', isBot: false, isRed: false),
    ]);

/// Tap a full move: select [from], then tap [to]. Waits out the (fast)
/// animation so the controller settles back to awaitingMove.
Future<void> _playMove(CheckersController c, int from, int to) async {
  c.fastMode = true;
  c.tapSquare(from);
  c.tapSquare(to);
  await Future.delayed(const Duration(milliseconds: 30));
}

void main() {
  // ---------------- RULES.md §13 test cases (pure rules) ----------------
  test('1. initial board: 12 red rows 1-3, 12 black rows 6-8, red first', () {
    final b = _initial();
    expect(CheckersRules.pieceCount(b, true), 12);
    expect(CheckersRules.pieceCount(b, false), 12);
    for (int s = 0; s < 64; s++) {
      if (b[s] == 1) {
        expect(s ~/ 8 >= 5, true);
        expect((s ~/ 8 + s % 8) % 2, 1);
      }
      if (b[s] == -1) {
        expect(s ~/ 8 <= 2, true);
        expect((s ~/ 8 + s % 8) % 2, 1);
      }
    }
    final c = _humans();
    addTearDown(c.dispose);
    expect(c.redTurn, true);
    expect(CheckersRules.movesFor(b, true).length, 7);
  });

  test('2. red man moves forward only', () {
    final b = _empty();
    b[26] = 1; // (3,2)
    final ms = CheckersRules.movesFor(b, true);
    final tos = ms.map((m) => m.to).toSet();
    expect(tos, {17, 19}); // (2,1) and (2,3)
    expect(tos.contains(33), false); // backward illegal
  });

  test('3. forced capture: only capture moves offered', () {
    final b = _empty();
    b[40] = 1; // red man
    b[33] = -1; // black man adjacent
    final ms = CheckersRules.movesFor(b, true);
    expect(ms.isNotEmpty, true);
    expect(ms.every((m) => m.isCapture), true);
    expect(ms.any((m) => m.from == 40 && m.to == 26), true);
  });

  test('4. multi-jump chain captures both in one turn', () {
    final b = _empty();
    b[42] = 1;
    b[35] = -1;
    b[21] = -1;
    final ms = CheckersRules.movesFor(b, true);
    final chain = ms.where((m) => m.from == 42).toList();
    expect(chain.length, 1);
    expect(chain.first.landings, [28, 14]);
    final nb = List<int>.from(b);
    CheckersRules.applyRaw(nb, chain.first, true);
    expect(nb[35], 0);
    expect(nb[21], 0);
    expect(nb[14], 1);
  });

  test('5. crowning on the far row', () {
    final b = _empty();
    b[10] = 1;
    final mv =
        CheckersRules.movesFor(b, true).firstWhere((m) => m.to == 1);
    final nb = List<int>.from(b);
    CheckersRules.applyRaw(nb, mv, true);
    expect(nb[1], 2);
  });

  test('5b. crowning stops a jump sequence (turn ends)', () {
    final b = _empty();
    b[17] = 1; // red man (2,1)
    b[10] = -1; // black (1,2) — jumped on the way to crowning
    b[12] = -1; // black (1,4) — a fresh king could jump it
    final ms =
        CheckersRules.movesFor(b, true).where((m) => m.from == 17).toList();
    expect(ms.length, 1);
    expect(ms.first.landings, [3]); // crowns on (0,3), stops
    final nb = List<int>.from(b);
    CheckersRules.applyRaw(nb, ms.first, true);
    expect(nb[3], 2);
    expect(nb[12], -1); // second black man survives
  });

  test('6. king moves and captures all four diagonals', () {
    final b = _empty();
    b[27] = 2; // red king
    final ms =
        CheckersRules.movesFor(b, true).where((m) => m.from == 27).toList();
    expect(ms.length, 4);
    final b2 = _empty();
    b2[27] = 2;
    b2[18] = -1; // behind the king
    final caps =
        CheckersRules.movesFor(b2, true).where((m) => m.isCapture).toList();
    expect(caps.any((m) => m.from == 27 && m.to == 9), true);
  });

  test('7. men capture forward only', () {
    final b = _empty();
    b[27] = 1; // red man
    b[34] = -1; // behind it (4,2)
    final ms = CheckersRules.movesFor(b, true);
    expect(ms.any((m) => m.isCapture), false);
  });

  // ---------------- controller: wins / draws / undo ----------------
  test('8. win when opponent has no pieces', () async {
    final c = _humans();
    addTearDown(c.dispose);
    final b = _empty();
    b[40] = 1;
    c.debugSetBoard(b, true);
    await _playMove(c, 40, 33);
    expect(c.over, true);
    expect(c.winnerIsRed, true);
  });

  test('9. win when opponent is blocked', () async {
    final c = _humans();
    addTearDown(c.dispose);
    final b = _empty();
    b[40] = 1; // red man
    b[1] = -1; // black man (0,1): forward squares are 8 and 10
    b[8] = 1; // red blockers (their own jumps would leave the board)
    b[10] = 1;
    b[19] = 1; // occupies black's only capture landing (1->19 over 10)
    c.debugSetBoard(b, true);
    await _playMove(c, 40, 33);
    expect(c.over, true);
    expect(c.winnerIsRed, true); // black has pieces but no legal moves
  });

  test('10. 40 quiet half-moves (king shuffling) -> draw', () async {
    final c = _humans();
    addTearDown(c.dispose);
    final b = _empty();
    b[9] = 2; // red king, far from black so no capture is possible
    b[54] = -2; // black king
    c.debugSetBoard(b, true);
    c.quietHalves = 39;
    await _playMove(c, 9, 0); // king move, no capture
    expect(c.over, true);
    expect(c.winnerIsRed, null);
  });

  test('11. threefold repetition -> draw', () async {
    final c = _humans();
    addTearDown(c.dispose);
    c.fastMode = true;
    final b = _empty();
    b[9] = 2; // red king shuffles 9 <-> 0
    b[54] = -2; // black king shuffles 54 <-> 45 (never adjacent: no captures)
    c.debugSetBoard(b, true);
    // Two full shuffle cycles return to the same position twice more.
    for (int i = 0; i < 2; i++) {
      await _playMove(c, 9, 0);
      await _playMove(c, 54, 45);
      await _playMove(c, 0, 9);
      await _playMove(c, 45, 54);
      if (c.over) break;
    }
    expect(c.over, true);
    expect(c.winnerIsRed, null);
  });

  test('12. undo restores captured piece and king status exactly', () async {
    final c = _humans();
    addTearDown(c.dispose);
    final b = _empty();
    b[40] = 1;
    b[33] = -1;
    b[10] = -1; // second black piece: the capture does not end the game
    c.debugSetBoard(b, true);
    await _playMove(c, 40, 26); // capture
    expect(c.board[33], 0);
    expect(c.over, false);
    c.undo();
    expect(c.board[40], 1);
    expect(c.board[33], -1);
    expect(c.board[26], 0);
    expect(c.redTurn, true);
  });

  test('13. invalid tap: no state change', () async {
    final c = _humans();
    addTearDown(c.dispose);
    c.fastMode = true;
    final before = List<int>.from(c.board);
    c.tapSquare(36); // black piece on red's turn
    c.tapSquare(0); // empty far square
    await Future.delayed(const Duration(milliseconds: 20));
    expect(c.board, before);
    expect(c.redTurn, true);
    expect(c.phase, CkPhase.awaitingMove);
  });

  test('14. draw by agreement in 2-human mode', () async {
    final c = _humans();
    addTearDown(c.dispose);
    expect(c.canOfferDraw, true);
    c.offerDraw();
    expect(c.drawOffered, true);
    c.acceptDraw();
    expect(c.over, true);
    expect(c.winnerIsRed, null);
  });

  test('15. resign hands the game to the other side', () async {
    final c = _humans();
    addTearDown(c.dispose);
    c.fastMode = true;
    c.resign();
    expect(c.over, true);
    expect(c.winnerIsRed, false);
  });

  test('16. mustCapture flag mirrors forced-capture rule', () {
    final c = _humans();
    addTearDown(c.dispose);
    final b = _empty();
    b[40] = 1;
    b[33] = -1;
    c.debugSetBoard(b, true);
    expect(c.mustCapture, true);
    expect(c.legal.every((m) => m.isCapture), true);
  });

  // ---------------- bot legality: 200 simulated games ----------------
  test('17. bot never makes an illegal move across 200 games', () {
    final rand = Random(20261009);
    for (int g = 0; g < 200; g++) {
      var board = _initial();
      var redTurn = true;
      // Mix difficulties: mostly easy (fast), some medium.
      final diff = g % 10 == 0 ? 1 : 0;
      int moves = 0;
      while (moves < 200) {
        if (CheckersRules.pieceCount(board, redTurn) == 0) break;
        final legal = CheckersRules.movesFor(board, redTurn);
        if (legal.isEmpty) break; // blocked: game over
        final pick = CheckersRules.pickBot(board, redTurn, diff, rand);
        expect(
          legal.any((m) => m.from == pick.from && m.to == pick.to),
          true,
          reason: 'game $g move $moves: bot picked an illegal move',
        );
        CheckersRules.applyRaw(board, pick, redTurn);
        redTurn = !redTurn;
        moves++;
      }
    }
  });

  test('18. hard bot answers forced captures on fixed positions', () {
    final rand = Random(7);
    final b = _empty();
    b[42] = 1;
    b[35] = -1;
    b[21] = -1;
    final pick = CheckersRules.pickBot(b, true, 2, rand);
    expect(pick.isCapture, true);
    expect(pick.landings, [28, 14]);
  });

  // ---------------- engine-owned state machine: no stuck states ----------------
  test('19. bot-vs-bot game completes through the state machine', () async {
    final c = CheckersController(players: [
      CkPlayer(name: 'R', isBot: true, isRed: true),
      CkPlayer(name: 'B', isBot: true, isRed: false),
    ], difficulty: 0);
    addTearDown(c.dispose);
    final result = await c.simulateBotGame();
    expect(result, isNot('timeout'),
        reason: 'engine stuck: watchdog should make this impossible');
    expect(c.over, true);
    expect(c.phase, CkPhase.over);
  });

  test('20. bot as red (first player) kicks off by itself', () async {
    final c = CheckersController(
      players: [
        CkPlayer(name: 'Bot', isBot: true, isRed: true),
        CkPlayer(name: 'Human', isBot: false, isRed: false),
      ],
      difficulty: 0,
      fastMode: true,
    );
    addTearDown(c.dispose);
    // The engine must drive the bot's first move with no UI help.
    await Future.delayed(const Duration(milliseconds: 500));
    expect(c.moveCount, 1);
    expect(c.redTurn, false); // turn passed to the human
  });

  test('21. pause during bot turn freezes; resume recovers via watchdog',
      () async {
    final c = CheckersController(players: [
      CkPlayer(name: 'Bot', isBot: true, isRed: true),
      CkPlayer(name: 'Human', isBot: false, isRed: false),
    ], difficulty: 0);
    addTearDown(c.dispose);
    // Not fastMode: botThinking lasts 750ms + compute, giving us a window.
    await Future.delayed(const Duration(milliseconds: 200));
    expect(c.phase, CkPhase.botThinking);
    c.setPaused(true);
    await Future.delayed(const Duration(milliseconds: 400));
    expect(c.phase, CkPhase.botThinking); // frozen, no progress
    expect(c.moveCount, 0);
    c.setPaused(false); // watchdog re-arms the phase
    await Future.delayed(const Duration(milliseconds: 2500));
    expect(c.moveCount, 1); // bot's move completed after resume
    expect(c.redTurn, false);
  });
}
