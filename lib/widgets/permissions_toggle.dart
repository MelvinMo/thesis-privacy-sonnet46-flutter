// MIGRATION: components/PermissionsToggle.tsx → Dart.
//            Switch control with label — replaces React Native Switch.

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class PermissionsToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onValueChange;
  final String label;

  const PermissionsToggle({
    super.key,
    required this.value,
    required this.onValueChange,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // MIGRATION: RN — plain Row, no card background. marginVertical: 10,
    //            paddingHorizontal: 20, width: '100%', label flex: 2.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                )),
          ),
          Switch(
            value: value,
            onChanged: onValueChange,
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFCCCCCC)),
            thumbColor: WidgetStateProperty.all(Colors.white),
          ),
        ],
      ),
    );
  }
}
