import 'dart:async';

import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../room/models/room_model.dart';
import '../../room/repositories/room_repository.dart';
import '../models/audit_log.dart';
import '../models/expense.dart';
import '../models/member_option.dart';
import '../models/tag.dart';
import '../repositories/audit_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/tag_repository.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final AuditRepository _auditRepository = AuditRepository();
  final TagRepository _tagRepository = TagRepository();
  final RoomRepository _roomRepository = RoomRepository();
  final AuthRepository _authRepository = AuthRepository();
  final AuthController _authController = Get.find<AuthController>();

  final selectedDate = DateTime.now().obs;
  final focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  ).obs;
  final tags = <Tag>[].obs;
  final expenses = <Expense>[].obs;
  final members = <MemberOption>[].obs;
  final RxList<String> activeMemberUids = <String>[].obs;
  final Rxn<RoomModel> currentRoom = Rxn<RoomModel>();

  final RxMap<DateTime, List<Expense>> calendarEvents =
      <DateTime, List<Expense>>{}.obs;
  final RxMap<DateTime, double> dailyTotals = <DateTime, double>{}.obs;
  final RxMap<DateTime, String> firstExpenseIdByDay = <DateTime, String>{}.obs;
  final RxMap<String, List<Expense>> monthlyExpensesLookup =
      <String, List<Expense>>{}.obs;
  final RxMap<String, Tag> tagLookup = <String, Tag>{}.obs;
  final RxMap<String, String> memberNameLookup = <String, String>{}.obs;

  final RxList<AuditLog> currentExpenseLogs = <AuditLog>[].obs;
  final RxBool isLoadingLogs = false.obs;

  final RxBool isLoadingTags = true.obs;
  final RxBool isLoadingExpenses = true.obs;
  final RxBool isLoadingMembers = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString membersErrorMessage = RxnString();
  final RxnString tagsErrorMessage = RxnString();
  final RxnString expensesErrorMessage = RxnString();

  String? get currentUid => _authRepository.currentUid;

  List<MemberOption> get activeRoomMembers {
    final room = currentRoom.value;
    if (room == null || members.isEmpty) return const [];
    return members.where((m) => room.members.contains(m.uid)).toList();
  }

  String? _boundRoomId;

  int _roomRequestId = 0;
  Worker? _roomWorker;
  Worker? _focusedMonthWorker;
  Worker? _expensesWorker;
  Worker? _tagsWorker;
  Worker? _membersWorker;
  StreamSubscription<RoomModel?>? _roomSubscription;
  StreamSubscription<List<Tag>>? _tagSubscription;
  final Map<String, StreamSubscription<List<Expense>>> _expenseSubscriptions =
      <String, StreamSubscription<List<Expense>>>{};
  final Map<String, List<Expense>> _monthExpenseStore =
      <String, List<Expense>>{};

  bool get isInitialLoadingView {
    return isLoadingMembers.value ||
        isLoadingTags.value ||
        isLoadingExpenses.value;
  }

  String? get primaryLoadError {
    return membersErrorMessage.value ??
        tagsErrorMessage.value ??
        expensesErrorMessage.value;
  }

  @override
  void onInit() {
    super.onInit();

    _expensesWorker = ever<List<Expense>>(expenses, (_) {
      _rebuildExpenseDerivedData();
      _fetchMissingHistoricalMembers();
    });

    _tagsWorker = ever<List<Tag>>(tags, (_) {
      _rebuildTagLookup();
    });

    _membersWorker = ever<List<MemberOption>>(members, (_) {
      _rebuildMemberLookup();
    });

    _focusedMonthWorker = ever<DateTime>(focusedMonth, (month) {
      final roomId = _boundRoomId;
      if (roomId == null || roomId.isEmpty) {
        return;
      }
      _syncExpenseMonths(roomId, _roomRequestId);
    });

    _roomWorker = ever<String>(_authController.roomId, (roomId) {
      _handleRoomChange(roomId);
    });

    _handleRoomChange(_authController.roomId.value);
  }

  Future<void> _handleRoomChange(
    String rawRoomId, {
    bool forceReload = false,
  }) async {
    final roomId = rawRoomId.trim();
    final requestId = ++_roomRequestId;

    if (roomId.isEmpty) {
      _boundRoomId = null;
      await _clearRoomState();
      return;
    }

    if (!forceReload && _boundRoomId == roomId) {
      return;
    }

    _boundRoomId = roomId;
    await _clearRoomState();
    isLoadingMembers.value = true;
    isLoadingTags.value = true;
    isLoadingExpenses.value = true;
    membersErrorMessage.value = null;
    tagsErrorMessage.value = null;
    expensesErrorMessage.value = null;

    try {
      await _listenToRoomAndMembers(roomId, requestId);
      await _bindTags(roomId, requestId);
      if (!_isActiveRequest(requestId, roomId)) {
        return;
      }
      await _syncExpenseMonths(roomId, requestId);
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
    await _roomSubscription?.cancel();
    _roomSubscription = null;
    await _tagSubscription?.cancel();
    _tagSubscription = null;
    for (final subscription in _expenseSubscriptions.values) {
      await subscription.cancel();
    }
    _expenseSubscriptions.clear();
    _monthExpenseStore.clear();

    expenses.clear();
    tags.clear();
    members.clear();
    activeMemberUids.clear();
    currentRoom.value = null;
    calendarEvents.clear();
    dailyTotals.clear();
    firstExpenseIdByDay.clear();
    monthlyExpensesLookup.clear();
    tagLookup.clear();
    memberNameLookup.clear();
    currentExpenseLogs.clear();
    isLoadingLogs.value = false;
    membersErrorMessage.value = null;
    tagsErrorMessage.value = null;
    expensesErrorMessage.value = null;

    isLoadingMembers.value = false;
    isLoadingTags.value = false;
    isLoadingExpenses.value = false;
  }

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

  Set<String> _requiredMonthKeys() {
    final now = DateTime.now();
    return <String>{
      _monthKey(DateTime(now.year, now.month, 1)),
      _monthKey(focusedMonth.value),
    };
  }

  DateTime _monthStart(DateTime value) => DateTime(value.year, value.month, 1);

  DateTime _monthStartFromKey(String monthKey) {
    final parts = monthKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  void _combineTrackedExpenses() {
    final combined =
        _monthExpenseStore.values
            .expand((items) => items)
            .toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
    expenses.assignAll(combined);
  }

  void _rebuildExpenseDerivedData() {
    final eventMap = <DateTime, List<Expense>>{};
    final totalMap = <DateTime, double>{};
    final firstExpenseMap = <DateTime, String>{};
    final monthlyMap = <String, List<Expense>>{};

    for (final expense in expenses) {
      final normalizedDay = _normalizeDay(expense.date);
      (eventMap[normalizedDay] ??= <Expense>[]).add(expense);
      totalMap[normalizedDay] = (totalMap[normalizedDay] ?? 0) + expense.amount;
      firstExpenseMap.putIfAbsent(normalizedDay, () => expense.id);
      (monthlyMap[_monthKey(expense.date)] ??= <Expense>[]).add(expense);
    }

    for (final list in monthlyMap.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }

    calendarEvents.assignAll(eventMap);
    dailyTotals.assignAll(totalMap);
    firstExpenseIdByDay.assignAll(firstExpenseMap);
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

  Future<void> _listenToRoomAndMembers(String roomId, int requestId) async {
    isLoadingMembers.value = true;
    final completer = Completer<void>();
    await _roomSubscription?.cancel();

    _roomSubscription = _roomRepository
        .streamRoom(roomId)
        .listen(
          (roomData) async {
            if (!_isActiveRequest(requestId, roomId)) return;
            if (roomData == null) {
              if (!completer.isCompleted) {
                membersErrorMessage.value = 'Phòng không tồn tại.';
                isLoadingMembers.value = false;
                completer.completeError('Phòng không tồn tại');
              }
              return;
            }

            currentRoom.value = roomData;
            activeMemberUids.assignAll(roomData.members);

            try {
              final historicalUids = _extractAllHistoricalUids();
              final combinedUids = {
                ...roomData.members,
                ...historicalUids,
              }.toList();

              final result = await _expenseRepository.getMemberOptions(
                combinedUids,
              );
              if (!_isActiveRequest(requestId, roomId)) return;

              members.assignAll(result);
              // Worker sẽ tự động gọi _rebuildMemberLookup
              membersErrorMessage.value = null;
            } catch (_) {
              membersErrorMessage.value = 'Không thể tải danh sách thành viên.';
            } finally {
              isLoadingMembers.value = false;
              if (!completer.isCompleted) completer.complete();
            }
          },
          onError: (_) {
            if (!_isActiveRequest(requestId, roomId)) return;
            if (!completer.isCompleted) {
              membersErrorMessage.value = 'Lỗi kết nối CSDL.';
              isLoadingMembers.value = false;
              completer.completeError('Connection Error');
            }
          },
        );

    try {
      await completer.future;
    } catch (_) {}
  }

  Set<String> _extractAllHistoricalUids() {
    final uids = <String>{};
    for (final e in expenses) {
      if (!memberNameLookup.containsKey(e.paidBy)) uids.add(e.paidBy);
      for (final p in e.splitBetween) {
        if (!memberNameLookup.containsKey(p)) uids.add(p);
      }
    }
    return uids;
  }

  Future<void> _fetchMissingHistoricalMembers() async {
    final missingUids = _extractAllHistoricalUids();
    if (missingUids.isEmpty) return;

    try {
      final newMembers = await _expenseRepository.getMemberOptions(
        missingUids.toList(),
      );
      if (newMembers.isNotEmpty) {
        final currentMap = {for (final m in members) m.uid: m};
        for (final m in newMembers) {
          currentMap[m.uid] = m;
        }
        members.assignAll(currentMap.values);
      }
    } catch (_) {}
  }

  Future<void> _bindTags(String roomId, int requestId) async {
    isLoadingTags.value = true;
    await _tagRepository.ensureDefaultTags(roomId);
    if (!_isActiveRequest(requestId, roomId)) {
      return;
    }

    await _tagSubscription?.cancel();
    final completer = Completer<void>();
    _tagSubscription = _tagRepository
        .streamTagsByRoom(roomId)
        .listen(
          (items) {
            if (!_isActiveRequest(requestId, roomId)) {
              return;
            }
            tags.assignAll(items);
            isLoadingTags.value = false;
            tagsErrorMessage.value = null;
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onError: (_) {
            if (!_isActiveRequest(requestId, roomId)) {
              return;
            }
            tags.clear();
            isLoadingTags.value = false;
            tagsErrorMessage.value = 'Không thể tải danh mục chi tiêu.';
            if (!completer.isCompleted) {
              completer.completeError(
                Exception('Không thể tải danh mục chi tiêu.'),
              );
              return;
            }
            Get.snackbar(
              'Lỗi',
              'Không thể tải danh mục chi tiêu. Vui lòng thử lại.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        );
    await completer.future;
  }

  Future<void> _syncExpenseMonths(String roomId, int requestId) async {
    isLoadingExpenses.value = true;
    final requiredKeys = _requiredMonthKeys();
    final obsoleteKeys = _expenseSubscriptions.keys
        .where((key) => !requiredKeys.contains(key))
        .toList(growable: false);

    for (final key in obsoleteKeys) {
      await _expenseSubscriptions.remove(key)?.cancel();
      _monthExpenseStore.remove(key);
    }

    if (obsoleteKeys.isNotEmpty) {
      _combineTrackedExpenses();
    }

    final pendingLoads = <Future<void>>[];
    for (final monthKey in requiredKeys) {
      if (_expenseSubscriptions.containsKey(monthKey)) {
        continue;
      }

      final completer = Completer<void>();
      final month = _monthStartFromKey(monthKey);
      final subscription = _expenseRepository
          .streamExpensesByRoomMonth(roomId, month)
          .listen(
            (items) {
              if (!_isActiveRequest(requestId, roomId)) {
                return;
              }
              _monthExpenseStore[monthKey] = items;
              _combineTrackedExpenses();
              isLoadingExpenses.value = false;
              expensesErrorMessage.value = null;
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            onError: (_) {
              if (!_isActiveRequest(requestId, roomId)) {
                return;
              }
              _monthExpenseStore.remove(monthKey);
              _combineTrackedExpenses();
              isLoadingExpenses.value = false;
              expensesErrorMessage.value = 'Không thể tải danh sách chi tiêu.';
              if (!completer.isCompleted) {
                completer.completeError(
                  Exception('Không thể tải danh sách chi tiêu.'),
                );
                return;
              }
              Get.snackbar(
                'Lỗi',
                'Không thể tải danh sách chi tiêu. Vui lòng thử lại.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          );

      _expenseSubscriptions[monthKey] = subscription;
      pendingLoads.add(completer.future);
    }

    if (pendingLoads.isEmpty) {
      isLoadingExpenses.value = false;
      expensesErrorMessage.value = null;
      _combineTrackedExpenses();
      return;
    }

    await Future.wait(pendingLoads);
  }

  void updateSelectedDate(DateTime date) {
    selectedDate.value = date;
    focusedMonth.value = _monthStart(date);
  }

  void updateFocusedMonth(DateTime date) {
    focusedMonth.value = _monthStart(date);
  }

  Future<void> retryLoad() async {
    await _handleRoomChange(_authController.roomId.value, forceReload: true);
  }

  List<Expense> eventsForDay(DateTime day) {
    return calendarEvents[_normalizeDay(day)] ?? const <Expense>[];
  }

  String? firstExpenseIdForDay(DateTime day) {
    return firstExpenseIdByDay[_normalizeDay(day)];
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

  Future<void> fetchLogs(String expenseId) async {
    if (isLoadingLogs.value) return;

    isLoadingLogs.value = true;
    try {
      final logs = await _auditRepository.getLogsByExpenseId(expenseId);
      currentExpenseLogs.assignAll(logs);
    } catch (_) {
      // Sliently fail for logs, user just won't see them
      currentExpenseLogs.clear();
    } finally {
      isLoadingLogs.value = false;
    }
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

      if (!activeMemberUids.contains(paidByUid)) {
        throw Exception(
          'Người trả tiền đã rời phòng. Không thể thêm hóa đơn cho người này.',
        );
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
      final newId = await _expenseRepository.addExpense(expense);
      // Fire-and-forget audit log with post-completion fetch
      _auditRepository
          .logAction(
            AuditLog(
              uid: uid,
              action: 'CREATE',
              expenseId: newId,
              oldData: null,
              newData: expense.toMap(),
              timestamp: DateTime.now(),
            ),
          )
          .then((_) => fetchLogs(newId));
      selectedDate.value = date;
      focusedMonth.value = _monthStart(date);
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

  Future<void> updateExpense(Expense expense) async {
    if (isSaving.value) {
      return;
    }

    isSaving.value = true;
    try {
      final oldExpense = expenses.firstWhereOrNull((e) => e.id == expense.id);
      if (oldExpense == null) throw Exception('Hóa đơn không tồn tại.');

      final uid = _authRepository.currentUid;
      final adminId = currentRoom.value?.adminId;

      if (oldExpense.createdBy != uid && adminId != uid) {
        throw Exception(
          'Chỉ người tạo hóa đơn hoặc Quản trị viên mới có quyền sửa!',
        );
      }

      if (expense.paidBy != oldExpense.paidBy &&
          !activeMemberUids.contains(expense.paidBy)) {
        throw Exception('Người trả tiền mới thao tác đã rời phòng!');
      }

      await _expenseRepository.updateExpense(expense);
      // Fire-and-forget audit log with post-completion fetch
      _auditRepository
          .logAction(
            AuditLog(
              uid: _authRepository.currentUid ?? '',
              action: 'UPDATE',
              expenseId: expense.id,
              oldData: oldExpense.toMap(),
              newData: expense.toMap(),
              timestamp: DateTime.now(),
            ),
          )
          .then((_) => fetchLogs(expense.id));
      selectedDate.value = expense.date;
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Không thể cập nhật khoản chi. Vui lòng thử lại.';
      Get.snackbar('Lỗi', message, snackPosition: SnackPosition.BOTTOM);
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final oldExpense = expenses.firstWhereOrNull((e) => e.id == id);
      if (oldExpense == null) throw Exception('Hóa đơn không tồn tại.');

      final uid = _authRepository.currentUid;
      final adminId = currentRoom.value?.adminId;

      if (oldExpense.createdBy != uid && adminId != uid) {
        throw Exception('Chỉ người tạo hoặc Quản trị viên mới có quyền xóa!');
      }

      await _expenseRepository.deleteExpense(id);
      // Fire-and-forget audit log with post-completion fetch
      _auditRepository
          .logAction(
            AuditLog(
              uid: _authRepository.currentUid ?? '',
              action: 'DELETE',
              expenseId: id,
              oldData: oldExpense?.toMap(),
              newData: null,
              timestamp: DateTime.now(),
            ),
          )
          .then((_) => fetchLogs(id));
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Không thể xóa khoản chi. Vui lòng thử lại.';
      Get.snackbar('Lỗi', message, snackPosition: SnackPosition.BOTTOM);
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
    _tagSubscription?.cancel();
    for (final subscription in _expenseSubscriptions.values) {
      subscription.cancel();
    }
    _roomWorker?.dispose();
    _focusedMonthWorker?.dispose();
    _expensesWorker?.dispose();
    _tagsWorker?.dispose();
    _membersWorker?.dispose();
    super.onClose();
  }
}
