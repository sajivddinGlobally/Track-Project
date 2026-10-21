import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:track_loved/core/AuthService/AuthServiceProvider.dart';
import 'package:track_loved/core/Data/ResponseModel/ChatHistoryResModel.dart';
import 'package:track_loved/core/Network/ChatSocketService.dart';

class MessageScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String name;
  final String initials;
  final String profileImage;
  final bool isHindi;

  const MessageScreen({
    super.key,
    required this.receiverId,
    required this.name,
    required this.initials,
    this.profileImage = '',
    required this.isHindi,
  });

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatSocketService? _socketService;
  List<SocketChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isLocked = false;
  bool _canSend = true;
  bool _isAccepted = false;
  // bool _isSocketConnected = false;
  String? _lockReason;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    if (Hive.isBoxOpen('userdata')) {
      _currentUserId = Hive.box('userdata').get('id')?.toString() ?? '';
    }
    _loadCurrentUser();
    _loadChatHistory();
    _initSocketConnection();
  }

  Future<void> _loadCurrentUser() async {
    final box = Hive.isBoxOpen('userdata')
        ? Hive.box('userdata')
        : await Hive.openBox('userdata');
    if (mounted) {
      setState(() {
        _currentUserId = box.get('id')?.toString() ?? '';
      });
    }
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.getChatHistoryData(
        receiverId: widget.receiverId,
      );

      if (!mounted) return;

      if (response.success == true && response.data != null) {
        final chatData = response.data!;
        setState(() {
          _messages = List<SocketChatMessage>.from(chatData.messages ?? []);
          _isAccepted = chatData.isAccepted ?? false;
          _isLocked = chatData.isLocked ?? false;
          _canSend = chatData.canSend ?? true;
          _lockReason = chatData.lockReason;
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      log('[ChatHistory] Error fetching chat history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initSocketConnection() {
    _socketService = ChatSocketService(
      receiverId: widget.receiverId,
      onNewMessage: (newMsg) {
        if (!mounted) return;
        setState(() {
          // If this is our own message, check if we have a temporary optimistic message to update
          final tempIndex = _messages.indexWhere(
            (m) =>
                m.id != null &&
                m.id!.startsWith('temp_') &&
                m.senderId == newMsg.senderId &&
                m.text == newMsg.text,
          );

          if (tempIndex != -1) {
            _messages[tempIndex] = newMsg;
          } else {
            final alreadyExists = _messages.any(
              (m) =>
                  (m.id != null && m.id == newMsg.id) ||
                  (m.senderId == newMsg.senderId &&
                      m.text == newMsg.text &&
                      m.createdAt != null &&
                      newMsg.createdAt != null &&
                      m.createdAt!
                              .difference(newMsg.createdAt!)
                              .inSeconds
                              .abs() <
                          3),
            );
            if (!alreadyExists) {
              _messages.add(newMsg);
            }
          }
        });
        _scrollToBottom();
      },
      onChatLocked: (reason) {
        if (!mounted) return;
        setState(() {
          _isLocked = true;
          _canSend = false;
          if (reason != null && reason.isNotEmpty) {
            _lockReason = reason;
          }
        });
      },
      onRequestAccepted: () {
        if (!mounted) return;
        setState(() {
          _isAccepted = true;
          _isLocked = false;
          _canSend = true;
          _lockReason = null;
        });
      },
      onConnectionChanged: (connected) {
        // if (!mounted) return;
        // setState(() {
        //   _isSocketConnected = connected;
        // });
      },
    );

    _socketService?.connect();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isLocked || !_canSend) return;

    // 1. Optimistic UI Update: Instantly show message in UI
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = SocketChatMessage(
      id: tempId,
      senderId: _currentUserId,
      receiverId: widget.receiverId,
      text: text,
      isRead: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(optimisticMsg);
    });
    _msgController.clear();
    _scrollToBottom();

    // 2. Emit to socket server in background
    _socketService?.sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60.h,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    try {
      return DateFormat('hh:mm a').format(dt.toLocal());
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _socketService?.disconnect();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isInputDisabled = _isLocked || !_canSend;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: const Color(0xFF0B4F4A),
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.profileImage.isNotEmpty
                      ? NetworkImage(widget.profileImage)
                      : null,
                  child: widget.profileImage.isEmpty
                      ? Text(
                          widget.initials,
                          style: TextStyle(
                            color: const Color(0xFF0B4F4A),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Green dot indicator commented as requested:
                // Positioned(
                //   bottom: -1,
                //   right: -1,
                //   child: Container(
                //     width: 10.w,
                //     height: 10.w,
                //     decoration: BoxDecoration(
                //       color: _isSocketConnected
                //           ? const Color(0xFF00E676)
                //           : Colors.orangeAccent,
                //       shape: BoxShape.circle,
                //       border: Border.all(
                //         color: const Color(0xFF0B4F4A),
                //         width: 1.5,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Online status text commented as requested:
                  // Text(
                  //   _isSocketConnected
                  //       ? (widget.isHindi ? 'ऑनलाइन' : 'Online')
                  //       : (widget.isHindi
                  //             ? 'कनेक्ट हो रहा है...'
                  //             : 'Connecting...'),
                  //   style: TextStyle(
                  //     fontSize: 11.sp,
                  //     color: _isSocketConnected
                  //         ? const Color(0xFF80CBC4)
                  //         : Colors.white70,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status / Notification Bar if Accepted or Pending
            if (_isAccepted)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                color: const Color(0xFFE8F5E9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14.sp,
                      color: const Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      widget.isHindi
                          ? 'अनुरोध स्वीकृत • असीमित चैट अनलॉक'
                          : 'Request Accepted • Unlimited Chat Unlocked',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages List or Loader
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0B4F4A),
                      ),
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48.sp,
                              color: Colors.black26,
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              widget.isHindi
                                  ? 'बातचीत शुरू करने के लिए पहला संदेश भेजें!'
                                  : 'Say Hello! Send your introductory message.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg.senderId == _currentUserId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 9.h,
                            ),
                            constraints: BoxConstraints(maxWidth: 290.w),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF0B4F4A)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14.r),
                                topRight: Radius.circular(14.r),
                                bottomLeft: isMe
                                    ? Radius.circular(14.r)
                                    : Radius.circular(2.r),
                                bottomRight: isMe
                                    ? Radius.circular(2.r)
                                    : Radius.circular(14.r),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text ?? '',
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                    fontSize: 15.sp,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(msg.createdAt),
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white60
                                            : Colors.black45,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      SizedBox(width: 4.w),
                                      Icon(
                                        (msg.id != null &&
                                                msg.id!.startsWith('temp_'))
                                            ? Icons.access_time_rounded
                                            : Icons.done_all,
                                        size: 13.5.sp,
                                        color: msg.isRead == true
                                            ? const Color(0xFF00E676)
                                            : Colors.white60,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Lock Banner if locked or limit reached
            if (isInputDisabled)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  border: Border(
                    top: BorderSide(color: const Color(0xFFFFEEBA), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: const Color(0xFF856404),
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _lockReason ??
                            (widget.isHindi
                                ? 'अनुरोध लंबित: सामने वाले के स्वीकार करने तक आप और संदेश नहीं भेज सकते।'
                                : 'Request Pending: You cannot send more messages until the request is accepted.'),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF856404),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Message Input Area
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      enabled: !isInputDisabled,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 15.5.sp,
                        color: isInputDisabled
                            ? Colors.black38
                            : Colors.black87,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: isInputDisabled
                            ? (widget.isHindi
                                  ? 'चैट लॉक है...'
                                  : 'Chat is locked...')
                            : (widget.isHindi
                                  ? 'संदेश लिखें...'
                                  : 'Type a message...'),
                        hintStyle: TextStyle(
                          fontSize: 14.5.sp,
                          color: Colors.black38,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: isInputDisabled
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFFF8FAFC),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 14.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  CircleAvatar(
                    backgroundColor: isInputDisabled
                        ? Colors.grey.shade400
                        : const Color(0xFF0B4F4A),
                    radius: 22.r,
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      onPressed: isInputDisabled ? null : _sendMessage,
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
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}

enum ConnectionStatus { none, pendingSent, pendingReceived, connected }

class Member {
  final String id;
  final String name;
  final String initials;
  ConnectionStatus status;

  Member({
    required this.id,
    required this.name,
    required this.initials,
    this.status = ConnectionStatus.none,
  });
}

class ActivityLog {
  final String title;
  final DateTime timestamp;

  ActivityLog({required this.title, required this.timestamp});
}

class NetworkMember {
  final String id;
  final String nameEn;
  final String nameHi;
  final String roleEn;
  final String roleHi;
  final String initials;
  final String currentLocation;
  final String permanentLocation;
  final String pincode;
  bool isPending;

  NetworkMember({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.roleEn,
    required this.roleHi,
    required this.initials,
    required this.currentLocation,
    required this.permanentLocation,
    required this.pincode,
    this.isPending = false,
  });
}
