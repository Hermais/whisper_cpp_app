import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data'; // Needed for Endian and ByteData
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

// FFI type definitions from whisper.h
typedef whisper_token = Int32;
typedef whisper_pos = Int32;
typedef whisper_seq_id = Int32;

// --- Define whisper_context as an Opaque type for type safety ---
// This tells Dart that it's a pointer to a C struct that we don't need to read from.
final class WhisperContext extends Opaque {}

// --- All of your FFI Struct definitions go here ---
// (These are kept exactly as you provided them as they were correct)

enum WhisperAlignmentHeadsPreset {
  WHISPER_AHEADS_NONE,
  WHISPER_AHEADS_N_TOP_MOST,
  WHISPER_AHEADS_CUSTOM,
  WHISPER_AHEADS_TINY_EN,
  WHISPER_AHEADS_TINY,
  WHISPER_AHEADS_BASE_EN,
  WHISPER_AHEADS_BASE,
  WHISPER_AHEADS_SMALL_EN,
  WHISPER_AHEADS_SMALL,
  WHISPER_AHEADS_MEDIUM_EN,
  WHISPER_AHEADS_MEDIUM,
  WHISPER_AHEADS_LARGE_V1,
  WHISPER_AHEADS_LARGE_V2,
  WHISPER_AHEADS_LARGE_V3,
  WHISPER_AHEADS_LARGE_V3_TURBO,
}

final class WhisperAhead extends Struct {
  @Int32()
  external int n_text_layer;
  @Int32()
  external int n_head;
}

final class WhisperAheads extends Struct {
  @IntPtr()
  external int n_heads;
  external Pointer<WhisperAhead> heads;
}

final class WhisperContextParams extends Struct {
  @Bool()
  external bool use_gpu;
  @Bool()
  external bool flash_attn;
  @Int32()
  external int gpu_device;

  @Bool()
  external bool dtw_token_timestamps;
  @Int32()
  external int dtw_aheads_preset; // enum WhisperAlignmentHeadsPreset
  @Int32()
  external int dtw_n_top;
  external WhisperAheads dtw_aheads;
  @IntPtr()
  external int dtw_mem_size;
}

final class WhisperVadParams extends Struct {
  @Float()
  external double threshold;
  @Int32()
  external int min_speech_duration_ms;
  @Int32()
  external int min_silence_duration_ms;
  @Float()
  external double max_speech_duration_s;
  @Int32()
  external int speech_pad_ms;
  @Float()
  external double samples_overlap;
}

final class Greedy extends Struct {
  @Int32()
  external int best_of;
}

final class BeamSearch extends Struct {
  @Int32()
  external int beam_size;
  @Float()
  external double patience;
}

final class WhisperGrammarElement extends Struct {
  @Int32()
  external int type;
  @Uint32()
  external int value;
}

final class WhisperFullParams extends Struct {
  @Int32()
  external int strategy;

  @Int32()
  external int n_threads;
  @Int32()
  external int n_max_text_ctx;
  @Int32()
  external int offset_ms;
  @Int32()
  external int duration_ms;

  @Bool()
  external bool translate;
  @Bool()
  external bool no_context;
  @Bool()
  external bool no_timestamps;
  @Bool()
  external bool single_segment;
  @Bool()
  external bool print_special;
  @Bool()
  external bool print_progress;
  @Bool()
  external bool print_realtime;
  @Bool()
  external bool print_timestamps;

  @Bool()
  external bool token_timestamps;
  @Float()
  external double thold_pt;
  @Float()
  external double thold_ptsum;
  @Int32()
  external int max_len;
  @Bool()
  external bool split_on_word;
  @Int32()
  external int max_tokens;

  @Bool()
  external bool debug_mode;
  @Int32()
  external int audio_ctx;

  @Bool()
  external bool tdrz_enable;

  external Pointer<Utf8> suppress_regex;

  external Pointer<Utf8> initial_prompt;
  external Pointer<whisper_token> prompt_tokens;
  @Int32()
  external int prompt_n_tokens;

  external Pointer<Utf8> language;
  @Bool()
  external bool detect_language;

  @Bool()
  external bool suppress_blank;
  @Bool()
  external bool suppress_nst;

  @Float()
  external double temperature;
  @Float()
  external double max_initial_ts;
  @Float()
  external double length_penalty;

  @Float()
  external double temperature_inc;
  @Float()
  external double entropy_thold;
  @Float()
  external double logprob_thold;
  @Float()
  external double no_speech_thold;

  external Greedy greedy;
  external BeamSearch beam_search;

  external Pointer<Void> new_segment_callback;
  external Pointer<Void> new_segment_callback_user_data;

  external Pointer<Void> progress_callback;
  external Pointer<Void> progress_callback_user_data;

  external Pointer<Void> encoder_begin_callback;
  external Pointer<Void> encoder_begin_callback_user_data;

  external Pointer<Void> abort_callback;
  external Pointer<Void> abort_callback_user_data;

  external Pointer<Void> logits_filter_callback;
  external Pointer<Void> logits_filter_callback_user_data;

  external Pointer<Pointer<WhisperGrammarElement>> grammar_rules;
  @IntPtr()
  external int n_grammar_rules;
  @IntPtr()
  external int i_start_rule;
  @Float()
  external double grammar_penalty;

  @Bool()
  external bool vad;
  external Pointer<Utf8> vad_model_path;

