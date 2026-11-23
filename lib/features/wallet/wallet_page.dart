import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../design/page_footer.dart';
import '../../design/vimi_ui.dart';
import 'coin_pack_grid.dart';
import 'play_coins.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final PlayCoins billing;
  CursorPager<Json>? ledger;
  bool loading = false;
  bool checkingOut = false;
  bool checkingPurchases = false;
  String? selectedId;
  int? shownBalance, shownDebt;
  String? error;
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (!initialized) {
      initialized = true;
      billing = PlayCoins.current!;
      billing.addListener(changed);
      final owner = app.account;
      ledger = CursorPager(
        fetch: (cursor) => app.repo!.ledgerPage(cursor: cursor),
        identity: (row) => row['id'] as String,
        isCurrent: () => app.signedIn && app.account == owner,
      );
      unawaited(load());
    }
    if (shownBalance != app.coins || shownDebt != app.reversalDebt) {
      final previouslyShown = shownBalance != null;
      shownBalance = app.coins;
      shownDebt = app.reversalDebt;
      if (previouslyShown) unawaited(ledger!.refresh());
    }
  }

  void changed() {
    if (mounted) setState(() {});
  }

  Future<void> load() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    final app = VimiScope.of(context);
    try {
      await Future.wait([
        billing.loadCatalog().then((_) => changed()),
        app.refreshWallet(),
        ledger!.refresh(),
      ]);
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    if (initialized) billing.removeListener(changed);
    ledger?.dispose();
    super.dispose();
  }

  bool get purchaseBusy => checkingOut || checkingPurchases || billing.busy;

  Future<void> checkout(String id, int amount) async {
    final app = VimiScope.of(context);
    if (!PlayCoins.enabled || purchaseBusy || !app.signedIn) return;
    final owner = app.account;
    final coins = MaterialLocalizations.of(context).formatDecimal(amount);
    setState(() => checkingOut = true);
    try {
      final detail = billing.products[id] ?? await billing.price(id);
      if (detail == null || !mounted || !app.signedIn || app.account != owner) {
        return;
      }
      final confirmed = await confirmAction(
        context,
        title: 'Add $coins coins?',
        body:
            'This pack costs ${detail.price} through Google Play. '
            'Coins unlock practice packs.',
        action: 'Continue to Google Play',
      );
      if (confirmed && mounted && app.signedIn && app.account == owner) {
        await billing.buy(id);
      }
    } finally {
      if (mounted) setState(() => checkingOut = false);
    }
  }

  Future<void> recoverPurchases() async {
    if (purchaseBusy) return;
    setState(() => checkingPurchases = true);
    try {
      await billing.checkPurchases();
    } finally {
      if (mounted) setState(() => checkingPurchases = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final type = Theme.of(context).textTheme;
    final numbers = MaterialLocalizations.of(context);
    final packs = [
      for (final product in billing.catalog)
        (
          id: product['id'] as String,
          coins: (product['coins'] as num).toInt(),
          price: billing.products[product['id']]?.price,
        ),
    ];
    final selected = packs.where((pack) => pack.id == selectedId).firstOrNull;
    final price = selected?.price;
    final checkoutLabel = switch ((selected, price)) {
      (null, _) => 'Choose a coin pack',
      (_, final String value) => 'Continue · $value',
      _ => 'Check Google Play price',
    };
    return VPage(
      title: 'Coin wallet',
      actions: [
        VIconButton(
          Glyph.refresh,
          label: 'Refresh wallet',
          onPressed: load,
          busy: loading,
        ),
      ],
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _BalanceCard(amount: numbers.formatDecimal(app.coins)),
              if (app.reversalDebt > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ErrorNote(
                    'A reversed Google Play purchase left '
                    '${numbers.formatDecimal(app.reversalDebt)} coins owed. '
                    'New purchases settle this amount before paid packs resume.',
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ErrorNote(error!, onRetry: load),
                ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text('Coin packs', style: type.titleLarge),
              ),
              if (!PlayCoins.enabled)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Purchases are currently unavailable.',
                    style: TextStyle(color: VimiColors.muted),
                  ),
                ),
              const SizedBox(height: 10),
              if (packs.isEmpty && loading)
                Semantics(
                  liveRegion: true,
                  child: const Text('Loading packs…'),
                ),
              CoinPackGrid(
                packs: packs,
                selectedId: selectedId,
                onSelected: !PlayCoins.enabled || purchaseBusy
                    ? null
                    : (id) => setState(() => selectedId = id),
              ),
              if (PlayCoins.enabled && packs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: VButton(
                    checkoutLabel,
                    busy: checkingOut || billing.busy,
                    onPressed: selected == null || purchaseBusy
                        ? null
                        : () => checkout(selected.id, selected.coins),
                  ),
                ),
              ],
              if (PlayCoins.enabled)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: VimiColors.violet,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: purchaseBusy ? null : recoverPurchases,
                    child: Text(
                      checkingPurchases
                          ? 'Checking purchases…'
                          : 'Check pending purchases',
                    ),
                  ),
                ),
              if (billing.status case final status?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      status,
                      style: const TextStyle(color: VimiColors.cyan),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Divider(color: VimiColors.line.withValues(alpha: .32)),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text('Transactions', style: type.titleLarge),
              ),
              const SizedBox(height: 4),
              _WalletLedger(pager: ledger!),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        color: VimiColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VimiColors.violet.withValues(alpha: .36)),
        image: const DecorationImage(
          image: AssetImage('assets/ui/neon-spectrum.webp'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0xCD211039), BlendMode.srcATop),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeType = MediaQuery.textScalerOf(context).scale(16) > 24;
          final artSize = (constraints.maxWidth * (largeType ? .27 : .43))
              .clamp(0.0, 148.0)
              .toDouble();
          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amount,
                        style: type.displaySmall?.copyWith(
                          fontSize: 42,
                          height: 1.05,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('coins available', style: type.labelLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock practice packs.',
                        style: type.bodyMedium?.copyWith(
                          color: VimiColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Image.asset(
                'assets/ui/wallet-coin.webp',
                width: artSize,
                height: artSize,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletLedger extends StatelessWidget {
  const _WalletLedger({required this.pager});

  final CursorPager<Json> pager;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: pager,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pager.loaded && pager.items.isEmpty && pager.error == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const VIcon(Glyph.clock, size: 18, color: VimiColors.violet),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No transactions yet.',
                      style: type.bodyMedium?.copyWith(color: VimiColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          for (final entry in pager.items) ...[
            _LedgerEntry(entry: entry),
            Divider(height: 1, color: VimiColors.line.withValues(alpha: .26)),
          ],
          PageFooter(
            pager: pager,
            moreLabel: 'Earlier transactions',
            loadingLabel: 'Loading transactions…',
          ),
        ],
      ),
    );
  }
}

class _LedgerEntry extends StatelessWidget {
  const _LedgerEntry({required this.entry});

  final Json entry;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final numbers = MaterialLocalizations.of(context);
    final delta = (entry['delta'] as num).toInt();
    final sign = delta > 0
        ? '+'
        : delta < 0
        ? '−'
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry['description'] as String),
                Text(
                  displayDate(DateTime.parse(entry['created_at'] as String)),
                  style: type.bodySmall?.copyWith(color: VimiColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '$sign${numbers.formatDecimal(delta.abs())}',
                textAlign: TextAlign.end,
                style: type.titleMedium?.copyWith(
                  color: delta > 0 ? VimiColors.cyan : VimiColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
