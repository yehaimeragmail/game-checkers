import 'package:flutter/material.dart';
import 'theme/tavern_themes.dart';

/// "Tavern Oak & Brass" design system for Checkers (from Stitch project
/// 17479415822619451598). Pseudo-3D physical materials: deep walnut,
/// cast brass, glossy bakelite discs, warm incandescent light from
/// upper-left. All widgets take an optional [TavernThemeDef].
class Tavern {
  static const headlineFamily = 'EBGaramond';
  static const bodyFamily = 'Newsreader';

  static TextStyle display(double size,
          {TavernThemeDef? theme, Color? color}) =>
      TextStyle(
        fontFamily: headlineFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? theme?.accentLight ?? const Color(0xFFF2BE71),
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 6),
          Shadow(color: Color(0x66D4A359), offset: Offset(0, -1), blurRadius: 1),
        ],
      );

  static TextStyle title(double size,
          {TavernThemeDef? theme, Color? color}) =>
      TextStyle(
        fontFamily: headlineFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFF2BE71),
        letterSpacing: 0.8,
        shadows: const [
          Shadow(color: Color(0x99000000), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size,
          {TavernThemeDef? theme, Color? color}) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        color: color ?? theme?.ivory ?? const Color(0xFFF3DED4),
        height: 1.45,
      );

  static TextStyle label(double size,
          {TavernThemeDef? theme, Color? color}) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFF2BE71),
        letterSpacing: 0.8,
      );

  static TextStyle caption({TavernThemeDef? theme, Color? color}) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12.5,
        color: color ?? theme?.outline ?? const Color(0xFF9C8F7F),
      );

  /// Warm key light from upper-left: top-edge highlight + downward occlusion.
  static List<BoxShadow> plaqueShadow(TavernThemeDef t) => [
        const BoxShadow(
            color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 5)),
        BoxShadow(
            color: t.accentLight.withValues(alpha: 0.10),
            blurRadius: 2,
            offset: const Offset(0, -1)),
      ];

  static List<BoxShadow> get insetShadow => const [
        BoxShadow(color: Color(0xB3000000), blurRadius: 8, offset: Offset(0, 3)),
      ];

  static BoxDecoration plaqueDeco(TavernThemeDef t, {double radius = 14}) =>
      BoxDecoration(
        color: t.woodMid,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: t.accentDark.withValues(alpha: 0.45), width: 1.2),
        boxShadow: plaqueShadow(t),
      );

  static BoxDecoration brassRim(TavernThemeDef t, {double radius = 14}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.accentLight, t.accent, t.accentDark],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      );

  static ThemeData appTheme(TavernThemeDef t) {
    final darkText = t.id == 'ivory';
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.woodDeep,
      colorScheme: ColorScheme(
        brightness: darkText ? Brightness.light : Brightness.dark,
        primary: t.accent,
        onPrimary: t.woodDeep,
        secondary: t.accentLight,
        onSecondary: t.woodDeep,
        surface: t.woodMid,
        onSurface: t.ivory,
        error: t.redDisc,
        onError: t.ivory,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        titleLarge: title(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.woodMid),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.accent,
        inactiveTrackColor: t.plaqueDeep,
        thumbColor: t.accentLight,
      ),
    );
  }
}

/// Warm vignette backdrop used across screens.
class TavernBackdrop extends StatelessWidget {
  final Widget child;
  final TavernThemeDef? theme;
  const TavernBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? TavernThemes.byId('classic');
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.35),
          radius: 1.25,
          colors: [t.woodMid, t.woodDeep, t.plaqueDeep],
        ),
      ),
      child: child,
    );
  }
}

/// A wooden plaque button with brass rim (DESIGN.md: carved plaque,
/// brass inlay). Presses physically (dips down on tap).
class PlaqueButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double fontSize;
  final TavernThemeDef? theme;
  const PlaqueButton(
      {super.key,
      required this.label,
      required this.onTap,
      this.fontSize = 20,
      this.theme});

  @override
  State<PlaqueButton> createState() => _PlaqueButtonState();
}

class _PlaqueButtonState extends State<PlaqueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? TavernThemes.byId('classic');
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        padding: const EdgeInsets.all(3),
        decoration: Tavern.brassRim(t, radius: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 28),
          decoration: BoxDecoration(
            color: t.woodMid,
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: enabled
                  ? [t.woodMid, t.woodDeep]
                  : [
                      t.woodMid.withValues(alpha: 0.6),
                      t.woodDeep.withValues(alpha: 0.6)
                    ],
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: Tavern.title(widget.fontSize, theme: t).copyWith(
                color: enabled
                    ? t.accentLight
                    : t.ivory.withValues(alpha: 0.4),
                shadows: const [
                  Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 2),
                      blurRadius: 3)
                ],
              ),
            ),
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
  final TavernThemeDef? theme;
  const BrassLever(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? TavernThemes.byId('classic');
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? t.accentDark : t.plaqueDeep,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
              color: t.accentDark.withValues(alpha: 0.6)),
          boxShadow: Tavern.insetShadow,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accentLight, t.accent, t.accentDark],
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
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
  final TavernThemeDef? theme;
  const TokenButton(
      {super.key,
      required this.icon,
      required this.onTap,
      this.size = 52,
      this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? TavernThemes.byId('classic');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.accentLight, t.accent, t.accentDark],
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.woodMid, t.woodDeep],
            ),
          ),
          child: Icon(icon, color: t.accentLight, size: size * 0.44),
        ),
      ),
    );
  }
}

/// Selectable chip (difficulty, piece style, etc.).
class TavernChip extends StatelessWidget {
  final TavernThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const TavernChip(
      {super.key,
      required this.theme,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? theme.accent.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: Tavern.label(13,
              theme: theme,
              color: selected ? theme.woodDeep : theme.ivory),
        ),
      ),
    );
  }
}

/// A titled wooden card section (menu/settings building block).
class TavernCard extends StatelessWidget {
  final TavernThemeDef theme;
  final String title;
  final Widget child;
  const TavernCard(
      {super.key,
      required this.theme,
      required this.title,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.woodMid.withValues(alpha: 0.9),
            theme.woodDeep.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: theme.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: Tavern.display(20, theme: theme)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
