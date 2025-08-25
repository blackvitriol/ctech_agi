import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../widgets/collapsible_section.dart';

class DeviceSettingsSection extends StatelessWidget {
  final bool isLoadingDevices;
  final List<MediaDeviceInfo> videoDevices;
  final List<MediaDeviceInfo> audioInputDevices;
  final List<MediaDeviceInfo> audioOutputDevices;
  final String? selectedVideoDeviceId;
  final String? selectedAudioInputId;
  final String? selectedAudioOutputId;
  final VoidCallback onRefreshDevices;
  final ValueChanged<String?> onVideoChanged;
  final ValueChanged<String?> onAudioInputChanged;
  final ValueChanged<String?> onAudioOutputChanged;
  final Map<String, dynamic> deviceInfo;
  final List<String> sensors;

  const DeviceSettingsSection({
    super.key,
    required this.isLoadingDevices,
    required this.videoDevices,
    required this.audioInputDevices,
    required this.audioOutputDevices,
    required this.selectedVideoDeviceId,
    required this.selectedAudioInputId,
    required this.selectedAudioOutputId,
    required this.onRefreshDevices,
    required this.onVideoChanged,
    required this.onAudioInputChanged,
    required this.onAudioOutputChanged,
    required this.deviceInfo,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      title: 'Device Settings',
      icon: Icons.devices,
      headerColor: Colors.green.shade50,
      backgroundColor: Colors.green.shade50.withOpacity(0.3),
      initiallyExpanded: true,
      trailing: TextButton.icon(
        onPressed: onRefreshDevices,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Refresh'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Device Selection',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoadingDevices)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<String>(
              value: selectedVideoDeviceId,
              decoration: const InputDecoration(
                labelText: 'Select Camera',
                border: OutlineInputBorder(),
              ),
              items: videoDevices.map((device) {
                return DropdownMenuItem(
                  value: device.deviceId,
                  child: Text(device.label.isNotEmpty
                      ? device.label
                      : 'Camera ${videoDevices.indexOf(device) + 1}'),
                );
              }).toList(),
              onChanged: onVideoChanged,
            ),
          const SizedBox(height: 16),
          Text(
            'Audio Device Selection',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedAudioInputId,
            decoration: const InputDecoration(
              labelText: 'Select Microphone (audio input)',
              border: OutlineInputBorder(),
            ),
            isExpanded: true,
            items: audioInputDevices.map((device) {
              return DropdownMenuItem(
                value: device.deviceId,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        device.label.isNotEmpty
                            ? device.label
                            : 'Mic ${audioInputDevices.indexOf(device) + 1}',
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              return audioInputDevices.map((device) {
                final label = device.label.isNotEmpty
                    ? device.label
                    : 'Mic ${audioInputDevices.indexOf(device) + 1}';
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                    softWrap: false,
                  ),
                );
              }).toList();
            },
            onChanged: onAudioInputChanged,
          ),
          const SizedBox(height: 12),
          if (!WebRTC.platformIsMobile)
            DropdownButtonFormField<String>(
              value: selectedAudioOutputId,
              decoration: const InputDecoration(
                labelText: 'Select Speaker (audio output)',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: audioOutputDevices.map((device) {
                return DropdownMenuItem(
                  value: device.deviceId,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.label.isNotEmpty
                              ? device.label
                              : 'Speaker ${audioOutputDevices.indexOf(device) + 1}',
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              selectedItemBuilder: (context) {
                return audioOutputDevices.map((device) {
                  final label = device.label.isNotEmpty
                      ? device.label
                      : 'Speaker ${audioOutputDevices.indexOf(device) + 1}';
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  );
                }).toList();
              },
              onChanged: onAudioOutputChanged,
            ),
          const SizedBox(height: 16),
          Text(
            'System Info',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          if (deviceInfo.isEmpty)
            Text(
              'No device info available',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...deviceInfo.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 180,
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${e.value}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Sensors: ${sensors.isEmpty ? 'None' : sensors.join(', ')}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
