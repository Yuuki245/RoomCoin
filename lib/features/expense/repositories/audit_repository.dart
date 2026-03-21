import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/audit_log.dart';

class AuditRepository {
  final FirebaseFirestore _db;

  AuditRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  static const String _logsCollection = 'logs';

  /// Ghi audit log theo kiểu fire-and-forget.
  /// Không throw lỗi, không block caller.
  Future<void> logAction(AuditLog log) {
    return _db.collection(_logsCollection).doc().set(log.toMap()).catchError((
      error,
    ) {
      if (kDebugMode) {
        debugPrint('[AuditRepository] Ghi log thất bại: $error');
      }
    });
  }

  /// Lấy danh sách log theo expenseId, sắp xếp mới nhất lên đầu.
  Future<List<AuditLog>> getLogsByExpenseId(
    String expenseId, {
    int limit = 10,
  }) async {
    final snap = await _db
        .collection(_logsCollection)
        .where('expenseId', isEqualTo: expenseId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(AuditLog.fromDoc).toList(growable: false);
  }
}
