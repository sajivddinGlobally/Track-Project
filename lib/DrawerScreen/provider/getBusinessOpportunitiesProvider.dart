import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/GetBusinessOpportunitiesResModel.dart';

class BusinessOpportunitiesFilter {
  final String? search;
  final String? pincode;
  final int page;
  final int limit;

  const BusinessOpportunitiesFilter({
    this.search,
    this.pincode,
    this.page = 1,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessOpportunitiesFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          pincode == other.pincode &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode =>
      (search?.hashCode ?? 0) ^
      (pincode?.hashCode ?? 0) ^
      page.hashCode ^
      limit.hashCode;
}

final getBusinessOpportunitiesProvider = FutureProvider.autoDispose
    .family<GetBusinessOpportunitiesResModel, BusinessOpportunitiesFilter>(
  (ref, filter) async {
    final authService = ref.watch(authServiceProvider);
    log('Calling GET /api/v1/business/opportunities?search=${filter.search}&pincode=${filter.pincode}...');
    final result = await authService.getBusinessOpportunitiesData(
      page: filter.page,
      limit: filter.limit,
      search: filter.search?.trim().isNotEmpty == true
          ? filter.search!.trim()
          : null,
      pincode: filter.pincode?.trim().isNotEmpty == true
          ? filter.pincode!.trim()
          : null,
    );
    log('GET /api/v1/business/opportunities response: count=${result.data?.length}');
    return result;
  },
);
