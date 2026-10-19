import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import 'package:track_loved/core/AuthService/AuthService.dart';
import 'package:track_loved/core/Network/ApiStateNetwork.dart';
import 'package:track_loved/core/Utils/preety.dio.dart';

final dioProvider = Provider<Dio>((ref){
  return createDio();
});

final apiProvider  = Provider((ref){
  final dio = ref.read(dioProvider);
  return ApiStateNetwork(dio);
});

final authServiceProvider = Provider((ref){
  final api = ref.read(apiProvider);
  return Authservice(api);
});