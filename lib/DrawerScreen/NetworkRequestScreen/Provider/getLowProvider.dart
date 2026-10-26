import 'package:riverpod/riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';

final getLawProvider = FutureProvider((ref) async {
  final service = ref.read(authServiceProvider);
  return await service.getLawContent();
});

final getLawProviderNew = FutureProvider.family<dynamic, Map<String, dynamic>>((
  ref,
  args,
) async {
  final service = ref.read(authServiceProvider);
  final String state = args['state']!;
  final String category = args['category']!;
  final String type = args['type']!;
  return await service.getLawContentByState(
    state: state,
    category: category,
    type: type,
  );
});
