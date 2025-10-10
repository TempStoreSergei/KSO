// ============================================
// lib/presentation/booking/widgets/step_building_selection.dart
// ============================================

import 'package:flutter/cupertino.dart';
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
        Building(id: '1', name: 'Корпус А'),
        Building(id: '2', name: 'Корпус Б'),
        Building(id: '3', name: 'Корпус В'),
        Building(id: '4', name: 'Корпус Г'),
      ];

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      title: 'Выберите корпус',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: _mockBuildings.length,
          itemBuilder: (context, index) {
            final building = _mockBuildings[index];
            final isSelected = selectedBuilding?.id == building.id;

            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onBuildingSelected(building),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : const Color(0xFF3A3A3C),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    building.name,
                    style: TextStyle(
                      color: isSelected
                          ? CupertinoColors.white
                          : CupertinoColors.systemGrey,
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
