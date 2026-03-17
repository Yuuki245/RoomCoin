import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  static const String _usersCollection = 'users';

  Stream<User?> get authStateChanges => _authService.authStateChanges;
  String? get currentUid => _authService.currentUser?.uid;

  /// Đăng nhập bằng Google. Nếu user mới thì tạo document trong Firestore.
  Future<UserModel?> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    if (credential == null) return null;

    final firebaseUser = credential.user!;
    final uid = firebaseUser.uid;

    // Kiểm tra user đã tồn tại trong Firestore chưa
    final existingDoc = await _firestoreService.getDoc(_usersCollection, uid);
    if (!existingDoc.exists) {
      // User mới → tạo document
      final newUser = UserModel(
        uid: uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'Người dùng',
        photoUrl: firebaseUser.photoURL ?? '',
        roomId: null,
      );
      await _firestoreService.setDoc(_usersCollection, uid, {
        ...newUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return newUser;
    }

    // User cũ → đọc từ Firestore
    final data = existingDoc.data();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  Future<void> signOut() => _authService.signOut();

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestoreService.getDoc(_usersCollection, uid);
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestoreService.streamDoc(_usersCollection, uid).map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return UserModel.fromMap(data);
    });
  }

  Future<void> updateUserRoom(String uid, String roomId) async {
    await _firestoreService.updateDoc(_usersCollection, uid, {'roomId': roomId});
  }
}
