import 'package:flutter/material.dart';

import '../../widgets/collapsible_section.dart';

class ConnectionSettingsSection extends StatelessWidget {
  final String serverUrl;
  final String roomId;
  final String userId;
  final int connectionCount;
  final ValueChanged<String> onServerUrlChanged;
  final ValueChanged<String> onRoomIdChanged;
  final ValueChanged<String> onUserIdChanged;

  const ConnectionSettingsSection({
    super.key,
    required this.serverUrl,
    required this.roomId,
    required this.userId,
    required this.connectionCount,
    required this.onServerUrlChanged,
    required this.onRoomIdChanged,
    required this.onUserIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      title: 'Connection Settings',
      icon: Icons.settings_ethernet,
      headerColor: Colors.orange.shade50,
      backgroundColor: Colors.orange.shade50.withOpacity(0.3),
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: serverUrl,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onServerUrlChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: roomId,
                  decoration: const InputDecoration(
                    labelText: 'Room ID',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onRoomIdChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: userId,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                    hintText: 'Auto-generated if empty',
                  ),
                  onChanged: onUserIdChanged,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Count',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$connectionCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
