# Contributing

Thank you for helping improve FlutterGuard.

## Development setup

1. Install [Flutter 3.44.0](https://docs.flutter.dev/release/archive) (Dart 3.12).
2. Clone this repository.
3. From the package root:

```bash
flutter pub get
cd example && flutter pub get && cd ..
flutter analyze
flutter test
cd example && flutter test
```

## Project structure

```text
lib/flutter_guard.dart     Public exports
lib/src/                   Implementation
example/                   Runnable demo of every module
test/                      Package tests
```

Do not export new types from `lib/flutter_guard.dart` unless they are part of
the supported public API.

## Branch strategy

* `main` is the release branch.
* Use short-lived feature branches.
* Open a pull request for review.

## Coding standards

* Dart 3.12 null safety and the package `analysis_options.yaml`.
* Document every public member with dartdoc.
* Keep FlutterGuard architecture-agnostic. Do not add GetX, Bloc, Riverpod,
  Provider, or MobX as dependencies.
* Prefer adapters over new runtime dependencies.

## Testing

Add tests with every behavior change.

Required coverage for network changes:

* success and failure paths
* cancellation
* retries
* token refresh concurrency when auth is involved

Run:

```bash
flutter test
cd example && flutter test
```

## Pull requests

* Keep the README, example, and public API synchronized.
* Update `CHANGELOG.md`.
* If you add a configuration field, add it to `ConfigCatalog` and the README
  table in the same pull request.

## Commit expectations

Write commits that explain why the change exists. One logical change per
commit is preferred.

## Documentation requirements

Code examples in `README.md` must compile against the public API in the same
commit. Do not invent methods or configuration fields.
