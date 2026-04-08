import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/merchant_collection_model.dart';

final merchantCollectionRepositoryProvider = Provider<MerchantCollectionRepository>((ref) {
  return MerchantCollectionRepository(FirebaseFirestore.instance);
});

class MerchantCollectionRepository {
  final FirebaseFirestore _firestore;

  MerchantCollectionRepository(this._firestore);

  Stream<List<MerchantCollectionModel>> getCollectionsForMerchant(String merchantId) {
    return _firestore
        .collection('merchant_collections')
        .where('merchantId', isEqualTo: merchantId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MerchantCollectionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<MerchantCollectionModel>> getCollectionsForDelegate(String delegateId) {
    return _firestore
        .collection('merchant_collections')
        .where('delegateId', isEqualTo: delegateId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MerchantCollectionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<MerchantCollectionModel>> getAllCollections() {
    return _firestore
        .collection('merchant_collections')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MerchantCollectionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addCollection(MerchantCollectionModel collection) async {
    await _firestore.collection('merchant_collections').add(collection.toMap());
  }

  Future<void> deleteCollection(String id) async {
    await _firestore.collection('merchant_collections').doc(id).delete();
  }
}
