// MIGRATION: components/Calendar.tsx → Dart StatefulWidget.
//            Props: selectedDate, setSelectedDate.
//            Navigate months, select dates — same UX as source.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _prevMonth() => setState(() {
        _displayMonth =
            DateTime(_displayMonth.year, _displayMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _displayMonth =
            DateTime(_displayMonth.year, _displayMonth.month + 1);
      });

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayMonth.year, _displayMonth.month);
    final firstWeekday =
        DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Month navigation header.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: _prevMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_displayMonth),
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: _nextMonth,
              ),
            ],
          ),
          // Day-of-week labels.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            color: AppColors.mutedText,
                            fontSize: 11,
                          )),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Day grid.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth + firstWeekday,
            itemBuilder: (_, index) {
              if (index < firstWeekday) return const SizedBox.shrink();
              final day = index - firstWeekday + 1;
              final date = DateTime(_displayMonth.year, _displayMonth.month, day);
              final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              return GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.generalBlue
                        : isToday
                            ? AppColors.inputBackground
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.generalBlue
                              : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
