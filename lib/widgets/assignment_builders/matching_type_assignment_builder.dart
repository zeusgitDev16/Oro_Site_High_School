import 'package:flutter/material.dart';

/// Matching Type Assignment Builder Widget
/// 
/// Reusable widget for building matching-type assignments.
/// 
/// Content Structure:
/// ```json
/// {
///   "pairs": [
///     {
///       "columnA": "Dog",
///       "columnB": "Bark",
///       "points": 1
///     }
///   ]
/// }
/// ```
/// 
/// Features:
/// - Add/remove pairs
/// - Auto-calculate total points
/// - Validation
/// - Small text UI (10-12px)
/// - Case-insensitive answer checking (handled server-side)
class MatchingTypeAssignmentBuilder extends StatefulWidget {
  final List<Map<String, dynamic>> initialPairs;
  final ValueChanged<List<Map<String, dynamic>>> onPairsChanged;
  final ValueChanged<int> onTotalPointsChanged;

  const MatchingTypeAssignmentBuilder({
    super.key,
    required this.initialPairs,
    required this.onPairsChanged,
    required this.onTotalPointsChanged,
  });

  @override
  State<MatchingTypeAssignmentBuilder> createState() =>
      _MatchingTypeAssignmentBuilderState();
}

class _MatchingTypeAssignmentBuilderState
    extends State<MatchingTypeAssignmentBuilder> {
  late List<Map<String, dynamic>> _pairs;

  @override
  void initState() {
    super.initState();
    _pairs = List<Map<String, dynamic>>.from(widget.initialPairs);
  }

  void _addPair() {
    setState(() {
      _pairs.add({'columnA': '', 'columnB': '', 'points': 1});
      _notifyChanges();
    });
  }

  void _removePair(int index) {
    setState(() {
      _pairs.removeAt(index);
      _notifyChanges();
    });
  }

  void _updatePair(int index, String field, dynamic value) {
    setState(() {
      _pairs[index][field] = value;
      _notifyChanges();
    });
  }

  void _notifyChanges() {
    widget.onPairsChanged(_pairs);
    final totalPoints = _pairs.fold<int>(
      0,
      (sum, p) => sum + (p['points'] as int? ?? 0),
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
              'Matching Type Pairs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addPair,
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Add Pair',
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
        if (_pairs.isEmpty)
          _buildEmptyState()
        else
          ..._pairs.asMap().entries.map((entry) {
            return _buildPairCard(entry.key, entry.value);
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
            Icon(Icons.compare_arrows, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No pairs added yet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click "Add Pair" to create your first matching pair',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairCard(int index, Map<String, dynamic> pair) {
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
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pair ${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: pair['points']?.toString() ?? '1',
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
                      _updatePair(index, 'points', int.tryParse(value) ?? 1);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red.shade400,
                  onPressed: () => _removePair(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: pair['columnA'] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Column A (Question)',
                      labelStyle: TextStyle(fontSize: 11),
                      hintText: 'e.g., Dog',
                      hintStyle: TextStyle(fontSize: 10),
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 11),
                    maxLines: 2,
                    onChanged: (value) => _updatePair(index, 'columnA', value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: pair['columnB'] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Column B (Answer)',
                      labelStyle: TextStyle(fontSize: 11),
                      hintText: 'e.g., Bark',
                      hintStyle: TextStyle(fontSize: 10),
                      helperText: 'Case-insensitive',
                      helperStyle: TextStyle(fontSize: 9),
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 11),
                    maxLines: 2,
                    onChanged: (value) => _updatePair(index, 'columnB', value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

