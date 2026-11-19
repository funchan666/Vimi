# Google Play virtual coins

Android package: `com.vimistudio.vimi`. These are planned **one-time consumable products**, not subscriptions. Create the exact IDs in the Vimi app's Google Play Console. IDs are already present in the app and Supabase catalog; they have not been created in Play Console.

| Product ID | Coins | Suggested US price |
| --- | ---: | ---: |
| `vimi_coins_100` | 100 | $0.99 |
| `vimi_coins_350` | 350 | $2.99 |
| `vimi_coins_600` | 600 | $4.99 |
| `vimi_coins_1300` | 1,300 | $9.99 |
| `vimi_coins_2800` | 2,800 | $19.99 |
| `vimi_coins_7500` | 7,500 | $49.99 |
| `vimi_coins_16000` | 16,000 | $99.99 |

Prices above are a proposal only. Configure the purchase option, availability, pricing and eligible countries in Play Console. Keep purchase quantity at one; multi-quantity purchases are intentionally rejected by verification. The app displays only the actual localized `ProductDetails.price` returned by Google Play, never these suggested amounts.

## What coins buy

- Chorus Builder: 120 coins, a four-phrase rehearsal plan and retained drill progress.
- Formation Notes: 180 coins, a group-spacing and transition worksheet with retained progress.
- Comeback Planner: 240 coins, a seven-session cover preparation plan and progress.

Each pack shows its contents before a one-time unlock. An unlocked pack can generate an editable practice note. The basic journal, sharing, follows, messages, reports and blocks stay free. No cash-out, transfer, fake purchase success or charge for contacting dancers.

## Required Play setup

1. Create the app for `com.vimistudio.vimi`, prepare Play App Signing/upload signing and an internal testing release when you authorize a build.
2. Create and activate the seven products and purchase options; configure availability and pricing.
3. Enable Android Publisher API in your Google Cloud project. Grant a dedicated service account the required access to this Play app's purchase/order information and purchase management. Keep the JSON private key only in Supabase Edge Function secrets as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`; never paste it into Dart or chat.
4. Configure license testers and install the build through Google Play's testing track. Ordinary sideloading is not proof that billing works.
5. Configure and operate refund reconciliation with the `reconcile-play` function, including its pagination, and monitor failures. The code supports coin reversal debt; paid pack access pauses until that debt is settled. No reconciliation scheduler has been activated.
6. After server credentials and store products are ready, set `PLAY_BILLING_ENABLED` to `true` in the local build configuration. It is currently `false` and the wallet clearly states that buying coins is unavailable.

The app sets an obfuscated account ID based on the authenticated Vimi user. The server checks that binding, calls Google to verify completed payment, looks up the server coin amount, writes an idempotent credit and only then consumes the token on the server. Unverified purchases are neither acknowledged nor consumed by the client. Retry records are encrypted and filtered by their original account hash. Existing balances come from the server; consumed packs are not restored as new coin purchases.

Current implementation follows [Google's billing security guidance](https://developer.android.com/google/play/billing/security), [purchase status API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/get), [server consumption API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/consume), [voided purchases API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.voidedpurchases/list) and [Flutter's purchase plugin](https://pub.dev/packages/in_app_purchase).

No live or sandbox transaction has been executed. IDs in source alone do not activate purchases.
