import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class ConversationService {
  Future<String> exportConversation(List<ChatMessage> messages) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'conversation_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');

    final buffer = StringBuffer();
    buffer.writeln('Time,Speaker,Message,IsFinal');

    for (var message in messages) {
      // Use text instead of displayedText for assistant messages
      final messageText = message.isUser ? message.displayedText : message.text;
      buffer.writeln('${DateFormat('HH:mm:ss').format(message.timestamp)},'
          '${message.isUser ? "User" : "Assistant"},'
          '"${messageText.replaceAll('"', '""')}",'
          '${message.isFinal}');
    }

    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<List<String>> getConversationFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory
        .listSync()
        .where((file) => file.path.endsWith('.csv'))
        .map((file) => file.path)
        .toList();
  }

  Future<List<ChatMessage>> importConversation(String filePath) async {
    final file = File(filePath);
    final lines = await file.readAsLines();

    return lines.skip(1).map((line) {
      final parts = line.split(',');
      final timestamp = DateFormat('HH:mm:ss').parse(parts[0]);
      final isUser = parts[1] == "User";
      final text = parts[2].replaceAll('"', '');
      final isFinal = parts[3] == 'true';

      return ChatMessage(
        initialText: text,
        isUser: isUser,
        isFinal: true,
        isComplete: true,
        displayedText: text, // Set displayed text for both user and assistant
      );
    }).toList();
  }
}
