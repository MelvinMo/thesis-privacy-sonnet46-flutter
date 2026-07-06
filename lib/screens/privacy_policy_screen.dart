// MIGRATION: app/privacy-policy.tsx → Dart StatefulWidget.
//            privacyPolicyData.json loaded via rootBundle (imported at compile time in RN,
//            loaded async here — same data, same content).
//            measureLayout + scrollTo → GlobalKey + Scrollable.ensureVisible.
//            OnboardingHeader → AppBar with back button.
//            Styles mirror RN exactly: headingLevel1=22/bold/generalBlue,
//            headingLevel2=18/600/generalBlue, headingLevel3=16/500/generalBlue,
//            subHeading=#ADD8E6/15/bold, bodyText=white/16, descriptionText=white/15/italic,
//            dataPoint=#ADD8E6/14, listItemText=white/15, metadataText=#BBBBBB/12.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final String? sectionId;
  const PrivacyPolicyScreen({super.key, this.sectionId});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _keys = {};
  late Future<Map<String, dynamic>> _future;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final raw = await rootBundle.loadString('assets/privacyPolicyData.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data['privacyPolicy'] as Map<String, dynamic>;
  }

  GlobalKey _key(String id) =>
      _keys.putIfAbsent(id, () => GlobalKey());

  void _scrollTo(String id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: AppColors.generalBlue)),
          );
        }
        // Scroll to sectionId once after the first frame is drawn.
        if (!_initialScrollDone && widget.sectionId != null) {
          _initialScrollDone = true;
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollTo(widget.sectionId!));
        }
        return _buildScreen(snap.data!);
      },
    );
  }

  Widget _buildScreen(Map<String, dynamic> policy) {
    final meta = policy['metadata'] as Map<String, dynamic>;
    final toc = (policy['tableOfContents'] as List).cast<String>();
    final s = policy['sections'] as Map<String, dynamic>;

    // Map TOC titles → section keys (mirrors tocToSectionKeyMap in RN).
    const tocMap = {
      'Interpretation and Definitions': 'interpretationsAndDefinitions',
      'Types of Information Collected and How We Use it': 'dataCollection',
      'Cloud vs. Local Data Storage & Processing': 'cloudVsLocalStorage',
      'Data Encryption and Pseudonymization': 'dataEncryptionAndPsuedonymization',
      'How We share Your information': 'dataSharing',
      'Retention of Your information': 'dataRetention',
      'Your Rights under PIPEDA': 'userRights',
      'Data Breach Notification': 'dataBreachNotification',
      'Changes to the Privacy Policy': 'policyChanges',
      'Contact Us': 'contact',
    };

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Privacy Policy',
            style: TextStyle(fontFamily: 'SpaceMono', fontSize: 15)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metadata line — outside scroll view, matches RN layout.
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Version: ${meta['version']} | Effective Date: ${meta['effectiveDate']} | Last Updated: ${meta['lastUpdated']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Table of Contents ────────────────────────────────────
                  _TocBlock(
                    toc: toc,
                    tocMap: tocMap,
                    onTap: _scrollTo,
                  ),

                  // ── Introduction ─────────────────────────────────────────
                  _Section(
                    id: 'introduction',
                    sectionKey: _key('introduction'),
                    children: [
                      _body(s['introduction']['content'] as String),
                    ],
                  ),

                  // ── Interpretations and Definitions ──────────────────────
                  _Section(
                    id: 'interpretationsAndDefinitions',
                    sectionKey: _key('interpretationsAndDefinitions'),
                    children: [
                      _h1('Interpretation and Definitions'),
                      ..._definitions(s['interpretationsAndDefinitions']['content'] as Map<String, dynamic>),
                    ],
                  ),

                  // ── Types of Information Collected ───────────────────────
                  _Section(
                    id: 'dataCollection',
                    sectionKey: _key('dataCollection'),
                    children: [
                      _h1(s['dataCollection']['title'] as String),
                      _body(s['dataCollection']['content'] as String),

                      // Personal Information
                      _SubSection(
                        id: 'personalInformation',
                        sectionKey: _key('personalInformation'),
                        children: [
                          _h2(s['dataCollection']['personalInformation']['title'] as String),
                          _desc(s['dataCollection']['personalInformation']['description'] as String),
                          _h3('Account Information'),
                          _dp('Data Type', s['dataCollection']['personalInformation']['accountInformation']['dataType'] as String),
                          _dp('Purpose', s['dataCollection']['personalInformation']['accountInformation']['purpose'] as String),
                          _dp('Collection Method', s['dataCollection']['personalInformation']['accountInformation']['collectionMethod'] as String),
                          _dp('Storage', s['dataCollection']['personalInformation']['accountInformation']['storageLocationAndMethods'] as String),
                        ],
                      ),

                      // Personal Health Information
                      _SubSection(
                        id: 'personalHealthInformation',
                        sectionKey: _key('personalHealthInformation'),
                        children: [
                          _h2(s['dataCollection']['personalHealthInformation']['title'] as String),
                          _desc(s['dataCollection']['personalHealthInformation']['description'] as String),

                          // Sensor Data
                          _h3WithKey('Sensor Data', _key('sensorData')),
                          _subHeadingWithKey('Microphone:', _key('microphone')),
                          _dp('Data Type', s['dataCollection']['personalHealthInformation']['sensorData']['microphone']['dataType'] as String),
                          _dp('Purpose', s['dataCollection']['personalHealthInformation']['sensorData']['microphone']['purpose'] as String),
                          _dp('Collection Method', s['dataCollection']['personalHealthInformation']['sensorData']['microphone']['collectionMethod'] as String),

                          _subHeadingWithKey('Accelerometer:', _key('accelerometer')),
                          _dp('Data Type', s['dataCollection']['personalHealthInformation']['sensorData']['accelerometer']['dataType'] as String),
                          _dp('Purpose', s['dataCollection']['personalHealthInformation']['sensorData']['accelerometer']['purpose'] as String),
                          _dp('Collection Method', s['dataCollection']['personalHealthInformation']['sensorData']['accelerometer']['collectionMethod'] as String),

                          _subHeadingWithKey('Light Sensor:', _key('lightSensor')),
                          _dp('Data Type', s['dataCollection']['personalHealthInformation']['sensorData']['lightSensor']['dataType'] as String),
                          _dp('Purpose', s['dataCollection']['personalHealthInformation']['sensorData']['lightSensor']['purpose'] as String),
                          _dp('Collection Method', s['dataCollection']['personalHealthInformation']['sensorData']['lightSensor']['collectionMethod'] as String),

                          // Journal Data
                          _h3WithKey('Journal Data', _key('journalData')),
                          _dp('Data Type', s['dataCollection']['personalHealthInformation']['journalData']['dataType'] as String),
                          _dp('Purpose', s['dataCollection']['personalHealthInformation']['journalData']['purpose'] as String),
                          _dp('Collection Method', s['dataCollection']['personalHealthInformation']['journalData']['collectionMethod'] as String),

                          // Derived Data
                          _h3WithKey('Derived Data', _key('derivedData')),
                          _body(s['dataCollection']['personalHealthInformation']['derivedData']['content'] as String),
                        ],
                      ),

                      // Usage Data
                      _SubSection(
                        id: 'usageData',
                        sectionKey: _key('usageData'),
                        children: [
                          _h2(s['dataCollection']['usageData']['title'] as String),
                          _desc(s['dataCollection']['usageData']['description'] as String),
                          _h3('Technical Information'),
                          _dp('Data Type', s['dataCollection']['usageData']['technicalInformation']['dataType'] as String),
                          _dp('Purpose', s['dataCollection']['usageData']['technicalInformation']['purpose'] as String),
                          _dp('Collection Method', s['dataCollection']['usageData']['technicalInformation']['collectionMethod'] as String),
                          _dp('Storage Location', s['dataCollection']['usageData']['technicalInformation']['storageLocation'] as String),
                          _dp('Troubleshooting', s['dataCollection']['usageData']['technicalInformation']['troubleshooting'] as String),
                          _dp('General Analytics', s['dataCollection']['usageData']['technicalInformation']['generalAnalytics'] as String),
                        ],
                      ),
                    ],
                  ),

                  // ── Cloud vs. Local Storage ──────────────────────────────
                  _Section(
                    id: 'cloudVsLocalStorage',
                    sectionKey: _key('cloudVsLocalStorage'),
                    children: [
                      _h1(s['cloudVsLocalStorage']['title'] as String),
                      _body(s['cloudVsLocalStorage']['content'] as String),
                      _SubSection(
                        id: 'cloudStorage',
                        sectionKey: _key('cloudStorage'),
                        children: [
                          _h2(s['cloudVsLocalStorage']['cloudStorage']['title'] as String),
                          _desc(s['cloudVsLocalStorage']['cloudStorage']['description'] as String),
                          _dp('Benefits', s['cloudVsLocalStorage']['cloudStorage']['benefits'] as String),
                          _dp('Data Location', s['cloudVsLocalStorage']['cloudStorage']['dataLocation'] as String),
                          _dp('Accountability', s['cloudVsLocalStorage']['cloudStorage']['accountability'] as String),
                        ],
                      ),
                      _SubSection(
                        id: 'localStorage',
                        sectionKey: _key('localStorage'),
                        children: [
                          _h2(s['cloudVsLocalStorage']['localStorage']['title'] as String),
                          _desc(s['cloudVsLocalStorage']['localStorage']['description'] as String),
                          _dp('Limitations', s['cloudVsLocalStorage']['localStorage']['limitations'] as String),
                          _dp('Responsibility', s['cloudVsLocalStorage']['localStorage']['responsibility'] as String),
                          _dp('Consent', s['cloudVsLocalStorage']['localStorage']['consent'] as String),
                        ],
                      ),
                    ],
                  ),

                  // ── Data Encryption and Pseudonymization ─────────────────
                  _Section(
                    id: 'dataEncryptionAndPsuedonymization',
                    sectionKey: _key('dataEncryptionAndPsuedonymization'),
                    children: [
                      _h1(s['dataEncryptionAndPsuedonymization']['title'] as String),
                      _desc(s['dataEncryptionAndPsuedonymization']['description'] as String),
                      _SubSection(
                        id: 'encryption',
                        sectionKey: _key('encryption'),
                        children: [
                          _h2('Encryption'),
                          _subHeading('At Rest:'),
                          _dp('Server Data', s['dataEncryptionAndPsuedonymization']['encryption']['atRest']['serverData'] as String),
                          _dp('Local Data', s['dataEncryptionAndPsuedonymization']['encryption']['atRest']['localData'] as String),
                          _subHeading('In Transit:'),
                          _dataValue(s['dataEncryptionAndPsuedonymization']['encryption']['inTransit'] as String),
                        ],
                      ),
                      _SubSection(
                        id: 'pseudonymization',
                        sectionKey: _key('pseudonymization'),
                        children: [
                          _h2('Pseudonymization'),
                          _desc(s['dataEncryptionAndPsuedonymization']['pseudonymization']['description'] as String),
                          _dp('Purpose', s['dataEncryptionAndPsuedonymization']['pseudonymization']['purpose'] as String),
                        ],
                      ),
                    ],
                  ),

                  // ── How We Share Your Information ────────────────────────
                  _Section(
                    id: 'dataSharing',
                    sectionKey: _key('dataSharing'),
                    children: [
                      _h1(s['dataSharing']['title'] as String),
                      _desc(s['dataSharing']['description'] as String),
                      _SubSection(
                        id: 'dataSharingGoogleCloud',
                        sectionKey: _key('dataSharingGoogleCloud'),
                        children: [
                          _h2(s['dataSharing']['googleCloud']['title'] as String),
                          _desc(s['dataSharing']['googleCloud']['description'] as String),
                        ],
                      ),
                      _SubSection(
                        id: 'dataSharingLegal',
                        sectionKey: _key('dataSharingLegal'),
                        children: [
                          _h2(s['dataSharing']['legal']['title'] as String),
                          _desc(s['dataSharing']['legal']['description'] as String),
                        ],
                      ),
                    ],
                  ),

                  // ── Retention of Your Information ────────────────────────
                  _Section(
                    id: 'dataRetention',
                    sectionKey: _key('dataRetention'),
                    children: [
                      _h1(s['dataRetention']['title'] as String),
                      _desc(s['dataRetention']['description'] as String),
                      _SubSection(
                        id: 'retentionAccountInfo',
                        sectionKey: _key('retentionAccountInfo'),
                        children: [
                          _h2('Account Information'),
                          _desc(s['dataRetention']['accountInformation']['description'] as String),
                          _dp('Data Type', s['dataRetention']['accountInformation']['dataType'] as String),
                        ],
                      ),
                      _SubSection(
                        id: 'retentionPHI',
                        sectionKey: _key('retentionPHI'),
                        children: [
                          _h2('Personal Health Information'),
                          _dp('Cloud Stored', s['dataRetention']['personalHealthInformation']['cloudStored'] as String),
                          _dp('User Initiated Deletion', s['dataRetention']['personalHealthInformation']['userInitiated'] as String),
                          _dp('Local Stored', s['dataRetention']['personalHealthInformation']['localStored'] as String),
                          _dp('Data Type', s['dataRetention']['personalHealthInformation']['dataType'] as String),
                        ],
                      ),
                      _SubSection(
                        id: 'retentionUsageData',
                        sectionKey: _key('retentionUsageData'),
                        children: [
                          _h2('Usage Data'),
                          _dp('Pseudonymized', s['dataRetention']['usageData']['pseudonymized'] as String),
                          _dp('Anonymized', s['dataRetention']['usageData']['anonymized'] as String),
                        ],
                      ),
                    ],
                  ),

                  // ── Your Rights under PIPEDA ─────────────────────────────
                  _Section(
                    id: 'userRights',
                    sectionKey: _key('userRights'),
                    children: [
                      _h1(s['userRights']['title'] as String),
                      _desc(s['userRights']['description'] as String),
                      _SubSection(
                        id: 'userRightsDetails',
                        sectionKey: _key('userRightsDetails'),
                        children: [
                          _h2(s['userRights']['access']['title'] as String),
                          _body(s['userRights']['access']['description'] as String),
                          _h2(s['userRights']['correction']['title'] as String),
                          _body(s['userRights']['correction']['description'] as String),
                          _h2(s['userRights']['withdrawConsent']['title'] as String),
                          _body(s['userRights']['withdrawConsent']['description'] as String),
                          _h2(s['userRights']['accountability']['title'] as String),
                          _body(s['userRights']['accountability']['description'] as String),
                          _h2(s['userRights']['challengeCompliance']['title'] as String),
                          _body(s['userRights']['challengeCompliance']['description'] as String),
                          _body(s['userRights']['exerciseRights'] as String),
                        ],
                      ),
                    ],
                  ),

                  // ── Data Breach Notification ─────────────────────────────
                  _Section(
                    id: 'dataBreachNotification',
                    sectionKey: _key('dataBreachNotification'),
                    children: [
                      _h1(s['dataBreachNotification']['title'] as String),
                      _desc(s['dataBreachNotification']['description'] as String),
                      _SubSection(
                        id: 'breachDetails',
                        sectionKey: _key('breachDetails'),
                        children: [
                          _h2(s['dataBreachNotification']['riskAssessment']['title'] as String),
                          _body(s['dataBreachNotification']['riskAssessment']['description'] as String),
                          _h2(s['dataBreachNotification']['notificationOPC']['title'] as String),
                          _body(s['dataBreachNotification']['notificationOPC']['description'] as String),
                          _h2(s['dataBreachNotification']['notificationIndividuals']['title'] as String),
                          _body(s['dataBreachNotification']['notificationIndividuals']['description'] as String),
                          ...(s['dataBreachNotification']['notificationIndividuals']['content'] as List)
                              .cast<String>()
                              .map((item) => _listItem(item)),
                          _h2(s['dataBreachNotification']['notificationOtherOrganizations']['title'] as String),
                          _body(s['dataBreachNotification']['notificationOtherOrganizations']['description'] as String),
                          _h2(s['dataBreachNotification']['recordKeeping']['title'] as String),
                          _body(s['dataBreachNotification']['recordKeeping']['description'] as String),
                        ],
                      ),
                    ],
                  ),

                  // ── Changes to the Privacy Policy ────────────────────────
                  _Section(
                    id: 'policyChanges',
                    sectionKey: _key('policyChanges'),
                    children: [
                      _h1('Changes to the Privacy Policy'),
                      _body(s['policyChanges']['content'] as String),
                    ],
                  ),

                  // ── Contact Us ───────────────────────────────────────────
                  _Section(
                    id: 'contact',
                    sectionKey: _key('contact'),
                    children: [
                      _h1(s['contact']['title'] as String),
                      _desc(s['contact']['description'] as String),
                      _dp('Email', s['contact']['email'] as String),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout helpers — mirrors RN StyleSheet values exactly
// ─────────────────────────────────────────────────────────────────────────────

// headingLevel1: fontSize 22, bold, generalBlue
Widget _h1(String text) => Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.generalBlue)),
    );

// headingLevel2: fontSize 18, weight 600, generalBlue, indent 5
Widget _h2(String text) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8, left: 5),
      child: Text(text,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.generalBlue)),
    );

