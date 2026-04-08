import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/delegate_model.dart';

final delegateRepositoryProvider = Provider<DelegateRepository>((ref) {
  return DelegateRepository(FirebaseFirestore.instance);
});

class DelegateRepository {
  final FirebaseFirestore _firestore;

  DelegateRepository(this._firestore);

  CollectionReference get _delegates => _firestore.collection('delegates');

  Stream<List<DelegateModel>> getDelegates() {
    return _delegates.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DelegateModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addDelegate(DelegateModel delegate) async {
    await _delegates.add(delegate.toMap());
  }

  Future<void> updateDelegate(DelegateModel delegate) async {
    await _delegates.doc(delegate.id).update(delegate.toMap());
  }

  Future<void> deleteDelegate(String id) async {
    await _delegates.doc(id).delete();
  }
}
