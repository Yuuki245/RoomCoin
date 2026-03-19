import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import '../models/member_option.dart';

class ExpenseRepository {
  final FirebaseFirestore _db;

  ExpenseRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  static const String _expensesCollection = 'expenses';
  static const String _usersCollection = 'users';

  Stream<List<Expense>> streamExpensesByRoom(String roomId) {
    return _db
        .collection(_expensesCollection)
        .where('roomId', isEqualTo: roomId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Expense.fromDoc).toList());
  }

  Future<void> addExpense(Expense expense) async {
    await _db.collection(_expensesCollection).add({
      ...expense.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db.collection(_expensesCollection).doc(expenseId).delete();
  }

  Future<List<MemberOption>> getMemberOptions(List<String> memberUids) async {
    if (memberUids.isEmpty) {
      return const <MemberOption>[];
    }

    final results = <MemberOption>[];
    for (final memberUid in memberUids) {
      try {
        final snap = await _db
            .collection(_usersCollection)
            .doc(memberUid)
            .get();
        final data = snap.data();
        final displayName = data == null
            ? 'Nguyễn Văn A'
            : (data['displayName'] as String?) ??
                  (data['name'] as String?) ??
                  'Nguyễn Văn A';
        results.add(MemberOption(uid: memberUid, displayName: displayName));
      } catch (_) {
        results.add(MemberOption(uid: memberUid, displayName: 'Nguyễn Văn A'));
      }
    }

    return results;
  }
}
