// ============================================
// lib/presentation/booking/widgets/step_item_selection.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';
import 'package:provider/provider.dart';

class StepItemSelection extends StatefulWidget {
  final BookingCategory category;
  final List<BookingItem> selectedItems;
  final Function(List<BookingItem>) onItemsChanged;

  const StepItemSelection({
    super.key,
    required this.category,
    required this.selectedItems,
    required this.onItemsChanged,
  });

  @override
  State<StepItemSelection> createState() => _StepItemSelectionState();
}

class _StepItemSelectionState extends State<StepItemSelection> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Регистрируем поле поиска в клавиатуре если это услуги или штрафы
    if (_shouldShowSearch()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final keyboardNotifier = context.read<KeyboardNotifier>();
        keyboardNotifier.registerFields(
          controllers: [_searchController],
          focusNodes: [_searchFocusNode],
        );
      });
    }

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _shouldShowSearch() {
    return widget.category == BookingCategory.services ||
        widget.category == BookingCategory.ruleViolationPenalty ||
        widget.category == BookingCategory.propertyDamagePenalty;
  }

  String _getCategoryTitle() {
    switch (widget.category) {
      case BookingCategory.accommodation:
        return 'Выберите услуги к проживанию';
      case BookingCategory.services:
        return 'Выберите услуги';
      case BookingCategory.ruleViolationPenalty:
        return 'Выберите штрафы за нарушение правил';
      case BookingCategory.propertyDamagePenalty:
        return 'Выберите штрафы за порчу имущества';
      case BookingCategory.unknown:
        return '';
    }
  }

  // Моковые данные для разных категорий
  List<BookingItem> _getMockItems() {
    switch (widget.category) {
      case BookingCategory.accommodation:
        return [
          BookingItem(
            id: 'breakfast',
            name: 'Завтрак',
            price: 500,
            category: BookingCategory.accommodation,
          ),
          BookingItem(
            id: 'parking',
            name: 'Парковка',
            price: 300,
            category: BookingCategory.accommodation,
          ),
          BookingItem(
            id: 'spa',
            name: 'СПА-услуги',
            price: 1200,
            category: BookingCategory.accommodation,
          ),
          BookingItem(
            id: 'gym',
            name: 'Тренажёрный зал',
            price: 400,
            category: BookingCategory.accommodation,
          ),
        ];
      case BookingCategory.services:
        return [
          BookingItem(
            id: 'laundry',
            name: 'Прачечная',
            price: 800,
            category: BookingCategory.services,
          ),
          BookingItem(
            id: 'room_service',
            name: 'Обслуживание в номере',
            price: 600,
            category: BookingCategory.services,
          ),
          BookingItem(
            id: 'transfer',
            name: 'Трансфер',
            price: 1500,
            category: BookingCategory.services,
          ),
          BookingItem(
            id: 'excursion',
            name: 'Экскурсия',
            price: 2000,
            category: BookingCategory.services,
          ),
          BookingItem(
            id: 'massage',
            name: 'Массаж',
            price: 1800,
            category: BookingCategory.services,
          ),
          BookingItem(
            id: 'sauna',
            name: 'Сауна',
            price: 1000,
            category: BookingCategory.services,
          ),
        ];
      case BookingCategory.ruleViolationPenalty:
        return [
          BookingItem(
            id: 'smoking',
            name: 'Курение в номере',
            price: 5000,
            category: BookingCategory.ruleViolationPenalty,
          ),
          BookingItem(
            id: 'noise',
            name: 'Нарушение тишины',
            price: 2000,
            category: BookingCategory.ruleViolationPenalty,
          ),
          BookingItem(
            id: 'pets',
            name: 'Содержание животных без разрешения',
            price: 3000,
            category: BookingCategory.ruleViolationPenalty,
          ),
          BookingItem(
            id: 'unauthorized_guests',
            name: 'Неразрешённые гости',
            price: 2500,
            category: BookingCategory.ruleViolationPenalty,
          ),
        ];
      case BookingCategory.propertyDamagePenalty:
        return [
          BookingItem(
            id: 'furniture_damage',
            name: 'Повреждение мебели',
            price: 10000,
            category: BookingCategory.propertyDamagePenalty,
          ),
          BookingItem(
            id: 'appliance_damage',
            name: 'Повреждение техники',
            price: 15000,
            category: BookingCategory.propertyDamagePenalty,
          ),
          BookingItem(
            id: 'linen_damage',
            name: 'Порча белья',
            price: 3000,
            category: BookingCategory.propertyDamagePenalty,
          ),
          BookingItem(
            id: 'wall_damage',
            name: 'Повреждение стен/пола',
            price: 8000,
            category: BookingCategory.propertyDamagePenalty,
          ),
          BookingItem(
            id: 'window_damage',
            name: 'Повреждение окон',
            price: 12000,
            category: BookingCategory.propertyDamagePenalty,
          ),
        ];
      case BookingCategory.unknown:
        return [];
    }
  }

  List<BookingItem> get _filteredItems {
    final items = _getMockItems();
    if (_searchQuery.isEmpty) {
      return items;
    }
    return items.where((item) => item.name.toLowerCase().contains(_searchQuery)).toList();
  }

  void _toggleItem(BookingItem item) {
    final updatedItems = List<BookingItem>.from(widget.selectedItems);
    final index = updatedItems.indexWhere((i) => i.id == item.id);

    if (index >= 0) {
      updatedItems.removeAt(index);
    } else {
      updatedItems.add(item);
    }

    widget.onItemsChanged(updatedItems);
  }

  bool _isSelected(BookingItem item) {
    return widget.selectedItems.any((i) => i.id == item.id);
  }

  String _getSubtitle() {
    final count = widget.selectedItems.length;
    if (widget.category == BookingCategory.accommodation) {
      return count > 0
          ? 'Выбрано: $count (опционально)'
          : 'Опционально - можете пропустить';
    }
    return 'Выбрано: $count';
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      title: _getCategoryTitle(),
      subtitle: _getSubtitle(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_shouldShowSearch()) _buildSearchField(),
          SizedBox(
            height: _shouldShowSearch() ? 280 : 320,
            child: _buildItemsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: CupertinoTextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        placeholder: 'Поиск...',
        prefix: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey, size: 18),
        ),
        clearButtonMode: OverlayVisibilityMode.editing,
        style: const TextStyle(color: CupertinoColors.white, fontSize: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  IconData _getItemIcon(BookingItem item) {
    // Иконки для услуг проживания
    if (widget.category == BookingCategory.accommodation) {
      switch (item.id) {
        case 'breakfast':
          return CupertinoIcons.cart_fill;
        case 'parking':
          return CupertinoIcons.car_fill;
        case 'spa':
          return CupertinoIcons.sparkles;
        case 'gym':
          return CupertinoIcons.flame_fill;
        default:
          return CupertinoIcons.checkmark_circle_fill;
      }
    }
    // Иконки для доп. услуг
    else if (widget.category == BookingCategory.services) {
      switch (item.id) {
        case 'laundry':
          return CupertinoIcons.archivebox_fill;
        case 'room_service':
          return CupertinoIcons.tray_fill;
        case 'transfer':
          return CupertinoIcons.car_fill;
        case 'excursion':
          return CupertinoIcons.map_fill;
        case 'massage':
          return CupertinoIcons.hand_raised_fill;
        case 'sauna':
          return CupertinoIcons.flame_fill;
        default:
          return CupertinoIcons.star_fill;
      }
    }
    // Иконки для штрафов за нарушение правил
    else if (widget.category == BookingCategory.ruleViolationPenalty) {
      return CupertinoIcons.exclamationmark_triangle_fill;
    }
    // Иконки для штрафов за порчу имущества
    else if (widget.category == BookingCategory.propertyDamagePenalty) {
      return CupertinoIcons.exclamationmark_octagon_fill;
    }
    return CupertinoIcons.circle_fill;
  }

  Color _getItemIconColor(BookingItem item) {
    // Цвета для услуг проживания
    if (widget.category == BookingCategory.accommodation) {
      switch (item.id) {
        case 'breakfast':
          return CupertinoColors.systemOrange;
        case 'parking':
          return CupertinoColors.systemBlue;
        case 'spa':
          return CupertinoColors.systemPurple;
        case 'gym':
          return CupertinoColors.systemRed;
        default:
          return CupertinoColors.systemGreen;
      }
    }
    // Цвета для доп. услуг
    else if (widget.category == BookingCategory.services) {
      switch (item.id) {
        case 'laundry':
          return CupertinoColors.systemTeal;
        case 'room_service':
          return CupertinoColors.systemIndigo;
        case 'transfer':
          return CupertinoColors.systemBlue;
        case 'excursion':
          return CupertinoColors.systemGreen;
        case 'massage':
          return CupertinoColors.systemPink;
        case 'sauna':
          return CupertinoColors.systemOrange;
        default:
          return CupertinoColors.systemYellow;
      }
    }
    // Цвет для штрафов за нарушение правил
    else if (widget.category == BookingCategory.ruleViolationPenalty) {
      return CupertinoColors.systemYellow;
    }
    // Цвет для штрафов за порчу имущества
    else if (widget.category == BookingCategory.propertyDamagePenalty) {
      return CupertinoColors.systemRed;
    }
    return CupertinoColors.systemGrey;
  }

  Widget _buildItemsList() {
    final items = _filteredItems;

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        CupertinoListSection.insetGrouped(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: const Color(0xFF000000),
          children: items.map((item) {
            final isSelected = _isSelected(item);
            return CupertinoListTile(
              title: Text(
                item.name,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${item.price} ₽',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _getItemIconColor(item),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getItemIcon(item),
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              trailing: Icon(
                isSelected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey,
                size: 24,
              ),
              onTap: () => _toggleItem(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}
