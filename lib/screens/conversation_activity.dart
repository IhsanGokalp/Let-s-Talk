import 'package:flutter/material.dart';
import 'package:lets_tallk/models/user_data.dart';
import 'package:lets_tallk/services/chatgpt_service_handler.dart';
import 'package:lets_tallk/services/speech_handler.dart';
import 'package:lets_tallk/services/tts_service_handler.dart';
import 'package:lets_tallk/widgets/dot_waveform_animator.dart';
import 'package:lets_tallk/config/env_config.dart';
import 'dart:async'; // Add this import at the top
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:lets_tallk/services/conversation_service.dart';
import 'package:lets_tallk/models/chat_message.dart'; // Add this import
import '../models/conversation_import_result.dart';

class ConversationActivity extends StatefulWidget {
  final UserData userData;

  const ConversationActivity({Key? key, required this.userData})
      : super(key: key);

  @override
  _ConversationActivityState createState() => _ConversationActivityState();
}

class _ConversationActivityState extends State<ConversationActivity>
    implements TextToSpeechCallback {
  SpeechHandler? _speechHandler;
  TTSServiceHandler? _ttsServiceHandler;
  ChatGPTServiceHandler? _chatGPTServiceHandler;
  final TextEditingController _conversationController = TextEditingController();
  bool _isProcessing = false;
  bool _isConversationActive = false;
  bool _isSpeaking = false;
  bool _hasTalked = false;
  bool _conversationEnded = false;
  final List<Map<String, String>> _conversationHistory = [];
  String _recognizedText = '';
  bool _isListening = false;
  String _aiResponse = '';

  String _currentWord = '';

  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ConversationService _conversationService = ConversationService();

  Timer? _speechTimeout;
  static const int SPEECH_COMPLETION_DELAY = 1500; // 1.5 seconds

  static const int PAUSE_THRESHOLD = 2000; // 2 seconds for end of speech
  static const int SHORT_PAUSE = 500; // 0.5 seconds for normal pauses
  Timer? _pauseTimer;
  bool _isInitializing = true;

  void _finalizeAndSendSpeech(String recognizedText) {
    if (!mounted) return;

    // Only send if the message isn't already finalized
    if (_messages.isNotEmpty &&
        _messages.last.isUser &&
        !_messages.last.isFinal) {
      setState(() {
        _messages.last.isFinal = true;
        _isListening = false;
      });

      _sendToChatGPT(recognizedText);
    }
  }

  @override
  void onProgress(String word) {
    if (!mounted) return;
    if (_messages.isNotEmpty && !_messages.last.isUser) {
      setState(() {
        _messages.last.displayedText += ' $word';
      });
      _scrollToBottom();
    }
  }

  @override
  void onStart(String text) {
    debugPrint('Started speaking: $text');
    setState(() {
      _isSpeaking = true;
      _stopListening(); // Stop listening when TTS starts
    });
  }

  void _stopListening() {
    _speechHandler?.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void onComplete() {
    debugPrint('TTS Complete');
    setState(() {
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages.last.isFinal = true;
        _messages.last.displayedText = _messages.last.text;
      }
      _isSpeaking = false;
      _isProcessing = false;

      // Auto-start listening after TTS completes
      if (_isConversationActive && !_conversationEnded) {
        _startListening();
      }
    });
  }

  void _startConversation() {
    if (_conversationEnded) {
      _showWarningDialog();
      return;
    }

    setState(() {
      _isConversationActive = true;
      _isInitializing = true;
      _conversationEnded = false;
    });

    // Start listening immediately when conversation starts
    _startListening();
  }

  void _sendInitialPrompt() {
    final initialPrompt =
        "Hello, I'm ${widget.userData.selectedBuddy}. Let's talk about ${widget.userData.selectedTopics}.";
    _chatGPTServiceHandler?.generateTextAndConvertToSpeech(
      initialPrompt,
      _conversationHistory,
    );
  }

  void _startListening() {
    _speechHandler?.startListening((String text) {
      setState(() {
        _recognizedText = text;
        _isListening = true;
        _processSpeechResult(
            text, false); // Changed to false to prevent immediate sending
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeHandlers();

    // Add speech initialization status check
    _speechHandler?.initializeAndCheck().then((_) {
      setState(() {}); // Trigger rebuild after initialization
    });
  }

  void _initializeHandlers() {
    _speechHandler = SpeechHandler(
      context: context,
      conversationController: _conversationController,
    );

    _ttsServiceHandler = TTSServiceHandler(
      apiKey: EnvConfig.openAiApiKey,
    );
    _ttsServiceHandler?.setCallback(this);

    _chatGPTServiceHandler = ChatGPTServiceHandler(
      apiKey: EnvConfig.openAiApiKey,
      onResponse: _onAIResponse,
      onError: _onAIError,
      ttsServiceHandler: _ttsServiceHandler!,
    );

    _speechHandler?.setOnSpeechResult((recognizedText) {
      _processSpeechResult(recognizedText, true);
    });
  }

  void _sendToChatGPT(String userInput) {
    setState(() {
      _isProcessing = true;
    });

    _conversationHistory.add({"role": "user", "content": userInput});

    _chatGPTServiceHandler
        ?.generateTextAndConvertToSpeech(
      userInput,
      _conversationHistory,
    )
        .then((_) {
      setState(() {
        _isProcessing = false;
      });
    }).catchError((error) {
      debugPrint('Error sending to ChatGPT: $error');
      _onAIError(error.toString());
    });
  }

  void _onAIResponse(String response) {
    if (response.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        initialText: response,
        isUser: false,
        isFinal: false,
        displayedText: '', // Start empty for assistant messages
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onAIError(String error) {
    debugPrint('AI Error: $error');
    setState(() {
      _isProcessing = false;
      _conversationController.text += "Error: $error\n\n";
    });
  }

  void _stopConversation() {
    if (_hasTalked) {
      _showPurchaseDialog();
    } else {
      _speechHandler?.stopListening();
      setState(() {
        _isConversationActive = false;
        _isProcessing = false;
        _conversationEnded = true;
      });
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              title: Text(
                "Warning",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: double.maxFinite,
                  child: Text(
                    "You have already completed a conversation. Please purchase the app to continue.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(88, 36),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Purchase Required"),
          content: Text(
              "You have reached the limit for free conversations. Please purchase the app to continue."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Purchase"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _speechHandler?.dispose();
    _conversationController.dispose();
    _ttsServiceHandler?.dispose();
    super.dispose();
  }

  void _processSpeechResult(String recognizedText, bool isFinal) {
    if (!mounted) return;

    _pauseTimer?.cancel();
    _pauseTimer = Timer(Duration(milliseconds: PAUSE_THRESHOLD), () {
      if (mounted && _isListening) {
        _finalizeAndSendSpeech(recognizedText);
      }
    });

    setState(() {
      _recognizedText = recognizedText;
      if (_messages.isEmpty || _messages.last.isFinal) {
        _messages.add(ChatMessage(
          initialText: recognizedText,
          isUser: true,
          isFinal: false,
        ));
      } else if (_messages.last.isUser) {
        _messages.last.updateText(recognizedText);
      }
    });
  }

  void _onFinalSpeechResult(String recognizedText) {
    if (!mounted) return;

    setState(() {
      if (_messages.isNotEmpty && _messages.last.isUser) {
        _messages.last.isFinal = true;
        _messages.last.text = recognizedText;
        _messages.last.displayedText = recognizedText;
      }
      _isProcessing = true;
    });

    _chatGPTServiceHandler?.generateTextAndConvertToSpeech(
      recognizedText,
      _conversationHistory,
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.displayedText,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _showHistoryDialog() async {
    final files = await _conversationService.getConversationFiles();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Saved Conversations'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              itemBuilder: (context, index) {
                final filePath = files[index];
                final fileName = filePath.split('/').last;
                print('Processing file: $fileName'); // Debug print

                try {
                  // Extract timestamp between 'conversation_' and '.csv'
                  final start = 'conversation_'.length;
                  final end = fileName.lastIndexOf('.csv');
                  final timestamp = fileName.substring(start, end);
                  print('Extracted timestamp: $timestamp'); // Debug print

                  // Split into date and time parts
                  final parts = timestamp.split('_');
                  if (parts.length != 2) {
                    throw FormatException('Invalid timestamp format');
                  }

                  final dateStr = parts[0]; // yyyyMMdd
                  final timeStr = parts[1]; // HHmmss
                  print('Date: $dateStr, Time: $timeStr'); // Debug print

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
                  print('Formatted date: $formattedDate'); // Debug print

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(formattedDate),
                      subtitle: FutureBuilder<ConversationImportResult>(
                        future:
                            _conversationService.importConversation(filePath),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                                snapshot.data?.description ?? 'No description');
                          }
                          return Text('Loading...');
                        },
                      ),
                      leading: Icon(Icons.history),
                      onTap: () => Navigator.pop(context, filePath),
                    ),
                  );
                } catch (e) {
                  print('Error parsing date: $e\nFilename: $fileName');
                  return ListTile(
                    title: Text(fileName),
                    subtitle: Text('Error loading conversation'),
                  );
                }
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      final importResult =
          await _conversationService.importConversation(result);
      setState(() {
        _messages.clear();
        _messages.addAll(importResult.messages);
      });
    }
  }

  Future<void> _exportConversation() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'conversation_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');

      final buffer = StringBuffer();
      buffer.writeln('Time,Speaker,Message');

      for (var message in _messages) {
        buffer.writeln('${DateFormat('HH:mm:ss').format(message.timestamp)},'
            '${message.isUser ? "User" : "Assistant"},'
            '"${message.text.replaceAll('"', '""')}"');
      }

      await file.writeAsString(buffer.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation saved to: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save conversation: $e')),
      );
    }
  }

  Future<void> _showSaveDialog() async {
    String? description;
    try {
      // Generate description using ChatGPT
      description =
          await _chatGPTServiceHandler?.generateDescription(_messages);
    } catch (e) {
      print('Error generating description: $e');
    }

    final TextEditingController descriptionController = TextEditingController(
        text: description ??
            "Conversation ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}");

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save Conversation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Generated Description:'),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter conversation description',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () =>
                  Navigator.pop(context, descriptionController.text),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        final path = await _conversationService.exportConversation(_messages,
            description: result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversation saved')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save conversation')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Building UI - isProcessing: $_isProcessing, isConversationActive: $_isConversationActive, isListening: ${_speechHandler?.isListening}');

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userData.name} Let's Talk"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _showHistoryDialog,
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed:
                _showSaveDialog, // Change this line to call _showSaveDialog
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing)
                  Icon(Icons.sync, color: Colors.orange, size: 20)
                else if (_speechHandler?.isListening ?? false)
                  Icon(Icons.mic, color: Colors.green, size: 20)
                else if (_ttsServiceHandler?.isPlaying ?? false)
                  Icon(Icons.volume_up, color: Colors.blue, size: 20)
                else
                  Icon(Icons.mic_off, color: Colors.red, size: 20),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _getStatusText(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message History
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildMessageBubble(_messages[index]),
              ),
            ),

            Column(
              children: [
                // Current Assistant Message
                // if (_ttsServiceHandler?.isPlaying ?? false)
                //   Align(
                //     alignment: Alignment.centerLeft,
                //     child: Container(
                //       margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                //       padding:
                //           EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                //       decoration: BoxDecoration(
                //         color: Colors.green[100],
                //         borderRadius: BorderRadius.circular(20),
                //       ),
                //       child: Text(
                //         _currentWord,
                //         style: TextStyle(fontSize: 16, color: Colors.black87),
                //       ),
                //     ),
                //   ),

                // Current User Message
                // if (_isListening && _recognizedText.isNotEmpty)
                //   Align(
                //     alignment: Alignment.centerRight,
                //     child: Container(
                //       margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                //       padding:
                //           EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                //       decoration: BoxDecoration(
                //         color: Colors.blue[100],
                //         borderRadius: BorderRadius.circular(20),
                //       ),
                //       child: Text(
                //         _recognizedText,
                //         style: TextStyle(fontSize: 16, color: Colors.black87),
                //       ),
                //     ),
                //   ),

                SizedBox(height: 20),

                // Other UI components
                Center(
                  child: DotWaveformAnimator(
                    isVisible: (_speechHandler?.isListening ?? false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: _startConversation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        _isConversationActive ? "Active" : "Start",
                        style: TextStyle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: _stopConversation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isConversationActive ? Colors.red : Colors.grey,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        "End",
                        style: TextStyle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isProcessing) Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_isProcessing) return 'Processing...';
    if (_speechHandler?.isListening ?? false) return 'Listening';
    if (_ttsServiceHandler?.isPlaying ?? false) return 'Speaking';
    if (_isConversationActive) return 'Ready';
    return 'Inactive';
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
