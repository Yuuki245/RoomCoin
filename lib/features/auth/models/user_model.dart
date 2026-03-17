class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String? bankName;
  final String? accountNumber;
  final String? roomId;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.bankName,
    this.accountNumber,
    this.roomId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: (map['displayName'] as String?) ?? (map['name'] as String?) ?? 'Người dùng',
      photoUrl: (map['photoUrl'] as String?) ??
          (map['photoURL'] as String?) ??
          (map['avatarUrl'] as String?) ??
          '',
      bankName: map['bankName'] as String?,
      accountNumber: map['accountNumber'] as String?,
      roomId: map['roomId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      if (bankName != null) 'bankName': bankName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      'roomId': roomId,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bankName,
    String? accountNumber,
    String? roomId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      roomId: roomId ?? this.roomId,
    );
  }
}
