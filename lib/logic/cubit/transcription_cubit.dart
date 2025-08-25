import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/whisper_service.dart';
import '../../services/audio_service.dart';

part '../models/transcription_state.dart';

class TranscriptionCubit extends Cubit<TranscriptionState> {
  final WhisperService _whisperService;
  final AudioService _audioService;

  TranscriptionCubit(this._whisperService, this._audioService) : super(TranscriptionInitial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      emit(const TranscriptionLoading('Initializing...'));
      await _whisperService.initialize();
      await _audioService.initialize();
      emit(TranscriptionInitial());
    } catch (e) {
      emit(TranscriptionError(e.toString()));
    }
  }

  Future<void> startRecording() async {
    try {
      await _audioService.startRecording();
      emit(Recording());
    } catch (e) {
      emit(TranscriptionError(e.toString()));
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioService.stopRecording();
      if (path != null) {
        emit(RecordingStopped(path));
      } else {
        emit(TranscriptionInitial()); // Go back to initial if path is null
      }
    } catch (e) {
      emit(TranscriptionError(e.toString()));
    }
  }

  Future<void> playRecording() async {
    if (state is RecordingStopped) {
      final path = (state as RecordingStopped).path;
      try {
        emit(PlaybackInProgress(path));
        // The callback will be called by the service when playback finishes
        await _audioService.startPlayback(() {
          // When playback is done, go back to the stopped state
          if (state is PlaybackInProgress) {
            emit(RecordingStopped(path));
          }
        });
      } catch (e) {
        emit(TranscriptionError(e.toString()));
      }
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _audioService.stopPlayback();
      // Manually stopping playback should also return to the stopped state
      if (state is PlaybackInProgress) {
        final path = (state as PlaybackInProgress).path;
        emit(RecordingStopped(path));
      }
    } catch (e) {
      emit(TranscriptionError(e.toString()));
    }
  }


  Future<void> transcribeRecording() async {
    if (state is RecordingStopped) {
      final path = (state as RecordingStopped).path;
      try {
        emit(const TranscriptionLoading('Transcribing...'));
        final result = await _whisperService.transcribe(path);
        emit(TranscriptionSuccess(result.isEmpty ? "[No speech detected]" : result));
      } catch (e) {
        emit(TranscriptionError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    _whisperService.dispose();
    _audioService.dispose();
    return super.close();
  }
}
