import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../checkers_theme.dart';
import '../services/iap_service.dart';
import '../services/tavern_audio.dart';
import '../services/tavern_settings.dart';
import '../theme/tavern_themes.dart';

/// Checkers PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
///
/// Products (created by Wajiha in Play Console):
/// - `checkerspro` — one-time non-consumable Pro unlock.
/// - `checkerscoffee` / `checkerschocolate` — consumable tips.
class ProScreen extends StatefulWidget {
  final TavernAudio audio;
  final TavernSettings settings;
  final CheckersStore store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  TavernThemeDef get _t => TavernThemes.byId(widget.settings.themeId);

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: Tavern.body(15, theme: _t)),
          backgroundColor: _t.woodDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Tavern.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return TavernBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Checkers PRO', style: Tavern.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  // Tips are Android-only: hidden on iOS (App Store).
                  if (defaultTargetPlatform != TargetPlatform.iOS) ...[
                    const SizedBox(height: 16),
                    _TipsCard(
                      theme: t,
                      store: store,
                      audio: widget.audio,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final TavernThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete Checkers game', true, true),
      ('All official rules', true, true),
      ('Easy & Medium bots', true, true),
      ('2-player pass-and-play', true, true),
      ('Renameable players', true, true),
      ('Music & sound effects', true, true),
      ('Tavern themes', '1', '9'),
      ('Disc styles', '2', '5'),
      ('Hard bot mode', false, true),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.woodMid.withValues(alpha: 0.85),
            theme.woodDeep.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Column(
        children: [
          Text('Free vs PRO', style: Tavern.display(20, theme: theme)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: Tavern.body(13,
                theme: theme,
                color: theme.ivory.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: Tavern.label(12, theme: theme),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: Tavern.label(12, theme: theme),
                      textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(r.$1, style: Tavern.body(13, theme: theme)),
                  ),
                  Expanded(flex: 2, child: _Cell(value: r.$2, theme: theme)),
                  Expanded(flex: 2, child: _Cell(value: r.$3, theme: theme)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.accent.withValues(alpha: 0.25),
                  border: Border.all(color: theme.accentLight),
                ),
                child: Text('✦ PRO ACTIVE ✦',
                    style: Tavern.label(14, theme: theme)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  final TavernThemeDef theme;
  const _Cell({required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final v = value as bool;
      return Text(
        v ? '✓' : '—',
        style: Tavern.body(15,
            theme: theme,
            color: v
                ? theme.accentLight
                : theme.ivory.withValues(alpha: 0.4)),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      value as String,
      style: Tavern.label(12, theme: theme),
      textAlign: TextAlign.center,
    );
  }
}

// ---------------------------------------------------------------------------
class _BuyCard extends StatelessWidget {
  final TavernThemeDef theme;
  final TavernSettings settings;
  final CheckersStore store;
  final TavernAudio audio;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final pro = store.proProduct;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.woodMid.withValues(alpha: 0.85),
            theme.woodDeep.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Column(
        children: [
          Text('Unlock PRO', style: Tavern.display(20, theme: theme)),
          const SizedBox(height: 8),
          if (settings.isPro)
            Text(
              'You own Checkers PRO — everything is unlocked.',
              style: Tavern.body(14, theme: theme),
              textAlign: TextAlign.center,
            )
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Tavern.body(14,
                  theme: theme,
                  color: theme.ivory.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            )
          else ...[
            Text(
              'All 9 tavern themes, all 5 disc styles,\nand the Hard bot — forever.',
              style: Tavern.body(14, theme: theme),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, inProgress, _) => PlaqueButton(
                label: inProgress
                    ? 'Working…'
                    : 'Unlock PRO — ${pro?.price ?? ''}',
                fontSize: 17,
                theme: theme,
                onTap: inProgress
                    ? null
                    : () {
                        audio.click();
                        store.buyPro();
                      },
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: store.purchaseError,
              builder: (_, err, _) => err == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(err,
                          style: Tavern.body(13,
                              theme: theme,
                              color: Colors.red.shade300),
                          textAlign: TextAlign.center),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                audio.click();
                store.restore();
              },
              child: Text('Restore purchases',
                  style: Tavern.body(14,
                      theme: theme, color: theme.accentLight)),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _TipsCard extends StatelessWidget {
  final TavernThemeDef theme;
  final CheckersStore store;
  final TavernAudio audio;
  const _TipsCard({
    required this.theme,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.woodDeep.withValues(alpha: 0.65),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text('Tip jar', style: Tavern.display(20, theme: theme)),
          const SizedBox(height: 8),
          Text(
            'Checkers is 100% free. A small tip keeps the tavern open!',
            style: Tavern.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Tavern.body(13,
                  theme: theme,
                  color: theme.ivory.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            )
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  TavernChip(
                    theme: theme,
                    label: p.id == CheckersStore.chocolateId
                        ? '🍫 ${p.price}'
                        : '☕ ${p.price}',
                    selected: false,
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
