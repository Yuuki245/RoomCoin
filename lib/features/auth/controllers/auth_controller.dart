import 'package:get/get.dart';

import '../../../core/controllers/app_controller.dart';

class AuthController extends GetxController {
  final AppController _app = Get.find<AppController>();

  /// Room hiện tại của user (rỗng nếu chưa có)
  final RxString roomId = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // đồng bộ giá trị ban đầu (nếu đã có)
    roomId.value = (_app.user.value?.roomId ?? '').trim();

    // lắng nghe user doc realtime từ AppController
    ever(_app.user, (u) {
      roomId.value = (u?.roomId ?? '').trim();
    });
  }
}

