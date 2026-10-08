import 'package:flutter_test/flutter_test.dart';
import 'package:checkers/game_screen.dart';

List<int> _empty() => List.filled(64, 0);

void main() {
  test('initial: white has 7 quiet moves, no captures', () {
    final e = CheckersEngine()..reset();
    final ms = e.legalMoves();
    expect(ms.length, 7);
    expect(ms.any((m) => m.isCapture), false);
  });

  test('captures are forced over quiet moves', () {
    final e = CheckersEngine();
    e.board = _empty();
    e.board[40] = 1; // white man c6
    e.board[33] = -1; // black man b5
    e.board[4] = -6;
    e.board[62] = 6;
    e.whiteTurn = true;
    final ms = e.legalMoves();
    expect(ms.isNotEmpty, true);
    expect(ms.every((m) => m.isCapture), true);
    expect(ms.any((m) => m.from == 40 && m.to == 26), true);
  });

  test('multi-jump chain captures both', () {
    final e = CheckersEngine();
    e.board = _empty();
    e.board[60] = 6;
    e.board[4] = -6;
    e.board[42] = 1; // white man
    e.board[35] = -1; // black man 1
    e.board[21] = -1; // black man 2
    e.whiteTurn = true;
    final ms = e.legalMoves();
    final chain = ms.where((m) => m.from == 42).toList();
    expect(chain.length, 1);
    expect(chain.first.landings, [28, 14]);
    e.doMove(chain.first);
    expect(e.board[35], 0);
    expect(e.board[21], 0);
    expect(e.board[14], 1);
  });

  test('crowning on the far row', () {
    final e = CheckersEngine();
    e.board = _empty();
    e.board[60] = 6;
    e.board[4] = -6;
    e.board[10] = 1; // white man c7
    e.whiteTurn = true;
    e.doMove(e.legalMoves().firstWhere((m) => m.from == 10 && m.to == 1));
    expect(e.board[1], 2); // crowned king
  });

  test('king moves both directions', () {
    final e = CheckersEngine();
    e.board = _empty();
    e.board[60] = 6;
    e.board[4] = -6;
    e.board[27] = 2; // white king d5
    e.whiteTurn = true;
    final ms = e.legalMoves().where((m) => m.from == 27).toList();
    expect(ms.length, 4); // all four diagonals
  });

  test('win when opponent has no pieces', () {
    final e = CheckersEngine();
    e.board = _empty();
    e.board[60] = 6;
    e.board[40] = 1;
    e.whiteTurn = true;
    // black has no pieces at all
    final won = e.doMove(e.legalMoves().first);
    expect(won, true);
  });

  test('crowning stops a jump sequence', () {
    final e = CheckersEngine();
    e.board = _empty();
    e.board[62] = 6;
    e.board[5] = -6;
    e.board[17] = 1; // white man b6 (2,1)
    e.board[10] = -1; // black man c7 (1,2)
    e.board[12] = -1; // black man e7 (1,4) — a fresh king could jump it
    e.whiteTurn = true;
    // 17 -> 3 over 10, crowns on (0,3): turn must stop here
    final ms = e.legalMoves().where((m) => m.from == 17).toList();
    expect(ms.length, 1);
    expect(ms.first.landings, [3]);
    e.doMove(ms.first);
    expect(e.board[3], 2);
    expect(e.board[12], -1); // second black man survives
  });
}
