// lib/presentation/booking/room_booking_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:motel/core/api/api_client.dart';

// Модели данных
class AdditionalService {
  final String id;
  final String name;
  final String description;
  final int price;
  final int originalPrice;

  AdditionalService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
  });
}

class BookingData {
  String? firstName;
  String? lastName;
  String? middleName;
  DateTime? checkInDate;
  DateTime? checkOutDate;
  AdditionalService? selectedService;
  String? paymentMethod;

  int get totalNights {
    if (checkInDate == null || checkOutDate == null) return 0;
    return checkOutDate!.difference(checkInDate!).inDays;
  }

  bool get isValid {
    return firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty &&
        checkInDate != null &&
        checkOutDate != null &&
        checkOutDate!.isAfter(checkInDate!) &&
        paymentMethod != null;
  }
}

// Use Cases
class RoomBookingUseCases {
  final ApiClient _apiClient;

  RoomBookingUseCases(this._apiClient);

  Future<void> createBooking({
    required String firstName,
    required String lastName,
    required String middleName,
    required DateTime checkIn,
    required DateTime checkOut,
    String? serviceId,
    required String paymentMethod,
  }) async {
    await _apiClient.post(
      '/bookings/create',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        if (serviceId != null) 'service_id': serviceId,
        'payment_method': paymentMethod,
      },
    );
  }

  List<AdditionalService> getAvailableServices() {
    return [
      AdditionalService(
        id: 'breakfast',
        name: 'Завтрак',
        description: 'Континентальный завтрак в номер',
        price: 500,
        originalPrice: 650,
      ),
      AdditionalService(
        id: 'parking',
        name: 'Парковка',
        description: 'Охраняемая парковка на территории',
        price: 300,
        originalPrice: 400,
      ),
      AdditionalService(
        id: 'spa',
        name: 'СПА-услуги',
        description: 'Доступ к СПА-зоне и бассейну',
        price: 1200,
        originalPrice: 1500,
      ),
    ];
  }
}

// Главный виджет
class RoomBookingScreen extends StatelessWidget {
  const RoomBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RoomBookingUseCases useCases = RoomBookingUseCases(ApiClient.instance);

    return Provider.value(
      value: useCases,
      child: const _RoomBookingView(),
    );
  }
}

class _RoomBookingView extends StatefulWidget {
  const _RoomBookingView();

  @override
  State<_RoomBookingView> createState() => _RoomBookingViewState();
}

class _RoomBookingViewState extends State<_RoomBookingView> {
  final BookingData _bookingData = BookingData();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  bool _isLoading = false;
  int _selectedTab = 1;

