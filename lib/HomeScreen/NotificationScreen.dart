import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required bool isHindi});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int selectedTab = 0;

  final Color primaryColor = const Color(0xFF0B4F4A);

  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Connection Request',
      'message': 'Rahul Sharma sent you a connection request.',
      'time': '5 min ago',
      'icon': Icons.person_add_alt_1,
      'read': false,
    },
    {
      'title': 'Request Accepted',
      'message': 'Priya Verma accepted your connection request.',
      'time': '30 min ago',
      'icon': Icons.people_alt_outlined,
      'read': false,
    },
    {
      'title': 'New Message',
      'message': 'You have received a new message.',
      'time': '2 hours ago',
      'icon': Icons.chat_bubble_outline,
      'read': true,
    },
    {
      'title': 'Profile Update',
      'message': 'Your profile was updated successfully.',
      'time': 'Yesterday',
      'icon': Icons.person_outline,
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = notifications.where((item) {
      if (selectedTab == 1) {
        return item['read'] == false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: () {
              setState(() {
                for (final item in notifications) {
                  item['read'] = true;
                }
              });
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
                _buildTab('All', 0),
                const SizedBox(width: 10),
                _buildTab('Unread', 1),
                const Spacer(),
                Text(
                  '${notifications.where((e) => e['read'] == false).length} unread',
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
            child: filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredNotifications[index];
                      return _buildNotificationCard(item);
                    },
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

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final bool isUnread = item['read'] == false;

    return InkWell(
      onTap: () {
        setState(() {
          item['read'] = true;
        });
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
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: primaryColor,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] as String,
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
                    item['message'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF65716D),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    item['time'] as String,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 70,
            color: primaryColor.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          const Text(
            'No notifications found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF26332F),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You are all caught up!',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
