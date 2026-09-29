# KiranaSmart

Offline-first Flutter Android app for small general stores.

## Stack
- Flutter/Dart
- Hive CE for local persistence
- ChangeNotifier + InheritedNotifier for lightweight reactive state
- `url_launcher` for WhatsApp billing
- `intl` for INR/date formatting

Current package versions are pinned to the stable versions checked on 2026-09-29.

## Create/run
1. Install Flutter 3.44+ / Dart 3.12+.
2. Create a blank Flutter project:
   `flutter create kirana_smart`
3. Replace `pubspec.yaml` and the `lib/` directory with this archive.
4. Run:
   `flutter pub get`
   `flutter analyze`
   `flutter test`
   `flutter run`

## Architecture
`presentation -> AppController -> Repository -> HiveDatabase -> Hive CE`

All business data is local. No internet connection is required for inventory, POS, khata or reports. WhatsApp requires the device to have WhatsApp or a browser capable of opening the generated `wa.me` URL.

## Data model
- Product: inventory and prices
- Customer: name/phone
- Sale + SaleLine: immutable sales history
- KhataEntry: credit/payment ledger
- AppSettings: store name and default low-stock threshold

Money is stored as `double` for readability in this starter. For a strict accounting implementation, migrate monetary values to integer paise before production rollout.

## Important production hardening
Hive CE is excellent for an offline-first local app, but this sample keeps the repository intentionally compact. Before a large deployment, add:
- encrypted Hive boxes with a securely stored key
- export/import backup
- automated backup/versioning
- audit log
- stock adjustment ledger
- integer paise money representation
- repository-level crash recovery/journaling for multi-record sale commits
- tests for concurrent/repeated checkout
- app lock/PIN if required

## WhatsApp
Bills use:
`https://wa.me/<international_number>?text=<encoded_invoice>`

Indian numbers are normalized to `91XXXXXXXXXX` when the user enters a 10-digit number.