  @override
  void initState() {
    super.initState();
    _bookingData.checkInDate = DateTime.now();
    _bookingData.checkOutDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_bookingData.isValid) {
      _showErrorDialog('Пожалуйста, заполните все обязательные поля');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final useCases = Provider.of<RoomBookingUseCases>(context, listen: false);

      await useCases.createBooking(
        firstName: _bookingData.firstName!,
        lastName: _bookingData.lastName!,
        middleName: _bookingData.middleName ?? '',
        checkIn: _bookingData.checkInDate!,
        checkOut: _bookingData.checkOutDate!,
        serviceId: _bookingData.selectedService?.id,
        paymentMethod: _bookingData.paymentMethod!,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showErrorDialog('Ошибка при создании бронирования: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Не выбрано';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  int _calculateTotalPrice() {
    int basePrice = 3000;
    int total = basePrice * _bookingData.totalNights;

    if (_bookingData.selectedService != null) {
      total += _bookingData.selectedService!.price * _bookingData.totalNights;
    }

    return total;
  }

  int _calculateOriginalPrice() {
    int basePrice = 3500;
    int total = basePrice * _bookingData.totalNights;

    if (_bookingData.selectedService != null) {
      total += _bookingData.selectedService!.originalPrice * _bookingData.totalNights;
    }

    return total;
  }

  int _calculateDiscount() {
    return _calculateOriginalPrice() - _calculateTotalPrice();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Вкладки сверху
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _buildTab('Корзина', 0),
                  const SizedBox(width: 20),
                  _buildTab('Оформление заказа', 1),
                ],
              ),
            ),

            // Основной контент
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Левая часть - основной контент
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPeriodSection(),
                          const SizedBox(height: 30),
                          _buildGuestDataSection(),
                          const SizedBox(height: 30),
                          _buildServicesSection(),
                          const SizedBox(height: 30),
                          _buildPaymentSection(),
                        ],
                      ),
                    ),
                  ),

                  // Правая панель - итоги
                  Container(
                    width: 400,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      border: Border(
                        left: BorderSide(
                          color: CupertinoColors.separator.resolveFrom(context),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildSummaryPanel(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? CupertinoColors.label.resolveFrom(context)
              : CupertinoColors.systemGrey.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Период проживания',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            // Открываем отдельный экран для выбора периода
            final result = await Navigator.of(context).push<Map<String, DateTime>>(
              CupertinoPageRoute(
                builder: (_) => SelectPeriodScreen(
                  initialCheckIn: _bookingData.checkInDate,
                  initialCheckOut: _bookingData.checkOutDate,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _bookingData.checkInDate = result['checkIn'];
                _bookingData.checkOutDate = result['checkOut'];
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.calendar, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Проверили, где можно сдать именно эти анализы в вашем городе',
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatDate(_bookingData.checkInDate)} - ${_formatDate(_bookingData.checkOutDate)} (${_bookingData.totalNights} ${_getNightsWord(_bookingData.totalNights)})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getNightsWord(int nights) {
    if (nights % 10 == 1 && nights % 100 != 11) return 'ночь';
    if ([2, 3, 4].contains(nights % 10) && ![12, 13, 14].contains(nights % 100)) return 'ночи';
    return 'ночей';
  }

  Widget _buildGuestDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Данные гостя',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            _showGuestDataModal();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.person, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Введите данные гостя',
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getGuestDataSummary(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getGuestDataSummary() {
    if (_bookingData.lastName != null &&
        _bookingData.lastName!.isNotEmpty &&
        _bookingData.firstName != null &&
        _bookingData.firstName!.isNotEmpty) {
      return '${_bookingData.lastName} ${_bookingData.firstName}';
    }
    return 'Не заполнено';
  }

  void _showGuestDataModal() {
    final tempLastName = TextEditingController(text: _bookingData.lastName);
    final tempFirstName = TextEditingController(text: _bookingData.firstName);
    final tempMiddleName = TextEditingController(text: _bookingData.middleName);

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Хедер модального окна
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Отмена'),
                      onPressed: () {
                        tempLastName.dispose();
                        tempFirstName.dispose();
                        tempMiddleName.dispose();
                        Navigator.of(context).pop();
                      },
                    ),
                    const Text(
                      'Данные гостя',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Готово'),
                      onPressed: () {
                        setState(() {
                          _bookingData.lastName = tempLastName.text;
                          _bookingData.firstName = tempFirstName.text;
                          _bookingData.middleName = tempMiddleName.text;

                          _lastNameController.text = tempLastName.text;
                          _firstNameController.text = tempFirstName.text;
                          _middleNameController.text = tempMiddleName.text;
                        });

                        tempLastName.dispose();
                        tempFirstName.dispose();
                        tempMiddleName.dispose();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              // Контент модального окна
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalTextField(
                        label: 'Фамилия',
                        controller: tempLastName,
                        placeholder: 'Иванов',
                      ),
                      const SizedBox(height: 20),
                      _buildModalTextField(
                        label: 'Имя',
                        controller: tempFirstName,
                        placeholder: 'Иван',
                      ),
                      const SizedBox(height: 20),
                      _buildModalTextField(
                        label: 'Отчество',
                        controller: tempMiddleName,
                        placeholder: 'Иванович',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.systemGrey.resolveFrom(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дополнительные услуги',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            // Открываем отдельный экран для выбора услуги
            final result = await Navigator.of(context).push<AdditionalService>(
              CupertinoPageRoute(
                builder: (_) => SelectServiceScreen(
                  currentService: _bookingData.selectedService,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _bookingData.selectedService = result;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.square_list, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выбрать дополнительную услугу',
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bookingData.selectedService?.name ?? 'Не выбрано',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Способ оплаты',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            // Открываем отдельный экран для выбора способа оплаты
            final result = await Navigator.of(context).push<String>(
              CupertinoPageRoute(
                builder: (_) => SelectPaymentMethodScreen(
                  currentMethod: _bookingData.paymentMethod,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _bookingData.paymentMethod = result;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.creditcard, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выбрать способ оплаты',
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bookingData.paymentMethod ?? 'Не выбрано',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPanel() {
    final totalPrice = _calculateTotalPrice();
    final originalPrice = _calculateOriginalPrice();
    final discount = _calculateDiscount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(
          'Проживание',
          '${3500 * _bookingData.totalNights} ₽',
          strikethrough: true,
          subtitle: 'от ${3000 * _bookingData.totalNights} ₽',
        ),
        const SizedBox(height: 16),

        if (_bookingData.selectedService != null) ...[
          _buildSummaryRow(
            _bookingData.selectedService!.name,
            '${_bookingData.selectedService!.originalPrice * _bookingData.totalNights} ₽',
            strikethrough: true,
            subtitle: 'от ${_bookingData.selectedService!.price * _bookingData.totalNights} ₽',
          ),
          const SizedBox(height: 16),
        ],

        if (discount > 0) ...[
          _buildSummaryRow(
            'Скидка',
            'до -$discount ₽',
            valueColor: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 24),
        ] else
          const SizedBox(height: 8),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Итого',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (originalPrice > totalPrice)
                  Text(
                    '$originalPrice ₽',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            Text(
              'от $totalPrice ₽',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: _isLoading || !_bookingData.isValid ? null : _submitBooking,
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text(
              'Забронировать номер',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                color: CupertinoColors.activeBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'При бронировании требуется внесение предоплаты в размере 30% от стоимости',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool strikethrough = false,
        String? subtitle,
        Color? valueColor,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: valueColor,
                decoration: strikethrough ? TextDecoration.lineThrough : null,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Успешно'),
        content: const Text('Номер успешно забронирован!'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ЗАГЛУШКИ ДЛЯ ОТДЕЛЬНЫХ ЭКРАНОВ

// Экран выбора периода проживания
class SelectPeriodScreen extends StatelessWidget {
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;

  const SelectPeriodScreen({
    super.key,
    this.initialCheckIn,
    this.initialCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Выбор периода'),
        previousPageTitle: 'Назад',
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Экран выбора периода проживания',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              child: const Text('Выбрать период'),
              onPressed: () {
                Navigator.of(context).pop({
                  'checkIn': DateTime.now(),
                  'checkOut': DateTime.now().add(const Duration(days: 3)),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Экран выбора дополнительной услуги
class SelectServiceScreen extends StatelessWidget {
  final AdditionalService? currentService;

  const SelectServiceScreen({super.key, this.currentService});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Дополнительные услуги'),
        previousPageTitle: 'Назад',
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Экран выбора дополнительной услуги',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              child: const Text('Выбрать завтрак'),
              onPressed: () {
                Navigator.of(context).pop(
                  AdditionalService(
                    id: 'breakfast',
                    name: 'Завтрак',
                    description: 'Континентальный завтрак',
                    price: 500,
                    originalPrice: 650,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Экран выбора способа оплаты
class SelectPaymentMethodScreen extends StatelessWidget {
  final String? currentMethod;

  const SelectPaymentMethodScreen({super.key, this.currentMethod});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Способ оплаты'),
        previousPageTitle: 'Назад',
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Экран выбора способа оплаты',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              child: const Text('Выбрать картой'),
              onPressed: () {
                Navigator.of(context).pop('Банковская карта');
              },
            ),
          ],
        ),
      ),
    );
  }
}