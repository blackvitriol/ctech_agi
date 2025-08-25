import 'package:flutter/material.dart';

import '../../widgets/collapsible_section.dart';

class ConnectionLogsSection extends StatelessWidget {
  final List<String> logs;
  final VoidCallback onClear;

  const ConnectionLogsSection({
    super.key,
    required this.logs,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      title: 'Connection Logs',
      icon: Icons.info_outline,
      headerColor: Colors.red.shade50,
      backgroundColor: Colors.red.shade50.withOpacity(0.3),
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Real-time connection and system messages',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear Logs'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No connection logs yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[logs.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log,
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
