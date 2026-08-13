// ============================================
// lib/presentation/settings/bill_acceptor/widgets/test_events_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/settings/bill_acceptor/models/bill_acceptor_models.dart';
import 'package:motel/presentation/widgets/sliver_cupertino_list_section.dart';

/// Экран журнала операций теста купюроприемника
class TestEventsScreen extends StatelessWidget {
  final List<TestEvent> events;

  const TestEventsScreen({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Журнал операций'),
            previousPageTitle: 'Назад',
          ),
          SliverCupertinoListSection(
            header: const Text('ВСЕ СОБЫТИЯ'),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
                IconData? icon;
                Color? iconColor;

                switch (event.type) {
                  case 'acceptedBill':
                    icon = CupertinoIcons.money_dollar_circle_fill;
                    iconColor = CupertinoColors.activeGreen;
                    break;
                  case 'successPayment':
                    icon = CupertinoIcons.checkmark_circle_fill;
                    iconColor = CupertinoColors.activeBlue;
                    break;
                  case 'error':
                    icon = CupertinoIcons.exclamationmark_circle_fill;
                    iconColor = CupertinoColors.systemRed;
                    break;
                  case 'info':
                    icon = CupertinoIcons.info_circle_fill;
                    iconColor = CupertinoColors.systemGrey;
                    break;
                }

                return CupertinoListTile(
                  leading: icon != null
                      ? Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: iconColor?.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        )
                      : null,
                  title: Text(_getEventTitle(event)),
                  subtitle: Text(_getEventSubtitle(event)),
                  trailing: Text(
                    '${event.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${event.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${event.timestamp.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 13,
                    ),
                  ),
                );
            },
          ),
        ],
      ),
    );
  }

  String _getEventTitle(TestEvent event) {
    switch (event.type) {
      case 'acceptedBill':
        return 'Принята купюра ${event.data['bill_value']} руб.';
      case 'successPayment':
        return 'Платеж завершен';
      case 'info':
        return 'Информация';
      case 'error':
        return 'Ошибка';
      default:
        return 'Событие ${event.type}';
    }
  }

  String _getEventSubtitle(TestEvent event) {
    switch (event.type) {
      case 'acceptedBill':
        return 'Всего: ${event.data['collected_amount']} руб.';
      case 'successPayment':
        return 'Собрано: ${event.data['collected_amount']} руб., '
            'сдача: ${event.data['change']} руб.';
      case 'info':
      case 'error':
        return event.data['message'] ?? '';
      default:
        return '';
    }
  }
}