  external WhisperVadParams vad_params;
}
// --- End of FFI Structs ---

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _transcription = 'Initializing...';
  bool _isTranscribing = true;

  @override
  void initState() {
    super.initState();
    _runWhisper();
  }

  /// This is the main function that handles the entire transcription process.
  Future<void> _runWhisper() async {
    final dylib = DynamicLibrary.open('libwhisper.so');

    // --- Update function signatures to use the type-safe Pointer<WhisperContext> ---
    final whisper_init_from_file_with_params = dylib.lookupFunction<
        Pointer<WhisperContext> Function(Pointer<Utf8>, WhisperContextParams),
        Pointer<WhisperContext> Function(Pointer<Utf8>,
            WhisperContextParams)>('whisper_init_from_file_with_params');
    final whisper_context_default_params = dylib.lookupFunction<
        WhisperContextParams Function(),
        WhisperContextParams Function()>('whisper_context_default_params');
    final whisper_full_parallel = dylib.lookupFunction<
        Int32 Function(
            Pointer<WhisperContext>, WhisperFullParams, Pointer<Float>, Int32, Int32),
        int Function(Pointer<WhisperContext>, WhisperFullParams, Pointer<Float>,
            int, int)>('whisper_full_parallel');
    final whisper_full_n_segments = dylib.lookupFunction<
        Int32 Function(Pointer<WhisperContext>),
        int Function(Pointer<WhisperContext>)>('whisper_full_n_segments');
    final whisper_full_get_segment_text = dylib.lookupFunction<
        Pointer<Utf8> Function(Pointer<WhisperContext>, Int32),
        Pointer<Utf8> Function(
            Pointer<WhisperContext>, int)>('whisper_full_get_segment_text');
    final whisper_free = dylib.lookupFunction<
        Void Function(Pointer<WhisperContext>),
        void Function(Pointer<WhisperContext>)>('whisper_free');
    final whisper_full_default_params = dylib.lookupFunction<
        WhisperFullParams Function(Int32),
        WhisperFullParams Function(int)>('whisper_full_default_params');

    // Prepare paths for model and audio files
    final modelPath = await _getPathFromAsset('assets/ggml-tiny.en.bin');
    final audioPath = await _getPathFromAsset('assets/test.wav');

    final modelPathUtf8 = modelPath.toNativeUtf8();
    // --- Use the type-safe Pointer<WhisperContext> ---
    Pointer<WhisperContext> ctx = nullptr;
    Pointer<Utf8> langUtf8 = nullptr;

    try {
      // Initialize model
      final cparams = whisper_context_default_params();
      ctx = whisper_init_from_file_with_params(modelPathUtf8, cparams);

      if (ctx == nullptr) {
        if (mounted) {
          setState(() {
            _transcription = 'Failed to load whisper model.';
            _isTranscribing = false;
          });
        }
        return;
      }

      // --- FIX 2: Add -y flag to auto-overwrite output file ---
      final tempDir = await getTemporaryDirectory();
      final pcmPath = '${tempDir.path}/output.pcm';
      final session = await FFmpegKit.execute(
          '-y -i $audioPath -f s16le -acodec pcm_s16le -ar 16000 -ac 1 $pcmPath');
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        // --- FIX: Await the log message before displaying it ---
        final sessionLog = await session.getOutput();
        if (mounted) {
          setState(() {
            _transcription =
            'FFmpeg failed to convert audio. Log: $sessionLog';
            _isTranscribing = false;
          });
        }
        return;
      }

      // Read file and normalize audio data
      final pcmBytes = await File(pcmPath).readAsBytes();
      final pcmData = pcmBytes.buffer.asByteData();
      final audioFloats =
      List<double>.filled(pcmData.lengthInBytes ~/ 2, 0.0);

      for (int i = 0; i < audioFloats.length; i++) {
        final intSample = pcmData.getInt16(i * 2, Endian.little);
        audioFloats[i] = intSample / 32768.0;
      }

      final audioDataPtr = calloc<Float>(audioFloats.length);
      audioDataPtr.asTypedList(audioFloats.length).setAll(0, audioFloats);

      // Set parameters
      final params = whisper_full_default_params(0); // 0 = WHISPER_SAMPLING_GREEDY
      final paramsPtr = calloc<WhisperFullParams>();
      paramsPtr.ref = params;
      paramsPtr.ref.n_threads = 4;
      paramsPtr.ref.print_progress = false;
      paramsPtr.ref.print_realtime = false;

      // Correctly set language parameter and manage its memory
      langUtf8 = 'en'.toNativeUtf8();
      paramsPtr.ref.language = langUtf8;

      // Run transcription
      final status = whisper_full_parallel(
          ctx, paramsPtr.ref, audioDataPtr, audioFloats.length, 1);

      // Process result
      if (status != 0) {
        if (mounted) {
          setState(() => _transcription = 'Failed to transcribe audio. Status: $status');
        }
      } else {
        final nSegments = whisper_full_n_segments(ctx);
        final transcriptionBuffer = StringBuffer();
        for (var i = 0; i < nSegments; i++) {
          final textPtr = whisper_full_get_segment_text(ctx, i);
          transcriptionBuffer.write(textPtr.toDartString());
        }
        if (mounted) {
          setState(() => _transcription = transcriptionBuffer.toString().trim());
        }
      }

      // Free C-allocated memory
      calloc.free(audioDataPtr);
      calloc.free(paramsPtr);

    } finally {
      // Free all remaining C pointers in a finally block to prevent leaks
      if (ctx != nullptr) {
        whisper_free(ctx);
      }
      calloc.free(modelPathUtf8);
      if (langUtf8 != nullptr) {
        calloc.free(langUtf8);
      }
      if (mounted) setState(() => _isTranscribing = false);
    }
  }

  /// Helper function to copy an asset to a temporary file so native code can access it.
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isTranscribing)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Transcribing, please wait...'),
                  ],
                )
              else
                Text(
                  'Transcription Result:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  // --- FIX 1: Use SelectableText for copy functionality ---
                  child: SelectableText(
                    _transcription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
