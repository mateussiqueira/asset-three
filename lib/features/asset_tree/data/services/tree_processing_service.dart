import 'dart:async';
import 'dart:isolate';

import '../../domain/entities/asset.dart';
import '../../domain/entities/location.dart';

class TreeProcessingService {
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
    List<Asset> allAssets,
    List<Location> allLocations,
    String searchText,
    bool hasEnergyFilter,
    bool hasCriticalFilter,
  ) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _processTreeIsolate,
      _ProcessTreeMessage(
        allAssets: allAssets,
        allLocations: allLocations,
        searchText: searchText,
        hasEnergyFilter: hasEnergyFilter,
        hasCriticalFilter: hasCriticalFilter,
        sendPort: receivePort.sendPort,
      ),
    );

    final result = await receivePort.first as Map<String, List<Asset>>;
    receivePort.close();
    isolate.kill();
    return result;
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

class _ProcessTreeMessage {
  final List<Asset> allAssets;
  final List<Location> allLocations;
  final String searchText;
  final bool hasEnergyFilter;
  final bool hasCriticalFilter;
  final SendPort sendPort;

  _ProcessTreeMessage({
    required this.allAssets,
    required this.allLocations,
    required this.searchText,
    required this.hasEnergyFilter,
    required this.hasCriticalFilter,
    required this.sendPort,
  });
}

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

void _processTreeIsolate(_ProcessTreeMessage message) {
  final Map<String, List<Asset>> result = {};

  for (final location in message.allLocations) {
    final locationAssets =
        message.allAssets
            .where((asset) => asset.locationId == location.id)
            .where((asset) {
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
            })
            .toList();

    result[location.id] = locationAssets;
  }

  message.sendPort.send(result);
}
