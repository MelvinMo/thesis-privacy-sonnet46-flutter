// MIGRATION: components/modal/JournalEntryModal.tsx → Dart.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class JournalEntryModal extends StatefulWidget {
  final bool isVisible;
  final String tempDiaryEntry;
  final ValueChanged<String> onDiaryEntryChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const JournalEntryModal({
    super.key,
    required this.isVisible,
    required this.tempDiaryEntry,
    required this.onDiaryEntryChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<JournalEntryModal> createState() => _JournalEntryModalState();
}

class _JournalEntryModalState extends State<JournalEntryModal> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tempDiaryEntry);
  }

  @override
  void didUpdateWidget(JournalEntryModal old) {
    super.didUpdateWidget(old);
    if (widget.tempDiaryEntry != _controller.text) {
      _controller.text = widget.tempDiaryEntry;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              const Text('Journal Entry',
                  style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                onChanged: widget.onDiaryEntryChanged,
                maxLines: 8,
                style: const TextStyle(
                    fontFamily: 'SpaceMono', color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Write about your day...',
                  hintStyle: TextStyle(color: Colors.white38, fontFamily: 'SpaceMono'),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
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
                      onPressed: widget.onSave,
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
