// MIGRATION: app/(tabs)/statistics.tsx → Dart StatefulWidget.
//            Two tabs: Daily (DailyStatisticsPage) and Statistics (4 graph cards).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app.dart';
import '../../blocs/transparency/transparency_bloc.dart';
import '../../blocs/transparency/transparency_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/transparency_config.dart';
import '../../core/utils/transparency_utils.dart';
import '../../widgets/transparency/privacy_icon.dart';
import '../../widgets/transparency/privacy_tooltip.dart';
import '../../widgets/transparency/privacy_page_components.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _activeTab = 0; // 0 = Daily, 1 = Stats
  bool _displayNormalUI = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransparencyBloc, TransparencyState>(
      builder: (ctx, ts) {
        final statsT = ts.statisticsTransparency;
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header with background overlay ────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xCC000A14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Tab row + privacy icon
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 70, 0),
                            child: Row(
                              children: [
                                _TabButton(
                                  label: 'Daily',
                                  active: _activeTab == 0,
                                  onTap: () => setState(() => _activeTab = 0),
                                ),
                                const SizedBox(width: 10),
                                _TabButton(
                                  label: 'Statistics',
                                  active: _activeTab == 1,
                                  onTap: () => setState(() => _activeTab = 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    // ── Tab content ───────────────────────────────────────
                    Expanded(
                      child: _displayNormalUI
                          ? (_activeTab == 0
                              ? const _DailyTab()
                              : const _StatsTab())
                          : const PrivacyStatisticsPage(),
                    ),
                  ],
                ),
                // ── Transparency button ───────────────────────────────────
                Positioned(
                  top: 16, right: 16,
                  child: TransparencyConfig.sleepPageTooltipEnabled
                      ? PrivacyTooltip(
                          color: getPrivacyRiskColor(statsT.privacyRisk),
                          iconName: getPrivacyRiskIcon(statsT.privacyRisk),
                          violationsDetected:
                              getPrivacyRiskLabel(statsT.privacyRisk),
                          privacyViolations: formatPrivacyViolations(statsT),
                          purpose: statsT.aiExplanation?.why ?? '',
                          storage: statsT.aiExplanation?.storage ?? '',
                          access: statsT.aiExplanation?.access ?? '',
                          optOutLink: AppRoutes.consentPreferences,
                          privacyPolicySectionLink:
                              statsT.aiExplanation?.privacyPolicyLink.firstOrNull,
                          regulationLink:
                              statsT.aiExplanation?.regulationLink.firstOrNull,
                          dataType: 'statistics',
                        )
                      : PrivacyIcon(
                          handleIconPress: () =>
                              setState(() => _displayNormalUI = !_displayNormalUI),
                          isOpen: !_displayNormalUI,
                          iconName: getPrivacyRiskIcon(statsT.privacyRisk),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab button
// ─────────────────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.generalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 18,
              color: active ? Colors.white : const Color(0xFFBBBBBB),
              fontWeight: FontWeight.w500,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily tab — mirrors DailyStatisticsPage.tsx
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTab extends StatefulWidget {
  const _DailyTab();

  @override
  State<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<_DailyTab> {
  String _clipTab = 'snoring'; // 'snoring' | 'talking'

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ── Sleep Quality ───────────────────────────────────────────────
          _sectionTitle('Sleep Quality'),
          _sectionCard(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/images/sleep-quality-daily.png',
                    width: 100, height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time in Bed',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
                      const SizedBox(height: 2),
                      const Text('10:14 PM - 6:44 AM',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      const Text('8h 30m',
                          style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('Pretty Good!',
                          style: TextStyle(
                              color: AppColors.generalBlue,
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sleep Stages image ──────────────────────────────────────────
          _sectionTitle('Sleep Stages'),
          _imageCard('assets/images/sleep-stages-daily.png'),

          // ── Sleep Stage Breakdown grid ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StageItem(
                  color: const Color(0xFF4A4A4A),
                  icon: Icons.nightlight_round,
                  label: 'Deep Sleep',
                  pct: '21%',
                  dur: '2h 25m',
                ),
                _StageItem(
                  color: const Color(0xFF6A9EFF),
                  icon: Icons.nightlight_outlined,
                  label: 'Light Sleep',
                  pct: '56%',
                  dur: '4h 35m',
                ),
                _StageItem(
                  color: const Color(0xFF8A6AFF),
                  icon: Icons.remove_red_eye,
                  label: 'REM',
                  pct: '17%',
                  dur: '1h 25m',
                ),
                _StageItem(
                  color: const Color(0xFFFFA64A),
                  icon: Icons.remove_red_eye_outlined,
                  label: 'Awake',
                  pct: '6%',
                  dur: '30m',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Sleep Insights grid ─────────────────────────────────────────
          Row(
            children: [
              _insightCard(
                icon: Icons.bed_outlined,
                iconColor: const Color(0xFF4A9EFF),
                label: 'In Bed',
                value: '8h 30 min',
              ),
              const SizedBox(width: 8),
              _insightCard(
                icon: Icons.nightlight_outlined,
                iconColor: const Color(0xFF8A6AFF),
                label: 'Asleep',
                value: '7h 34 min',
              ),
              const SizedBox(width: 8),
              _insightCard(
                icon: Icons.access_time_outlined,
                iconColor: const Color(0xFF6A9EFF),
                label: 'Asleep After',
                value: '11 min',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _insightCard(
                icon: Icons.volume_up_outlined,
                iconColor: const Color(0xFFFFA64A),
                label: 'Noise',
                value: '39 dB',
              ),
              const SizedBox(width: 8),
              _insightCard(
                icon: Icons.volume_mute_outlined,
                iconColor: const Color(0xFFFF6B6B),
                label: 'Snoring',
                value: '1h 30 min',
              ),
              const SizedBox(width: 8),
              // spacer to keep symmetry
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 20),

          // ── Sleep Clips ─────────────────────────────────────────────────
          _sectionTitle('Sleep Clips'),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Snoring / Talking tabs
                Row(
                  children: [
                    _ClipTabButton(
                      label: 'Snoring',
                      active: _clipTab == 'snoring',
                      onTap: () => setState(() => _clipTab = 'snoring'),
                    ),
                    const SizedBox(width: 10),
                    _ClipTabButton(
                      label: 'Talking',
                      active: _clipTab == 'talking',
                      onTap: () => setState(() => _clipTab = 'talking'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ClipItem(time: '11:04 PM'),
                const SizedBox(height: 12),
                _ClipItem(time: '11:04 PM'),
                const SizedBox(height: 12),
                _ClipItem(time: '11:04 PM'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 15),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
      );

  Widget _sectionCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  Widget _imageCard(String assetPath) => Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Image.asset(assetPath, width: double.infinity, height: 200, fit: BoxFit.contain),
      );

  Widget _insightCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFFBBBBBB), fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sleep stage item
// ─────────────────────────────────────────────────────────────────────────────

class _StageItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String pct;
  final String dur;
  const _StageItem(
      {required this.color,
      required this.icon,
      required this.label,
      required this.pct,
      required this.dur});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(pct,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        Text(dur,
            style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clip tab button
// ─────────────────────────────────────────────────────────────────────────────

class _ClipTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ClipTabButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.generalBlue : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : const Color(0xFFBBBBBB),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single clip item (play button + time + waveform + ellipsis)
// ─────────────────────────────────────────────────────────────────────────────

class _ClipItem extends StatelessWidget {
  final String time;
  const _ClipItem({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline, color: AppColors.generalBlue, size: 24),
          const SizedBox(width: 12),
          Text(time,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          // Waveform bars
          Expanded(
            child: SizedBox(
              height: 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  20,
                  (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: (i % 5 + 1) * 5.0,
                      decoration: BoxDecoration(
                        color: AppColors.generalBlue,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.more_horiz, color: Color(0xFF888888), size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats tab — 4 graph image cards, mirrors StatisticItem.tsx
// ─────────────────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 12),
          _GraphCard(label: 'Sleep Quality', assetPath: 'assets/images/sleep-quality-graph.png'),
          _GraphCard(label: 'Sleep Duration', assetPath: 'assets/images/sleep-duration-graph.png'),
          _GraphCard(label: 'Sleep Stages', assetPath: 'assets/images/sleep-duration-graph.png'),
          _GraphCard(label: 'Snore Time', assetPath: 'assets/images/sleep-quality-graph.png'),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GraphCard extends StatelessWidget {
  final String label;
  final String assetPath;
  const _GraphCard({required this.label, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Image.asset(
            assetPath,
            width: double.infinity, height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
