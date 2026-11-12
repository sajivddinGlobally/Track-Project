import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/trackFriendModel.dart';

class NetworkLocationPermissionsState {
  final List<FriendElement> friends;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const NetworkLocationPermissionsState({
    this.friends = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
    this.hasNextPage = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  NetworkLocationPermissionsState copyWith({
    List<FriendElement>? friends,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? hasNextPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return NetworkLocationPermissionsState(
      friends: friends ?? this.friends,
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

class NetworkLocationPermissionsNotifier
    extends StateNotifier<NetworkLocationPermissionsState> {
  final Ref ref;
  final String search;

  NetworkLocationPermissionsNotifier(this.ref, this.search)
    : super(const NetworkLocationPermissionsState(isLoading: true)) {
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final service = ref.read(authServiceProvider);
      final query = search.trim();
      final res = await service.trackFriend(
        search: query.isNotEmpty ? query : null,
        page: 1,
        limit: state.limit,
      );
      final newFriends = res.data?.friends ?? [];
      final pagination = res.data?.pagination;
      final totalP = pagination?.totalPages ?? 1;
      final pageNum = pagination?.pageInt ?? 1;

      state = state.copyWith(
        friends: List<FriendElement>.from(newFriends),
        page: 1,
        limit: pagination?.limitInt ?? state.limit,
        total: pagination?.total ?? newFriends.length,
        totalPages: totalP,
        hasNextPage: pageNum < totalP,
        isLoading: false,
      );
    } catch (e, stack) {
      log(
        '[NetworkLocationPermissions] fetchFirstPage error: $e, stack: $stack',
      );
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
      final query = search.trim();
      final res = await service.trackFriend(
        search: query.isNotEmpty ? query : null,
        page: nextPage,
        limit: state.limit,
      );
      final nextFriends = res.data?.friends ?? [];
      final pagination = res.data?.pagination;
      final totalP = pagination?.totalPages ?? state.totalPages;

      // Deduplicate by friendshipId or friend.id
      final existingIds = state.friends
          .map((f) => f.friendshipId ?? f.friend?.id)
          .whereType<String>()
          .toSet();

      final filteredNew = nextFriends.where((f) {
        final id = f.friendshipId ?? f.friend?.id;
        return id == null || !existingIds.contains(id);
      }).toList();

      state = state.copyWith(
        friends: [...state.friends, ...filteredNew],
        page: nextPage,
        limit: pagination?.limitInt ?? state.limit,
        total: pagination?.total ?? state.total,
        totalPages: totalP,
        hasNextPage: nextPage < totalP,
        isLoadingMore: false,
      );
    } catch (e, stack) {
      log(
        '[NetworkLocationPermissions] fetchNextPage error: $e, stack: $stack',
      );
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void updateFriendSharingLocally(String friendId, bool isSharing) {
    final updated = state.friends.map((item) {
      if (item.friend?.id == friendId) {
        item.sharingMyLocation = isSharing;
      }
      return item;
    }).toList();
    state = state.copyWith(friends: updated);
  }

  Future<void> refresh() async {
    await fetchFirstPage();
  }
}

final networkLocationPermissionsProvider = StateNotifierProvider.family
    .autoDispose<
      NetworkLocationPermissionsNotifier,
      NetworkLocationPermissionsState,
      String
    >((ref, search) => NetworkLocationPermissionsNotifier(ref, search));
