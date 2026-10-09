import 'package:flutter/material.dart';

/// "Tavern Oak & Brass" design system for Checkers (from Stitch project
/// 17479415822619451598). Pseudo-3D physical materials: deep walnut,
/// cast brass, glossy bakelite discs, warm incandescent light from upper-left.
abstract final class CkTheme {
  // Palette
  static const walnut = Color(0xFF1B110B);      // app background, board frame
  static const walnutDeep = Color(0xFF120B07);  // canvas base, recessed wells
  static const plaque = Color(0xFF281D17);     // wooden plaques, cards
  static const brass = Color(0xFFF2BE71);       // accents, highlights
  static const brassDeep = Color(0xFFD4A359);   // hardware, inlays
  static const oxblood = Color(0xFF7E301E);     // red player accents
  static const parchment = Color(0xFFF3DED4);   // primary text
  static const bark = Color(0xFF3A2E27);        // text on light elements
  static const outline = Color(0xFF9C8F7F);     // subtle borders
  static const felt = Color(0xFF1E2B22);        // baize under board

  // Board squares: warm woods (light = honey oak, dark = espresso walnut)
  static const sqLight = Color(0xFFC89B6A);
  static const sqLightHi = Color(0xFFD9AE7C);
  static const sqDark = Color(0xFF5A3A22);
  static const sqDarkLo = Color(0xFF4A2E1B);

  // Bakelite discs
  static const redDisc = Color(0xFFB3231B);
  static const redDiscHi = Color(0xFFD9483B);
  static const blackDisc = Color(0xFF1A1512);
  static const blackDiscHi = Color(0xFF3D342C);

  // Typography
  static const headlineFamily = 'EBGaramond';
  static const bodyFamily = 'Newsreader';

  static TextStyle get title => const TextStyle(
        fontFamily: headlineFamily,
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: brass,
        letterSpacing: 1.5,
        shadows: [
          Shadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 6),
          Shadow(color: Color(0x66D4A359), offset: Offset(0, -1), blurRadius: 1),
        ],
      );

  static TextStyle get plaqueTitle => const TextStyle(
        fontFamily: headlineFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: brass,
        letterSpacing: 0.8,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        color: parchment,
        height: 1.45,
      );

  static TextStyle get buttonLabel => const TextStyle(
        fontFamily: headlineFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: walnut,
        letterSpacing: 1.0,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12.5,
        color: outline,
      );

  /// Warm key light from upper-left: top-edge highlight + downward occlusion.
  static List<BoxShadow> get plaqueShadow => const [
        BoxShadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 5)),
        BoxShadow(color: Color(0x1AF2BE71), blurRadius: 2, offset: Offset(0, -1)),
      ];

  static List<BoxShadow> get insetShadow => const [
        BoxShadow(color: Color(0xB3000000), blurRadius: 8, offset: Offset(0, 3)),
      ];

  static BoxDecoration plaqueDeco({double radius = 14}) => BoxDecoration(
        color: plaque,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: brassDeep.withValues(alpha: 0.45), width: 1.2),
        boxShadow: plaqueShadow,
      );

  static BoxDecoration brassRim({double radius = 14}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brass, brassDeep, Color(0xFF9A6B32)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      );
}

/// A wooden plaque button with brass rim (DESIGN.md: carved plaque, brass inlay).
class PlaqueButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  const PlaqueButton({super.key, required this.label, required this.onTap, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: CkTheme.brassRim(radius: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 28),
          decoration: BoxDecoration(
            color: CkTheme.plaque,
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF32241B), Color(0xFF241812)],
            ),
          ),
          child: Center(
            child: Text(label,
                style: CkTheme.buttonLabel.copyWith(
                    color: CkTheme.brass, fontSize: fontSize,
                    shadows: const [Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 3)])),
          ),
        ),
      ),
    );
  }
}

/// Brass rocker-lever toggle (DESIGN.md: never iOS switches).
class BrassLever extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const BrassLever({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 64, height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: CkTheme.walnutDeep,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: CkTheme.brassDeep.withValues(alpha: 0.6)),
          boxShadow: CkTheme.insetShadow,
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [CkTheme.brass, CkTheme.brassDeep],
              ),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small brass-rimmed circular token button (pause / restart / undo).
class TokenButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const TokenButton({super.key, required this.icon, required this.onTap, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [CkTheme.brass, CkTheme.brassDeep, Color(0xFF9A6B32)],
          ),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF32241B), Color(0xFF241812)],
            ),
          ),
          child: Icon(icon, color: CkTheme.brass, size: size * 0.44),
        ),
      ),
    );
  }
}
