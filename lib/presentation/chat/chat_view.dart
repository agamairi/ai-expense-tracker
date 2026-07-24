import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:ai_expense_tracker/domain/services/slm_engine_service.dart';
import 'package:ai_expense_tracker/data/database.dart';
import 'package:ai_expense_tracker/data/repositories/app_rule_repository_impl.dart';
import 'package:ai_expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:ai_expense_tracker/domain/models/transaction.dart' as model;
import 'package:ai_expense_tracker/domain/models/enums.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage("Hi! I'm your AI expense assistant. Tell me what you just bought, and I'll log it for you.", false),
  ];
  bool _isProcessing = false;
  bool _isModelReady = false;
  bool _isLoadingModelStatus = true;

  late final SlmEngineService _slmService;
  late final TransactionRepositoryImpl _transactionRepo;

  @override
  void initState() {
    super.initState();
    final db = AppDatabase.instance;
    final ruleRepo = AppRuleRepositoryImpl(db);
    _slmService = SlmEngineService(ruleRepo);
    _transactionRepo = TransactionRepositoryImpl(db);
    _initModelStatus();
  }

  Future<void> _initModelStatus() async {
    try {
      final models = await FlutterGemma.listInstalledModels();
      if (mounted) {
        if (models.isNotEmpty) {
          setState(() {
            _isModelReady = true;
            _isLoadingModelStatus = false;
          });
          _slmService.downloadAndInitialize(); // Just sets up the plugin
        } else {
          setState(() {
            _isModelReady = false;
            _isLoadingModelStatus = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isModelReady = false;
          _isLoadingModelStatus = false;
        });
      }
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text, true));
      _controller.clear();
      _isProcessing = true;
    });

    try {
      // Use Gemma to parse the transaction
      final parsedTx = await _slmService.processNotification("Chat Input", text);
      
      if (parsedTx != null) {
        // Auto-approve as per user request
        final approvedTx = parsedTx.copyWith(status: TransactionStatus.approved);
        
        // Save to DB
        final id = await _transactionRepo.insertTransaction(approvedTx);
        final finalTx = approvedTx.copyWith(id: id);

        if (mounted) {
          setState(() {
            _isProcessing = false;
            _messages.add(_ChatMessage(
              "I've logged \$${finalTx.amount.toStringAsFixed(2)} at ${finalTx.merchant} as ${finalTx.category.name.toUpperCase()}.\nIt has been auto-approved and added to your Audit Log.", 
              false, 
              transaction: finalTx
            ));
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _messages.add(_ChatMessage("I couldn't quite understand that transaction. Could you rephrase it?", false));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _messages.add(_ChatMessage("Error processing: $e\nMake sure you downloaded the AI model in Settings.", false));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("AI Assistant"),
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isLoadingModelStatus && !_isModelReady)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: colorScheme.errorContainer,
                child: Text(
                  "No AI model downloaded yet — go to Settings to download one.",
                  style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isProcessing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isProcessing) {
                    return _buildTypingIndicator(colorScheme);
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, colorScheme);
                },
              ),
            ),
            _buildInputArea(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text("Thinking...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, ColorScheme colorScheme) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: msg.isUser ? colorScheme.primary.withAlpha(40) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: msg.isUser ? Border.all(color: colorScheme.primary.withAlpha(80)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: msg.isUser ? colorScheme.primary : Colors.white),
            ),
            if (msg.transaction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/edit', arguments: msg.transaction),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("Edit Transaction", style: TextStyle(color: colorScheme.primary)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    final bool isDisabled = _isLoadingModelStatus || !_isModelReady;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !isDisabled,
              decoration: InputDecoration(
                hintText: isDisabled ? "Model required to chat" : "E.g., Bought coffee for \$4.50...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
              ),
              onSubmitted: isDisabled ? null : (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: isDisabled ? Colors.grey : colorScheme.primary),
            onPressed: isDisabled ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final model.Transaction? transaction;

  _ChatMessage(this.text, this.isUser, {this.transaction});
}
