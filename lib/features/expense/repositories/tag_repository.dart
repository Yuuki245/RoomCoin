import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tag.dart';

class TagRepository {
  final FirebaseFirestore _db;

  TagRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  static const String _roomsCollection = 'rooms';
  static const String _tagsCollection = 'tags';

  CollectionReference<Map<String, dynamic>> _tagCollection(String roomId) {
    return _db
        .collection(_roomsCollection)
        .doc(roomId)
        .collection(_tagsCollection);
  }

  Stream<List<Tag>> streamTagsByRoom(String roomId) {
    return _tagCollection(roomId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(Tag.fromDoc).toList(growable: false));
  }

  Future<void> ensureDefaultTags(String roomId) async {
    final collection = _tagCollection(roomId);
    final existingTags = await collection.limit(1).get();
    if (existingTags.docs.isNotEmpty) {
      return;
    }

    final batch = _db.batch();
    for (final tag in _defaultTags(roomId)) {
      batch.set(collection.doc(tag.id), tag.toMap());
    }
    await batch.commit();
  }

  Future<void> addTag(Tag tag) async {
    await _tagCollection(tag.roomId).doc(tag.id).set(tag.toMap());
  }

  Future<void> updateTag(Tag tag) async {
    await _tagCollection(tag.roomId).doc(tag.id).update(tag.toMap());
  }

  Future<void> deleteTag(String roomId, String tagId) async {
    await _tagCollection(roomId).doc(tagId).delete();
  }

  List<Tag> _defaultTags(String roomId) {
    return const [
          ('food', 'Ăn uống', 0xe532, '#FF5722'),
          ('electricity', 'Tiền điện', 0xe1a3, '#FFC107'),
          ('market', 'Đi chợ', 0xe8cc, '#4CAF50'),
          ('rent', 'Tiền nhà', 0xe88a, '#2196F3'),
          ('transport', 'Đi lại', 0xe530, '#9C27B0'),
          ('healthcare', 'Y tế', 0xe3f0, '#E91E63'),
          ('internet', 'Internet', 0xe63e, '#00BCD4'),
        ]
        .map((seed) {
          return Tag(
            id: seed.$1,
            name: seed.$2,
            iconCode: seed.$3,
            colorHex: seed.$4,
            roomId: roomId,
          );
        })
        .toList(growable: false);
  }
}
