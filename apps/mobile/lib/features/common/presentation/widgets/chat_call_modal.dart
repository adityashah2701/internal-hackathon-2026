import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Page 19 — In-App Realtime Chat & Number-Masked Calling
/// Allows secure communication between customer and worker with pre-set quick
/// message chips, privacy-preserved calling, and instant message dispatch.
class ChatCallModal extends StatefulWidget {
  const ChatCallModal({
    super.key,
    required this.peerName,
    required this.peerRole,
    this.trackingCode = 'SR-8921',
  });

  final String peerName;
  final String peerRole;
  final String trackingCode;

  @override
  State<ChatCallModal> createState() => _ChatCallModalState();
}

class _ChatCallModalState extends State<ChatCallModal> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final List<_ChatMessage> _messages;

  final List<String> _quickChips = <String>[
    'I have arrived at the gate',
    'Please confirm flat number',
    'Inspecting the electrical panel now',
    'Work completed, please check',
    'Sharing location pin',
  ];

  @override
  void initState() {
    super.initState();
    _messages = <_ChatMessage>[
      _ChatMessage(
        text: 'Hello! I have been assigned to your service request #${widget.trackingCode}.',
        isMe: false,
        time: '10:32 AM',
      ),
      const _ChatMessage(
        text: 'Hello! Please call when you reach near Marvel Residency gate.',
        isMe: true,
        time: '10:33 AM',
      ),
      const _ChatMessage(
        text: 'Sure, I am on Paud Road right now, arriving in 8 minutes with my toolkit.',
        isMe: false,
        time: '10:35 AM',
      ),
    ];
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customText]) {
    final String text = customText ?? _msgController.text.trim();
    if (text.isEmpty) return;

    final DateTime now = DateTime.now();
    final String timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isMe: true,
          time: timeStr,
        ),
      );
      if (customText == null) {
        _msgController.clear();
      }
    });

    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Auto-reply simulation after 1.5s
    if (customText != null) {
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _messages.add(
            _ChatMessage(
              text: 'Got it, noted! Thank you.',
              isMe: false,
              time: '${now.hour}:${(now.minute + 1).toString().padLeft(2, '0')}',
            ),
          );
        });
      });
    }
  }

  void _simulateMaskedCall(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Calling ${widget.peerName}...',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Cooperative Virtual Number (Masked)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your actual phone number is protected. Calls are routed via the cooperative telecom proxy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.3),
              ),
            ],
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('End Call'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: <Widget>[
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        widget.peerName.substring(0, 1),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                widget.peerName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 15, color: AppColors.primary),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${widget.peerRole} • Active Now',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                      tooltip: 'Call (Number Masked)',
                      onPressed: () => _simulateMaskedCall(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Privacy Notice Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: isDark ? AppColors.surfaceDark : const Color(0xFFFEF3C7),
            child: Row(
              children: <Widget>[
                const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #${widget.trackingCode} • End-to-end masked for privacy & safety',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.primaryLight : const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (BuildContext ctx, int i) {
                final _ChatMessage msg = _messages[i];
                return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isMe
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                        bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                      ),
                      border: msg.isMe
                          ? null
                          : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: msg.isMe
                                ? AppColors.onPrimary
                                : (isDark ? Colors.white : Colors.black87),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              msg.time,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: msg.isMe ? Colors.black54 : Colors.grey,
                              ),
                            ),
                            if (msg.isMe) ...<Widget>[
                              const SizedBox(width: 4),
                              const Icon(Icons.done_all_rounded, size: 12, color: Colors.black54),
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

          // Quick Prompt Chips
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickChips.length,
              itemBuilder: (BuildContext ctx, int i) {
                final String chip = _quickChips[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(chip, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _sendMessage(chip),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a secure message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });

  final String text;
  final bool isMe;
  final String time;
}
