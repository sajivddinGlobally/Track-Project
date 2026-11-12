import 'package:riverpod/riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/LocationSharingReceivedResModel.dart';

final searchLovedProvider = FutureProvider.family
    .autoDispose<LocationSharingReceivedResModel, String>((ref, search) async {
      final service = ref.read(authServiceProvider);
      return await service.getLocationSharingReceived(search);
    });
