import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/NetworkRequestResModel.dart';

final networkRequestProvider =
    FutureProvider.autoDispose<NetworkRequestResModel>((ref) async {
      final service = ref.read(authServiceProvider);
      return await service.getNetworkRequestData();
    });
