import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_loved/DrawerScreen/NetworkRequestScreen/NetworkingRequest.dart';
import 'package:track_loved/core/Data/ResponseModel/getNotificationListModel.dart';
import 'package:track_loved/core/Utils/showMessage.dart';

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

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedNotificationIds = {};
  bool _isDeleting = false;

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

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotificationIds.clear();
    });
  }

  void _toggleItemSelection(String id) {
    if (id.isEmpty) return;
    setState(() {
      if (_selectedNotificationIds.contains(id)) {
        _selectedNotificationIds.remove(id);
        if (_selectedNotificationIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotificationIds.add(id);
      }
    });
  }

  bool _isAllSelected(List<Datum> items) {
    final validIds = items
        .map((e) => e.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    if (validIds.isEmpty) return false;
    return validIds.every((id) => _selectedNotificationIds.contains(id));
  }

  void _toggleSelectAll(List<Datum> items) {
    final validIds = items
        .map((e) => e.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    if (validIds.isEmpty) return;

    setState(() {
      if (_isAllSelected(items)) {
        _selectedNotificationIds.clear();
      } else {
        _selectedNotificationIds.addAll(validIds);
      }
    });
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

  // 1) EK notification delete
  Future<void> _confirmDeleteSingle(Datum item) async {
    if (item.id == null || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.isHindi ? 'सूचना हटाएं?' : 'Delete Notification?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          widget.isHindi
              ? 'क्या आप वाकई इस सूचना को हटाना चाहते हैं?'
              : 'Are you sure you want to delete this notification?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              widget.isHindi ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.isHindi ? 'हटाएं' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final res = await ref
            .read(getNotificationProvider.notifier)
            .deleteSingleNotification(item.id!);
        if (mounted) {
          if (res.success == true) {
            showSuccessSnackBar(
              res.message ??
                  (widget.isHindi
                      ? 'सूचना सफलतापूर्वक हटाई गई'
                      : 'Notification deleted successfully'),
              context,
            );
          } else {
            showErrorSnackBar(
              res.message ??
                  (widget.isHindi
                      ? 'सूचना हटाने में विफल'
                      : 'Failed to delete notification'),
              context,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(e.toString(), context);
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  // 2) SELECTED notifications delete
  Future<void> _confirmDeleteSelected() async {
    if (_selectedNotificationIds.isEmpty || _isDeleting) return;

    final count = _selectedNotificationIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.isHindi
                  ? '$count सूचनाएं हटाएं?'
                  : 'Delete $count Notification${count > 1 ? 's' : ''}?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          widget.isHindi
              ? 'क्या आप वाकई $count चयनित सूचनाएं हटाना चाहते हैं?'
              : 'Are you sure you want to delete $count selected notification${count > 1 ? 's' : ''}?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              widget.isHindi ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.isHindi ? 'हटाएं' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final idsToDelete = _selectedNotificationIds.toList();
        final res = await ref
            .read(getNotificationProvider.notifier)
            .deleteSelectedNotifications(idsToDelete);
        if (mounted) {
          if (res.success == true) {
            showSuccessSnackBar(
              res.message ??
                  (widget.isHindi
                      ? 'चयनित सूचनाएं सफलतापूर्वक हटाई गईं'
                      : 'Selected notifications deleted successfully'),
              context,
            );
            _exitSelectionMode();
          } else {
            showErrorSnackBar(
              res.message ??
                  (widget.isHindi
                      ? 'सूचनाएं हटाने में विफल'
                      : 'Failed to delete selected notifications'),
              context,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(e.toString(), context);
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  // 3) SAARI notifications delete
  Future<void> _confirmDeleteAll(int totalCount) async {
    if (totalCount == 0 || _isDeleting) {
      showErrorSnackBar(
        widget.isHindi
            ? 'हटाने के लिए कोई सूचना नहीं है'
            : 'No notifications to delete',
        context,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.isHindi
                  ? 'सभी सूचनाएं हटाएं?'
                  : 'Delete All Notifications?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          widget.isHindi
              ? 'क्या आप वाकई सभी सूचनाएं स्थायी रूप से हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।'
              : 'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              widget.isHindi ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.isHindi ? 'सभी हटाएं' : 'Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final res = await ref
            .read(getNotificationProvider.notifier)
            .deleteAllNotifications();
        if (mounted) {
          if (res.success == true) {
            showSuccessSnackBar(
              res.message ??
                  (widget.isHindi
                      ? 'सभी सूचनाएं सफलतापूर्वक हटाई गईं'
                      : 'All notifications deleted successfully'),
              context,
            );
            _exitSelectionMode();
          } else {
            showErrorSnackBar(
              res.message ??
                  (widget.isHindi
                      ? 'सूचनाएं हटाने में विफल'
                      : 'Failed to delete notifications'),
              context,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(e.toString(), context);
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(getNotificationProvider);
    final isLoadingMore = ref.watch(isNotificationLoadingMoreProvider);

    final model = notificationState.asData?.value;
    final allList = model?.data ?? [];
    final unreadCount =
        model?.unreadCount ?? (allList.where((e) => e.isRead != true).length);
    final totalCount = model?.totalNotifications ?? allList.length;

    final filteredNotifications = selectedTab == 1
        ? allList.where((item) => item.isRead != true).toList()
        : allList;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F7),
        appBar: _isSelectionMode
            ? AppBar(
                backgroundColor: const Color(0xFF002E29),
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: widget.isHindi ? 'बंद करें' : 'Close',
                  onPressed: _exitSelectionMode,
                ),
                title: Text(
                  '${_selectedNotificationIds.length} ${widget.isHindi ? 'चयनित' : 'selected'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: _isAllSelected(filteredNotifications)
                        ? (widget.isHindi ? 'चयन हटाएं' : 'Deselect all')
                        : (widget.isHindi ? 'सभी चुनें' : 'Select all'),
                    icon: Icon(
                      _isAllSelected(filteredNotifications)
                          ? Icons.deselect
                          : Icons.select_all,
                    ),
                    onPressed: () => _toggleSelectAll(filteredNotifications),
                  ),
                  IconButton(
                    tooltip: widget.isHindi ? 'चयनित हटाएं' : 'Delete selected',
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed:
                        _selectedNotificationIds.isNotEmpty && !_isDeleting
                        ? _confirmDeleteSelected
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : AppBar(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  widget.isHindi ? 'सूचनाएं' : 'Notifications',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: false,
                actions: [
                  if (allList.isNotEmpty) ...[
                    IconButton(
                      tooltip: widget.isHindi ? 'चुनें' : 'Select',
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                      icon: const Icon(Icons.checklist_rounded),
                    ),
                    IconButton(
                      tooltip: widget.isHindi
                          ? 'सभी को पढ़ा हुआ चिह्नित करें'
                          : 'Mark all as read',
                      onPressed: () {
                        ref
                            .read(getNotificationProvider.notifier)
                            .markAllAsRead();
                      },
                      icon: const Icon(Icons.done_all),
                    ),
                    IconButton(
                      tooltip: widget.isHindi ? 'सभी हटाएं' : 'Delete all',
                      onPressed: () => _confirmDeleteAll(totalCount),
                      icon: const Icon(Icons.delete_sweep_outlined),
                    ),
                  ],
                  const SizedBox(width: 4),
                ],
              ),
        body: Stack(
          children: [
            Column(
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
                      if (filteredNotifications.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () => ref
                              .read(getNotificationProvider.notifier)
                              .refreshNotifications(),
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
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
                              filteredNotifications.length +
                              (isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
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
                            final isSelected = _selectedNotificationIds
                                .contains(item.id);
                            return _buildNotificationCard(
                              item,
                              isSelected: isSelected,
                            );
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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
            if (_isDeleting)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0B4F4A)),
                ),
              ),
          ],
        ),
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

  Widget _buildNotificationCard(Datum item, {required bool isSelected}) {
    final bool isUnread = item.isRead != true;
    final String itemId = item.id ?? '';

    return Dismissible(
      key: ValueKey(itemId.isNotEmpty ? itemId : UniqueKey().toString()),
      direction: _isSelectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (direction) async {
        if (_isSelectionMode) return false;
        await _confirmDeleteSingle(item);
        return false;
      },
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleItemSelection(itemId);
          } else {
            if (isUnread && item.id != null) {
              ref.read(getNotificationProvider.notifier).markAsRead(item.id!);
            }
            _handleNotificationNavigation(item);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              if (itemId.isNotEmpty) {
                _selectedNotificationIds.add(itemId);
              }
            });
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE0F2F1)
                : (isUnread ? const Color(0xFFEFF7F5) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (isUnread
                        ? const Color(0xFFD0E7E1)
                        : const Color(0xFFE8ECEA)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (_) => _toggleItemSelection(itemId),
                    ),
                  ),
                ),
              ],
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
                        if (isUnread) ...[
                          Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (!_isSelectionMode)
                          InkWell(
                            onTap: () => _confirmDeleteSingle(item),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Color(0xFF9E9E9E),
                              ),
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