// headingLevel3: fontSize 16, weight 500, generalBlue, indent 10
Widget _h3(String text) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 5, left: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.generalBlue)),
    );

// headingLevel3 with GlobalKey for scroll-to navigation
Widget _h3WithKey(String text, GlobalKey key) => Padding(
      key: key,
      padding: const EdgeInsets.only(top: 8, bottom: 5, left: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.generalBlue)),
    );

// subHeading: fontSize 15, bold, #ADD8E6, indent 15
Widget _subHeading(String text) => Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 3, left: 15),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFADD8E6))),
    );

Widget _subHeadingWithKey(String text, GlobalKey key) => Padding(
      key: key,
      padding: const EdgeInsets.only(top: 5, bottom: 3, left: 15),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFADD8E6))),
    );

// bodyText: fontSize 16, lineHeight 24, white
Widget _body(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 16, height: 1.5, color: Colors.white)),
    );

// descriptionText: fontSize 15, lineHeight 22, white, italic
Widget _desc(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              height: 22 / 15,
              color: Colors.white,
              fontStyle: FontStyle.italic)),
    );

// dataPoint: label in #ADD8E6, value in white, indent 15
Widget _dp(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 15),
      child: Text.rich(
        TextSpan(
          text: '• $label: ',
          style: const TextStyle(fontSize: 14, color: Color(0xFFADD8E6)),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );

// dataPointValue standalone (used for inTransit line)
Widget _dataValue(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 15),
      child: Text(text,
          style: const TextStyle(fontSize: 14, color: Colors.white)),
    );

