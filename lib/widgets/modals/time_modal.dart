// MIGRATION: components/modal/TimeModal.tsx → Dart.
//            Hour/minute picker modal preserved.
//            React Native Modal → showDialog() + AlertDialog.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TimeModal extends StatefulWidget {
  final bool isVisible;
  final String label;
  final String defaultTime; // format "HH:MM" or "HH:MM AM/PM"
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const TimeModal({
    super.key,
    required this.isVisible,
    required this.label,
    required this.defaultTime,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<TimeModal> createState() => _TimeModalState();
}

class _TimeModalState extends State<TimeModal> {
  int _hour = 22;
  int _minute = 0;
  bool _isAm = false;

  @override
  void initState() {
    super.initState();
    _parseTime(widget.defaultTime);
  }

  void _parseTime(String t) {
    // Accepts "HH:MM" or "HH:MM AM/PM".
    try {
      final upper = t.toUpperCase();
      final isPm = upper.contains('PM');
      final isAm = upper.contains('AM');
      final clean = t.replaceAll(RegExp(r'[APM\s]', caseSensitive: false), '');
      final parts = clean.split(':');
      _hour = int.parse(parts[0]);
      _minute = int.parse(parts[1]);
      _isAm = isAm || (!isPm && _hour < 12);
    } catch (_) {
      _hour = 22;
      _minute = 0;
      _isAm = false;
    }
  }

  String _formatResult() {
    final h12 = _hour % 12 == 0 ? 12 : _hour % 12;
    final m = _minute.toString().padLeft(2, '0');
    final period = _isAm ? 'AM' : 'PM';
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onCancel,
      child: Material(
        color: AppColors.overlayDark,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent close on inner tap.
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.label,
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 24),
                  // Hour / Minute / AM-PM pickers.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Picker(
                        value: _hour % 12 == 0 ? 12 : _hour % 12,
                        min: 1,
                        max: 12,
                        onChanged: (v) => setState(() {
                          _hour = _isAm ? v % 12 : (v % 12) + 12;
                        }),
                      ),
                      const Text(':',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontFamily: 'SpaceMono')),
                      _Picker(
                        value: _minute,
                        min: 0,
                        max: 59,
                        onChanged: (v) => setState(() => _minute = v),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          _AmPmButton(
                            label: 'AM',
                            selected: _isAm,
                            onTap: () => setState(() {
                              _isAm = true;
                              if (_hour >= 12) _hour -= 12;
                            }),
                          ),
                          _AmPmButton(
                            label: 'PM',
                            selected: !_isAm,
                            onTap: () => setState(() {
                              _isAm = false;
                              if (_hour < 12) _hour += 12;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onCancel,
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  color: AppColors.mutedText)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.generalBlue),
                          onPressed: () => widget.onSave(_formatResult()),
                          child: const Text('Save',
                              style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Picker(
      {required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up, color: Colors.white),
          onPressed: () => onChanged(value >= max ? min : value + 1),
        ),
        Text(value.toString().padLeft(2, '0'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          onPressed: () => onChanged(value <= min ? max : value - 1),
        ),
      ],
    );
  }
}

class _AmPmButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AmPmButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.generalBlue : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                fontFamily: 'SpaceMono', color: Colors.white, fontSize: 12)),
      ),
    );
  }
}
