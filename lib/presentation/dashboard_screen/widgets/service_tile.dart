  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';
  import 'package:motel/domain/entities/service_entity.dart';
  import 'package:motel/presentation/helpers/adaptive_text.dart';
  import 'package:motel/presentation/helpers/glassmorphic_container.dart';

  class ServiceTile extends StatelessWidget {
    final ServiceEntity service;
    final VoidCallback onTap;

    const ServiceTile({
      super.key,
      required this.service,
      required this.onTap,
    });

    // Карта для динамического сопоставления имени услуги и иконки.
    static final Map<String, IconData> _serviceIcons = {
      'Проживание': CupertinoIcons.house_fill,
      'Платная уборка комнаты': CupertinoIcons.wind,
      'Внеплановая замена белья': CupertinoIcons.refresh_thick,
      'Штраф за нарушение правил проживания': CupertinoIcons.exclamationmark_shield_fill,
      'Стоянка автотранспорта': CupertinoIcons.car_detailed,
      'Стирка': CupertinoIcons.drop_fill,
    };

    // Иконка по умолчанию, если название услуги не найдено в карте.
    static const IconData _defaultIcon = CupertinoIcons.square_grid_2x2_fill;

    @override
    Widget build(BuildContext context) {
      final iconData = _serviceIcons[service.name] ?? _defaultIcon;

      return GestureDetector(
        onTap: onTap,
        child: GlassmorphicContainer(
          // Добавляем внутренние отступы, чтобы контент не прилипал к краям.
          padding: const EdgeInsets.all(14.0),
          child: Column(
            // Выравниваем весь контент по левому краю.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Иконка в левом верхнем углу.
              Icon(
                iconData,
                color: Colors.white,
                size: scaleText(context, 32), // Можно сделать иконку чуть меньше
              ),

              // 2. "Распорка", которая толкает текст вниз.
              // Занимает все доступное пространство между иконкой и текстом.
              const Spacer(),

              // 3. Текст в левом нижнем углу.
              Text(
                service.name,
                // Устанавливаем максимальное количество строк.
                maxLines: 3,
                // Если текст не помещается, он обрезается с многоточием.
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: scaleText(context, 17),
                  // Делаем шрифт жирным для лучшего акцента, как в iOS.
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
