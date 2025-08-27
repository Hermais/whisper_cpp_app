# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }

-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep FFmpeg classes
-keep class com.arthenica.mobileffmpeg.** { *; }

# Keep native libraries
-keepattributes *Annotation*
-keep public class * extends java.lang.Exception