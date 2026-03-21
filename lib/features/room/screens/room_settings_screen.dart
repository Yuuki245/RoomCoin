import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:roomcoin/features/expense/controllers/expense_controller.dart';
import '../controllers/room_settings_controller.dart';

class RoomSettingsScreen extends StatelessWidget {
  const RoomSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RoomSettingsController());

    // Optional: dùng ExpenseController để lấy tên thành viên nếu đã khởi tạo
    ExpenseController? expenseController;
    if (Get.isRegistered<ExpenseController>()) {
      expenseController = Get.find<ExpenseController>();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt phòng'), centerTitle: true),
      body: Obx(() {
        final room = controller.currentRoom.value;
        if (room == null) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSkeletonCard(context, height: 120),
              const SizedBox(height: 24),
              _buildSkeletonCard(context, height: 60),
              const SizedBox(height: 16),
              _buildSkeletonCard(context, height: 80),
            ],
          );
        }

        final uid = controller.currentUid;
        final isAdmin = room.adminId == uid;
        final isMember = !isAdmin;
        final isPending = room.pendingLeaveUids.contains(uid);

        debugPrint(
          'DEBUG: isAdmin = $isAdmin, roomAdmin = ${room.adminId}, myUid = $uid',
        );

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Thông tin chung
            Card(
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(100),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin phòng',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(context, 'Tên phòng', room.name),
                    const Divider(height: 24),
                    _buildInfoRow(context, 'Mã mời', room.inviteCode),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'Thành viên',
                      '${room.members.length} người',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Khu vực Member
            if (isMember) ...[
              Text(
                'Tùy chọn thành viên',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error.withAlpha(127),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    isPending ? 'Đang chờ Admin duyệt' : 'Xin rời phòng',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: isPending
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isPending
                        ? 'Yêu cầu của bạn đã được gửi đến quản trị viên.'
                        : 'Bạn sẽ không thể truy cập lại dữ liệu phòng này sau khi rời đi.',
                  ),
                  trailing: isPending || controller.isLoadingRequest.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.exit_to_app,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  onTap: isPending || controller.isLoadingRequest.value
                      ? null
                      : () => _showLeaveConfirmDialog(context, controller),
                ),
              ),
            ],

            // Khu vực Admin
            if (isAdmin) ...[
              Text(
                'Quản lý yêu cầu rời phòng (${room.pendingLeaveUids.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (room.pendingLeaveUids.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: Text('Không có yêu cầu nào.')),
                )
              else
                ...room.pendingLeaveUids.map((targetUid) {
                  final isApproving =
                      controller.isApproving[targetUid] ?? false;
                  // Thử lấy tên từ nameLookup của ExpenseController
                  final memberName =
                      expenseController?.memberNameLookup[targetUid] ??
                      'Thành viên vô danh';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          memberName.isNotEmpty
                              ? memberName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(memberName),
                      subtitle: const Text('Đã gửi yêu cầu rời phòng'),
                      trailing: isApproving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton.tonal(
                              onPressed: () =>
                                  controller.approveLeave(targetUid),
                              style: FilledButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                              ),
                              child: const Text('Duyệt'),
                            ),
                    ),
                  );
                }),
              const Divider(height: 32),
              Text(
                'Tùy chọn Quản trị viên',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error.withAlpha(127),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    room.members.length > 1
                        ? 'Rời phòng & Nhường quyền'
                        : 'Giải tán phòng',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    room.members.length > 1
                        ? 'Bạn cần chọn quản trị viên mới trước khi rời đi.'
                        : 'Bạn là người cuối cùng. Rời đi sẽ giải tán toàn bộ dữ liệu phòng.',
                  ),
                  trailing: controller.isLoadingRequest.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.delete_forever,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  onTap: controller.isLoadingRequest.value
                      ? null
                      : () => _handleAdminLeave(
                          context,
                          controller,
                          room,
                          expenseController,
                        ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context, {required double height}) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(height: height, width: double.infinity),
    );
  }

  void _showLeaveConfirmDialog(
    BuildContext context,
    RoomSettingsController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận rời phòng'),
        content: const Text(
          'Bạn có chắc chắn muốn rời phòng này không? Bạn sẽ không thể hoàn tác hành động này cho đến khi được thêm lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.requestLeave();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  void _handleAdminLeave(
    BuildContext context,
    RoomSettingsController controller,
    dynamic room,
    ExpenseController? expenseController,
  ) {
    if (room.members.length == 1) {
      // Giải tán phòng
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận giải tán phòng'),
          content: const Text(
            'Bạn là người cuối cùng. Rời đi sẽ giải tán toàn bộ phòng. Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Đóng dialog
                controller.adminLeaveRoom(null);
                Get.back(); // Thoát về màn chính (Join Room)
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Giải tán phòng'),
            ),
          ],
        ),
      );
    } else {
      // Nhường quyền
      final otherMembers = room.members
          .where((uid) => uid != controller.currentUid)
          .toList();
      String? selectedUid;

      Get.bottomSheet(
        StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn Quản trị viên mới',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...otherMembers.map((uid) {
                    final memberName =
                        expenseController?.memberNameLookup[uid] ??
                        'Thành viên vô danh';
                    return RadioListTile<String>(
                      title: Text(memberName),
                      subtitle: Text('UID: $uid'),
                      value: uid as String,
                      groupValue: selectedUid,
                      onChanged: (val) => setState(() => selectedUid = val),
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedUid == null
                          ? null
                          : () {
                              Get.back(); // Đóng bottom sheet
                              controller.adminLeaveRoom(selectedUid);
                              Get.back(); // Trở ra ngoài màn Join Room
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Nhường quyền & Rời đi'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }
}
