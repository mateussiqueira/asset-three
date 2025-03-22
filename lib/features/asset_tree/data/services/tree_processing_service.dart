import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import '../../domain/entities/asset.dart';
import '../../domain/entities/location.dart';

void _filterAssetsIsolate(_FilterAssetsMessage message) {
  final filteredAssets =
      message.assets.where((asset) {
        if (message.searchText.isNotEmpty) {
          final name = asset.name.toLowerCase();
          if (!name.contains(message.searchText)) {
            return false;
          }
        }

        if (message.hasEnergyFilter && asset.sensorType != 'energy') {
          return false;
        }

        if (message.hasCriticalFilter && asset.status != 'alert') {
          return false;
        }

        return true;
      }).toList();

  message.sendPort.send(filteredAssets);
}

void _processBatchIsolate(_ProcessBatchMessage message) {
  final result = <String, List<Asset>>{};
  final searchLower = message.searchText.toLowerCase();

  for (final asset in message.batch) {
    if (!_shouldIncludeAsset(
      asset,
      searchLower,
      message.hasEnergyFilter,
      message.hasCriticalFilter,
    )) {
      continue;
    }

    final parentKey = 'child_${asset.parentId}';
    final locationKey = 'loc_${asset.locationId}';

    result[parentKey] = [...(result[parentKey] ?? []), asset];
    result[locationKey] = [...(result[locationKey] ?? []), asset];
  }

  message.sendPort.send(result);
}

bool _shouldIncludeAsset(
  Asset asset,
  String searchText,
  bool hasEnergyFilter,
  bool hasCriticalFilter,
) {
  if (searchText.isNotEmpty) {
    final name = asset.name.toLowerCase();
    if (!name.contains(searchText)) {
      return false;
    }
  }

  if (hasEnergyFilter && asset.sensorType != 'energy') {
    return false;
  }

  if (hasCriticalFilter && asset.status != 'alert') {
    return false;
  }

  return true;
}

class TreeProcessingService {
  static const int _batchSize = 100;
  static const int _maxIsolates = 4;
  static final Map<String, Map<String, List<Asset>>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static final _isolatePool = Queue<Isolate>();
  static final _processingQueue = Queue<Future<void>>();
  static final bool _isProcessing = false;

  static Future<List<Asset>> filterAssetsInBackground(
    List<Asset> assets,
    String searchText,
    bool hasEnergyFilter,
    bool hasCriticalFilter,
  ) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _filterAssetsIsolate,
      _FilterAssetsMessage(
        assets: assets,
        searchText: searchText,
        hasEnergyFilter: hasEnergyFilter,
        hasCriticalFilter: hasCriticalFilter,
        sendPort: receivePort.sendPort,
      ),
    );

    final result = await receivePort.first as List<Asset>;
    receivePort.close();
    isolate.kill();
    return result;
  }

  static Future<Map<String, List<Asset>>> processAssetTreeInBackground(
    List<Asset> assets,
    List<Location> locations,
    String searchText,
    bool hasEnergyFilter,
    bool hasCriticalFilter,
  ) async {
    final cacheKey = _generateCacheKey(
      assets,
      locations,
      searchText,
      hasEnergyFilter,
      hasCriticalFilter,
    );

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final result = await _processWithIsolates(
      assets,
      locations,
      searchText,
      hasEnergyFilter,
      hasCriticalFilter,
    );

    _updateCache(cacheKey, result);
    return result;
  }

  static void _cleanupOldCache() {
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp) > _cacheDuration) {
        _cache.remove(key);
        return true;
      }
      return false;
    });
  }

  static String _generateCacheKey(
    List<Asset> assets,
    List<Location> locations,
    String searchText,
    bool hasEnergyFilter,
    bool hasCriticalFilter,
  ) {
    return '${assets.length}_${locations.length}_$searchText'
        '_${hasEnergyFilter}_$hasCriticalFilter';
  }

  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  static Map<String, List<Asset>> _mergeResults(
    List<Map<String, List<Asset>>> results,
  ) {
    final merged = <String, List<Asset>>{};
    for (final result in results) {
      result.forEach((key, value) {
        merged[key] = [...(merged[key] ?? []), ...value];
      });
    }
    return merged;
  }

  static Future<Map<String, List<Asset>>> _processWithIsolates(
    List<Asset> assets,
    List<Location> locations,
    String searchText,
    bool hasEnergyFilter,
    bool hasCriticalFilter,
  ) async {
    final batches = _splitIntoBatches(assets);
    final results = <Map<String, List<Asset>>>[];
    final completer = Completer<Map<String, List<Asset>>>();

    for (final batch in batches) {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _processBatchIsolate,
        _ProcessBatchMessage(
          batch: batch,
          locations: locations,
          searchText: searchText,
          hasEnergyFilter: hasEnergyFilter,
          hasCriticalFilter: hasCriticalFilter,
          sendPort: receivePort.sendPort,
        ),
      );

      receivePort.listen((result) {
        results.add(result as Map<String, List<Asset>>);
        receivePort.close();
        isolate.kill();

        if (results.length == batches.length) {
          completer.complete(_mergeResults(results));
        }
      });
    }

    return completer.future;
  }

  static List<List<Asset>> _splitIntoBatches(List<Asset> assets) {
    final batches = <List<Asset>>[];
    for (var i = 0; i < assets.length; i += _batchSize) {
      batches.add(assets.skip(i).take(_batchSize).toList());
    }
    return batches;
  }

  static void _updateCache(String key, Map<String, List<Asset>> data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    _cleanupOldCache();
  }
}

class _FilterAssetsMessage {
  final List<Asset> assets;
  final String searchText;
  final bool hasEnergyFilter;
  final bool hasCriticalFilter;
  final SendPort sendPort;

  _FilterAssetsMessage({
    required this.assets,
    required this.searchText,
    required this.hasEnergyFilter,
    required this.hasCriticalFilter,
    required this.sendPort,
  });
}

class _ProcessBatchMessage {
  final List<Asset> batch;
  final List<Location> locations;
  final String searchText;
  final bool hasEnergyFilter;
  final bool hasCriticalFilter;
  final SendPort sendPort;

  _ProcessBatchMessage({
    required this.batch,
    required this.locations,
    required this.searchText,
    required this.hasEnergyFilter,
    required this.hasCriticalFilter,
    required this.sendPort,
  });
}
