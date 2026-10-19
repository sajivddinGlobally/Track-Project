import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:track_loved/HomeScreen/DashboardScreen.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/ProfileScreen/provider/getMyProfileProvider.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/BodyModel/UpdateProfileBodyModel.dart';
import 'package:track_loved/core/Data/ResponseModel/getMyProfileModel.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isHindi = false;

  String _userName = '';
  String _userEmail = '';
  bool _isUserVerified = false;
  bool _isInitialDataLoaded = false;
  bool _isSaving = false;

  File? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();

  // String _selectedAvatarUrl =
  //     'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80';
  String _selectedAvatarUrl = '';
  bool _isGoogleAvatar = true;

  /*
  final List<String> _googlePhotos = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
  ];
  */

  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(
    text: 'India',
  );
  final TextEditingController _villageTownController = TextEditingController();

  final FocusNode _schoolFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _yearFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _currentAddressFocusNode = FocusNode();
  final FocusNode _permanentAddressFocusNode = FocusNode();

  final FocusNode _professionFocusNode = FocusNode();
  final FocusNode _educationFocusNode = FocusNode();
  final FocusNode _bioFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _stateFocusNode = FocusNode();
  final FocusNode _pincodeFocusNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();
  final FocusNode _villageTownFocusNode = FocusNode();

  final TextEditingController _mobileController = TextEditingController();
  bool _isMobileVerified = false;

  final TextEditingController _currentAddressController =
      TextEditingController();
  final TextEditingController _permanentAddressController =
      TextEditingController();

  bool _sameAsCurrentAddress = false;
  bool _isFormValid = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _schoolController.addListener(_validateForm);
    _locationController.addListener(_validateForm);
    _yearController.addListener(_validateForm);
    _mobileController.addListener(_validateForm);
    _currentAddressController.addListener(_validateForm);
    _permanentAddressController.addListener(_validateForm);
    _cityController.addListener(_validateForm);
    _stateController.addListener(_validateForm);
    _pincodeController.addListener(_validateForm);
    _countryController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid =
        _schoolController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty &&
        _yearController.text.trim().isNotEmpty &&
        _mobileController.text.trim().isNotEmpty &&
        _currentAddressController.text.trim().isNotEmpty &&
        _permanentAddressController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _stateController.text.trim().isNotEmpty &&
        _pincodeController.text.trim().isNotEmpty &&
        _countryController.text.trim().isNotEmpty &&
        _isMobileVerified;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _populateUserData(User user) {
    _userName = user.name ?? '';
    _userEmail = user.email ?? '';
    _isUserVerified = user.isVerified ?? false;

    if (user.profileImage != null && user.profileImage!.trim().isNotEmpty) {
      _selectedAvatarUrl = user.profileImage!;
      _isGoogleAvatar = false;
    }

    // Only populate if available in API, otherwise keep blank
    if (user.school != null && user.school!.trim().isNotEmpty) {
      _schoolController.text = user.school!;
    } else if (user.college != null && user.college!.trim().isNotEmpty) {
      _schoolController.text = user.college!;
    }

    if (user.campusLocation != null && user.campusLocation!.trim().isNotEmpty) {
      _locationController.text = user.campusLocation!;
    }

    if (user.graduationYear != null && user.graduationYear!.trim().isNotEmpty) {
      _yearController.text = user.graduationYear!;
    }

    if (user.phone != null && user.phone!.trim().isNotEmpty) {
      _mobileController.text = user.phone!;
    }
    _isMobileVerified = user.isVerified ?? false;

    if (user.currentAddress != null && user.currentAddress!.trim().isNotEmpty) {
      _currentAddressController.text = user.currentAddress!;
    }

    if (user.permanentAddress != null &&
        user.permanentAddress!.trim().isNotEmpty) {
      _permanentAddressController.text = user.permanentAddress!;
    }

    if (user.profession != null && user.profession!.trim().isNotEmpty) {
      _professionController.text = user.profession!;
    }
    if (user.education != null && user.education!.trim().isNotEmpty) {
      _educationController.text = user.education!;
    }
    if (user.bio != null && user.bio!.trim().isNotEmpty) {
      _bioController.text = user.bio!;
    }
    if (user.city != null && user.city!.trim().isNotEmpty) {
      _cityController.text = user.city!;
    }
    if (user.state != null && user.state!.trim().isNotEmpty) {
      _stateController.text = user.state!;
    }
    if (user.country != null && user.country!.trim().isNotEmpty) {
      _countryController.text = user.country!;
    }
    if (user.pincode != null && user.pincode!.trim().isNotEmpty) {
      _pincodeController.text = user.pincode!;
    }
    if (user.villageTown != null && user.villageTown!.trim().isNotEmpty) {
      _villageTownController.text = user.villageTown!;
    }

    if (mounted) {
      setState(() {});
      _validateForm();
    }
  }

  @override
  void dispose() {
    _schoolFocusNode.dispose();
    _locationFocusNode.dispose();
    _yearFocusNode.dispose();
    _mobileFocusNode.dispose();
    _currentAddressFocusNode.dispose();
    _permanentAddressFocusNode.dispose();
    _professionFocusNode.dispose();
    _educationFocusNode.dispose();
    _bioFocusNode.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    _pincodeFocusNode.dispose();
    _countryFocusNode.dispose();
    _villageTownFocusNode.dispose();

    _schoolController.dispose();
    _locationController.dispose();
    _yearController.dispose();
    _mobileController.dispose();
    _currentAddressController.dispose();
    _permanentAddressController.dispose();
    _professionController.dispose();
    _educationController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _villageTownController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
          _isGoogleAvatar = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isHindi
                    ? 'फ़ोटो सफलतापूर्वक चुनी गई!'
                    : 'Photo selected successfully!',
              ),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerModal() {
    /*
    // Previous modal code commented out as requested:
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F3D38),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isHindi ? 'प्रोफ़ाइल विकल्प' : 'Profile Options',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF072420),
                    child: Icon(
                      Icons.dashboard_outlined,
                      color: Color(0xFFD4AF37),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    _isHindi ? 'डैशबोर्ड पर जाएं' : 'Go to Dashboard',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _isHindi
                        ? 'मुख्य डैशबोर्ड दृश्य पर लौटें'
                        : 'Return to the main dashboard view',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF072420),
                    child: Icon(
                      Icons.g_mobiledata,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    _isHindi
                        ? 'गूगल खाते से चुनें'
                        : 'Pick from Google Account',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _isHindi
                        ? 'अपनी सिंक की गई गूगल तस्वीरों में से चुनें'
                        : 'Choose from your synced Google photos',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showGooglePhotoSelector();
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF072420),
                    child: Icon(
                      Icons.upload_file,
                      color: Colors.brown,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    _isHindi ? 'डिवाइस से अपलोड करें' : 'Upload from Device',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _isHindi
                        ? 'गैलरी या फ़ाइलों से चुनें'
                        : 'Choose from Gallery or Files',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedAvatarUrl =
                          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=300&q=80';
                      _isGoogleAvatar = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isHindi
                              ? 'डिवाइस से फोटो अपलोड हो गई!'
                              : 'Photo uploaded from device!',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF072420),
                    child: Icon(
                      Icons.logout,
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _isHindi ? 'लॉग आउट' : 'Log Out',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _isHindi
                        ? 'अपने खाते से साइन आउट करें'
                        : 'Sign out of your account',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    */

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F3D38),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isHindi ? 'फ़ोटो चुनें' : 'Select Photo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF072420),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFD4AF37),
                    size: 22,
                  ),
                ),
                title: Text(
                  _isHindi ? 'कैमरा' : 'Camera',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _isHindi
                      ? 'कैमरे से नई फ़ोटो लें'
                      : 'Take a photo using camera',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF072420),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFD4AF37),
                    size: 22,
                  ),
                ),
                title: Text(
                  _isHindi ? 'गैलरी' : 'Gallery',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _isHindi
                      ? 'फ़ोन गैलरी से फ़ोटो चुनें'
                      : 'Choose photo from gallery',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /*
  void _showGooglePhotoSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFF0F3D38),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.g_mobiledata,
                    color: Color(0xFFD4AF37),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isHindi
                        ? 'गूगल खाता फोटो चुनें'
                        : 'Select Google Account Photo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: _googlePhotos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final photoUrl = _googlePhotos[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatarUrl = photoUrl;
                        _isGoogleAvatar = true;
                      });
                      Navigator.pop(context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(photoUrl, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  */

  void _showOtpVerificationDialog() {
    final TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F3D38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            _isHindi ? 'मोबाइल नंबर सत्यापित करें' : 'Verify Mobile Number',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isHindi
                    ? '${_mobileController.text} पर भेजा गया 4-अंकों का OTP दर्ज करें'
                    : 'Enter the 4-digit OTP sent to ${_mobileController.text}',
                style: TextStyle(color: Colors.white70, fontSize: 13.5.sp),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  labelText: _isHindi ? 'OTP कोड' : 'OTP Code',
                  labelStyle: TextStyle(
                    color: Colors.white60,
                    fontSize: 13.5.sp,
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
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _isHindi ? 'रद्द करें' : 'Cancel',
                style: TextStyle(color: Colors.white60, fontSize: 14.sp),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () {
                if (otpController.text.length == 4) {
                  setState(() {
                    _isMobileVerified = true;
                  });
                  _validateForm();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isHindi
                            ? 'मोबाइल नंबर सफलतापूर्वक सत्यापित हुआ!'
                            : 'Mobile number verified successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isHindi
                            ? 'कृपया वैध 4-अंकों का OTP दर्ज करें।'
                            : 'Please enter a valid 4-digit OTP.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(
                _isHindi ? 'सत्यापित करें' : 'Verify',
                style: const TextStyle(
                  color: Color(0xFF072420),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(getMyProfileProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F3D38), Color(0xFF072420), Color(0xFF031210)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ToggleButtons(
                        constraints: const BoxConstraints(
                          minHeight: 32,
                          minWidth: 60,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        selectedColor: Color(0xFF072420),
                        fillColor: const Color(0xFFD4AF37),
                        color: Colors.white,
                        isSelected: [!_isHindi, _isHindi],
                        onPressed: (int index) {
                          setState(() {
                            _isHindi = index == 1;
                          });
                        },
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'Eng',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'हिंदी',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _isHindi ? 'प्रोफ़ाइल पेज' : 'Profile Page',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: asyncState.when(
                    data: (data) {
                      final user = data.data?.user;
                      if (user != null && !_isInitialDataLoaded) {
                        _isInitialDataLoaded = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _populateUserData(user);
                          }
                        });
                      }
                      return Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 35),
                            _buildHeaderProfileCard(user),
                            const SizedBox(height: 16),
                            _buildMandatoryInfoCard(),
                            const SizedBox(height: 16),
                            _buildContactInfoCard(),
                            const SizedBox(height: 16),
                            _buildAddressCard(),
                            const SizedBox(height: 24),
                            _buildSaveButtonAndLogout(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                    error: (error, stackTrace) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            error.toString(),
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      );
                    },
                    loading: () {
                      return SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height / 1.4,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderProfileCard([User? user]) {
    final displayName = (user?.name != null && user!.name!.trim().isNotEmpty)
        ? user.name!
        : (_userName.isNotEmpty ? _userName : 'User');
    final displayEmail = (user?.email != null && user!.email!.trim().isNotEmpty)
        ? user.email!
        : _userEmail;
    final isVerified = user?.isVerified ?? _isUserVerified;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: Color(0xFFD4AF37),
                      size: 18,
                    ),
                  ],
                ],
              ),
              if (displayEmail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: const TextStyle(fontSize: 13, color: Colors.white60),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isGoogleAvatar ? Icons.g_mobiledata : Icons.upload_file,
                    color: _isGoogleAvatar ? Colors.redAccent : Colors.white70,
                    size: 20,
                  ),
                  Text(
                    _isGoogleAvatar
                        ? (_isHindi ? 'गूगल से जुड़ा है' : 'Linked to Google')
                        : (_isHindi
                              ? 'कस्टम अपलोड की गई फोटो'
                              : 'Custom Uploaded Photo'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isGoogleAvatar
                          ? const Color(0xFFD4AF37)
                          : Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: _showImagePickerModal,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Image.file(
                            _pickedImageFile!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Image.network(
                            _selectedAvatarUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF072420),
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMandatoryInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isHindi ? 'शैक्षणिक विवरण' : 'Academic Details',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isHindi ? 'आवश्यक *' : 'Required *',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.school_outlined,
            title: _isHindi
                ? 'स्कूल / विश्वविद्यालय का नाम *'
                : 'School / University Name *',
            controller: _schoolController,
            focusNode: _schoolFocusNode,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi
                    ? 'कृपया स्कूल / विश्वविद्यालय का नाम दर्ज करें'
                    : 'Please enter school / university name';
              }
              return null;
            },
          ),
          const Divider(color: Colors.white12, height: 20),
          _buildDetailRow(
            icon: Icons.location_on_outlined,
            title: _isHindi ? 'परिसर का स्थान *' : 'Campus Location *',
            controller: _locationController,
            focusNode: _locationFocusNode,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi
                    ? 'कृपया परिसर का स्थान दर्ज करें'
                    : 'Please enter campus location';
              }
              return null;
            },
          ),
          const Divider(color: Colors.white12, height: 20),
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            title: _isHindi
                ? 'स्नातक / बैच वर्ष *'
                : 'Graduation / Batch Year *',
            controller: _yearController,
            focusNode: _yearFocusNode,
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi
                    ? 'कृपया स्नातक / बैच वर्ष दर्ज करें'
                    : 'Please enter graduation / batch year';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isHindi ? 'संपर्क जानकारी' : 'Contact Information',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isHindi ? 'आवश्यक *' : 'Required *',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone_outlined, color: Colors.white70, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    _mobileFocusNode.requestFocus();
                    _mobileController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _mobileController.text.length),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi
                            ? 'मोबाइल नंबर (OTP सत्यापित) *'
                            : 'Mobile Number (OTP Verified) *',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      TextFormField(
                        controller: _mobileController,
                        focusNode: _mobileFocusNode,
                        keyboardType: TextInputType.phone,
                        onChanged: (val) {
                          setState(() {
                            _isMobileVerified = false;
                          });
                          _validateForm();
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return _isHindi
                                ? 'कृपया मोबाइल नंबर दर्ज करें'
                                : 'Please enter mobile number';
                          }
                          if (val.trim().length < 10) {
                            return _isHindi
                                ? 'कृपया वैध 10-अंकों का मोबाइल नंबर दर्ज करें'
                                : 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: _isHindi
                              ? 'मोबाइल नंबर दर्ज करें'
                              : 'Enter mobile number',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: 15.sp,
                          ),
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          errorStyle: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _mobileFocusNode.requestFocus();
                  _mobileController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _mobileController.text.length),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () {
                  if (_mobileController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isHindi
                              ? 'कृपया पहले मोबाइल नंबर दर्ज करें।'
                              : 'Please enter a mobile number first.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  _showOtpVerificationDialog();
                },
                style: TextButton.styleFrom(
                  backgroundColor: _isMobileVerified
                      ? Colors.green.withValues(alpha: 0.2)
                      : const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                child: Text(
                  _isMobileVerified
                      ? (_isHindi ? 'सत्यापित ✓' : 'Verified ✓')
                      : (_isHindi ? 'OTP सत्यापित करें' : 'Verify OTP'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isMobileVerified
                        ? Colors.greenAccent
                        : const Color(0xFFD4AF37),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isHindi ? 'पते की जानकारी' : 'Address Information',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isHindi ? 'आवश्यक *' : 'Required *',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.home_outlined,
            title: _isHindi ? 'वर्तमान पता *' : 'Current Address *',
            controller: _currentAddressController,
            focusNode: _currentAddressFocusNode,
            maxLines: 1,
            onChanged: (val) {
              if (_sameAsCurrentAddress) {
                setState(() {
                  _permanentAddressController.text = val;
                });
              }
            },
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi
                    ? 'कृपया वर्तमान पता दर्ज करें'
                    : 'Please enter current address';
              }
              return null;
            },
          ),
          const Divider(color: Colors.white12, height: 20),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _sameAsCurrentAddress,
                  activeColor: const Color(0xFFD4AF37),
                  checkColor: const Color(0xFF072420),
                  onChanged: (bool? value) {
                    setState(() {
                      _sameAsCurrentAddress = value ?? false;
                      if (_sameAsCurrentAddress) {
                        _permanentAddressController.text =
                            _currentAddressController.text;
                      }
                    });
                    _validateForm();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isHindi
                      ? 'स्थाई पता वर्तमान पता जैसा ही है'
                      : 'Permanent address same as current address',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.location_city_outlined,
            title: _isHindi ? 'स्थाई पता *' : 'Permanent Address *',
            controller: _permanentAddressController,
            focusNode: _permanentAddressFocusNode,
            maxLines: 1,
            readOnly: _sameAsCurrentAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi
                    ? 'कृपया स्थाई पता दर्ज करें'
                    : 'Please enter permanent address';
              }
              return null;
            },
          ),
          const Divider(color: Colors.white12, height: 20),
          _buildDetailRow(
            icon: Icons.location_city,
            title: _isHindi ? 'शहर *' : 'City *',
            controller: _cityController,
            focusNode: _cityFocusNode,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi ? 'कृपया शहर दर्ज करें' : 'Please enter city';
              }
              return null;
            },
          ),
          const Divider(color: Colors.white12, height: 20),
          _buildDetailRow(
            icon: Icons.map_outlined,
            title: _isHindi ? 'राज्य *' : 'State *',
            controller: _stateController,
            focusNode: _stateFocusNode,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi
                    ? 'कृपया राज्य दर्ज करें'
                    : 'Please enter state';
              }
              return null;
            },
          ),
          const Divider(color: Colors.white12, height: 20),
          _buildDetailRow(
            icon: Icons.pin_drop_outlined,
            title: _isHindi ? 'पिन कोड *' : 'Pin Code *',
            controller: _pincodeController,
            focusNode: _pincodeFocusNode,
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi
                    ? 'कृपया पिन कोड दर्ज करें'
                    : 'Please enter pin code';
              }
              if (val.trim().length != 6) {
                return _isHindi
                    ? 'कृपया 6-अंकों का पिन कोड दर्ज करें'
                    : 'Please enter 6-digit pin code';
              }
              return null;
            },
          ),
          const Divider(color: Colors.white12, height: 20),
          _buildDetailRow(
            icon: Icons.public,
            title: _isHindi ? 'देश *' : 'Country *',
            controller: _countryController,
            focusNode: _countryFocusNode,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return _isHindi
                    ? 'कृपया देश दर्ज करें'
                    : 'Please enter country';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    FocusNode? focusNode,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return InkWell(
      onTap: readOnly
          ? null
          : () {
              if (focusNode != null) {
                focusNode.requestFocus();
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              }
            },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: maxLines,
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  validator: validator,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: readOnly ? Colors.white38 : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: _isHindi ? 'विवरण दर्ज करें' : 'Enter details',
                    hintStyle: TextStyle(
                      color: Colors.white38,
                      fontSize: 15.sp,
                    ),
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    errorStyle: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!readOnly)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (focusNode != null) {
                  focusNode.requestFocus();
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSaveProfile() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      showErrorSnackBar(
        _isHindi
            ? 'कृपया सभी आवश्यक फ़ील्ड भरें।'
            : 'Please fill all required fields.',
      );
      return;
    }

    if (!_isMobileVerified) {
      showErrorSnackBar(
        _isHindi
            ? 'कृपया मोबाइल नंबर OTP द्वारा सत्यापित करें।'
            : 'Please verify mobile number with OTP.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      String? profileImageUrl = _selectedAvatarUrl.isNotEmpty
          ? _selectedAvatarUrl
          : null;

      // 1. Agar nayi image choose ki gayi hai to pehle image upload API call hogi
      if (_pickedImageFile != null) {
        log('Uploading profile image: ${_pickedImageFile!.path}');
        final uploadResponse = await authService.uploadImage(_pickedImageFile!);

        final extractedUrl = uploadResponse.data?.imageUrl;
        if (extractedUrl != null && extractedUrl.isNotEmpty) {
          profileImageUrl = extractedUrl;
        }
      }

      // 2. Profile update API - keval vahi fields jo design me present hain
      final body = UpdateProfileBodyModel(
        name: _userName.isNotEmpty ? _userName : null,
        email: _userEmail.isNotEmpty ? _userEmail : null,
        phone: _mobileController.text.trim(),
        isVerified: _isMobileVerified,
        profileImage: profileImageUrl,
        school: _schoolController.text.trim(),
        campusLocation: _locationController.text.trim(),
        graduationYear: _yearController.text.trim(),
        currentAddress: _currentAddressController.text.trim(),
        permanentAddress: _permanentAddressController.text.trim(),
        profession: _professionController.text.trim().isNotEmpty
            ? _professionController.text.trim()
            : null,
        education: _educationController.text.trim().isNotEmpty
            ? _educationController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : null,
        pincode: _pincodeController.text.trim().isNotEmpty
            ? _pincodeController.text.trim()
            : null,
        villageTown: _villageTownController.text.trim().isNotEmpty
            ? _villageTownController.text.trim()
            : null,
      );

      final updateResponse = await authService.updateUserProfileData(body);
      if (updateResponse.success == true) {
        var box = Hive.box("userdata");
        await box.put("isProfileComplete", true);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DynamicDashboardScreen()),
          (route) => false,
        );
      }

      // ref.invalidate(getMyProfileProvider);

      if (mounted) {
        setState(() {
          if (profileImageUrl != null) {
            _selectedAvatarUrl = profileImageUrl;
            _pickedImageFile = null;
          }
        });
      }
    } catch (e) {
      log('Error saving profile: $e');
      if (mounted) {
        showErrorSnackBar(
          _isHindi
              ? 'प्रोफ़ाइल सहेजने में विफल: $e'
              : 'Failed to save profile: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSaveButtonAndLogout() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSaveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              disabledBackgroundColor: Colors.white12,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _isHindi ? 'प्रोफ़ाइल सहेजें' : 'Save Profile',
                    style: const TextStyle(
                      color: Color(0xFF072420),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    title: Text(
                      'Sign Out',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 19.sp,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to sign out?',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        color: Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          'No',
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);

                          var box = Hive.box("userdata");
                          await box.clear();

                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text(
                          'Yes',
                          style: GoogleFonts.outfit(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.deepOrange, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Log Out',
              style: const TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
