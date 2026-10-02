import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Firebase isn't initialized in widget tests, so every call is a no-op there.
bool get _ready => Firebase.apps.isNotEmpty;

CollectionReference<Map<String, dynamic>> get _sessions =>
    FirebaseFirestore.instance.collection('sessions');

/// Saves a finished focus session to Firestore.
Future<void> saveSession(int minutes) async {
  if (!_ready) return;
  await _sessions.add({
    'minutes': minutes,
    'finishedAt': FieldValue.serverTimestamp(),
  });
}

/// Live total of minutes across all saved sessions.
// ponytail: sums every doc client-side and has no per-user split; add auth + an aggregate query if sessions grow.
Stream<int> totalMinutes() => _ready
    ? _sessions.snapshots().map(
        (s) => s.docs.fold(0, (total, d) => total +(d['minutes'] as num).toInt()),
      )
    : Stream.value(0);
