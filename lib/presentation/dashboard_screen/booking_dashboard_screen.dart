import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/api/api_client.dart';
import '../../data/datasources/desktop_background_remote_data_source.dart';
import '../../data/datasources/service_remote_data_source.dart';
import '../../data/repositories/desktop_background_repository_impl.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../domain/entities/desktop_background_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/desktop_background_repository.dart';
import '../../domain/usecases/get_services_usecase.dart';
import '../../models/booking_data.dart';
import '../../presentation/payment_screen.dart';
import 'cubit/services_cubit.dart';
import 'widgets/language_switcher_widget.dart';
import 'widgets/service_tile.dart';
import 'widgets/user_profile_header.dart';
import '../helpers/animated_background.dart';
import '../helpers/glassmorphic_container.dart';

class BookingDashboardScreen extends StatelessWidget {
  final BookingData bookingData;
  const BookingDashboardScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final repo = ServiceRepositoryImpl(
          remoteDataSource: ServiceRemoteDataSourceImpl(apiClient: ApiClient.instance),
        );
        return ServicesCubit(getServicesUseCase: GetServicesUseCase(repo))..fetchServices();
      },
      child: BookingDashboardView(bookingData: bookingData),
    );
  }
}

class BookingDashboardView extends StatefulWidget {
  final BookingData bookingData;
  const BookingDashboardView({super.key, required this.bookingData});

  @override
  State<BookingDashboardView> createState() => _BookingDashboardViewState();
}

class _BookingDashboardViewState extends State<BookingDashboardView> {
  final DesktopBackgroundRepository _repo = DesktopBackgroundRepositoryImpl(
    remoteDataSource: DesktopBackgroundRemoteDataSourceImpl(apiClient: ApiClient.instance),
  );
  DesktopBackgroundEntity? _bg;
  int _page = 0;
  static const _per = 5;

  @override
  void initState() {
    super.initState();
    _repo.getDesktopBackground().then((b) => setState(() => _bg = b));
  }

  void _select(ServiceEntity s) {
    widget.bookingData.selectedService = s.name;
    Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => PaymentScreen(bookingData: widget.bookingData),
    ));
  }

  /// Создает динамический паттерн на основе количества виджетов и наличия стрелок
  List<QuiltedGridTile> _createDynamicPattern(int widgetsCount, bool hasLeftArrow, bool hasRightArrow) {
    final pattern = <QuiltedGridTile>[];
    int index = 0;

    // Добавляем левую стрелку (если есть) - всегда 1x1
    if (hasLeftArrow) {
      pattern.add(const QuiltedGridTile(1, 1));
      index++;
    }

    // Количество плиток для услуг
    final tilesCount = widgetsCount - (hasLeftArrow ? 1 : 0) - (hasRightArrow ? 1 : 0);

    // Создаем плитки для услуг с разнообразными размерами
    for (int i = 0; i < tilesCount; i++) {
      switch (i % 6) {
        case 0:
          pattern.add(const QuiltedGridTile(1, 2)); // Широкая плитка
          break;
        case 1:
          pattern.add(const QuiltedGridTile(1, 1)); // Высокая плитка
          break;
        case 2:
          pattern.add(const QuiltedGridTile(2, 1)); // Обычная плитка
          break;
        case 3:
          pattern.add(const QuiltedGridTile(1, 3)); // Высокая плитка
          break;
        case 4:
          pattern.add(const QuiltedGridTile(1, 2)); // Широкая плитка
          break;
        case 5:
          pattern.add(const QuiltedGridTile(1, 1)); // Обычная плитка
          break;
      }
      index++;
    }

    // Добавляем правую стрелку (если есть) - всегда 1x1
    if (hasRightArrow) {
      pattern.add(const QuiltedGridTile(1, 1));
    }

    return pattern;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _bg == null
              ? const LightHomeKitBackground()
              : Stack(
            fit: StackFit.expand,
            children: [
              Image.network(_bg!.fullUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const LightHomeKitBackground()),
              Container(color: Colors.black26),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.transparent),
              ),
            ],
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1020),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GlassmorphicContainer(
                            child: CupertinoButton(
                              padding: const EdgeInsets.all(10),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Icon(CupertinoIcons.back,
                                  color: Colors.white, size: 35),
                            ),
                          ),
                          UserProfileHeader(bookingData: widget.bookingData),
                        ],
                      ),
                      const SizedBox(height: 25),
                      BlocBuilder<ServicesCubit, ServicesState>(
                        builder: (_, state) {
                          if (state is ServicesLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 100),
                                child: CupertinoActivityIndicator(
                                    radius: 20, color: Colors.white),
                              ),
                            );
                          }
                          if (state is ServicesError) {
                            return Center(
                                child: Text(state.message,
                                    style: const TextStyle(
                                        color: Colors.redAccent, fontSize: 18)));
                          }
                          if (state is ServicesLoaded) {
                            final list = state.services;
                            final start = _page * _per;
                            final end = (start + _per).clamp(0, list.length);
                            final slice = list.sublist(start, end);

                            // 1. Создаём плитки услуг
                            final tiles = slice
                                .asMap()
                                .entries
                                .map((e) => ServiceTile(
                              service: e.value,
                              onTap: () => _select(e.value),
                            ))
                                .toList();

                            // 2. Определяем наличие стрелок
                            final hasLeftArrow = _page > 0;
                            final hasRightArrow = end < list.length;

                            // 3. Формируем общий список виджетов
                            final widgets = <Widget>[];
                            if (hasLeftArrow) {
                              widgets.add(_Arrow(
                                icon: CupertinoIcons.chevron_left,
                                onTap: () => setState(() => _page--),
                              ));
                            }
                            widgets.addAll(tiles);
                            if (hasRightArrow) {
                              widgets.add(_Arrow(
                                icon: CupertinoIcons.chevron_right,
                                onTap: () => setState(() => _page++),
                              ));
                            }

                            // 4. Создаем динамический паттерн
                            final pattern = _createDynamicPattern(
                                widgets.length,
                                hasLeftArrow,
                                hasRightArrow
                            );

                            return GridView.custom(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverQuiltedGridDelegate(
                                crossAxisCount: 4,
                                mainAxisSpacing: 25,
                                crossAxisSpacing: 25,
                                pattern: pattern,
                              ),
                              childrenDelegate: SliverChildListDelegate(widgets),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 25),
                      const Row(
                        children: [LanguageSwitcherWidget()],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Arrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        child: Center(child: Icon(icon, color: Colors.white, size: 32)),
      ),
    );
  }
}
