import 'package:flutter/material.dart';
import 'package:lets_tallk/models/user_data.dart';
import 'package:lets_tallk/services/chatgpt_service_handler.dart';
import 'package:lets_tallk/services/speech_handler.dart';
import 'package:lets_tallk/services/tts_service_handler.dart';
import 'package:lets_tallk/widgets/dot_waveform_animator.dart';
import 'package:lets_tallk/config/env_config.dart';
import 'dart:async'; // Add this import at the top

class ConversationActivity extends StatefulWidget {
  final UserData userData;

  const ConversationActivity({Key? key, required this.userData})
      : super(key: key);

  @override
  _ConversationActivityState createState() => _ConversationActivityState();
}

class ChatMessage {
  String text;
  final bool isUser;
  String displayedText;
  bool isFinal;
  bool isComplete;

  ChatMessage({
    required String initialText,
    required this.isUser,
    this.isFinal = false,
    this.isComplete = false,
  })  : text = initialText,
        displayedText = isUser
            ? initialText
            : ''; // Initialize empty for assistant messages

  void updateText(String newText) {
    text = newText;
    displayedText = newText;
  }
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

  Timer? _speechTimeout;
  static const int SPEECH_COMPLETION_DELAY = 1500; // 1.5 seconds

  void _finalizeAndSendSpeech(String recognizedText) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.isUser) {
        _messages.last.isFinal = true;
        _messages.last.isComplete = true;
      }
      _isListening = false;
    });

    _sendToChatGPT(recognizedText);
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
    });
  }

  @override
  void onComplete() {
    debugPrint('TTS Complete');
    setState(() {
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages.last.displayedText = _messages.last.text;
        _messages.last.isComplete = true;
      }
      _isSpeaking = false;
      _isProcessing = false;
      // Don't end conversation here
      _isConversationActive = true; // Keep conversation active
      _startListening(); // Auto-start listening for next input
    });
  }

  void _startConversation() {
    setState(() {
      _isConversationActive = true;
      _isListening = true;
      _conversationEnded = false; // Reset conversation end state
    });

    _startListening();
  }

  void _startListening() {
    if (!_isConversationActive) return;

    _speechHandler?.startListening((String text) {
      setState(() {
        _recognizedText = text;
        _processSpeechResult(text, false);
      });
    });

    setState(() {
      _isListening = true;
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
      ));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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

    _speechTimeout?.cancel();
    _speechTimeout = Timer(Duration(milliseconds: SPEECH_COMPLETION_DELAY), () {
      if (mounted && _isListening) {
        _finalizeAndSendSpeech(recognizedText);
      }
    });

    setState(() {
      _recognizedText = recognizedText;
      if (_messages.isEmpty ||
          (_messages.last.isUser && _messages.last.isFinal)) {
        _messages.add(ChatMessage(
          initialText: recognizedText,
          isUser: true,
          isFinal: false,
        ));
      } else if (_messages.last.isUser) {
        _messages.last.updateText(recognizedText);
      }
    });

    _scrollToBottom();
  }

  void _stopListening() {
    _speechHandler?.stopListening();
    setState(() {
      // Update UI to reflect that listening has stopped
      _isListening = false; // Now this variable is defined
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
          message.displayedText, // Make sure to use displayedText here
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
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
          // Add conversation state indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (_isProcessing)
                  Icon(Icons.sync, color: Colors.orange)
                else if (_speechHandler?.isListening ?? false)
                  Icon(Icons.mic, color: Colors.green)
                else if (_ttsServiceHandler?.isPlaying ?? false)
                  Icon(Icons.volume_up, color: Colors.blue)
                else
                  Icon(Icons.mic_off, color: Colors.red),
                SizedBox(width: 8),
                Text(_getStatusText()),
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
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildMessageBubble(_messages[index]),
              ),
            ),
            if (_ttsServiceHandler?.isPlaying ?? false)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentWord,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20),
            Center(
              child: DotWaveformAnimator(
                isVisible: (_speechHandler?.isListening ?? false) &&
                    _isConversationActive,
                soundLevelStream: _speechHandler?.soundLevelStream,
              ),
            ),
            if (_isListening && _recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _recognizedText,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _startConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    _isConversationActive
                        ? "Conversation Active"
                        : "Start Conversation",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: _stopConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isConversationActive ? Colors.red : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    "End Conversation",
                    style: TextStyle(fontSize: 18),
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
