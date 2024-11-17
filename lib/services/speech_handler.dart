import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechHandler {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Function(String) onSpeechResult;
  bool isListening = false;

  SpeechHandler({required this.onSpeechResult});

  Future<void> startListening() async {
    if (!isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        _speechToText.listen(onResult: (result) {
          onSpeechResult(result.recognizedWords);
        });
        isListening = true;
      }
    }
  }

  void stopListening() {
    if (isListening) {
      _speechToText.stop();
      isListening = false;
    }
  }
}
