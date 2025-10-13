// ============================================
// lib/presentation/settings/services/services_settings_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
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
  List<ServiceEntity>? _services;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
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
              '${service.price} ₽ | Налог: ${service.tax}%',
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () => _navigateAndReload(ServiceEditScreen(service: service)),
          );
        }).toList(),
      ),
    );
  }
}
