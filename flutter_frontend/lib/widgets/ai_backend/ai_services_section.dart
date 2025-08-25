import 'package:flutter/material.dart';

import '../../widgets/collapsible_section.dart';

class AIServicesSection extends StatelessWidget {
  final Map<String, Map<String, bool>> selections;
  final void Function(String category, String key, bool value) onChanged;

  const AIServicesSection({
    super.key,
    required this.selections,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      title: 'AI Services',
      icon: Icons.extension,
      headerColor: Colors.teal.shade50,
      backgroundColor: Colors.teal.shade50.withOpacity(0.3),
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategory(context, 'Vision', selections['vision'] ?? {}),
          const SizedBox(height: 12),
          _buildCategory(context, 'NLP', selections['nlp'] ?? {}),
          const SizedBox(height: 12),
          _buildCategory(context, 'Audio', selections['audio'] ?? {}),
        ],
      ),
    );
  }

  Widget _buildCategory(
      BuildContext context, String title, Map<String, bool> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: items.entries.map((e) {
            final key = e.key;
            final checked = e.value;
            return FilterChip(
              label: Text(_prettyName(key)),
              selected: checked,
              onSelected: (v) => onChanged(_categoryKey(title), key, v),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _categoryKey(String title) {
    switch (title) {
      case 'Vision':
        return 'vision';
      case 'NLP':
        return 'nlp';
      case 'Audio':
        return 'audio';
      default:
        return title.toLowerCase();
    }
  }

  String _prettyName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
        .join(' ');
  }
}
