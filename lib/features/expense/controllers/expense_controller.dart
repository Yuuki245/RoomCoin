import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/expense.dart';
import '../models/tag.dart';
import '../repositories/expense_repository.dart';
import '../../room/repositories/room_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class MemberOption {
  final String uid;
  final String displayName;
  const MemberOption({required this.uid, required this.displayName});
}

class ExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final RoomRepository _roomRepository = RoomRepository();
  final AuthRepository _authRepository = AuthRepository();
  final AuthController _authController = Get.find<AuthController>();

  // Trạng thái ngày đang chọn trên lịch
  var selectedDate = DateTime.now().obs;

  // Danh sách Tag
  var tags = <Tag>[].obs;

  // Danh sách Chi tiêu
  var expenses = <Expense>[].obs;

  /// Map sự kiện cho TableCalendar: key là ngày (yyyy-mm-dd, đã normalize), value là danh sách chi tiêu của ngày đó
  final RxMap<DateTime, List<Expense>> calendarEvents = <DateTime, List<Expense>>{}.obs;

  // Members của phòng (UID + tên hiển thị)
  final members = <MemberOption>[].obs;

  final RxBool isLoadingTags = true.obs;
  final RxBool isLoadingExpenses = true.obs;
  final RxBool isLoadingMembers = true.obs;
  final RxBool isSaving = false.obs;

  String? get currentUid => _authRepository.currentUid;
  String? _boundRoomId;
  Worker? _roomWorker;
  Worker? _expensesWorker;

  bool get isInitialLoadingView => isLoadingMembers.value || isLoadingTags.value || isLoadingExpenses.value;

  @override
  void onInit() {
    super.onInit();
    _expensesWorker = ever(expenses, (_) {
      _rebuildCalendarEvents();
    });

    _roomWorker = ever<String>(_authController.roomId, (id) async {
      final roomId = id.trim();
      if (roomId.isEmpty) return;
      if (_boundRoomId == roomId) return;

      _boundRoomId = roomId;
      // ignore: avoid_print
      print('[StreamFix] Khởi động lắng nghe cho Room: $roomId');

      // làm sạch stream cũ + state cũ trước khi bind stream mới
      expenses.bindStream(const Stream<List<Expense>>.empty());
      expenses.clear();
      calendarEvents.clear();
      members.clear();
      tags.clear();
      isLoadingMembers.value = true;
      isLoadingTags.value = true;
      isLoadingExpenses.value = true;

      // bind lại theo roomId mới
      await _loadMembers(roomId);
      _loadTagsMock(roomId);
      _bindExpenses(roomId);
    });

    // nếu roomId đã có sẵn ngay từ đầu
    final initial = _authController.roomId.value.trim();
    if (initial.isNotEmpty) {
      _boundRoomId = initial;
      // ignore: avoid_print
      print('[StreamFix] Khởi động lắng nghe cho Room: $initial');
      isLoadingMembers.value = true;
      isLoadingTags.value = true;
      isLoadingExpenses.value = true;
      _loadMembers(initial).then((_) {
        _loadTagsMock(initial);
        _bindExpenses(initial);
      });
    }
  }

  DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  void _rebuildCalendarEvents() {
    final map = <DateTime, List<Expense>>{};
    for (final e in expenses) {
      final key = _normalizeDay(e.date);
      (map[key] ??= <Expense>[]).add(e);
    }
    calendarEvents.assignAll(map);
  }

  List<Expense> eventsForDay(DateTime day) {
    return calendarEvents[_normalizeDay(day)] ?? const <Expense>[];
  }

  Future<void> _loadMembers(String roomId) async {
    isLoadingMembers.value = true;
    final room = await _roomRepository.getRoom(roomId);
    final memberUids = room?.members ?? const <String>[];
    if (memberUids.isEmpty) {
      members.assignAll(const []);
      isLoadingMembers.value = false;
      return;
    }

    // Best-effort map UID -> displayName bằng cách đọc users/{uid}
    final db = FirebaseFirestore.instance;
    final results = <MemberOption>[];
    for (final mUid in memberUids) {
      try {
        final snap = await db.collection('users').doc(mUid).get();
        final data = snap.data();
        final displayName = data == null
            ? 'Nguyễn Văn A'
            : (data['displayName'] as String?) ?? (data['name'] as String?) ?? 'Nguyễn Văn A';
        results.add(MemberOption(uid: mUid, displayName: displayName));
      } catch (_) {
        results.add(MemberOption(uid: mUid, displayName: 'Nguyễn Văn A'));
      }
    }
    members.assignAll(results);
    isLoadingMembers.value = false;
  }

  void _loadTagsMock(String roomId) {
    isLoadingTags.value = true;
    tags.value = [
      Tag(id: 't1', name: 'Ăn uống', iconCode: Icons.restaurant.codePoint, colorHex: '#FF5722', roomId: roomId),
      Tag(id: 't2', name: 'Tiền điện', iconCode: Icons.electrical_services.codePoint, colorHex: '#FFC107', roomId: roomId),
      Tag(id: 't3', name: 'Đi chợ', iconCode: Icons.local_grocery_store.codePoint, colorHex: '#4CAF50', roomId: roomId),
      Tag(id: 't4', name: 'Tiền nhà', iconCode: Icons.house.codePoint, colorHex: '#2196F3', roomId: roomId),
      Tag(id: 't5', name: 'Đi lại', iconCode: Icons.directions_bus.codePoint, colorHex: '#9C27B0', roomId: roomId),
      Tag(id: 't6', name: 'Y tế', iconCode: Icons.medical_services.codePoint, colorHex: '#E91E63', roomId: roomId),
      Tag(id: 't7', name: 'Internet', iconCode: Icons.wifi.codePoint, colorHex: '#00BCD4', roomId: roomId),
    ];
    isLoadingTags.value = false;
  }

  void _bindExpenses(String roomId) {
    isLoadingExpenses.value = true;
    final stream = _expenseRepository.streamExpensesByRoom(roomId);
    expenses.bindStream(stream);
    stream.first.then((_) {
      isLoadingExpenses.value = false;
    }).catchError((_) {
      isLoadingExpenses.value = false;
    });
  }

  void updateSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  List<Expense> getExpensesForDate(DateTime date) {
    return eventsForDay(date);
  }

  List<Expense> getExpensesForMonth(DateTime date) {
    final list = expenses.where((element) => 
      element.date.year == date.year && 
      element.date.month == date.month
    ).toList();
    // Sort by date descending (mới nhất lên đầu)
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double getTotalForDate(DateTime date) {
    final dailyExpenses = getExpensesForDate(date);
    return dailyExpenses.fold(0, (total, item) => total + item.amount);
  }

  Future<void> addExpense({
    required double amount,
    required String paidByUid,
    required List<String> splitBetweenUids,
    required String tagId,
    required DateTime date,
    String? note,
  }) async {
    final uid = _authRepository.currentUid;
    if (uid == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final user = await _authRepository.getUser(uid);
    final roomId = user?.roomId;
    if (roomId == null || roomId.isEmpty) {
      throw Exception('Bạn chưa tham gia phòng.');
    }

    isSaving.value = true;
    try {
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
    } finally {
      isSaving.value = false;
    }
  }

  void deleteExpense(String id) {
    expenses.removeWhere((element) => element.id == id);
  }

  Tag getTagById(String tagId) {
    return tags.firstWhere((element) => element.id == tagId, orElse: () => tags.first);
  }

  String memberName(String uid) {
    final m = members.firstWhereOrNull((e) => e.uid == uid);
    return m?.displayName ?? 'Người dùng';
  }

  String tagName(String tagId) {
    final t = tags.firstWhereOrNull((e) => e.id == tagId);
    return t?.name ?? 'Danh mục';
  }

  @override
  void onClose() {
    _roomWorker?.dispose();
    _expensesWorker?.dispose();
    super.onClose();
  }

}
