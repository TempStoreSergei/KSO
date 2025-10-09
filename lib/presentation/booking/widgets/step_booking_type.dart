// lib/presentation/booking/widgets/step_booking_type.dart
import 'package:flutter/cupertino.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepBookingType extends StatelessWidget {
  final BookingType selectedType;
  final Function(BookingType) onTypeSelected;

  const StepBookingType({super.key, required this.selectedType, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.house_fill,
      title: 'Тип бронирования',
      subtitle: 'Что вы хотите забронировать?',
      child: Column(
        children: [
          _buildCard(
            context,
            title: 'Проживание',
            subtitle: 'Забронировать номер с датами',
            icon: CupertinoIcons.bed_double_fill,
            isSelected: selectedType == BookingType.accommodation,
            onTap: () => onTypeSelected(BookingType.accommodation),
          ),
          const SizedBox(height: 12),
          _buildCard(
            context,
            title: 'Только услуга',
            subtitle: 'Заказ спа, ужина и т.д.',
            icon: CupertinoIcons.star_fill,
            isSelected: selectedType == BookingType.serviceOnly,
            onTap: () => onTypeSelected(BookingType.serviceOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: CupertinoColors.activeBlue, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? CupertinoColors.activeBlue : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.activeBlue),
          ],
        ),
      ),
    );
  }
}