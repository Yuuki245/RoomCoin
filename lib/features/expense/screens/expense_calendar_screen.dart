import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/widgets/empty_state.dart';
import '../controllers/expense_controller.dart';
import '../widgets/expense_state_widgets.dart';
import 'expense_detail_screen.dart';

class ExpenseCalendarScreen extends StatefulWidget {
  const ExpenseCalendarScreen({super.key});

  @override
  State<ExpenseCalendarScreen> createState() => _ExpenseCalendarScreenState();
}

class _ExpenseCalendarScreenState extends State<ExpenseCalendarScreen> {
  final ExpenseController controller = Get.put(ExpenseController());
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};
  final NumberFormat _compactCurrency = NumberFormat.compact(locale: 'vi_VN');
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
  final DateFormat _dateFormatter = DateFormat('dd/MM - EEEE', 'vi_VN');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToDate(DateTime date) {
    final firstExpenseId = controller.firstExpenseIdForDay(date);
    if (firstExpenseId == null) {
      return;
    }

    final keyContext = _itemKeys[firstExpenseId]?.currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  void _scrollToDateAfterBuild(DateTime date) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToDate(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiêu nhóm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCalendar(context),
          const Divider(height: 1),
          Expanded(child: _buildExpenseList(context)),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return Obx(() {
      final eventVersion = controller.calendarEvents.length;
      final selectedDate = controller.selectedDate.value;
      final focusedMonth = controller.focusedMonth.value;
      return TableCalendar(
        key: ValueKey('calendar-$eventVersion'),
        locale: 'vi_VN',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedMonth,
        currentDay: DateTime.now(),
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          controller.updateSelectedDate(selectedDay);
          _scrollToDateAfterBuild(selectedDay);
        },
        onPageChanged: controller.updateFocusedMonth,
        eventLoader: (day) => controller.eventsForDay(day),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Tháng',
          CalendarFormat.week: 'Tuần',
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(77),
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) =>
              _buildCalendarCell(context, day, false),
          selectedBuilder: (context, day, focusedDay) =>
              _buildCalendarCell(context, day, true),
          todayBuilder: (context, day, focusedDay) =>
              _buildCalendarCell(context, day, false, isToday: true),
          markerBuilder: (context, day, events) {
            return const SizedBox.shrink();
          },
        ),
      );
    });
  }

  Widget _buildCalendarCell(
    BuildContext context,
    DateTime day,
    bool isSelected, {
    bool isToday = false,
  }) {
    final total = controller.getTotalForDate(day);
    final hasData = total > 0;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : (isToday
                  ? Theme.of(context).colorScheme.primary.withAlpha(77)
                  : Colors.transparent),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (hasData)
            Positioned(
              bottom: 4, // Đẩy xuống dưới cùng một chút
              child: SizedBox(
                width: 40, // Giới hạn chiều rộng tối đa của số tiền trong 1 ô
                child: FittedBox(
                  fit: BoxFit.scaleDown, // TỰ ĐỘNG THU NHỎ nếu chữ quá dài
                  alignment: Alignment.center,
                  child: Text(
                    '${_compactCurrency.format(total)}đ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5, // Ép các chữ số sát nhau hơn cho gọn
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context) {
    return Obx(() {
      if (controller.isInitialLoadingView) {
        return ExpenseListShimmer(controller: _scrollController);
      }

      final errorMessage = controller.primaryLoadError;
      if (errorMessage != null && controller.expenses.isEmpty) {
        return ExpenseErrorState(
          title: 'Không thể tải chi tiêu',
          subtitle: errorMessage,
          onRetry: controller.retryLoad,
        );
      }

      final selectedDate = controller.selectedDate.value;
      final focusedMonth = controller.focusedMonth.value;
      final monthlyExpenses = controller.getExpensesForMonth(focusedMonth);

      if (monthlyExpenses.isEmpty) {
        return const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Không có chi tiêu',
          subtitle: 'Bạn chưa có khoản chi nào trong tháng này.',
        );
      }

      return ListView.builder(
        controller: _scrollController,
        cacheExtent: 720,
        padding: const EdgeInsets.all(16),
        itemCount: monthlyExpenses.length,
        itemBuilder: (context, index) {
          final expense = monthlyExpenses[index];
          final tag = controller.getTagById(expense.tagId);
          final tagColor = tag == null
              ? Theme.of(context).colorScheme.primary
              : Color(int.parse(tag.colorHex.replaceFirst('#', '0xff')));

          return Container(
            key: _itemKeys.putIfAbsent(expense.id, () => GlobalKey()),
            child: Card(
              elevation: 0,
              color: isSameDay(expense.date, selectedDate)
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withAlpha(77),
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Get.to(() => ExpenseDetailScreen(expense: expense));
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: tagColor.withAlpha(51),
                        child: Icon(
                          IconData(
                            tag?.iconCode ?? Icons.receipt_long.codePoint,
                            fontFamily: 'MaterialIcons',
                          ),
                          color: tagColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (expense.note == null ||
                                      expense.note!.trim().isEmpty)
                                  ? controller.tagName(expense.tagId)
                                  : expense.note!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_dateFormatter.format(expense.date)} • Người trả: ${controller.memberName(expense.paidBy)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '-${_currencyFormatter.format(expense.amount)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
