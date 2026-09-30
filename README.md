# App 4

Group project starter built with Flutter and developed in Android Studio.
The app idea is still being decided. This first commit contains the standard
Flutter counter app and project structure so everyone can get started.

## Getting started

1. Install Flutter and Android Studio with the Flutter and Dart plugins.
2. Clone the repository:

   ```sh
   git clone https://github.com/Sauz21/app4.git
   cd app4
   flutter pub get
   ```

3. Open the `app4` folder in Android Studio (the folder containing `pubspec.yaml`).
4. Start an Android emulator or connect an Android phone with USB debugging enabled.
5. Select the device and run `lib/main.dart`.

Run `flutter doctor` if your local setup needs troubleshooting. Use a Flutter SDK
that includes Dart 3.13.1 or newer within Dart 3, as required by `pubspec.yaml`.

## Project structure

- `lib/main.dart`: app entry point and starter screen.
- `test/`: Flutter tests.
- `android/`: Android project configuration.
- `ios/`, `web/`, `macos/`, `windows/`, `linux/`: standard Flutter platform files.
- `pubspec.yaml`: dependencies and app settings.

## Working together

Accept your GitHub collaborator invitation before pushing changes. Start each
piece of work from an updated `main` branch:

```sh
git switch main
git pull --ff-only
git switch -c feature/your-feature-name
```

Commit and push your branch, then open a pull request into `main` for the group
to review. Replace `your-feature-name` with a short name for your change.

Before opening a pull request, run:

```sh
flutter analyze
flutter test
```

Build output, local SDK paths, and personal IDE settings are excluded from Git.
