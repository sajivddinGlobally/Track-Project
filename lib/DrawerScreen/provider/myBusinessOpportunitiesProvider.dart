import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthService.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/GetMyBusinessOpportunitiesResModel.dart';

class MyBusinessOpportunitiesState {
  final AsyncValue<List<MyBusinessOpportunityItem>> opportunities;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final int totalPostsCount;
  final int totalApplicantsCount;
  final bool hasMore;
  final bool isLoadingMore;
  final String? searchQuery;

  const MyBusinessOpportunitiesState({
    this.opportunities = const AsyncValue.loading(),
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
    this.totalPostsCount = 0,
    this.totalApplicantsCount = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.searchQuery,
  });

  MyBusinessOpportunitiesState copyWith({
    AsyncValue<List<MyBusinessOpportunityItem>>? opportunities,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    int? totalPostsCount,
    int? totalApplicantsCount,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return MyBusinessOpportunitiesState(
      opportunities: opportunities ?? this.opportunities,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      totalPostsCount: totalPostsCount ?? this.totalPostsCount,
      totalApplicantsCount:
          totalApplicantsCount ?? this.totalApplicantsCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MyBusinessOpportunitiesNotifier
    extends StateNotifier<MyBusinessOpportunitiesState> {
  final Authservice _authService;

  MyBusinessOpportunitiesNotifier(this._authService)
      : super(const MyBusinessOpportunitiesState()) {
    fetchFirstPage();
  }

  Future<void> fetchFirstPage({String? search}) async {
    state = state.copyWith(
      opportunities: const AsyncValue.loading(),
      page: 1,
      searchQuery: search,
      isLoadingMore: false,
    );

    try {
      log('Fetching My Business Opportunities page: 1, search: $search');
      final res = await _authService.getMyBusinessOpportunitiesData(
        page: 1,
        limit: state.limit,
        search: (search != null && search.trim().isNotEmpty)
            ? search.trim()
            : null,
      );

      final List<MyBusinessOpportunityItem> list =
          res.data ?? <MyBusinessOpportunityItem>[];
      final pagination = res.pagination;
      final totalPages = pagination?.totalPages ?? 1;

      state = state.copyWith(
        opportunities: AsyncValue.data(list),
        page: 1,
        total: pagination?.total ?? list.length,
        totalPages: totalPages,
        totalPostsCount: res.counts?.totalPosts ?? list.length,
        totalApplicantsCount: res.counts?.totalApplicants ?? 0,
        hasMore: 1 < totalPages,
        isLoadingMore: false,
      );
    } catch (e, st) {
      log('Error fetching my business opportunities: $e');
      state = state.copyWith(
        opportunities: AsyncValue.error(e, st),
        isLoadingMore: false,
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      log('Fetching next page of business opportunities: $nextPage');
      final res = await _authService.getMyBusinessOpportunitiesData(
        page: nextPage,
        limit: state.limit,
        search: (state.searchQuery != null &&
                state.searchQuery!.trim().isNotEmpty)
            ? state.searchQuery!.trim()
            : null,
      );

      final List<MyBusinessOpportunityItem> currentList =
          state.opportunities.value ?? <MyBusinessOpportunityItem>[];
      final List<MyBusinessOpportunityItem> newList =
          <MyBusinessOpportunityItem>[
        ...currentList,
        ...(res.data ?? <MyBusinessOpportunityItem>[])
      ];
      final totalPages = res.pagination?.totalPages ?? state.totalPages;

      state = state.copyWith(
        opportunities: AsyncValue.data(newList),
        page: nextPage,
        totalPages: totalPages,
        total: res.pagination?.total ?? newList.length,
        totalPostsCount: res.counts?.totalPosts ?? state.totalPostsCount,
        totalApplicantsCount:
            res.counts?.totalApplicants ?? state.totalApplicantsCount,
        hasMore: nextPage < totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      log('Error fetching next page of business opportunities: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await fetchFirstPage(search: state.searchQuery);
  }
}

final myBusinessOpportunitiesProvider = StateNotifierProvider.autoDispose<
    MyBusinessOpportunitiesNotifier, MyBusinessOpportunitiesState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return MyBusinessOpportunitiesNotifier(authService);
});
