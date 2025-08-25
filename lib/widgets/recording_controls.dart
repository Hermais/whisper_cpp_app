import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubit/transcription_cubit.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranscriptionCubit, TranscriptionState>(
      builder: (context, state) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state is TranscriptionInitial ||
                state is TranscriptionSuccess ||
                state is TranscriptionError) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.mic),
                onPressed: () =>
                    context.read<TranscriptionCubit>().startRecording(),
                label: const Text('Record'),
              ),
            ],
            if (state is Recording) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                onPressed: () =>
                    context.read<TranscriptionCubit>().stopRecording(),
                label: const Text('Stop Recording'),
              ),
            ],
            if (state is RecordingStopped) ...[
              const Text("Recording finished. Play it back or transcribe."),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () =>
                        context.read<TranscriptionCubit>().playRecording(),
                    label: const Text('Play'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.translate),
                    onPressed: () =>
                        context.read<TranscriptionCubit>().transcribeRecording(),
                    label: const Text('Transcribe'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.mic_none),
                onPressed: () =>
                    context.read<TranscriptionCubit>().startRecording(),
                label: const Text('New Record'),
              ),
            ],
            if (state is PlaybackInProgress) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: () =>
                    context.read<TranscriptionCubit>().stopPlayback(),
                label: const Text('Stop Playback'),
              ),
            ]
          ],
        );
      },
    );
  }
}
