import 'package:flutter/material.dart';

import '../../widgets/collapsible_section.dart';

class VideoGridSection extends StatelessWidget {
  final bool cameraOn;
  final ValueChanged<bool> onToggleCamera;
  final Widget grid;

  const VideoGridSection({
    super.key,
    required this.cameraOn,
    required this.onToggleCamera,
    required this.grid,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      title: 'Video Processing Grid',
      icon: Icons.grid_view,
      headerColor: Colors.blue.shade50,
      backgroundColor: Colors.blue.shade50.withOpacity(0.3),
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '3x3 Video Grid - User stream and AI processing streams',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              Switch(
                value: cameraOn,
                onChanged: onToggleCamera,
              ),
              const SizedBox(width: 8),
              Text(
                'Camera',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: grid,
          ),
        ],
      ),
    );
  }
}
