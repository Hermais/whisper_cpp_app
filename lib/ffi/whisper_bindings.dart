import 'dart:ffi';
import 'package:ffi/ffi.dart';


// lib/ffi/whisper_bindings.dart - Add this class at the end of the file

class WhisperBindings {
  final DynamicLibrary _dylib;

  WhisperBindings(this._dylib);

  // Function to initialize the whisper context from a file
  Pointer<WhisperContext> whisper_init_from_file_with_params(
      Pointer<Utf8> path, WhisperContextParams params) {
    return _dylib
        .lookupFunction<
        Pointer<WhisperContext> Function(
            Pointer<Utf8>, WhisperContextParams),
        Pointer<WhisperContext> Function(
            Pointer<Utf8>, WhisperContextParams)>(
        'whisper_init_from_file_with_params')
        .call(path, params);
  }

  // Get default context parameters
  WhisperContextParams whisper_context_default_params() {
    return _dylib
        .lookupFunction<WhisperContextParams Function(),
        WhisperContextParams Function()>(
        'whisper_context_default_params')
        .call();
  }

  // Get default full parameters
  WhisperFullParams whisper_full_default_params(int strategy) {
    return _dylib
        .lookupFunction<WhisperFullParams Function(Int32),
        WhisperFullParams Function(int)>(
        'whisper_full_default_params')
        .call(strategy);
  }

  // Run parallel inference
  int whisper_full_parallel(
      Pointer<WhisperContext> ctx,
      WhisperFullParams params,
      Pointer<Float> samples,
      int n_samples,
      int n_processors) {
    return _dylib
        .lookupFunction<
        Int32 Function(Pointer<WhisperContext>, WhisperFullParams,
            Pointer<Float>, Int32, Int32),
        int Function(Pointer<WhisperContext>, WhisperFullParams,
            Pointer<Float>, int, int)>(
        'whisper_full_parallel')
        .call(ctx, params, samples, n_samples, n_processors);
  }

  // Get number of segments
  int whisper_full_n_segments(Pointer<WhisperContext> ctx) {
    return _dylib
        .lookupFunction<Int32 Function(Pointer<WhisperContext>),
        int Function(Pointer<WhisperContext>)>(
        'whisper_full_n_segments')
        .call(ctx);
  }

  // Get text for a segment
  Pointer<Utf8> whisper_full_get_segment_text(
      Pointer<WhisperContext> ctx, int i) {
    return _dylib
        .lookupFunction<
        Pointer<Utf8> Function(Pointer<WhisperContext>, Int32),
        Pointer<Utf8> Function(Pointer<WhisperContext>, int)>(
        'whisper_full_get_segment_text')
        .call(ctx, i);
  }

  // Free the whisper context
  void whisper_free(Pointer<WhisperContext> ctx) {
    _dylib
        .lookupFunction<Void Function(Pointer<WhisperContext>),
        void Function(Pointer<WhisperContext>)>(
        'whisper_free')
        .call(ctx);
  }
}

// This file contains the direct Dart-to-C mappings based on the whisper.h header file.
// You should not need to modify this file unless the underlying C++ library changes.

// FFI type definitions from whisper.h
typedef whisper_token = Int32;
typedef whisper_pos = Int32;
typedef whisper_seq_id = Int32;

// Opaque type for the whisper_context pointer, ensuring type safety.
final class WhisperContext extends Opaque {}

// All FFI Struct definitions
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
