// MIGRATION: components/transparency/PrivacyTooltip.tsx → Dart.
//
//            Key translation challenges:
//
//            1. react-native-walkthrough-tooltip → Flutter custom Overlay-based tooltip.
//               No direct Flutter equivalent; we use CompositedTransformTarget /
//               CompositedTransformFollower with an OverlayEntry.
//
//            2. SMART POSITIONING (Rule 14):
//               Source: iconRef.current.measure() → pageY → compare to screenHeight/2.
//               Flutter: RenderBox.localToGlobal() gives the widget's global position.
//               If globalY > screenHeight/2 → show tooltip ABOVE the icon.
//               If globalY <= screenHeight/2 → show tooltip BELOW the icon.
//
//            3. ScrollView in tooltip → SingleChildScrollView.
//
//            4. expo-router useRouter → go_router context.go() / context.push().

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/transparency.dart';
import '../../core/utils/transparency_utils.dart';
import 'privacy_icon.dart';
import 'sensor_privacy_icon.dart';

class PrivacyTooltip extends StatefulWidget {
  final Color color;
  final double iconSize;
  final String iconName;
  final String violationsDetected;
  final String? privacyViolations;
  final String purpose;
  final String storage;
  final String access;
  final String? optOutLink;
  final String? privacyPolicySectionLink;
  final String? regulationLink;
  // MIGRATION: `dataType` encodes both the type category and storage location.
  //            Format: 'sensor-<type>-<storage>' or 'journal', 'statistics' etc.
  final String dataType;

  const PrivacyTooltip({
    super.key,
    required this.color,
    this.iconSize = 40,
    required this.iconName,
    required this.violationsDetected,
    this.privacyViolations,
    required this.purpose,
    required this.storage,
    required this.access,
    this.optOutLink,
    this.privacyPolicySectionLink,
    this.regulationLink,
    required this.dataType,
  });

  @override
  State<PrivacyTooltip> createState() => _PrivacyTooltipState();
}

class _PrivacyTooltipState extends State<PrivacyTooltip> {
  bool _showTooltip = false;
  OverlayEntry? _overlayEntry;

  // MIGRATION: iconRef (React ref) → GlobalKey to access RenderBox.
  final _iconKey = GlobalKey();

  // MIGRATION: React `Dimensions.get('window')` → MediaQuery.sizeOf(context).
  // Cached at press time to avoid MediaQuery dependency in overlay.
  double _screenHeight = 0;
  double _screenWidth = 0;

  // ---------------------------------------------------------------------------
  // Smart positioning (Rule 14)
  // MIGRATION: iconRef.current.measure(pageY) → RenderBox.localToGlobal(Offset.zero).
  // ---------------------------------------------------------------------------
  void _handleIconPress() {
    final box = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = MediaQuery.sizeOf(context);
    _screenHeight = size.height;
    _screenWidth = size.width;

    final globalPos = box.localToGlobal(Offset.zero);
    final pageY = globalPos.dy;
    final pageX = globalPos.dx;
    final iconW = box.size.width;
    final iconH = box.size.height;

    // Rule 14: if pageY > screenHeight/2 → show ABOVE icon, else BELOW.
    final showAbove = pageY > _screenHeight / 2;

    setState(() => _showTooltip = true);
    _overlayEntry = _buildOverlay(
      pageX: pageX,
      pageY: pageY,
      iconW: iconW,
      iconH: iconH,
      showAbove: showAbove,
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _showTooltip = false);
  }

