import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_store.dart';
import '../../widgets/glass_card.dart';

class LifeOsAiScreen extends ConsumerStatefulWidget {
  const LifeOsAiScreen({super.key});

  @override
  ConsumerState<LifeOsAiScreen> createState() => _LifeOsAiScreenState();
}

class _LifeOsAiScreenState extends ConsumerState<LifeOsAiScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechToText();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: 'assistant',
      text: 'I am LifeOS AI. Tell me what you want to improve today and I will turn it into a small plan.',
    ),
  ];
  var _provider = 'local';
  var _listening = false;
  var _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? prompt]) async {
    final text = (prompt ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _controller.clear();
      _loading = true;
      _messages.add(_ChatMessage(role: 'user', text: text));
    });
    await LocalStore.aiCache.add({'role': 'user', 'content': text, 'createdAt': DateTime.now().toIso8601String()});

    try {
      final response = await ref.read(apiClientProvider).postJson('/ai/chat', {
        'provider': _provider,
        'messages': _messages.map((message) => {'role': message.role, 'content': message.text}).toList(),
      });
      final data = Map<String, dynamic>.from(response['data'] as Map);
      final answer = data['content'] as String? ?? 'I could not generate a response right now.';
      setState(() => _messages.add(_ChatMessage(role: 'assistant', text: answer)));
      await LocalStore.aiCache.add({'role': 'assistant', 'content': answer, 'provider': data['provider'], 'createdAt': DateTime.now().toIso8601String()});
    } catch (_) {
      const fallback = 'Offline coach: choose one tiny action, set a 25-minute timer, log the result, and restart smaller if you miss.';
      setState(() => _messages.add(const _ChatMessage(role: 'assistant', text: fallback)));
    } finally {
      if (mounted) setState(() => _loading = false);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  Future<void> _listen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ready = await _speech.initialize();
    if (!ready) return;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) => setState(() => _controller.text = result.recognizedWords),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LifeOS AI', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const Text('Coach, planner, study mentor, finance analyst, and recovery companion.'),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: _provider,
                items: const [
                  DropdownMenuItem(value: 'local', child: Text('Local')),
                  DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
                  DropdownMenuItem(value: 'openrouter', child: Text('OpenRouter')),
                  DropdownMenuItem(value: 'ollama', child: Text('Ollama')),
                  DropdownMenuItem(value: 'lmstudio', child: Text('LM Studio')),
                ],
                onChanged: (value) => setState(() => _provider = value ?? 'local'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final prompt = AppConstants.aiPrompts[index];
              return ActionChip(
                avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(prompt),
                onPressed: () => _send(prompt),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: AppConstants.aiPrompts.length,
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _messages.length) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: GlassCard(child: Text('LifeOS AI is thinking...')),
                );
              }
              final message = _messages[index];
              final isUser = message.role == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: isUser
                          ? Text(message.text)
                          : MarkdownBody(
                              data: message.text,
                              selectable: true,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _listen,
                  icon: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded),
                  tooltip: 'Voice input',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration.collapsed(hintText: 'Ask for a plan, analysis, or challenge'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton.filled(
                  onPressed: _loading ? null : () => _send(),
                  icon: const Icon(Icons.send_rounded),
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final String role;
  final String text;
}

