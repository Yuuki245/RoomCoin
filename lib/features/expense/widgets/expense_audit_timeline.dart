import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/expense_controller.dart';
import '../models/audit_log.dart';
import '../models/expense.dart';
import '../../../core/widgets/empty_state.dart';

class ExpenseAuditTimeline extends StatelessWidget {
  final Expense expense;

  const ExpenseAuditTimeline({super.key, required this.expense});

  String _formatVnd(dynamic amount) {
    if (amount == null) return '0 đ';
    final num value = amount is num
        ? amount
        : double.tryParse(amount.toString()) ?? 0;
    final formatted = NumberFormat('#,##0', 'vi_VN').format(value.round());
    return '$formatted đ';
  }

  String _getDiffMessage(ExpenseController controller, AuditLog log) {
    if (log.action == 'CREATE') {
      return 'Đã tạo khoản chi ${_formatVnd(log.newData?['amount'])}';
    }

    if (log.action == 'UPDATE') {
      final oldData = log.oldData ?? {};
      final newData = log.newData ?? {};

      final changes = <String>[];
      if (oldData['amount'] != newData['amount']) {
        changes.add(
          'số tiền từ ${_formatVnd(oldData['amount'])} thành ${_formatVnd(newData['amount'])}',
        );
      }
      if (oldData['paidBy'] != newData['paidBy']) {
        changes.add(
          'người trả từ ${controller.memberName(oldData['paidBy'] as String? ?? '')} thành ${controller.memberName(newData['paidBy'] as String? ?? '')}',
        );
      }
      if (oldData['tagId'] != newData['tagId']) {
        changes.add(
          'danh mục từ ${controller.tagName(oldData['tagId'] as String? ?? '')} thành ${controller.tagName(newData['tagId'] as String? ?? '')}',
        );
      }
      if (oldData['note'] != newData['note']) {
        changes.add('ghi chú');
      }

      if (changes.isEmpty) return 'Đã cập nhật khoản chi';
      return 'Đã cập nhật ${changes.join(', ')}';
    }

    if (log.action == 'DELETE') {
      return 'Đã xóa khoản chi';
    }

    return 'Đã thay đổi dữ liệu';
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.find();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');

    return Obx(() {
      final isLoading = controller.isLoadingLogs.value;
      final logs = controller.currentExpenseLogs;

      if (isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (logs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: EmptyState(
            icon: Icons.history_toggle_off,
            title: 'Chưa có lịch sử',
            subtitle:
                'Khoản chi này chưa có lịch sử hoạt động nào được ghi nhận.',
          ),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          final isFirst = index == 0;
          final isLast = index == logs.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline Connector
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: 2,
                        height: 24,
                        color: isFirst
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: log.action == 'CREATE'
                              ? Colors.green
                              : (log.action == 'UPDATE'
                                    ? Colors.blue
                                    : Colors.red),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isLast
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Timeline Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              controller.memberName(log.uid),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateFormatter.format(log.timestamp),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDiffMessage(controller, log),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
