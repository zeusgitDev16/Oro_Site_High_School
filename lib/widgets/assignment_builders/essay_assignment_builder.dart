import 'package:flutter/material.dart';

/// Essay Assignment Builder Widget
/// 
/// Reusable widget for building essay-type assignments.
/// 
/// Content Structure:
/// ```json
/// {
///   "questions": [
///     {
///       "question": "Discuss the impact of climate change",
///       "guidelines": "Minimum 500 words, cite sources",
///       "minWords": 500,
///       "points": 10
///     }
///   ]
/// }
/// ```
/// 
/// Features:
/// - Add/remove questions
/// - Optional guidelines and minimum word count
/// - Auto-calculate total points
/// - Validation
/// - Small text UI (10-12px)
/// - Manual grading required
class EssayAssignmentBuilder extends StatefulWidget {
  final List<Map<String, dynamic>> initialQuestions;
  final ValueChanged<List<Map<String, dynamic>>> onQuestionsChanged;
  final ValueChanged<int> onTotalPointsChanged;

  const EssayAssignmentBuilder({
    super.key,
    required this.initialQuestions,
    required this.onQuestionsChanged,
    required this.onTotalPointsChanged,
  });

  @override
  State<EssayAssignmentBuilder> createState() => _EssayAssignmentBuilderState();
}

class _EssayAssignmentBuilderState extends State<EssayAssignmentBuilder> {
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List<Map<String, dynamic>>.from(widget.initialQuestions);
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': '',
        'guidelines': '',
        'minWords': null,
        'points': 10,
      });
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
              'Essay Questions',
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
          }),
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
            Icon(Icons.article, size: 48, color: Colors.grey.shade400),
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
              'Click "Add Question" to create your first essay question',
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
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 12, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Manual Grading',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: question['points']?.toString() ?? '10',
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
                      _updateQuestion(index, 'points', int.tryParse(value) ?? 10);
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
                labelText: 'Essay Question',
                labelStyle: TextStyle(fontSize: 11),
                hintText: 'Enter your essay question here',
                hintStyle: TextStyle(fontSize: 10),
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 11),
              maxLines: 3,
              onChanged: (value) => _updateQuestion(index, 'question', value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question['guidelines'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Guidelines (Optional)',
                labelStyle: TextStyle(fontSize: 11),
                hintText: 'e.g., Cite sources, minimum 500 words',
                hintStyle: TextStyle(fontSize: 10),
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              onChanged: (value) => _updateQuestion(index, 'guidelines', value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 150,
              child: TextFormField(
                initialValue: question['minWords']?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Words (Optional)',
                  labelStyle: TextStyle(fontSize: 10),
                  hintText: 'e.g., 500',
                  hintStyle: TextStyle(fontSize: 10),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 11),
                onChanged: (value) {
                  _updateQuestion(
                    index,
                    'minWords',
                    value.isEmpty ? null : int.tryParse(value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

