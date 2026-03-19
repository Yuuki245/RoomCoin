import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String roomId;
  final double amount;
  final String paidBy; // UID người trả
  final String createdBy; // UID người tạo
  final List<String> splitBetween;
  final String tagId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.roomId,
    required this.amount,
    required this.paidBy,
    required this.createdBy,
    required this.splitBetween,
    required this.tagId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'amount': amount,
      'paidBy': paidBy,
      'createdBy': createdBy,
      'splitBetween': splitBetween,
      'tagId': tagId,
      'date': Timestamp.fromDate(date),
      if (note != null) 'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Expense document is empty: ${doc.id}');
    }

    return Expense(
      id: doc.id,
      roomId: data['roomId'] as String,
      amount: (data['amount'] as num).toDouble(),
      paidBy: data['paidBy'] as String,
      createdBy: (data['createdBy'] as String?) ?? (data['paidBy'] as String),
      splitBetween: List<String>.from(
        (data['splitBetween'] as List?) ?? const <String>[],
      ),
      tagId: data['tagId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Expense copyWith({
    String? id,
    String? roomId,
    double? amount,
    String? paidBy,
    String? createdBy,
    List<String>? splitBetween,
    String? tagId,
    DateTime? date,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      createdBy: createdBy ?? this.createdBy,
      splitBetween: splitBetween ?? this.splitBetween,
      tagId: tagId ?? this.tagId,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
