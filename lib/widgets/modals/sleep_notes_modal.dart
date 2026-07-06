// MIGRATION: components/modal/SleepNotesModal.tsx → Dart.
//            Checkbox list of SleepNote enum values.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/journal_data.dart';

class SleepNotesModal extends StatefulWidget {
  final bool isVisible;
  final List<SleepNote> selectedNotes;
  final ValueChanged<List<SleepNote>> onSave;
  final VoidCallback onCancel;

  const SleepNotesModal({
    super.key,
    required this.isVisible,
    required this.selectedNotes,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<SleepNotesModal> createState() => _SleepNotesModalState();
}

class _SleepNotesModalState extends State<SleepNotesModal> {
  late List<SleepNote> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedNotes);
  }

  @override
  void didUpdateWidget(SleepNotesModal old) {
    super.didUpdateWidget(old);
    if (widget.isVisible && !old.isVisible) {
      _selected = List.from(widget.selectedNotes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    return Material(
      color: AppColors.overlayDark,
      child: Center(
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.9,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sleep Notes',
                  style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              ...SleepNote.values.map((note) {
                final isChecked = _selected.contains(note);
                return CheckboxListTile(
                  title: Text(note.toJson(),
                      style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          color: Colors.white,
                          fontSize: 13)),
                  value: isChecked,
                  activeColor: AppColors.generalBlue,
                  checkColor: Colors.white,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(note);
                    } else {
                      _selected.remove(note);
                    }
                  }),
                );
              }),
              const SizedBox(height: 12),
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
                      onPressed: () => widget.onSave(List.from(_selected)),
                      child: const Text('Save',
                          style: TextStyle(
                              fontFamily: 'SpaceMono', color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
