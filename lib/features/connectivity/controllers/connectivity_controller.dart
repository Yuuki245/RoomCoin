import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController
    with WidgetsBindingObserver {
  static const Duration _refreshInterval = Duration(seconds: 12);
  static const Duration _lookupTimeout = Duration(seconds: 3);

  final RxBool isOffline = false.obs;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _checkConnectivity();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkConnectivity();
    }
  }

  Future<void> refreshStatus() async {
    await _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(_lookupTimeout);
      isOffline.value = result.isEmpty || result.first.rawAddress.isEmpty;
    } catch (_) {
      isOffline.value = true;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.onClose();
  }
}
