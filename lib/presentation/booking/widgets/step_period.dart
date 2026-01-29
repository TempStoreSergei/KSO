
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepPeriod extends StatefulWidget {
  final DateTime? checkIn;
  final DateTime? checkOut;
  final Function(DateTime?, DateTime?) onDatesChanged;

  const StepPeriod({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onDatesChanged,
  });

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
    // Если даты не заданы, показываем текущий месяц
    final initialDate = widget.checkIn ?? DateTime.now();
    _displayMonth = DateTime(initialDate.year, initialDate.month);
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

    // Отправляем обновленные даты, даже если выбрана только одна
    widget.onDatesChanged(_startDate, _endDate);
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
              final isBeforeToday = currentDate.isBefore(DateUtils.dateOnly(DateTime.now()));

              return _buildDayCell(currentDate, isBeforeToday);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isBeforeToday) {
    bool isStartDate = _startDate != null && DateUtils.isSameDay(day, _startDate);
    bool isEndDate = _endDate != null && DateUtils.isSameDay(day, _endDate);
    bool isInRange = _startDate != null && _endDate != null && day.isAfter(_startDate!) && day.isBefore(_endDate!);

    Color textColor = isBeforeToday ? CupertinoColors.systemGrey3 : CupertinoColors.white;
    Color? backgroundColor;
    BorderRadius? borderRadius;

    if (isStartDate && isEndDate) {
      backgroundColor = CupertinoColors.activeBlue;
      borderRadius = BorderRadius.circular(8);
      textColor = CupertinoColors.white;
    } else if (isStartDate) {
      backgroundColor = CupertinoColors.activeBlue;
      borderRadius = const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8));
      textColor = CupertinoColors.white;
    } else if (isEndDate) {
      backgroundColor = CupertinoColors.activeBlue;
      borderRadius = const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8));
      textColor = CupertinoColors.white;
    } else if (isInRange) {
      backgroundColor = CupertinoColors.activeBlue.withOpacity(0.3);
      borderRadius = BorderRadius.zero;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isBeforeToday ? null : () => _onDateSelected(day),
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: backgroundColor != null
            ? BoxDecoration(color: backgroundColor, borderRadius: borderRadius)
            : null,
        child: Text(
          day.day.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: isStartDate || isEndDate ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.all(12),
          minSize: 44,
          onPressed: () => _changeMonth(-1),
          child: const Icon(CupertinoIcons.chevron_left, color: CupertinoColors.systemGrey, size: 24),
        ),
        Text(
          MaterialLocalizations.of(context).formatMonthYear(_displayMonth),
          style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        CupertinoButton(
          padding: const EdgeInsets.all(12),
          minSize: 44,
          onPressed: () => _changeMonth(1),
          child: const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey, size: 24),
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
