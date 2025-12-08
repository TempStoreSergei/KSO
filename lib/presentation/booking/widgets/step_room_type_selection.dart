
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/cubit/booking_cubit.dart';
import 'package:motel/presentation/booking/cubit/booking_state.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepRoomTypeSelection extends StatelessWidget {
  const StepRoomTypeSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingCubit>();
    final selectedRoomType = context.watch<BookingCubit>().state.bookingData.selectedRoomType;

    final roomTypes = [RoomType.fourBed, RoomType.sixBed, RoomType.eightBed];

    return StepContainer(
      icon: CupertinoIcons.tag_fill,
      title: 'Выберите тип комнаты',
      subtitle: 'Доступно ${roomTypes.length} типа комнат',
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.separated(
          itemCount: roomTypes.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: CupertinoListTileSeparator(),
          ),
          itemBuilder: (context, index) {
            final roomType = roomTypes[index];
            return _buildRoomTypeRow(
              cubit,
              roomType,
              isSelected: selectedRoomType == roomType,
            );
          },
        ),
      ),
    );
  }

  IconData _getRoomTypeIcon(RoomType type) {
    switch (type) {
      case RoomType.fourBed:
        return CupertinoIcons.person_2_fill;
      case RoomType.sixBed:
        return CupertinoIcons.person_3_fill;
      case RoomType.eightBed:
        return CupertinoIcons.group;
      default:
        return CupertinoIcons.square;
    }
  }

  String _getRoomTypeName(RoomType type) {
    switch (type) {
      case RoomType.fourBed:
        return '4-х местная';
      case RoomType.sixBed:
        return '6-ти местная';
      case RoomType.eightBed:
        return '8-ми местная';
      default:
        return '';
    }
  }

  Widget _buildRoomTypeRow(BookingCubit cubit, RoomType roomType, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => cubit.setRoomType(roomType),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? CupertinoColors.activeBlue.withOpacity(0.2) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getRoomTypeIcon(roomType),
                color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _getRoomTypeName(roomType),
                style: TextStyle(
                  color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 24,
              child: isSelected
                  ? const Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.activeBlue, size: 24)
                  : const Icon(CupertinoIcons.circle, color: CupertinoColors.systemGrey3, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for the separator to avoid material import
class CupertinoListTileSeparator extends StatelessWidget {
  const CupertinoListTileSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: const Color(0xFF2C2C2E),
    );
  }
}
