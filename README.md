# App 4: Focus

Focus is a study timer built with Flutter. Pick a tree, start a focus session,
and unlock new trees as your total focused time grows. Finished sessions are
saved to the cloud, so your progress comes back when you reopen the app.

## Features

- **Landing page** with a live total of hours focused so far.
- **Tree picker** with several trees. Each one unlocks after a set amount of
  focus time, starting with a free Focus Sprout.
- **Focus timer** that defaults to 25 minutes. You can change the length from
  1 to 240 minutes, and pause or reset at any time.
- **Cloud saving** with Cloud Firestore. A finished session stores its minutes
  and finish time. The app reads them back to show total hours and unlock trees.
- **Task list** in a side panel on the focus timer screen. Tap the checklist
  icon in the top bar to slide it open, add, check off or delete tasks while the
  timer keeps running, then close it. Tasks live in memory, so they reset when
  the app restarts.

## Getting started

1. Install Flutter and Android Studio with the Flutter and Dart plugins.
2. Clone the repository and install packages:

   ```sh
   git clone https://github.com/Sauz21/app4.git
   cd app4
   git switch main && git pull && flutter pub get
   ```

3. Start an emulator or connect a phone, then run:

   ```sh
   flutter run
   ```

The app runs fine without Firebase keys. It just won't save sessions, so the
hours total stays at zero. That is expected.

Run `flutter doctor` if your setup needs troubleshooting. Use a Flutter SDK
that includes Dart 3.13.1 or newer within Dart 3, as required by `pubspec.yaml`.

### Running with Firebase saving

Firebase keys are never committed to this repo. Whoever has the keys keeps them
in a local `.env` file and runs:

```sh
flutter run --dart-define-from-file=.env
```

`lib/firebase_options.dart` reads each API key with `String.fromEnvironment`.
Never run `flutterfire configure`, never commit `.env`, and never commit a
string that starts with `AIza`.

## Project structure

- `lib/main.dart`: app entry, Firebase startup (skipped when there are no keys), and the landing page.
- `lib/tree_picker.dart`: tree catalog, unlock progress, the tree picker screen, and the focus timer screen.
- `lib/tasks.dart`: the task list store and the side panel opened from the focus timer.
- `lib/session_store.dart`: saves finished sessions and reads back total minutes. It does nothing when Firebase isn't set up, so tests run without keys.
- `lib/firebase_options.dart`: Firebase project config. API keys come from the environment.
- `test/`: Flutter widget tests.
- `.github/workflows/main.yml`: CI that runs `flutter pub get`, `flutter test` and builds an APK.
- `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`: standard Flutter platform files.

Firestore rules only accept sessions with the fields `minutes` and `finishedAt`.
Ask Kenny before saving any other fields.

## Working together

1. Branch off an updated `main`:

   ```sh
   git switch main
   git pull --ff-only
   git switch -c feature/your-feature-name
   ```

2. Add a test for anything you build.
3. Before pushing, run:

   ```sh
   flutter analyze && flutter test
   ```

4. Push your branch and open a pull request into `main`. Wait for the green
   check, then merge.

Rules that keep CI working:

- Never push straight to `main`.
- CI only runs on pull requests into `main` that have no merge conflicts. If
  yours conflicts, run `git pull origin main`, fix it, and push.
- Don't push again while your pull request's build is running. It cancels the
  build, and cancelled builds don't count.

Build output, local SDK paths, and personal IDE settings are excluded from Git.
