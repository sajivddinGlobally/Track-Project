import 'package:riverpod/riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';

final getLawProvider = FutureProvider((ref) async {
  final service = ref.read(authServiceProvider);
  return await service.getLawContent();
});
