import 'package:flutter/material.dart';

import '../providers/asset_tree_provider.dart';
import 'asset_tree_node.dart';
import 'location_tree_node.dart';

class AssetTree extends StatelessWidget {
  final AssetTreeProvider provider;

  const AssetTree({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }

    final rootLocations = provider.getRootLocations();
    final unlinkedAssets = provider.getUnlinkedAssets();

    return ListView.builder(
      itemCount: rootLocations.length + unlinkedAssets.length,
      itemBuilder: (context, index) {
        if (index < rootLocations.length) {
          return LocationTreeNode(
            key: ValueKey('location_${rootLocations[index].id}'),
            location: rootLocations[index],
            level: 0,
            provider: provider,
          );
        } else {
          final assetIndex = index - rootLocations.length;
          return AssetTreeNode(
            key: ValueKey('asset_${unlinkedAssets[assetIndex].id}'),
            asset: unlinkedAssets[assetIndex],
            level: 0,
            provider: provider,
          );
        }
      },
    );
  }
}
