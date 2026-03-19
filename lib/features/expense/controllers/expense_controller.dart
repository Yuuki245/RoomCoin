import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../room/repositories/room_repository.dart';
import '../models/expense.dart';
import '../models/member_option.dart';
import '../models/tag.dart';
import '../repositories/expense_repository.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final RoomRepository _roomRepository = RoomRepository();
  final AuthRepository _authRepository = AuthRepository();
  final AuthController _authController = Get.find<AuthController>();

  final selectedDate = DateTime.now().obs;
  final tags = <Tag>[].obs;
  final expenses = <Expense>[].obs;
  final RxMap<DateTime, List<Expense>> calendarEvents =
      <DateTime, List<Expense>>{}.obs;
  final RxMap<DateTime, double> dailyTotals = <DateTime, double>{}.obs;
  final RxMap<String, List<Expense>> monthlyExpensesLookup =
      <String, List<Expense>>{}.obs;
  final RxMap<String, Tag> tagLookup = <String, Tag>{}.obs;
  final RxMap<String, String> memberNameLookup = <String, String>{}.obs;
  final members = <MemberOption>[].obs;
  final RxBool isLoadingTags = true.obs;
  final RxBool isLoadingExpenses = true.obs;
  final RxBool isLoadingMembers = true.obs;
  final RxBool isSaving = false.obs;

  String? get currentUid => _authRepository.currentUid;

  String? _boundRoomId;
  int _roomRequestId = 0;
  Worker? _roomWorker;
  Worker? _expensesWorker;
  Worker? _tagsWorker;
  Worker? _membersWorker;
  StreamSubscription<List<Expense>>? _expenseSubscription;

  bool get isInitialLoadingView {
    return isLoadingMembers.value ||
        isLoadingTags.value ||
        isLoadingExpenses.value;
  }

  @override
  void onInit() {
    super.onInit();

    _expensesWorker = ever(expenses, (_) {
      _rebuildExpenseDerivedData();
    });

    _tagsWorker = ever(tags, (_) {
      _rebuildTagLookup();
    });

    _membersWorker = ever(members, (_) {
      _rebuildMemberLookup();
    });

    _roomWorker = ever<String>(_authController.roomId, (id) {
      _handleRoomChange(id);
    });

    _handleRoomChange(_authController.roomId.value);
  }

  Future<void> _handleRoomChange(String rawRoomId) async {
    final roomId = rawRoomId.trim();
    final requestId = ++_roomRequestId;

    if (roomId.isEmpty) {
      _boundRoomId = null;
      await _clearRoomState();
      return;
    }

    if (_boundRoomId == roomId) {
      return;
    }

    _boundRoomId = roomId;
    await _clearRoomState();
    isLoadingMembers.value = true;
    isLoadingTags.value = true;
    isLoadingExpenses.value = true;

    try {
      await _loadMembers(roomId, requestId);
      await _loadTagsMock(roomId, requestId);
      if (!_isActiveRequest(requestId, roomId)) {
        return;
      }
      await _bindExpenses(roomId, requestId);
    } catch (_) {
      if (_isActiveRequest(requestId, roomId)) {
        isLoadingMembers.value = false;
        isLoadingTags.value = false;
        isLoadingExpenses.value = false;
        Get.snackbar(
          'Lỗi',
          'Không thể tải dữ liệu chi tiêu. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  bool _isActiveRequest(int requestId, String roomId) {
    return _roomRequestId == requestId && _boundRoomId == roomId;
  }

  Future<void> _clearRoomState() async {
    await _expenseSubscription?.cancel();
    _expenseSubscription = null;
    expenses.clear();
    calendarEvents.clear();
    dailyTotals.clear();
    monthlyExpensesLookup.clear();
    tagLookup.clear();
    memberNameLookup.clear();
    members.clear();
    tags.clear();
    isLoadingMembers.value = false;
    isLoadingTags.value = false;
    isLoadingExpenses.value = false;
  }

  DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _rebuildExpenseDerivedData() {
    final eventMap = <DateTime, List<Expense>>{};
    final totalMap = <DateTime, double>{};
    final monthlyMap = <String, List<Expense>>{};

    for (final expense in expenses) {
      final key = _normalizeDay(expense.date);
      (eventMap[key] ??= <Expense>[]).add(expense);
      totalMap[key] = (totalMap[key] ?? 0) + expense.amount;
      (monthlyMap[_monthKey(expense.date)] ??= <Expense>[]).add(expense);
    }

    for (final list in monthlyMap.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }

    calendarEvents.assignAll(eventMap);
    dailyTotals.assignAll(totalMap);
    monthlyExpensesLookup.assignAll(monthlyMap);
  }

  void _rebuildTagLookup() {
    tagLookup.assignAll({for (final tag in tags) tag.id: tag});
  }

  void _rebuildMemberLookup() {
    memberNameLookup.assignAll({
      for (final member in members) member.uid: member.displayName,
    });
  }

  List<Expense> eventsForDay(DateTime day) {
    return calendarEvents[_normalizeDay(day)] ?? const <Expense>[];
  }

  Future<void> _loadMembers(String roomId, int requestId) async {
    isLoadingMembers.value = true;
    try {
      final room = await _roomRepository.getRoom(roomId);
      final memberUids = room?.members ?? const <String>[];
      final result = await _expenseRepository.getMemberOptions(memberUids);
      if (_isActiveRequest(requestId, roomId)) {
        members.assignAll(result);
      }
    } catch (_) {
      if (_isActiveRequest(requestId, roomId)) {
        members.assignAll(const <MemberOption>[]);
      }
      rethrow;
    } finally {
      if (_isActiveRequest(requestId, roomId)) {
        isLoadingMembers.value = false;
      }
    }
  }

  Future<void> _loadTagsMock(String roomId, int requestId) async {
    isLoadingTags.value = true;
    try {
      final mockTags = <Tag>[
        Tag(
          id: 't1',
          name: 'Ăn uống',
          iconCode: Icons.restaurant.codePoint,
          colorHex: '#FF5722',
          roomId: roomId,
        ),
        Tag(
          id: 't2',
          name: 'Tiền điện',
          iconCode: Icons.electrical_services.codePoint,
          colorHex: '#FFC107',
          roomId: roomId,
        ),
        Tag(
          id: 't3',
          name: 'Đi chợ',
          iconCode: Icons.local_grocery_store.codePoint,
          colorHex: '#4CAF50',
          roomId: roomId,
        ),
        Tag(
          id: 't4',
          name: 'Tiền nhà',
          iconCode: Icons.house.codePoint,
          colorHex: '#2196F3',
          roomId: roomId,
        ),
        Tag(
          id: 't5',
          name: 'Đi lại',
          iconCode: Icons.directions_bus.codePoint,
          colorHex: '#9C27B0',
          roomId: roomId,
        ),
        Tag(
          id: 't6',
          name: 'Y tế',
          iconCode: Icons.medical_services.codePoint,
          colorHex: '#E91E63',
          roomId: roomId,
        ),
        Tag(
          id: 't7',
          name: 'Internet',
          iconCode: Icons.wifi.codePoint,
          colorHex: '#00BCD4',
          roomId: roomId,
        ),
      ];
      if (_isActiveRequest(requestId, roomId)) {
        tags.assignAll(mockTags);
      }
    } finally {
      if (_isActiveRequest(requestId, roomId)) {
        isLoadingTags.value = false;
      }
    }
  }

  Future<void> _bindExpenses(String roomId, int requestId) async {
    isLoadingExpenses.value = true;
    await _expenseSubscription?.cancel();
    _expenseSubscription = _expenseRepository
        .streamExpensesByRoom(roomId)
        .listen(
          (items) {
            if (!_isActiveRequest(requestId, roomId)) {
              return;
            }
            expenses.assignAll(items);
            isLoadingExpenses.value = false;
          },
          onError: (_) {
            if (!_isActiveRequest(requestId, roomId)) {
              return;
            }
            expenses.clear();
            isLoadingExpenses.value = false;
            Get.snackbar(
              'Lỗi',
              'Không thể tải danh sách chi tiêu. Vui lòng thử lại.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        );
  }

  void updateSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  List<Expense> getExpensesForDate(DateTime date) {
    return eventsForDay(date);
  }

  List<Expense> getExpensesForMonth(DateTime date) {
    return monthlyExpensesLookup[_monthKey(date)] ?? const <Expense>[];
  }

  double getTotalForDate(DateTime date) {
    return dailyTotals[_normalizeDay(date)] ?? 0;
  }

  Future<void> addExpense({
    required double amount,
    required String paidByUid,
    required List<String> splitBetweenUids,
    required String tagId,
    required DateTime date,
    String? note,
  }) async {
    if (isSaving.value) {
      return;
    }

    isSaving.value = true;
    try {
      final uid = _authRepository.currentUid;
      if (uid == null) {
        throw Exception('Bạn chưa đăng nhập.');
      }

      final user = await _authRepository.getUser(uid);
      final roomId = user?.roomId;
      if (roomId == null || roomId.isEmpty) {
        throw Exception('Bạn chưa tham gia phòng.');
      }

      final expense = Expense(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        amount: amount,
        paidBy: paidByUid,
        createdBy: uid,
        splitBetween: splitBetweenUids,
        tagId: tagId,
        date: date,
        note: note,
        createdAt: DateTime.now(),
      );
      await _expenseRepository.addExpense(expense);
      selectedDate.value = date;
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Không thể lưu khoản chi. Vui lòng thử lại.';
      Get.snackbar('Lỗi', message, snackPosition: SnackPosition.BOTTOM);
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _expenseRepository.deleteExpense(id);
    } catch (_) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa khoản chi. Vui lòng thử lại.',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Tag? getTagById(String tagId) {
    return tagLookup[tagId] ?? tags.firstOrNull;
  }

  String memberName(String uid) {
    return memberNameLookup[uid] ?? 'Người dùng';
  }

  String tagName(String tagId) {
    return tagLookup[tagId]?.name ?? 'Danh mục';
  }

  @override
  void onClose() {
    _expenseSubscription?.cancel();
    _roomWorker?.dispose();
    _expensesWorker?.dispose();
    _tagsWorker?.dispose();
    _membersWorker?.dispose();
    super.onClose();
  }
}
