import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

class CompanyPaymentScreen extends ConsumerStatefulWidget {
  final String? token;
  final String? email;
  final String? phone;
  final String? companyName;

  const CompanyPaymentScreen({
    super.key,
    this.token,
    this.email,
    this.phone,
    this.companyName,
  });

  @override
  ConsumerState<CompanyPaymentScreen> createState() =>
      _CompanyPaymentScreenState();
}

class _CompanyPaymentScreenState extends ConsumerState<CompanyPaymentScreen> {
  static const String razorpayLiveKey = 'rzp_live_TwPUg5iwt2pI5D';
  static const String razorpayTestKey = 'rzp_test_TwT72AQ3m2g8Kv';
  // Force test key so Razorpay checkout always opens in Test mode
  static const bool useTestKey = true;

  late Razorpay _razorpay;
  bool _isLoading = false;
  String? _statusMessage;
  String? _currentOrderId;
  num? _currentOrderAmount;

  /// Converts paise (e.g. 100) or rupees (e.g. 1) to rupees for UI display
  int get _displayAmountRupees {
    final amt = _currentOrderAmount ?? 1;
    if (amt >= 100 && amt % 100 == 0) {
      return (amt / 100).round();
    }
    return amt.toInt();
  }

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    // Auto-trigger order creation and checkout on screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPaymentFlow();
    });
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startPaymentFlow() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing secure subscription order...';
    });

    try {
      final authService = ref.read(authServiceProvider);

      // Save token if provided so Dio interceptors have it
      if (widget.token != null && widget.token!.isNotEmpty) {
        final box = Hive.isBoxOpen('userdata')
            ? Hive.box('userdata')
            : await Hive.openBox('userdata');
        await box.put('token', widget.token);
      }

      // 1. Create order on backend: POST /api/v1/payment/create-order (Amount: 1 Rupee)
      final orderRes = await authService.createPaymentOrder(
        amount: 1,
        planName: 'Company Subscription',
        token: widget.token,
      );

      final orderData = orderRes.order ?? orderRes.data;
      final orderId = orderData?.id;
      final orderKey = orderData?.key;
      final orderAmount = orderData?.amount ?? 100;

      if (orderId == null || orderId.isEmpty) {
        throw Exception(orderRes.message ?? 'Failed to generate order ID');
      }

      _currentOrderId = orderId;
      _currentOrderAmount = orderAmount;

      log(
        '[Payment] Order generated: $orderId, Key: $orderKey, Amount: $orderAmount',
      );

      // 2. Open official Razorpay Checkout SDK
      // Prioritize test key rzp_test_TwT72AQ3m2g8Kv to ensure test environment
      final effectiveKey = useTestKey
          ? razorpayTestKey
          : ((orderKey != null &&
                    orderKey.isNotEmpty &&
                    !orderKey.contains('mock') &&
                    !orderKey.contains('placeholder'))
                ? orderKey
                : razorpayLiveKey);

      // Amount in paise (Razorpay takes integer in sub-units: 1 Rupee = 100 paise)
      final num amountInPaise = (orderAmount >= 100)
          ? orderAmount
          : (orderAmount * 100);

      final effectiveEmail =
          widget.email ??
          (Hive.isBoxOpen('userdata')
              ? Hive.box('userdata').get('email')?.toString()
              : '') ??
          '';
      final effectivePhone =
          widget.phone ??
          (Hive.isBoxOpen('userdata')
              ? Hive.box('userdata').get('phone')?.toString()
              : '') ??
          '';

      final options = {
        'key': effectiveKey,
        'amount': amountInPaise.toInt(),
        'name': 'Track Loved Ones',
        'order_id': orderId,
        'description': 'Company Subscription (₹$_displayAmountRupees)',
        'timeout': 300,
        'prefill': {
          if (effectivePhone.isNotEmpty) 'contact': effectivePhone,
          if (effectiveEmail.isNotEmpty) 'email': effectiveEmail,
        },
        'external': {
          'wallets': ['paytm'],
        },
        'theme': {'color': '#0F3D38'},
      };

      setState(() {
        _isLoading = false;
        _statusMessage = 'Awaiting payment confirmation...';
      });

      _razorpay.open(options);
    } catch (e) {
      log('[Payment] Order initiation failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error generating order: $e';
        });
        showErrorSnackBar('Failed to initiate payment: $e');
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    log(
      '[Payment] Razorpay Success Callback: orderId=${response.orderId}, paymentId=${response.paymentId}',
    );

    await _verifyPaymentOnBackend(
      orderId: response.orderId ?? _currentOrderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );
  }

  /// Sends signature and order details to backend: POST /api/v1/payment/verify
  Future<void> _verifyPaymentOnBackend({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verifying payment with server...';
    });

    try {
      final authService = ref.read(authServiceProvider);

      final verifyRes = await authService.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
        token: widget.token,
      );

      if (verifyRes.isCompanyPaymentCompleted == true ||
          verifyRes.success == true) {
        final box = Hive.isBoxOpen('userdata')
            ? Hive.box('userdata')
            : await Hive.openBox('userdata');

        await box.put('isCompanyPaymentCompleted', true);
        await box.put('isPaymentPending', false);
        await box.put('role', 'company');
        // Clear pending registration token so user logs in cleanly from LoginScreen
        await box.delete('token');

        if (!mounted) return;

        showSuccessSnackBar(
          verifyRes.message ??
              'Payment verified successfully! Please log in to continue.',
        );

        // Navigate to Login Screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        throw Exception(verifyRes.message ?? 'Payment verification failed');
      }
    } catch (e) {
      log('[Payment] Verification error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Verification failed: $e';
        });
        showErrorSnackBar('Payment verification failed: $e');
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    log(
      '[Payment] Error callback: Code=${response.code}, Message=${response.message}',
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _statusMessage =
          'Payment cancelled or failed: ${response.message ?? "Unknown error"}';
    });

    final isCancelled =
        response.code == Razorpay.PAYMENT_CANCELLED ||
        (response.message != null &&
            response.message!.toLowerCase().contains('cancel'));

    if (isCancelled) {
      log(
        '[Payment] Cancellation detected from Razorpay. Navigating to LoginScreen.',
      );
      showErrorSnackBar('Payment cancelled. Returning to Login screen.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    showErrorSnackBar(
      'Payment was not completed: ${response.message ?? "Payment Failed"}',
    );
  }

  Future<void> _showCancelConfirmationDialog() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFC5A038).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: const Color(0xFFE6C567),
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Cancel Payment?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel the registration payment? You will be redirected back to the Login screen.',
          style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              'No, Continue',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    log('[Payment] External wallet selected: ${response.walletName}');
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF002E29);
    const secondaryDark = Color(0xFF0F3D38);
    const accentGold = Color(0xFFC5A038);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showCancelConfirmationDialog();
      },
      child: Scaffold(
        backgroundColor: primaryDark,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002E29), Color(0xFF051D1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Back / Cancel Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _isLoading
                          ? null
                          : _showCancelConfirmationDialog,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                      tooltip: 'Cancel Payment',
                    ),
                  ),

                  // Header Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.business_center_rounded,
                          color: const Color(0xFFE6C567),
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'B2B CORPORATE MEMBERSHIP',
                          style: TextStyle(
                            color: const Color(0xFFE6C567),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5.sp,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Company Icon Badge
                  Container(
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentGold.withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.apartment_rounded,
                        color: const Color(0xFF002E29),
                        size: 46.sp,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  Text(
                    'Company Subscription',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    'Activate your business profile to start hiring verified candidates and exploring B2B partnerships.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5.sp,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Plan Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: secondaryDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Standard Corporate Plan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Full Commercial Access',
                                  style: TextStyle(
                                    color: const Color(0xFF00E676),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹$_displayAmountRupees',
                                  style: TextStyle(
                                    color: const Color(0xFFE6C567),
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'One-time / Activation',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10.5.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 18.h),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.12),
                          height: 1,
                        ),
                        SizedBox(height: 18.h),

                        _buildFeatureItem(
                          'Unlimited Job & Hiring Opportunities',
                        ),
                        SizedBox(height: 10.h),
                        _buildFeatureItem(
                          'Direct Candidate Applications & Resumes',
                        ),
                        SizedBox(height: 10.h),
                        _buildFeatureItem(
                          'Verified Company Trust Badge & Search Ranking',
                        ),
                        SizedBox(height: 10.h),
                        _buildFeatureItem(
                          'DPDPA 2023 Compliant Data Safeguards',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Status / Loading Indicator
                  if (_isLoading) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE6C567),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Flexible(
                          child: Text(
                            _statusMessage ?? 'Processing...',
                            style: TextStyle(
                              color: const Color(0xFFE6C567),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ] else if (_statusMessage != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Pay Now / Simulate / Retry Button
                  Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6C567), Color(0xFFC5A038)],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: accentGold.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: _isLoading ? null : _startPaymentFlow,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: const Color(0xFF002E29),
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _statusMessage != null && !_isLoading
                                ? 'Retry Payment (₹$_displayAmountRupees)'
                                : 'Pay ₹$_displayAmountRupees via Razorpay',
                            style: TextStyle(
                              color: const Color(0xFF002E29),
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // Razorpay Security Label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield,
                        color: const Color(0xFF00E676),
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Secured by Razorpay • 256-bit Bank Grade Encryption',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Cancel Payment & Return to Login
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : _showCancelConfirmationDialog,
                    icon: Icon(
                      Icons.cancel_outlined,
                      color: Colors.white60,
                      size: 16.sp,
                    ),
                    label: Text(
                      'Cancel Payment & Return to Login',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: const Color(0xFF00E676),
          size: 16.sp,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13.sp,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
