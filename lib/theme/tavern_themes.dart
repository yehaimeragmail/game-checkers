import 'package:flutter/material.dart';

/// Theme + piece-style catalogs for Checkers — "Tavern Oak & Brass".
///
/// Every theme stays inside the Victorian-parlor material world (real woods,
/// brass/copper/silver, ivory, felt, bakelite). The variety comes from
/// different woods, metal accents, square inlays and disc finishes —
/// never neon, never flat, never generic.
class TavernThemeDef {
  final String id;
  final String name;
  final Color woodDeep; // canvas base, app background
  final Color woodMid; // plaques, raised panels
  final Color plaqueDeep; // recessed wells
  final Color accent; // brass/copper/silver
  final Color accentLight;
  final Color accentDark;
  final Color ivory; // primary text
  final Color outline; // subtle borders, dim text
  final Color felt; // baize under the board
  final Color sqLight;
  final Color sqLightHi;
  final Color sqDark;
  final Color sqDarkLo;
  final Color redDisc;
  final Color redDiscHi;
  final Color redDiscLo;
  final Color blackDisc;
  final Color blackDiscHi;
  final Color blackDiscLo;
  final Color crown; // king crown color

  const TavernThemeDef({
    required this.id,
    required this.name,
    required this.woodDeep,
    required this.woodMid,
    required this.plaqueDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ivory,
    required this.outline,
    required this.felt,
    required this.sqLight,
    required this.sqLightHi,
    required this.sqDark,
    required this.sqDarkLo,
    required this.redDisc,
    required this.redDiscHi,
    required this.redDiscLo,
    required this.blackDisc,
    required this.blackDiscHi,
    required this.blackDiscLo,
    required this.crown,
  });
}

