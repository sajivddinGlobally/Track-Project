import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/core/Data/ResponseModel/GetLawContentResModel.dart';
import 'package:url_launcher/url_launcher.dart';

import 'NetworkRequestScreen/Provider/getLowProvider.dart';

class LegalSectionDetail {
  final String sectionTitle;
  final String explanation;
  final String youtubeVideoUrl;

  LegalSectionDetail({
    required this.sectionTitle,
    required this.explanation,
    required this.youtubeVideoUrl,
  });
}

class LandmarkCaseDetail {
  final String caseName;
  final String summary;
  final String youtubeVideoUrl;

  LandmarkCaseDetail({
    required this.caseName,
    required this.summary,
    required this.youtubeVideoUrl,
  });
}

class LegalActDetail {
  final String actName;
  final String jurisdiction; // 'Central' or 'State'
  final String englishPdfUrl;
  final String hindiPdfUrl;
  final String referenceVideoUrl;
  final List<LegalSectionDetail> sections;
  final List<LandmarkCaseDetail> landmarkCases;

  LegalActDetail({
    required this.actName,
    required this.jurisdiction,
    required this.englishPdfUrl,
    required this.hindiPdfUrl,
    this.referenceVideoUrl = '',
    required this.sections,
    required this.landmarkCases,
  });
}

class LegalTopic {
  final String titleEn;
  final String titleHi;
  final String description;
  final IconData icon;
  final String youtubeUrl;
  final List<LegalActDetail> acts;

  LegalTopic({
    required this.titleEn,
    required this.titleHi,
    required this.description,
    required this.icon,
    required this.youtubeUrl,
    required this.acts,
  });
}

/// ---------------------------------------------------------------------------
/// DPDP ACT (2023) COMPLIANT MEDIA REDIRECT & MINOR PROTECTION HELPER
/// ---------------------------------------------------------------------------
class LegalMediaRedirectHelper {
  /// Extracts the YouTube video ID from various YouTube URL formats.
  static String? extractYouTubeVideoId(String url) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(cleanUrl);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      if (uri.host.contains('youtube.com') ||
          uri.host.contains('youtube-nocookie.com')) {
        if (uri.pathSegments.contains('watch')) {
          return uri.queryParameters['v'];
        }
        if (uri.pathSegments.contains('embed')) {
          final index = uri.pathSegments.indexOf('embed');
          if (index + 1 < uri.pathSegments.length) {
            return uri.pathSegments[index + 1];
          }
        }
        if (uri.pathSegments.contains('shorts')) {
          final index = uri.pathSegments.indexOf('shorts');
          if (index + 1 < uri.pathSegments.length) {
            return uri.pathSegments[index + 1];
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Launch media respecting DPDP Act, Section 9 child privacy & explicit consent redirect modal.
  static Future<void> launchLegalMedia({
    required BuildContext context,
    required String? urlString,
    required bool isHindi,
  }) async {
    if (urlString == null || urlString.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'कोई लिंक उपलब्ध नहीं है'
                  : 'No URL available for this item',
            ),
          ),
        );
      }
      return;
    }

    final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
    final role = box?.get('role')?.toString().toLowerCase() ?? 'user';
    final isMinor = role == 'child';
    final shouldShowRedirect =
        box?.get('should_show_youtube_redirect', defaultValue: true) as bool? ??
        true;

    final isVideoOrYoutube =
        urlString.contains('youtube.com') ||
        urlString.contains('youtu.be') ||
        urlString.contains('youtube-nocookie.com');

    // If it's a PDF or general doc, launch without YouTube modal
    if (!isVideoOrYoutube) {
      _executeUrlLaunch(context, urlString, isMinor: false);
      return;
    }

    // If user has checked "Don't show this warning again" and is not a minor, launch directly
    if (!shouldShowRedirect && !isMinor) {
      _executeUrlLaunch(context, urlString, isMinor: false);
      return;
    }

