import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/caffeine_entry.dart';

class SyncRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _entriesRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('entries');
  }

  Future<void> uploadEntry(CaffeineEntry entry) async {
    if (kIsWeb) return;
    final ref = _entriesRef;
    if (ref == null) return;
    await ref.doc(entry.id).set(entry.toMap());
  }

  Future<void> deleteEntry(String id) async {
    if (kIsWeb) return;
    final ref = _entriesRef;
    if (ref == null) return;
    await ref.doc(id).delete();
  }

  Future<void> syncAll(List<CaffeineEntry> entries) async {
    if (kIsWeb) return;
    final ref = _entriesRef;
    if (ref == null) return;
    final batch = _db.batch();
    for (final entry in entries) {
      batch.set(ref.doc(entry.id), entry.toMap());
    }
    await batch.commit();
  }

  Stream<List<CaffeineEntry>> listenToRemoteEntries() {
    if (kIsWeb || _entriesRef == null) {
      return const Stream.empty();
    }
    return _entriesRef!.snapshots().map((snap) =>
        snap.docs.map((d) => CaffeineEntry.fromMap(d.data())).toList());
  }
}
