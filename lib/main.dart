import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'services/whisper_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisper Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Whisper FFI Demo'),
    );
  }
}

// Enum to represent the state of the transcription process
enum TranscriptionState {
  initializing,
  loading,
  transcribing,
  success,
  error,
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final WhisperService _whisperService = WhisperService();
  TranscriptionState _state = TranscriptionState.initializing;
  String _transcription = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAndTranscribe();
  }

  @override
  void dispose() {
    _whisperService.dispose(); // Clean up native resources
    super.dispose();
  }

  Future<void> _initializeAndTranscribe() async {
    try {
      // Initialize the service
      setState(() => _state = TranscriptionState.initializing);
      await _whisperService.initialize();

      // Prepare the audio file asset
      setState(() => _state = TranscriptionState.loading);
      final audioPath = await _getPathFromAsset('assets/test.wav');

      // Start transcription
      setState(() => _state = TranscriptionState.transcribing);
      final result = await _whisperService.transcribe(audioPath);

      // Show result
      setState(() {
        _transcription = result;
        _state = TranscriptionState.success;
      });
    } catch (e) {
      // Handle errors
      setState(() {
        _errorMessage = e.toString();
        _state = TranscriptionState.error;
      });
    }
  }

  /// Helper function to copy an asset to a temporary file.
  Future<String> _getPathFromAsset(String asset) async {
    final byteData = await rootBundle.load(asset);
    final buffer = byteData.buffer;
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${asset.split('/').last}';
    await File(path).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  /// Builds the main content based on the current transcription state.
  Widget _buildContent() {
    switch (_state) {
      case TranscriptionState.initializing:
        return _buildStatusIndicator('Initializing Whisper...');
      case TranscriptionState.loading:
        return _buildStatusIndicator('Loading audio file...');
      case TranscriptionState.transcribing:
        return _buildStatusIndicator('Transcribing...');
      case TranscriptionState.success:
        return _buildResultView(_transcription);
      case TranscriptionState.error:
        return _buildResultView(_errorMessage, isError: true);
    }
  }

  Widget _buildStatusIndicator(String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(text),
      ],
    );
  }

  Widget _buildResultView(String text, {bool isError = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isError ? 'An Error Occurred:' : 'Transcription Result:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
