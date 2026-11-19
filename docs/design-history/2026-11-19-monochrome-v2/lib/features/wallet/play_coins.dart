import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../core/app_controller.dart';
import '../../core/models.dart';

class PlayCoins extends ChangeNotifier {
  PlayCoins(this.app) {
    current = this;
    if (Platform.isAndroid) {
      subscription = InAppPurchase.instance.purchaseStream.listen(
        (purchases) {
          _events = _events.then((_) => handle(purchases)).catchError((
            Object _,
          ) {
            status =
                'Your purchase is saved for verification. Try checking pending purchases.';
            notifyListeners();
          });
        },
        onError: (Object _) {
          status =
              'Google Play could not complete this request. Please try again.';
          notifyListeners();
        },
      );
    }
    app.addListener(accountChanged);
    unawaited(retryPending());
  }
  static PlayCoins? current;
  static const enabled = bool.fromEnvironment(
    'PLAY_BILLING_ENABLED',
    defaultValue: false,
  );
  static const store = FlutterSecureStorage();
  static const queueKey = 'vimi.play.pending.v1';
  final AppController app;
  StreamSubscription<List<PurchaseDetails>>? subscription;
  Future<void> _events = Future.value();
  Future<void> _queueWork = Future.value();
  final Map<String, ProductDetails> products = {};
  List<Json> catalog = [];
  bool busy = false, retrying = false;
  String? status;
  String get accountHash => sha256.convert(utf8.encode(app.account)).toString();
  void accountChanged() {
    if (app.signedIn) unawaited(retryPending());
  }

  Future<void> loadCatalog() async {
    if (catalog.isEmpty)
      catalog = jsonRows(
        jsonDecode(
          await rootBundle.loadString('assets/data/coin_products.json'),
        ),
      );
  }

  Future<ProductDetails?> price(String id) async {
    if (!enabled) {
      status = 'Coin purchases are not available yet.';
      notifyListeners();
      return null;
    }
    if (!app.signedIn || busy) return null;
    busy = true;
    status = null;
    notifyListeners();
    try {
      if (!await InAppPurchase.instance.isAvailable()) {
        status = 'Google Play is unavailable on this device.';
        return null;
      }
      final response = await InAppPurchase.instance.queryProductDetails({id});
      if (response.error != null || response.productDetails.isEmpty) {
        status = 'This coin pack is currently unavailable in Google Play.';
        return null;
      }
      products[id] = response.productDetails.first;
      return products[id];
    } catch (_) {
      status = 'The price could not be loaded. Please try again.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> buy(String id) async {
    if (busy || !app.signedIn || !enabled) return;
    final product = products[id] ?? await price(id);
    if (product == null) return;
    busy = true;
    status = null;
    notifyListeners();
    try {
      final launched = await InAppPurchase.instance.buyConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: product,
          applicationUserName: accountHash,
        ),
        autoConsume: false,
      );
      if (!launched) {
        busy = false;
        status = 'Google Play could not open checkout. Please try again.';
      }
    } catch (_) {
      busy = false;
      status = 'The purchase could not be started. Please try again.';
    }
    notifyListeners();
  }

  Future<List<Json>> queue() async {
    final raw = await store.read(key: queueKey);
    return raw == null ? [] : jsonRows(jsonDecode(raw));
  }

  Future<void> saveQueue(List<Json> entries) =>
      store.write(key: queueKey, value: jsonEncode(entries));
  Future<void> editQueue(void Function(List<Json>) edit) {
    final next = _queueWork.then((_) async {
      final entries = await queue();
      edit(entries);
      await saveQueue(entries);
    });
    _queueWork = next.catchError((Object _) {});
    return next;
  }

  Future<void> handle(List<PurchaseDetails> purchases) async {
    await loadCatalog();
    for (final purchase in purchases) {
      if (!catalog.any((p) => p['id'] == purchase.productID)) continue;
      if (purchase.status == PurchaseStatus.pending) {
        busy = false;
        status =
            'Payment is pending in Google Play. Coins appear after confirmation.';
        notifyListeners();
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        busy = false;
        status = 'Purchase canceled.';
        notifyListeners();
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        busy = false;
        status =
            'Google Play could not complete this purchase. No coins have been added.';
        notifyListeners();
        continue;
      }
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored)
        continue;
      final hash = purchase is GooglePlayPurchaseDetails
          ? purchase.billingClientPurchase.obfuscatedAccountId
          : null;
      final token = purchase.verificationData.serverVerificationData;
      if (hash == null || token.isEmpty) {
        busy = false;
        status =
            'This purchase could not be linked to a Vimi account. Contact the publisher through Google Play.';
        notifyListeners();
        continue;
      }
      await editQueue((entries) {
        if (!entries.any((e) => e['token'] == token)) {
          entries.add({
            'product': purchase.productID,
            'token': token,
            'account_hash': hash,
          });
        }
      });
      busy = false;
    }
    await retryPending();
    notifyListeners();
  }

  Future<void> retryPending() async {
    if (retrying || !app.signedIn || !Platform.isAndroid) return;
    retrying = true;
    try {
      final owner = app.account, hash = accountHash;
      final entries = await queue();
      for (final entry
          in entries.where((e) => e['account_hash'] == hash).toList()) {
        if (owner != app.account) break;
        try {
          final response = await app.repo!.client.functions.invoke(
            'verify-play-purchase',
            body: {
              'product_id': entry['product'],
              'purchase_token': entry['token'],
            },
          );
          final result = jsonMap(response.data);
          if (result['credited'] == true && result['consumed'] == true) {
            // The server consumes only after a durable credit. Consumption also acknowledges it.
            // Never acknowledge or consume an unverified purchase on the client.
            await editQueue(
              (latest) =>
                  latest.removeWhere((e) => e['token'] == entry['token']),
            );
            status = 'Coins added to your wallet.';
            await app.refreshWallet();
          } else {
            status =
                'Your purchase is awaiting verification. Check again shortly.';
          }
        } catch (_) {
          status =
              'Your purchase is saved and awaiting verification. Check again when connected.';
        }
      }
    } catch (_) {
      status =
          'Pending purchases could not be opened. Your payment has not been discarded.';
    } finally {
      retrying = false;
      busy = false;
      notifyListeners();
    }
  }

  Future<void> checkPurchases() async {
    if (!enabled || !app.signedIn) return;
    try {
      await InAppPurchase.instance.restorePurchases(
        applicationUserName: accountHash,
      );
      await retryPending();
    } catch (_) {
      status = 'Google Play could not check purchases. Please try again.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    app.removeListener(accountChanged);
    subscription?.cancel();
    if (current == this) current = null;
    super.dispose();
  }
}
