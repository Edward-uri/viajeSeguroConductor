# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Keep app models and activities
-keep class com.jala.viajeseguroconductor.** { *; }

# Keep Kotlin metadata for reflection
-keep class kotlin.Metadata { *; }

# Method/Event channels
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel$MethodCallHandler *;
    @io.flutter.plugin.common.EventChannel$StreamHandler *;
}

# Keep Gson/JSON serialization classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Play Core (split compat) — referenced by Flutter but not always bundled
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
-assumenosideeffects class io.flutter.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
