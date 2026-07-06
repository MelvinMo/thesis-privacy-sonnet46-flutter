// MIGRATION: app/(tabs)/profile/index.tsx → Dart.
//            "Hello, {firstName}" greeting matches original RN profile screen.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../blocs/auth/auth_cubit.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/menu_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      const Text('Profile',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),

                // ── User greeting ─────────────────────────────────────────
                if (user != null) ...[
                  const SizedBox(height: 40),
                  Text(
                    'Hello, ${user.firstName.isNotEmpty ? user.firstName : 'Guest'}',
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 50),
                ],

                // ── Menu items ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      MenuItem(
                        title: 'Consent Preferences',
                        onPress: () => context.push(AppRoutes.consentPreferences),
                      ),
                      MenuItem(
                        title: 'Privacy Policy',
                        onPress: () => context.push(AppRoutes.privacyPolicy),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Logout button ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () => context.read<AuthCubit>().logout(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.generalBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(0, 4),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('LOGOUT',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
