// ============================================
// lib/presentation/booking/widgets/step_building_selection.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepBuildingSelection extends StatelessWidget {
  final Building? selectedBuilding;
  final Function(Building) onBuildingSelected;

  const StepBuildingSelection({
    super.key,
    required this.selectedBuilding,
    required this.onBuildingSelected,
  });

  // Моковые данные корпусов
  List<Building> get _mockBuildings => [
        Building(id: '1', name: 'Корпус 1'),
        Building(id: '2', name: 'Корпус 2'),
        Building(id: '3', name: 'Корпус 3'),
      ];

  IconData _getBuildingIcon(String buildingId) {
    switch (buildingId) {
      case '1':
        return CupertinoIcons.building_2_fill;
      case '2':
        return CupertinoIcons.house_alt_fill;
      case '3':
        return CupertinoIcons.layers_alt_fill;
      default:
        return CupertinoIcons.building_2_fill;
    }
  }

  Color _getBuildingColor(String buildingId) {
    switch (buildingId) {
      case '1':
        return CupertinoColors.systemBlue;
      case '2':
        return CupertinoColors.systemGreen;
      case '3':
        return CupertinoColors.systemPurple;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.building_2_fill,
      title: 'Выберите корпус',
      subtitle: 'Всего ${_mockBuildings.length} корпуса',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Первый корпус
            _buildBuildingRow(_mockBuildings[0]),

            // Разделитель
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Divider(height: 1, color: Color(0xFF2C2C2E)),
            ),

            // Второй корпус
            _buildBuildingRow(_mockBuildings[1]),

            // Разделитель
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Divider(height: 1, color: Color(0xFF2C2C2E)),
            ),

            // Третий корпус
            _buildBuildingRow(_mockBuildings[2]),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingRow(Building building) {
    final isSelected = selectedBuilding?.id == building.id;
    final buildingColor = _getBuildingColor(building.id);

    return GestureDetector(
      onTap: () => onBuildingSelected(building),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? buildingColor.withValues(alpha: 0.2) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getBuildingIcon(building.id),
                color: isSelected ? buildingColor : CupertinoColors.systemGrey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    building.name,
                    style: TextStyle(
                      color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 24,
              child: isSelected
                  ? Icon(CupertinoIcons.checkmark_circle_fill, color: buildingColor, size: 24)
                  : const Icon(CupertinoIcons.circle, color: CupertinoColors.systemGrey3, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
