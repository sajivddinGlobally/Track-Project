import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
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
            contactItems.add(ContactItem(name: name, phone: cleaned));
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
          MatchContactsBodyModel(contacts: batch),
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

  void _showImportContactsModal() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isHindi ? 'संपर्क आयात करें' : 'Import Contacts',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _isHindi
                        ? 'चुनें कि आप अपने संपर्क कहाँ से सिंक करना चाहते हैं:'
                        : 'Choose where you want to sync your contacts from:',
                    style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                  ),
                  SizedBox(height: 20.h),
                  if (isLoading)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF0B4F4A),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              _isHindi
                                  ? 'संपर्क मैच किए जा रहे हैं...'
                                  : 'Matching contacts on Track Loved...',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF0B4F4A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEBF2FA),
                        child: Icon(
                          Icons.phone_android,
                          color: const Color(0xFF0B4F4A),
                          size: 22.sp,
                        ),
                      ),
                      title: Text(
                        _isHindi ? 'फ़ोन संपर्क' : 'Phone Contacts',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        _isHindi
                            ? 'स्थानीय डिवाइस संपर्क सिंक करें और मैच करें'
                            : 'Sync & match local device contacts',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      onTap: () {
                        _handleMatchContacts(
                          isGoogle: false,
                          setModalState: setModalState,
                          setLoading: (v) => isLoading = v,
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEBF2FA),
                        child: Icon(
                          Icons.g_mobiledata,
                          color: const Color(0xFF1565C0),
                          size: 32.sp,
                        ),
                      ),
                      title: Text(
                        _isHindi ? 'गूगल संपर्क' : 'Google Contacts',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        _isHindi
                            ? 'Google खाते से संपर्क सिंक करें और मैच करें'
                            : 'Sync & match contacts from Google account',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      onTap: () {
                        _handleMatchContacts(
                          isGoogle: true,
                          setModalState: setModalState,
                          setLoading: (v) => isLoading = v,
                        );
                      },
                    ),
                  ],
                  SizedBox(height: 10.h),
                ],
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
    final addNetwork = ref.watch(addNetworkSerachProvider(_effectiveQuery));
    final contactState = ref.watch(getMatchContactProvider);

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
          ),
        )
        .toList();
    final apiInviteList = matchData?.inviteList ?? [];
    for (final c in matchData?.contacts ?? <mcr.Contact>[]) {
      final uid = c.user?.userId;
      final ph = c.matchedPhone;
      if (uid != null && ph != null && ph.isNotEmpty) {
        _phoneByUserId[uid] = ph;
      }
    }

    final effectiveMatchedUsers = _matchedContactsUsers ?? apiContacts;
    final effectiveInviteList = _matchedInviteList ?? apiInviteList;

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
                      child: TextField(
                        controller: _memberSearchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.black45,
                            size: 20.sp,
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 40.w,
                            minHeight: 0,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.r),
                            borderSide: BorderSide.none,
                          ),
                          hintText: _isHindi
                              ? 'नाम, भूमिका, शहर या पिनकोड से खोजें...'
                              : 'Search members by name, role, city, pincode...',
                          hintStyle: TextStyle(
                            color: Colors.black45,
                            fontSize: 14.sp,
                          ),
                          suffixIcon: _memberSearchController.text.isNotEmpty
                              ? IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.clear,
                                    size: 18.sp,
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
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: _showImportContactsModal,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        constraints: BoxConstraints(minHeight: 45.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B4F4A),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.contact_page_sharp,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              _isHindi ? 'संपर्क' : 'Contacts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
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
                  child:
                      _isMatchedViewActive &&
                          (effectiveMatchedUsers.isNotEmpty ||
                              effectiveInviteList.isNotEmpty)
                      ? _buildMatchedContactsView(
                          effectiveMatchedUsers,
                          effectiveInviteList,
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
                                          getMatchContactProvider.future,
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

  Widget _buildMatchedContactsView(
    List<User> users,
    List<mcr.InviteItem> inviteList,
  ) {
    final totalCount = users.length + inviteList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isHindi
                  ? 'मिलान करने वाले सदस्य ($totalCount)'
                  : 'Matching Members ($totalCount)',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      child: Text(
                        _selectMode
                            ? (_isHindi ? 'रद्द करें' : 'Cancel')
                            : (_isHindi ? 'चुनें' : 'Select'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isMatchedViewActive = false;
                      _selectMode = false;
                      _selectedPhones.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 16.sp, color: Colors.white70),
                        SizedBox(width: 4.w),
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
        if (_selectMode) _buildSelectionBar(users, inviteList),
        SizedBox(height: 14.h),
        Expanded(
          child: (users.isEmpty && inviteList.isEmpty)
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
                          _isHindi
                              ? 'आपके संपर्कों में से कोई भी सदस्य नहीं मिला।'
                              : 'No members found matching your contacts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isMatchedViewActive = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B4F4A),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _isHindi
                                ? 'सामान्य खोज पर वापस जाएं'
                                : 'Back to General Search',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF0B4F4A),
                  onRefresh: () async {
                    ref.invalidate(getMatchContactProvider);
                    await ref.read(getMatchContactProvider.future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: users.length + inviteList.length,
                    itemBuilder: (context, index) {
                      final String? phone = index < users.length
                          ? _phoneByUserId[users[index].id]
                          : inviteList[index - users.length].phone;
                      final Widget card = index < users.length
                          ? _buildMemberCard(
                              users[index],
                              isContactMatched: true,
                            )
                          : _buildInviteCard(inviteList[index - users.length]);
                      if (!_selectMode) return card;
                      final bool checked =
                          phone != null && _selectedPhones.contains(phone);
                      return Row(
                        children: [
                          Checkbox(
                            value: checked,
                            activeColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Colors.white70),
                            onChanged: phone == null
                                ? null
                                : (v) => setState(() {
                                    v == true
                                        ? _selectedPhones.add(phone)
                                        : _selectedPhones.remove(phone);
                                  }),
                          ),
                          Expanded(child: card),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSelectionBar(List<User> users, List<mcr.InviteItem> inviteList) {
    final allPhones = <String>{
      for (final u in users)
        if (_phoneByUserId[u.id] != null) _phoneByUserId[u.id]!,
      for (final i in inviteList)
        if (i.phone != null && i.phone!.isNotEmpty) i.phone!,
    };
    final allSelected =
        allPhones.isNotEmpty && _selectedPhones.containsAll(allPhones);

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            activeColor: const Color(0xFF2E7D32),
            side: const BorderSide(color: Colors.white70),
            onChanged: (v) => setState(() {
              _selectedPhones
                ..clear()
                ..addAll(v == true ? allPhones : <String>{});
            }),
          ),
          Expanded(
            child: Text(
              _isHindi
                  ? 'सभी चुनें (${_selectedPhones.length} चयनित)'
                  : 'Select all (${_selectedPhones.length} selected)',
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _selectedPhones.isEmpty || _isDeleting
                ? null
                : _confirmAndDeleteSelected,
            icon: _isDeleting
                ? SizedBox(
                    width: 14.sp,
                    height: 14.sp,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.delete_outline, size: 16.sp),
            label: Text(_isHindi ? 'हटाएं' : 'Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteSelected() async {
    final count = _selectedPhones.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isHindi ? 'संपर्क हटाएं?' : 'Remove contacts?'),
        content: Text(
          _isHindi
              ? '$count संपर्क हटाए जाएंगे।'
              : '$count contact(s) will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isHindi ? 'रद्द करें' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _isHindi ? 'हटाएं' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final res = await ref
          .read(authServiceProvider)
          .deleteContacts(_selectedPhones.toList());
      if (!mounted) return;
      setState(() {
        _matchedContactsUsers = null;
        _matchedInviteList = null;
        _selectedPhones.clear();
        _selectMode = false;
      });
      ref.invalidate(getMatchContactProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.message ??
                (_isHindi ? 'संपर्क हटा दिए गए' : 'Contacts removed'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi ? 'संपर्क हटाने में विफल' : 'Failed to remove contacts',
          ),
        ),
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

  Widget _buildMemberCard(User member, {bool isContactMatched = false}) {
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

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDCDFE4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
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
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
                                        final res = await service.sendRequest(
                                          id: member.id.toString(),
                                        );
                                        if (res.success == true &&
                                            context.mounted) {
                                          setState(() {
                                            _pendingUserIds.add(member.id!);
                                            member.requestStatus = 'pending';
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
                                            _loadingUserIds.remove(member.id!);
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
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
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
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
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
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
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
                      "${member.campusLocation},${member.city},${member.state},${member.country},${member.pincode}",
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
    );
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
        ? inviteMessage
        : (_isHindi
              ? 'नमस्ते $contactName! मैं Track Loved One ऐप का उपयोग कर रहा हूँ ताकि हम अपने प्रियजनों और समुदाय से जुड़े रह सकें। आप भी इस ऐप को डाउनलोड करें और मुझसे जुड़ें:\n$defaultLink'
              : 'Hello $contactName! I am using the Track Loved One app to stay connected with family, friends, and community. Download the app today and connect with me:\n$defaultLink');

    // Normalize phone number (keep digits only)
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final String encodedText = Uri.encodeComponent(textToSend);
    final Uri waMeUri = cleanPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$cleanPhone?text=$encodedText')
        : Uri.parse('https://wa.me/?text=$encodedText');

    try {
      if (await canLaunchUrl(waMeUri)) {
        await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
      } else {
        final Uri whatsappSchemeUri = Uri.parse(
          cleanPhone.isNotEmpty
              ? 'whatsapp://send?phone=$cleanPhone&text=$encodedText'
              : 'whatsapp://send?text=$encodedText',
        );
        final bool schemeLaunched = await launchUrl(
          whatsappSchemeUri,
          mode: LaunchMode.externalApplication,
        );
        if (!schemeLaunched && mounted) {
          showErrorSnackBar(
            _isHindi
                ? 'व्हाट्सएप नहीं खोला जा सका। कृपया सुनिश्चित करें कि व्हाट्सएप इंस्टॉल है।'
                : 'Could not open WhatsApp. Please ensure WhatsApp is installed.',
          );
        }
      }
    } catch (e) {
      log('Error launching WhatsApp: $e');
      if (mounted) {
        showErrorSnackBar(
          _isHindi
              ? 'व्हाट्सएप नहीं खोला जा सका। कृपया सुनिश्चित करें कि व्हाट्सएप इंस्टॉल है।'
              : 'Could not open WhatsApp. Please ensure WhatsApp is installed.',
        );
      }
    }
  }

  Widget _buildInviteCard(mcr.InviteItem item) {
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

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF003832),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF005B52).withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF003832),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
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
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      _isHindi ? 'ऑनलाइन' : 'Online',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF00E676),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (phone.isNotEmpty) ...[
                  SizedBox(height: 3.h),
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
                      size: 15.sp,
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
        ],
      ),
    );
  }
}
