import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/DeleteNotificationResModel.dart';

import '../../core/Data/ResponseModel/getNotificationListModel.dart';

final isNotificationLoadingMoreProvider = StateProvider<bool>((ref) => false);

class GetNotificationNotifier
    extends StateNotifier<AsyncValue<GetNotificationListModel>> {
  final Ref ref;

  GetNotificationNotifier(this.ref) : super(const AsyncValue.loading()) {
    getNotificationListData();
  }

  int currentPage = 1;
  final int limit = 20;
  bool hasMore = true;
  bool isLoadingMore = false;

  Future<void> getNotificationListData({bool isLoadMore = false}) async {
    if (isLoadingMore || (isLoadMore && !hasMore)) return;

    if (isLoadMore) {
      isLoadingMore = true;
      ref.read(isNotificationLoadingMoreProvider.notifier).state = true;
    } else {
      currentPage = 1;
      hasMore = true;
      state = const AsyncValue.loading();
    }

    try {
      final service = ref.read(authServiceProvider);
      final response = await service.getNotificationListData(
        page: currentPage,
        limit: limit,
      );

      if (isLoadMore) {
        final previousData = state.value;

        if (previousData != null) {
          final updatedData = [...?previousData.data, ...?response.data];

          state = AsyncValue.data(
            GetNotificationListModel(
              success: response.success,
              message: response.message,
              unreadCount: response.unreadCount,
              totalNotifications: response.totalNotifications,
              currentPage: response.currentPage,
              totalPages: response.totalPages,
              data: updatedData,
            ),
          );
        } else {
          state = AsyncValue.data(response);
        }
      } else {
        state = AsyncValue.data(response);
      }

      final page = response.currentPage ?? currentPage;
      final totalP = response.totalPages ?? 1;
      hasMore = page < totalP;
      if (hasMore) {
        currentPage = page + 1;
      } else {
        currentPage = page;
      }
    } catch (e, st) {
      if (!isLoadMore) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      isLoadingMore = false;
      ref.read(isNotificationLoadingMoreProvider.notifier).state = false;
    }
  }

  Future<void> refreshNotifications() async {
    await getNotificationListData();
  }

  Future<void> loadMoreNotifications() async {
    await getNotificationListData(isLoadMore: true);
  }

  Future<void> markAsRead(String id) async {
    final current = state.value;
    if (current == null || current.data == null) return;

    final targetIndex = current.data!.indexWhere((item) => item.id == id);
    if (targetIndex == -1) return;
    if (current.data![targetIndex].isRead == true) return;

    final updatedList = current.data!.map((item) {
      if (item.id == id) {
        return Datum(
          id: item.id,
          title: item.title,
          message: item.message,
          type: item.type,
          isRead: true,
          senderId: item.senderId,
          createdAt: item.createdAt,
        );
      }
      return item;
    }).toList();

    final currentUnread = current.unreadCount ?? 0;
    final newUnread = currentUnread > 0 ? currentUnread - 1 : 0;

    state = AsyncValue.data(
      GetNotificationListModel(
        success: current.success,
        message: current.message,
        unreadCount: newUnread,
        totalNotifications: current.totalNotifications,
        currentPage: current.currentPage,
        totalPages: current.totalPages,
        data: updatedList,
      ),
    );

    try {
      final service = ref.read(authServiceProvider);
      await service.readSingleNotificationData(id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final current = state.value;
    if (current == null || current.data == null) return;

    final hasUnread = current.data!.any((item) => item.isRead != true);
    if (!hasUnread &&
        (current.unreadCount == null || current.unreadCount == 0)) {
      return;
    }

    final updatedList = current.data!.map((item) {
      return Datum(
        id: item.id,
        title: item.title,
        message: item.message,
        type: item.type,
        isRead: true,
        senderId: item.senderId,
        createdAt: item.createdAt,
      );
    }).toList();

    state = AsyncValue.data(
      GetNotificationListModel(
        success: current.success,
        message: current.message,
        unreadCount: 0,
        totalNotifications: current.totalNotifications,
        currentPage: current.currentPage,
        totalPages: current.totalPages,
        data: updatedList,
      ),
    );

    try {
      final service = ref.read(authServiceProvider);
      await service.readAllNotificationsData();
    } catch (_) {}
  }

  Future<DeleteNotificationResModel> deleteSingleNotification(String id) async {
    final service = ref.read(authServiceProvider);
    final response = await service.deleteSingleNotificationData(
      notificationId: id,
    );

    if (response.success == true) {
      final current = state.value;
      if (current != null && current.data != null) {
        final target = current.data!.firstWhere(
          (item) => item.id == id,
          orElse: () => Datum(),
        );
        final bool wasUnread = target.isRead != true;
        final updatedList =
            current.data!.where((item) => item.id != id).toList();

        final currentTotal =
            current.totalNotifications ?? current.data!.length;
        final currentUnread = current.unreadCount ?? 0;

        state = AsyncValue.data(
          GetNotificationListModel(
            success: current.success,
            message: response.message ?? current.message,
            unreadCount: wasUnread && currentUnread > 0
                ? currentUnread - 1
                : currentUnread,
            totalNotifications:
                currentTotal > 0 ? currentTotal - 1 : 0,
            currentPage: current.currentPage,
            totalPages: current.totalPages,
            data: updatedList,
          ),
        );
      }
    }
    return response;
  }

  Future<DeleteNotificationResModel> deleteSelectedNotifications(
    List<String> ids,
  ) async {
    final service = ref.read(authServiceProvider);
    final response = await service.deleteSelectedNotificationsData(
      notificationIds: ids,
    );

    if (response.success == true) {
      final current = state.value;
      if (current != null && current.data != null) {
        final idSet = ids.toSet();
        int unreadDeletedCount = 0;
        for (final item in current.data!) {
          if (idSet.contains(item.id) && item.isRead != true) {
            unreadDeletedCount++;
          }
        }
        final updatedList =
            current.data!.where((item) => !idSet.contains(item.id)).toList();

        final currentTotal =
            current.totalNotifications ?? current.data!.length;
        final currentUnread = current.unreadCount ?? 0;

        state = AsyncValue.data(
          GetNotificationListModel(
            success: current.success,
            message: response.message ?? current.message,
            unreadCount:
                (currentUnread - unreadDeletedCount).clamp(0, 999999),
            totalNotifications:
                (currentTotal - ids.length).clamp(0, 999999),
            currentPage: current.currentPage,
            totalPages: current.totalPages,
            data: updatedList,
          ),
        );
      }
    }
    return response;
  }

  Future<DeleteNotificationResModel> deleteAllNotifications() async {
    final service = ref.read(authServiceProvider);
    final response = await service.deleteAllNotificationsData();

    if (response.success == true) {
      final current = state.value;
      state = AsyncValue.data(
        GetNotificationListModel(
          success: current?.success ?? true,
          message: response.message ?? 'All notifications deleted successfully',
          unreadCount: 0,
          totalNotifications: 0,
          currentPage: 1,
          totalPages: 1,
          data: [],
        ),
      );
    }
    return response;
  }
}

final getNotificationProvider =
    StateNotifierProvider.autoDispose<
      GetNotificationNotifier,
      AsyncValue<GetNotificationListModel>
    >((ref) {
      return GetNotificationNotifier(ref);
    });
