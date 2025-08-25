import 'package:flutter/material.dart';

import '../../widgets/collapsible_section.dart';

class AIModelsSection extends StatelessWidget {
  final VoidCallback onAddModel;
  final VoidCallback onConfigure;

  const AIModelsSection({
    super.key,
    required this.onAddModel,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      title: 'AI Agent Models',
      icon: Icons.psychology,
      headerColor: Colors.purple.shade50,
      backgroundColor: Colors.purple.shade50.withOpacity(0.3),
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                // Placeholder cards to match original UI
                _ModelCard(
                  name: 'GPT-4 Vision',
                  description:
                      'Advanced multimodal AI model for video analysis',
                  status: 'Active',
                  statusColor: Colors.green,
                  icon: Icons.visibility,
                ),
                SizedBox(width: 12),
                _ModelCard(
                  name: 'Claude 3 Opus',
                  description: 'High-performance reasoning and analysis',
                  status: 'Active',
                  statusColor: Colors.green,
                  icon: Icons.psychology,
                ),
                SizedBox(width: 12),
                _ModelCard(
                  name: 'Gemini Pro',
                  description:
                      'Google\'s multimodal AI for real-time processing',
                  status: 'Standby',
                  statusColor: Colors.orange,
                  icon: Icons.auto_awesome,
                ),
                SizedBox(width: 12),
                _ModelCard(
                  name: 'Custom Vision Model',
                  description: 'Specialized video processing neural network',
                  status: 'Training',
                  statusColor: Colors.blue,
                  icon: Icons.tune,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onAddModel,
                icon: const Icon(Icons.add),
                label: const Text('Add Model'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onConfigure,
                icon: const Icon(Icons.settings),
                label: const Text('Configure'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String name;
  final String description;
  final String status;
  final Color statusColor;
  final IconData icon;

  const _ModelCard({
    required this.name,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
