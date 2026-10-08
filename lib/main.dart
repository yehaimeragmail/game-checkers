import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const CheckersApp());

class CheckersApp extends StatelessWidget {
  const CheckersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.zenStone,
      title: 'Checkers',
      tagline: 'Jump, capture, crown! Every move is a trap waiting to spring! 🐸',
      emoji: '⚫',
      slug: 'checkers',
      howToPlay:
          '• Tap a piece, then tap a glowing square to move diagonally.\n• Captures are FORCED — if you can jump, you must! Multi-jumps chain automatically.\n• Reach the far row to crown your piece 👑 (kings move both ways).\n• Win by capturing every enemy piece or blocking all their moves!',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => CheckersScreen(players: players, callbacks: cb),
    );
  }
}
