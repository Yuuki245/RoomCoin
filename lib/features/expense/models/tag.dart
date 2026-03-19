import 'package:cloud_firestore/cloud_firestore.dart';

class Tag {
  final String id;
  final String name;
  final int iconCode;
  final String colorHex;
  final String roomId;

  Tag({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.roomId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'roomId': roomId,
    };
  }

  factory Tag.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Tag document is empty: ${doc.id}');
    }

    return Tag(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Danh mục',
      iconCode: (data['iconCode'] as num?)?.toInt() ?? 0,
      colorHex: (data['colorHex'] as String?) ?? '#607D8B',
      roomId: (data['roomId'] as String?) ?? '',
    );
  }

  Tag copyWith({
    String? id,
    String? name,
    int? iconCode,
    String? colorHex,
    String? roomId,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
      roomId: roomId ?? this.roomId,
    );
  }
}
