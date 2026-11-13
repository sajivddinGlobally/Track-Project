import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/DrawerScreen/NetworkRequestScreen/NetworkingRequest.dart';
import 'package:track_loved/core/Data/ResponseModel/getNotificationListModel.dart';

import 'provider/getNotificationListProvider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  final bool isHindi;
  const NotificationScreen({super.key, this.isHindi = false});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  int selectedTab = 0;
  final Color primaryColor = const Color(0xFF0B4F4A);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 250) {
        ref.read(getNotificationProvider.notifier).loadMoreNotifications();
      }
    }
  }

  void _handleNotificationNavigation(Datum item) {
    final type = item.type?.toLowerCase().trim();
    if (type == 'friend_request' || type == 'connection_request') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NetworkingRequestScreen(),
        ),
      );
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.isNegative || difference.inSeconds < 60) {
      return widget.isHindi ? 'अभी' : 'Just now';
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return widget.isHindi ? '$m मिनट पहले' : '$m min ago';
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return widget.isHindi ? '$h घंटे पहले' : '$h hour${h > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return widget.isHindi ? 'कल' : 'Yesterday';
    } else if (difference.inDays < 7) {
      final d = difference.inDays;
      return widget.isHindi ? '$d दिन पहले' : '$d days ago';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final monthName = months[localDate.month - 1];
      return '${localDate.day} $monthName';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(getNotificationProvider);
    final isLoadingMore = ref.watch(isNotificationLoadingMoreProvider);

    final model = notificationState.asData?.value;
    final unreadCount =
        model?.unreadCount ??
        (model?.data?.where((e) => e.isRead != true).length ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isHindi ? 'सूचनाएं' : 'Notifications',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: widget.isHindi
                ? 'सभी को पढ़ा हुआ चिह्नित करें'
                : 'Mark all as read',
            onPressed: () {
              ref.read(getNotificationProvider.notifier).markAllAsRead();
            },
            icon: const Icon(Icons.done_all),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _buildTab(widget.isHindi ? 'सभी' : 'All', 0),
                const SizedBox(width: 10),
                _buildTab(widget.isHindi ? 'अपठित' : 'Unread', 1),
                const Spacer(),
                Text(
                  '$unreadCount ${widget.isHindi ? 'अपठित' : 'unread'}',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: notificationState.when(
              data: (response) {
                final allNotifications = response.data ?? [];
                final filteredNotifications = selectedTab == 1
                    ? allNotifications
                          .where((item) => item.isRead != true)
                          .toList()
                    : allNotifications;

                if (filteredNotifications.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(getNotificationProvider.notifier)
                        .refreshNotifications(),
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: _buildEmptyState(),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(getNotificationProvider.notifier)
                      .refreshNotifications(),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        filteredNotifications.length + (isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == filteredNotifications.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        );
                      }
                      final item = filteredNotifications[index];
                      return _buildNotificationCard(item);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => ref
                            .read(getNotificationProvider.notifier)
                            .refreshNotifications(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          widget.isHindi ? 'पुनः प्रयास करें' : 'Retry',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE0E5E3),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Datum item) {
    final bool isUnread = item.isRead != true;

    return InkWell(
      onTap: () {
        if (isUnread && item.id != null) {
          ref.read(getNotificationProvider.notifier).markAsRead(item.id!);
        }
        _handleNotificationNavigation(item);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFEFF7F5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? const Color(0xFFD0E7E1) : const Color(0xFFE8ECEA),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingAvatar(item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title ??
                              (widget.isHindi ? 'सूचना' : 'Notification'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172521),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF65716D),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _formatTime(item.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingAvatar(Datum item) {
    final profileImage = item.senderId?.profileImage?.trim();
    if (profileImage != null &&
        profileImage.isNotEmpty &&
        profileImage.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.network(
          profileImage,
          height: 46,
          width: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildTypeIcon(item.type),
        ),
      );
    }
    return _buildTypeIcon(item.type);
  }

  Widget _buildTypeIcon(String? type) {
    IconData iconData;
    switch (type?.toLowerCase().trim()) {
      case 'friend_request':
      case 'connection_request':
        iconData = Icons.person_add_alt_1;
        break;
      case 'friend_accept':
      case 'request_accepted':
        iconData = Icons.people_alt_outlined;
        break;
      case 'message':
      case 'chat':
        iconData = Icons.chat_bubble_outline;
        break;
      case 'sos':
      case 'emergency':
        iconData = Icons.warning_amber_rounded;
        break;
      case 'location':
        iconData = Icons.location_on_outlined;
        break;
      default:
        iconData = Icons.notifications_none_rounded;
        break;
    }

    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(iconData, color: primaryColor, size: 23),
    );
  }

  Widget _buildEmptyState() {
    final isUnreadTab = selectedTab == 1;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 70,
            color: primaryColor.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          Text(
            isUnreadTab
                ? (widget.isHindi
                      ? 'कोई अपठित सूचना नहीं'
                      : 'No unread notifications')
                : (widget.isHindi
                      ? 'कोई सूचना नहीं मिली'
                      : 'No notifications found'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF26332F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isHindi
                ? 'आप पूरी तरह अपडेट हैं!'
                : 'You are all caught up!',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
