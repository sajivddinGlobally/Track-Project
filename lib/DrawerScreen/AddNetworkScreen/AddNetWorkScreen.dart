import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';
import 'package:track_loved/DrawerScreen/AddNetworkScreen/Provider/AddNetoworkserachProvider.dart';
import 'package:track_loved/DrawerScreen/AddNetworkScreen/Provider/getMatchContactProvider.dart';
import 'package:track_loved/MessageScreen/MessageScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/MatchContactsBodyModel.dart';
import 'package:track_loved/core/Data/BodyModel/ManualContactBodyModel.dart';
import 'package:track_loved/core/Data/ResponseModel/AddNetworkSearchResModel.dart';
import 'package:track_loved/core/Data/ResponseModel/MatchContactsResModel.dart'
    as mcr;
import 'package:track_loved/core/Utils/showMessage.dart';
import 'package:url_launcher/url_launcher.dart';

class AddNetworkSearchScreen extends ConsumerStatefulWidget {
  const AddNetworkSearchScreen({super.key});

  @override
  ConsumerState<AddNetworkSearchScreen> createState() =>
      _AddNetworkSearchScreenState();
}

class _AddNetworkSearchScreenState
    extends ConsumerState<AddNetworkSearchScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _memberSearchController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String _searchQuery = '';
  String _activePincode = '';
  bool _isHindi = false;
  bool _isPincodeValid = true;
  String _validationMessage = '';
  Timer? _debounceTimer;
  final Set<String> _pendingUserIds = {};
  final Set<String> _loadingUserIds = {};
  final Set<String> _invitedPhoneNumbers = {};

  List<User>? _matchedContactsUsers;
  List<mcr.InviteItem>? _matchedInviteList;
  bool _isMatchedViewActive = false;

  bool _selectMode = false;
  bool _isDeleting = false;
  final Set<String> _selectedPhones = {};
  final Map<String, String> _phoneByUserId = {};

  void _validatePincode(String pincode) {
    final cleanPin = pincode.trim();
    if (cleanPin.isEmpty) {
      setState(() {
        _isPincodeValid = true;
        _validationMessage = '';
        _activePincode = '';
      });
      return;
    }

    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(cleanPin);

    setState(() {
      _activePincode = cleanPin;
      if (!isNumeric) {
        _isPincodeValid = false;
        _validationMessage = _isHindi
            ? 'पिन कोड में केवल अंक होने चाहिए।'
            : 'Pincode should contain only digits.';
      } else if (cleanPin.length > 6) {
        _isPincodeValid = false;
        _validationMessage = _isHindi
            ? 'पिन कोड अधिकतम 6 अंकों का होना चाहिए।'
            : 'Pincode must be up to 6 digits.';
      } else {
        _isPincodeValid = true;
        _validationMessage = '';
      }
    });
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim();
        });
      }
    });
  }

  void _onPincodeChanged(String pincode) {
    _validatePincode(pincode);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _activePincode = pincode.trim();
        });
      }
    });
  }

  String get _effectiveQuery {
    if (_isMatchedViewActive) {
      return '';
    }
    if (_searchQuery.isNotEmpty) {
      return _searchQuery;
    }
    if (_activePincode.isNotEmpty) {
      return _activePincode;
    }
    return '';
  }

  Future<void> _handleMatchContacts({
    bool isGoogle = false,
    StateSetter? setModalState,
    void Function(bool)? setLoading,
  }) async {
    if (setModalState != null && setLoading != null) {
      setModalState(() {
        setLoading(true);
      });
    }
    try {
      // 1. Request Contacts Permission
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        if (!mounted) return;
        if (setModalState != null && setLoading != null) {
          setModalState(() {
            setLoading(false);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'संपर्क मैच करने के लिए अनुमति आवश्यक है।'
                  : 'Contact permission is required to match contacts.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Fetch Contacts from Device
      final deviceContacts = await fc.FlutterContacts.getAll(
        properties: {fc.ContactProperty.name, fc.ContactProperty.phone},
      );

      // 3. Process & Normalize Contacts
      final List<ContactItem> contactItems = [];
      final Set<String> seenPhones = {};

      for (final contact in deviceContacts) {
        String name = contact.displayName?.trim() ?? '';
        if (name.isEmpty) {
          final first = contact.name?.first ?? '';
          final last = contact.name?.last ?? '';
          name = '$first $last'.trim();
        }
        if (name.isEmpty) {
          name = 'Contact';
        }

        for (final phone in contact.phones) {
          final String raw = phone.number.trim();
          // Remove spaces, hyphens, brackets, dots
          String cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

          // Normalize phone number (strip standard prefixes for 10-digit mobile numbers)
          if (cleaned.startsWith('+91') && cleaned.length == 13) {
            cleaned = cleaned.substring(3);
          } else if (cleaned.startsWith('91') && cleaned.length == 12) {
            cleaned = cleaned.substring(2);
          } else if (cleaned.startsWith('0') && cleaned.length == 11) {
            cleaned = cleaned.substring(1);
          } else if (cleaned.length > 10) {
            cleaned = cleaned.substring(cleaned.length - 10);
          }

          if (cleaned.length >= 10 && !seenPhones.contains(cleaned)) {
            seenPhones.add(cleaned);
            // Local SHA-256 Cryptographic Hash as per DPDPA Rule 1
            final String phoneHash = sha256
                .convert(utf8.encode(cleaned))
                .toString();
            contactItems.add(
              ContactItem(name: name, phone: cleaned, phoneHash: phoneHash),
            );
          }
        }
      }

      if (contactItems.isEmpty) {
        if (!mounted) return;
        if (setModalState != null && setLoading != null) {
          setModalState(() {
            setLoading(false);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'डिवाइस पर कोई मान्य संपर्क नंबर नहीं मिला।'
                  : 'No valid contact numbers found on device.',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }

      // 4. Send Dynamic Contact Matching Payload to API
      // Send in small batches: one request with every contact is rejected
      // by the server with 413 (Payload Too Large).
      const batchSize = 200;
      final authService = ref.read(authServiceProvider);
      final contacts = <mcr.Contact>[];
      final inviteList = <mcr.InviteItem>[];
      for (var i = 0; i < contactItems.length; i += batchSize) {
        final batch = contactItems.sublist(
          i,
          i + batchSize > contactItems.length
              ? contactItems.length
              : i + batchSize,
        );
        final response = await authService.matchContactsData(
          MatchContactsBodyModel(
            contacts: batch,
            consentGrantedAffirmatively: true,
            syncMechanism: isGoogle
                ? "Google API OAuth2 / Local Address Book"
                : "Local Address Book",
            hashingProtocol: "SHA-256",
          ),
        );
        contacts.addAll(response.data?.contacts ?? []);
        inviteList.addAll(response.data?.inviteList ?? []);
      }

      if (!mounted) return;
      if (setModalState != null) {
        Navigator.pop(context);
      }

      for (final c in contacts) {
        final uid = c.user?.userId;
        final ph = c.matchedPhone;
        if (uid != null && ph != null && ph.isNotEmpty) {
          _phoneByUserId[uid] = ph;
        }
      }

      final matchedUsers = contacts
          .map(
            (c) => User(
              id: c.user?.userId,
              name: (c.user?.name != null && c.user!.name!.isNotEmpty)
                  ? c.user!.name
                  : (c.contactName ?? 'Unknown User'),
              profileImage: c.user?.profileImage?.toString(),
              requestStatus: c.connectionStatus,
              phone: c.matchedPhone,
            ),
          )
          .toList();

      setState(() {
        _matchedContactsUsers = matchedUsers;
        _matchedInviteList = inviteList;
        _isMatchedViewActive = true;
      });
      ref.invalidate(getMatchContactProvider);

      if (!mounted) return;
      if (matchedUsers.isNotEmpty || inviteList.isNotEmpty) {
        final totalFound = matchedUsers.length + inviteList.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? '$totalFound संपर्क लोड किए गए!'
                        : '$totalFound contacts synced on Track Loved!',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0B4F4A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isHindi
                  ? 'कोई संपर्क Track Loved पर नहीं मिला'
                  : 'No contacts matched on Track Loved',
              style: TextStyle(fontSize: 13.sp),
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (setModalState != null && setLoading != null) {
        setModalState(() {
          setLoading(false);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? 'संपर्क मैच करने में त्रुटि: $e'
                : 'Failed to match contacts: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCustomContactImport({
    required String name,
    required String phone,
    required StateSetter setModalState,
    required void Function(bool) setLoading,
  }) async {
    final cleanPhone = _normalizePhone(phone);
    if (cleanPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? 'कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें।'
                : 'Please enter a valid 10-digit mobile number.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setModalState(() {
      setLoading(true);
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.addManualContactData(
        ManualContactBodyModel(name: name.trim(), phone: cleanPhone),
      );

      final returnedContacts = response.data?.contacts ?? [];
      final returnedInvites = response.data?.inviteList ?? [];

      for (final c in returnedContacts) {
        final uid = c.user?.userId;
        final ph = c.matchedPhone;
        if (uid != null && ph != null && ph.isNotEmpty) {
          _phoneByUserId[uid] = ph;
        }
      }

      final contactState = ref.read(getMatchContactProvider(_searchQuery));
      final existingApiContacts =
          (contactState.asData?.value.data?.contacts ?? [])
              .map(
                (c) => User(
                  id: c.user?.userId,
                  name: (c.user?.name != null && c.user!.name!.isNotEmpty)
                      ? c.user!.name
                      : (c.contactName ?? 'Unknown User'),
                  profileImage: c.user?.profileImage?.toString(),
                  requestStatus: c.connectionStatus,
                  phone: c.matchedPhone,
                ),
              )
              .toList();
      final existingApiInvites =
          contactState.asData?.value.data?.inviteList ?? [];

      final currentUsers = List<User>.from(
        _matchedContactsUsers ?? existingApiContacts,
      );
      final currentInvites = List<mcr.InviteItem>.from(
        _matchedInviteList ?? existingApiInvites,
      );

      for (final c in returnedContacts) {
        final u = User(
          id: c.user?.userId,
          name: (c.user?.name != null && c.user!.name!.isNotEmpty)
              ? c.user!.name
              : (c.contactName ?? name.trim()),
          profileImage: c.user?.profileImage?.toString(),
          requestStatus: c.connectionStatus,
          phone: c.matchedPhone ?? cleanPhone,
        );
        final idx = currentUsers.indexWhere(
          (existing) =>
              (existing.id != null && existing.id == u.id) ||
              (_normalizePhone(
                    existing.phone ?? _phoneByUserId[existing.id] ?? '',
                  ) ==
                  cleanPhone),
        );
        if (idx >= 0) {
          currentUsers[idx] = u;
        } else {
          currentUsers.insert(0, u);
        }
      }

      for (final inv in returnedInvites) {
        final idx = currentInvites.indexWhere(
          (existing) => _normalizePhone(existing.phone ?? '') == cleanPhone,
        );
        if (idx >= 0) {
          currentInvites[idx] = inv;
        } else {
          currentInvites.insert(0, inv);
        }
      }

      if (returnedContacts.isEmpty && returnedInvites.isEmpty) {
        final alreadyInInvites = currentInvites.any(
          (existing) => _normalizePhone(existing.phone ?? '') == cleanPhone,
        );
        if (!alreadyInInvites) {
          currentInvites.insert(
            0,
            mcr.InviteItem(contactName: name.trim(), phone: cleanPhone),
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        _matchedContactsUsers = currentUsers;
        _matchedInviteList = currentInvites;
        _isMatchedViewActive = true;
      });

      ref.invalidate(getMatchContactProvider);

      if (returnedContacts.isNotEmpty) {
        final found = returnedContacts.first;
        final displayName =
            (found.user?.name != null && found.user!.name!.isNotEmpty)
            ? found.user!.name
            : (found.contactName ?? name.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? '$displayName Track Loved पर मिल गए!'
                        : '$displayName matched on Track Loved!',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0B4F4A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.person_add_alt_1, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _isHindi
                        ? '$name को संपर्क सूची में सफलतापूर्वक जोड़ा गया!'
                        : '$name added to contact list successfully!',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0B4F4A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setModalState(() {
        setLoading(false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? 'संपर्क जोड़ने में त्रुटि: $e'
                : 'Failed to add contact: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImportContactsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (modalCtx) {
        bool isLoading = false;
        int selectedOption = 1; // 1 = Device Phone Book, 2 = Google Contacts
        bool isConsentChecked =
            false; // Unchecked by default (Granular Consent Rule)

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: 0.90.sh),
              decoration: BoxDecoration(
                color: const Color(0xFF002E29),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  SizedBox(height: 12.h),
                  Center(
                    child: Container(
                      width: 44.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: BUILD YOUR SAFETY NETWORK
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00E676,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shield_rounded,
                                  color: const Color(0xFF00E676),
                                  size: 22.sp,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isHindi
                                          ? 'अपना सुरक्षा नेटवर्क बनाएं'
                                          : 'BUILD YOUR SAFETY NETWORK',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      _isHindi
                                          ? '[संपर्क सिंक गोपनीयता सुरक्षा]'
                                          : '[Contact Syncing Privacy Safeguard]',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF00E676),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            _isHindi
                                ? 'अपने परिवार के सदस्यों और प्रियजनों को तुरंत ढूंढें। नीचे एक विकल्प चुनें और देखें कि आपके कौन से मित्र पहले से Track Loved One ऐप पर हैं।'
                                : 'Find your family members and loved ones quickly. Select a method below to view which of your friends are already on Track Loved Ones App.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          const Divider(color: Colors.white12, height: 1),
                          SizedBox(height: 14.h),

                          // Option 1: SYNC DEVICE PHONE BOOK
                          _buildSyncOptionCard(
                            title: _isHindi
                                ? 'विकल्प 1: डिवाइस फ़ोन बुक सिंक करें'
                                : 'OPTION 1: SYNC DEVICE PHONE BOOK',
                            buttonText: _isHindi
                                ? 'मोबाइल संपर्क आयात करें'
                                : 'Import Mobile Contacts',
                            icon: Icons.phone_android_rounded,
                            isSelected: selectedOption == 1,
                            onTap: () {
                              setModalState(() {
                                selectedOption = 1;
                              });
                            },
                          ),
                          SizedBox(height: 10.h),

                          // Option 2: SYNC GOOGLE CONTACTS
                          _buildSyncOptionCard(
                            title: _isHindi
                                ? 'विकल्प 2: गूगल संपर्क सिंक करें'
                                : 'OPTION 2: SYNC GOOGLE CONTACTS',
                            buttonText: _isHindi
                                ? 'गूगल संपर्क कनेक्ट करें'
                                : 'Connect Google Contacts',
                            icon: Icons.alternate_email_rounded,
                            isSelected: selectedOption == 2,
                            onTap: () {
                              setModalState(() {
                                selectedOption = 2;
                              });
                            },
                          ),
                          SizedBox(height: 16.h),

                          // 🛡️ PRIVACY & CONVENIENCE GUARANTEE
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003832),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: const Color(
                                  0xFF005B52,
                                ).withValues(alpha: 0.8),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.security_update_good_rounded,
                                      color: const Color(0xFF00E676),
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      _isHindi
                                          ? '🛡️ गोपनीयता और सुविधा गारंटी:'
                                          : '🛡️ PRIVACY & CONVENIENCE GUARANTEE:',
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF00E676),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                _buildGuaranteeBullet(
                                  title: _isHindi
                                      ? 'केवल सुविधा:'
                                      : 'Convenience Only:',
                                  desc: _isHindi
                                      ? 'हम केवल यह जांचने के लिए संपर्कों तक पहुंचते हैं कि कौन से उपयोगकर्ता पहले से हमारे प्लेटफॉर्म पर हैं।'
                                      : 'We access your contacts solely to match phone numbers with existing users on our platform.',
                                ),
                                SizedBox(height: 8.h),
                                _buildGuaranteeBullet(
                                  title: _isHindi
                                      ? 'डेटा संचयन नहीं:'
                                      : 'No Data Harvesting:',
                                  desc: _isHindi
                                      ? 'Track Loved One ऐप आपकी संपर्क सूची को कभी भी सर्वर पर स्थायी रूप से संग्रहीत या कॉपी नहीं करता है।'
                                      : 'Track Loved Ones App NEVER permanently stores, saves, or copies your contact book onto our servers.',
                                ),
                                SizedBox(height: 8.h),
                                _buildGuaranteeBullet(
                                  title: _isHindi
                                      ? 'जीरो स्पैम नीति:'
                                      : 'Zero Spam Policy:',
                                  desc: _isHindi
                                      ? 'हम कभी भी आपके संपर्कों को स्वचालित संदेश/ईमेल नहीं भेजेंगे, न ही डेटा तीसरे पक्ष को बेचेंगे।'
                                      : 'We will never automatically text, email, or spam your contacts, nor will we sell this data to third-party marketing companies.',
                                ),
                                SizedBox(height: 8.h),
                                _buildGuaranteeBullet(
                                  title: _isHindi
                                      ? 'पूर्ण एन्क्रिप्शन:'
                                      : 'Complete Encryption:',
                                  desc: _isHindi
                                      ? 'संपर्क मिलान सुरक्षित, वन-वे क्रिप्टोग्राफ़िक हैशिंग (SHA-256) के माध्यम से होता है।'
                                      : 'Contact matching happens via secure, one-way cryptographic hashing.',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14.h),

                          // ✍️ GRANULAR CONSENT CHECKBOX (Unchecked by Default)
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                isConsentChecked = !isConsentChecked;
                              });
                            },
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24.w,
                                    height: 24.h,
                                    child: Checkbox(
                                      value: isConsentChecked,
                                      activeColor: const Color(0xFF00E676),
                                      checkColor: const Color(0xFF002E29),
                                      side: const BorderSide(
                                        color: Colors.white54,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        setModalState(() {
                                          isConsentChecked = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      _isHindi
                                          ? '* मैं Track Loved One ऐप को सक्रिय उपयोगकर्ताओं को खोजने के लिए मेरी फ़ोन बुक/Google संपर्कों का मिलान करने की एकमुश्त अनुमति देता हूँ। मैं समझता हूँ कि यह डेटा केवल मेरी सुविधा के लिए संसाधित होता है और संग्रहीत नहीं होता है।'
                                          : '* I grant Track Loved Ones App one-time permission to cross-reference my phone book/Google contacts to find active users. I understand this data is processed strictly for my convenience and is not stored.',
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        color: isConsentChecked
                                            ? Colors.white
                                            : Colors.white70,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Link to manual custom contact
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showCustomManualContactModal();
                              },
                              icon: Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 14.sp,
                                color: const Color(0xFF14B8A6),
                              ),
                              label: Text(
                                _isHindi
                                    ? 'या मैन्युअल रूप से संपर्क जोड़ें'
                                    : 'Or enter contact manually',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF14B8A6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons: [ CANCEL ] [ AGREE & PROCEED ]
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
                    child: isLoading
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFF00E676),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    _isHindi
                                        ? 'सुरक्षित हैशिंग और मिलान जारी है...'
                                        : 'Matching contacts with SHA-256...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(
                                      color: Colors.white30,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: Text(
                                    _isHindi ? 'रद्द करें' : 'CANCEL',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: isConsentChecked
                                      ? () {
                                          _handleMatchContacts(
                                            isGoogle: selectedOption == 2,
                                            setModalState: setModalState,
                                            setLoading: (v) => isLoading = v,
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E676),
                                    foregroundColor: const Color(0xFF002E29),
                                    disabledBackgroundColor: Colors.white12,
                                    disabledForegroundColor: Colors.white38,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    elevation: isConsentChecked ? 2 : 0,
                                  ),
                                  child: Text(
                                    _isHindi
                                        ? 'सहमति दें और आगे बढ़ें'
                                        : 'AGREE & PROCEED',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSyncOptionCard({
    required String title,
    required String buttonText,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF003832) : const Color(0xFF002521),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E676) : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: isSelected
                  ? const Color(0xFF00E676).withValues(alpha: 0.15)
                  : Colors.white10,
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF00E676) : Colors.white70,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : Colors.white60,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF00E676) : Colors.white38,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuaranteeBullet({required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            color: const Color(0xFF00E676),
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 11.5.sp,
                color: Colors.white70,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomManualContactModal() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(maxHeight: 0.85.sh),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3D38),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                  border: Border.all(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(9.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF002E29),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF14B8A6),
                                  width: 1.4,
                                ),
                              ),
                              child: Icon(
                                Icons.person_add_alt_1_rounded,
                                color: const Color(0xFF5EEAD4),
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isHindi
                                        ? 'मैन्युअल संपर्क जोड़ें'
                                        : 'Add Custom Contact',
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    _isHindi
                                        ? 'नाम और फ़ोन नंबर से सीधे आयात करें'
                                        : 'Import directly with name & phone',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 22.sp,
                              ),
                              onPressed: () => Navigator.pop(modalCtx),
                              splashRadius: 20.r,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Text(
                              _isHindi ? 'संपर्क का नाम' : 'Contact Name',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '*',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7.h),
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          enabled: !isSubmitting,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFF002420),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: const Color(0xFF14B8A6),
                              size: 20.sp,
                            ),
                            hintText: _isHindi
                                ? 'उदा. राहुल शर्मा'
                                : 'e.g. Rahul Sharma',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 13.sp,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Colors.white12,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF14B8A6),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return _isHindi
                                  ? 'कृपया संपर्क का नाम दर्ज करें'
                                  : 'Please enter contact name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Text(
                              _isHindi ? 'फ़ोन नंबर' : 'Phone Number',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '*',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7.h),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !isSubmitting,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFF002420),
                            prefixIcon: Icon(
                              Icons.phone_android_rounded,
                              color: const Color(0xFF14B8A6),
                              size: 20.sp,
                            ),
                            prefixText: '+91 ',
                            prefixStyle: TextStyle(
                              color: const Color(0xFF5EEAD4),
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            hintText: _isHindi
                                ? '10 अंकों का मोबाइल नंबर'
                                : '10-digit mobile number',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 13.sp,
                              letterSpacing: 0,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Colors.white12,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF14B8A6),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return _isHindi
                                  ? 'कृपया मोबाइल नंबर दर्ज करें'
                                  : 'Please enter mobile number';
                            }
                            final clean = val.trim().replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            if (clean.length != 10) {
                              return _isHindi
                                  ? '10 अंकों का मान्य मोबाइल नंबर दर्ज करें'
                                  : 'Enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002420),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(
                                0xFF14B8A6,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: const Color(0xFF5EEAD4),
                                size: 18.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _isHindi
                                      ? 'यह संपर्क Track Loved पर मैच किया जाएगा और आपकी नेटवर्क संपर्क सूची में जोड़ा जाएगा।'
                                      : 'This contact will be matched on Track Loved and added to your network contact list.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5.sp,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 22.h),
                        SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (formKey.currentState?.validate() ??
                                        false) {
                                      await _handleCustomContactImport(
                                        name: nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                        setModalState: setModalState,
                                        setLoading: (v) => isSubmitting = v,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B4F4A),
                              disabledBackgroundColor: const Color(
                                0xFF0B4F4A,
                              ).withValues(alpha: 0.6),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.black45,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                side: const BorderSide(
                                  color: Color(0xFF14B8A6),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            child: isSubmitting
                                ? SizedBox(
                                    width: 22.sp,
                                    height: 22.sp,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: const Color(0xFF5EEAD4),
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        _isHindi
                                            ? 'संपर्क आयात करें'
                                            : 'Import Contact',
                                        style: TextStyle(
                                          fontSize: 14.5.sp,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openChatScreen(User member) {
    final String name = member.name ?? 'Member';
    final String initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((word) => word[0])
              .join()
              .toUpperCase();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          receiverId: member.id ?? '',
          name: name,
          initials: initials,
          profileImage: member.profileImage ?? '',
          isHindi: _isHindi,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _memberSearchController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addNetwork = !_isMatchedViewActive
        ? ref.watch(addNetworkSerachProvider(_effectiveQuery))
        : const AsyncValue<AddNetworkSearchResModel>.loading();
    final contactState = ref.watch(getMatchContactProvider(_searchQuery));

    final matchData = contactState.asData?.value.data;
    final apiContacts = (matchData?.contacts ?? [])
        .map(
          (c) => User(
            id: c.user?.userId,
            name: (c.user?.name != null && c.user!.name!.isNotEmpty)
                ? c.user!.name
                : (c.contactName ?? 'Unknown User'),
            profileImage: c.user?.profileImage?.toString(),
            requestStatus: c.connectionStatus,
            phone: c.matchedPhone ?? c.contactPhone,
          ),
        )
        .toList();
    final apiInviteList = matchData?.inviteList ?? [];
    for (final c in matchData?.contacts ?? <mcr.Contact>[]) {
      final uid = c.user?.userId;
      final ph = c.matchedPhone ?? c.contactPhone;
      if (uid != null && ph != null && ph.isNotEmpty) {
        _phoneByUserId[uid] = ph;
      }
    }

    final effectiveMatchedUsers = _searchQuery.isNotEmpty
        ? apiContacts
        : (_matchedContactsUsers ?? apiContacts);
    final effectiveInviteList = _searchQuery.isNotEmpty
        ? apiInviteList
        : (_matchedInviteList ?? apiInviteList);

    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: 'Add Network Search',
        titleHi: 'नेटवर्क खोज जोड़ें',
        isHindi: _isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 480.w),
            padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40.h,
                        child: TextField(
                          controller: _memberSearchController,
                          onChanged: _onSearchChanged,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.black45,
                              size: 18.sp,
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 34.w,
                              minHeight: 0,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                              borderSide: BorderSide.none,
                            ),
                            hintText: _isMatchedViewActive
                                ? (_isHindi
                                    ? 'सहेजे गए संपर्कों में नाम या नंबर से खोजें...'
                                    : 'Search contacts by name or phone...')
                                : (_isHindi
                                    ? 'नाम, भूमिका, शहर या पिनकोड से खोजें...'
                                    : 'Search members by name, role, city, pincode...'),
                            hintStyle: TextStyle(
                              color: Colors.black45,
                              fontSize: 12.sp,
                            ),
                            suffixIcon: _memberSearchController.text.isNotEmpty
                                ? IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.clear,
                                      size: 16.sp,
                                      color: Colors.black45,
                                    ),
                                    onPressed: () {
                                      _memberSearchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    InkWell(
                      onTap: _showImportContactsModal,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        height: 38.h,
                        padding: EdgeInsets.symmetric(horizontal: 9.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B4F4A),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.contact_page_sharp,
                              color: Colors.white,
                              size: 17.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _isHindi ? 'संपर्क' : 'Contacts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    InkWell(
                      onTap: _showCustomManualContactModal,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        height: 38.h,
                        padding: EdgeInsets.symmetric(horizontal: 9.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              color: const Color(0xFF002E29),
                              size: 16.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _isHindi ? 'कस्टम' : 'Custom',
                              style: TextStyle(
                                // color: const Color(0xFF002E29),
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _isPincodeValid
                        ? const Color(0xFFEBF2FA)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: _isPincodeValid
                          ? Colors.transparent
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: _isPincodeValid
                                ? const Color(0xFF1967D2)
                                : Colors.red,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isHindi
                                      ? 'पिन कोड खोज मोड'
                                      : 'Pin Code Search Mode',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _isPincodeValid
                                        ? const Color(0xFF1967D2)
                                        : Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  _activePincode.isEmpty
                                      ? (_isHindi
                                            ? 'सभी पिन कोड दिखाए जा रहे हैं'
                                            : 'Showing all pin codes')
                                      : (_isHindi
                                            ? 'पिन कोड से खोजा जा रहा है: $_activePincode'
                                            : 'Searching by pin code: $_activePincode'),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 100.w,
                              maxWidth: 125.w,
                              minHeight: 38.h,
                            ),
                            child: TextField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                counterText: '',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 8.h,
                                ),
                                hintText: _isHindi ? 'पिनकोड' : 'Pincode',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: _onPincodeChanged,
                            ),
                          ),
                        ],
                      ),
                      if (_validationMessage.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          _validationMessage,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: _isMatchedViewActive
                      ? _buildMatchedContactsView(
                          effectiveMatchedUsers,
                          effectiveInviteList,
                          isLoading: contactState.isLoading,
                        )
                      : addNetwork.when(
                          data: (data) {
                            final allUsers = data.data?.users ?? [];
                            final filteredMembers = allUsers.where((member) {
                              if (_activePincode.isEmpty) return true;
                              final memberPin = member.pincode ?? '';
                              if (memberPin.isNotEmpty) {
                                return memberPin.contains(_activePincode);
                              }
                              return true;
                            }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDynamicFilterChips(
                                  filteredMembers,
                                  effectiveMatchedUsers,
                                  effectiveInviteList,
                                ),
                                SizedBox(height: 12.h),
                                Expanded(
                                  child: RefreshIndicator(
                                    color: const Color(0xFF0B4F4A),
                                    onRefresh: () async {
                                      ref.invalidate(addNetworkSerachProvider);
                                      ref.invalidate(getMatchContactProvider);
                                      await Future.wait([
                                        ref.read(
                                          addNetworkSerachProvider(
                                            _effectiveQuery,
                                          ).future,
                                        ),
                                        ref.read(
                                          getMatchContactProvider(
                                            _searchQuery,
                                          ).future,
                                        ),
                                      ]);
                                    },
                                    child: filteredMembers.isEmpty
                                        ? LayoutBuilder(
                                            builder: (context, constraints) =>
                                                SingleChildScrollView(
                                                  physics:
                                                      const AlwaysScrollableScrollPhysics(),
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      minHeight:
                                                          constraints.maxHeight,
                                                    ),
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .person_search_outlined,
                                                            size: 48.sp,
                                                            color:
                                                                Colors.white60,
                                                          ),
                                                          SizedBox(height: 8.h),
                                                          Text(
                                                            _isHindi
                                                                ? 'आपकी खोज से मेल खाता कोई सदस्य नहीं मिला।'
                                                                : 'No members found matching your search.',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14.sp,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          )
                                        : ListView.builder(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            itemCount: filteredMembers.length,
                                            itemBuilder: (context, index) {
                                              return _buildMemberCard(
                                                filteredMembers[index],
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDynamicFilterChips(
                                  [],
                                  effectiveMatchedUsers,
                                  effectiveInviteList,
                                ),
                                SizedBox(height: 12.h),
                                const Expanded(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          error: (error, stackTrace) {
                            return Center(
                              child: Text(
                                _isHindi
                                    ? 'डेटा लोड करने में त्रुटि आई'
                                    : 'Error loading data',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _normalizePhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('91') && clean.length == 12) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0') && clean.length == 11) {
      clean = clean.substring(1);
    } else if (clean.length > 10) {
      clean = clean.substring(clean.length - 10);
    }
    return clean;
  }

  Widget _buildMatchedContactsView(
    List<User> users,
    List<mcr.InviteItem> inviteList, {
    bool isLoading = false,
  }) {
    final totalCount = users.length + inviteList.length;

    final allPhones = <String>{
      for (final u in users)
        if (_normalizePhone(u.phone ?? _phoneByUserId[u.id] ?? '').isNotEmpty)
          _normalizePhone(u.phone ?? _phoneByUserId[u.id] ?? ''),
      for (final i in inviteList)
        if (_normalizePhone(i.phone ?? '').isNotEmpty)
          _normalizePhone(i.phone ?? ''),
    };

    final bool allSelected =
        allPhones.isNotEmpty && _selectedPhones.length == allPhones.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _isHindi
                    ? 'सहेजे गए संपर्क ($totalCount)'
                    : 'Saved Contacts ($totalCount)',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (totalCount > 0)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectMode = !_selectMode;
                        _selectedPhones.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _selectMode
                            ? Colors.white.withValues(alpha: 0.15)
                            : const Color(0xFFD32F2F).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: _selectMode
                              ? Colors.white30
                              : const Color(0xFFFF5252).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectMode
                                ? Icons.close_rounded
                                : Icons.delete_outline_rounded,
                            size: 14.sp,
                            color: _selectMode
                                ? Colors.white
                                : const Color(0xFFFF8A80),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _selectMode
                                ? (_isHindi ? 'रद्द करें' : 'Cancel')
                                : (_isHindi ? 'हटाएं' : 'Delete'),
                            style: TextStyle(
                              color: _selectMode
                                  ? Colors.white
                                  : const Color(0xFFFF8A80),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isMatchedViewActive = false;
                      _selectMode = false;
                      _selectedPhones.clear();
                      _memberSearchController.clear();
                      _searchQuery = '';
                    });
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 16.sp, color: Colors.white70),
                        SizedBox(width: 3.w),
                        Text(
                          _isHindi ? 'बंद करें' : 'Close',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_selectMode) ...[
          SizedBox(height: 10.h),
          _buildSelectionBar(allPhones, allSelected),
        ],
        SizedBox(height: 12.h),
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : (users.isEmpty && inviteList.isEmpty)
                  ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 48.sp,
                              color: Colors.white60,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? (_isHindi
                                      ? 'खोज "$_searchQuery" से मेल खाता कोई संपर्क नहीं मिला।'
                                      : 'No contacts found matching "$_searchQuery".')
                                  : (_isHindi
                                      ? 'कोई सहेजा गया संपर्क नहीं मिला।'
                                      : 'No saved contacts found.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _showCustomManualContactModal,
                                  icon: Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 16.sp,
                                    color: const Color(0xFF002E29),
                                  ),
                                  label: Text(
                                    _isHindi
                                        ? 'कस्टम संपर्क जोड़ें'
                                        : 'Add Custom Contact',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: const Color(0xFF002E29),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 10.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isMatchedViewActive = false;
                                      _memberSearchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white30),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 10.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: Text(
                                    _isHindi ? 'वापस जाएं' : 'Back',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF0B4F4A),
                      onRefresh: () async {
                        ref.invalidate(getMatchContactProvider);
                        await ref.read(
                          getMatchContactProvider(_searchQuery).future,
                        );
                      },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: users.length + inviteList.length,
                    itemBuilder: (context, index) {
                      if (index < users.length) {
                        final user = users[index];
                        final rawPhone =
                            user.phone ?? _phoneByUserId[user.id] ?? '';
                        final cleanPhone = _normalizePhone(rawPhone);
                        final isSelected =
                            cleanPhone.isNotEmpty &&
                            _selectedPhones.contains(cleanPhone);

                        return _buildMemberCard(
                          user,
                          isContactMatched: true,
                          isSelectMode: _selectMode,
                          isSelected: isSelected,
                          onSelectToggle: () {
                            if (cleanPhone.isEmpty) return;
                            setState(() {
                              if (_selectedPhones.contains(cleanPhone)) {
                                _selectedPhones.remove(cleanPhone);
                              } else {
                                _selectedPhones.add(cleanPhone);
                              }
                            });
                          },
                          onDirectDelete: () {
                            _confirmAndDeleteSingleContact(
                              phone: cleanPhone,
                              contactName: user.name ?? 'User',
                            );
                          },
                        );
                      } else {
                        final inviteIndex = index - users.length;
                        final item = inviteList[inviteIndex];
                        final cleanPhone = _normalizePhone(item.phone ?? '');
                        final isSelected =
                            cleanPhone.isNotEmpty &&
                            _selectedPhones.contains(cleanPhone);

                        return _buildInviteCard(
                          item,
                          isSelectMode: _selectMode,
                          isSelected: isSelected,
                          onSelectToggle: () {
                            if (cleanPhone.isEmpty) return;
                            setState(() {
                              if (_selectedPhones.contains(cleanPhone)) {
                                _selectedPhones.remove(cleanPhone);
                              } else {
                                _selectedPhones.add(cleanPhone);
                              }
                            });
                          },
                          onDirectDelete: () {
                            _confirmAndDeleteSingleContact(
                              phone: cleanPhone,
                              contactName: item.contactName ?? 'Contact',
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
        ),
        if (_selectMode && totalCount > 0) _buildBottomDeleteBar(),
      ],
    );
  }

  Widget _buildSelectionBar(Set<String> allPhones, bool allSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF003832),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF005B52).withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (allSelected) {
                  _selectedPhones.clear();
                } else {
                  _selectedPhones
                    ..clear()
                    ..addAll(allPhones);
                }
              });
            },
            borderRadius: BorderRadius.circular(6.r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: allSelected
                        ? const Color(0xFF00E676)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(5.r),
                    border: Border.all(
                      color: allSelected
                          ? const Color(0xFF00E676)
                          : Colors.white60,
                      width: 1.5,
                    ),
                  ),
                  child: allSelected
                      ? Icon(Icons.check, size: 14.sp, color: Colors.black87)
                      : null,
                ),
                SizedBox(width: 8.w),
                Text(
                  _isHindi ? 'सभी चुनें' : 'Select All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _selectedPhones.isNotEmpty
                  ? const Color(0xFF0B4F4A)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _selectedPhones.isNotEmpty
                    ? const Color(0xFF00E676).withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              _isHindi
                  ? '${_selectedPhones.length} चयनित'
                  : '${_selectedPhones.length} Selected',
              style: TextStyle(
                color: _selectedPhones.isNotEmpty
                    ? const Color(0xFF00E676)
                    : Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDeleteBar() {
    final bool canDelete = _selectedPhones.isNotEmpty && !_isDeleting;
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF00221E),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: canDelete
              ? const Color(0xFFD32F2F).withValues(alpha: 0.5)
              : Colors.white12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white70, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _selectedPhones.isEmpty
                  ? (_isHindi
                        ? 'हटाने के लिए संपर्क चुनें'
                        : 'Tap contacts to select')
                  : (_isHindi
                        ? '${_selectedPhones.length} संपर्क हटाने के लिए तैयार'
                        : '${_selectedPhones.length} contact(s) ready to delete'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton.icon(
            onPressed: canDelete ? _confirmAndDeleteSelected : null,
            icon: _isDeleting
                ? SizedBox(
                    width: 14.sp,
                    height: 14.sp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.delete_forever_rounded, size: 16.sp),
            label: Text(
              _isHindi
                  ? 'हटाएं (${_selectedPhones.length})'
                  : 'Delete (${_selectedPhones.length})',
              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              disabledBackgroundColor: Colors.white12,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white38,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
              elevation: canDelete ? 3 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteSingleContact({
    required String? phone,
    required String contactName,
  }) async {
    final cleanPhone = _normalizePhone(phone ?? '');
    if (cleanPhone.isEmpty) {
      showErrorSnackBar(
        _isHindi ? 'फ़ोन नंबर उपलब्ध नहीं है।' : 'Phone number not available.',
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF002E29),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFF005B52), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: const Color(0xFFFF5252),
                size: 22.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _isHindi ? 'संपर्क हटाएं?' : 'Delete Contact?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _isHindi
              ? 'क्या आप वाकई "$contactName" को अपने सहेजे गए संपर्कों से हटाना चाहते हैं?'
              : 'Are you sure you want to delete "$contactName" from your saved contacts?',
          style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _isHindi ? 'रद्द करें' : 'Cancel',
              style: TextStyle(color: Colors.white60, fontSize: 13.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              _isHindi ? 'हटाएं' : 'Delete',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _deletePhonesList([cleanPhone]);
    }
  }

  Future<void> _confirmAndDeleteSelected() async {
    final count = _selectedPhones.length;
    if (count == 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF002E29),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFF005B52), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: const Color(0xFFFF5252),
                size: 22.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _isHindi ? 'संपर्क हटाएं?' : 'Delete Contacts?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _isHindi
              ? 'क्या आप वाकई चुने गए $count संपर्कों को हटाना चाहते हैं?'
              : 'Are you sure you want to delete $count selected contact(s)?',
          style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _isHindi ? 'रद्द करें' : 'Cancel',
              style: TextStyle(color: Colors.white60, fontSize: 13.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              _isHindi ? 'हटाएं' : 'Delete',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _deletePhonesList(_selectedPhones.toList());
    }
  }

  Future<void> _deletePhonesList(List<String> rawPhones) async {
    final cleanPhones = rawPhones
        .map(_normalizePhone)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();

    if (cleanPhones.isEmpty) {
      showErrorSnackBar(
        _isHindi
            ? 'कोई मान्य फ़ोन नंबर नहीं मिला।'
            : 'No valid phone numbers found.',
      );
      return;
    }

    setState(() => _isDeleting = true);
    try {
      final res = await ref
          .read(authServiceProvider)
          .deleteContacts(cleanPhones);
      if (!mounted) return;

      final phoneSet = cleanPhones.toSet();

      setState(() {
        if (_matchedContactsUsers != null) {
          _matchedContactsUsers = _matchedContactsUsers!.where((u) {
            final ph = _normalizePhone(u.phone ?? _phoneByUserId[u.id] ?? '');
            return !phoneSet.contains(ph);
          }).toList();
        }
        if (_matchedInviteList != null) {
          _matchedInviteList = _matchedInviteList!
              .where(
                (item) => !phoneSet.contains(_normalizePhone(item.phone ?? '')),
              )
              .toList();
        }
        _selectedPhones.removeWhere(
          (p) => phoneSet.contains(_normalizePhone(p)),
        );
        if (_selectedPhones.isEmpty) {
          _selectMode = false;
        }
      });

      ref.invalidate(getMatchContactProvider);

      showSuccessSnackBar(
        res.message ??
            (_isHindi
                ? '${res.deletedCount ?? cleanPhones.length} संपर्क सफलतापूर्वक हटा दिए गए।'
                : '${res.deletedCount ?? cleanPhones.length} contact(s) deleted successfully.'),
      );
    } catch (e) {
      log('Error deleting contacts: $e');
      if (!mounted) return;
      showErrorSnackBar(
        _isHindi ? 'संपर्क हटाने में विफल रहा।' : 'Failed to delete contacts.',
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _buildDynamicFilterChips(
    List<User> users,
    List<User> matchedUsers,
    List<mcr.InviteItem> inviteList,
  ) {
    final Set<String> states = {};
    final Set<String> cities = {};

    for (var u in users) {
      if (u.state != null && u.state!.trim().isNotEmpty) {
        states.add(u.state!.trim());
      }
      if (u.city != null && u.city!.trim().isNotEmpty) {
        cities.add(u.city!.trim());
      }
    }

    final totalMatched = matchedUsers.length + inviteList.length;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        if (totalMatched > 0)
          InkWell(
            onTap: () {
              setState(() {
                _isMatchedViewActive = !_isMatchedViewActive;
                _memberSearchController.clear();
                _searchQuery = '';
              });
            },
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: _isMatchedViewActive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.contact_phone,
                    size: 14.sp,
                    color: _isMatchedViewActive
                        ? Colors.white
                        : const Color(0xFF2E7D32),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _isHindi
                        ? 'फ़ोन संपर्क ($totalMatched)'
                        : 'Contacts ($totalMatched)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: _isMatchedViewActive
                          ? Colors.white
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _buildInfoChip(
          _isHindi ? 'पिन कोड' : 'Pin Code',
          _activePincode.isEmpty ? (_isHindi ? 'सभी' : 'All') : _activePincode,
        ),
        if (_searchQuery.isNotEmpty)
          _buildInfoChip(_isHindi ? 'खोज' : 'Search', _searchQuery),
        if (states.isNotEmpty)
          _buildInfoChip(
            _isHindi ? 'राज्य' : 'State',
            states.take(2).join(', '),
          ),
        if (cities.isNotEmpty)
          _buildInfoChip(_isHindi ? 'शहर' : 'City', cities.take(2).join(', ')),
        _buildInfoChip(_isHindi ? 'सदस्य' : 'Members', '${users.length}'),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E7EE)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13.sp, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.black54),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    User member, {
    bool isContactMatched = false,
    bool isSelectMode = false,
    bool isSelected = false,
    VoidCallback? onSelectToggle,
    VoidCallback? onDirectDelete,
  }) {
    final String name = member.name ?? 'Unknown User';
    final String profileImage = member.profileImage ?? '';

    final String initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((word) => word.isNotEmpty ? word[0] : '')
              .join()
              .toUpperCase();

    final String status = (member.requestStatus ?? '').toLowerCase().trim();
    final bool isPending =
        status == 'pending' ||
        (member.id != null && _pendingUserIds.contains(member.id));
    final bool isConnected = status == 'connected';
    final bool isLoading =
        member.id != null && _loadingUserIds.contains(member.id);

    final bool isFromPhoneContacts =
        isContactMatched ||
        (_matchedContactsUsers != null &&
            _matchedContactsUsers!.any(
              (u) => u.id != null && u.id == member.id,
            ));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: isSelectMode ? onSelectToggle : null,
        onLongPress: isContactMatched ? onSelectToggle : null,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : const Color(0xFFDCDFE4),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF00E676).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: const Color(0xFF0B4F4A),
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage.isEmpty
                        ? Text(
                            initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (member.isVerified == true) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.verified,
                            color: const Color(0xFF0B8F68),
                            size: 16.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isFromPhoneContacts) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call,
                            size: 11.sp,
                            color: const Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _isHindi ? 'संपर्क में' : 'In Contacts',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isContactMatched) ...[
                    if (isSelectMode) ...[
                      SizedBox(width: 8.w),
                      Container(
                        width: 22.w,
                        height: 22.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E676)
                                : Colors.black26,
                            width: 1.8,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 14.sp,
                                color: Colors.black87,
                              )
                            : null,
                      ),
                    ] else ...[
                      SizedBox(width: 6.w),
                      InkWell(
                        onTap: onDirectDelete,
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.all(5.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 17.sp,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              SizedBox(height: 14.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: 40.h),
                          child: isConnected
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: const Color(0xFF81C784),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16.sp,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                      SizedBox(width: 5.w),
                                      Text(
                                        _isHindi ? 'जुड़े हुए' : 'Connected',
                                        style: TextStyle(
                                          color: const Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : isPending
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 15.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                      SizedBox(width: 5.w),
                                      Text(
                                        _isHindi ? 'लंबित' : 'Pending',
                                        style: TextStyle(
                                          color: const Color(0xFF475569),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (member.id == null) return;
                                          setState(() {
                                            _loadingUserIds.add(member.id!);
                                          });
                                          try {
                                            final service = ref.read(
                                              authServiceProvider,
                                            );
                                            final res = await service
                                                .sendRequest(
                                                  id: member.id.toString(),
                                                );
                                            if (res.success == true &&
                                                context.mounted) {
                                              setState(() {
                                                _pendingUserIds.add(member.id!);
                                                member.requestStatus =
                                                    'pending';
                                              });
                                              ref.invalidate(
                                                addNetworkSerachProvider,
                                              );
                                              showSuccessSnackBar(
                                                _isHindi
                                                    ? '$name को कनेक्शन अनुरोध भेजा गया!'
                                                    : 'Connection request sent to $name!',
                                              );
                                            } else if (context.mounted &&
                                                res.message != null &&
                                                res.message!.isNotEmpty) {
                                              showErrorSnackBar(res.message!);
                                            }
                                          } catch (e) {
                                            log(e.toString());
                                            if (context.mounted) {
                                              showErrorSnackBar(
                                                _isHindi
                                                    ? 'अनुरोध भेजने में विफल रहा।'
                                                    : 'Failed to send request.',
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() {
                                                _loadingUserIds.remove(
                                                  member.id!,
                                                );
                                              });
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B4F4A),
                                    disabledBackgroundColor: const Color(
                                      0xFF0B4F4A,
                                    ).withValues(alpha: 0.7),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: isLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 14.w,
                                              height: 14.w,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              _isHindi
                                                  ? 'भेज रहे हैं...'
                                                  : 'Sending...',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_add_alt_1,
                                              size: 16.sp,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 5.w),
                                            Text(
                                              _isHindi ? 'जोड़ें' : 'Connect',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: 40.h),
                          child: isConnected
                              ? ElevatedButton.icon(
                                  onPressed: () {
                                    _openChatScreen(member);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B4F4A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16.sp,
                                  ),
                                  label: Text(
                                    _isHindi ? 'चैट' : 'Chat',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () {
                                    if (isPending) {
                                      showErrorSnackBar(
                                        _isHindi
                                            ? 'कनेक्शन अनुरोध स्वीकार होने के बाद ही आप संदेश भेज सकते हैं।'
                                            : 'You can chat once the connection request is accepted.',
                                      );
                                    } else {
                                      showErrorSnackBar(
                                        _isHindi
                                            ? 'चैट करने के लिए पहले कनेक्शन अनुरोध भेजें।'
                                            : 'Send a connection request first to chat.',
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    foregroundColor: const Color(0xFF94A3B8),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  icon: Icon(
                                    isPending
                                        ? Icons.lock_clock_outlined
                                        : Icons.lock_outline,
                                    size: 15.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  label: Text(
                                    _isHindi ? 'चैट' : 'Chat',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 18.sp),
                      SizedBox(width: 4.w),
                      Text(
                        "Current:",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          [
                                member.currentAddress,
                                member.city,
                                member.state,
                                member.country,
                                member.pincode,
                              ]
                              .where((e) => e != null && e.trim().isNotEmpty)
                              .join(', '),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendNativeSmsInvite({
    required String contactName,
    required String phone,
    String? inviteMessage,
  }) async {
    const String defaultLink =
        'https://play.google.com/store/apps/details?id=com.trackloved.app';

    final String textToSend =
        (inviteMessage != null && inviteMessage.trim().isNotEmpty)
        ? inviteMessage
        : (_isHindi
              ? 'नमस्ते $contactName! मैं Track Loved One ऐप का उपयोग कर रहा हूँ ताकि हम अपने प्रियजनों और समुदाय से जुड़े रह सकें। आप भी इस ऐप को डाउनलोड करें और मुझसे जुड़ें:\n$defaultLink'
              : 'Hello $contactName! I am using the Track Loved One app to stay connected with family, friends, and community. Download the app today and connect with me:\n$defaultLink');

    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '+91$cleanPhone';
    }

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{'body': textToSend},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await _sendWhatsAppInvite(
          contactName: contactName,
          phone: phone,
          inviteMessage: inviteMessage,
        );
      }
    } catch (e) {
      log('Error launching SMS wrapper: $e');
      await _sendWhatsAppInvite(
        contactName: contactName,
        phone: phone,
        inviteMessage: inviteMessage,
      );
    }
  }

  Future<void> _sendWhatsAppInvite({
    required String contactName,
    required String phone,
    String? inviteMessage,
  }) async {
    const String defaultLink =
        'https://play.google.com/store/apps/details?id=com.trackloved.app';

    final String textToSend =
        (inviteMessage != null && inviteMessage.trim().isNotEmpty)
        ? inviteMessage.trim()
        : (_isHindi
              ? 'नमस्ते $contactName! मैं Track Loved One ऐप का उपयोग कर रहा हूँ ताकि हम अपने प्रियजनों और समुदाय से जुड़े रह सकें। आप भी इस ऐप को डाउनलोड करें और मुझसे जुड़ें:\n$defaultLink'
              : 'Hello $contactName! I am using the Track Loved One app to stay connected with family, friends, and community. Download the app today and connect with me:\n$defaultLink');

    // Normalize phone number (keep digits only)
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      cleanPhone = cleanPhone.substring(1);
    }
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    } else if (cleanPhone.startsWith('091') && cleanPhone.length == 13) {
      cleanPhone = cleanPhone.substring(1);
    }

    final String encodedText = Uri.encodeComponent(textToSend);

    // 1. Direct WhatsApp Custom Scheme URI (opens WhatsApp chat directly)
    final Uri whatsappSchemeUri = cleanPhone.isNotEmpty
        ? Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText')
        : Uri.parse('whatsapp://send?text=$encodedText');

    // 2. WhatsApp Web / Universal URI fallback
    final Uri waMeUri = cleanPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$cleanPhone?text=$encodedText')
        : Uri.parse('https://wa.me/?text=$encodedText');

    final Uri apiWhatsappUri = cleanPhone.isNotEmpty
        ? Uri.parse(
            'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedText',
          )
        : Uri.parse('https://api.whatsapp.com/send?text=$encodedText');

    try {
      // First try opening directly inside WhatsApp app via whatsapp:// scheme
      if (await canLaunchUrl(whatsappSchemeUri)) {
        await launchUrl(
          whatsappSchemeUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }
    } catch (e) {
      log('whatsapp:// direct scheme error: $e');
    }

    try {
      // Second try via wa.me link
      if (await canLaunchUrl(waMeUri)) {
        await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      log('wa.me error: $e');
    }

    try {
      // Third try via api.whatsapp.com
      if (await canLaunchUrl(apiWhatsappUri)) {
        await launchUrl(apiWhatsappUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      log('api.whatsapp.com error: $e');
    }

    // If WhatsApp cannot be launched, fallback to Native SMS
    await _sendNativeSmsInvite(
      contactName: contactName,
      phone: phone,
      inviteMessage: inviteMessage,
    );
  }

  Widget _buildInviteCard(
    mcr.InviteItem item, {
    bool isSelectMode = false,
    bool isSelected = false,
    VoidCallback? onSelectToggle,
    VoidCallback? onDirectDelete,
  }) {
    final String contactName = item.contactName ?? 'Contact';
    final String phone = item.phone ?? '';
    final String phoneKey = phone.isNotEmpty ? phone : contactName;
    final bool isInvited = _invitedPhoneNumbers.contains(phoneKey);

    final String initials = contactName.trim().isEmpty
        ? '?'
        : contactName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((word) => word.isNotEmpty ? word[0] : '')
              .join()
              .toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: isSelectMode ? onSelectToggle : null,
        onLongPress: onSelectToggle,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFF003832),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : const Color(0xFF005B52).withValues(alpha: 0.6),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF00E676).withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFF0B4F4A),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contactName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phone.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.call, size: 11.sp, color: Colors.white70),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              phone.startsWith('+') ? phone : '+91 $phone',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: 36.h),
                child: isInvited
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004D40),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(color: const Color(0xFF00897B)),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 14.sp, color: Colors.white),
                            SizedBox(width: 4.w),
                            Text(
                              _isHindi ? 'आमंत्रित' : 'Invited',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _invitedPhoneNumbers.add(phoneKey);
                          });
                          await _sendWhatsAppInvite(
                            contactName: contactName,
                            phone: phone,
                            inviteMessage: item.inviteMessage,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                        ),
                        icon: Icon(
                          Icons.person_add,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isHindi ? 'आमंत्रित करें' : 'Invite',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              if (isSelectMode) ...[
                SizedBox(width: 8.w),
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF00E676)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : Colors.white38,
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 14.sp, color: Colors.black87)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
