// MIGRATION: app/(tabs)/_layout.tsx (bottom tabs with @react-navigation/bottom-tabs)
//            → go_router ShellRoute + BottomNavigationBar.
//            Tab icons and labels preserved: Sleep, Journal, Statistics, Profile.
//            Active/inactive colours from AppColors (Rule 2).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../core/constants/app_colors.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/tabs/sleep')) return 0;
    if (location.startsWith('/tabs/journal')) return 1;
    if (location.startsWith('/tabs/statistics')) return 2;
    if (location.startsWith('/tabs/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      // MIGRATION: @react-navigation/bottom-tabs → BottomNavigationBar.
      //            tabBarActiveTintColor → AppColors.tabBarActive.
      //            tabBarInactiveTintColor → AppColors.tabBarInactive.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.tabBarBackground,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: AppColors.tabBarBackground,
          selectedItemColor: AppColors.tabBarActive,
          unselectedItemColor: AppColors.tabBarInactive,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'SpaceMono', fontSize: 10),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'SpaceMono', fontSize: 10),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go(AppRoutes.sleep);
              case 1:
                context.go(AppRoutes.journal);
              case 2:
                context.go(AppRoutes.statistics);
              case 3:
                context.go(AppRoutes.profile);
            }
          },
          // MIGRATION: Ionicons moon-outline/document-text-outline/bar-chart-outline/person-outline
          //            → closest Material equivalents.
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.nightlight_outlined),
              activeIcon: Icon(Icons.nightlight_round),
              label: 'Sleep',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Statistics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
