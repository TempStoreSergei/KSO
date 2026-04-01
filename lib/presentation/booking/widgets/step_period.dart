
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
  static const int _maxNights = 31;
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _displayMonth;
  late final DateTime _today;
  late final DateTime _minSelectableDate;
  late final DateTime _maxSelectableDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.checkIn;
    _endDate = widget.checkOut;
    _today = DateUtils.dateOnly(DateTime.now());
    _minSelectableDate = DateUtils.addMonthsToMonthDate(_today, -1);
    _maxSelectableDate = DateUtils.addMonthsToMonthDate(_today, 1);
    // Если даты не заданы, показываем текущий месяц
    final initialDate = widget.checkIn ?? DateTime.now();
    _displayMonth = DateTime(initialDate.year, initialDate.month);
  }

  DateTime _dateOnly(DateTime date) => DateUtils.dateOnly(date);

  bool _isSelectable(DateTime day) {
    final d = _dateOnly(day);
    return !d.isBefore(_minSelectableDate) && !d.isAfter(_maxSelectableDate);
  }

  bool _exceedsNightLimit(DateTime day) {
    if (_startDate == null || _endDate != null) return false;
    final selected = _dateOnly(day);
    final start = _dateOnly(_startDate!);
    if (!selected.isAfter(start)) return false;
    return selected.difference(start).inDays > _maxNights;
  }

  void _onDateSelected(DateTime day) {
    final selectedDay = _dateOnly(day);
    final start = _startDate == null ? null : _dateOnly(_startDate!);

    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = selectedDay;
        _endDate = null;
      } else {
        if (selectedDay.isAfter(start!)) {
          if (selectedDay.difference(start).inDays > _maxNights) {
            return;
          }
          _endDate = selectedDay;
        } else {
          _startDate = selectedDay;
          _endDate = null;
        }
      }
    });

    // Отправляем обновленные даты, даже если выбрана только одна
    widget.onDatesChanged(_startDate, _endDate);
  }

  void _changeMonth(int increment) {
    final target = DateTime(_displayMonth.year, _displayMonth.month + increment);
    final minMonth = DateTime(_minSelectableDate.year, _minSelectableDate.month);
    final maxMonth = DateTime(_maxSelectableDate.year, _maxSelectableDate.month);

    if (target.isBefore(minMonth) || target.isAfter(maxMonth)) {
      return;
    }

    setState(() {
      _displayMonth = target;
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
              final isDisabled = !_isSelectable(currentDate) || _exceedsNightLimit(currentDate);

              return _buildDayCell(currentDate, isDisabled);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isDisabled) {
    bool isStartDate = _startDate != null && DateUtils.isSameDay(day, _startDate);
    bool isEndDate = _endDate != null && DateUtils.isSameDay(day, _endDate);
    bool isInRange = _startDate != null && _endDate != null && day.isAfter(_startDate!) && day.isBefore(_endDate!);

    Color textColor = isDisabled ? CupertinoColors.systemGrey3 : CupertinoColors.white;
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
      onTap: isDisabled ? null : () => _onDateSelected(day),
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
    final minMonth = DateTime(_minSelectableDate.year, _minSelectableDate.month);
    final maxMonth = DateTime(_maxSelectableDate.year, _maxSelectableDate.month);
    final canGoPrev = _displayMonth.isAfter(minMonth);
    final canGoNext = _displayMonth.isBefore(maxMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          minimumSize: const Size(96, 52),
          onPressed: canGoPrev ? () => _changeMonth(-1) : null,
          child: Icon(
            CupertinoIcons.chevron_left,
            color: canGoPrev ? CupertinoColors.systemGrey : CupertinoColors.systemGrey3,
            size: 24,
          ),
        ),
        Text(
          MaterialLocalizations.of(context).formatMonthYear(_displayMonth),
          style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          minimumSize: const Size(96, 52),
          onPressed: canGoNext ? () => _changeMonth(1) : null,
          child: Icon(
            CupertinoIcons.chevron_right,
            color: canGoNext ? CupertinoColors.systemGrey : CupertinoColors.systemGrey3,
            size: 24,
          ),
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
