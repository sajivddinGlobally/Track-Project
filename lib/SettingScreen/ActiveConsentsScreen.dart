import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/UpdateConsentsBodyModel.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class ActiveConsentsScreen extends ConsumerStatefulWidget {
  final bool isHindi;

  const ActiveConsentsScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<ActiveConsentsScreen> createState() =>
      _ActiveConsentsScreenState();
}

class _ActiveConsentsScreenState extends ConsumerState<ActiveConsentsScreen> {
  bool _isAdult = true;

  // Consent Toggles
  bool _locationConsent = true;
  bool _marketplaceConsent = true;
  bool _analyticsConsent = false;

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _updatingToggle;

  @override
  void initState() {
    super.initState();
    _loadLocalCacheAndFetchProfile();
  }

  void _loadLocalCacheAndFetchProfile() {
    // 1. Initialise with local Hive state for instant rendering
    try {
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      if (box != null) {
        final accountType =
            box.get('account_type', defaultValue: 'adult') as String;
        final adultSubmitted =
            box.get('adult_upgrade_submitted', defaultValue: false) as bool;
        _isAdult = accountType == 'adult' || adultSubmitted;

        _locationConsent =
            box.get('consent_location_tracking', defaultValue: true) as bool;
        _marketplaceConsent =
            box.get('consent_marketplace_jobs', defaultValue: true) as bool;
        _analyticsConsent =
            box.get('consent_service_analytics', defaultValue: false) as bool;

        if (!_isAdult) {
          _analyticsConsent = false;
          _marketplaceConsent = false;
        }
      }
    } catch (_) {}

    // 2. Fetch fresh consents from profile API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchConsentsFromApi();
    });
  }

  Future<void> _fetchConsentsFromApi() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final profileRes = await authService.getMyProfileData();

      final user = profileRes.data?.user;
      if (user != null) {
        final accountRole = user.role?.toLowerCase() ?? '';
        final isAdultUser = accountRole != 'child' && accountRole != 'minor';
        _isAdult = isAdultUser;

        final consents = user.consents;
        if (consents != null) {
          setState(() {
            _locationConsent = consents.realTimeLocation ?? true;
            _marketplaceConsent = consents.jobMarketplace ?? true;
            _analyticsConsent = consents.analytics ?? false;

            if (!_isAdult) {
              _analyticsConsent = false;
              _marketplaceConsent = false;
            }
          });
        }

        // Cache fresh values to Hive
        final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
        if (box != null) {
          await box.put('consent_location_tracking', _locationConsent);
          await box.put('consent_marketplace_jobs', _marketplaceConsent);
          await box.put('consent_service_analytics', _analyticsConsent);
        }
      }
    } catch (e) {
      // Keep local state if offline or API error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateConsentOnToggle({
    required String toggleKey,
    required bool newValue,
  }) async {
    if (_isUpdating) return;

    final oldLocation = _locationConsent;
    final oldMarketplace = _marketplaceConsent;
    final oldAnalytics = _analyticsConsent;

    // Optimistic local UI update
    setState(() {
      _isUpdating = true;
      _updatingToggle = toggleKey;
      if (toggleKey == 'location') {
        _locationConsent = newValue;
      } else if (toggleKey == 'marketplace') {
        _marketplaceConsent = newValue;
      } else if (toggleKey == 'analytics') {
        _analyticsConsent = newValue;
      }
    });

    // Device level action: If location turned OFF, immediately stop GPS listeners
    if (toggleKey == 'location' && !newValue) {
      _stopDeviceLocationTracking();
    }

    try {
      final body = UpdateConsentsBodyModel(
        realTimeLocation: _locationConsent,
        jobMarketplace: _marketplaceConsent,
        analytics: _analyticsConsent,
      );

      final authService = ref.read(authServiceProvider);
      final response = await authService.updateConsentsData(body);

      // Persist in local Hive
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      if (box != null) {
        await box.put('consent_location_tracking', _locationConsent);
        await box.put('consent_marketplace_jobs', _marketplaceConsent);
        await box.put('consent_service_analytics', _analyticsConsent);
        await box.put(
          'consent_last_updated_iso',
          DateTime.now().toUtc().toIso8601String(),
        );
      }

      final msg = response.message ?? 'Consents updated successfully.';
      showSuccessSnackBar(
        widget.isHindi
            ? 'सहमति प्राथमिकताएं सफलतापूर्वक अपडेट हो गईं।'
            : msg,
      );
    } catch (error) {
      // Revert state on failure
      if (mounted) {
        setState(() {
          _locationConsent = oldLocation;
          _marketplaceConsent = oldMarketplace;
          _analyticsConsent = oldAnalytics;
        });
      }
      showErrorSnackBar(
        widget.isHindi
            ? 'सहमति अपडेट करने में विफल। कृपया पुनः प्रयास करें।'
            : 'Failed to update consents. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _updatingToggle = null;
        });
      }
    }
  }

  void _stopDeviceLocationTracking() {
    try {
      final box = Hive.isBoxOpen('userdata') ? Hive.box('userdata') : null;
      if (box != null) {
        box.put('isLocationSharingActive', false);
        box.put('isTrackingAllowed', false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFC5A038);
    const brightGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3D38),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F3D38),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isHindi ? 'मेरी सक्रिय सहमतियां' : 'My Active Consents',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F3D38), Color(0xFF072420), Color(0xFF031210)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: brightGold),
                )
              : SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              brightGold.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: brandGold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  color: brightGold,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  widget.isHindi
                                      ? 'अपनी सहमति प्रबंधित करें 🛡️ (DPDPA Sec 6(4))'
                                      : 'Manage Your Consents 🛡️ (DPDPA Sec 6(4))',
                                  style: GoogleFonts.outfit(
                                    color: brightGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              widget.isHindi
                                  ? 'समीक्षा करें और नियंत्रित करें कि आप किन डेटा प्रोसेसिंग गतिविधियों की अनुमति देते हैं। किसी आइटम को टॉगल बंद करने पर आपकी सहमति तत्काल प्रभाव से वापस (Revoke) हो जाती है।'
                                  : 'Review and control what data processing activities you allow. Toggling an item off immediately revokes your consent under Section 6(4) of the DPDP Act, 2023.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12.5.sp,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Consent 1: Real-Time Location Tracking
                      _buildConsentCard(
                        icon: Icons.my_location_rounded,
                        title: widget.isHindi
                            ? 'रीयल-टाइम जीपीएस लोकेशन ट्रैकिंग'
                            : 'Real-Time Location Tracking',
                        description: widget.isHindi
                            ? 'ऐप को आपके चयनित सर्कल को आपकी लाइव मानचित्र स्थिति प्रदर्शित करने के लिए आपके जीपीएस निर्देशांक को संसाधित करने की अनुमति देता है।'
                            : 'Allows the app to process your GPS coordinates to display your live map status to your selected circle.',
                        actionNote: widget.isHindi
                            ? 'कार्रवाई: इसे बंद करने पर सभी लोकेशन ब्रॉडकास्टिंग तुरंत रुक जाती है।'
                            : 'Action: Turning this off stops all location broadcasting immediately.',
                        isActive: _locationConsent,
                        accentColor: const Color(0xFF00E676),
                        isUpdating: _isUpdating && _updatingToggle == 'location',
                        onChanged: (val) {
                          _updateConsentOnToggle(
                            toggleKey: 'location',
                            newValue: val,
                          );
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Consent 2: Job & Opportunities Marketplace
                      if (_isAdult)
                        _buildConsentCard(
                          icon: Icons.business_center_rounded,
                          title: widget.isHindi
                              ? 'नौकरी एवं अवसर मार्केटप्लेस'
                              : 'Job & Opportunities Marketplace',
                          badge: widget.isHindi
                              ? '18+ बालिग प्रोफाइल'
                              : 'Adult Profiles Only',
                          description: widget.isHindi
                              ? 'प्लेटफ़ॉर्म को कॉर्पोरेट नौकरी रिक्तियों को प्रदर्शित करने और आपके "Apply" टैप करने पर आपके पेशेवर विवरण को आगे भेजने की अनुमति देता है।'
                              : 'Allows the platform to display corporate job vacancies and pass your professional card details forward when you tap "Apply".',
                          actionNote: widget.isHindi
                              ? 'कार्रवाई: इसे बंद करने पर करियर टैब छिप जाता है और आपकी दृश्यमान प्रोफ़ाइल नेटवर्क से बाहर हो जाती है।'
                              : 'Action: Turning this off hides the career tab and pulls your visible professional profile out of the marketplace network.',
                          isActive: _marketplaceConsent,
                          accentColor: brightGold,
                          isUpdating:
                              _isUpdating && _updatingToggle == 'marketplace',
                          onChanged: (val) {
                            _updateConsentOnToggle(
                              toggleKey: 'marketplace',
                              newValue: val,
                            );
                          },
                        )
                      else
                        _buildDisabledForChildCard(
                          icon: Icons.business_center_rounded,
                          title: widget.isHindi
                              ? 'नौकरी एवं अवसर मार्केटप्लेस'
                              : 'Job & Opportunities Marketplace',
                          reason: widget.isHindi
                              ? 'नाबालिग खातों के लिए पूरी तरह से अक्षम (Section 9 DPDP Act Child Safeguard).'
                              : 'Permanently restricted for minor accounts under Section 9 Child Safeguards.',
                        ),
                      SizedBox(height: 16.h),

                      // Consent 3: Internal Service Analytics
                      if (_isAdult)
                        _buildConsentCard(
                          icon: Icons.insights_rounded,
                          title: widget.isHindi
                              ? 'आंतरिक सेवा विश्लेषण (Service Analytics)'
                              : 'Internal Service Analytics',
                          description: widget.isHindi
                              ? 'मानचित्र विलंबता और ट्रैकिंग सटीकता को अनुकूलित करने के लिए उपयोग की जाने वाली सुविधाओं और सत्र रुझानों की निगरानी करने की अनुमति देता है।'
                              : 'Allows the app to monitor features tapped and session trends to optimize map latency and tracking accuracy.',
                          actionNote: widget.isHindi
                              ? 'कार्रवाई: इसे बंद करने पर व्यवहार ट्रैकिंग बंद हो जाती है और केवल महत्वपूर्ण टेलीमेट्री पर निर्भर रहता है।'
                              : 'Action: Turning this off switches off behavioral tracking and relies strictly on critical telemetry.',
                          isActive: _analyticsConsent,
                          accentColor: const Color(0xFF4FC3F7),
                          isUpdating:
                              _isUpdating && _updatingToggle == 'analytics',
                          onChanged: (val) {
                            _updateConsentOnToggle(
                              toggleKey: 'analytics',
                              newValue: val,
                            );
                          },
                        )
                      else
                        _buildDisabledForChildCard(
                          icon: Icons.insights_rounded,
                          title: widget.isHindi
                              ? 'आंतरिक सेवा विश्लेषण (Analytics)'
                              : 'Internal Service Analytics',
                          reason: widget.isHindi
                              ? 'चाइल्ड प्रोफाइल के लिए डिफ़ॉल्ट रूप से अक्षम (व्यवहार ट्रैकिंग पूरी तरह से प्रतिबंधित है)।'
                              : 'Forced to Disabled by default for Child Profiles (Zero behavioral tracking).',
                        ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildConsentCard({
    required IconData icon,
    required String title,
    required String description,
    required String actionNote,
    required bool isActive,
    required Color accentColor,
    required ValueChanged<bool> onChanged,
    required bool isUpdating,
    String? badge,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isActive ? accentColor.withValues(alpha: 0.4) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (badge != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        badge,
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUpdating)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
                )
              else
                Switch(
                  value: isActive,
                  activeColor: accentColor,
                  activeTrackColor: accentColor.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white54,
                  inactiveTrackColor: Colors.white12,
                  onChanged: _isUpdating ? null : onChanged,
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              actionNote,
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                color: isActive ? Colors.white60 : Colors.orangeAccent,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledForChildCard({
    required IconData icon,
    required String title,
    required String reason,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Locked / Disabled',
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  reason,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5.sp,
                    color: Colors.white38,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
