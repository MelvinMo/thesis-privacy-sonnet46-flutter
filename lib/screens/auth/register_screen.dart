// MIGRATION: app/(auth)/register.tsx → Dart StatefulWidget.
//            Field order mirrors RN: Email → FirstName → LastName → Password → ConfirmPassword.
//            Title "Register Now!" as large inline text (no AppBar), subtitle "Create an account".
//            "Do you have an account? Sign In" link preserved.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/auth_input.dart';
import '../../widgets/general_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _password = '';
  String _confirmPassword = '';

  void _register() {
    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    context.read<AuthCubit>().register(_firstName, _lastName, _email, _password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (ctx, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (ctx, state) {
          final isLoading = state is AuthActionLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Register Now!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 8),
                  const Text('Create an account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 40),
                  // MIGRATION: RN field order — Email, FirstName, LastName, Password, Confirm.
                  AuthInput(
                    placeholder: 'Email',
                    value: _email,
                    onChangeText: (v) => setState(() => _email = v),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  AuthInput(
                    placeholder: 'First Name',
                    value: _firstName,
                    onChangeText: (v) => setState(() => _firstName = v),
                    autoCapitalize: TextCapitalization.words,
                  ),
                  AuthInput(
                    placeholder: 'Last Name',
                    value: _lastName,
                    onChangeText: (v) => setState(() => _lastName = v),
                    autoCapitalize: TextCapitalization.words,
                  ),
                  AuthInput(
                    placeholder: 'Password',
                    value: _password,
                    onChangeText: (v) => setState(() => _password = v),
                    secureTextEntry: true,
                    showPasswordToggle: true,
                  ),
                  AuthInput(
                    placeholder: 'Confirm Password',
                    value: _confirmPassword,
                    onChangeText: (v) => setState(() => _confirmPassword = v),
                    secureTextEntry: true,
                    showPasswordToggle: true,
                  ),
                  GeneralButton(
                    title: 'Register',
                    onPress: _register,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Do you have an account? ',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: const Text('Sign In',
                            style: TextStyle(
                                color: AppColors.hyperlinkBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
