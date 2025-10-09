// ============================================
// lib/presentation/booking/widgets/step_service_selection.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/api_service.dart';
import 'package:motel/domain/usecases/get_services.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

// === ИЗМЕНЕНИЕ: Виджет преобразован в StatefulWidget для самостоятельной загрузки данных ===
class StepServiceSelection extends StatefulWidget {
  final ApiService? selectedService;
  final Function(ApiService) onServiceSelected;

  const StepServiceSelection({
    super.key,
    this.selectedService,
    required this.onServiceSelected,
  });

  @override
  State<StepServiceSelection> createState() => _StepServiceSelectionState();
}

class _StepServiceSelectionState extends State<StepServiceSelection> {
  // Состояние для хранения загруженных данных
  late Future<List<ApiService>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    // Запускаем загрузку данных при инициализации виджета
    _loadServices();
  }

  void _loadServices() {
    final getServicesUseCase = GetServices(ApiClient.instance);
    // Присваиваем Future нашей переменной состояния
    _servicesFuture = getServicesUseCase.call();
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.star_fill,
      title: 'Выберите услугу',
      subtitle: 'Добавьте что-то особенное к вашему отдыху',
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        // === ИЗМЕНЕНИЕ: Используем FutureBuilder для отображения состояний загрузки ===
        child: FutureBuilder<List<ApiService>>(
          future: _servicesFuture,
          builder: (context, snapshot) {
            // 1. Пока идет загрузка, показываем индикатор
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator(radius: 15));
            }

            // 2. Если произошла ошибка, показываем сообщение
            if (snapshot.hasError) {
              return Center(
                child: Text('Ошибка загрузки услуг', style: TextStyle(color: CupertinoColors.systemRed)),
              );
            }

            // 3. Если данные пришли, но список пуст
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Дополнительные услуги отсутствуют.', style: TextStyle(color: CupertinoColors.systemGrey)),
              );
            }

            // 4. Если все успешно, строим список
            final services = snapshot.data!;
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final isSelected = widget.selectedService?.id == service.id;

                return GestureDetector(
                  onTap: () => widget.onServiceSelected(service),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${service.price} ₽',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 22,
                          child: isSelected
                              ? const Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.activeBlue, size: 22)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                );
              },
            );
          },
        ),
      ),
    );
  }
}