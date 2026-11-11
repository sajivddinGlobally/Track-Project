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
          case DioExceptionType.connectionTimeout:
            message = "Connection timeout. Server took too long to connect.";
            break;

          case DioExceptionType.sendTimeout:
            message = "Send timeout. Request took too long to send.";
            break;

          case DioExceptionType.receiveTimeout:
            message = "Receive timeout. Server is taking too long to respond.";
            break;

          case DioExceptionType.connectionError:
            message =
                "No Internet Connection or Server is unreachable. Please check your network.";
            break;

          case DioExceptionType.cancel:
            message = "Request was cancelled.";
            break;

          case DioExceptionType.badCertificate:
            message =
                "Security certificate error. Secure connection could not be established.";
            break;

          case DioExceptionType.badResponse:
            try {
              final responseData = error.response?.data;

              log("ERROR RESPONSE: $responseData");

              if (responseData is Map) {
                final errorsField = responseData['errors'];
                final List<String> extractedErrors = [];

                // --------------------------------
                // Case 1A: errors is a List
                // e.g. [{"field": "companyPanNumber", "message": "..."}] or ["error 1", "error 2"]
                // --------------------------------
                if (errorsField is List && errorsField.isNotEmpty) {
                  for (final item in errorsField) {
                    if (item is Map) {
                      final msg =
                          item['message'] ?? item['msg'] ?? item['error'];
                      if (msg != null && msg.toString().trim().isNotEmpty) {
                        extractedErrors.add(msg.toString().trim());
                      } else {
                        extractedErrors.add(item.toString());
                      }
                    } else if (item != null &&
                        item.toString().trim().isNotEmpty) {
                      extractedErrors.add(item.toString().trim());
                    }
                  }
                }
                // --------------------------------
                // Case 1B: errors is a Map
                // e.g. {"field": ["msg1"], "field2": "msg2"}
                // --------------------------------
                else if (errorsField is Map && errorsField.isNotEmpty) {
                  for (final entry in errorsField.entries) {
                    final val = entry.value;
                    if (val is List) {
                      for (final subItem in val) {
                        if (subItem != null &&
                            subItem.toString().trim().isNotEmpty) {
                          extractedErrors.add(subItem.toString().trim());
                        }
                      }
                    } else if (val is Map) {
                      final msg = val['message'] ?? val['msg'] ?? val['error'];
                      if (msg != null && msg.toString().trim().isNotEmpty) {
                        extractedErrors.add(msg.toString().trim());
                      } else {
                        extractedErrors.add(val.toString());
                      }
                    } else if (val != null &&
                        val.toString().trim().isNotEmpty) {
                      extractedErrors.add(val.toString().trim());
                    }
                  }
                }
                // --------------------------------
                // Case 1C: message is a List
                // --------------------------------
                else if (responseData['message'] is List &&
                    (responseData['message'] as List).isNotEmpty) {
                  for (final item in (responseData['message'] as List)) {
                    if (item != null && item.toString().trim().isNotEmpty) {
                      extractedErrors.add(item.toString().trim());
                    }
                  }
                }

                // If validation errors were found, prioritize and format them
                if (extractedErrors.isNotEmpty) {
                  if (extractedErrors.length == 1) {
                    message = extractedErrors.first;
                  } else {
                    message = extractedErrors.map((e) => '• $e').join('\n');
                  }
                }
                // --------------------------------
                // Case 2: Normal message fallback (e.g. 409 Conflict "gstNumber already exists")
                // --------------------------------
                else if (responseData['message'] != null &&
                    responseData['message'].toString().trim().isNotEmpty) {
                  message = responseData['message'].toString().trim();
                }
                // --------------------------------
                // Case 3: error field fallback
                // --------------------------------
                else if (responseData['error'] != null &&
                    responseData['error'].toString().trim().isNotEmpty) {
                  message = responseData['error'].toString().trim();
                }
              } else if (responseData is String &&
                  responseData.trim().isNotEmpty) {
                message = responseData.trim();
              } else {
                final status = error.response?.statusCode;
                if (status != null && status >= 500) {
                  message = "Server error ($status). Please try again later.";
                }
              }
            } catch (e) {
              log("Error while parsing DioException message: $e");
            }
            break;

          default:
            final dynamic err = error.error;
            final String errString = (err?.toString() ?? error.message ?? '')
                .toLowerCase();

            if (err is SocketException ||
                errString.contains('failed host lookup') ||
                errString.contains('network is unreachable')) {
              message =
                  "No Internet Connection or Server is unreachable. Please check your network.";
            } else if (err is HttpException ||
                errString.contains('connection closed while receiving data') ||
                errString.contains('connection closed')) {
              message =
                  "Server connection closed while receiving data. Please check your internet or try again.";
            } else if (errString.contains('connection reset') ||
                errString.contains('connection refused') ||
                errString.contains('connection aborted')) {
              message = "Server connection was interrupted. Please try again.";
            } else if (err is HandshakeException ||
                err is TlsException ||
                errString.contains('handshake') ||
                errString.contains('certificate')) {
              message =
                  "Secure connection to server failed. Please check your network.";
            } else if (err is FormatException ||
                errString.contains('formatexception')) {
              message = "Unexpected response format received from server.";
            } else if (error.response != null) {
              final data = error.response?.data;
              if (data is Map) {
                message =
                    data["message"]?.toString() ??
                    data["error"]?.toString() ??
                    "Server error";
              } else if (data is String && data.trim().isNotEmpty) {
                message = data.trim();
              } else {
                message =
                    "Server error (${error.response?.statusCode ?? 'unknown'}). Please try again.";
              }
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
