import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_site_high_school/services/deped_grade_service.dart';

/// **Phase 4: Grade Computation Dialog**
///
/// Shows DepEd grade computation breakdown for a student.
/// Allows manual QA entry, weight overrides, plus/extra points, and remarks.
class GradeComputationDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final String classroomId;
  final String courseId;  // Can be either course_id (bigint as string) OR subject_id (UUID)
  final int quarter;
  final VoidCallback? onSaved;

  const GradeComputationDialog({
    super.key,
    required this.student,
    required this.classroomId,
    required this.courseId,
    required this.quarter,
    this.onSaved,
  });

  @override
  State<GradeComputationDialog> createState() => _GradeComputationDialogState();
}

class _GradeComputationDialogState extends State<GradeComputationDialog> {
  final DepEdGradeService _gradeService = DepEdGradeService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _breakdown;
  
  // Manual inputs
  final TextEditingController _qaScoreController = TextEditingController();
  final TextEditingController _qaMaxController = TextEditingController();
  final TextEditingController _wwWeightController = TextEditingController();
  final TextEditingController _ptWeightController = TextEditingController();
  final TextEditingController _qaWeightController = TextEditingController();
  final TextEditingController _plusPointsController = TextEditingController();
  final TextEditingController _extraPointsController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBreakdown();
  }

  @override
  void dispose() {
    _qaScoreController.dispose();
    _qaMaxController.dispose();
    _wwWeightController.dispose();
    _ptWeightController.dispose();
    _qaWeightController.dispose();
    _plusPointsController.dispose();
    _extraPointsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadBreakdown() async {
    setState(() => _isLoading = true);

    try {
      // Detect if courseId is UUID (new system) or bigint (old system)
      final isUuid = widget.courseId.contains('-'); // UUID contains hyphens

      final breakdown = await _gradeService.computeQuarterlyBreakdown(
        classroomId: widget.classroomId,
        courseId: isUuid ? null : widget.courseId,    // OLD: bigint course_id
        subjectId: isUuid ? widget.courseId : null,   // NEW: UUID subject_id
        studentId: widget.student['id'].toString(),
        quarter: widget.quarter,
      );

      setState(() {
        _breakdown = breakdown;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading breakdown: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recompute() async {
    setState(() => _isLoading = true);

    try {
      final qaScore = double.tryParse(_qaScoreController.text) ?? 0;
      final qaMax = double.tryParse(_qaMaxController.text) ?? 0;
      final wwWeight = double.tryParse(_wwWeightController.text);
      final ptWeight = double.tryParse(_ptWeightController.text);
      final qaWeight = double.tryParse(_qaWeightController.text);
      final plusPoints = double.tryParse(_plusPointsController.text) ?? 0;
      final extraPoints = double.tryParse(_extraPointsController.text) ?? 0;

      // Detect if courseId is UUID (new system) or bigint (old system)
      final isUuid = widget.courseId.contains('-');

      final breakdown = await _gradeService.computeQuarterlyBreakdown(
        classroomId: widget.classroomId,
        courseId: isUuid ? null : widget.courseId,    // OLD: bigint course_id
        subjectId: isUuid ? widget.courseId : null,   // NEW: UUID subject_id
        studentId: widget.student['id'].toString(),
        quarter: widget.quarter,
        qaScoreOverride: qaScore,
        qaMaxOverride: qaMax,
        wwWeightOverride: wwWeight != null ? wwWeight / 100 : null,
        ptWeightOverride: ptWeight != null ? ptWeight / 100 : null,
        qaWeightOverride: qaWeight != null ? qaWeight / 100 : null,
        plusPoints: plusPoints,
        extraPoints: extraPoints,
      );

      setState(() {
        _breakdown = breakdown;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error recomputing: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGrade() async {
    if (_breakdown == null) return;

    setState(() => _isSaving = true);

    try {
      final qaScore = double.tryParse(_qaScoreController.text);
      final qaMax = double.tryParse(_qaMaxController.text);
      final wwWeight = double.tryParse(_wwWeightController.text);
      final ptWeight = double.tryParse(_ptWeightController.text);
      final qaWeight = double.tryParse(_qaWeightController.text);
      final plusPoints = double.tryParse(_plusPointsController.text) ?? 0;
      final extraPoints = double.tryParse(_extraPointsController.text) ?? 0;
      final remarks = _remarksController.text.trim();

      // Detect if courseId is UUID (new system) or bigint (old system)
      final isUuid = widget.courseId.contains('-');

      await _gradeService.saveOrUpdateStudentQuarterGrade(
        studentId: widget.student['id'].toString(),
        classroomId: widget.classroomId,
        courseId: isUuid ? null : widget.courseId,    // OLD: bigint course_id
        subjectId: isUuid ? widget.courseId : null,   // NEW: UUID subject_id
        quarter: widget.quarter,
        initialGrade: (_breakdown!['initial_grade'] as num).toDouble(),
        transmutedGrade: (_breakdown!['transmuted_grade'] as num).toDouble(),
        plusPoints: plusPoints,
        extraPoints: extraPoints,
        remarks: remarks.isNotEmpty ? remarks : null,
        qaScoreOverride: qaScore,
        qaMaxOverride: qaMax,
        wwWeightPctOverride: wwWeight,
        ptWeightPctOverride: ptWeight,
        qaWeightPctOverride: qaWeight,
      );

      setState(() => _isSaving = false);

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error saving grade: $e');
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving grade: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: _isLoading ? _buildLoading() : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildContent() {
    if (_breakdown == null) {
      return const Center(child: Text('Failed to load grade breakdown'));
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    final fullName = widget.student['full_name'] ?? 'Unknown';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grade Computation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreakdownSection(),
          const SizedBox(height: 16),
          _buildManualInputsSection(),
          const SizedBox(height: 16),
          _buildAdjustmentsSection(),
          const SizedBox(height: 16),
          _buildRemarksSection(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Spacer(),
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveGrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Grade', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    final weights = _breakdown!['weights'] as Map<String, dynamic>;
    final wwWeight = ((weights['ww'] as num) * 100).toStringAsFixed(0);
    final ptWeight = ((weights['pt'] as num) * 100).toStringAsFixed(0);
    final qaWeight = ((weights['qa'] as num) * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grade Breakdown',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // WW, PT, QA breakdown table
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                _buildTableCell('Component', isHeader: true),
                _buildTableCell('Score', isHeader: true),
                _buildTableCell('Max', isHeader: true),
                _buildTableCell('PS', isHeader: true),
                _buildTableCell('WS', isHeader: true),
              ],
            ),
            // WW
            TableRow(
              children: [
                _buildTableCell('Written Work ($wwWeight%)'),
                _buildTableCell(_breakdown!['ww_score'].toStringAsFixed(1)),
                _buildTableCell(_breakdown!['ww_max'].toStringAsFixed(1)),
                _buildTableCell(_breakdown!['ww_ps'].toStringAsFixed(2)),
                _buildTableCell(_breakdown!['ww_ws'].toStringAsFixed(2)),
              ],
            ),
            // PT
            TableRow(
              children: [
                _buildTableCell('Performance Task ($ptWeight%)'),
                _buildTableCell(_breakdown!['pt_score'].toStringAsFixed(1)),
                _buildTableCell(_breakdown!['pt_max'].toStringAsFixed(1)),
                _buildTableCell(_breakdown!['pt_ps'].toStringAsFixed(2)),
                _buildTableCell(_breakdown!['pt_ws'].toStringAsFixed(2)),
              ],
            ),
            // QA
            TableRow(
              children: [
                _buildTableCell('Quarterly Assessment ($qaWeight%)'),
                _buildTableCell(_breakdown!['qa_score'].toStringAsFixed(1)),
                _buildTableCell(_breakdown!['qa_max'].toStringAsFixed(1)),
                _buildTableCell(_breakdown!['qa_ps'].toStringAsFixed(2)),
                _buildTableCell(_breakdown!['qa_ws'].toStringAsFixed(2)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Final grades
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGradeDisplay(
                'Initial Grade',
                _breakdown!['initial_grade'].toStringAsFixed(2),
                Colors.blue.shade700,
              ),
              Container(width: 1, height: 30, color: Colors.blue.shade200),
              _buildGradeDisplay(
                'Transmuted Grade',
                _breakdown!['transmuted_grade'].toStringAsFixed(2),
                Colors.green.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualInputsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Manual Inputs',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Enter QA score manually and adjust weights if needed',
              child: Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // QA Manual Entry
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _qaScoreController,
                label: 'QA Score',
                hint: '0',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _qaMaxController,
                label: 'QA Max',
                hint: '0',
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Weight Overrides
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _wwWeightController,
                label: 'WW Weight %',
                hint: '30',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _ptWeightController,
                label: 'PT Weight %',
                hint: '50',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _qaWeightController,
                label: 'QA Weight %',
                hint: '20',
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ElevatedButton.icon(
          onPressed: _recompute,
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('Recompute', style: TextStyle(fontSize: 11)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adjustments',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _plusPointsController,
                label: 'Plus Points',
                hint: '0',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _extraPointsController,
                label: 'Extra Points',
                hint: '0',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Remarks',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _remarksController,
          decoration: InputDecoration(
            hintText: 'Optional remarks...',
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 11),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildGradeDisplay(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 11),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
      ],
    );
  }
}

