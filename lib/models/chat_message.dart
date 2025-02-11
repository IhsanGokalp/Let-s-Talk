class ChatMessage {
  String text;
  final bool isUser;
  String displayedText;
  bool isFinal;
  bool isComplete;
  DateTime timestamp;

  ChatMessage({
    required String initialText,
    required this.isUser,
    this.isFinal = false,
    this.isComplete = false,
    String? displayedText,
  })  : text = initialText,
        displayedText = displayedText ?? (isUser ? initialText : ''),
        timestamp =
            DateTime.now(); // Initialize timestamp when message is created

  void updateText(String newText) {
    text = newText;
    displayedText = newText;
  }
}
