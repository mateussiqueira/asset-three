import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Provider responsável por gerenciar a árvore de ativos.
///
/// Este provider implementa a lógica de construção e filtragem da árvore de ativos,
/// com as seguintes características:
///
/// 1. Construção da árvore hierárquica
/// 2. Filtros de busca e status
/// 3. Gerenciamento de estado de expansão
/// 4. Otimização de performance
///
/// A estrutura é otimizada para:
/// - Construção eficiente da árvore
/// - Filtragem sem perda de contexto
/// - Atualização seletiva de nós
/// - Experiência de usuário fluida
class AssetTreeProvider extends ChangeNotifier {
  final String companyId;
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = false;
  String? _error;

  // Filtros
  String _searchQuery = '';
  bool _showEnergySensors = false;
  bool _showCriticalStatus = false;

  // Estado de expansão dos nós
  final Map<String, ValueNotifier<bool>> _expansionNotifiers = {};

  AssetTreeProvider({required this.companyId}) {
    loadData();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get energyFilter => _showEnergySensors;
  bool get criticalFilter => _showCriticalStatus;

  /// Carrega os dados de localizações e ativos da API.
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final locations = await ApiService.fetchLocations(companyId);
      final assets = await ApiService.fetchAssets(companyId);
      _locations = locations;
      _assets = assets;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca os ativos da empresa.
  Future<List<Map<String, dynamic>>> fetchAssets(String companyId) async {
    try {
      return await ApiService.fetchAssets(companyId);
    } catch (e) {
      _error = 'Erro ao carregar ativos: $e';
      notifyListeners();
      return [];
    }
  }

  /// Define a query de busca.
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Define o filtro de sensores de energia.
  void setEnergyFilter(bool value) {
    _showEnergySensors = value;
    notifyListeners();
  }

  /// Define o filtro de status crítico.
  void setCriticalFilter(bool value) {
    _showCriticalStatus = value;
    notifyListeners();
  }

  /// Alterna o estado de expansão de um nó.
  void toggleNodeExpansion(String nodeId) {
    final notifier = _expansionNotifiers[nodeId] ?? ValueNotifier<bool>(false);
    notifier.value = !notifier.value;
    _expansionNotifiers[nodeId] = notifier;
    notifyListeners();
  }

  /// Verifica se um nó está expandido.
  bool isNodeExpanded(String nodeId) {
    return _expansionNotifiers[nodeId]?.value ?? false;
  }

  /// Verifica se um ativo deve ser exibido com base nos filtros.
  bool _shouldShowAsset(Map<String, dynamic> asset) {
    if (_searchQuery.isNotEmpty) {
      final name = asset['name']?.toString().toLowerCase() ?? '';
      if (!name.contains(_searchQuery)) {
        return false;
      }
    }

    if (_showEnergySensors && asset['sensorType'] != 'energy') {
      return false;
    }

    if (_showCriticalStatus && asset['status'] != 'alert') {
      return false;
    }

    return true;
  }

  /// Verifica se um ativo tem filhos que devem ser exibidos.
  bool _hasVisibleChildren(Map<String, dynamic> asset) {
    return _assets.any(
      (child) =>
          child['parentId'] == asset['id'] &&
          _shouldShowAssetWithParents(child),
    );
  }

  /// Verifica se um ativo deve ser exibido (incluindo seus pais).
  bool _shouldShowAssetWithParents(Map<String, dynamic> asset) {
    // Se não há filtros ativos, mostra todos os ativos
    if (_searchQuery.isEmpty && !_showEnergySensors && !_showCriticalStatus) {
      return true;
    }

    // Verifica se o ativo atual corresponde aos filtros
    if (_shouldShowAsset(asset)) {
      return true;
    }

    // Verifica se tem filhos que correspondem aos filtros
    if (_hasVisibleChildren(asset)) {
      return true;
    }

    return false;
  }

  /// Constrói a árvore de ativos.
  Widget buildTree([String? locationId]) {
    // Se uma locationId foi especificada, constrói a árvore a partir dela
    if (locationId != null) {
      final location = _locations.firstWhere(
        (loc) => loc['id'] == locationId,
        orElse: () => {},
      );
      if (location.isNotEmpty) {
        return _buildLocationNode(location, level: 0);
      }
      return const SizedBox.shrink();
    }

    // Busca localizações raiz (sem parentId)
    final rootLocations =
        _locations.where((loc) => loc['parentId'] == null).toList();

    // Busca ativos sem localização nem pai (componentes soltos)
    final unlinkedAssets =
        _assets
            .where(
              (asset) =>
                  asset['locationId'] == null && asset['parentId'] == null,
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Renderiza localizações raiz
        ...rootLocations.map(
          (location) => _buildLocationNode(location, level: 0),
        ),
        // Renderiza ativos sem vínculo
        ...unlinkedAssets.map((asset) => _buildAssetNode(asset, level: 0)),
      ],
    );
  }

