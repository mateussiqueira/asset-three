import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/asset_tree_provider.dart';

/// Widget que exibe a árvore de ativos.
///
/// Este widget implementa a visualização da árvore de ativos, com as seguintes características:
///
/// 1. Integração com o AssetTreeProvider
/// 2. Suporte a expansão/colapso de nós
/// 3. Indentação visual da hierarquia
/// 4. Linhas de conexão entre nós
///
/// A estrutura é otimizada para:
/// - Renderização eficiente de grandes árvores
/// - Manutenção do estado de expansão
/// - Navegação intuitiva
/// - Feedback visual claro
class AssetTree extends StatefulWidget {
  final String companyId;
  final String locationId;

  const AssetTree({
    super.key,
    required this.companyId,
    required this.locationId,
  });

  @override
  State<AssetTree> createState() => _AssetTreeState();
}

class _AssetTreeState extends State<AssetTree> {
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInit) {
        final provider = Provider.of<AssetTreeProvider>(context, listen: false);
        provider.fetchAssets(widget.companyId);
        _isInit = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssetTreeProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return provider.buildTree(widget.locationId);
  }
}
