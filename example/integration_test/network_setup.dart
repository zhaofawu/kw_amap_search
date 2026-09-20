import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

// A fresh iOS installation can require network permission before SDK tests run.
Future<void> waitForNetworkPermission() async {
  if (!const bool.fromEnvironment('AMAP_WAIT_FOR_NETWORK_PERMISSION') ||
      const bool.fromEnvironment('AMAP_TEST_OFFLINE')) {
    return;
  }
  await waitForDeviceNetwork(online: true);
}

Future<void> waitForDeviceNetwork({required bool online}) async {
  debugPrint('AMAP_SETUP: turn network ${online ? "on" : "off"} (up to 180s).');
  final elapsed = Stopwatch()..start();
  while (elapsed.elapsed < const Duration(seconds: 180)) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    var reachable = false;
    try {
      // Connectivity only: no Key, coordinates, or search request is sent.
      await (() async {
        final request = await client.headUrl(
          Uri.https('restapi.amap.com', '/'),
        );
        final response = await request.close();
        await response.drain<void>();
      })().timeout(const Duration(seconds: 5));
      reachable = true;
    } on IOException {
      // This probe does not retry SDK requests or affect their assertions.
    } on TimeoutException {
      // Keep the preflight bounded even if the connection stalls.
    } finally {
      client.close(force: true);
    }
    if (reachable == online) {
      debugPrint(
        'AMAP_SETUP: network ${online ? "online" : "offline"} confirmed.',
      );
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  throw StateError(
    'Network did not become ${online ? "online" : "offline"} within 180s.',
  );
}
