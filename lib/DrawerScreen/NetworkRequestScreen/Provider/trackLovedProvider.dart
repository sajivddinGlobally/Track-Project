import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/trackFriendModel.dart';

final trackLovedProvider = FutureProvider.autoDispose<TrackFriendModel>((
  ref,
) async {
  final service = ref.read(authServiceProvider);
  return await service.trackFriend();
});

final trackLovedPaginationProvider = FutureProvider.family
    .autoDispose<TrackFriendModel, int>((ref, page) async {
      final service = ref.read(authServiceProvider);
      return await service.trackFriend(page: page);
    });
