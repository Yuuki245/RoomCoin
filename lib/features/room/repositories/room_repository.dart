import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/room_model.dart';

class RoomRepositoryException implements Exception {
  final String message;
  const RoomRepositoryException(this.message);

  @override
  String toString() => message;
}

class RoomRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthRepository _authRepository = AuthRepository();

  static const String _roomsCollection = 'rooms';
  static const String _usersCollection = 'users';

  /// Tạo mã mời 6 số ngẫu nhiên, ví dụ: 123456
  String _generateInviteCode() {
    final random = Random.secure();
    final value = 100000 + random.nextInt(900000);
    return value.toString();
  }

  /// Tạo phòng mới, gán adminId, cập nhật roomId cho user
  Future<RoomModel> createRoom(String roomName) async {
    final adminUid = _authRepository.currentUid;
    if (adminUid == null) {
      throw const RoomRepositoryException(
        'Bạn chưa đăng nhập. Vui lòng đăng nhập lại.',
      );
    }

    // best-effort tránh trùng mã mời (hiếm, nhưng nên xử lý)
    String inviteCode = _generateInviteCode();
    for (var i = 0; i < 5; i++) {
      final existed = await _firestoreService.queryWhere(
        _roomsCollection,
        'inviteCode',
        inviteCode,
      );
      if (existed.docs.isEmpty) break;
      inviteCode = _generateInviteCode();
    }

    final createdAtLocal = DateTime.now();
    final db = FirebaseFirestore.instance;
    final roomRef = db.collection(_roomsCollection).doc();
    final userRef = db.collection(_usersCollection).doc(adminUid);

    try {
      await db.runTransaction((tx) async {
        tx.set(roomRef, {
          'inviteCode': inviteCode, // 6 chữ số
          'name': roomName,
          'adminId': adminUid,
          'members': [adminUid],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Schema: `users.joinedRooms` (Array<String>) theo database_schema.md
        // Luồng hiện tại của app vẫn dùng `roomId` để điều hướng → giữ để không phá flow.
        tx.set(userRef, {
          'roomId': roomRef.id,
          'joinedRooms': FieldValue.arrayUnion([roomRef.id]),
        }, SetOptions(merge: true));
      });
    } on FirebaseException catch (e) {
      throw RoomRepositoryException('Lỗi tạo phòng: ${e.message ?? e.code}');
    } catch (_) {
      throw const RoomRepositoryException('Lỗi tạo phòng. Vui lòng thử lại.');
    }

    return RoomModel(
      id: roomRef.id,
      name: roomName,
      inviteCode: inviteCode,
      adminId: adminUid,
      members: [adminUid],
      createdAt: createdAtLocal,
    );
  }

  /// Tham gia phòng bằng mã 6 số, thêm uid vào members[] và cập nhật roomId cho user
  Future<RoomModel?> joinRoom(String inviteCode) async {
    final uid = _authRepository.currentUid;
    if (uid == null) {
      throw const RoomRepositoryException(
        'Bạn chưa đăng nhập. Vui lòng đăng nhập lại.',
      );
    }

    final snapshot = await _firestoreService.queryWhere(
      _roomsCollection,
      'inviteCode',
      inviteCode,
    );

    if (snapshot.docs.isEmpty) return null; // Không tìm thấy phòng với code này

    final doc = snapshot.docs.first;
    final room = RoomModel.fromMap(doc.id, doc.data());

    final db = FirebaseFirestore.instance;
    final roomRef = db.collection(_roomsCollection).doc(room.id);
    final userRef = db.collection(_usersCollection).doc(uid);

    try {
      await db.runTransaction((tx) async {
        final roomSnap = await tx.get(roomRef);
        if (!roomSnap.exists) {
          throw const RoomRepositoryException(
            'Phòng không tồn tại hoặc đã bị xoá.',
          );
        }

        tx.update(roomRef, {
          'members': FieldValue.arrayUnion([uid]),
        });

        tx.set(userRef, {
          'roomId': room.id,
          'joinedRooms': FieldValue.arrayUnion([room.id]),
        }, SetOptions(merge: true));
      });
    } on RoomRepositoryException {
      rethrow;
    } on FirebaseException catch (e) {
      throw RoomRepositoryException(
        'Lỗi tham gia phòng: ${e.message ?? e.code}',
      );
    } catch (_) {
      throw const RoomRepositoryException(
        'Lỗi tham gia phòng. Vui lòng thử lại.',
      );
    }

    final members = room.members.contains(uid)
        ? room.members
        : [...room.members, uid];
    return room.copyWith(members: members);
  }

  Future<RoomModel?> getRoom(String roomId) async {
    final doc = await _firestoreService.getDoc(_roomsCollection, roomId);
    if (!doc.exists || doc.data() == null) return null;
    return RoomModel.fromMap(doc.id, doc.data()!);
  }

  /// Theo dõi biến động của một phòng theo realtime
  Stream<RoomModel?> streamRoom(String roomId) {
    return FirebaseFirestore.instance
        .collection(_roomsCollection)
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return RoomModel.fromMap(snapshot.id, snapshot.data()!);
        });
  }

  /// Gửi yêu cầu xin rời phòng
  Future<void> requestLeaveRoom(String roomId) async {
    final uid = _authRepository.currentUid;
    if (uid == null) {
      throw const RoomRepositoryException('Bạn chưa đăng nhập.');
    }

    final db = FirebaseFirestore.instance;
    try {
      await db.collection(_roomsCollection).doc(roomId).update({
        'pendingLeaveUids': FieldValue.arrayUnion([uid]),
      });
    } on FirebaseException catch (e) {
      throw RoomRepositoryException(
        'Lỗi duyệt yêu cầu: ${e.message ?? e.code}',
      );
    } catch (_) {
      throw const RoomRepositoryException(
        'Lỗi không xác định khi gửi yêu cầu.',
      );
    }
  }

  /// Quản trị viên duyệt người khác rời phòng
  Future<void> approveLeave(String roomId, String targetUid) async {
    final uid = _authRepository.currentUid;
    if (uid == null) {
      throw const RoomRepositoryException('Bạn chưa đăng nhập.');
    }

    final db = FirebaseFirestore.instance;
    final roomRef = db.collection(_roomsCollection).doc(roomId);
    final userRef = db.collection(_usersCollection).doc(targetUid);

    try {
      await db.runTransaction((tx) async {
        final roomSnap = await tx.get(roomRef);
        if (!roomSnap.exists) {
          throw const RoomRepositoryException('Phòng không tồn tại.');
        }

        final roomData = roomSnap.data() as Map<String, dynamic>;
        if (roomData['adminId'] != uid) {
          throw const RoomRepositoryException(
            'Bạn không phải là trưởng phòng.',
          );
        }

        tx.update(roomRef, {
          'members': FieldValue.arrayRemove([targetUid]),
          'pendingLeaveUids': FieldValue.arrayRemove([targetUid]),
        });

        tx.update(userRef, {'roomId': null});
      });
    } on RoomRepositoryException {
      rethrow;
    } on FirebaseException catch (e) {
      throw RoomRepositoryException(
        'Lỗi duyệt yêu cầu: ${e.message ?? e.code}',
      );
    } catch (_) {
      throw const RoomRepositoryException(
        'Lỗi duyệt yêu cầu. Vui lòng thử lại.',
      );
    }
  }

  /// Quản trị viên rời phòng (nhường quyền hoặc giải tán phòng)
  Future<void> adminLeaveRoom(String roomId, String? newAdminUid) async {
    final uid = _authRepository.currentUid;
    if (uid == null) {
      throw const RoomRepositoryException('Bạn chưa đăng nhập.');
    }

    final db = FirebaseFirestore.instance;
    final roomRef = db.collection(_roomsCollection).doc(roomId);
    final userRef = db.collection(_usersCollection).doc(uid);

    try {
      final batch = db.batch();

      if (newAdminUid != null && newAdminUid.isNotEmpty) {
        // Nhường quyền cho người khác
        batch.update(roomRef, {
          'adminId': newAdminUid,
          'members': FieldValue.arrayRemove([uid]),
          'pendingLeaveUids': FieldValue.arrayRemove([uid]),
        });
      } else {
        // Chỉ còn 1 mình admin -> Giải tán phòng (xoá document)
        batch.delete(roomRef);
      }

      // Admin bị mất roomId trong profile
      batch.update(userRef, {'roomId': null});

      // Rất nhanh và an toàn
      await batch.commit();
    } on FirebaseException catch (e) {
      throw RoomRepositoryException(
        'Lỗi khi rời phòng: ${e.message ?? e.code}',
      );
    } catch (_) {
      throw const RoomRepositoryException(
        'Lỗi không xác định khi Admin rời phòng.',
      );
    }
  }
}
