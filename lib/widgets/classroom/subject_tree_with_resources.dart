import 'package:flutter/material.dart';
import '../../models/classroom_subject.dart';
import '../../models/subject_resource.dart';
import '../../models/resource_type.dart';

/// Enhanced subject tree item that shows quarters and resources
/// Displays a hierarchical tree: Subject > Quarters (Q1-Q4) > Resources
class SubjectTreeItemWithResources extends StatelessWidget {
  final String subjectName;
  final List<ClassroomSubject>? subjects;
  final Map<int, List<SubjectResource>> resourcesByQuarter;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddSubSubject;
  final VoidCallback onAssignTeacher;
  final VoidCallback onAddSubject;
  final bool hasTeacher;
  final int totalResourceCount;
  final Function(int quarter)? onQuarterTap;
  final int? selectedQuarter;

  const SubjectTreeItemWithResources({
    super.key,
    required this.subjectName,
    this.subjects,
    required this.resourcesByQuarter,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
    required this.onToggleExpand,
    required this.onAddSubSubject,
    required this.onAssignTeacher,
    required this.onAddSubject,
    required this.hasTeacher,
    required this.totalResourceCount,
    this.onQuarterTap,
    this.selectedQuarter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main subject item
        InkWell(
          onTap: onTap,
          hoverColor: Colors.grey.shade100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                // Expand/collapse icon
                InkWell(
                  onTap: onToggleExpand,
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subjectName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.blue.shade900
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                // Sub-subject button
                Tooltip(
                  message: 'Add sub-subject',
                  child: InkWell(
                    onTap: onAddSubSubject,
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.purple.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.account_tree,
                        size: 10,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Teacher assignment button with badge
                Tooltip(
                  message: 'Assign teacher',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: onAssignTeacher,
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 10,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      if (hasTeacher)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Plus button (add subject)
                Tooltip(
                  message: 'Add subject',
                  child: InkWell(
                    onTap: onAddSubject,
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 10,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Resource count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: totalResourceCount > 0
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalResourceCount',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: totalResourceCount > 0
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded content - show quarters with resources
        if (isExpanded) _buildQuartersList(context),
      ],
    );
  }

  Widget _buildQuartersList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int quarter = 1; quarter <= 4; quarter++)
            _buildQuarterItem(context, quarter),
        ],
      ),
    );
  }

  Widget _buildQuarterItem(BuildContext context, int quarter) {
    final resources = resourcesByQuarter[quarter] ?? [];
    final isQuarterSelected = selectedQuarter == quarter;

    // Count resources by type
    final moduleCount = resources
        .where((r) => r.resourceType == ResourceType.module)
        .length;
    final assignmentResourceCount = resources
        .where((r) => r.resourceType == ResourceType.assignmentResource)
        .length;
    final assignmentCount = resources
        .where((r) => r.resourceType == ResourceType.assignment)
        .length;
    final totalCount = resources.length;

    return InkWell(
      onTap: onQuarterTap != null ? () => onQuarterTap!(quarter) : null,
      hoverColor: Colors.grey.shade50,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isQuarterSelected ? Colors.blue.shade50 : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isQuarterSelected
                  ? Colors.blue.shade400
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Q$quarter',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isQuarterSelected
                    ? Colors.blue.shade900
                    : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            // Resource type badges
            if (moduleCount > 0) ...[
              _buildResourceBadge(moduleCount, Colors.green, 'M', 'Modules'),
              const SizedBox(width: 3),
            ],
            if (assignmentResourceCount > 0) ...[
              _buildResourceBadge(
                assignmentResourceCount,
                Colors.orange,
                'AR',
                'Assignment Resources',
              ),
              const SizedBox(width: 3),
            ],
            if (assignmentCount > 0) ...[
              _buildResourceBadge(
                assignmentCount,
                Colors.purple,
                'A',
                'Assignments',
              ),
              const SizedBox(width: 3),
            ],
            // Total count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: totalCount > 0
                    ? Colors.grey.shade200
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalCount',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceBadge(
    int count,
    MaterialColor color,
    String label,
    String tooltip,
  ) {
    return Tooltip(
      message: '$count $tooltip',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.shade50,
          border: Border.all(color: color.shade200, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
