# Let's Talk - AI Language Learning Assistant

Let's Talk is a Flutter application designed to help users practice language learning through interactive conversations with an AI assistant named Elif. The app uses speech recognition, text-to-speech, and OpenAI's GPT model to create a natural language learning experience.

## Features

- **Real-time Speech Recognition**: Capture user's speech and convert it to text
- **AI-Powered Conversations**: Interact with an AI assistant (Elif) for language practice
- **Text-to-Speech**: Listen to AI responses with natural voice synthesis
- **Focus Areas**:
  - Grammar practice
  - Pronunciation guidance
- **Conversation Management**:
  - Save conversations as CSV files
  - Load and review past conversations
- **Visual Feedback**: Dynamic waveform animation during speech recognition

## Setup

1. Clone the repository
2. Create a `.env` file in the `assets` folder using `.env.example` as template
3. Add your OpenAI API key to the `.env` file:

OPENAI_API_KEY=your_api_key_here

## Dependencies

Add the following to your `pubspec.yaml`:

yaml
dependencies:
flutter:
sdk: flutter
speech_to_text: ^latest_version
flutter_dotenv: ^latest_version
path_provider: ^latest_version
csv: ^latest_version


## Getting Started

1. Ensure Flutter is installed and set up on your system
2. Run `flutter pub get` to install dependencies
3. Configure your OpenAI API key in the `.env` file
4. Run the app using `flutter run`

## Usage

1. Launch the app and select your preferred language focus (Grammar/Pronunciation)
2. Tap "Start Listening" to begin a conversation
3. Speak clearly into your device's microphone
4. Wait for Elif's response, which will be displayed and spoken
5. Save interesting conversations using the "Save Conversation" button
6. Review past conversations using the load feature

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
