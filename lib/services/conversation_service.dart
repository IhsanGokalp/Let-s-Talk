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
    buffer.writeln('Time,Speaker,Message');

    for (var message in messages) {
      buffer.writeln('${DateFormat('HH:mm:ss').format(message.timestamp)},'
          '${message.isUser ? "User" : "Assistant"},'
          '"${message.text.replaceAll('"', '""')}"');
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
      final text = parts[2].replaceAll('"', '');
      final isUser = parts[1] == "User";

      return ChatMessage(
        initialText: text,
        isUser: isUser,
        isFinal: true,
        isComplete: true,
      );
    }).toList();
  }
}
