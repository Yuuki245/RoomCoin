class RoomModel {
  final String id;
  final String name;
  final String inviteCode; // 6 số
  final String adminId;
  final List<String> members;
  final List<String> pendingLeaveUids;
  final DateTime createdAt;

  const RoomModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.adminId,
    required this.members,
    this.pendingLeaveUids = const [],
    required this.createdAt,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else if (createdAtRaw == null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      // Timestamp from Firestore
      createdAt = (createdAtRaw as dynamic).toDate() as DateTime;
    }
    return RoomModel(
      id: id,
      name: map['name'] as String,
      inviteCode: (map['inviteCode'] as String?) ?? (map['code'] as String),
      adminId: map['adminId'] as String,
      members: List<String>.from(map['members'] as List),
      pendingLeaveUids: map['pendingLeaveUids'] != null
          ? List<String>.from(map['pendingLeaveUids'] as List)
          : [],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'adminId': adminId,
      'members': members,
      'pendingLeaveUids': pendingLeaveUids,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? adminId,
    List<String>? members,
    List<String>? pendingLeaveUids,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      adminId: adminId ?? this.adminId,
      members: members ?? this.members,
      pendingLeaveUids: pendingLeaveUids ?? this.pendingLeaveUids,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
