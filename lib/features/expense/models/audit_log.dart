import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String uid;
  final String action; // CREATE | UPDATE | DELETE
  final String expenseId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime timestamp;

  AuditLog({
    required this.uid,
    required this.action,
    required this.expenseId,
    this.oldData,
    this.newData,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'action': action,
      'expenseId': expenseId,
      if (oldData != null) 'oldData': oldData,
      if (newData != null) 'newData': newData,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AuditLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AuditLog(
      uid: data['uid'] as String,
      action: data['action'] as String,
      expenseId: data['expenseId'] as String,
      oldData: data['oldData'] as Map<String, dynamic>?,
      newData: data['newData'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
