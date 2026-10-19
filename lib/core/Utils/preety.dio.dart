import 'dart:developer';
import 'dart:io';


import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:track_loved/LoginScreen/LoginScreen.dart';
import 'package:track_loved/core/Utils/key.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

bool isLoveTrackToLogin = false;

Dio createDio() {
  Dio dio = Dio();
  dio.interceptors.add(
    PrettyDioLogger(
      requestBody: true,
      requestHeader: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final box = Hive.isBoxOpen("userdata")
            ? Hive.box("userdata")
            : await Hive.openBox("userdata");
        final token = box.get("token");

        options.headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.toString().isNotEmpty)
            "Authorization": "Bearer $token",
        });
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          log("Token expired / Unauthenticated");

          final box = Hive.isBoxOpen("userdata")
              ? Hive.box("userdata")
              : await Hive.openBox("userdata");

          await box.delete("token");

          if (!isLoveTrackToLogin) {
            isLoveTrackToLogin = true;
            showErrorSnackBar("Session expired. Please log in again.");
            // Login screen par bhejo
            navigatorKey.currentState?.pushAndRemoveUntil(
              CupertinoPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );

            Future.delayed(const Duration(seconds: 2), () {
              isLoveTrackToLogin = false;
            });
          }
          return handler.next(error);
        }
        String message = "Something went wrong";

        switch (error.type) {
          case DioExceptionType.connectionError:
            message =
                "No Internet Connection or Server is unreachable. Please check your network.";
            break;

          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            message =
                "Connection timed out. Server is taking too long to respond.";
            break;

          case DioExceptionType.cancel:
            message = "Request was cancelled.";
            break;

          case DioExceptionType.badResponse:
            try {
              final responseData = error.response?.data;

              log("ERROR RESPONSE: $responseData");

              if (responseData is Map) {
                // --------------------------------
                // Case 1: Validation errors (Prioritized)
                // --------------------------------
                if (responseData['errors'] is Map) {
                  final errors = responseData['errors'] as Map;
                  if (errors.isNotEmpty) {
                    final firstError = errors.values.first;
                    if (firstError is List && firstError.isNotEmpty) {
                      message = firstError.first.toString();
                    } else if (firstError != null) {
                      message = firstError.toString();
                    }
                  }
                }
                // --------------------------------
                // Case 2: Normal message fallback
                // --------------------------------
                else if (responseData['message'] != null) {
                  message = responseData['message'].toString();
                }
              }
            } catch (e) {
              log("Error while parsing DioException message: $e");
            }
            break;

          default:
            if (error.error is SocketException) {
              message =
                  "No Internet Connection or Server is unreachable. Please check your network.";
            } else {
              message = "Something went wrong. Please try again.";
            }
            break;
        }
        log("FINAL API ERROR MESSAGE: $message");

        showErrorSnackBar(message);

        return handler.next(error);
      },
    ),
  );
  return dio;
}
