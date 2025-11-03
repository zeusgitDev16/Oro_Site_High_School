import 'package:flutter/material.dart';

class TeacherCalendarView extends StatelessWidget {
  const TeacherCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Schedule',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View your class schedule and upcoming events',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _buildWeeklySchedule(),
          const SizedBox(height: 32),
          _buildUpcomingClasses(),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildScheduleDay('Monday', [
              {'time': '8:00 - 9:00 AM', 'subject': 'Mathematics 7', 'room': 'Room 101'},
              {'time': '10:00 - 11:00 AM', 'subject': 'Advisory Class', 'room': 'Room 101'},
            ]),
            const Divider(height: 32),
            _buildScheduleDay('Tuesday', [
              {'time': '10:00 - 11:30 AM', 'subject': 'Science 7', 'room': 'Lab 201'},
            ]),
            const Divider(height: 32),
            _buildScheduleDay('Wednesday', [
              {'time': '8:00 - 9:00 AM', 'subject': 'Mathematics 7', 'room': 'Room 101'},
            ]),
            const Divider(height: 32),
            _buildScheduleDay('Thursday', [
              {'time': '10:00 - 11:30 AM', 'subject': 'Science 7', 'room': 'Lab 201'},
            ]),
            const Divider(height: 32),
            _buildScheduleDay('Friday', [
              {'time': '8:00 - 9:00 AM', 'subject': 'Mathematics 7', 'room': 'Room 101'},
              {'time': '2:00 - 3:00 PM', 'subject': 'Faculty Meeting', 'room': 'Conference Room'},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleDay(String day, List<Map<String, String>> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...classes.map((classInfo) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classInfo['subject']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              classInfo['time']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.room, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              classInfo['room']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildUpcomingClasses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Classes Today',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildUpcomingClassCard(
          'Mathematics 7',
          'Grade 7 - Diamond',
          '8:00 - 9:00 AM',
          'Room 101',
          'In 30 minutes',
          Colors.blue,
          true,
        ),
        const SizedBox(height: 12),
        _buildUpcomingClassCard(
          'Advisory Class',
          'Grade 7 - Diamond',
          '10:00 - 11:00 AM',
          'Room 101',
          'In 2 hours',
          Colors.green,
          false,
        ),
      ],
    );
  }

  Widget _buildUpcomingClassCard(
    String subject,
    String section,
    String time,
    String room,
    String countdown,
    Color color,
    bool isNext,
  ) {
    return Card(
      elevation: isNext ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isNext ? Border.all(color: color, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isNext) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEXT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.room, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          room,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    countdown,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Start Class'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
