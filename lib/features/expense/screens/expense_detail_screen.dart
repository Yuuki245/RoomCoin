import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../screens/add_expense_screen.dart';
import '../widgets/expense_audit_timeline.dart';
import '../widgets/expense_state_widgets.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  String _formatVnd(num amount) {
    final formatted = NumberFormat('#,##0', 'vi_VN').format(amount.round());
    return '$formatted đ';
  }

  Widget _userName(ExpenseController controller, String uid) {
    return Text(
      controller.memberName(uid),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      textAlign: TextAlign.right,
    );
  }

  @override
  void initState() {
    super.initState();
    final ExpenseController controller = Get.find();
    // Use addPostFrameCallback to ensure this runs after initial frame and doesn't conflict with current build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchLogs(widget.expense.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Chi tiêu'),
        actions: [
          Obx(() {
            final expense = controller.expenses.firstWhereOrNull(
              (e) => e.id == widget.expense.id,
            );
            if (expense == null) return const SizedBox.shrink();

            final isCreator = controller.currentUid == expense.createdBy;
            if (!isCreator) return const SizedBox.shrink();

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Get.to(() => AddExpenseScreen(existingExpense: expense));
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () =>
                      _showDeleteConfirm(context, controller, expense),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        final expense = controller.expenses.firstWhereOrNull(
          (e) => e.id == widget.expense.id,
        );

        if (expense == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Get.back();
          });
          return const SizedBox.shrink();
        }

        if (controller.isLoadingMembers.value ||
            controller.isLoadingTags.value) {
          return const ExpenseDetailShimmer();
        }

        final tag = controller.getTagById(expense.tagId);
        final tagColor = tag == null
            ? Theme.of(context).colorScheme.primary
            : Color(int.parse(tag.colorHex.replaceFirst('#', '0xff')));
        final dateFormatter = DateFormat('EEEE, dd MMMM yyyy - HH:mm', 'vi_VN');

        final errorMessage = controller.primaryLoadError;
        if (errorMessage != null && tag == null) {
          return ExpenseErrorState(
            title: 'Không thể tải chi tiết khoản chi',
            subtitle: errorMessage,
            onRetry: controller.retryLoad,
          );
        }

        return SingleChildScrollView(
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
                value: _userName(controller, expense.createdBy),
              ),
              _buildDetailRow(
                context,
                title: 'Người trả tiền',
                value: _userName(controller, expense.paidBy),
              ),
              const Divider(height: 32),
              Text(
                'Danh sách chia tiền',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (expense.splitBetween.isEmpty)
                const EmptyState(
                  icon: Icons.group_off_outlined,
                  title: 'Chưa có người chia tiền',
                  subtitle:
                      'Khoản chi này chưa có danh sách thành viên được chia.',
                )
              else
                ...expense.splitBetween.map(
                  (member) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person),
                    title: _userName(controller, member),
                    trailing: Text(
                      _formatVnd(expense.amount / expense.splitBetween.length),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const Divider(height: 32),
              Text(
                'Lịch sử hoạt động',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ExpenseAuditTimeline(expense: expense),
            ],
          ),
        );
      }),
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

  void _showDeleteConfirm(
    BuildContext context,
    ExpenseController controller,
    Expense expense,
  ) {
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
