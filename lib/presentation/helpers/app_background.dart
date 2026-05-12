// lib/presentation/helpers/app_background.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:motel/data/datasources/desktop_background_remote_data_source.dart';
import 'package:motel/data/repositories/desktop_background_repository_impl.dart';
import 'package:motel/domain/entities/desktop_background_entity.dart';
import 'package:motel/domain/repositories/desktop_background_repository.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/presentation/helpers/animated_background.dart';

class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  DesktopBackgroundEntity? _background;
  final DesktopBackgroundRepository _repository = DesktopBackgroundRepositoryImpl(
    remoteDataSource: DesktopBackgroundRemoteDataSourceImpl(apiClient: ApiClient.instance),
  );

  @override
  void initState() {
    super.initState();
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    final background = await _repository.getDesktopBackground();
    if (mounted) {
      setState(() {
        _background = background;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Фоновое изображение с эффектами
        _buildBackground(),
        // Основное содержимое экрана
        widget.child,
      ],
    );
  }

  Widget _buildBackground() {
    if (_background != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _background!.fullUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const LightHomeKitBackground(),
          ),
          Container(color: Colors.black.withValues(alpha: 0.2)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.transparent),
          ),
        ],
      );
    } else {
      return const LightHomeKitBackground();
    }
  }
}
