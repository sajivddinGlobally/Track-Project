import 'package:riverpod/riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';

import '../../core/Data/ResponseModel/getDashboardModel.dart';

final getDashbordProvider = FutureProvider.autoDispose<GetDashboardModel>((ref) async {
  final service = ref.read(authServiceProvider);
  return await service.getDashboardData();
});
