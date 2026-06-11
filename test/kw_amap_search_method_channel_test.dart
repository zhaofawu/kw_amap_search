import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kw_amap_search/kw_amap_search_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelKwAmapSearch platform = MethodChannelKwAmapSearch();
  const MethodChannel channel = MethodChannel('kw_amap_search');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
