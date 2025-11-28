import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/screens/student/grades/widgets/student_quarter_selector.dart';
import 'package:oro_site_high_school/screens/student/grades/widgets/student_grade_summary_card.dart';
import 'package:oro_site_high_school/screens/student/grades/widgets/student_grade_breakdown_card.dart';

/// **Phase 2 Task 2.3: Student Grades Content Panel (Right Panel)**
/// 
/// Displays grade information for selected subject and quarter.
/// Composes quarter selector, summary card, and breakdown card.
class StudentGradesContentPanel extends StatelessWidget {
  final ClassroomSubject subject;
  final int selectedQuarter;
  final Function(int) onQuarterSelected;
  final Map<int, Map<String, dynamic>> quarterGrades;
  final Map<String, dynamic>? explanation;
  final bool isLoadingGrades;
  final bool isLoadingExplanation;

  const StudentGradesContentPanel({
    super.key,
    required this.subject,
    required this.selectedQuarter,
    required this.onQuarterSelected,
    required this.quarterGrades,
    required this.explanation,
    this.isLoadingGrades = false,
    this.isLoadingExplanation = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradeData = quarterGrades[selectedQuarter];
    final hasGrade = gradeData != null;

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header with subject name and quarter selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject name
                Row(
                  children: [
                    Icon(Icons.book, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject.subjectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Quarter selector
                StudentQuarterSelector(
                  selectedQuarter: selectedQuarter,
                  onQuarterSelected: onQuarterSelected,
                  availableQuarters: quarterGrades.keys.toList(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: isLoadingGrades
                ? const Center(child: CircularProgressIndicator())
                : !hasGrade
                    ? _buildNoGradeState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Grade Summary Card
                            StudentGradeSummaryCard(
                              gradeData: gradeData,
                              quarter: selectedQuarter,
                            ),

                            const SizedBox(height: 16),

                            // Grade Breakdown Card
                            if (explanation != null)
                              StudentGradeBreakdownCard(
                                explanation: explanation!,
                                quarter: selectedQuarter,
                                isLoading: isLoadingExplanation,
                              )
                            else if (isLoadingExplanation)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGradeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No grade available for Quarter $selectedQuarter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your teacher hasn\'t computed your grade yet',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

