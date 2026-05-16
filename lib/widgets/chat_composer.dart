import 'package:flutter/material.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.sending,
    required this.onSend,
  });

  final bool sending;
  final Future<void> Function(String text) onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _localBusy = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    // Three-layer guard: parent's `sending` flag, local busy flag, empty text.
    if (widget.sending || _localBusy) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _localBusy = true);
    _controller.clear();

    try {
      await widget.onSend(text);
    } finally {
      if (mounted) setState(() => _localBusy = false);
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.sending || _localBusy;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                enabled: !disabled,
                decoration: const InputDecoration(
                  hintText: 'Message…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: disabled
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF268E86),
                      ),
                    )
                  : const Icon(Icons.send, color: Color(0xFF268E86)),
              onPressed: disabled ? null : _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}