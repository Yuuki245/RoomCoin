import 'package:get/get.dart';

import '../../../core/controllers/app_controller.dart';

class AuthController extends GetxController {
  final AppController _app = Get.find<AppController>();

  /// Room hiện tại của user (rỗng nếu chưa có)
  final RxString roomId = ''.obs;
  Worker? _userWorker;

  @override
  void onInit() {
    super.onInit();

    roomId.value = (_app.user.value?.roomId ?? '').trim();

    _userWorker = ever(_app.user, (u) {
      roomId.value = (u?.roomId ?? '').trim();
    });
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    super.onClose();
  }
}
