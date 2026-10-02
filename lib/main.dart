import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'session_store.dart';
import 'tree_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options.apiKey.isEmpty) {
    debugPrint('No Firebase key: run with --dart-define-from-file=.env');
  } else {
    await Firebase.initializeApp(options: options);
  }
  runApp(const MyApp());
}

const ink = Color(0xFF172B35);
const teal = Color(0xFF087F70);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Focus',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      colorScheme: ColorScheme.fromSeed(seedColor: teal),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
    ),
    home: const LandingPage(),
  );
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.filter_center_focus_rounded,
                      color: teal,
                      size: 32,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'focus',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'A little less distraction.',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 750;
                    final intro = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEEEE9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'MAKE ROOM FOR WHAT MATTERS',
                            style: TextStyle(
                              color: teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Big ideas.\nSmall steps.\nClear mind.',
                          style: TextStyle(
                            fontSize: compact ? 48 : 68,
                            height: 1.06,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Find your rhythm, tune out the noise, and give your next great idea a little space.',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.65,
                            color: Color(0xFF60727C),
                          ),
                        ),
                        const SizedBox(height: 30),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TreePicker(),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: teal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 22,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          label: const Text(
                            'Start focusing',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          iconAlignment: IconAlignment.end,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'One task. Your pace. You’ve got this.',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<int>(
                          stream: totalMinutes(),
                          builder: (context, snap) => Text(
                            '${((snap.data ?? 0) / 60).toStringAsFixed(1)} hours focused so far',
                            style: const TextStyle(
                              color: teal,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
                    const preview = _Preview();
                    return compact
                        ? Column(
                            children: [
                              intro,
                              const SizedBox(height: 40),
                              preview,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: intro),
                              const SizedBox(width: 70),
                              const Expanded(child: preview),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 64),
                const Divider(color: Color(0xFFDDE5E9)),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const features = [
                      _Feature(
                        Icons.center_focus_strong_rounded,
                        'Find your focus',
                        'Make space for one thing at a time.',
                      ),
                      _Feature(
                        Icons.timer_outlined,
                        'Build your rhythm',
                        'Turn your study time into real progress.',
                      ),
                      _Feature(
                        Icons.spa_outlined,
                        'Keep it simple',
                        'Less setup. More getting started.',
                      ),
                    ];
                    return constraints.maxWidth < 700
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: features,
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: features
                                .map((f) => Expanded(child: f))
                                .toList(),
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: ink.withValues(alpha: 0.15),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    ),
    child: Column(
      children: [
        const Row(
          children: [
            Icon(Icons.wb_sunny_outlined, color: Color(0xFFB7E7D6), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'YOUR MOMENT OF CLARITY',
                style: TextStyle(
                  color: Color(0xFFB7E7D6),
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          width: 216,
          height: 216,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF96DCC3), width: 8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '25:00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -2,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Time to do your thing',
                style: TextStyle(color: Color(0xFFB4C9CF), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF96DCC3)),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One small step forward',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'That’s all it takes to begin.',
                      style: TextStyle(color: Color(0xFFB4C9CF), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 20, bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: teal, size: 25),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