  // ---------------------------------------------------------------------------
  // Build the overlay entry (replaces react-native-walkthrough-tooltip).
  // ---------------------------------------------------------------------------
  OverlayEntry _buildOverlay({
    required double pageX,
    required double pageY,
    required double iconW,
    required double iconH,
    required bool showAbove,
  }) {
    final tooltipW = _screenWidth * 0.8;
    const maxH = 400.0;
    const arrowH = 8.0;
    const arrowW = 16.0;
    final gap = 6.0;

    // Center the tooltip horizontally on the icon, clamped to screen edges.
    double left = pageX + iconW / 2 - tooltipW / 2;
    left = left.clamp(8.0, _screenWidth - tooltipW - 8);

    // Position above or below the icon.
    final double top = showAbove
        ? pageY - maxH - arrowH - gap
        : pageY + iconH + arrowH + gap;

    // Arrow horizontal offset (points to icon center).
    final double arrowLeft =
        (pageX + iconW / 2 - left - arrowW / 2).clamp(8.0, tooltipW - arrowW - 8);

    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeTooltip,
        child: Stack(
          children: [
            // Dimmed background tap-to-close.
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // Tooltip card.
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arrow (pointing toward the icon).
                    if (!showAbove)
                      Padding(
                        padding: EdgeInsets.only(left: arrowLeft),
                        child: _Arrow(
                            color: widget.color, pointUp: true, size: arrowW),
                      ),
                    // Content box.
                    Container(
                      width: tooltipW,
                      constraints:
                          const BoxConstraints(maxHeight: maxH),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // MIGRATION: ScrollView → SingleChildScrollView.
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _TooltipContent(
                            violationsDetected: widget.violationsDetected,
                            privacyViolations: widget.privacyViolations,
                            purpose: widget.purpose,
                            storage: widget.storage,
                            access: widget.access,
                            privacyPolicySectionLink:
                                widget.privacyPolicySectionLink,
                            regulationLink: widget.regulationLink,
                            optOutLink: widget.optOutLink,
                            onClose: _closeTooltip,
                            context: context,
                          ),
                        ),
                      ),
                    ),
                    if (showAbove)
                      Padding(
                        padding: EdgeInsets.only(left: arrowLeft),
                        child: _Arrow(
                            color: widget.color, pointUp: false, size: arrowW),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MIGRATION: react-native-walkthrough-tooltip wraps the icon child.
    //            Flutter: wrap with a KeyedSubtree to measure position.
    final isSensor = widget.dataType.contains('sensor');
    final isCloud = widget.dataType.contains('cloud');
    final sensorType = isSensor ? widget.dataType.split('-')[1] : '';

    return KeyedSubtree(
      key: _iconKey,
      child: isSensor
          ? SensorPrivacyIcon(
              sensorType: sensorType,
              iconName: widget.iconName,
              storageType: isCloud ? 'cloud' : 'local',
              handleIconPress: _handleIconPress,
            )
          : PrivacyIcon(
              handleIconPress: _handleIconPress,
              isOpen: _showTooltip,
              iconName: widget.iconName,
              iconSize: widget.iconSize,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tooltip content widget (mirrors renderTooltipContent() in source).
// ---------------------------------------------------------------------------
class _TooltipContent extends StatelessWidget {
  final String violationsDetected;
  final String? privacyViolations;
  final String purpose;
  final String storage;
  final String access;
  final String? privacyPolicySectionLink;
  final String? regulationLink;
  final String? optOutLink;
  final VoidCallback onClose;
  final BuildContext context;

  const _TooltipContent({
    required this.violationsDetected,
    this.privacyViolations,
    required this.purpose,
    required this.storage,
    required this.access,
    this.privacyPolicySectionLink,
    this.regulationLink,
    this.optOutLink,
    required this.onClose,
    required this.context,
  });

  bool get _isLowRisk =>
      violationsDetected == getPrivacyRiskLabel(PrivacyRisk.low);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Privacy violations section.
        _Section(
          title: violationsDetected,
          body: _isLowRisk ? null : privacyViolations,
        ),
        // Purpose.
        const _Section(title: 'Purpose:'),
        _BodyText(purpose),
        const SizedBox(height: 8),
        // Storage + Access (only when no violations).
        if (_isLowRisk) ...[
          const _Section(title: 'Storage:'),
          _BodyText(storage),
          const SizedBox(height: 8),
          const _Section(title: 'Access:'),
          _BodyText(access),
          const SizedBox(height: 8),
        ],
        // Links section.
        if (privacyPolicySectionLink != null ||
            regulationLink != null ||
            optOutLink != null) ...[
          const Divider(color: Color(0x44FFFFFF)),
          if (privacyPolicySectionLink != null)
            _LinkButton(
              label: 'Link to privacy policy section',
              onTap: () {
                onClose();
                context.push(
                  '${AppRoutes.privacyPolicy}?sectionId=$privacyPolicySectionLink',
                );
              },
            ),
          if (regulationLink != null)
            _LinkButton(
              label: 'PIPEDA regulation',
              onTap: () => handleLinkPress(regulationLink),
            ),
          if (optOutLink != null)
            _LinkButton(
              label: 'Opt Out',
              onTap: () {
                onClose();
                context.push(optOutLink!);
              },
            ),
          _LinkButton(
            label: 'View Full Privacy Policy',
            onTap: () {
              onClose();
              context.push(AppRoutes.privacyPolicy);
            },
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  const _Section({required this.title, this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            )),
        if (body != null) ...[
          const SizedBox(height: 2),
          _BodyText(body!),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 12,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            color: AppColors.tooltipLinkBlue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arrow widget (replaces tooltip arrow styling in source).
// ---------------------------------------------------------------------------
class _Arrow extends StatelessWidget {
  final Color color;
  final bool pointUp;
  final double size;
  const _Arrow({required this.color, required this.pointUp, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size / 2),
      painter: _ArrowPainter(color: color, pointUp: pointUp),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointUp;
  const _ArrowPainter({required this.color, required this.pointUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.pointUp != pointUp;
}
