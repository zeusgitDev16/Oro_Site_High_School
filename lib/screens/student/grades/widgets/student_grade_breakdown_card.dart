import 'package:flutter/material.dart';

/// **Phase 2 Task 2.4: Student Grade Breakdown Card**
/// 
/// Displays detailed grade breakdown: WW/PT/QA items with scores.
/// Extracted from student_grade_viewer_screen.dart with modern styling.
class StudentGradeBreakdownCard extends StatefulWidget {
  final Map<String, dynamic> explanation;
  final int quarter;
  final bool isLoading;

  const StudentGradeBreakdownCard({
    super.key,
    required this.explanation,
    required this.quarter,
    this.isLoading = false,
  });

  @override
  State<StudentGradeBreakdownCard> createState() => _StudentGradeBreakdownCardState();
}

class _StudentGradeBreakdownCardState extends State<StudentGradeBreakdownCard> {
  bool _wwExpanded = true;
  bool _ptExpanded = true;
  bool _qaExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final items = widget.explanation['items'] as Map<String, dynamic>? ?? {};
    final computed = widget.explanation['computed'] as Map<String, dynamic>? ?? {};
    final wwItems = (items['ww'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final ptItems = (items['pt'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final qaItems = (items['qa'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.analytics, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Grade Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Written Works
            _buildComponentSection(
              title: 'Written Works (WW)',
              items: wwItems,
              color: Colors.blue,
              isExpanded: _wwExpanded,
              onToggle: () => setState(() => _wwExpanded = !_wwExpanded),
              computed: computed['ww'] as Map<String, dynamic>?,
            ),

            const SizedBox(height: 12),

            // Performance Tasks
            _buildComponentSection(
              title: 'Performance Tasks (PT)',
              items: ptItems,
              color: Colors.orange,
              isExpanded: _ptExpanded,
              onToggle: () => setState(() => _ptExpanded = !_ptExpanded),
              computed: computed['pt'] as Map<String, dynamic>?,
            ),

            const SizedBox(height: 12),

            // Quarterly Assessment
            _buildComponentSection(
              title: 'Quarterly Assessment (QA)',
              items: qaItems,
              color: Colors.purple,
              isExpanded: _qaExpanded,
              onToggle: () => setState(() => _qaExpanded = !_qaExpanded),
              computed: computed['qa'] as Map<String, dynamic>?,
            ),

            const SizedBox(height: 16),

            // Computation Summary
            if (computed.isNotEmpty) _buildComputationSummary(computed),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    Map<String, dynamic>? computed,
  }) {
    final totalScore = items.fold<double>(
      0.0,
      (sum, item) => sum + ((item['score'] as num?)?.toDouble() ?? 0.0),
    );
    final totalMax = items.fold<double>(
      0.0,
      (sum, item) => sum + ((item['max'] as num?)?.toDouble() ?? 0.0),
    );
    final missingCount = items.where((item) => item['missing'] == true).length;

    final ps = computed?['ps'] as num?;
    final ws = computed?['ws'] as num?;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(8))
                    : BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    '${totalScore.toStringAsFixed(1)} / ${totalMax.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (isExpanded) ...[
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items list
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No items yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...items.map((item) => _buildItemRow(item, color)),

                  // Missing count
                  if (missingCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '$missingCount missing submission${missingCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Computation
                  if (ps != null && ws != null) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Percentage Score (PS)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${ps.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weighted Score (WS)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          ws.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item, Color color) {
    final title = item['title'] as String? ?? 'Untitled';
    final score = (item['score'] as num?)?.toDouble() ?? 0.0;
    final max = (item['max'] as num?)?.toDouble() ?? 0.0;
    final isMissing = item['missing'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMissing ? Icons.cancel : Icons.check_circle,
            size: 14,
            color: isMissing ? Colors.grey.shade400 : Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isMissing ? Colors.grey.shade500 : Colors.black87,
                decoration: isMissing ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            isMissing
                ? 'Missing'
                : '${score.toStringAsFixed(1)} / ${max.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMissing ? Colors.grey.shade500 : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComputationSummary(Map<String, dynamic> computed) {
    final initialGrade = (computed['initial_grade'] as num?)?.toDouble();
    final transmutedGrade = (computed['transmuted_grade'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Final Computation',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (initialGrade != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Initial Grade',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  initialGrade.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          if (transmutedGrade != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transmuted Grade',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  transmutedGrade.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


