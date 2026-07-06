// MIGRATION: app/(auth)/index.tsx (Login) → Dart StatefulWidget.
//            authStore.login() → AuthCubit.login().
//            expo-router useRouter().push → context.push() (go_router).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/auth_input.dart';
import '../../widgets/general_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _password = '';

  void _login() {
    context.read<AuthCubit>().login(_email, _password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthActionLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome Back!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 8),
                  const Text('Sign in to your account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 40),
                  AuthInput(
                    placeholder: 'Email',
                    value: _email,
                    onChangeText: (v) => setState(() => _email = v),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  AuthInput(
                    placeholder: 'Password',
                    value: _password,
                    onChangeText: (v) => setState(() => _password = v),
                    secureTextEntry: true,
                    showPasswordToggle: true,
                  ),
                  GeneralButton(
                    title: 'Sign In',
                    onPress: _login,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16)),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: const Text('Register',
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
