import 'package:flutter/material.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/location.dart';
import '../../domain/usecases/get_asset_tree.dart';

class AssetTreeProvider extends ChangeNotifier {
  final GetAssetTree _getAssetTree;
  bool _isLoading = false;
  String? _error;
  String _searchText = '';
  bool _hasEnergyFilter = false;
  bool _hasCriticalFilter = false;
  final Map<String, bool> _expandedNodes = {};
  final Map<String, List<Asset>> _filteredAssetsCache = {};
  final Map<String, List<Location>> _locationsCache = {};

  AssetTreeProvider(this._getAssetTree) {
    loadData('company_id');
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchText => _searchText;
  bool get hasEnergyFilter => _hasEnergyFilter;
  bool get hasCriticalFilter => _hasCriticalFilter;

  Future<void> loadData(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _getAssetTree.execute(companyId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchText(String text) {
    _searchText = text;
    clearCache();
    notifyListeners();
  }

  void toggleEnergyFilter() {
    _hasEnergyFilter = !_hasEnergyFilter;
    clearCache();
    notifyListeners();
  }

  void toggleCriticalFilter() {
    _hasCriticalFilter = !_hasCriticalFilter;
    clearCache();
    notifyListeners();
  }

  void toggleNodeExpansion(String nodeId) {
    _expandedNodes[nodeId] = !(_expandedNodes[nodeId] ?? false);
    notifyListeners();
  }

  bool isNodeExpanded(String nodeId) {
    return _expandedNodes[nodeId] ?? false;
  }

  List<Asset> getChildAssets(String parentId) {
    final cacheKey = 'child_$parentId';
    if (_filteredAssetsCache.containsKey(cacheKey)) {
      return _filteredAssetsCache[cacheKey]!;
    }

    final assets =
        _getAssetTree
            .getChildAssets(parentId)
            .where(shouldShowAssetWithParents)
            .toList();

    _filteredAssetsCache[cacheKey] = assets;
    return assets;
  }

  List<Location> getSubLocations(String parentId) {
    final cacheKey = 'sub_$parentId';
    if (_locationsCache.containsKey(cacheKey)) {
      return _locationsCache[cacheKey]!;
    }

    final locations = _getAssetTree.getSubLocations(parentId);
    _locationsCache[cacheKey] = locations;
    return locations;
  }

  List<Asset> getLocationAssets(String locationId) {
    final cacheKey = 'loc_$locationId';
    if (_filteredAssetsCache.containsKey(cacheKey)) {
      return _filteredAssetsCache[cacheKey]!;
    }

    final assets =
        _getAssetTree
            .getLocationAssets(locationId)
            .where(shouldShowAssetWithParents)
            .toList();

    _filteredAssetsCache[cacheKey] = assets;
    return assets;
  }

  List<Location> getRootLocations() {
    return _getAssetTree.getRootLocations();
  }

  List<Asset> getUnlinkedAssets() {
    return _getAssetTree.getUnlinkedAssets();
  }

  Location? getLocation(String locationId) {
    return _getAssetTree.getLocation(locationId);
  }

  bool shouldShowAsset(Asset asset) {
    if (_searchText.isNotEmpty) {
      final name = asset.name.toLowerCase();
      if (!name.contains(_searchText)) {
        return false;
      }
    }

    if (_hasEnergyFilter && asset.sensorType != 'energy') {
      return false;
    }

    if (_hasCriticalFilter && asset.status != 'alert') {
      return false;
    }

    return true;
  }

  bool hasVisibleChildren(Asset asset) {
    return getChildAssets(asset.id).isNotEmpty;
  }

  bool shouldShowAssetWithParents(Asset asset) {
    if (_searchText.isEmpty && !_hasEnergyFilter && !_hasCriticalFilter) {
      return true;
    }

    if (shouldShowAsset(asset)) {
      return true;
    }

    return hasVisibleChildren(asset);
  }

  void clearCache() {
    _filteredAssetsCache.clear();
    _locationsCache.clear();
  }
}
