import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'key.dart';

void showSuccessSnackBar(String message) {
  snackBarKey.currentState?.hideCurrentSnackBar();
  snackBarKey.currentState?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle_sharp, color: Colors.white, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.all(16.w),
      elevation: 6,
      duration: const Duration(seconds: 3),
    ),
  );
}

void showErrorSnackBar(String message) {
  snackBarKey.currentState?.hideCurrentSnackBar();
  snackBarKey.currentState?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.white, size: 18.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.all(16.w),
      elevation: 6,
      duration: const Duration(seconds: 3),
    ),
  );
}
