
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/calendar_dialog.dart';

class DashboardCalendar extends StatefulWidget {
  const DashboardCalendar({super.key});

  @override
  State<DashboardCalendar> createState() => _DashboardCalendarState();
}

class _DashboardCalendarState extends State<DashboardCalendar> {
  late final ValueNotifier<List<String>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock data for events
  final Map<DateTime, List<String>> _mockEvents = {
    DateTime.utc(2024, 5, 20): ['Web conference with the CEO', 'Team Leadership and Collaboration'],
    DateTime.utc(2024, 5, 22): ['Project Alpha Deadline'],
    DateTime.utc(2024, 6, 1): ['Submit Q2 Report', 'Review new hire applications'],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<String> _getEventsForDay(DateTime day) {
    // Implementation for getting events for a given day
    return _mockEvents[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMMd().format(_focusedDay),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_full, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CalendarDialog(),
                    );
                  },
                  tooltip: 'Expand Calendar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
                defaultTextStyle: TextStyle(fontSize: 12),
                weekendTextStyle: TextStyle(fontSize: 12, color: Colors.redAccent),
                outsideTextStyle: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                        width: 7.0,
                        height: 7.0,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const Divider(height: 24),
            const Text('Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ValueListenableBuilder<List<String>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(child: Text('No events for this day.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(value[index]),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
