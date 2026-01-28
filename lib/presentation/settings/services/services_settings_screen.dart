// ============================================
// lib/presentation/settings/services/services_settings_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/constants/permissions_mapping.dart';
import 'package:motel/core/services/permissions_service.dart';
import 'package:motel/core/services/token_service.dart';
import 'package:motel/data/datasources/service_remote_data_source.dart';
import 'package:motel/data/repositories/service_repository_impl.dart';
import 'package:motel/domain/entities/service_entity.dart';
import 'package:motel/domain/repositories/service_repository.dart';
import 'package:motel/presentation/settings/services/service_edit_screen.dart';

class ServicesSettingsScreen extends StatefulWidget {
  const ServicesSettingsScreen({super.key});

  @override
  State<ServicesSettingsScreen> createState() => _ServicesSettingsScreenState();
}

class _ServicesSettingsScreenState extends State<ServicesSettingsScreen> {
  final ServiceRepository _repository = ServiceRepositoryImpl(
      remoteDataSource: ServiceRemoteDataSourceImpl(apiClient: ApiClient.instance));
  final PermissionsService _permissionsService = PermissionsService();
  final TokenService _tokenService = TokenService();
  
  List<ServiceEntity>? _services;
  bool _isLoading = false;
  bool _canAddService = false;
  bool _canUpdateService = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final role = await _tokenService.getUserRole();
    final canAdd = _permissionsService.hasPermission(role, PermissionsMapping.servicesAdd);
    final canUpdate = _permissionsService.hasPermission(role, PermissionsMapping.servicesUpdate);
    if (mounted) {
      setState(() {
        _canAddService = canAdd;
        _canUpdateService = canUpdate;
      });
    }
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final services = await _repository.getServices();
    if (mounted) {
      setState(() {
        _services = services;
        _isLoading = false;
      });
    }
  }

  void _navigateAndReload(Widget screen) async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(builder: (_) => screen),
    );
    if (result == true) {
      _loadServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Услуги'),
                previousPageTitle: 'Настройки',
              ),
              CupertinoSliverRefreshControl(onRefresh: _loadServices),

              _buildServiceList(),

              // Кнопка добавления услуги
              if (_canAddService)
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        title: const Text(
                          'Добавить услугу',
                          style: TextStyle(color: CupertinoColors.activeBlue),
                        ),
                        leading: const Icon(
                          CupertinoIcons.add_circled_solid,
                          color: CupertinoColors.activeBlue,
                        ),
                        onTap: () => _navigateAndReload(const ServiceEditScreen()),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isLoading && _services == null)
            const Center(child: CupertinoActivityIndicator(radius: 15)),
        ],
      ),
    );
  }

  Widget _buildServiceList() {
    if (_services == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_services!.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'Нажмите "Добавить услугу", чтобы\nсоздать первую услугу.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: const Text('СУЩЕСТВУЮЩИЕ УСЛУГИ'),
        children: _services!.map((service) {
          return CupertinoListTile(
            title: Text(service.name),
            subtitle: Text(
              '${service.price ~/ 100} ₽ | Налог: ${service.tax}%',
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
            trailing: _canUpdateService ? const CupertinoListTileChevron() : null,
            onTap: _canUpdateService ? () => _navigateAndReload(ServiceEditScreen(service: service)) : null,
          );
        }).toList(),
      ),
    );
  }
}
