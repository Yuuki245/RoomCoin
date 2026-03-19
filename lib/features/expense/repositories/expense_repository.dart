import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import '../models/member_option.dart';

class ExpenseRepository {
  final FirebaseFirestore _db;

  ExpenseRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  static const String _expensesCollection = 'expenses';
  static const String _usersCollection = 'users';
  static const int monthExpenseLimit = 500;

  Stream<List<Expense>> streamExpensesByRoomMonth(
    String roomId,
    DateTime month,
  ) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    return _db
        .collection(_expensesCollection)
        .where('roomId', isEqualTo: roomId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('date', isLessThan: Timestamp.fromDate(monthEnd))
        .orderBy('date', descending: true)
        .limit(monthExpenseLimit)
        .snapshots()
        .map((snap) => snap.docs.map(Expense.fromDoc).toList(growable: false));
  }

  Future<String> addExpense(Expense expense) async {
    final docRef = _db.collection(_expensesCollection).doc();
    await docRef.set({
      ...expense.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateExpense(Expense expense) async {
    final payload = <String, dynamic>{
      'roomId': expense.roomId,
      'amount': expense.amount,
      'paidBy': expense.paidBy,
      'createdBy': expense.createdBy,
      'splitBetween': expense.splitBetween,
      'tagId': expense.tagId,
      'date': Timestamp.fromDate(expense.date),
      'createdAt': Timestamp.fromDate(expense.createdAt),
    };

    if (expense.note == null || expense.note!.trim().isEmpty) {
      payload['note'] = FieldValue.delete();
    } else {
      payload['note'] = expense.note!.trim();
    }

    await _db.collection(_expensesCollection).doc(expense.id).update(payload);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db.collection(_expensesCollection).doc(expenseId).delete();
  }

  Future<List<MemberOption>> getMemberOptions(List<String> memberUids) async {
    if (memberUids.isEmpty) {
      return const <MemberOption>[];
    }

    return Future.wait(memberUids.map(_getMemberOption));
  }

  Future<MemberOption> _getMemberOption(String memberUid) async {
    try {
      final snap = await _db.collection(_usersCollection).doc(memberUid).get();
      final data = snap.data();
      final displayName = data == null
          ? 'Nguyễn Văn A'
          : (data['displayName'] as String?) ??
                (data['name'] as String?) ??
                'Nguyễn Văn A';
      return MemberOption(uid: memberUid, displayName: displayName);
    } catch (_) {
      return MemberOption(uid: memberUid, displayName: 'Nguyễn Văn A');
    }
  }
}
