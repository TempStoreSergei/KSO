# Repository Guidelines

## Project Structure & Modules
- Flutter app entry and UI live in `lib/` (widgets, state, services).
- Platform shells: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`; keep platform-specific tweaks inside respective directories.
- Assets (images/fonts) are in `assets/` and declared in `pubspec.yaml`; avoid hardcoding asset paths.
- Tests belong in `test/` mirroring `lib/` structure for easy discovery; generated builds stay out of version control.

## Build, Test, and Development Commands
- Install deps: `flutter pub get`.
- Static analysis: `flutter analyze` (uses `analysis_options.yaml` with `flutter_lints`).
- Format: do **not** run `dart format` automatically; only run it when explicitly requested.
- Run unit/widget tests: `flutter test`.
- Run the app: `flutter run -d <device>`; add `--dart-define` for runtime config when needed.
- Build release bundles: `flutter build apk` (Android), `flutter build ios` (iOS), `flutter build web` (Web). Use matching platform directory for further signing steps.

## Coding Style & Naming Conventions
- Follow Dart style with `flutter_lints`; prefer descriptive class names (`BookingCard`, `RoomFilterState`).
- Use lower_snake_case for files (`booking_card.dart`), lowerCamelCase for variables/functions, UpperCamelCase for classes.
- Keep widgets small and composable; move shared styles/constants into dedicated files in `lib/`.
- Avoid printing in production code; use logging or proper error handling.

## Testing Guidelines
- Name tests after behavior, e.g., `booking_card_test.dart` in `test/widgets/`.
- Cover new logic with widget or unit tests; include edge cases and null/empty inputs.
- Run `flutter test` locally before opening a PR; ensure deterministic tests (no network/filesystem writes without mocks).
- После любых изменений обязательно прогонять статический анализ `flutter analyze` (flutter analytics) и устранять предупреждения до публикации PR.

## Commit & Pull Request Guidelines
- Commit messages follow short, present-tense summaries (seen history: `freeze`, `clean`, `step`); keep scope tight per commit.
- PRs should list changes, affected screens/flows, and any `--dart-define` keys needed for local runs.
- Attach screenshots or screen recordings for UI changes (per platform touched) and note any new dependencies or migrations.
- Link issues/requirements when available; request review only after analysis, formatting, and tests pass.
