import 'dart:developer';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';


/// A service class to encapsulate audio recording and playback functionality.
class AudioService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isInitialized = false;
  String? _recordingPath;
  // Dart


    // Use an event channel name that matches the one configured on the native side.
    static const EventChannel _ffmpegEventChannel = EventChannel('com.myapp.ffmpeg/events');

    void initFfmpegEvents() {
      _ffmpegEventChannel.receiveBroadcastStream().listen((event) {
        // Process the ffmpeg event; for example, print its content.
        print('FFmpeg Event: $event');
      }, onError: (error) {
        print('FFmpeg Event Error: $error');
      });



  }

  /// Initializes the audio service, requesting permissions and opening the recorder/player.
  Future<void> initialize() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    initFfmpegEvents();

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await _recorder!.openRecorder();
    await _player!.openPlayer();
    _isInitialized = true;
    log('AudioService Initialized');
  }

  /// Starts recording audio to a file.
  Future<void> startRecording() async {
    if (!_isInitialized) throw Exception('AudioService not initialized');
    final directory = await getApplicationDocumentsDirectory();
    // FIX: Change file extension to aac for the new codec.
    _recordingPath = '${directory.path}/recording.aac';
    log('Starting recording to: $_recordingPath');
    // FIX: Use a more compatible codec like AAC for recording.
    await _recorder!.startRecorder(toFile: _recordingPath, codec: Codec.aacADTS);
  }

  /// Stops the current recording.
  /// Returns the path to the recorded audio file.
  Future<String?> stopRecording() async {
    if (!_isInitialized) throw Exception('AudioService not initialized');
    await _recorder!.stopRecorder();
    log('Stopped recording. File saved at: $_recordingPath');
    return _recordingPath;
  }

  /// Starts playback of the last recorded audio file.
  /// The [whenFinished] callback is executed when playback completes.
  Future<void> startPlayback(void Function() whenFinished) async {
    if (!_isInitialized) throw Exception('AudioService not initialized');
    if (_recordingPath == null) throw Exception('No recording available to play');

    log('Starting playback from: $_recordingPath');

    await _player!.startPlayer(
      fromURI: _recordingPath,
      // FIX: Specify the correct codec for playback.
      codec: Codec.aacADTS,
      whenFinished: whenFinished,
    );
  }

  /// Stops the current playback.
  Future<void> stopPlayback() async {
    if (!_isInitialized) throw Exception('AudioService not initialized');
    log('Stopping playback');
    await _player!.stopPlayer();
  }

  /// Disposes of the recorder and player resources.
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _recorder = null;
    _player = null;
    log('AudioService Disposed');
  }
}
