import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kw_amap_search/kw_amap_search.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _androidKeyController = TextEditingController();
  final _iosKeyController = TextEditingController();
  final _keywordController = TextEditingController(text: '咖啡');
  final _cityController = TextEditingController(text: '上海');
  final _latitudeController = TextEditingController(text: '31.2304');
  final _longitudeController = TextEditingController(text: '121.4737');
  final _radiusController = TextEditingController(text: '1000');
  final _typesController = TextEditingController(
    text:
        '050000|060000|070000|080000|090000|100000|110000|120000|130000|140000|150000|160000|170000|190000',
  );

  String _platformVersion = 'Unknown';
  String _status = 'Ready';
  bool _privacyAgreed = false;
  bool get _loading => _activeRequestIds.isNotEmpty;
  int _requestSeed = 0;
  final _activeRequestIds = <String>{};
  final _requestStatuses = <String, String>{};
  List<SearchResultItem> _results = const <SearchResultItem>[];
  AmapRegeocodeResult? _reverseResult;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlatformVersion());
  }

  @override
  void dispose() {
    _androidKeyController.dispose();
    _iosKeyController.dispose();
    _keywordController.dispose();
    _cityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    _typesController.dispose();
    for (final requestId in _activeRequestIds) {
      KwAmapSearch.cancelRequest(requestId).ignore();
    }
    _activeRequestIds.clear();
    super.dispose();
  }

  Future<void> _loadPlatformVersion() async {
    try {
      final version = await KwAmapSearch.getPlatformVersion();
      if (!mounted) return;
      setState(() {
        _platformVersion = version ?? 'Unknown platform version';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _platformVersion = 'Failed: $error';
      });
    }
  }

  Future<void> _prepareAmapSdk() async {
    if (!_privacyAgreed) {
      throw const AmapSearchException(
        code: 'privacy_not_agreed',
        message: 'Privacy consent is required.',
      );
    }
    // AMap requires the privacy methods to be called before SDK APIs are used.
    // Keeping that sequence in one helper makes both search buttons behave the
    // same on Android and iOS.
    await KwAmapSearch.setApiKey(
      _androidKeyController.text.trim(),
      _iosKeyController.text.trim(),
    );
    await KwAmapSearch.updatePrivacyShow(true, true);
    await KwAmapSearch.updatePrivacyAgree(true);
  }

  Future<void> _searchByKeyword() async {
    final requestId = _nextRequestId('keyword');
    final query = AmapKeywordSearchQuery(
      keyword: _keywordController.text.trim(),
      city: _cityController.text.trim(),
      types: _typesController.text.trim(),
    );
    await _runSearch(requestId, () {
      return KwAmapSearch.searchByKeyword(
        query,
        options: AmapSearchRequestOptions(requestId: requestId),
      );
    });
  }

  Future<void> _searchNearby() async {
    final point = _pointFromInput();
    if (point == null) {
      _setSearchError('Invalid coordinate');
      return;
    }
    final radius = int.tryParse(_radiusController.text.trim()) ?? 1000;
    final requestId = _nextRequestId('nearby');
    final query = AmapAroundSearchQuery(
      center: point,
      radius: radius,
      keyword: _keywordController.text.trim(),
      city: _cityController.text.trim(),
      types: _typesController.text.trim(),
      sortRule: AmapAroundSortRule.distance,
    );

    await _runSearch(requestId, () {
      return KwAmapSearch.searchNearby(
        query,
        options: AmapSearchRequestOptions(requestId: requestId),
      );
    });
  }

  Future<void> _reverseGeocode() async {
    final point = _pointFromInput();
    if (point == null) {
      _setSearchError('Invalid coordinate');
      return;
    }
    final radius = int.tryParse(_radiusController.text.trim()) ?? 300;
    final requestId = _nextRequestId('reverse');
    _activeRequestIds.add(requestId);
    setState(() {
      _requestStatuses[requestId] = 'pending';
      _status = 'Reverse geocoding... $requestId';
      _reverseResult = null;
    });

    try {
      await _prepareAmapSdk();
      if (!mounted || !_activeRequestIds.contains(requestId)) return;
      final reverse = await KwAmapSearch.reverseGeocode(
        AmapReverseGeocodeQuery(point: point, radius: radius),
        options: AmapSearchRequestOptions(requestId: requestId),
      );
      if (!mounted) return;
      setState(() {
        _reverseResult = reverse;
        _requestStatuses[requestId] = 'success';
        _status = 'Reverse OK: ${reverse.pois.length} POI(s)';
      });
    } on AmapSearchException catch (error) {
      _setSearchError(
        '${error.code}: ${error.message ?? error.details ?? ''}',
        requestId: requestId,
      );
    } on Object catch (error) {
      _setSearchError(error.toString(), requestId: requestId);
    } finally {
      _activeRequestIds.remove(requestId);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _runReverseAndNearby() async {
    await Future.wait([_reverseGeocode(), _searchNearby()]);
  }

  Future<void> _cancelActiveRequests() async {
    await Future.wait(_activeRequestIds.toList().map(_cancelRequest));
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      final cancelled = await KwAmapSearch.cancelRequest(requestId);
      if (!mounted) return;
      // An ID can still be waiting for SDK setup, before native registration.
      if (cancelled || _activeRequestIds.contains(requestId)) {
        setState(() {
          _activeRequestIds.remove(requestId);
          _requestStatuses[requestId] = 'cancelled';
        });
      }
    } on Object catch (error) {
      _setSearchError(error.toString(), requestId: requestId);
    }
  }

  Future<void> _runSearch(
    String requestId,
    Future<List<SearchResultItem>> Function() search,
  ) async {
    _activeRequestIds.add(requestId);
    setState(() {
      _requestStatuses[requestId] = 'pending';
      _status = 'Searching... $requestId';
      _results = const <SearchResultItem>[];
    });

    try {
      await _prepareAmapSdk();
      if (!mounted || !_activeRequestIds.contains(requestId)) return;
      final results = await search();
      if (!mounted) return;
      setState(() {
        _results = results;
        _requestStatuses[requestId] = 'success';
        _status = 'Found ${results.length} POI(s)';
      });
    } on AmapSearchException catch (error) {
      _setSearchError(
        '${error.code}: ${error.message ?? error.details ?? ''}',
        requestId: requestId,
      );
    } on PlatformException catch (error) {
      _setSearchError(
        '${error.code}: ${error.message ?? ''}',
        requestId: requestId,
      );
    } on Object catch (error) {
      _setSearchError(error.toString(), requestId: requestId);
    } finally {
      _activeRequestIds.remove(requestId);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _setSearchError(String message, {String? requestId}) {
    if (!mounted) return;
    setState(() {
      if (requestId != null) _requestStatuses[requestId] = message;
      _status = message;
    });
  }

  AmapLatLng? _pointFromInput() {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (latitude == null || longitude == null) return null;
    return AmapLatLng(latitude: latitude, longitude: longitude);
  }

  String _nextRequestId(String operation) {
    if (_activeRequestIds.isEmpty) _requestStatuses.clear();
    _requestSeed += 1;
    return 'example-$_requestSeed-$operation';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('kw_amap_search example')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text('Running on: $_platformVersion'),
              const SizedBox(height: 16),
              _Section(
                title: 'SDK',
                children: <Widget>[
                  TextField(
                    controller: _androidKeyController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Android Key',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _iosKeyController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'iOS Key',
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('同意高德 SDK 隐私政策和个人信息处理'),
                    value: _privacyAgreed,
                    onChanged: _loading
                        ? null
                        : (value) {
                            setState(() => _privacyAgreed = value ?? false);
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Search',
                children: <Widget>[
                  TextField(
                    controller: _keywordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Keyword',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'City',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _latitudeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Latitude',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _longitudeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Longitude',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Radius meters',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _typesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Types',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _loading ? null : _searchByKeyword,
                        icon: const Icon(Icons.search),
                        label: const Text('Keyword'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _searchNearby,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Nearby'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _reverseGeocode,
                        icon: const Icon(Icons.place),
                        label: const Text('Reverse'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _runReverseAndNearby,
                        icon: const Icon(Icons.sync),
                        label: const Text('Both'),
                      ),
                      TextButton.icon(
                        onPressed: _activeRequestIds.isEmpty
                            ? null
                            : _cancelActiveRequests,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel all'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatusLine(loading: _loading, status: _status),
              ..._requestStatuses.entries.map(
                (entry) => ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                  trailing: IconButton(
                    tooltip: 'Cancel ${entry.key}',
                    onPressed: _activeRequestIds.contains(entry.key)
                        ? () => _cancelRequest(entry.key)
                        : null,
                    icon: const Icon(Icons.cancel),
                  ),
                ),
              ),
              if (_reverseResult != null) ...<Widget>[
                const SizedBox(height: 12),
                _ReverseTile(_reverseResult!),
                ..._reverseResult!.pois.map(_PoiTile.new),
              ],
              const SizedBox(height: 12),
              ..._results.map(_PoiTile.new),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReverseTile extends StatelessWidget {
  const _ReverseTile(this.result);

  final AmapRegeocodeResult result;

  @override
  Widget build(BuildContext context) {
    final address = result.addressComponent;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(result.formattedAddress),
      subtitle: Text(
        [
          '${result.requestedLocation.latitude}, ${result.requestedLocation.longitude}',
          if (address != null)
            [
              address.province,
              address.city,
              address.district,
              address.township,
            ].where((text) => text.isNotEmpty).join(' '),
          'POI ${result.pois.length} / AOI ${result.aois.length} / Road ${result.roads.length}',
        ].where((text) => text.isNotEmpty).join('\n'),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.loading, required this.status});

  final bool loading;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (loading) ...<Widget>[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(status)),
      ],
    );
  }
}

class _PoiTile extends StatelessWidget {
  const _PoiTile(this.item);

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    final location = item.location;
    final distance = item.distanceMeters ?? item.sdkDistanceMeters;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.name),
      subtitle: Text(
        [
          item.address,
          'ID: ${item.id} / Type: ${item.typeCode} ${item.typeDescription}',
          if (item.tel.isNotEmpty) item.tel,
          location == null
              ? 'Coordinate: null'
              : '${location.latitude}, ${location.longitude}',
        ].where((text) => text.isNotEmpty).join('\n'),
      ),
      trailing: Text(distance == null ? 'null' : '${distance.round()} m'),
    );
  }
}
