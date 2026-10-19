import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/AddNetworkSearchResModel.dart';

final addNetworkSerachProvider = FutureProvider.family
    .autoDispose<AddNetworkSearchResModel, String>((ref, search) async {
      final service = ref.read(authServiceProvider);
      return await service.addNetworkSearchData(search: search);
    });
