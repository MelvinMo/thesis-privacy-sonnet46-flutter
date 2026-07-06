// MIGRATION: components/AuthInput.tsx → Dart StatefulWidget.
//            Props: placeholder, value, onChangeText, secureTextEntry,
//                   showPasswordToggle, keyboardType, autoCapitalize.
//            Eye icon toggle for password visibility preserved.

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AuthInput extends StatefulWidget {
  final String placeholder;
  final String value;
  final ValueChanged<String> onChangeText;
  final bool secureTextEntry;
  final bool showPasswordToggle;
  final TextInputType keyboardType;
  final TextCapitalization autoCapitalize;

  const AuthInput({
    super.key,
    required this.placeholder,
    required this.value,
    required this.onChangeText,
    this.secureTextEntry = false,
    this.showPasswordToggle = false,
    this.keyboardType = TextInputType.text,
    this.autoCapitalize = TextCapitalization.none,
  });

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  late bool _obscure;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _obscure = widget.secureTextEntry;
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(AuthInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection =
          TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        obscureText: _obscure,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.autoCapitalize,
        onChanged: widget.onChangeText,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: const TextStyle(
            fontFamily: 'SpaceMono',
            color: Colors.white54,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          // MIGRATION: Eye icon to toggle password visibility (same as source).
          suffixIcon: widget.showPasswordToggle && widget.secureTextEntry
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }
}
