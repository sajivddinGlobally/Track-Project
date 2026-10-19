import 'package:riverpod/riverpod.dart';
import 'package:track_loved/core/Data/ResponseModel/getMyProfileModel.dart';

import '../../core/AuthService/AuthServiceProvider.dart';

final getMyProfileProvider = FutureProvider.autoDispose<GetMyProfileModel>((
  ref,
) async {
  final authService = ref.read(authServiceProvider);
  return await authService.getMyProfileData();
});
