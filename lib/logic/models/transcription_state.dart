// lib/logic/models/transcription_state.dart
part of '../cubit/transcription_cubit.dart';

abstract class TranscriptionState extends Equatable {
  const TranscriptionState();

  @override
  List<Object> get props => [];
}

class TranscriptionInitial extends TranscriptionState {}

class Recording extends TranscriptionState {}

class RecordingStopped extends TranscriptionState {
  final String path;

  const RecordingStopped(this.path);

  @override
  List<Object> get props => [path];
}

// New state for when audio is playing
class PlaybackInProgress extends TranscriptionState {
  final String path;

  const PlaybackInProgress(this.path);

  @override
  List<Object> get props => [path];
}

class TranscriptionLoading extends TranscriptionState {
  final String message;

  const TranscriptionLoading(this.message);

  @override
  List<Object> get props => [message];
}

class TranscriptionSuccess extends TranscriptionState {
  final String transcription;

  const TranscriptionSuccess(this.transcription);

  @override
  List<Object> get props => [transcription];
}

class TranscriptionError extends TranscriptionState {
  final String message;

  const TranscriptionError(this.message);

  @override
  List<Object> get props => [message];
}