import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/GetLawContentResModel.dart';

final getLawProvider = FutureProvider<GetLawContentResModel>((ref) async {
  final service = ref.read(authServiceProvider);
  return await service.getLawContent();
});

final getLawProviderNew =
    FutureProvider.family<GetLawContentResModel, Map<String, dynamic>>((
  ref,
  args,
) async {
  final service = ref.read(authServiceProvider);
  final String state = args['state'] ?? 'All';
  final String category = args['category'] ?? '';
  final String type = args['type'] ?? '';
  return await service.getLawContentByState(
    state: state,
    category: category,
    type: type,
  );
});
