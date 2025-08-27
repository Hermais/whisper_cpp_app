import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'logic/cubit/transcription_cubit.dart';
import 'services/audio_service.dart';
import 'services/whisper_service.dart';
import 'widgets/recording_controls.dart';

void main() {
  // bindings initialization
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisper Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      // Provide both services to the TranscriptionCubit
      home: BlocProvider(
        create: (context) => TranscriptionCubit(WhisperService(), AudioService()),
        child: const MyHomePage(title: 'Whisper FFI Demo'),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: BlocBuilder<TranscriptionCubit, TranscriptionState>(
            builder: (context, state) {
              if (state is TranscriptionLoading) {
                return _buildStatusIndicator(context, state.message);
              } else if (state is TranscriptionSuccess) {
                return _buildResultView(context, state.transcription);
              } else if (state is TranscriptionError) {
                return _buildResultView(context, state.message, isError: true);
              } else if (state is Recording) {
                return _buildStatusIndicator(context, 'Recording...', showControls: true);
              } else if (state is PlaybackInProgress) {
                return _buildStatusIndicator(context, 'Playing back...', showControls: true);
              }
              // For Initial, RecordingStopped, and others, show the main controls.
              return _buildRecordingView(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingView(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Text('Press the record button to start recording.'),
          ),
        ),
        RecordingControls(),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context, String text, {bool showControls = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(text),
        if (showControls) ...[
          const Spacer(),
          const RecordingControls(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildResultView(BuildContext context, String text, {bool isError = false}) {
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
        const SizedBox(height: 20),
        const RecordingControls(),
        const SizedBox(height: 20),
      ],
    );
  }
}
