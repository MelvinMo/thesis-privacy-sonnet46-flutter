// MIGRATION: components/transparency/PrivacySleepPage.tsx,
//                                        PrivacyJournalPage.tsx,
//                                        PrivacySleepMode.tsx,
//                                        PrivacyStatisticsPage.tsx
//            → consolidated Dart file (all are static info display widgets).

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Shared privacy info card.
// ---------------------------------------------------------------------------
class PrivacyInfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const PrivacyInfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.generalBlue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    )),
                const SizedBox(height: 6),
                Text(description,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PrivacySleepPage
// MIGRATION: components/transparency/PrivacySleepPage.tsx → StatelessWidget.
// ---------------------------------------------------------------------------
class PrivacySleepPage extends StatelessWidget {
  const PrivacySleepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionHeader(title: 'Sleep Data Privacy'),
          PrivacyInfoCard(
            icon: Icons.lock,
            title: 'Encrypted Storage',
            description:
                'Your bedtime, alarm, and sleep duration are encrypted using AES-256 before being stored on this device.',
          ),
          PrivacyInfoCard(
            icon: Icons.person,
            title: 'You Are In Control',
            description:
                'Your sleep data is only accessible to you. You can delete it at any time from the Profile screen.',
          ),
          PrivacyInfoCard(
            icon: Icons.policy,
            title: 'PIPEDA Compliant',
            description:
                'Data collection and storage comply with PIPEDA principles of accountability, consent, and limiting collection.',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PrivacyJournalPage
// ---------------------------------------------------------------------------
class PrivacyJournalPage extends StatelessWidget {
  const PrivacyJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          _SectionHeader(title: 'Journal Data Privacy'),
          PrivacyInfoCard(
            icon: Icons.edit_note,
            title: 'Your Diary Stays Private',
            description:
                'Journal entries and sleep notes are encrypted and stored locally on your device.',
          ),
          PrivacyInfoCard(
            icon: Icons.cloud_off,
            title: 'Optional Cloud Sync',
            description:
                'Cloud storage is opt-in. If disabled, your journal never leaves your device.',
          ),
          PrivacyInfoCard(
            icon: Icons.security,
            title: 'AES-256 Encryption',
            description:
                'All sensitive fields (diary text, sleep notes, timings) are encrypted before storage.',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PrivacySleepMode
// ---------------------------------------------------------------------------
class PrivacySleepMode extends StatelessWidget {
  const PrivacySleepMode({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          _SectionHeader(title: 'Active Sensor Collection'),
          PrivacyInfoCard(
            icon: Icons.mic,
            title: 'Microphone',
            description:
                'Recording ambient audio to detect snoring and sleep disturbances. Audio clips are not saved unless enabled.',
          ),
          PrivacyInfoCard(
            icon: Icons.light_mode,
            title: 'Light Sensor',
            description:
                'Measuring ambient light levels to understand your sleep environment.',
          ),
          PrivacyInfoCard(
            icon: Icons.speed,
            title: 'Accelerometer',
            description:
                'Tracking movement to analyse sleep stages and quality.',
          ),
          PrivacyInfoCard(
            icon: Icons.lock_outline,
            title: 'Data Protection',
            description:
                'All sensor data is encrypted before storage. You can disable any sensor in Consent Preferences.',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PrivacyStatisticsPage
// ---------------------------------------------------------------------------
class PrivacyStatisticsPage extends StatelessWidget {
  const PrivacyStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          _SectionHeader(title: 'Statistics Data Privacy'),
          PrivacyInfoCard(
            icon: Icons.bar_chart,
            title: 'Derived Data Only',
            description:
                'Statistics are computed from your own sensor and journal data. No raw audio or movement data is sent.',
          ),
          PrivacyInfoCard(
            icon: Icons.no_accounts,
            title: 'No Third-Party Sharing',
            description:
                'Your sleep statistics are never shared with third parties or advertisers.',
          ),
          PrivacyInfoCard(
            icon: Icons.delete_forever,
            title: 'Your Right to Delete',
            description:
                'You can delete all your data at any time from the Profile screen.',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
