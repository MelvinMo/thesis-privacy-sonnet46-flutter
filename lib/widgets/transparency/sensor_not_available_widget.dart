// MIGRATION: iOS light sensor stub — Rule 10.
//            No equivalent in the source (it silently uses simulation).
//            This widget provides explicit user feedback on iOS.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SensorNotAvailableWidget extends StatelessWidget {
  final String sensorName;

  const SensorNotAvailableWidget({
    super.key,
    this.sensorName = 'Light Sensor',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sensors_off, color: AppColors.mutedText, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$sensorName not available on this device.',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
