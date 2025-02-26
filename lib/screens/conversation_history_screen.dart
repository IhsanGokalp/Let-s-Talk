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

  String _formatTimestamp(String filePath) {
    try {
      // Get just the filename from the full path and print for debugging
      final fileName = filePath.split('/').last;
      print('Original filename: $fileName');

      // Check for valid filename format
      if (!fileName.startsWith('conversation_') || !fileName.endsWith('.csv')) {
        print('Invalid filename format: $fileName');
        return fileName;
      }

      // Extract timestamp part (yyyyMMdd_HHmmss)
      String timestampPart = fileName.substring(12, fileName.length - 4);
      print('Extracted timestamp part: $timestampPart');

      // Split into date and time components
      List<String> parts = timestampPart.split('_');
      if (parts.length != 2) {
        print('Invalid timestamp format, parts: ${parts.length}');
        return fileName;
      }

      String dateStr = parts[0];
      String timeStr = parts[1];
      print('Date string: $dateStr, Time string: $timeStr');

      // Parse date components
      int year = int.parse(dateStr.substring(0, 4));
      int month = int.parse(dateStr.substring(4, 6));
      int day = int.parse(dateStr.substring(6, 8));

      // Parse time components
      int hour = int.parse(timeStr.substring(0, 2));
      int minute = int.parse(timeStr.substring(2, 4));
      int second = int.parse(timeStr.substring(4, 6));

      print(
          'Parsed components: y=$year, m=$month, d=$day, h=$hour, min=$minute, s=$second');

      DateTime dateTime = DateTime(year, month, day, hour, minute, second);
      String formatted = DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);
      print('Formatted result: $formatted');

      return formatted;
    } catch (e, stackTrace) {
      print('Error parsing date from filepath: $filePath');
      print('Error details: $e');
      print('Stack trace: $stackTrace');
      return filePath.split('/').last;
    }
  }

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

          final files = snapshot.data ?? [];
          if (files.isEmpty) {
            return Center(child: Text('No saved conversations'));
          }

          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final filePath = files[index];
              print('ListView processing file path: $filePath');

              // Extract filename for debugging
              final fileName = filePath.split('/').last;
              print('Extracted filename: $fileName');

              // Try to format timestamp
              String formattedDate;
              try {
                formattedDate = _formatTimestamp(filePath);
                print('Successfully formatted date: $formattedDate');
              } catch (e) {
                print('Error formatting timestamp: $e');
                formattedDate = fileName;
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(formattedDate),
                      ),
                      Text(DateFormat('HH:mm').format(
                          DateTime.now())), // Current time for debugging
                    ],
                  ),
                  subtitle: FutureBuilder<ConversationImportResult>(
                    future: _conversationService.importConversation(filePath),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Error loading conversation: ${snapshot.error}');
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData) {
                        return Text('Loading...');
                      }
                      print(
                          'Loaded conversation description: ${snapshot.data?.description}');
                      return Text(
                          snapshot.data?.description ?? 'No description');
                    },
                  ),
                  leading: Icon(Icons.history),
                  onTap: () async {
                    try {
                      final result = await _conversationService
                          .importConversation(filePath);
                      Navigator.pop(context, result);
                    } catch (e) {
                      print('Error on tap: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error loading conversation: $e')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
