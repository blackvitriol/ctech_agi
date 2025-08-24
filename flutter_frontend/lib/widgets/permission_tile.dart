import 'package:flutter/material.dart';

class PermissionTile extends StatelessWidget {
  final String title;
  final bool isGranted;
  final IconData icon;
  final VoidCallback? onRequest;

  const PermissionTile({
    super.key,
    required this.title,
    required this.isGranted,
    required this.icon,
    this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle;
    String description;

    switch (title.toLowerCase()) {
      case 'camera':
        subtitle = isGranted ? 'Permission granted' : 'Permission denied';
        description = 'Required for video calls and camera features';
        break;
      case 'microphone':
        subtitle = isGranted ? 'Permission granted' : 'Permission denied';
        description = 'Required for voice calls and audio recording';
        break;
      case 'sensors':
        subtitle = isGranted ? 'Available' : 'Unavailable';
        description = 'Used for device orientation and motion detection';
        break;
      default:
        subtitle = isGranted ? 'Available' : 'Unavailable';
        description = 'Required for app functionality';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        leading: Icon(icon, color: isGranted ? Colors.green : Colors.red),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : onRequest != null
                ? ElevatedButton.icon(
                    onPressed: onRequest,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  )
                : null,
      ),
    );
  }
}
