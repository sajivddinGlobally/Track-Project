import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/GetMyJobApplicationsResModel.dart';

final getMyJobApplicationsProvider =
    FutureProvider.autoDispose<GetMyJobApplicationsResModel>((ref) async {
  final authService = ref.watch(authServiceProvider);
  log('Calling GET /api/v1/business/job-applications/me...');
  final result = await authService.getMyJobApplicationsData();
  log(
    'GET /api/v1/business/job-applications/me response: success=${result.success}, jobs=${result.jobApplications.length}, business=${result.businessApplications.length}',
  );
  return result;
});
