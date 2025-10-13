// ============================================
// lib/presentation/booking/widgets/step_item_selection.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/datasources/service_remote_data_source.dart';
import 'package:motel/data/repositories/service_repository_impl.dart';
import 'package:motel/domain/entities/service_entity.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/models/fine_models.dart';
import 'package:motel/domain/usecases/get_fines.dart';
import 'package:motel/domain/usecases/get_services_usecase.dart';
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
  List<BookingItem> _items = [];
  bool _isLoading = true;

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

    // Загружаем данные из API
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _fetchItemsFromAPI();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<BookingItem>> _fetchItemsFromAPI() async {
    final apiClient = ApiClient.instance;

    switch (widget.category) {
      case BookingCategory.services:
      case BookingCategory.accommodation:
        // Загружаем услуги из API
        final repository = ServiceRepositoryImpl(
          remoteDataSource: ServiceRemoteDataSourceImpl(apiClient: apiClient),
        );
        final getServicesUseCase = GetServicesUseCase(repository);
        final services = await getServicesUseCase.call();
        return services.map((service) => _serviceToBookingItem(service)).toList();

      case BookingCategory.ruleViolationPenalty:
        // Загружаем штрафы за нарушение правил
        final getFinesUseCase = GetFinesUseCase(apiClient);
        final fines = await getFinesUseCase.getByType(FineType.violationRules);
        return fines.map((fine) => _fineToBookingItem(fine)).toList();

      case BookingCategory.propertyDamagePenalty:
        // Загружаем штрафы за порчу имущества
        final getFinesUseCase = GetFinesUseCase(apiClient);
        final fines = await getFinesUseCase.getByType(FineType.damageToProperty);
        return fines.map((fine) => _fineToBookingItem(fine)).toList();

      case BookingCategory.unknown:
        return [];
    }
  }

  BookingItem _serviceToBookingItem(ServiceEntity service) {
    return BookingItem(
      id: service.id.toString(),
      name: service.name,
      price: service.price,
      category: widget.category,
      isCountable: service.isCountable,
      isDuration: service.isDuration,
    );
  }

  BookingItem _fineToBookingItem(Fine fine) {
    return BookingItem(
      id: fine.id.toString(),
      name: fine.name,
      price: fine.price,
      category: widget.category,
      isCountable: false,
      isDuration: false,
    );
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

  List<BookingItem> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _items;
    }
    return _items.where((item) => item.name.toLowerCase().contains(_searchQuery)).toList();
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

  void _updateItemQuantity(BookingItem item, int newQuantity) {
    final updatedItems = List<BookingItem>.from(widget.selectedItems);
    final index = updatedItems.indexWhere((i) => i.id == item.id);

    if (index >= 0) {
      updatedItems[index].quantity = newQuantity.clamp(1, 99);
      widget.onItemsChanged(updatedItems);
    }
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
            child: _isLoading
                ? const Center(
                    child: CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                      radius: 15,
                    ),
                  )
                : _buildItemsList(),
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
            final selectedItem = widget.selectedItems.firstWhere(
              (i) => i.id == item.id,
              orElse: () => item,
            );

            return CupertinoListTile(
              title: Text(
                item.name,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
              subtitle: _buildSubtitle(item, selectedItem),
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
              trailing: _buildTrailing(item, selectedItem, isSelected),
              onTap: () => _toggleItem(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubtitle(BookingItem item, BookingItem selectedItem) {
    String priceText = '${item.price} ₽';

    if (_isSelected(item)) {
      if (item.isCountable) {
        priceText += ' × ${selectedItem.quantity} = ${selectedItem.totalPrice} ₽';
      } else if (item.isDuration) {
        priceText += ' × ${selectedItem.quantity} ${_getDaysText(selectedItem.quantity)} = ${selectedItem.totalPrice} ₽';
      }
    } else {
      if (item.isCountable) {
        priceText += ' (можно выбрать количество)';
      } else if (item.isDuration) {
        priceText += ' (можно выбрать дни)';
      }
    }

    return Text(
      priceText,
      style: const TextStyle(
        color: CupertinoColors.systemGrey,
        fontSize: 14,
      ),
    );
  }

  String _getDaysText(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день';
    } else if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }

  Widget _buildTrailing(BookingItem item, BookingItem selectedItem, bool isSelected) {
    if (isSelected && (item.isCountable || item.isDuration)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 30,
            onPressed: () => _updateItemQuantity(selectedItem, selectedItem.quantity - 1),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                CupertinoIcons.minus,
                color: CupertinoColors.white,
                size: 18,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${selectedItem.quantity}',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 30,
            onPressed: () => _updateItemQuantity(selectedItem, selectedItem.quantity + 1),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                CupertinoIcons.plus,
                color: CupertinoColors.white,
                size: 18,
              ),
            ),
          ),
        ],
      );
    }

    return Icon(
      isSelected
          ? CupertinoIcons.checkmark_circle_fill
          : CupertinoIcons.circle,
      color: isSelected
          ? CupertinoColors.activeBlue
          : CupertinoColors.systemGrey,
      size: 24,
    );
  }
}
