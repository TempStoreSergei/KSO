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

  const StepRoomSelection({super.key, required this.onRoomSelected, this.selectedRoom});

  @override
  State<StepRoomSelection> createState() => _StepRoomSelectionState();
}

class _StepRoomSelectionState extends State<StepRoomSelection> {
  int _currentPage = 0;
  late int _totalPages;
  final int _gridSlots = 12;

  // Состояние для хранения загруженных комнат
  late Future<List<Room>> _roomsFuture;
  List<Room> _allRooms = [];

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

  void _calculatePages() {
    if (_allRooms.isEmpty) {
      _totalPages = 1;
      return;
    }

    // Для одной страницы - все слоты доступны
    if (_allRooms.length <= _gridSlots) {
      _totalPages = 1;
      return;
    }

    // Первая страница: _gridSlots - 1 (минус кнопка вперед)
    // Средние страницы: _gridSlots - 2 (минус обе кнопки)
    // Последняя страница: _gridSlots - 1 (минус кнопка назад)

    int remainingRooms = _allRooms.length;
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
          _calculatePages();
          subtitle = 'Страница ${_currentPage + 1} из $_totalPages';
        }

        return StepContainer(
          icon: CupertinoIcons.bed_double_fill,
          title: 'Выберите комнату',
          subtitle: subtitle,
          child: SizedBox(
            height: 300, // Увеличили высоту для размещения 3 рядов с новым aspect ratio
            child: _buildContent(snapshot),
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

    // 4. Успешная загрузка - строим сетку
    final bool hasPrevPage = _currentPage > 0;
    final bool hasNextPage = _currentPage < _totalPages - 1;

    // Получаем индекс начала для текущей страницы
    final int roomStartIndex = _getStartIndexForPage(_currentPage);

    // Определяем сколько слотов доступно на этой странице
    int availableSlots = _gridSlots;
    if (hasPrevPage) availableSlots--;
    if (hasNextPage) availableSlots--;

    final int roomEndIndex = min(roomStartIndex + availableSlots, _allRooms.length);

    final List<Room> roomsForThisPage = _allRooms.sublist(roomStartIndex, roomEndIndex);

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