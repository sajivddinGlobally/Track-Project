import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/getBusinnesProfileModel.dart';

final getBussinessProfileProvider =
    FutureProvider.autoDispose<GetBussinessProfileModel>((ref) async {
  final authService = ref.watch(authServiceProvider);
  log('Calling GET /api/v1/business/profile...');
  final result = await authService.getBussinessProfileData();
  log('GET /api/v1/business/profile response: status=${result.status}, count=${result.count}');
  return result;
});
