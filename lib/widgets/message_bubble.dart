import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final Map<String, dynamic> message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final text = message['text']?.toString() ?? '';
    final pending = message['_pending'] == true;
    final failed = message['_failed'] == true;

    final bg = isMine
        ? const Color(0xFF268E86)
        : const Color(0xFFF1F1F1);
    final fg = isMine ? Colors.white : Colors.black87;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: TextStyle(color: fg, fontSize: 15)),
            if (pending || failed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  failed ? 'Failed' : 'Sending…',
                  style: TextStyle(
                    color: fg.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}