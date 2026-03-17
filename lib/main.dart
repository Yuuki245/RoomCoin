import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/controllers/app_controller.dart';
import 'core/services/firebase_service.dart';
import 'core/widgets/app_gate.dart';
import 'features/home/screens/main_navigation.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/repositories/user_repository.dart';

// #region agent log
void _agentLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, dynamic>? data,
  String runId = 'startup-pre',
}) {
  try {
    final payload = <String, dynamic>{
      'sessionId': 'dd62c7',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data ?? <String, dynamic>{},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // 1) Best-effort write to local FS (works on desktop; may not on mobile)
    try {
      File('debug-dd62c7.log').writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}

    // 2) Best-effort POST to host debug ingest (use `adb reverse` on Android)
    try {
      final client = HttpClient();
      client
          .postUrl(Uri.parse('http://127.0.0.1:7595/ingest/801d4156-07c9-4bee-b44e-7b31327f93f1'))
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

void main() async {
  final startedAt = DateTime.now().millisecondsSinceEpoch;
  _agentLog(
    location: 'lib/main.dart:main',
    message: 'main() entered',
    hypothesisId: 'H0',
    data: {'startedAtMs': startedAt},
  );

  WidgetsFlutterBinding.ensureInitialized();
  _agentLog(
    location: 'lib/main.dart:main',
    message: 'WidgetsFlutterBinding.ensureInitialized done',
    hypothesisId: 'H0',
  );

  try {
    _agentLog(
      location: 'lib/main.dart:main',
      message: 'FirebaseService.initialize start',
      hypothesisId: 'H1',
    );
    await FirebaseService.initialize();
    _agentLog(
      location: 'lib/main.dart:main',
      message: 'FirebaseService.initialize success',
      hypothesisId: 'H1',
    );
  } catch (e) {
    _agentLog(
      location: 'lib/main.dart:main',
      message: 'FirebaseService.initialize failed',
      hypothesisId: 'H1',
      data: {'errorType': e.runtimeType.toString(), 'error': e.toString()},
    );
    rethrow;
  }

  try {
    _agentLog(
      location: 'lib/main.dart:main',
      message: 'initializeDateFormatting start',
      hypothesisId: 'H2',
      data: {'locale': 'vi_VN'},
    );
    await initializeDateFormatting('vi_VN', null);
    _agentLog(
      location: 'lib/main.dart:main',
      message: 'initializeDateFormatting success',
      hypothesisId: 'H2',
    );
  } catch (e) {
    _agentLog(
      location: 'lib/main.dart:main',
      message: 'initializeDateFormatting failed',
      hypothesisId: 'H2',
      data: {'errorType': e.runtimeType.toString(), 'error': e.toString()},
    );
    rethrow;
  }

  _agentLog(
    location: 'lib/main.dart:main',
    message: 'runApp start',
    hypothesisId: 'H3',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _agentLog(
      location: 'lib/main.dart:MyApp.build',
      message: 'MyApp.build entered',
      hypothesisId: 'H3',
    );
    Get.put(AppController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(UserRepository(), permanent: true);
    return GetMaterialApp(
      title: 'RoomCoin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: const Locale('vi', 'VN'),
      fallbackLocale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('vi', 'VN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AppGate()),
        GetPage(name: '/main', page: () => const MainNavigation()),
        GetPage(name: '/home', page: () => const MainNavigation()),
      ],
    );
  }
}

