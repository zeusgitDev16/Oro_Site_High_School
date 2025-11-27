import 'package:flutter/material.dart';

/// Quiz Assignment Builder Widget
/// 
/// Reusable widget for building quiz-type assignments.
/// 
/// Content Structure:
/// ```json
/// {
///   "questions": [
///     {
///       "question": "What is 2+2?",
///       "answer": "4",
///       "points": 1
///     }
///   ]
/// }
/// ```
/// 
/// Features:
/// - Add/remove questions
/// - Auto-calculate total points
/// - Validation
/// - Small text UI (10-12px)
class QuizAssignmentBuilder extends StatefulWidget {
  final List<Map<String, dynamic>> initialQuestions;
  final ValueChanged<List<Map<String, dynamic>>> onQuestionsChanged;
  final ValueChanged<int> onTotalPointsChanged;

  const QuizAssignmentBuilder({
    super.key,
    required this.initialQuestions,
    required this.onQuestionsChanged,
    required this.onTotalPointsChanged,
  });

  @override
  State<QuizAssignmentBuilder> createState() => _QuizAssignmentBuilderState();
}

class _QuizAssignmentBuilderState extends State<QuizAssignmentBuilder> {
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List<Map<String, dynamic>>.from(widget.initialQuestions);
  }

  void _addQuestion() {
    setState(() {
      _questions.add({'question': '', 'answer': '', 'points': 1});
      _notifyChanges();
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      _notifyChanges();
    });
  }

  void _updateQuestion(int index, String field, dynamic value) {
    setState(() {
      _questions[index][field] = value;
      _notifyChanges();
    });
  }

  void _notifyChanges() {
    widget.onQuestionsChanged(_questions);
    final totalPoints = _questions.fold<int>(
      0,
      (sum, q) => sum + (q['points'] as int? ?? 0),
    );
    widget.onTotalPointsChanged(totalPoints);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Quiz Questions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Add Question',
                style: TextStyle(fontSize: 11),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_questions.isEmpty)
          _buildEmptyState()
        else
          ..._questions.asMap().entries.map((entry) {
            return _buildQuestionCard(entry.key, entry.value);
          }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No questions added yet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click "Add Question" to create your first quiz question',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: question['points']?.toString() ?? '1',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Points',
                      labelStyle: TextStyle(fontSize: 10),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 11),
                    onChanged: (value) {
                      _updateQuestion(index, 'points', int.tryParse(value) ?? 1);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red.shade400,
                  onPressed: () => _removeQuestion(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question['question'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Question',
                labelStyle: TextStyle(fontSize: 11),
                hintText: 'Enter your question here',
                hintStyle: TextStyle(fontSize: 10),
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              onChanged: (value) => _updateQuestion(index, 'question', value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question['answer'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Correct Answer',
                labelStyle: TextStyle(fontSize: 11),
                hintText: 'Enter the correct answer',
                hintStyle: TextStyle(fontSize: 10),
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 11),
              onChanged: (value) => _updateQuestion(index, 'answer', value),
            ),
          ],
        ),
      ),
    );
  }
}