class TavernThemes {
  static const List<TavernThemeDef> all = [
    TavernThemeDef(
      id: 'classic',
      name: 'Classic Tavern',
      woodDeep: Color(0xFF120B07),
      woodMid: Color(0xFF281D17),
      plaqueDeep: Color(0xFF0D0805),
      accent: Color(0xFFF2BE71),
      accentLight: Color(0xFFFFD9A0),
      accentDark: Color(0xFFD4A359),
      ivory: Color(0xFFF3DED4),
      outline: Color(0xFF9C8F7F),
      felt: Color(0xFF1E2B22),
      sqLight: Color(0xFFC89B6A),
      sqLightHi: Color(0xFFD9AE7C),
      sqDark: Color(0xFF5A3A22),
      sqDarkLo: Color(0xFF4A2E1B),
      redDisc: Color(0xFFB3231B),
      redDiscHi: Color(0xFFD9483B),
      redDiscLo: Color(0xFF7E1A14),
      blackDisc: Color(0xFF1A1512),
      blackDiscHi: Color(0xFF3D342C),
      blackDiscLo: Color(0xFF0B0806),
      crown: Color(0xFFD4A359),
    ),
    TavernThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      woodDeep: Color(0xFF2B1009),
      woodMid: Color(0xFF4A1F14),
      plaqueDeep: Color(0xFF1D0A05),
      accent: Color(0xFFF5C86E),
      accentLight: Color(0xFFFFE3A6),
      accentDark: Color(0xFFD4A017),
      ivory: Color(0xFFF8EEDC),
      outline: Color(0xFFB09A80),
      felt: Color(0xFF3D1F2E),
      sqLight: Color(0xFFD8A86E),
      sqLightHi: Color(0xFFE8BC82),
      sqDark: Color(0xFF6E2F1C),
      sqDarkLo: Color(0xFF582412),
      redDisc: Color(0xFFC0392B),
      redDiscHi: Color(0xFFE86A5A),
      redDiscLo: Color(0xFF8E2318),
      blackDisc: Color(0xFF241A14),
      blackDiscHi: Color(0xFF4A3A2E),
      blackDiscLo: Color(0xFF120C08),
      crown: Color(0xFFF5C86E),
    ),
    TavernThemeDef(
      id: 'midnight',
      name: 'Midnight Study',
      woodDeep: Color(0xFF0E1420),
      woodMid: Color(0xFF1C2438),
      plaqueDeep: Color(0xFF090D16),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF8A90A0),
      ivory: Color(0xFFF2EEE4),
      outline: Color(0xFF8B93A3),
      felt: Color(0xFF1B2A4A),
      sqLight: Color(0xFFB9A87E),
      sqLightHi: Color(0xFFCBBD92),
      sqDark: Color(0xFF2C3A55),
      sqDarkLo: Color(0xFF222C44),
      redDisc: Color(0xFFD64545),
      redDiscHi: Color(0xFFF07070),
      redDiscLo: Color(0xFF9E2E2E),
      blackDisc: Color(0xFF141A26),
      blackDiscHi: Color(0xFF333D52),
      blackDiscLo: Color(0xFF080B12),
      crown: Color(0xFFD8DCE6),
    ),
    TavernThemeDef(
      id: 'emerald',
      name: 'Emerald Club',
      woodDeep: Color(0xFF1A2312),
      woodMid: Color(0xFF2E3B22),
      plaqueDeep: Color(0xFF10160B),
      accent: Color(0xFFE8CE7A),
      accentLight: Color(0xFFFFE9A8),
      accentDark: Color(0xFFC9A227),
      ivory: Color(0xFFF5EFE0),
      outline: Color(0xFF9AA08A),
      felt: Color(0xFF0F3D2E),
      sqLight: Color(0xFFCDB37E),
      sqLightHi: Color(0xFFDDC48E),
      sqDark: Color(0xFF3E4F2E),
      sqDarkLo: Color(0xFF314023),
      redDisc: Color(0xFFB03A2E),
      redDiscHi: Color(0xFFD95F52),
      redDiscLo: Color(0xFF7C241C),
      blackDisc: Color(0xFF1E2418),
      blackDiscHi: Color(0xFF3E4632),
      blackDiscLo: Color(0xFF0E120A),
      crown: Color(0xFFE8CE7A),
    ),
    TavernThemeDef(
      id: 'ivory',
      name: 'Ivory & Brass',
      woodDeep: Color(0xFFC9B586),
      woodMid: Color(0xFFEFE3C8),
      plaqueDeep: Color(0xFFB39D6E),
      accent: Color(0xFF9A7B1E),
      accentLight: Color(0xFFD4AF37),
      accentDark: Color(0xFF6E5514),
      ivory: Color(0xFF2E2118),
      outline: Color(0xFF7A6A52),
      felt: Color(0xFF2E5A44),
      sqLight: Color(0xFFFBF6E9),
      sqLightHi: Color(0xFFFFFFFF),
      sqDark: Color(0xFF8A6B3E),
      sqDarkLo: Color(0xFF75582F),
      redDisc: Color(0xFFA31621),
      redDiscHi: Color(0xFFC9404D),
      redDiscLo: Color(0xFF700F16),
      blackDisc: Color(0xFF2A2119),
      blackDiscHi: Color(0xFF52463A),
      blackDiscLo: Color(0xFF14100B),
      crown: Color(0xFF9A7B1E),
    ),
    TavernThemeDef(
      id: 'cherry',
      name: 'Cherry Parlor',
      woodDeep: Color(0xFF381408),
      woodMid: Color(0xFF5A2A1A),
      plaqueDeep: Color(0xFF260D05),
      accent: Color(0xFFDFC084),
      accentLight: Color(0xFFF5DDA6),
      accentDark: Color(0xFFB08D3E),
      ivory: Color(0xFFF7EFE0),
      outline: Color(0xFFB69A80),
      felt: Color(0xFF4A2E3F),
      sqLight: Color(0xFFD9A86E),
      sqLightHi: Color(0xFFE9BC82),
      sqDark: Color(0xFF7C3F24),
      sqDarkLo: Color(0xFF66311A),
      redDisc: Color(0xFFC0392B),
      redDiscHi: Color(0xFFE06655),
      redDiscLo: Color(0xFF86241A),
      blackDisc: Color(0xFF221610),
      blackDiscHi: Color(0xFF46352A),
      blackDiscLo: Color(0xFF100A06),
      crown: Color(0xFFDFC084),
    ),
    TavernThemeDef(
      id: 'copper',
      name: 'Walnut & Copper',
      woodDeep: Color(0xFF241309),
      woodMid: Color(0xFF3B2416),
      plaqueDeep: Color(0xFF170C05),
      accent: Color(0xFFE09E5A),
      accentLight: Color(0xFFF5C48E),
      accentDark: Color(0xFFB87333),
      ivory: Color(0xFFF5EFE0),
      outline: Color(0xFFA08A70),
      felt: Color(0xFF3F2B1F),
      sqLight: Color(0xFFC89B6A),
      sqLightHi: Color(0xFFD9AE7C),
      sqDark: Color(0xFF5C3A21),
      sqDarkLo: Color(0xFF4C2E18),
      redDisc: Color(0xFFA31621),
      redDiscHi: Color(0xFFCC3A44),
      redDiscLo: Color(0xFF6E0F16),
      blackDisc: Color(0xFF1A1512),
      blackDiscHi: Color(0xFF3D342C),
      blackDiscLo: Color(0xFF0B0806),
      crown: Color(0xFFE09E5A),
    ),
    TavernThemeDef(
      id: 'lodge',
      name: 'Forest Lodge',
      woodDeep: Color(0xFF26201A),
      woodMid: Color(0xFF3E3226),
      plaqueDeep: Color(0xFF191410),
      accent: Color(0xFFE8CE7A),
      accentLight: Color(0xFFFFE9A8),
      accentDark: Color(0xFFC9A227),
      ivory: Color(0xFFF1EAD8),
      outline: Color(0xFF9A8F76),
      felt: Color(0xFF2F4A2A),
      sqLight: Color(0xFFC9A86E),
      sqLightHi: Color(0xFFD9BC82),
      sqDark: Color(0xFF4A3D28),
      sqDarkLo: Color(0xFF3B301F),
      redDisc: Color(0xFFB03A2E),
      redDiscHi: Color(0xFFD95F52),
      redDiscLo: Color(0xFF7C241C),
      blackDisc: Color(0xFF23201A),
      blackDiscHi: Color(0xFF464134),
      blackDiscLo: Color(0xFF12100C),
      crown: Color(0xFFE8CE7A),
    ),
    TavernThemeDef(
      id: 'cellar',
      name: 'Burgundy Cellar',
      woodDeep: Color(0xFF1C0E12),
      woodMid: Color(0xFF33202A),
      plaqueDeep: Color(0xFF120810),
      accent: Color(0xFFD9A441),
      accentLight: Color(0xFFF2C96E),
      accentDark: Color(0xFFA67C2E),
      ivory: Color(0xFFF3E4D8),
      outline: Color(0xFF9A8577),
      felt: Color(0xFF40232B),
      sqLight: Color(0xFFC79A6C),
      sqLightHi: Color(0xFFD7AC7E),
      sqDark: Color(0xFF572E3A),
      sqDarkLo: Color(0xFF46242E),
      redDisc: Color(0xFF9E2B25),
      redDiscHi: Color(0xFFC95046),
      redDiscLo: Color(0xFF6B1B17),
      blackDisc: Color(0xFF201318),
      blackDiscHi: Color(0xFF45303A),
      blackDiscLo: Color(0xFF0F090D),
      crown: Color(0xFFD9A441),
    ),
  ];

  static TavernThemeDef byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);

  /// Free tier keeps the signature 'classic' tavern; the other 8 themes are
  /// the Pro set.
  static const freeThemeId = 'classic';
  static bool isProTheme(String id) => id != freeThemeId;
}

/// Piece styles — physical disc finishes, all tavern-appropriate.
class PieceStyles {
  /// Free tier: the first two finishes. The rest are Pro.
  static const freeStyleCount = 2;
  static bool isProStyle(int index) => index >= freeStyleCount;
  static const names = [
    'Bakelite',
    'Turned Wood',
    'Brass Ring',
    'Ivory',
    'Marble',
  ];
  static const descriptions = [
    'Glossy vintage bakelite discs',
    'Matte turned-wood discs',
    'Dark discs with a brass inlay ring',
    'Pale carved-ivory discs',
    'Swirled glass-marble discs',
  ];
}
