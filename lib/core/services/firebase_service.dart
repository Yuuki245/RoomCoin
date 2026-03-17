import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    // #region agent log
    void log(String message, String hypothesisId, [Map<String, dynamic>? data]) {
      try {
        final payload = <String, dynamic>{
          'sessionId': 'dd62c7',
          'runId': 'startup-pre',
          'hypothesisId': hypothesisId,
          'location': 'lib/core/services/firebase_service.dart:initialize',
          'message': message,
          'data': data ?? <String, dynamic>{},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // 1) Local FS (desktop)
        try {
          File('debug-dd62c7.log').writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
        } catch (_) {}

        // 2) POST to host debug ingest (use `adb reverse` on Android)
        try {
          final client = HttpClient();
          client
              .postUrl(
                Uri.parse('http://127.0.0.1:7595/ingest/801d4156-07c9-4bee-b44e-7b31327f93f1'),
              )
              .then((req) {
                req.headers.contentType = ContentType.json;
                req.headers.set('X-Debug-Session-Id', 'dd62c7');
                req.write(jsonEncode(payload));
                return req.close();
              })
              .then((_) {})
              .catchError((_) {})
              .whenComplete(() {
                try {
                  client.close(force: true);
                } catch (_) {}
              });
        } catch (_) {}
      } catch (_) {}
    }
    // #endregion

    log('Firebase.initializeApp start', 'H1', {
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
      'projectId': DefaultFirebaseOptions.currentPlatform.projectId,
    });
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('Firebase.initializeApp success', 'H1');
  }
}
