import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/conversation_import_result.dart';

class ConversationService {
  Future<String> exportConversation(List<ChatMessage> messages,
      {String? description}) async {
    try {
      final directory = await _getOrCreateDirectory();
      print('>> Saving conversation to directory: ${directory.path}');
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'conversation_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      print('>> File will be: ${file.path}');

      final csvContent = [
        'Timestamp,Sender,Message,IsFinal\n',
        'Description:${description ?? "Conversation"}\n' // Add description line
      ];

      for (var message in messages) {
        csvContent.add('${DateFormat('HH:mm:ss').format(message.timestamp)},'
            '${message.isUser ? "User" : "Assistant"},'
            '"${message.displayedText}",'
            '${message.isFinal}\n');
      }

      await file.writeAsString(csvContent.join());
      print('>> Conversation successfully saved.');
      return file.path;
    } catch (e) {
      print('Export error: $e');
      throw Exception('Failed to export conversation: $e');
    }
  }

  Future<Directory> _getOrCreateDirectory() async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();

      // Ensure base directory exists
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }
      print('Base directory path: ${baseDir.path}');

      // Create or get the conversations subdirectory
      final conversationsDir = Directory('${baseDir.path}/conversations');
      if (!await conversationsDir.exists()) {
        await conversationsDir.create(recursive: true);
        print('Created conversations directory at: ${conversationsDir.path}');
      } else {
        print(
            'Using existing conversations directory at: ${conversationsDir.path}');
      }

      return conversationsDir;
    } catch (e) {
      print('Directory error: $e');
      // Fallback to base directory if something goes wrong.
      final baseDir = await getApplicationDocumentsDirectory();
      return baseDir;
    }
  }

  Future<List<String>> getConversationFiles() async {
    try {
      final directory = await _getOrCreateDirectory();
      print('Listing CSV files in: ${directory.path}');
      final files = directory
          .listSync()
          .where((file) => file.path.toLowerCase().endsWith('.csv'))
          .map((file) => file.path)
          .toList();

      print('Files found: $files');
      return files;
    } catch (e) {
      print('Error accessing conversation files: $e');
      return [];
    }
  }

  Future<void> deleteConversation(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<ConversationImportResult> importConversation(String filePath) async {
    try {
      final file = File(filePath);
      final lines = await file.readAsLines();

      // Assume first line is the header and second is the description line
      String description = "Conversation";
      if (lines.length > 1 && lines[1].startsWith('Description:')) {
        description = lines[1].substring('Description:'.length);
      }

      // Remove header and description line before processing messages
      final messageLines = lines.skip(2);

      final messages = messageLines
          .map((line) {
            // Expect line format: Timestamp,Sender,Message,IsFinal
            // Note: This simple split might not work if the message itself includes commas.
            final parts = line.split(',');
            if (parts.length < 4) return null;
            final timeString = parts[0];
            final sender = parts[1];
            final messageText = parts[2].replaceAll('"', '');
            final isFinal = parts[3].trim().toLowerCase() == 'true';

            // Parse only time (assuming the date is not saved in the message)
            final timestamp = DateFormat('HH:mm:ss').parse(timeString);

            return ChatMessage(
              initialText: messageText,
              isUser: sender == "User",
              isFinal: isFinal,
              isComplete: true,
              displayedText: messageText,
            );
          })
          .whereType<ChatMessage>()
          .toList();

      return ConversationImportResult(
          messages: messages, description: description);
    } catch (e) {
      throw Exception('Failed to import conversation: $e');
    }
  }
}
