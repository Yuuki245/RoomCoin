import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/home/screens/main_navigation.dart';
import '../../features/room/screens/room_setup_screen.dart';
import '../controllers/app_controller.dart';

class AppGate extends GetView<AppController> {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isAuthed) return const SignInScreen();

      // Đã auth nhưng chưa load được user document (lần đầu tạo/đọc)
      if (controller.user.value == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (!controller.hasRoom) return const RoomSetupScreen();
      return const MainNavigation();
    });
  }
}

