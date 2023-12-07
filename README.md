# kanpai_mobile

iOS client for kanpai and other AI utils

you need to make `lib/secrets.dart`:

```dart
const openAiApiKey = "sk-...";
const openAiOrgId = "org-...";
```

build adhoc ipa:

```shell
flutter build ipa --export-method ad-hoc
```

rename the ipa to zip and unzip

then XCode -> Window -> Devices & Simulators -> phone -> Add the .app file

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
