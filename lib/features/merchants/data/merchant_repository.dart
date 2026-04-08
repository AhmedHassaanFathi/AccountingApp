import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/merchant_model.dart';

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepository(FirebaseFirestore.instance);
});

class MerchantRepository {
  final FirebaseFirestore _firestore;

  MerchantRepository(this._firestore);

  Stream<List<MerchantModel>> getMerchants() {
    return _firestore
        .collection('merchants')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MerchantModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addMerchant(String name) async {
    final model = MerchantModel(
      id: '',
      name: name,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('merchants').add(model.toMap());
  }

  Future<void> updateMerchant(String id, String name) async {
    await _firestore.collection('merchants').doc(id).update({
      'name': name,
    });
  }

  Future<void> deleteMerchant(String id) async {
    await _firestore.collection('merchants').doc(id).delete();
  }
}
