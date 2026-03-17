import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class ExpenseRepository {
  final FirebaseFirestore _db;

  ExpenseRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const String _expensesCollection = 'expenses';

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
      // đảm bảo createdAt đồng bộ server
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

