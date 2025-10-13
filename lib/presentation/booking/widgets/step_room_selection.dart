// ============================================
// lib/presentation/booking/widgets/step_room_selection.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepRoomSelection extends StatelessWidget {
  final String roomNumber;
  final Building? selectedBuilding;
  final RoomType? selectedRoomType;
  final Function(RoomType) onRoomTypeSelected;
  static const int maxRoomNumberLength = 6;

  const StepRoomSelection({
    super.key,
    required this.roomNumber,
    required this.selectedRoomType,
    required this.onRoomTypeSelected,
    this.selectedBuilding,
  });

  // === МЕТОДЫ ДЛЯ СТИЛИЗАЦИИ ТИПОВ КОМНАТ ===

  String _getRoomTypeLabel(RoomType type) {
    switch (type) {
      case RoomType.fourBed: return '4 места';
      case RoomType.sixBed: return '6 мест';
      case RoomType.eightBed: return '8 мест';
      default: return ''; // 'Все' не используется
    }
  }

  IconData _getRoomTypeIcon(RoomType type) {
    switch (type) {
      case RoomType.fourBed: return CupertinoIcons.person_2_fill;
      case RoomType.sixBed: return CupertinoIcons.person_3_fill;
      case RoomType.eightBed: return CupertinoIcons.group_solid;
      default: return CupertinoIcons.square_grid_2x2;
    }
  }

  Color _getRoomTypeColor(RoomType type) {
    switch (type) {
      case RoomType.fourBed: return CupertinoColors.systemYellow;
      case RoomType.sixBed: return CupertinoColors.systemOrange;
      case RoomType.eightBed: return CupertinoColors.systemGreen;
      default: return CupertinoColors.systemGrey;
    }
  }

  // === ВИДЖЕТ ВЫБОРА ТИПА КОМНАТЫ ===

  Widget _buildRoomTypeFilter() {
    // Убираем опцию "Все", чтобы пользователь был вынужден сделать конкретный выбор
    final availableTypes = RoomType.values.where((t) => t != RoomType.all).toList();

    return Row(
      children: availableTypes.map((type) {
        final isSelected = selectedRoomType == type;
        final typeColor = _getRoomTypeColor(type);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type != availableTypes.last ? 8 : 0,
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              minSize: 0,
              color: isSelected ? typeColor : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(10),
              onPressed: () => onRoomTypeSelected(type),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRoomTypeIcon(type),
                    color: isSelected ? CupertinoColors.white : typeColor,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _getRoomTypeLabel(type),
                      style: TextStyle(
                        color: isSelected ? CupertinoColors.white : typeColor,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // === ВИДЖЕТ ВВОДА НОМЕРА (появляется после выбора типа) ===

  Widget _buildRoomNumberDisplay() {
    final bool isEmpty = roomNumber.isEmpty;
    return Container(
      height: 65,
      width: 360,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.activeBlue, width: 2),
      ),
      child: Text(
        isEmpty ? 'Введите номер' : roomNumber,
        style: TextStyle(
          color: isEmpty ? CupertinoColors.systemGrey : Colors.white,
          fontSize: isEmpty ? 24 : 34,
          fontWeight: FontWeight.bold,
          letterSpacing: isEmpty ? 1.0 : 8.0,
        ),
      ),
    );
  }

  // === ЯВНАЯ ПОДСКАЗКА ДЛЯ ТЕХ, КТО НЕ ВЫБРАЛ ТИП ===

  Widget _buildInitialPrompt() {
    return Container(
      height: 120, // Задаем высоту, чтобы верстка не "прыгала"
      alignment: Alignment.center,
      child: const Text(
        '↑\nСначала выберите тип комнаты',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Определяем, был ли сделан конкретный выбор
    final bool isTypeSelected = selectedRoomType != null && selectedRoomType != RoomType.all;

    return StepContainer(
      icon: CupertinoIcons.bed_double_fill,
      title: 'Выберите тип и введите номер комнаты',
      subtitle: selectedBuilding?.name ?? '',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Фильтр типов комнат показывается всегда
          _buildRoomTypeFilter(),
          const SizedBox(height: 24),

          // 2. В зависимости от выбора, показываем либо поле ввода, либо подсказку
          if (isTypeSelected) ...[
            _buildRoomNumberDisplay(),
            const SizedBox(height: 20),
            if (roomNumber.isEmpty)
              const Text(
                'Используйте клавиатуру для ввода номера',
                style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15),
              )
          ] else ...[
            // Если тип не выбран - показываем большую явную подсказку
            _buildInitialPrompt(),
          ]
        ],
      ),
    );
  }
}