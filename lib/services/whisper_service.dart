// lib/services/whisper_service.dart
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../ffi/whisper_bindings.dart';

/// Data class for passing information to the isolate
class WhisperIsolateData {
  final SendPort sendPort;
  final String audioPath;
  final String modelPath;
  final RootIsolateToken rootIsolateToken;

  WhisperIsolateData({
    required this.sendPort,
    required this.audioPath,
    required this.modelPath,
    required this.rootIsolateToken,
  });
}

/// Result type for isolate communication
class TranscriptionResult {
  final String text;
  final bool success;
  final String? error;

  TranscriptionResult({required this.text, this.success = true, this.error});
}

/// A service class to encapsulate all whisper.cpp FFI logic.
class WhisperService {
  String? _modelPath;

  /// Initializes the service by loading the whisper model.
  Future<void> initialize() async {
    _modelPath = await _getPathFromAsset('assets/ggml-tiny.en.bin');
  }

  /// Transcribes an audio file at the given path using a separate isolate.
  /// Returns the transcribed text as a String.
  /// Throws an exception if transcription fails.
  Future<String> transcribe(String audioPath) async {
    if (_modelPath == null) {
      throw Exception('WhisperService not initialized. Call initialize() first.');
    }

    // Get the root isolate token for platform channel communication
    final rootIsolateToken = RootIsolateToken.instance!;

    // Create communication ports
    final receivePort = ReceivePort();

    // Create isolate data
    final isolateData = WhisperIsolateData(
      sendPort: receivePort.sendPort,
      audioPath: audioPath,
      modelPath: _modelPath!,
      rootIsolateToken: rootIsolateToken,
    );

    // Create a completer to handle the async result
    final completer = Completer<String>();

    // Spawn isolate
    final isolate = await Isolate.spawn(
      _transcribeInIsolate,
      isolateData,
      errorsAreFatal: false,
    );

    // Listen for messages from the isolate
    receivePort.listen((dynamic message) {
      if (message is TranscriptionResult) {
        if (message.success) {
          completer.complete(message.text);
        } else {
          completer.completeError(Exception(message.error ?? 'Unknown error'));
        }
        // Clean up
        receivePort.close();
        isolate.kill();
      }
    });

    return completer.future;
  }

  Future<String> _getPathFromAsset(String asset) async {
    final byteData = await rootBundle.load(asset);
    final buffer = byteData.buffer;
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${asset.split('/').last}';
    await File(path).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return path;
  }
}

/// Isolate entry point that performs the actual transcription work
void _transcribeInIsolate(WhisperIsolateData data) async {
  final sendPort = data.sendPort;

  try {
    // Initialize the binary messenger for platform channels
    BackgroundIsolateBinaryMessenger.ensureInitialized(data.rootIsolateToken);

    // 1. Load the dynamic library in the isolate
    final dylib = DynamicLibrary.open('libwhisper.so');
    final bindings = WhisperBindings(dylib);

    // 2. Initialize whisper context
    final modelPathUtf8 = data.modelPath.toNativeUtf8();
    final cparams = bindings.whisper_context_default_params();
    final context = bindings.whisper_init_from_file_with_params(modelPathUtf8, cparams);
    calloc.free(modelPathUtf8);

    if (context == nullptr) {
      sendPort.send(TranscriptionResult(
        text: '',
        success: false,
        error: 'Failed to initialize whisper context',
      ));
      return;
    }

    try {
      // 3. Convert audio to required PCM format
      final tempDir = await getTemporaryDirectory();
      final pcmPath = '${tempDir.path}/output.pcm';
      final session = await FFmpegKit.execute(
          '-y -i ${data.audioPath} -f s16le -acodec pcm_s16le -ar 16000 -ac 1 $pcmPath');
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final log = await session.getOutput();
        sendPort.send(TranscriptionResult(
          text: '',
          success: false,
          error: 'FFmpeg failed: $log',
        ));
        return;
      }

      // 4. Read and normalize audio data
      final pcmBytes = await File(pcmPath).readAsBytes();
      final pcmData = pcmBytes.buffer.asByteData();
      final audioFloats = List<double>.filled(pcmData.lengthInBytes ~/ 2, 0.0);

      for (int i = 0; i < audioFloats.length; i++) {
        final intSample = pcmData.getInt16(i * 2, Endian.little);
        audioFloats[i] = intSample / 32768.0;
      }

      final audioDataPtr = calloc<Float>(audioFloats.length);
      audioDataPtr.asTypedList(audioFloats.length).setAll(0, audioFloats);

      // 5. Set parameters
      final params = bindings.whisper_full_default_params(0);
      final paramsPtr = calloc<WhisperFullParams>();
      paramsPtr.ref = params;
      paramsPtr.ref.n_threads = 4;
      paramsPtr.ref.print_progress = false;
      paramsPtr.ref.print_realtime = false;

      final langUtf8 = 'en'.toNativeUtf8();
      paramsPtr.ref.language = langUtf8;

      // 6. Run transcription
      final status = bindings.whisper_full_parallel(
          context, paramsPtr.ref, audioDataPtr, audioFloats.length, 1);

      if (status != 0) {
        sendPort.send(TranscriptionResult(
          text: '',
          success: false,
          error: 'Failed to transcribe audio. Status: $status',
        ));
      } else {
        final nSegments = bindings.whisper_full_n_segments(context);
        final buffer = StringBuffer();
        for (var i = 0; i < nSegments; i++) {
          final textPtr = bindings.whisper_full_get_segment_text(context, i);
          buffer.write(textPtr.toDartString());
        }
        final transcription = buffer.toString().trim();

        sendPort.send(TranscriptionResult(
          text: transcription,
          success: true,
        ));
      }

      // 7. Clean up memory
      calloc.free(audioDataPtr);
      calloc.free(langUtf8);
      calloc.free(paramsPtr);

    } finally {
      // Always free the context
      if (context != nullptr) {
        bindings.whisper_free(context);
      }
    }

  } catch (e) {
    sendPort.send(TranscriptionResult(
      text: '',
      success: false,
      error: 'Exception in isolate: $e',
    ));
  }
}