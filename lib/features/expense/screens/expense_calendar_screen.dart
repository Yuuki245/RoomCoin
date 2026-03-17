import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/expense_controller.dart';
import 'expense_detail_screen.dart';

class ExpenseCalendarScreen extends StatefulWidget {
  const ExpenseCalendarScreen({super.key});

  @override
  State<ExpenseCalendarScreen> createState() => _ExpenseCalendarScreenState();
}

class _ExpenseCalendarScreenState extends State<ExpenseCalendarScreen> {
  final ExpenseController controller = Get.put(ExpenseController());
  final ScrollController _scrollController = ScrollController();
  final Map<DateTime, GlobalKey> _itemKeys = {};
  final NumberFormat _compactCurrency = NumberFormat.compact(locale: 'vi_VN');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToDate(DateTime date) {
    // Tìm expense đầu tiên có cùng ngày để cuộn tới
    final expenses = controller.getExpensesForMonth(controller.selectedDate.value);
    final targetExpense = expenses.firstWhereOrNull((e) => isSameDay(e.date, date));
    
    if (targetExpense != null && _itemKeys.containsKey(targetExpense.date)) {
      final keyContext = _itemKeys[targetExpense.date]?.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1, // Hơi căn xuống một chút
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiêu nhóm', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCalendar(context),
          const Divider(height: 1),
          Expanded(
            child: _buildExpenseList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return Obx(() {
      return TableCalendar(
        locale: 'vi_VN',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: controller.selectedDate.value,
        currentDay: DateTime.now(),
        selectedDayPredicate: (day) => isSameDay(controller.selectedDate.value, day),
        onDaySelected: (selectedDay, focusedDay) {
          controller.updateSelectedDate(selectedDay);
          // Đợi một chút để danh sách build xong (nếu chuyển tháng) rồi mới cuộn
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToDate(selectedDay);
          });
        },
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
          defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(context, day, false),
          selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(context, day, true),
          todayBuilder: (context, day, focusedDay) => _buildCalendarCell(context, day, false, isToday: true),
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            final total = controller.getTotalForDate(day);
            return Positioned(
              bottom: 2,
              child: Text(
                '${_compactCurrency.format(total)}đ',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildCalendarCell(BuildContext context, DateTime day, bool isSelected, {bool isToday = false}) {
    final total = controller.getTotalForDate(day);
    bool hasData = total > 0;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : (isToday ? Theme.of(context).colorScheme.primary.withAlpha(77) : Colors.transparent),
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
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (hasData)
            Positioned(
              bottom: 2,
              child: Text(
                '${_compactCurrency.format(total)}đ',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('dd/MM - EEEE', 'vi_VN');

    return Obx(() {
      // Chỉ hiển thị dữ liệu khi đã map xong Users + Tags + batch đầu tiên của Stream
      if (controller.isInitialLoadingView) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              highlightColor: Theme.of(context).colorScheme.surface,
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SizedBox(height: 12, width: double.infinity, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
                            SizedBox(height: 8),
                            SizedBox(height: 10, width: 180, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const SizedBox(height: 12, width: 64, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }

      final monthlyExpenses = controller.getExpensesForMonth(controller.selectedDate.value);
      
      if (monthlyExpenses.isEmpty) {
        return const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Không có chi tiêu',
          subtitle: 'Bạn chưa có khoản chi nào trong tháng này.',
        );
      }

      // Format lại keys cho cuộn
      _itemKeys.clear();
      for (var expense in monthlyExpenses) {
        _itemKeys.putIfAbsent(expense.date, () => GlobalKey());
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: monthlyExpenses.length,
        itemBuilder: (context, index) {
          final expense = monthlyExpenses[index];
          final tag = controller.getTagById(expense.tagId);
          
          return Container(
            key: _itemKeys[expense.date], // Gắn Key cho item đầu tiên của ngày
            child: Card(
              elevation: 0,
              color: isSameDay(expense.date, controller.selectedDate.value)
                  ? Theme.of(context).colorScheme.primaryContainer // Highlight item của ngày đang chọn
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
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
                        backgroundColor: Color(int.parse(tag.colorHex.replaceFirst('#', '0xff'))).withAlpha(51),
                        child: Icon(
                          IconData(tag.iconCode, fontFamily: 'MaterialIcons'),
                          color: Color(int.parse(tag.colorHex.replaceFirst('#', '0xff'))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (expense.note == null || expense.note!.trim().isEmpty)
                                  ? controller.tagName(expense.tagId)
                                  : expense.note!,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dateFormatter.format(expense.date)} • Người trả: ${controller.memberName(expense.paidBy)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '-${currencyFormatter.format(expense.amount)}',
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
