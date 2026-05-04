import 'package:flutter/material.dart';

/// All available sections in the app
const List<String> kAllSections = ['Section A', 'Section B', 'Section C'];

/// Small reusable widget – multi-select section chips
class SectionSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const SectionSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7B4DFF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B4DFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group, color: Color(0xFF7B4DFF), size: 18),
              SizedBox(width: 8),
              Text(
                'Assign to Sections *',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose which sections can see this content',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children:
                kAllSections.map((section) {
                  final isSelected = selected.contains(section);
                  return FilterChip(
                    label: Text(section),
                    selected: isSelected,
                    onSelected: (val) {
                      final updated = List<String>.from(selected);
                      if (val) {
                        updated.add(section);
                      } else {
                        updated.remove(section);
                      }
                      onChanged(updated);
                    },
                    selectedColor: const Color(0xFF7B4DFF),
                    checkmarkColor: Colors.white,
                    backgroundColor: const Color(0xFF1C1F3E),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color:
                          isSelected ? const Color(0xFF7B4DFF) : Colors.white24,
                    ),
                  );
                }).toList(),
          ),
          if (selected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade300,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Please select at least one section',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
