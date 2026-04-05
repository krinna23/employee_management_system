import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/query_provider.dart';
import '../../models/query_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final SupportQueryModel query;
  final int currentUserId; // 0 for admin
  final String senderType;  // 'Admin' or 'Employee'

  const ChatDetailScreen({
    Key? key,
    required this.query,
    required this.currentUserId,
    required this.senderType,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SupportQueryModel _localQuery;

  @override
  void initState() {
    super.initState();
    _localQuery = widget.query;
    Future.microtask(() => context.read<QueryProvider>().fetchMessages(widget.query.id!));
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final provider = context.read<QueryProvider>();
    bool success = await provider.sendMessage(widget.query.id!, widget.senderType, widget.currentUserId, text);
    if (success) {
      _msgController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Color get _statusColor {
    switch (_localQuery.status) {
      case 'Pending': return const Color(0xFFEF4444);
      case 'In Process': return const Color(0xFFF59E0B);
      case 'Resolved': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: const Color(0xFF1E293B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localQuery.subject.isNotEmpty ? _localQuery.subject : 'Query #${_localQuery.id}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(children: [
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor),
              ),
              Text(_localQuery.status, style: TextStyle(fontSize: 12, color: _statusColor, fontWeight: FontWeight.w500)),
            ]),
          ],
        ),
        actions: [
          if (widget.senderType == 'Admin')
            PopupMenuButton<String>(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Status', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
              ),
              onSelected: (val) async {
                await context.read<QueryProvider>().updateQueryStatus(_localQuery.id!, val);
                setState(() => _localQuery = _localQuery.copyWith(status: val));
              },
              itemBuilder: (_) => ['Pending', 'In Process', 'Resolved'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            ),
        ],
      ),
      body: Consumer<QueryProvider>(
        builder: (context, provider, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          return Column(
            children: [
              // Employee info banner
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _statusColor.withOpacity(0.1),
                      child: Text(_localQuery.employeeName.isNotEmpty ? _localQuery.employeeName[0].toUpperCase() : '?', style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_localQuery.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Query raised', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ])),
                    Text(_formatDate(_localQuery.createdAt), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Messages
              Expanded(
                child: provider.currentMessages.isEmpty
                    ? const Center(child: Text('No messages yet. Start the conversation!', style: TextStyle(color: Color(0xFF94A3B8))))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.currentMessages.length,
                        itemBuilder: (context, index) {
                          final msg = provider.currentMessages[index];
                          final isMe = msg.senderType == widget.senderType;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      isMe ? widget.senderType : (msg.senderType == 'Admin' ? 'Admin' : _localQuery.employeeName),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF4F46E5) : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                      ),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(msg.message, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1E293B), fontSize: 14, height: 1.4)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(msg.timestamp),
                                          style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : const Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Input bar (disabled if resolved)
              if (_localQuery.status == 'Resolved')
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text('This query has been resolved.', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w500)),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return iso; }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso.length > 15 ? iso.substring(11, 16) : iso; }
  }
}
