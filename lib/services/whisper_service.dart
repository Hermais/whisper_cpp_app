import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../ffi/whisper_bindings.dart';

/// A service class to encapsulate all whisper.cpp FFI logic.
class WhisperService {
  late final DynamicLibrary _dylib;
  late final WhisperBindings _bindings;
  Pointer<WhisperContext> _context = nullptr;

  /// Initializes the service by loading the dynamic library and the whisper model.
  /// Throws an exception if initialization fails.
  Future<void> initialize() async {
    _dylib = DynamicLibrary.open('libwhisper.so');
    _bindings = WhisperBindings(_dylib);

    final modelPath = await _getPathFromAsset('assets/ggml-tiny.en.bin');
    final modelPathUtf8 = modelPath.toNativeUtf8();

    final cparams = _bindings.whisper_context_default_params();
    _context = _bindings.whisper_init_from_file_with_params(modelPathUtf8, cparams);

    calloc.free(modelPathUtf8);

    if (_context == nullptr) {
      throw Exception('Failed to initialize whisper context.');
    }
  }

  /// Transcribes an audio file at the given path.
  /// Returns the transcribed text as a String.
  /// Throws an exception if transcription fails.
  Future<String> transcribe(String audioPath) async {
    if (_context == nullptr) {
      throw Exception('WhisperService not initialized. Call initialize() first.');
    }

    // 1. Convert audio to required PCM format using FFmpeg
    final pcmPath = await _convertAudioToPcm(audioPath);

    // 2. Read PCM data and normalize to 32-bit floats
    final audioFloats = await _normalizeAudio(pcmPath);
    final audioDataPtr = calloc<Float>(audioFloats.length);
    audioDataPtr.asTypedList(audioFloats.length).setAll(0, audioFloats);

    // 3. Set transcription parameters
    final params = _bindings.whisper_full_default_params(0); // 0 = WHISPER_SAMPLING_GREEDY
    final paramsPtr = calloc<WhisperFullParams>();
    paramsPtr.ref = params;
    paramsPtr.ref.n_threads = 4;
    paramsPtr.ref.print_progress = false;
    paramsPtr.ref.print_realtime = false;
    final langUtf8 = 'en'.toNativeUtf8();
    paramsPtr.ref.language = langUtf8;

    // 4. Run transcription
    final status = _bindings.whisper_full_parallel(
        _context, paramsPtr.ref, audioDataPtr, audioFloats.length, 1);

    String transcription = '';
    if (status == 0) {
      final nSegments = _bindings.whisper_full_n_segments(_context);
      final buffer = StringBuffer();
      for (var i = 0; i < nSegments; i++) {
        final textPtr = _bindings.whisper_full_get_segment_text(_context, i);
        buffer.write(textPtr.toDartString());
      }
      transcription = buffer.toString().trim();
    } else {
      throw Exception('Failed to transcribe audio. Status: $status');
    }

    // 5. Clean up memory
    calloc.free(audioDataPtr);
    calloc.free(langUtf8);
    calloc.free(paramsPtr);

    return transcription;
  }

  /// Disposes of the whisper context to free up native memory.
  void dispose() {
    if (_context != nullptr) {
      _bindings.whisper_free(_context);
      _context = nullptr;
    }
  }

  // --- Private Helper Methods ---

  Future<String> _convertAudioToPcm(String audioPath) async {
    final tempDir = await getTemporaryDirectory();
    final pcmPath = '${tempDir.path}/output.pcm';
    final session = await FFmpegKit.execute(
        '-y -i $audioPath -f s16le -acodec pcm_s16le -ar 16000 -ac 1 $pcmPath');
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final log = await session.getOutput();
      throw Exception('FFmpeg failed to convert audio. Log: $log');
    }
    return pcmPath;
  }

  Future<List<double>> _normalizeAudio(String pcmPath) async {
    final pcmBytes = await File(pcmPath).readAsBytes();
    final pcmData = pcmBytes.buffer.asByteData();
    final audioFloats = List<double>.filled(pcmData.lengthInBytes ~/ 2, 0.0);

    for (int i = 0; i < audioFloats.length; i++) {
      final intSample = pcmData.getInt16(i * 2, Endian.little);
      audioFloats[i] = intSample / 32768.0;
    }
    return audioFloats;
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


/// A helper class to bundle FFI function lookups.
class WhisperBindings {
  late final Pointer<WhisperContext> Function(Pointer<Utf8>, WhisperContextParams)
  whisper_init_from_file_with_params;
  late final WhisperContextParams Function() whisper_context_default_params;
  late final int Function(Pointer<WhisperContext>, WhisperFullParams, Pointer<Float>, int, int)
  whisper_full_parallel;
  late final int Function(Pointer<WhisperContext>) whisper_full_n_segments;
  late final Pointer<Utf8> Function(Pointer<WhisperContext>, int)
  whisper_full_get_segment_text;
  late final void Function(Pointer<WhisperContext>) whisper_free;
  late final WhisperFullParams Function(int) whisper_full_default_params;

  WhisperBindings(DynamicLibrary dylib) {
    whisper_init_from_file_with_params = dylib.lookupFunction<
        Pointer<WhisperContext> Function(Pointer<Utf8>, WhisperContextParams),
        Pointer<WhisperContext> Function(Pointer<Utf8>,
            WhisperContextParams)>('whisper_init_from_file_with_params');
    whisper_context_default_params = dylib.lookupFunction<
        WhisperContextParams Function(),
        WhisperContextParams Function()>('whisper_context_default_params');
    whisper_full_parallel = dylib.lookupFunction<
        Int32 Function(
            Pointer<WhisperContext>, WhisperFullParams, Pointer<Float>, Int32, Int32),
        int Function(Pointer<WhisperContext>, WhisperFullParams, Pointer<Float>,
            int, int)>('whisper_full_parallel');
    whisper_full_n_segments = dylib.lookupFunction<
        Int32 Function(Pointer<WhisperContext>),
        int Function(Pointer<WhisperContext>)>('whisper_full_n_segments');
    whisper_full_get_segment_text = dylib.lookupFunction<
        Pointer<Utf8> Function(Pointer<WhisperContext>, Int32),
        Pointer<Utf8> Function(
            Pointer<WhisperContext>, int)>('whisper_full_get_segment_text');
    whisper_free = dylib.lookupFunction<
        Void Function(Pointer<WhisperContext>),
        void Function(Pointer<WhisperContext>)>('whisper_free');
    whisper_full_default_params = dylib.lookupFunction<
        WhisperFullParams Function(Int32),
        WhisperFullParams Function(int)>('whisper_full_default_params');
  }
}
