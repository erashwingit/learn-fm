import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMessage({required this.text, required this.isUser}) : time = DateTime.now();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(text: 'Hello! I am your FM AI Assistant. Ask me anything about Facility Management - HVAC, safety compliance, housekeeping standards, vendor management, and more!', isUser: false),
  ];
  bool _loading = false;

  final List<String> _suggestions = [
    'What is preventive maintenance?',
    'Explain fire safety protocols',
    'How to manage vendors effectively?',
    'What is SLA in FM?',
    'Explain HVAC maintenance',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai-chat',
        body: {'message': text},
      );
      final reply = response.data?['reply'] as String? ?? _getFallbackReply(text);
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(_ChatMessage(text: _getFallbackReply(text), isUser: false));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  String _getFallbackReply(String question) {
    final q = question.toLowerCase();
    if (q.contains('hvac') || q.contains('heating') || q.contains('cooling')) {
      return 'HVAC (Heating, Ventilation, and Air Conditioning) maintenance involves regular filter changes (every 1-3 months), coil cleaning, refrigerant checks, and annual professional inspections. Key FM tasks include monitoring energy consumption and maintaining service logs.';
    } else if (q.contains('fire') || q.contains('safety')) {
      return 'Fire safety in FM includes: monthly inspection of fire extinguishers, quarterly fire alarm tests, annual sprinkler system checks, regular evacuation drills, and maintaining fire safety registers. Ensure all fire exits are clearly marked and unobstructed.';
    } else if (q.contains('vendor') || q.contains('supplier')) {
      return 'Effective vendor management in FM includes: defining clear SLAs, conducting regular performance reviews, maintaining vendor scorecards, ensuring compliance documentation, and building long-term relationships while keeping backup vendors for critical services.';
    } else if (q.contains('sla') || q.contains('service level')) {
      return 'SLA (Service Level Agreement) in FM defines the standards for service delivery - response times, resolution times, quality benchmarks, and penalties for non-compliance. Common FM SLAs cover helpdesk response (30 min), critical repairs (2-4 hours), and routine maintenance (24-48 hours).';
    } else if (q.contains('preventive') || q.contains('maintenance')) {
      return 'Preventive Maintenance (PM) is scheduled maintenance to prevent equipment failure. In FM, PM includes: daily checks, weekly inspections, monthly servicing, and annual overhauls. Benefits include reduced downtime, extended equipment life, and lower emergency repair costs.';
    } else if (q.contains('housekeeping') || q.contains('cleaning')) {
      return 'FM housekeeping standards include: daily sweeping and mopping, weekly deep cleaning, monthly sanitization drives, and quarterly pest control. Key metrics are cleanliness audits, complaint resolution time, and consumable usage tracking.';
    }
    return 'Great question about FM! Facility Management covers a wide range of disciplines including technical services, soft services, safety compliance, and administrative management. Could you be more specific about which area you\'d like to learn about?';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FM AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Online', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
        backgroundColor: const Color(0xFF1565C0),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0) + (_messages.length == 1 ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_messages.length == 1 && i == 1) {
                  return _buildSuggestions();
                }
                final idx = (_messages.length == 1 && i > 1) ? i - 1 : i;
                if (_loading && idx == _messages.length) {
                  return _buildTyping();
                }
                if (idx >= _messages.length) return const SizedBox();
                return _buildBubble(_messages[idx]);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suggested questions:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions.map((s) => GestureDetector(
              onTap: () => _sendMessage(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
                ),
                child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0))),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[  
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? const Color(0xFF1565C0) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(msg.text, style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87, fontSize: 13.5)),
            ),
          ),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]),
          child: const SizedBox(width: 40, child: LinearProgressIndicator(color: Color(0xFF1565C0))),
        ),
      ]),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Ask about FM...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF1565C0))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: _sendMessage,
            textInputAction: TextInputAction.send,
            maxLines: null,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _sendMessage(_controller.text),
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
