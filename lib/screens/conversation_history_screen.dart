import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lets_tallk/services/conversation_service.dart';
import 'package:lets_tallk/models/chat_message.dart';
import '../models/conversation_import_result.dart';

class ConversationHistoryScreen extends StatefulWidget {
  @override
  _ConversationHistoryScreenState createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  final ConversationService _conversationService = ConversationService();
  List<String> _files = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final files = await _conversationService.getConversationFiles();
    setState(() {
      _files = files;
    });
  }

  String _formatTimestamp(String fileName) {
    try {
      // Extract timestamp from filename (conversation_yyyyMMdd_HHmmss.csv)
      final regex = RegExp(
          r'conversation_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.csv');
      final match = regex.firstMatch(fileName);

      if (match != null) {
        final year = match.group(1);
        final month = match.group(2);
        final day = match.group(3);
        final hour = match.group(4);
        final minute = match.group(5);
        final second = match.group(6);

        if (year != null &&
            month != null &&
            day != null &&
            hour != null &&
            minute != null &&
            second != null) {
          final dateTime = DateTime(
              int.parse(year),
              int.parse(month),
              int.parse(day),
              int.parse(hour),
              int.parse(minute),
              int.parse(second));

          return DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);
        }
      }
      return fileName;
    } catch (e) {
      print('Error parsing date: $e');
      return fileName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation History'),
      ),
      body: _files.isEmpty
          ? Center(child: Text('No saved conversations'))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final filePath = _files[index];
                final fileName = filePath.split('/').last;
                final formattedDate = _formatTimestamp(fileName);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(formattedDate),
                    subtitle: FutureBuilder<ConversationImportResult>(
                      future: _conversationService.importConversation(filePath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                              snapshot.data?.description ?? 'No description');
                        }
                        return Text('Loading...');
                      },
                    ),
                    leading: Icon(Icons.history),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await _conversationService.deleteConversation(filePath);
                        _loadConversations();
                      },
                    ),
                    onTap: () async {
                      final importResult = await _conversationService
                          .importConversation(filePath);
                      Navigator.pop(context, importResult);
                    },
                  ),
                );
              },
            ),
    );
  }
}
