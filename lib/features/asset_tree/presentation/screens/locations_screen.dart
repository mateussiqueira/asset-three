import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/asset_tree_provider.dart';
import '../widgets/asset_tree.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<AssetTreeProvider>(
              builder:
                  (context, provider, child) => Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: provider.setSearchText,
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Energy'),
                            selected: provider.hasEnergyFilter,
                            onSelected: (_) => provider.toggleEnergyFilter(),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Critical'),
                            selected: provider.hasCriticalFilter,
                            onSelected: (_) => provider.toggleCriticalFilter(),
                          ),
                        ],
                      ),
                    ],
                  ),
            ),
          ),
          Expanded(
            child: Consumer<AssetTreeProvider>(
              builder:
                  (context, provider, child) => AssetTree(provider: provider),
            ),
          ),
        ],
      ),
    );
  }
}
