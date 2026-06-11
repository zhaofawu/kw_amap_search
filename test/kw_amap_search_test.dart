import 'package:flutter_test/flutter_test.dart';
import 'package:kw_amap_search/kw_amap_search.dart';
import 'package:kw_amap_search/kw_amap_search_platform_interface.dart';
import 'package:kw_amap_search/kw_amap_search_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKwAmapSearchPlatform
    with MockPlatformInterfaceMixin
    implements KwAmapSearchPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KwAmapSearchPlatform initialPlatform = KwAmapSearchPlatform.instance;

  test('$MethodChannelKwAmapSearch is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKwAmapSearch>());
  });

  test('getPlatformVersion', () async {
    KwAmapSearch kwAmapSearchPlugin = KwAmapSearch();
    MockKwAmapSearchPlatform fakePlatform = MockKwAmapSearchPlatform();
    KwAmapSearchPlatform.instance = fakePlatform;

    expect(await kwAmapSearchPlugin.getPlatformVersion(), '42');
  });
}
