import 'package:flutter/material.dart';

/// Child Selector Dialog - Allows parent to select which child to view
/// Used when parent has multiple children
class ChildSelectorDialog extends StatelessWidget {
  final List<Map<String, dynamic>> children;
  final String? selectedChildId;
  final Function(String) onChildSelected;

  const ChildSelectorDialog({
    super.key,
    required this.children,
    this.selectedChildId,
    required this.onChildSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Child'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: children.length,
          itemBuilder: (context, index) {
            final child = children[index];
            final isSelected = child['id'] == selectedChildId;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelected ? Colors.orange : Colors.grey,
                child: Text(
                  _getInitials(child['name']),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(child['name']),
              subtitle: Text('Grade ${child['gradeLevel']} - ${child['section']}'),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.orange) : null,
              onTap: () {
                onChildSelected(child['id']);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}
