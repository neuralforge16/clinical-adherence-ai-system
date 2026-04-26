import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/api_service.dart';

class DoctorCalendar extends StatefulWidget {
  const DoctorCalendar({super.key});

  @override
  State<DoctorCalendar> createState() => _DoctorCalendarState();
}

class _DoctorCalendarState extends State<DoctorCalendar> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _red = Color(0xFFEF4444);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _mutedText = Color(0xFF6B7280);

  DateTime _today = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Map>> _events = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await ApiService.getCalendarEvents();
      final loaded = <DateTime, List<Map>>{};
      for (var e in data) {
        final date = DateTime.parse(e['date']);
        final normalized = DateTime.utc(date.year, date.month, date.day);
        loaded.putIfAbsent(normalized, () => []).add(e);
      }
      if (mounted)
        setState(() {
          _events = loaded;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map> _eventsForDay(DateTime day) =>
      _events[DateTime.utc(day.year, day.month, day.day)] ?? [];

  Color _eventColor(String type) {
    switch (type) {
      case 'missed':
        return _red;
      case 'alert':
        return _amber;
      case 'scheduled':
        return _primary;
      default:
        return _mutedText;
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'missed':
        return Icons.warning_amber_rounded;
      case 'alert':
        return Icons.notifications_active;
      case 'scheduled':
        return Icons.medication;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _eventsForDay(_today);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color.fromRGBO(0, 0, 0, 0.06),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: _primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Medication Events Calendar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Loading
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading calendar...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[
            // Calendar
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2035),
              selectedDayPredicate: (day) => isSameDay(_today, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _today = selected;
                  _focusedDay = focused;
                });
              },
              eventLoader: _eventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: _primary.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: _mutedText),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: _primary,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: _primary,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: _mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: _mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Events for selected day
            Row(
              children: [
                const Text(
                  'Events for selected day',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                if (dayEvents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${dayEvents.length}',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (dayEvents.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'No events scheduled',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...dayEvents.map((event) {
                final type = (event['type'] ?? '').toString();
                final color = _eventColor(type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_eventIcon(type), color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            if ((event['description'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                event['description'].toString(),
                                style: const TextStyle(
                                  color: _mutedText,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
