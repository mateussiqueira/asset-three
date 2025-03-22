import 'package:asset_tree/features/asset_tree/domain/entities/asset.dart';
import 'package:asset_tree/features/asset_tree/domain/entities/location.dart';
import 'package:asset_tree/features/asset_tree/domain/usecases/get_asset_tree.dart';
import 'package:asset_tree/features/asset_tree/presentation/providers/asset_tree_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([GetAssetTree])
import 'asset_tree_provider_test.mocks.dart';

void main() {
  group('AssetTreeProvider', () {
    late AssetTreeProvider provider;
    late MockGetAssetTree mockGetAssetTree;
    late List<Asset> testAssets;
    late List<Location> testLocations;

    setUp(() {
      mockGetAssetTree = MockGetAssetTree();
      provider = AssetTreeProvider(mockGetAssetTree);

      testAssets = [
        Asset(
          id: '1',
          name: 'Asset 1',
          parentId: 'parent1',
          locationId: 'loc1',
          sensorType: 'energy',
          status: 'normal',
        ),
        Asset(
          id: '2',
          name: 'Asset 2',
          parentId: 'parent1',
          locationId: 'loc1',
          sensorType: 'temperature',
          status: 'alert',
        ),
        Asset(
          id: '3',
          name: 'Test Asset',
          parentId: 'parent2',
          locationId: 'loc2',
          sensorType: 'energy',
          status: 'normal',
        ),
      ];

      testLocations = [
        Location(id: 'loc1', name: 'Location 1', parentId: ''),
        Location(id: 'loc2', name: 'Location 2', parentId: ''),
      ];

      when(mockGetAssetTree.execute(any)).thenAnswer((_) async => null);
      when(mockGetAssetTree.getUnlinkedAssets()).thenReturn(testAssets);
      when(mockGetAssetTree.getRootLocations()).thenReturn(testLocations);
    });

    test('initial state should be correct', () {
      expect(provider.isLoading, false);
      expect(provider.error, null);
      expect(provider.searchText, '');
      expect(provider.hasEnergyFilter, false);
      expect(provider.hasCriticalFilter, false);
    });

    test('loadData should update state correctly', () async {
      provider.loadData('company_id');

      expect(provider.isLoading, true);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('loadData should handle errors correctly', () async {
      when(mockGetAssetTree.execute(any)).thenThrow(Exception('Test error'));

      provider.loadData('company_id');

      expect(provider.isLoading, true);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoading, false);
      expect(provider.error, isNotNull);
    });

    test('setSearchText should update search text', () async {
      provider.setSearchText('test');

      expect(provider.searchText, 'test');
      await Future.delayed(const Duration(milliseconds: 400));
      expect(provider.isLoading, true);
    });

    test('toggleEnergyFilter should update filter state', () async {
      provider.toggleEnergyFilter();

      expect(provider.hasEnergyFilter, true);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoading, true);
    });

    test('toggleCriticalFilter should update filter state', () async {
      provider.toggleCriticalFilter();

      expect(provider.hasCriticalFilter, true);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoading, true);
    });

    test('toggleNodeExpansion should update node state', () {
      provider.toggleNodeExpansion('node1');

      expect(provider.isNodeExpanded('node1'), true);
    });

    test('getChildAssets should return correct assets', () {
      provider.loadData('company_id');

      final assets = provider.getChildAssets('parent1');
      expect(assets.length, 2);
      expect(assets.every((asset) => asset.parentId == 'parent1'), true);
    });

    test('getSubLocations should return correct locations', () {
      provider.loadData('company_id');

      final locations = provider.getSubLocations('');
      expect(locations.length, 2);
      expect(locations.every((loc) => loc.parentId == ''), true);
    });

    test('getLocationAssets should return correct assets', () {
      provider.loadData('company_id');

      final assets = provider.getLocationAssets('loc1');
      expect(assets.length, 2);
      expect(assets.every((asset) => asset.locationId == 'loc1'), true);
    });

    test('shouldShowAsset should filter correctly', () {
      provider.loadData('company_id');

      final asset = testAssets.first;
      expect(provider.shouldShowAsset(asset), true);

      provider.setSearchText('nonexistent');
      expect(provider.shouldShowAsset(asset), false);

      provider.setSearchText('');
      provider.toggleEnergyFilter();
      expect(provider.shouldShowAsset(asset), true);

      provider.toggleEnergyFilter();
      provider.toggleCriticalFilter();
      expect(provider.shouldShowAsset(asset), false);
    });

    test('hasVisibleChildren should check correctly', () {
      provider.loadData('company_id');

      final asset = testAssets.first;
      expect(provider.hasVisibleChildren(asset), true);

      provider.setSearchText('nonexistent');
      expect(provider.hasVisibleChildren(asset), false);
    });

    test('shouldShowAssetWithParents should check correctly', () {
      provider.loadData('company_id');

      final asset = testAssets.first;
      expect(provider.shouldShowAssetWithParents(asset), true);

      provider.setSearchText('nonexistent');
      expect(provider.shouldShowAssetWithParents(asset), false);
    });

    test('dispose should clean up resources', () {
      provider.dispose();
      // Add any specific cleanup checks if needed
    });
  });
}
