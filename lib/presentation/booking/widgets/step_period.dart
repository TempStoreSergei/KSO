// ============================================
// lib/presentation/booking/widgets/step_period.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // === ИСПРАВЛЕНИЕ #1: ПРАВИЛЬНЫЙ ИМПОРТ MATERIAL ===
import 'package:motel/presentation/booking/widgets/step_container.dart';

// === ИЗМЕНЕНИЕ: Виджет преобразован в StatefulWidget для управления выбором диапазона ===
class StepPeriod extends StatefulWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final Function(DateTime, DateTime) onDatesChanged;

  const StepPeriod({super.key, required this.checkIn, required this.checkOut, required this.onDatesChanged});

  @override
  State<StepPeriod> createState() => _StepPeriodState();
}

class _StepPeriodState extends State<StepPeriod> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _startDate = widget.checkIn;
    _endDate = widget.checkOut;
    _displayMonth = DateTime(widget.checkIn.year, widget.checkIn.month);
  }

  void _onDateSelected(DateTime day) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = day;
        _endDate = null;
      } else {
        if (day.isAfter(_startDate!)) {
          _endDate = day;
        } else {
          _startDate = day;
          _endDate = null;
        }
      }
    });

    if (_startDate != null && _endDate != null) {
      widget.onDatesChanged(_startDate!, _endDate!);
    } else if (_startDate != null && _endDate == null) {
      widget.onDatesChanged(_startDate!, _startDate!.add(const Duration(days: 1)));
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + increment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.calendar,
      title: 'Период проживания',
      subtitle: 'Выберите даты заезда и выезда',
      child: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 24),
          _buildTotalNightsTag(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    // === ИСПРАВЛЕНИЕ #2: ИСПОЛЬЗУЕМ DateUtils ИЗ MATERIAL ===
    final daysInMonth = DateUtils.getDaysInMonth(_displayMonth.year, _displayMonth.month);
    final firstDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 12),
          _buildWeekdays(),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: daysInMonth + startingWeekday - 1,
            itemBuilder: (context, index) {
              if (index < startingWeekday - 1) {
                return Container();
              }

              final dayNumber = index - startingWeekday + 2;
              final currentDate = DateTime(_displayMonth.year, _displayMonth.month, dayNumber);

              // === ИСПРАВЛЕНИЕ #3: ИСПОЛЬЗУЕМ DateUtils ИЗ MATERIAL ===
              final isBeforeToday = currentDate.isBefore(DateUtils.dateOnly(DateTime.now()));

              return _buildDayCell(currentDate, isBeforeToday);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isBeforeToday) {
    // === ИСПРАВЛЕНИЕ #4: ИСПОЛЬЗУЕМ DateUtils ИЗ MATERIAL ===
    bool isStartDate = _startDate != null && DateUtils.isSameDay(day, _startDate);
    bool isEndDate = _endDate != null && DateUtils.isSameDay(day, _endDate);
    bool isInRange = _startDate != null && _endDate != null && day.isAfter(_startDate!) && day.isBefore(_endDate!);

    BoxDecoration decoration;
    Color textColor = isBeforeToday ? CupertinoColors.systemGrey3 : CupertinoColors.white;

    if (isStartDate || isEndDate) {
      decoration = BoxDecoration(color: CupertinoColors.activeBlue, shape: BoxShape.circle);
      textColor = CupertinoColors.white;
    } else if (isInRange) {
      decoration = BoxDecoration(color: CupertinoColors.activeBlue.withOpacity(0.3), shape: BoxShape.circle);
    } else {
      decoration = const BoxDecoration();
    }

    return GestureDetector(
      onTap: isBeforeToday ? null : () => _onDateSelected(day),
      child: Container(
        alignment: Alignment.center,
        decoration: decoration,
        child: Text(
          day.day.toString(),
          style: TextStyle(color: textColor, fontWeight: isStartDate || isEndDate ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _changeMonth(-1),
          child: const Icon(CupertinoIcons.chevron_left, color: CupertinoColors.systemGrey),
        ),
        Text(
          // === ИСПРАВЛЕНИЕ #5: ИСПОЛЬЗУЕМ MaterialLocalizations ИЗ MATERIAL ===
          '${MaterialLocalizations.of(context).formatMonthYear(_displayMonth)}',
          style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _changeMonth(1),
          child: const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey),
        ),
      ],
    );
  }

  Widget _buildWeekdays() {
    final List<String> weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) => Text(day, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12))).toList(),
    );
  }

  Widget _buildTotalNightsTag() {
    final nights = (_endDate != null && _startDate != null) ? _endDate!.difference(_startDate!).inDays : 0;

    if (nights <= 0) return const SizedBox.shrink();

    String nightsWord = 'ночей';
    if (nights % 10 == 1 && nights % 100 != 11) nightsWord = 'ночь';
    if ([2, 3, 4].contains(nights % 10) && ![12, 13, 14].contains(nights % 100)) nightsWord = 'ночи';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Итого: $nights $nightsWord',
        style: const TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}