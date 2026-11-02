import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/MatchContactsResModel.dart';

final getMatchContactProvider = FutureProvider.family
    .autoDispose<MatchContactsResModel, String>((ref, search) async {
      final service = ref.read(authServiceProvider);
      return await service.getMatchContactsData(
        search: search.trim().isNotEmpty ? search.trim() : null,
      );
    });
