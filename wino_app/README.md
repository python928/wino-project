# Wino App

Flutter client for the Wino backend.

## Routing

This app uses named routes via `RouteGenerator.generateRoute`.

- `Routes.store` expects an `int` (or `{storeId: int}`) in `arguments`.
- `Routes.productDetails` expects a `Post` instance in `arguments`.
- `Routes.packDetails` expects a `Pack` instance in `arguments`.
- `Routes.searchTab` expects a `{query, type, autoSearch}` map in `arguments`.

## API base URL

Base URLs and paths are centralized in `lib/core/config/api_config.dart`.
`ApiConfig.baseUrl` currently points to `http://192.168.94.21:8000/` for all
platforms. Update it there for local dev/testing.

## Getting Started

```bash
flutter pub get
flutter run
```

Quality checks:

```bash
flutter analyze
flutter test
```
