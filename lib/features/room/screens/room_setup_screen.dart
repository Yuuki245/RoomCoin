import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/controllers/app_controller.dart';
import '../repositories/room_repository.dart';

class _ShimmerButtonChild extends StatelessWidget {
  final String label;
  const _ShimmerButtonChild({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.onPrimary.withValues(alpha: 0.25),
      highlightColor: cs.onPrimary.withValues(alpha: 0.6),
      child: Text(label),
    );
  }
}

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({super.key});

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  final _roomNameCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();

  bool _creating = false;
  bool _joining = false;

  @override
  void dispose() {
    _roomNameCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập phòng'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => controller.signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tạo phòng mới', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _roomNameCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Tên phòng',
                        hintText: 'VD: Phòng 204',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _creating
                          ? null
                          : () async {
                              final name = _roomNameCtrl.text.trim();
                              if (name.isEmpty) {
                                Get.snackbar('Thiếu thông tin', 'Vui lòng nhập tên phòng');
                                return;
                              }
                              setState(() => _creating = true);
                              try {
                                await controller.createRoom(name);
                                _roomNameCtrl.clear();
                                Get.offAllNamed('/home');
                              } on RoomRepositoryException catch (e) {
                                Get.snackbar(
                                  'Tạo phòng thất bại',
                                  e.message,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } catch (_) {
                                Get.snackbar(
                                  'Tạo phòng thất bại',
                                  'Không thể tạo phòng. Vui lòng thử lại.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } finally {
                                if (mounted) setState(() => _creating = false);
                              }
                            },
                      child: _creating
                          ? const _ShimmerButtonChild(label: 'Đang tạo phòng...')
                          : const Text('Tạo phòng'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tham gia phòng', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inviteCodeCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Mã mời 6 số',
                        hintText: 'VD: 123456',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _joining
                          ? null
                          : () async {
                              final code = _inviteCodeCtrl.text.trim();
                              if (code.length != 6 || int.tryParse(code) == null) {
                                Get.snackbar('Mã không hợp lệ', 'Vui lòng nhập mã gồm đúng 6 chữ số');
                                return;
                              }
                              setState(() => _joining = true);
                              try {
                                final ok = await controller.joinRoom(code);
                                if (!ok) {
                                  Get.snackbar('Không tìm thấy phòng', 'Mã mời không tồn tại hoặc đã hết hạn');
                                } else {
                                  _inviteCodeCtrl.clear();
                                  Get.offAllNamed('/home');
                                }
                              } on RoomRepositoryException catch (e) {
                                Get.snackbar(
                                  'Tham gia thất bại',
                                  e.message,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } catch (_) {
                                Get.snackbar(
                                  'Tham gia thất bại',
                                  'Không thể tham gia phòng. Vui lòng thử lại.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } finally {
                                if (mounted) setState(() => _joining = false);
                              }
                            },
                      child: _joining
                          ? const _ShimmerButtonChild(label: 'Đang tham gia...')
                          : const Text('Tham gia'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final u = controller.user.value;
              return u == null
                  ? const SizedBox.shrink()
                  : Text(
                      'Bạn đang đăng nhập: ${u.displayName} (${u.email})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    );
            }),
          ],
        ),
      ),
    );
  }
}

