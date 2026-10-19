import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';

final getMatchContactProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.read(authServiceProvider);
  return await service.getMatchContactsData();
});
