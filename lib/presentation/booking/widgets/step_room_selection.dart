// ============================================
// lib/presentation/booking/widgets/step_room_selection.dart
// ============================================

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/usecases/get_rooms.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepRoomSelection extends StatefulWidget {
  final Function(Room) onRoomSelected;
  final Room? selectedRoom;
  final Building? selectedBuilding;

  const StepRoomSelection({
    super.key,
    required this.onRoomSelected,
    this.selectedRoom,
    this.selectedBuilding,
  });

  @override
  State<StepRoomSelection> createState() => _StepRoomSelectionState();
}

class _StepRoomSelectionState extends State<StepRoomSelection> {
  int _currentPage = 0;
  late int _totalPages;
  final int _gridSlots = 12;
  RoomType _selectedRoomType = RoomType.all;

  // Состояние для хранения загруженных комнат
  late Future<List<Room>> _roomsFuture;
  List<Room> _allRooms = [];
  List<Room> _filteredRooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  // === ЧИСТАЯ АРХИТЕКТУРА: Используем UseCase для загрузки данных ===
  void _loadRooms() {
    final getRoomsUseCase = GetRooms(ApiClient.instance);
    _roomsFuture = getRoomsUseCase.call();
  }

  void _applyFilters() {
    _filteredRooms = _allRooms.where((room) {
      // Фильтр по корпусу
      if (widget.selectedBuilding != null && room.buildingId != widget.selectedBuilding!.id) {
        return false;
      }
      // Фильтр по типу комнаты
      if (_selectedRoomType != RoomType.all && room.type != _selectedRoomType) {
        return false;
      }
      return true;
    }).toList();

    _currentPage = 0; // Сбрасываем на первую страницу при фильтрации
  }

  void _calculatePages() {
    if (_filteredRooms.isEmpty) {
      _totalPages = 1;
      return;
    }

    // Для одной страницы - все слоты доступны
    if (_filteredRooms.length <= _gridSlots) {
      _totalPages = 1;
      return;
    }

    // Первая страница: _gridSlots - 1 (минус кнопка вперед)
    // Средние страницы: _gridSlots - 2 (минус обе кнопки)
    // Последняя страница: _gridSlots - 1 (минус кнопка назад)

    int remainingRooms = _filteredRooms.length;
    int pages = 0;

    // Первая страница
    int firstPageSlots = _gridSlots - 1;
    if (remainingRooms <= firstPageSlots) {
      _totalPages = 1;
      return;
    }
    remainingRooms -= firstPageSlots;
    pages = 1;

    // Средние страницы
    int middlePageSlots = _gridSlots - 2;
    while (remainingRooms > (_gridSlots - 1)) {
      remainingRooms -= middlePageSlots;
      pages++;
    }

    // Последняя страница
    if (remainingRooms > 0) {
      pages++;
    }

    _totalPages = pages;
  }

  // Получаем индекс первой комнаты для указанной страницы
  int _getStartIndexForPage(int pageIndex) {
    if (pageIndex == 0) return 0;

    int startIndex = _gridSlots - 1; // Первая страница

    // Добавляем средние страницы
    for (int i = 1; i < pageIndex; i++) {
      startIndex += _gridSlots - 2;
    }

    return startIndex;
  }

  String _getRoomTypeLabel(RoomType type) {
    switch (type) {
      case RoomType.all:
        return 'Все';
      case RoomType.standard:
        return 'Стандарт';
      case RoomType.comfort:
        return 'Комфорт';
      case RoomType.lux:
        return 'Люкс';
      case RoomType.suite:
        return 'Сюит';
    }
  }

  Widget _buildRoomTypeFilter() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: RoomType.values.map((type) {
          final isSelected = _selectedRoomType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minSize: 0,
              color: isSelected ? CupertinoColors.activeBlue : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                setState(() {
                  _selectedRoomType = type;
                  _applyFilters();
                  _calculatePages();
                });
              },
              child: Text(
                _getRoomTypeLabel(type),
                style: TextStyle(
                  color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: CupertinoColors.white, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Room>>(
      future: _roomsFuture,
      builder: (context, snapshot) {
        // Определяем subtitle в зависимости от состояния загрузки
        String subtitle;
        if (snapshot.connectionState == ConnectionState.waiting) {
          subtitle = 'Загрузка...';
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          subtitle = '';
        } else {
          _allRooms = snapshot.data!;
          _applyFilters();
          _calculatePages();
          subtitle = 'Страница ${_currentPage + 1} из $_totalPages';
        }

        return StepContainer(
          icon: CupertinoIcons.bed_double_fill,
          title: 'Выберите комнату',
          subtitle: widget.selectedBuilding != null
              ? '${widget.selectedBuilding!.name} • $subtitle'
              : subtitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoomTypeFilter(),
              SizedBox(
                height: 300,
                child: _buildContent(snapshot),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(AsyncSnapshot<List<Room>> snapshot) {
    // 1. Пока идет загрузка
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CupertinoActivityIndicator(radius: 15));
    }

    // 2. Если произошла ошибка
    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Ошибка загрузки комнат',
          style: TextStyle(color: CupertinoColors.systemRed),
        ),
      );
    }

    // 3. Если данные пришли, но список пуст
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(
        child: Text(
          'Комнаты отсутствуют',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    // 3.5. Если после фильтрации список пуст
    if (_filteredRooms.isEmpty) {
      return const Center(
        child: Text(
          'Нет комнат по выбранным фильтрам',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    // 4. Успешная загрузка - строим сетку
    final bool hasPrevPage = _currentPage > 0;
    final bool hasNextPage = _currentPage < _totalPages - 1;

    // Получаем индекс начала для текущей страницы
    final int roomStartIndex = _getStartIndexForPage(_currentPage);

    // Определяем сколько слотов доступно на этой странице
    int availableSlots = _gridSlots;
    if (hasPrevPage) availableSlots--;
    if (hasNextPage) availableSlots--;

    final int roomEndIndex = min(roomStartIndex + availableSlots, _filteredRooms.length);

    final List<Room> roomsForThisPage = _filteredRooms.sublist(roomStartIndex, roomEndIndex);

    final List<dynamic> gridItems = [];
    if (hasPrevPage) gridItems.add('prev');
    gridItems.addAll(roomsForThisPage);
    if (hasNextPage) gridItems.add('next');

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2, // Увеличили высоту ячеек для больших номеров
      ),
      itemCount: gridItems.length,
      itemBuilder: (context, index) {
        final item = gridItems[index];

        if (item is String && item == 'prev') {
          return _buildNavigationButton(
            icon: CupertinoIcons.arrow_left,
            onPressed: () => setState(() => _currentPage--),
          );
        }

        if (item is String && item == 'next') {
          return _buildNavigationButton(
            icon: CupertinoIcons.arrow_right,
            onPressed: () => setState(() => _currentPage++),
          );
        }

        final room = item as Room;
        final isSelected = widget.selectedRoom?.id == room.id;

        return GestureDetector(
          onTap: () => widget.onRoomSelected(room),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: CupertinoColors.activeBlue, width: 2) : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                room.name,
                style: TextStyle(
                  color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}