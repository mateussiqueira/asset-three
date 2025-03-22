import 'package:asset_tree/features/asset_tree/domain/entities/asset.dart';
import 'package:asset_tree/features/asset_tree/domain/entities/location.dart';
import 'package:asset_tree/features/asset_tree/presentation/providers/asset_tree_provider.dart';
import 'package:asset_tree/features/asset_tree/presentation/widgets/asset_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

@GenerateMocks([AssetTreeProvider])
import 'asset_tree_test.mocks.dart';

void main() {
  group('AssetTree', () {
    late MockAssetTreeProvider mockProvider;
    late List<Asset> testAssets;
    late List<Location> testLocations;

    setUp(() {
      mockProvider = MockAssetTreeProvider();

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

      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.getRootLocations()).thenReturn(testLocations);
      when(mockProvider.getLocationAssets(any)).thenReturn([]);
      when(mockProvider.getChildAssets(any)).thenReturn([]);
    });

    testWidgets('should show loading indicator when loading',
        (WidgetTester tester) async {
      when(mockProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AssetTreeProvider>.value(
            value: mockProvider,
            child: AssetTree(provider: mockProvider),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when error exists',
        (WidgetTester tester) async {
      when(mockProvider.error).thenReturn('Test error');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AssetTreeProvider>.value(
            value: mockProvider,
            child: AssetTree(provider: mockProvider),
          ),
        ),
      );

      expect(find.text('Test error'), findsOneWidget);
    });

    testWidgets('should show locations when data is loaded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AssetTreeProvider>.value(
            value: mockProvider,
            child: AssetTree(provider: mockProvider),
          ),
        ),
      );

      expect(find.text('Location 1'), findsOneWidget);
      expect(find.text('Location 2'), findsOneWidget);
    });

    testWidgets('should show assets when location is expanded',
        (WidgetTester tester) async {
      when(mockProvider.getLocationAssets('loc1')).thenReturn(
        testAssets.where((asset) => asset.locationId == 'loc1').toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AssetTreeProvider>.value(
            value: mockProvider,
            child: AssetTree(provider: mockProvider),
          ),
        ),
      );

      await tester.tap(find.text('Location 1'));
      await tester.pump();

      expect(find.text('Asset 1'), findsOneWidget);
      expect(find.text('Asset 2'), findsOneWidget);
    });

    testWidgets('should show child assets when asset is expanded',
        (WidgetTester tester) async {
      when(mockProvider.getChildAssets('parent1')).thenReturn(
        testAssets.where((asset) => asset.parentId == 'parent1').toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AssetTreeProvider>.value(
            value: mockProvider,
            child: AssetTree(provider: mockProvider),
          ),
        ),
      );

      await tester.tap(find.text('Asset 1'));
      await tester.pump();

      expect(find.text('Asset 2'), findsOneWidget);
    });

    testWidgets('should handle empty data gracefully',
        (WidgetTester tester) async {
      when(mockProvider.getRootLocations()).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AssetTreeProvider>.value(
            value: mockProvider,
            child: AssetTree(provider: mockProvider),
          ),
        ),
      );

      expect(find.text('No locations found'), findsOneWidget);
    });
  });
}
