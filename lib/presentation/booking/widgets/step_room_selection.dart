import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/data/models/room_model.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/cubit/booking_cubit.dart';
import 'package:motel/presentation/booking/cubit/booking_state.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepRoomSelection extends StatefulWidget {
  final Building? selectedBuilding;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(bool isBedSelectionView) onViewChange;

  const StepRoomSelection({
    super.key,
    this.selectedBuilding,
    required this.searchController,
    required this.searchFocusNode,
    required this.onViewChange,
  });

  @override
  State<StepRoomSelection> createState() => _StepRoomSelectionState();
}

class _StepRoomSelectionState extends State<StepRoomSelection> {
  String? _selectedRoomNumber;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() {
      setState(() {}); // Rebuild on text change
    });
  }

  void _handleRoomNumberSelected(String roomNumber) {
    setState(() => _selectedRoomNumber = roomNumber);
    widget.onViewChange(true); // Notify parent that we are in bed selection view
    widget.searchFocusNode.unfocus();
  }

  void _handleBackPressed() {
    setState(() => _selectedRoomNumber = null);
    widget.onViewChange(false); // Notify parent that we are back to room number view
    widget.searchFocusNode.requestFocus();
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
        return 'Неизвестный тип';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        if (state.status == BookingStatus.loading) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final allRooms = state.rooms[widget.selectedBuilding?.id] ?? [];
        final roomsOfType = allRooms
            .where((room) => room.type == state.bookingData.selectedRoomType)
            .toList();

        if (_selectedRoomNumber == null) {
          return _buildRoomNumberSelection(context, state, roomsOfType);
        } else {
          final bedsInRoom =
              roomsOfType.where((r) => r.roomNumber == _selectedRoomNumber).toList();
          return _buildBedSelection(context, state, bedsInRoom);
        }
      },
    );
  }

  Widget _buildRoomNumberSelection(
      BuildContext context, BookingState state, List<Room> rooms) {
    final groupedRooms = groupBy(rooms, (Room room) => room.roomNumber);
    final roomNumbers = groupedRooms.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    final filteredRoomNumbers = roomNumbers
        .where((rn) => rn.contains(widget.searchController.text))
        .toList();

    return StepContainer(
        icon: CupertinoIcons.bed_double_fill,
        title: 'Выберите комнату',
        subtitle:
            'Доступно комнат: ${groupedRooms.length} (${_getRoomTypeName(state.bookingData.selectedRoomType!)})',
        child: Column(
          children: [
            SizedBox(
              width: 450,
              child: CupertinoSearchTextField(
                controller: widget.searchController,
                focusNode: widget.searchFocusNode,
                placeholder: 'Поиск по номеру комнаты',
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Container(
                width: 450,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  itemCount: filteredRoomNumbers.length,
                  shrinkWrap: true,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 70.0),
                    child: Container(height: 1, color: const Color(0xFF38383A)),
                  ),
                  itemBuilder: (context, index) {
                    final roomNumber = filteredRoomNumbers[index];
                    final beds = groupedRooms[roomNumber]!;
                    final isSelected =
                        state.bookingData.selectedRoom?.roomNumber == roomNumber;

                    return CupertinoListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.activeBlue.withOpacity(0.2)
                              : const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(CupertinoIcons.bed_double,
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.white,
                            size: 20),
                      ),
                      title: Text('Комната $roomNumber',
                          style: const TextStyle(
                              color: CupertinoColors.white, fontSize: 17)),
                      onTap: () => _handleRoomNumberSelected(roomNumber),
                      backgroundColor: isSelected
                          ? CupertinoColors.activeBlue.withOpacity(0.2)
                          : const Color(0xFF1C1C1E),
                      trailing: const Icon(CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemGrey3),
                    );
                  },
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildBedSelection(
      BuildContext context, BookingState state, List<Room> beds) {
    return StepContainer(
      icon: CupertinoIcons.checkmark_shield_fill,
      title: 'Выберите место',
      subtitle: 'Комната $_selectedRoomNumber',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Container(
              width: 450,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                itemCount: beds.length,
                shrinkWrap: true,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Container(height: 1, color: const Color(0xFF38383A)),
                ),
                itemBuilder: (context, index) {
                  final room = beds[index];
                  final isSelected = state.bookingData.selectedRoom?.id == room.id;

                  return CupertinoListTile(
                    title: Text('Место ${room.bedNumber}',
                        style: const TextStyle(
                            color: CupertinoColors.white, fontSize: 17)),
                    onTap: () async => await context.read<BookingCubit>().setRoom(room),
                    backgroundColor: isSelected
                        ? CupertinoColors.activeBlue.withOpacity(0.2)
                        : const Color(0xFF1C1C1E),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.checkmark_circle_fill,
                            color: CupertinoColors.activeBlue)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Widget? trailing;

  const CupertinoListTile(
      {super.key,
      this.leading,
      required this.title,
      this.subtitle,
      this.onTap,
      this.backgroundColor,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}