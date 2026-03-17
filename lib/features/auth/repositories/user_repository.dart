import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _db;
  UserRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  final Map<String, String> _displayNameCache = {};
  final Map<String, Future<String>> _inflight = {};

  Future<String> getDisplayName(String uid) {
    final cached = _displayNameCache[uid];
    if (cached != null && cached.trim().isNotEmpty) return Future.value(cached);

    final inflight = _inflight[uid];
    if (inflight != null) return inflight;

    final future = _db.collection(_usersCollection).doc(uid).get().then((doc) {
      final data = doc.data();
      final name = (data?['displayName'] as String?) ??
          (data?['name'] as String?) ??
          (data?['email'] as String?) ??
          'Người dùng';
      _displayNameCache[uid] = name;
      return name;
    }).catchError((_) {
      return 'Người dùng';
    }).whenComplete(() {
      _inflight.remove(uid);
    });

    _inflight[uid] = future;
    return future;
  }
}

