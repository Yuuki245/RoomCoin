import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setDoc(String collection, String docId, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(docId).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String collection, String docId) async {
    return await _db.collection(collection).doc(docId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> queryWhere(
    String collection,
    String field,
    dynamic value,
  ) async {
    return await _db.collection(collection).where(field, isEqualTo: value).get();
  }

  Future<void> updateDoc(String collection, String docId, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(String collection, String docId) {
    return _db.collection(collection).doc(docId).snapshots();
  }
}
