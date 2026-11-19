import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../design/vimi_ui.dart';
import 'play_coins.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final PlayCoins billing;
  Future<List<Json>>? ledger;
  String? error;
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      billing = PlayCoins.current!;
      billing.addListener(changed);
      unawaited(load());
    }
  }

  void changed() {
    if (mounted) setState(() {});
  }

  Future<void> load() async {
    try {
      final app = VimiScope.of(context);
      await billing.loadCatalog();
      await app.refreshWallet();
      if (mounted) setState(() => ledger = app.repo!.ledger());
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    }
  }

  @override
  void dispose() {
    if (initialized) billing.removeListener(changed);
    super.dispose();
  }

  Future<void> choose(String id, int amount) async {
    final detail = billing.products[id] ?? await billing.price(id);
    if (detail == null || !mounted) return;
    if (await confirmAction(
          context,
          title: 'Add $amount coins?',
          body:
              'Google Play price: ${detail.price}. Coins unlock Vimi practice packs; basic social features stay free.',
          action: 'Continue · ${detail.price}',
        ) &&
        mounted)
      await billing.buy(id);
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: 'Your coin wallet',
      actions: [
        VIconButton(Glyph.refresh, label: 'Refresh wallet', onPressed: load),
      ],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const VIcon(Glyph.coin, size: 40, color: VimiColors.cyan),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${app.coins}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'For practice packs that stay with your account. Following, messaging, reporting and blocking are free.',
          ),
          const SizedBox(height: 24),
          if (app.reversalDebt > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ErrorNote(
                '${app.reversalDebt} coins are owed after a reversed Google Play purchase. New coin purchases settle this amount first; paid packs resume when it is settled.',
              ),
            ),
          if (!PlayCoins.enabled)
            const SurfacePanel(
              child: Text(
                'Coin purchases are not available yet. You can keep using the community and your practice journal.',
              ),
            ),
          if (error != null) ErrorNote(error!, onRetry: load),
          if (billing.status != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Semantics(liveRegion: true, child: Text(billing.status!)),
            ),
          const SizedBox(height: 16),
          for (final product in billing.catalog)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfacePanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${product['coins']} coins',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    VButton(
                      billing.products[product['id']]?.price ?? 'Check price',
                      quiet: true,
                      busy: billing.busy,
                      onPressed: !PlayCoins.enabled || billing.busy
                          ? null
                          : () => choose(
                              product['id'] as String,
                              (product['coins'] as num).toInt(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          VButton(
            'Check pending purchases',
            quiet: true,
            onPressed: PlayCoins.enabled ? billing.checkPurchases : null,
          ),
          const Text(
            'Your existing coin balance is tied to your Vimi account. Consumed coin packs are not restored as another purchase.',
            style: TextStyle(color: VimiColors.muted),
          ),
          const SizedBox(height: 32),
          Text('Your ledger', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          FutureBuilder<List<Json>>(
            future: ledger,
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return ErrorNote(readableError(snapshot.error!), onRetry: load);
              final entries = snapshot.data;
              if (entries == null) return const Text('Opening your ledger…');
              if (entries.isEmpty)
                return const Text(
                  'Coin purchases and pack unlocks will appear here.',
                );
              return Column(
                children: entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['description'] as String),
                                  Text(
                                    displayDate(
                                      DateTime.parse(e['created_at'] as String),
                                    ),
                                    style: const TextStyle(
                                      color: VimiColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(e['delta'] as num) > 0 ? '+' : ''}${e['delta']}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
