import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/conversation_service.dart';
import '../models/conversation_import_result.dart';

class ConversationHistoryPage extends StatefulWidget {
  @override
  _ConversationHistoryPageState createState() =>
      _ConversationHistoryPageState();
}

class _ConversationHistoryPageState extends State<ConversationHistoryPage> {
  final ConversationService _conversationService = ConversationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation History'),
      ),
      body: FutureBuilder<List<String>>(
        future: _conversationService.getConversationFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No saved conversations'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final filePath = snapshot.data![index];
              final fileName = filePath.split('/').last;

              try {
                final start = 'conversation_'.length;
                final end = fileName.lastIndexOf('.csv');
                final timestamp = fileName.substring(start, end);
                final parts = timestamp.split('_');

                final dateStr = parts[0];
                final timeStr = parts[1];

                final year = int.parse(dateStr.substring(0, 4));
                final month = int.parse(dateStr.substring(4, 6));
                final day = int.parse(dateStr.substring(6, 8));
                final hour = int.parse(timeStr.substring(0, 2));
                final minute = int.parse(timeStr.substring(2, 4));
                final second = int.parse(timeStr.substring(4, 6));

                final dateTime =
                    DateTime(year, month, day, hour, minute, second);
                final formattedDate =
                    DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    onTap: () async {
                      final result = await _conversationService
                          .importConversation(filePath);
                      Navigator.pop(context, result);
                    },
                  ),
                );
              } catch (e) {
                return ListTile(
                  title: Text(fileName),
                  subtitle: Text('Error loading conversation'),
                );
              }
            },
          );
        },
      ),
    );
  }
}
