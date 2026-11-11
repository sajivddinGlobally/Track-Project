import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/AddNetworkSearchResModel.dart';

class AddNetworkSearchState {
  final List<User> users;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const AddNetworkSearchState({
    this.users = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
    this.hasNextPage = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  AddNetworkSearchState copyWith({
    List<User>? users,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? hasNextPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return AddNetworkSearchState(
      users: users ?? this.users,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }
}

class AddNetworkSearchNotifier extends StateNotifier<AddNetworkSearchState> {
  final Ref ref;
  final String search;

  AddNetworkSearchNotifier(this.ref, this.search)
      : super(const AddNetworkSearchState(isLoading: true)) {
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final service = ref.read(authServiceProvider);
      final res = await service.addNetworkSearchData(
        search: search,
        page: 1,
        limit: 20,
      );
      final newUsers = res.data?.users ?? [];
      final pagination = res.data?.pagination;

      state = state.copyWith(
        users: newUsers,
        page: 1,
        limit: pagination?.limit ?? 20,
        total: pagination?.total ?? newUsers.length,
        totalPages: pagination?.totalPages ?? 1,
        hasNextPage: pagination?.hasNextPage ?? false,
        isLoading: false,
      );
    } catch (e, stack) {
      log('[AddNetworkSearch] fetchFirstPage error: $e, stack: $stack');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    try {
      state = state.copyWith(isLoadingMore: true);
      final nextPage = state.page + 1;
      final service = ref.read(authServiceProvider);
      final res = await service.addNetworkSearchData(
        search: search,
        page: nextPage,
        limit: state.limit,
      );
      final nextUsers = res.data?.users ?? [];
      final pagination = res.data?.pagination;

      // Deduplicate by user.id
      final existingIds = state.users.map((u) => u.id).toSet();
      final filteredNew = nextUsers
          .where((u) => u.id == null || !existingIds.contains(u.id))
          .toList();

      state = state.copyWith(
        users: [...state.users, ...filteredNew],
        page: nextPage,
        limit: pagination?.limit ?? state.limit,
        total: pagination?.total ?? state.total,
        totalPages: pagination?.totalPages ?? state.totalPages,
        hasNextPage: pagination?.hasNextPage ??
            (nextPage < (pagination?.totalPages ?? 1)),
        isLoadingMore: false,
      );
    } catch (e) {
      log('[AddNetworkSearch] fetchNextPage error: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await fetchFirstPage();
  }
}

final addNetworkSerachProvider = StateNotifierProvider.family
    .autoDispose<AddNetworkSearchNotifier, AddNetworkSearchState, String>(
  (ref, search) => AddNetworkSearchNotifier(ref, search),
);