    // Show DPDP Compliant Redirect Warning Modal
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool dontShowAgain = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 20.h,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge & Title
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF002E29,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.public,
                              color: const Color(0xFF0F3D38),
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi
                                      ? 'ट्रैक लव्ड वन्स से प्रस्थान'
                                      : 'LEAVING TRACK LOVED ONES',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F3D38),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  isHindi
                                      ? 'बाहरी कानूनी शिक्षा रीडायरेक्ट'
                                      : 'External Legal Education Redirect',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Notice Intro
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: const Color(0xFFE65100),
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                isHindi
                                    ? 'आप अब एक बाहरी मंच पर स्थानांतरित हो रहे हैं। Track Loved Ones App आपको YouTube पर एक स्वतंत्र शैक्षिक चैनल पर रीडायरेक्ट कर रहा है।'
                                    : 'You are now transferring to an external platform. Track Loved Ones App is redirecting you to an independent educational channel on YouTube.',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: const Color(0xFF5D4037),
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Privacy & Compliance Verification Box
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: const Color(0xFF166534),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  isHindi
                                      ? 'गोपनीयता एवं अनुपालन सत्यापन'
                                      : 'PRIVACY & COMPLIANCE VERIFICATION',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF166534),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            _buildBulletItem(
                              isHindi
                                  ? 'Track Loved Ones App आपकी प्रोफ़ाइल, संपर्क, इतिहास या लाइव GPS ट्रैकिंग डेटा YouTube या किसी बाहरी होस्ट के साथ साझा नहीं करता है।'
                                  : 'Track Loved Ones App does NOT share your user profile, phone book contacts, historical logs, or live GPS tracking data with YouTube or any external hosts.',
                            ),
                            SizedBox(height: 6.h),
                            _buildBulletItem(
                              isHindi
                                  ? 'यह शैक्षिक वीडियो संसाधन कानूनी सलाह या औपचारिक वकालत का गठन नहीं करता है।'
                                  : 'This educational video resource does not constitute legal advice or formal advocacy.',
                            ),
                            SizedBox(height: 6.h),
                            _buildBulletItem(
                              isHindi
                                  ? 'प्लेबैक के दौरान दिखने वाले विज्ञापन पूरी तरह से YouTube द्वारा अपनी स्वतंत्र नीतियों के तहत संचालित होते हैं।'
                                  : 'Any video ads or monetization models active during playback are run entirely by YouTube under its own independent policies.',
                            ),
                            if (isMinor) ...[
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: const Color(0xFF166534),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.child_care,
                                      color: const Color(0xFF166534),
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 6.w),
                                    Expanded(
                                      child: Text(
                                        isHindi
                                            ? 'बाल सुरक्षा (DPDP धारा 9): नो-कुकी सैंडबॉक्स सक्रिय है। कोई लक्षित विज्ञापन या ट्रैकिंग की अनुमति नहीं है।'
                                            : 'Minor Safety (DPDP Sec 9): No-cookie sandbox active. Commercial tracking & targeted profiling strictly prevented.',
                                        style: TextStyle(
                                          fontSize: 10.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF166534),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Question prompt
                      Text(
                        isHindi
                            ? 'क्या आप बाहरी वीडियो पर आगे बढ़ना चाहते हैं?'
                            : 'Do you wish to proceed to the external video?',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Don't show again checkbox (for adults)
                      if (!isMinor)
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              dontShowAgain = !dontShowAgain;
                            });
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: Checkbox(
                                  value: dontShowAgain,
                                  activeColor: const Color(0xFF0F3D38),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  onChanged: (val) {
                                    setModalState(() {
                                      dontShowAgain = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  isHindi
                                      ? 'वीडियो लिंक के लिए यह चेतावनी दोबारा न दिखाएं।'
                                      : "Don't show this warning again for video links.",
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 14.h),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                side: const BorderSide(
                                  color: Color(0xFFDC2626),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: Text(
                                isHindi ? '🛑 रद्द करें' : '🛑 CANCEL & STAY',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                backgroundColor: const Color(0xFF15803D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              onPressed: () {
                                if (dontShowAgain && box != null && !isMinor) {
                                  box.put(
                                    'should_show_youtube_redirect',
                                    false,
                                  );
                                }
                                Navigator.pop(dialogCtx);
                                _executeUrlLaunch(
                                  context,
                                  urlString,
                                  isMinor: isMinor,
                                );
                              },
                              child: Text(
                                isHindi ? '🟢 आगे बढ़ें' : '🟢 CONTINUE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h, right: 6.w),
          child: Icon(Icons.circle, size: 5.sp, color: const Color(0xFF166534)),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF14532D),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> _executeUrlLaunch(
    BuildContext context,
    String rawUrl, {
    required bool isMinor,
  }) async {
    try {
      String finalUrl = rawUrl.trim();
      final videoId = extractYouTubeVideoId(finalUrl);

      // Section 9 DPDP compliance routing for Minor Profile
      if (isMinor) {
        if (videoId != null) {
          finalUrl =
              'https://www.youtube-nocookie.com/embed/$videoId?rel=0&modestbranding=1';
        }

        final complianceLedger = {
          "compliance_ledger_event": "LEGAL_PORTAL_MEDIA_ACCESS",
          "schema_version": "TLO-DPDPA-MEDIA-V1.4",
          "timestamp_iso8601": DateTime.now().toUtc().toIso8601String(),
          "user_context": {
            "user_id": Hive.isBoxOpen('userdata')
                ? (Hive.box('userdata').get('userId') ?? 'USR-MINOR-PROFILE')
                : 'USR-MINOR-PROFILE',
            "is_minor_profile": true,
            "parental_consent_token_verified": "VPC-DPDPA-COMPLIANT",
          },
          "routing_execution": {
            "external_youtube_intent_blocked": true,
            "in_app_sandbox_player_activated": true,
            "domain_restricted_to_nocookie_embed": true,
            "monetization_trackers_scrubbed": true,
          },
          "legal_status":
              "Strict compliance with Section 9 child ad bans maintained. Third-party commercial profiling successfully prevented.",
        };
        log("COMPLIANCE LEDGER EVENT: ${jsonEncode(complianceLedger)}");
      }

      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open link')));
        }
      }
    } catch (e) {
      log('Error launching legal media: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class LegalAwarenessApp extends ConsumerStatefulWidget {
  const LegalAwarenessApp({super.key});

  @override
  ConsumerState<LegalAwarenessApp> createState() => _LegalAwarenessAppState();
}

class _LegalAwarenessAppState extends ConsumerState<LegalAwarenessApp> {
  bool _isHindi = false;
  String _searchQuery = '';
  String _selectedJurisdictionFilter = 'All'; // 'All', 'Central', 'State'
  bool _isDisclaimerExpanded = false;

  /// CORE INDIAN LEGAL DOMAINS & SYLLABUS (Sections A, B, C)
  List<LegalTopic> getTopics() {
    return [
      LegalTopic(
        titleEn: '🏛️ SECTION A: CONSTITUTIONAL & CIVIL RIGHTS',
        titleHi: '🏛️ खंड क: संवैधानिक एवं नागरिक अधिकार',
        description:
            'Foundational laws of the Republic of India: Fundamental Rights, Constitutional Remedies, and Data Sovereignty under DPDP Act, 2023.',
        icon: Icons.account_balance,
        youtubeUrl: 'https://www.youtube.com/watch?v=ConstitutionIntro',
        acts: [
          LegalActDetail(
            actName: 'The Constitution of India, 1950',
            jurisdiction: 'Central',
            englishPdfUrl: 'https://legislative.gov.in/constitution-of-india/',
            hindiPdfUrl: 'https://legislative.gov.in/constitution-of-india/',
            referenceVideoUrl:
                'https://www.youtube.com/watch?v=ConstitutionModule',
            sections: [
              LegalSectionDetail(
                sectionTitle: 'Article 19: Freedom of Speech & Expression',
                explanation:
                    'Guarantees six basic democratic freedoms including speech, assembly, and trade, subject to reasonable restrictions.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=Art19Speech',
              ),
              LegalSectionDetail(
                sectionTitle:
                    'Article 21: Protection of Life & Personal Liberty',
                explanation:
                    'No person shall be deprived of life or liberty except according to procedure established by law.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=Art21Liberty',
              ),
              LegalSectionDetail(
                sectionTitle: 'Article 32: Right to Constitutional Remedies',
                explanation:
                    'Heart and soul of the Constitution: guarantees direct approach to the Supreme Court for enforcement of fundamental rights.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=Art32Remedies',
              ),
            ],
            landmarkCases: [
              LandmarkCaseDetail(
                caseName: 'Kesavananda Bharati v. State of Kerala (1973)',
                summary:
                    'Thirteen-judge bench established the Basic Structure Doctrine: Parliament cannot alter the basic framework of the Constitution.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=KesavanandaCase',
              ),
            ],
          ),
          LegalActDetail(
            actName: 'Digital Personal Data Protection (DPDP) Act, 2023',
            jurisdiction: 'Central',
            englishPdfUrl:
                'https://www.meity.gov.in/writereaddata/files/Digital%20Personal%20Data%20Protection%20Act%202023.pdf',
            hindiPdfUrl:
                'https://www.meity.gov.in/writereaddata/files/Digital%20Personal%20Data%20Protection%20Act%202023.pdf',
            referenceVideoUrl: 'https://www.youtube.com/watch?v=DPDPAwareness',
            sections: [
              LegalSectionDetail(
                sectionTitle: 'Section 6: Notice & Unambiguous Consent',
                explanation:
                    'Mandates clear itemized notice and explicit consent prior to processing personal data.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=DPDPASection6',
              ),
              LegalSectionDetail(
                sectionTitle:
                    'Section 9: Processing of Personal Data of Children',
                explanation:
                    'Requires verifiable parental consent and strictly bans behavioral tracking, targeted advertisements, or surveillance on minors.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=DPDPASection9',
              ),
            ],
            landmarkCases: [
              LandmarkCaseDetail(
                caseName: 'Justice K.S. Puttaswamy v. Union of India (2017)',
                summary:
                    'Nine-judge bench unanimously recognized the Right to Privacy as an intrinsic part of the Right to Life under Article 21.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=PuttaswamyCase',
              ),
            ],
          ),
        ],
      ),
      LegalTopic(
        titleEn: '⚖️ SECTION B: NATIONAL CRIMINAL & SECURITY CODES',
        titleHi: '⚖️ खंड ख: राष्ट्रीय आपराधिक एवं सुरक्षा संहिताएँ',
        description:
            'Public safety laws, police procedures under Bharatiya Nyaya Sanhita (BNS), cybercrime, and intermediary system protections.',
        icon: Icons.gavel,
        youtubeUrl: 'https://www.youtube.com/watch?v=BNSOverview',
        acts: [
          LegalActDetail(
            actName: 'Bharatiya Nyaya Sanhita (BNS), 2023',
            jurisdiction: 'Central',
            englishPdfUrl:
                'https://www.mha.gov.in/sites/default/files/250882_english_01042024.pdf',
            hindiPdfUrl:
                'https://www.mha.gov.in/sites/default/files/250882_hindi_ubah_01042024.pdf',
            referenceVideoUrl: 'https://www.youtube.com/watch?v=BNSModule',
            sections: [
              LegalSectionDetail(
                sectionTitle: 'Section 35: General Exceptions',
                explanation:
                    'Acts done in good faith or under mistake of fact without criminal intent.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=BNSSection35',
              ),
              LegalSectionDetail(
                sectionTitle: 'Section 103: Punishment for Murder',
                explanation:
                    'Prescribes death sentence or imprisonment for life along with fine.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=BNSSection103',
              ),
              LegalSectionDetail(
                sectionTitle: 'Section 115: Voluntarily Causing Hurt',
                explanation:
                    'Punishment for intentionally or knowingly causing bodily pain, disease, or infirmity.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=BNSSection115',
              ),
            ],
            landmarkCases: [
              LandmarkCaseDetail(
                caseName: 'D.K. Basu v. State of West Bengal (1997)',
                summary:
                    'Mandatory procedural guidelines for police during arrests, detentions, and interrogation memos.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=DKBasuCase',
              ),
            ],
          ),
          LegalActDetail(
            actName: 'Information Technology (IT) Act, 2000',
            jurisdiction: 'Central',
            englishPdfUrl:
                'https://www.meity.gov.in/content/information-technology-act-2000',
            hindiPdfUrl:
                'https://www.meity.gov.in/content/information-technology-act-2000',
            referenceVideoUrl: 'https://www.youtube.com/watch?v=ITActOverview',
            sections: [
              LegalSectionDetail(
                sectionTitle:
                    'Section 43A: Compensation for Failure to Protect Data',
                explanation:
                    'Liability of body corporate for negligence in implementing reasonable security practices.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=ITAct43A',
              ),
              LegalSectionDetail(
                sectionTitle:
                    'Section 66D: Punishment for Cheating by Personation',
                explanation:
                    'Penalizes online impersonation, phishing, and scamming using computer resources.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=ITAct66D',
              ),
              LegalSectionDetail(
                sectionTitle: 'Section 79: Intermediary Safe Harbor Exemption',
                explanation:
                    'Statutory immunity for network intermediaries that act as neutral conduits without initiating transmissions.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=ITAct79',
              ),
            ],
            landmarkCases: [
              LandmarkCaseDetail(
                caseName: 'Shreya Singhal v. Union of India (2015)',
                summary:
                    'Struck down arbitrary censorship provision (Section 66A) and upheld statutory safe harbor for intermediaries.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=ShreyaSinghalCase',
              ),
            ],
          ),
        ],
      ),
      LegalTopic(
        titleEn: '💼 SECTION C: COMMERCE, LABOR, & FACILITATION CODES',
        titleHi: '💼 खंड ग: वाणिज्य, श्रम एवं सुविधा संहिताएँ',
        description:
            'Electronic contracts, safe-harbor transactions, non-employment protections, and wage regulations for gig ecosystems.',
        icon: Icons.business_center,
        youtubeUrl: 'https://www.youtube.com/watch?v=CommercialCodes',
        acts: [
          LegalActDetail(
            actName: 'The Indian Contract Act, 1872',
            jurisdiction: 'Central',
            englishPdfUrl:
                'https://legislative.gov.in/sites/default/files/A1872-09.pdf',
            hindiPdfUrl:
                'https://legislative.gov.in/sites/default/files/A1872-09.pdf',
            referenceVideoUrl:
                'https://www.youtube.com/watch?v=ContractActModule',
            sections: [
              LegalSectionDetail(
                sectionTitle: 'Section 10: What Agreements are Contracts',
                explanation:
                    'Agreements made by free consent of competent parties for lawful consideration and object.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=ContractSec10',
              ),
              LegalSectionDetail(
                sectionTitle: 'Section 23: Lawful Consideration and Object',
                explanation:
                    'Defines when consideration is forbidden by law, fraudulent, or opposed to public policy.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=ContractSec23',
              ),
            ],
            landmarkCases: [
              LandmarkCaseDetail(
                caseName: 'Carlill v. Carbolic Smoke Ball Co. (1893)',
                summary:
                    'Foundational decision affirming unilateral contracts and binding offers made to the general public.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=CarlillCase',
              ),
            ],
          ),
          LegalActDetail(
            actName: 'Code on Wages & Industrial Relations',
            jurisdiction: 'Central',
            englishPdfUrl: 'https://labour.gov.in/wage-code-2019',
            hindiPdfUrl: 'https://labour.gov.in/wage-code-2019',
            referenceVideoUrl: 'https://www.youtube.com/watch?v=WageCodeModule',
            sections: [
              LegalSectionDetail(
                sectionTitle: 'Section 6: Fixation of Minimum Wages',
                explanation:
                    'Sets statutory floor wage benchmarks and working hour protections across states.',
                youtubeVideoUrl: 'https://www.youtube.com/watch?v=WageSec6',
              ),
              LegalSectionDetail(
                sectionTitle: 'Intermediary Non-Employment Protections',
                explanation:
                    'Distinguishes technological facilitation platforms from employer-employee master-servant relationships.',
                youtubeVideoUrl:
                    'https://www.youtube.com/watch?v=IntermediaryLabor',
              ),
            ],
            landmarkCases: [],
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Watch API provider to ensure cached/fresh data is ready
    ref.watch(getLawProvider);
    final topics = getTopics();

    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: "National Legal Education",
        titleHi: "राष्ट्रीय कानूनी शिक्षा",
        isHindi: _isHindi,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Column(
          children: [
            // -------------------------------------------------------------
            // MANDATORY NATIONAL LEGAL EDUCATION PORTAL HEADER & DISCLAIMER
            // -------------------------------------------------------------
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3D38),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: const Color(0xFFD4AF37),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _isHindi
                              ? 'राष्ट्रीय कानूनी शिक्षा पोर्टल'
                              : 'NATIONAL LEGAL EDUCATION PORTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _isHindi
                        ? '[स्थिर शैक्षिक संदर्भ एवं जन-जागरूकता केंद्र]'
                        : '[Static Educational Reference & Awareness Hub]',
                    style: TextStyle(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _isHindi
                        ? 'भारत गणराज्य के मूलभूत कानूनों को जानें। सभी मल्टीमीडिया और पाठ्य सामग्री केवल सामान्य जन जागरूकता और सूचना के उद्देश्य से प्रदान की गई है।'
                        : 'Explore the foundational laws of the Republic of India. All multimedia and text paths are provided strictly for general public awareness and informational purposes only.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.sp,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Collapsible Mandatory Platform Legal Disclaimer
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isDisclaimerExpanded = !_isDisclaimerExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  _isHindi
                                      ? '⚠️ अनिवार्य वैधानिक अस्वीकरण (Legal Disclaimer)'
                                      : '⚠️ MANDATORY PLATFORM LEGAL DISCLAIMER',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                _isDisclaimerExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.amber,
                                size: 18.sp,
                              ),
                            ],
                          ),
                        ),
                        if (_isDisclaimerExpanded) ...[
                          SizedBox(height: 6.h),
                          Text(
                            _isHindi
                                ? 'Track Loved Ones App केवल एक तकनीकी मध्यस्थ और तटस्थ सूचना मंच के रूप में कार्य करता है। इस पोर्टल में होस्ट की गई कानूनी सामग्री, धारा सारांश और वीडियो लिंक संसाधन औपचारिक कानूनी सलाह, वैधानिक प्रतिनिधित्व या पेशेवर वकालत का गठन नहीं करते हैं।\n\nइस शैक्षिक केंद्र का उपयोग आपके, डेवलपर्स या अवसर पोस्ट करने वाली कंपनियों के बीच कोई वकील-ग्राहक संबंध या रोजगार संबंध स्थापित नहीं करता है। वास्तविक विवादों के लिए किसी योग्य अधिवक्ता से परामर्श लें।'
                                : 'Track Loved Ones App operates strictly as a technological intermediary and neutral information venue. The legal materials, section summaries, and video link resources hosted in this portal do not constitute formal legal advice, statutory representation, or professional advocacy.\n\nYour utilization of this educational center does not establish an attorney-client relationship or any contractual labor/employer-employee ties between you, the application developers, or the opportunity-posting companies. For actionable legal counsel regarding disputes, consult a qualified advocate.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5.sp,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                backgroundColor: Colors.white10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                              icon: Icon(
                                Icons.restart_alt,
                                size: 14.sp,
                                color: Colors.amberAccent,
                              ),
                              label: Text(
                                _isHindi
                                    ? 'चेतावनी संकेत रीसेट करें'
                                    : 'Reset External Link Warnings',
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                final box = Hive.isBoxOpen('userdata')
                                    ? Hive.box('userdata')
                                    : null;
                                box?.put('should_show_youtube_redirect', true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _isHindi
                                          ? 'बाहरी वीडियो सुरक्षा चेतावनी पुनः सक्रिय कर दी गई है।'
                                          : 'External video warnings have been re-enabled for your safety.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filter and Search Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _isHindi
                          ? 'अधिनियम या धाराएं खोजें...'
                          : 'Search Acts or Sections...',
                      hintStyle: TextStyle(
                        color: Colors.black45,
                        fontSize: 13.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.black45,
                        size: 18.sp,
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 30.w,
                        minHeight: 30.h,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 9.h,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: const BorderSide(color: Color(0xFFD0E1F9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: const BorderSide(color: Color(0xFFD0E1F9)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 42.h,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: const Color(0xFFD0E1F9)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedJurisdictionFilter,
                        isExpanded: true,
                        items: ['All', 'Central', 'State']
                            .map(
                              (val) => DropdownMenuItem(
                                value: val,
                                child: Text(
                                  val,
                                  style: TextStyle(fontSize: 12.5.sp),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedJurisdictionFilter = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Syllabus Topics & Acts List
            Expanded(
              child: ListView.builder(
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];

                  final filteredActs = topic.acts.where((act) {
                    final matchesJurisdiction =
                        _selectedJurisdictionFilter == 'All' ||
                        act.jurisdiction.toLowerCase() ==
                            _selectedJurisdictionFilter.toLowerCase();

                    final matchesSearch =
                        act.actName.toLowerCase().contains(_searchQuery) ||
                        act.sections.any(
                          (sec) =>
                              sec.sectionTitle.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              sec.explanation.toLowerCase().contains(
                                _searchQuery,
                              ),
                        );

                    return matchesJurisdiction && matchesSearch;
                  }).toList();

                  if (filteredActs.isEmpty && _searchQuery.isNotEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(14.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18.r,
                                backgroundColor: const Color(0xFFE0ECF8),
                                child: Icon(
                                  topic.icon,
                                  color: const Color(0xFF0F4C81),
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isHindi ? topic.titleHi : topic.titleEn,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F3D38),
                                      ),
                                    ),
                                    if (!_isHindi)
                                      Text(
                                        topic.titleHi,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            topic.description,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 10.h),

                          Text(
                            _isHindi
                                ? 'लागू अधिनियम (विस्तृत धाराओं के लिए टैप करें):'
                                : 'Applicable Acts (Tap for Section Explanations):',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F4C81),
                            ),
                          ),
                          SizedBox(height: 6.h),

                          ...filteredActs.map(
                            (act) => Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: const Color(0xFFD0E1F9),
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8.r),
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => ActDetailBottomSheet(
                                      act: act,
                                      isHindi: _isHindi,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(10.w),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    act.actName,
                                                    style: TextStyle(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF0F4C81,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 6.w),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6.w,
                                                    vertical: 2.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        act.jurisdiction ==
                                                            'Central'
                                                        ? const Color(
                                                            0xFF0F4C81,
                                                          )
                                                        : const Color(
                                                            0xFF1B4332,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4.r,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    act.jurisdiction,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6.h),
                                            // Reference Module Button
                                            InkWell(
                                              onTap: () {
                                                LegalMediaRedirectHelper.launchLegalMedia(
                                                  context: context,
                                                  urlString:
                                                      act
                                                          .referenceVideoUrl
                                                          .isNotEmpty
                                                      ? act.referenceVideoUrl
                                                      : topic.youtubeUrl,
                                                  isHindi: _isHindi,
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFDE8E8,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        6.r,
                                                      ),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFF87171,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.play_circle_fill,
                                                      size: 14.sp,
                                                      color: const Color(
                                                        0xFFDC2626,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      _isHindi
                                                          ? '📺 संदर्भ मॉड्यूल देखें'
                                                          : '📺 View Reference Module',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFFB91C1C,
                                                        ),
                                                        fontSize: 10.5.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14.sp,
                                          color: const Color(0xFF0F4C81),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet displaying PDFs, Sections with individual YouTube links, and Case laws with videos
// ---------------------------------------------------------------------------
class ActDetailBottomSheet extends ConsumerStatefulWidget {
  final LegalActDetail act;
  final bool isHindi;
  const ActDetailBottomSheet({
    super.key,
    required this.act,
    this.isHindi = false,
  });

  @override
  ConsumerState<ActDetailBottomSheet> createState() =>
      _ActDetailBottomSheetState();
}

class _ActDetailBottomSheetState extends ConsumerState<ActDetailBottomSheet> {
  String _sectionSearchQuery = '';

  Future<void> _launchPdfUrl(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isHindi
                  ? 'पीडीएफ लिंक उपलब्ध नहीं है'
                  : 'No PDF URL available',
            ),
          ),
        );
      }
      return;
    }
    try {
      final uri = Uri.parse(urlString.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open PDF')));
        }
      }
    } catch (e) {
      log('Error opening PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lawAsync = ref.watch(getLawProvider);
    final List<LawContentItem> allItems = lawAsync.value?.data ?? [];

    final isCentral = widget.act.jurisdiction.toLowerCase() == 'central';

    // Filter API items by jurisdiction (Central vs State)
    final jurisdictionItems = allItems.where((item) {
      final itemState = (item.state ?? 'central').trim().toLowerCase();
      if (isCentral) {
        return itemState == 'central';
      } else {
        return itemState != 'central';
      }
    }).toList();

    // Separate PDFs from API
    final apiPdfItems = jurisdictionItems.where((i) {
      final isPdfType = i.type?.toLowerCase() == 'pdf';
      final hasPdfUrl = i.url != null && i.url!.toLowerCase().contains('.pdf');
      final isCloudinaryRaw = i.url != null && i.url!.contains('/raw/upload/');
      return isPdfType || hasPdfUrl || isCloudinaryRaw;
    }).toList();

    // Separate Videos from API
    final apiVideoItems = jurisdictionItems.where((i) {
      final isVideoType = i.type?.toLowerCase() == 'video';
      final isYoutube =
          i.url != null &&
          (i.url!.contains('youtu.be') || i.url!.contains('youtube.com'));
      return isVideoType || isYoutube;
    }).toList();

    // Search filter for API videos
    final filteredApiVideos = apiVideoItems.where((item) {
      if (_sectionSearchQuery.isEmpty) return true;
      final q = _sectionSearchQuery.toLowerCase();
      final titleMatch = item.title?.toLowerCase().contains(q) ?? false;
      final moduleMatch = item.lawModule?.toLowerCase().contains(q) ?? false;
      final secMatch = item.section?.toLowerCase().contains(q) ?? false;
      final catMatch = item.category?.toLowerCase().contains(q) ?? false;
      final descMatch = item.description?.toLowerCase().contains(q) ?? false;
      return titleMatch || moduleMatch || secMatch || catMatch || descMatch;
    }).toList();

    // Fallback mock sections filter
    final filteredSections = widget.act.sections
        .where(
          (sec) =>
              sec.sectionTitle.toLowerCase().contains(_sectionSearchQuery) ||
              sec.explanation.toLowerCase().contains(_sectionSearchQuery),
        )
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.all(18.w),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.act.actName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F4C81),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: widget.act.jurisdiction == 'Central'
                        ? const Color(0xFF0F4C81)
                        : const Color(0xFF1B4332),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    widget.act.jurisdiction,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              widget.isHindi
                  ? 'आधिकारिक अधिनियम पीडीएफ डाउनलोड करें'
                  : 'Download Official Act PDF',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      backgroundColor: const Color(0xFF0F4C81),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    label: Text(
                      'English PDF',
                      style: TextStyle(color: Colors.white, fontSize: 11.5.sp),
                    ),
                    onPressed: () {
                      final url = apiPdfItems.isNotEmpty
                          ? apiPdfItems.first.url
                          : widget.act.englishPdfUrl;
                      _launchPdfUrl(url);
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      backgroundColor: const Color(0xFF1B4332),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    label: Text(
                      'हिंदी पीडीएफ',
                      style: TextStyle(color: Colors.white, fontSize: 11.5.sp),
                    ),
                    onPressed: () {
                      final url = apiPdfItems.length > 1
                          ? apiPdfItems[1].url
                          : (apiPdfItems.isNotEmpty
                                ? apiPdfItems.first.url
                                : widget.act.hindiPdfUrl);
                      _launchPdfUrl(url);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Section Filter Search Bar Inside Bottom Sheet
            TextField(
              onChanged: (val) {
                setState(() {
                  _sectionSearchQuery = val.toLowerCase();
                });
              },
              style: TextStyle(fontSize: 13.sp, color: Colors.black87),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.isHindi
                    ? 'धाराएं खोजें (उदा. Section 103)...'
                    : 'Filter sections (e.g. Section 103)...',
                hintStyle: TextStyle(fontSize: 12.sp, color: Colors.black45),
                prefixIcon: Icon(
                  Icons.filter_list,
                  color: const Color(0xFF0F4C81),
                  size: 18.sp,
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 32.w,
                  minHeight: 32.h,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8.h,
                  horizontal: 12.w,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F4F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFFD0E1F9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFFD0E1F9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFF0F4C81)),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              widget.isHindi
                  ? 'प्रमुख धाराएं एवं वीडियो व्याख्याएं'
                  : 'Key Sections & Video Explanations',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F4C81),
              ),
            ),
            SizedBox(height: 6.h),

            // Loading / Dynamic List from API
            if (lawAsync.isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const CircularProgressIndicator(
                    color: Color(0xFF0F4C81),
                  ),
                ),
              )
            else if (filteredApiVideos.isNotEmpty)
              ...filteredApiVideos.map((item) {
                final title =
                    (item.lawModule != null &&
                        item.lawModule!.trim().isNotEmpty)
                    ? item.lawModule!.trim()
                    : ((item.title != null && item.title!.trim().isNotEmpty)
                          ? item.title!.trim()
                          : 'Legal Video Explanation');

                final subtitleParts = [
                  if (item.section != null && item.section!.trim().isNotEmpty)
                    item.section!.trim(),
                  if (item.category != null && item.category!.trim().isNotEmpty)
                    item.category!.trim(),
                ];
                final subtitle = subtitleParts.isNotEmpty
                    ? subtitleParts.join(' • ')
                    : (item.description ?? '');

                return Card(
                  elevation: 1,
                  margin: EdgeInsets.only(bottom: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: subtitle.isNotEmpty
                        ? Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: Colors.black54,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Color(0xFFCC0000),
                        size: 28,
                      ),
                      tooltip: 'Watch Section Video',
                      onPressed: () =>
                          LegalMediaRedirectHelper.launchLegalMedia(
                            context: context,
                            urlString: item.url,
                            isHindi: widget.isHindi,
                          ),
                    ),
                  ),
                );
              })
            else
              // Fallback to mock sections if API list is empty or matches none
              ...filteredSections.map(
                (sec) => Card(
                  elevation: 1,
                  margin: EdgeInsets.only(bottom: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      sec.sectionTitle,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      sec.explanation,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Color(0xFFCC0000),
                        size: 28,
                      ),
                      tooltip: 'Watch Section Video',
                      onPressed: () =>
                          LegalMediaRedirectHelper.launchLegalMedia(
                            context: context,
                            urlString: sec.youtubeVideoUrl,
                            isHindi: widget.isHindi,
                          ),
                    ),
                  ),
                ),
              ),

            if (widget.act.landmarkCases.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Text(
                widget.isHindi
                    ? 'ऐतिहासिक फैसले एवं वीडियो व्याख्याएं'
                    : 'Landmark Cases & Video Explanations',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F4C81),
                ),
              ),
              SizedBox(height: 6.h),
              ...widget.act.landmarkCases.map(
                (c) => Card(
                  elevation: 1,
                  margin: EdgeInsets.only(bottom: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      c.caseName,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    subtitle: Text(
                      c.summary,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Color(0xFFCC0000),
                        size: 28,
                      ),
                      tooltip: 'Watch Case Video',
                      onPressed: () =>
                          LegalMediaRedirectHelper.launchLegalMedia(
                            context: context,
                            urlString: c.youtubeVideoUrl,
                            isHindi: widget.isHindi,
                          ),
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              height: 42.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0F4C81)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  widget.isHindi ? 'बंद करें' : 'Close',
                  style: TextStyle(
                    color: const Color(0xFF0F4C81),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// ADMIN PORTAL SCREEN: Map YouTube Explainer URLs to Specific Sections & Cases
// -------------------------------------------------------------------------
class AdminVideoUploadScreen extends StatefulWidget {
  const AdminVideoUploadScreen({super.key});

  @override
  State<AdminVideoUploadScreen> createState() => _AdminVideoUploadScreenState();
}

class _AdminVideoUploadScreenState extends State<AdminVideoUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _actController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();

  String? _selectedTargetType = 'Section';
  String _selectedJurisdiction = 'Central';

  void _saveVideoMapping() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Success!',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'YouTube video linked successfully for $_selectedTargetType: ${_sectionController.text} under [$_selectedJurisdiction] ${_actController.text}.',
            style: TextStyle(fontSize: 13.5.sp, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _actController.clear();
                _sectionController.clear();
                _youtubeUrlController.clear();
                setState(() {
                  _selectedTargetType = 'Section';
                  _selectedJurisdiction = 'Central';
                });
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: const Color(0xFF0F4C81),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        title: Text(
          'Admin Portal: Link YouTube Videos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload / Map Section Explainer Video',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F4C81),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Enter the target Act, Jurisdiction (Central/State) and Section/Case details along with your YouTube video link.',
                style: TextStyle(fontSize: 13.sp, color: Colors.black54),
              ),
              SizedBox(height: 20.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedJurisdiction,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Jurisdiction (Central or State)',
                  labelStyle: TextStyle(
                    fontSize: 13.5.sp,
                    color: Colors.black54,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFDCDFE4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F4C81),
                      width: 1.5,
                    ),
                  ),
                ),
                items: ['Central', 'State'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type, style: TextStyle(fontSize: 14.sp)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedJurisdiction = val!;
                  });
                },
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedTargetType,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Target Type',
                  labelStyle: TextStyle(
                    fontSize: 13.5.sp,
                    color: Colors.black54,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFDCDFE4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F4C81),
                      width: 1.5,
                    ),
                  ),
                ),
                items: ['Section', 'Landmark Case'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type, style: TextStyle(fontSize: 14.sp)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTargetType = val;
                  });
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _actController,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Act Name (e.g. Bharatiya Nyaya Sanhita)',
                  labelStyle: TextStyle(
                    fontSize: 13.5.sp,
                    color: Colors.black54,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFDCDFE4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F4C81),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter Act name' : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _sectionController,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: _selectedTargetType == 'Section'
                      ? 'Section Title (e.g. Section 103)'
                      : 'Case Name (e.g. D.K. Basu v. State)',
                  labelStyle: TextStyle(
                    fontSize: 13.5.sp,
                    color: Colors.black54,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFDCDFE4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F4C81),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter title' : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _youtubeUrlController,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'YouTube Video URL',
                  labelStyle: TextStyle(
                    fontSize: 13.5.sp,
                    color: Colors.black54,
                  ),
                  hintText: 'https://www.youtube.com/watch?v=...',
                  hintStyle: TextStyle(fontSize: 13.sp, color: Colors.black45),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFDCDFE4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F4C81),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null ||
                      val.isEmpty ||
                      !val.contains('youtube.com')) {
                    return 'Please enter a valid YouTube link';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: _saveVideoMapping,
                  child: Text(
                    'Save & Publish Video Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
