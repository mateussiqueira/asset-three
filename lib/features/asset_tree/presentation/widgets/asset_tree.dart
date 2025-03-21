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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...provider.getRootLocations().map(
            (location) => LocationTreeNode(
              location: location,
              level: 0,
              provider: provider,
            ),
          ),
          ...provider.getUnlinkedAssets().map(
            (asset) =>
                AssetTreeNode(asset: asset, level: 0, provider: provider),
          ),
        ],
      ),
    );
  }
}
