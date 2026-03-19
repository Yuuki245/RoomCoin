import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../auth/repositories/user_repository.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  String _formatVnd(num amount) {
    final formatted = NumberFormat('#,##0', 'vi_VN').format(amount.round());
    return '$formatted đ';
  }

  Widget _userName(String uid) {
    final repo = Get.find<UserRepository>();
    return FutureBuilder<String>(
      future: repo.getDisplayName(uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            highlightColor: Theme.of(context).colorScheme.surface,
            child: Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }
        return Text(
          snap.data!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.right,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.find();
    final tag = controller.getTagById(expense.tagId);
    final tagColor = tag == null
        ? Theme.of(context).colorScheme.primary
        : Color(int.parse(tag.colorHex.replaceFirst('#', '0xff')));
    final isCreator = controller.currentUid == expense.createdBy;
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy - HH:mm', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Chi tiêu'),
        actions: isCreator
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Get.snackbar(
                      'Tính năng',
                      'Sửa khoản chi sẽ ra mắt sau.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _showDeleteConfirm(context, controller),
                ),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: tagColor.withAlpha(51),
                child: Icon(
                  IconData(
                    tag?.iconCode ?? Icons.receipt_long.codePoint,
                    fontFamily: 'MaterialIcons',
                  ),
                  size: 40,
                  color: tagColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                expense.note ?? tag?.name ?? 'Danh mục',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _formatVnd(expense.amount),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildDetailRow(
              context,
              title: 'Danh mục',
              value: Text(
                tag?.name ?? 'Danh mục',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildDetailRow(
              context,
              title: 'Thời gian',
              value: Text(
                dateFormatter.format(expense.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildDetailRow(
              context,
              title: 'Người tạo',
              value: _userName(expense.createdBy),
            ),
            _buildDetailRow(
              context,
              title: 'Người trả tiền',
              value: _userName(expense.paidBy),
            ),
            const Divider(height: 32),
            Text(
              'Danh sách chia tiền',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...expense.splitBetween.map(
              (member) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person),
                title: _userName(member),
                trailing: Text(
                  _formatVnd(expense.amount / expense.splitBetween.length),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String title,
    required Widget value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ExpenseController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa khoản chi này không? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await controller.deleteExpense(expense.id);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  Get.back();
                  Get.snackbar(
                    'Đã xóa',
                    'Khoản chi đã được xóa thành công',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } catch (_) {}
              },
              child: Text(
                'Xóa',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
