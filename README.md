# Whisper.cpp Flutter App

This Flutter project demonstrates the integration of the native **Whisper.cpp** library for efficient, on-device speech-to-text transcription. The app features a clean user interface, leverages Dart's isolates for high performance, and showcases advanced solutions to complex native integration challenges.

## How it Works

The application integrates the Whisper.cpp library, a high-performance C++ implementation of OpenAI's Whisper model. This is achieved through **`dart:ffi`** (Foreign Function Interface), allowing the Flutter application to directly call the native C++ functions from the compiled shared library (`.so` file).

A key architectural feature is the use of a **Dart Isolate** for the transcription process. This offloads the computationally intensive work of speech recognition to a separate thread, preventing the UI from freezing and ensuring a smooth user experience. The `WhisperService` manages the isolate and communication between the main UI thread and the background transcription thread.

The application's state is managed using the **`flutter_bloc`** package. The `TranscriptionCubit` handles the application's state, including recording status, transcription progress, and the final transcribed text.

## Features

* **On-device Transcription:** All speech recognition is performed locally, ensuring privacy and offline functionality.
* **High-Performance Native Code:** Directly leverages the speed and efficiency of the C++ `whisper.cpp` library.
* **Isolate for Performance:** Transcription is run in a separate isolate to maintain a fully responsive UI.
* **Clean UI:** A simple and intuitive user interface for recording and viewing transcriptions.
* **Audio Processing:** Uses `flutter_sound` for audio recording and `ffmpeg_kit_flutter_new` for robust audio format conversion.

## Key Technical Challenges & Solutions

Integrating a complex native C++ library into Flutter presented several significant engineering challenges, particularly for Android release builds:

* **Cross-Compiling a C++ Library:** The `whisper.cpp` library was compiled from source using the **Android NDK** to produce the required `arm64-v8a` shared object (`.so`) file, enabling it to run on modern Android devices.
* **Resolving Release-Mode Crashes:** The application worked perfectly in debug mode but would crash in release. This was diagnosed as an issue with the **R8 code shrinker** incorrectly removing essential Java code from the `path_provider` and `ffmpeg_kit_flutter_new` plugins. The solution involved authoring specific **ProGuard rules** to protect the necessary plugin classes from being stripped.
* **APK Size Optimization:** The initial release APK was excessively large (~350MB). The root cause was identified as **unstripped debug symbols** within the compiled `.so` file. The APK size was drastically reduced by using the NDK's `strip` tool to remove these symbols from the native library before packaging.

## Current Support

The application is currently in a proof-of-concept stage. It has been tested on Android and demonstrates the core functionality of integrating Whisper.cpp with Flutter, including solutions for common native integration pitfalls.

## Future Plans

* **UI/UX Enhancements:** The user interface will be improved to provide a more polished and user-friendly experience. This includes adding animations, improving the layout, and providing more visual feedback to the user.
* **Model Selection:** Users will be able to choose from different Whisper models (e.g., tiny, base, small) to balance performance and accuracy.
* **Language Selection:** The app will support transcription in multiple languages.
* **Real-time Visualization:** The app will display the transcribed text in real-time as the user is speaking.