  /// Constrói um nó de localização.
  Widget _buildLocationNode(Map<String, dynamic> location, {int level = 0}) {
    // Busca sublocalizações
    final subLocations =
        _locations.where((loc) => loc['parentId'] == location['id']).toList();

    // Busca ativos da localização
    final locationAssets =
        _assets
            .where(
              (asset) =>
                  asset['locationId'] == location['id'] &&
                  asset['parentId'] == null,
            )
            .toList();

    // Filtra ativos visíveis
    final visibleAssets =
        locationAssets.where(_shouldShowAssetWithParents).toList();

    // Se não tem sublocalizações nem ativos visíveis, retorna vazio
    if (subLocations.isEmpty && visibleAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    final isExpanded = isNodeExpanded(location['id']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: level * 16.0),
          child: InkWell(
            onTap: () => toggleNodeExpansion(location['id']),
            child: ListTile(
              title: Text(location['name'] ?? 'Sem nome'),
              subtitle: Text('Localização'),
              leading: const Icon(Icons.location_on),
              trailing:
                  (subLocations.isNotEmpty || visibleAssets.isNotEmpty)
                      ? Icon(isExpanded ? Icons.expand_less : Icons.expand_more)
                      : null,
            ),
          ),
        ),
        if (isExpanded) ...[
          // Renderiza sublocalizações
          ...subLocations.map(
            (subLoc) => _buildLocationNode(subLoc, level: level + 1),
          ),
          // Renderiza ativos da localização
          ...visibleAssets.map(
            (asset) => _buildAssetNode(asset, level: level + 1),
          ),
        ],
      ],
    );
  }

  /// Constrói um nó de ativo.
  Widget _buildAssetNode(Map<String, dynamic> asset, {int level = 0}) {
    final hasChildren = _hasVisibleChildren(asset);
    final isComponent = asset['sensorType'] != null;
    final isExpanded = isNodeExpanded(asset['id']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: level * 16.0),
          child: InkWell(
            onTap: hasChildren ? () => toggleNodeExpansion(asset['id']) : null,
            child: ListTile(
              title: Text(asset['name'] ?? 'Sem nome'),
              subtitle:
                  isComponent
                      ? Text(
                        '${asset['sensorType']} - ${asset['status'] ?? 'N/A'}',
                      )
                      : null,
              leading: Icon(
                isComponent ? Icons.sensors : Icons.inventory_2,
                color: _getStatusColor(asset['status']),
              ),
              trailing:
                  hasChildren
                      ? Icon(isExpanded ? Icons.expand_less : Icons.expand_more)
                      : null,
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          ..._assets
              .where(
                (child) =>
                    child['parentId'] == asset['id'] &&
                    _shouldShowAssetWithParents(child),
              )
              .map((child) => _buildAssetNode(child, level: level + 1)),
      ],
    );
  }

  /// Retorna a cor do status do ativo.
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'alert':
        return Colors.red;
      case 'operating':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    for (final notifier in _expansionNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }
}
