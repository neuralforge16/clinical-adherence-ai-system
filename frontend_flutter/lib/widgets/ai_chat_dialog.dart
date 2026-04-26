import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AIChatDialog extends StatefulWidget {
  final String? patientName;
  final int? patientId;
  final int? adherenceRate;
  final List? medications;

  const AIChatDialog({
    super.key,
    this.patientName,
    this.patientId,
    this.adherenceRate,
    this.medications,
  });

  /// Convenience static method so every caller uses the same show pattern.
  static void show(
    BuildContext context, {
    String? patientName,
    int? patientId,
    int? adherenceRate,
    List? medications,
  }) {
    showDialog(
      context: context,
      builder: (_) => AIChatDialog(
        patientName: patientName,
        patientId: patientId,
        adherenceRate: adherenceRate,
        medications: medications,
      ),
    );
  }

  @override
  State<AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<AIChatDialog> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _aiPurple = Color(0xFF7C3AED);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _mutedText = Color(0xFF6B7280);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _isLoading = false;

  bool get _hasPatientContext => widget.patientName != null;

  @override
  void initState() {
    super.initState();
    // If we have patient context, add an automatic greeting message
    if (_hasPatientContext) {
      _messages.add(_Msg(role: 'ai', text: _buildGreeting()));
    }
  }

  String _buildGreeting() {
    final name = widget.patientName ?? "this patient";
    final rate = widget.adherenceRate;
    final meds = widget.medications ?? [];

    final medList = meds.isEmpty
        ? "no medications on record"
        : meds
              .map(
                (m) =>
                    "${m["name"] ?? "Unknown"} ${m["dosage"] ?? ""} (${m["frequency"] ?? ""})",
              )
              .join(", ");

    return "I'm ready to help with $name's case.\n\n"
        "Here's what I know:\n"
        "• Adherence rate: ${rate != null ? "$rate%" : "unknown"}\n"
        "• Medications: $medList\n\n"
        "What would you like to know?";
  }

  // ── Patient context string sent with every message ─────────────────────────
  String? get _contextPrefix {
    if (!_hasPatientContext) return null;
    final name = widget.patientName!;
    final rate = widget.adherenceRate;
    final meds = widget.medications ?? [];
    final medList = meds.isEmpty
        ? "none"
        : meds
              .map(
                (m) =>
                    "${m["name"] ?? ""} ${m["dosage"] ?? ""} ${m["frequency"] ?? ""}",
              )
              .join(", ");
    return "Patient: $name. "
        "Adherence: ${rate != null ? "$rate%" : "unknown"}. "
        "Medications: $medList. ";
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add patient context prefix to the FIRST user message only
    final isFirstUserMessage = !_messages.any((m) => m.role == 'user');
    final prefix = _contextPrefix;
    final fullText = (isFirstUserMessage && prefix != null)
        ? "$prefix\n\nQuestion: $text"
        : text;

    setState(() {
      _messages.add(_Msg(role: 'user', text: text)); // display clean text
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Build history in the format Groq expects:
      // {"role": "user"|"assistant", "content": "..."}
      // We send all messages so the AI remembers the full conversation.
      // The first user message gets the context prefix injected.
      final history = <Map<String, String>>[];
      bool firstUserDone = false;

      for (final msg in _messages) {
        if (msg.role == 'user') {
          if (!firstUserDone && prefix != null) {
            // First user message: inject context prefix
            history.add({
              "role": "user",
              "content": "$prefix\n\nQuestion: ${msg.text}",
            });
            firstUserDone = true;
          } else {
            history.add({"role": "user", "content": msg.text});
          }
        } else if (msg.role == 'ai' && !msg.isError) {
          // Skip the auto-greeting from initState — it's UI only,
          // not part of the real Groq conversation
          if (_hasPatientContext &&
              history.isEmpty &&
              msg.text == _buildGreeting())
            continue;
          history.add({"role": "assistant", "content": msg.text});
        }
      }

      final response = await ApiService.sendChatMessage(history);
      setState(() => _messages.add(_Msg(role: 'ai', text: response)));
    } catch (e) {
      setState(
        () => _messages.add(
          _Msg(
            role: 'ai',
            text: "Sorry, I couldn't get a response. Please try again.",
            isError: true,
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              if (_hasPatientContext) _buildContextBanner(),
              Expanded(child: _buildMessages()),
              if (_isLoading) _buildTypingIndicator(),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _aiPurple,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Clinical Assistant",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _hasPatientContext
                      ? "Viewing: ${widget.patientName}"
                      : "Smart Medication Adherence Monitoring",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Patient context banner ─────────────────────────────────────────────────
  Widget _buildContextBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: _primary.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Icon(Icons.person_pin, color: _primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Context loaded for ${widget.patientName} · "
              "Adherence: ${widget.adherenceRate != null ? "${widget.adherenceRate}%" : "—"} · "
              "${(widget.medications ?? []).length} medication(s)",
              style: TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ───────────────────────────────────────────────────────────
  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _aiPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.smart_toy, color: _aiPurple, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ask about adherence, medications,\nor patient risk levels.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(_Msg msg) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _aiPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.smart_toy, color: _aiPurple, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? _primary
                    : msg.isError
                    ? const Color(0xFFFFF1F2)
                    : _pageBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: msg.isError
                    ? Border.all(color: const Color(0xFFFDA4AF))
                    : null,
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : msg.isError
                      ? const Color(0xFF9F1239)
                      : const Color(0xFF1A1A1A),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Typing indicator ───────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _aiPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.smart_toy, color: _aiPurple, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _pageBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(150),
                const SizedBox(width: 4),
                _dot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: _mutedText, shape: BoxShape.circle),
        ),
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────
  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: const Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _hasPatientContext
                    ? "Ask about ${widget.patientName}'s medications..."
                    : "Ask about adherence, risk, or patients...",
                hintStyle: const TextStyle(color: _mutedText, fontSize: 14),
                filled: true,
                fillColor: _pageBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedOpacity(
            opacity: _isLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: InkWell(
              onTap: _isLoading ? null : _send,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simple message model ───────────────────────────────────────────────────────
class _Msg {
  final String role;
  final String text;
  final bool isError;

  const _Msg({required this.role, required this.text, this.isError = false});
}
