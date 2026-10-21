import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../Data/ResponseModel/ChatHistoryResModel.dart';

class ChatSocketService {
  static const String defaultSocketUrl =
      'https://loveable-backend-5qi0.onrender.com';

  io.Socket? _socket;
  final String receiverId;
  final void Function(SocketChatMessage message)? onNewMessage;
  final void Function(String? lockReason)? onChatLocked;
  final void Function()? onRequestAccepted;
  final void Function(bool isConnected)? onConnectionChanged;

  ChatSocketService({
    required this.receiverId,
    this.onNewMessage,
    this.onChatLocked,
    this.onRequestAccepted,
    this.onConnectionChanged,
  });

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({String? socketUrl}) async {
    final box = Hive.isBoxOpen('userdata')
        ? Hive.box('userdata')
        : await Hive.openBox('userdata');
    final token = box.get('token')?.toString() ?? '';

    final url = socketUrl ?? defaultSocketUrl;
    log('[ChatSocket] Connecting to $url for receiver: $receiverId');

    final socket = io.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
    });

    _socket = socket;

    socket.onConnect((_) {
      log('[ChatSocket] Connected! Joining chat room: $receiverId');
      onConnectionChanged?.call(true);
      socket.emit('join_chat', {'receiverId': receiverId});
    });

    socket.on('new_message', (dynamic data) {
      log('[ChatSocket] new_message event received: $data');
      try {
        if (data is Map<String, dynamic>) {
          onNewMessage?.call(SocketChatMessage.fromJson(data));
        } else if (data is Map) {
          onNewMessage?.call(
            SocketChatMessage.fromJson(Map<String, dynamic>.from(data)),
          );
        }
      } catch (e) {
        log('[ChatSocket] Error parsing new_message: $e');
      }
    });

    socket.on('chat_locked', (dynamic data) {
      log('[ChatSocket] chat_locked event: $data');
      String? reason;
      if (data is Map) {
        reason = data['message']?.toString();
      } else if (data is String) {
        reason = data;
      }
      onChatLocked?.call(reason);
    });

    socket.on('request_accepted', (dynamic data) {
      log('[ChatSocket] request_accepted event: $data');
      onRequestAccepted?.call();
    });

    socket.onDisconnect((reason) {
      log('[ChatSocket] Disconnected: $reason');
      onConnectionChanged?.call(false);
    });

    socket.onConnectError((e) {
      log('[ChatSocket] Connect Error: $e');
      onConnectionChanged?.call(false);
    });

    socket.connect();
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    log('[ChatSocket] Emitting send_message to $receiverId: $text');
    _socket?.emit('send_message', {
      'receiverId': receiverId,
      'text': text.trim(),
    });
  }

  void disconnect() {
    log('[ChatSocket] Disconnecting socket for receiver: $receiverId');
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
