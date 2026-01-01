# the_app

A new Flutter project.

## Routing

This app uses named routes via `RouteGenerator.generateRoute`.

- `Routes.store` expects an `int` (or numeric `String`) `storeId` in `arguments`.
	- Example: `Navigator.pushNamed(context, Routes.store, arguments: 12)`
- `Routes.productDetails` expects a `Post` instance in `arguments`.
	- Example: `Navigator.pushNamed(context, Routes.productDetails, arguments: post)`

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
