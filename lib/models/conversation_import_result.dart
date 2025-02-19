import 'chat_message.dart';

class ConversationImportResult {
  final List<ChatMessage> messages;
  final String description;

  ConversationImportResult({
    required this.messages,
    required this.description,
  });
}
