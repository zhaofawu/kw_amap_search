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

  String _platformVersion = 'Unknown';
  String _status = 'Ready';
  bool _loading = false;
  List<SearchResultItem> _results = const <SearchResultItem>[];

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
    await _runSearch(() {
      return KwAmapSearch.searchByKeyword(
        AmapKeywordSearchQuery(
          keyword: _keywordController.text.trim(),
          city: _cityController.text.trim(),
        ),
      );
    });
  }

  Future<void> _searchNearby() async {
    final latitude = double.tryParse(_latitudeController.text.trim()) ?? 0;
    final longitude = double.tryParse(_longitudeController.text.trim()) ?? 0;
    final radius = int.tryParse(_radiusController.text.trim()) ?? 1000;

    await _runSearch(() {
      return KwAmapSearch.searchNearby(
        AmapAroundSearchQuery(
          center: AmapLatLng(latitude: latitude, longitude: longitude),
          radius: radius,
          keyword: _keywordController.text.trim(),
          city: _cityController.text.trim(),
        ),
      );
    });
  }

  Future<void> _runSearch(
    Future<List<SearchResultItem>> Function() search,
  ) async {
    setState(() {
      _loading = true;
      _status = 'Searching...';
    });

    try {
      await _prepareAmapSdk();
      final results = await search();
      if (!mounted) return;
      setState(() {
        _results = results;
        _status = 'Found ${results.length} POI(s)';
      });
    } on AmapSearchException catch (error) {
      _setSearchError('${error.code}: ${error.message ?? error.details ?? ''}');
    } on PlatformException catch (error) {
      _setSearchError('${error.code}: ${error.message ?? ''}');
    } on Object catch (error) {
      _setSearchError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _setSearchError(String message) {
    if (!mounted) return;
    setState(() {
      _results = const <SearchResultItem>[];
      _status = message;
    });
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatusLine(loading: _loading, status: _status),
              const SizedBox(height: 12),
              ..._results.map(_PoiTile.new),
            ],
          ),
        ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.name),
      subtitle: Text(
        [
          item.address,
          if (item.tel.isNotEmpty) item.tel,
          '${item.location.latitude}, ${item.location.longitude}',
        ].where((text) => text.isNotEmpty).join('\n'),
      ),
      trailing: item.distance > 0 ? Text('${item.distance} m') : null,
    );
  }
}