// listItemText: fontSize 15, white, indent 25
Widget _listItem(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 25),
      child: Text('- $text',
          style: const TextStyle(fontSize: 15, color: Colors.white)),
    );

List<Widget> _definitions(Map<String, dynamic> content) => [
      _DefItem('You', content['you'] as String),
      _DefItem('Company', content['company'] as String),
      _DefItem('App', content['app'] as String),
      _DefItem('Personal Information', content['personalInformation'] as String),
      _DefItem('Personal Health Information', content['personalHealthInformation'] as String),
    ];

// ─────────────────────────────────────────────────────────────────────────────
// Section wrapper — bottom border + spacing, carries GlobalKey for scroll-to
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String id;
  final GlobalKey sectionKey;
  final List<Widget> children;
  const _Section(
      {required this.id,
      required this.sectionKey,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFF555555), width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// Sub-section: indented 10 from left, top margin 10 — mirrors subSectionContainer
class _SubSection extends StatelessWidget {
  final String id;
  final GlobalKey sectionKey;
  final List<Widget> children;
  const _SubSection(
      {required this.id,
      required this.sectionKey,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      margin: const EdgeInsets.only(left: 10, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table of Contents block
// ─────────────────────────────────────────────────────────────────────────────

class _TocBlock extends StatelessWidget {
  final List<String> toc;
  final Map<String, String> tocMap;
  final void Function(String id) onTap;
  const _TocBlock(
      {required this.toc, required this.tocMap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFF333333), width: 1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Table of Contents',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          for (final title in toc)
            if (tocMap[title] != null)
              GestureDetector(
                onTap: () => onTap(tocMap[title]!),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 5, 4),
                  child: Text('• $title',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.generalBlue)),
                ),
              ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Definition item — term bold white, value normal white (mirrors definitionItem)
// ─────────────────────────────────────────────────────────────────────────────

class _DefItem extends StatelessWidget {
  final String term;
  final String value;
  const _DefItem(this.term, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$term:',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 2),
            child: Text(value,
                style: const TextStyle(fontSize: 15, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
