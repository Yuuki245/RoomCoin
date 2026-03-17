import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../features/auth/models/user_model.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/room/repositories/room_repository.dart';

class AppController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final RoomRepository _roomRepository = RoomRepository();

  final Rxn<User> firebaseUser = Rxn<User>();
  final Rxn<UserModel> user = Rxn<UserModel>();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  @override
  void onInit() {
    super.onInit();

    _authSub = _authRepository.authStateChanges.listen((u) {
      firebaseUser.value = u;

      _userSub?.cancel();
      user.value = null;

      if (u != null) {
        _userSub = _authRepository.streamUser(u.uid).listen((model) {
          user.value = model;
        });
      }
    });
  }

  bool get isAuthed => firebaseUser.value != null;
  bool get hasRoom => (user.value?.roomId ?? '').isNotEmpty;

  Future<void> signInWithGoogle() async {
    await _authRepository.signInWithGoogle();
  }

  Future<void> signOut() => _authRepository.signOut();

  Future<void> createRoom(String roomName) async {
    await _roomRepository.createRoom(roomName);
  }

  Future<bool> joinRoom(String inviteCode) async {
    final room = await _roomRepository.joinRoom(inviteCode);
    return room != null;
  }

  @override
  void onClose() {
    _userSub?.cancel();
    _authSub?.cancel();
    super.onClose();
  }
}

