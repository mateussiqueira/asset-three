import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/asset_tree_provider.dart';

class SearchControls extends StatelessWidget {
  const SearchControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar ativos...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<AssetTreeProvider>().setSearchText(value);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.electric_bolt),
            onPressed: () {
              context.read<AssetTreeProvider>().toggleEnergyFilter();
            },
            color:
                context.watch<AssetTreeProvider>().hasEnergyFilter
                    ? Colors.blue
                    : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.warning),
            onPressed: () {
              context.read<AssetTreeProvider>().toggleCriticalFilter();
            },
            color:
                context.watch<AssetTreeProvider>().hasCriticalFilter
                    ? Colors.red
                    : Colors.grey,
          ),
        ],
      ),
    );
  }
}
