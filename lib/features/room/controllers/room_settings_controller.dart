import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/controllers/app_controller.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/room_model.dart';
import '../repositories/room_repository.dart';

class RoomSettingsController extends GetxController {
  final RoomRepository _roomRepository = RoomRepository();
  final AppController _appController = Get.find<AppController>();
  final AuthRepository _authRepository = AuthRepository();

  final Rxn<RoomModel> currentRoom = Rxn<RoomModel>();
  StreamSubscription? _roomSub;

  final RxBool isLoadingRequest = false.obs;
  final RxMap<String, bool> isApproving = <String, bool>{}.obs;

  String? get currentUid => _authRepository.currentUid;

  @override
  void onInit() {
    super.onInit();
    final roomId = _appController.user.value?.roomId;
    debugPrint(
      'DEBUG [RoomSettingsController]: onInit called, roomId = $roomId',
    );

    if (roomId != null && roomId.isNotEmpty) {
      debugPrint(
        'DEBUG [RoomSettingsController]: Starting streamRoom for $roomId',
      );
      _roomSub = _roomRepository.streamRoom(roomId).listen((roomData) {
        debugPrint(
          'DEBUG [RoomSettingsController]: Received room data from Stream: ${roomData?.id}',
        );
        currentRoom.value = roomData;
      });
    } else {
      debugPrint(
        'DEBUG [RoomSettingsController]: roomId is null. Waiting for AppController.user...',
      );

      // Lắng nghe đến khi AppController có dữ liệu user.roomId
      ever(_appController.user, (user) {
        final newRoomId = user?.roomId;
        if (newRoomId != null && newRoomId.isNotEmpty && _roomSub == null) {
          debugPrint(
            'DEBUG [RoomSettingsController]: Fallback activated, starting streamRoom for $newRoomId',
          );
          _roomSub = _roomRepository.streamRoom(newRoomId).listen((roomData) {
            debugPrint(
              'DEBUG [RoomSettingsController]: Received room data from Fallback Stream: ${roomData?.id}',
            );
            currentRoom.value = roomData;
          });
        }
      });
    }
  }

  Future<void> requestLeave() async {
    final roomId = currentRoom.value?.id;
    if (roomId == null || isLoadingRequest.value) return;

    isLoadingRequest.value = true;
    try {
      await _roomRepository.requestLeaveRoom(roomId);
      Get.snackbar(
        'Thành công',
        'Đã gửi yêu cầu rời phòng cho Quản trị viên.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingRequest.value = false;
    }
  }

  Future<void> approveLeave(String targetUid) async {
    final roomId = currentRoom.value?.id;
    if (roomId == null || (isApproving[targetUid] ?? false)) return;

    isApproving[targetUid] = true;
    try {
      await _roomRepository.approveLeave(roomId, targetUid);
      Get.snackbar(
        'Thành công',
        'Đã duyệt yêu cầu rời phòng.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isApproving[targetUid] = false;
    }
  }

  Future<void> adminLeaveRoom(String? newAdminUid) async {
    final roomId = currentRoom.value?.id;
    if (roomId == null || isLoadingRequest.value) return;

    isLoadingRequest.value = true;
    try {
      await _roomRepository.adminLeaveRoom(roomId, newAdminUid);
      Get.snackbar(
        'Thành công',
        newAdminUid != null
            ? 'Đã nhường quyền và rời phòng.'
            : 'Đã giải tán phòng.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingRequest.value = false;
    }
  }

  @override
  void onClose() {
    _roomSub?.cancel();
    super.onClose();
  }
}
