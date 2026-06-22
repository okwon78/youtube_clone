# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get              # install dependencies
flutter run                  # run on a connected device/emulator
flutter analyze              # static analysis / lint (flutter_lints ruleset)
flutter test                 # run all tests
flutter test test/widget_test.dart --plain-name 'name'   # run a single test by name
flutter build apk            # release Android build
flutter build ios            # release iOS build
```

Firebase config is managed via FlutterFire; regenerate `lib/firebase_options.dart` with `flutterfire configure` (project id `obiwan-youtube-clone`).

## Architecture

Flutter app on Dart SDK `^3.12.2`. Note: despite the `youtube_clone` package name, the app currently renders a **garage-sale product grid**, not a YouTube clone — treat the name as historical.

State management is **Riverpod** (`flutter_riverpod` v3). The dependency flow is:

- `lib/main.dart` — boots `WidgetsFlutterBinding`, awaits `Firebase.initializeApp`, then wraps the app in a `ProviderScope`. Firebase Core + Auth are initialized but not yet used by any feature.
- `lib/providers/` — Riverpod providers are the data layer. `productListProvider` is a synchronous `Provider` returning static `Product` data; it's intentionally structured so it can later be swapped for async loading (e.g. `FutureProvider` backed by Firebase) without changing consumers.
- `lib/pages/` — screens are `ConsumerWidget`s that `ref.watch` providers. `HomePage` watches `productListProvider` and renders a `GridView`.
- `lib/models/` — plain immutable data classes (`Product`).

When adding features, follow this layering: define/extend a model, expose data through a provider, and consume it from a `ConsumerWidget`. To make data dynamic, replace the provider implementation rather than reaching for Firebase directly in widgets.

## Conventions

- UI strings and code comments are frequently written in **Korean** — match the existing language of the surrounding code.
- Lints come from `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`); `build/**` is excluded from analysis.
