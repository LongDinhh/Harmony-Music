# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }

# Keep audio service related classes
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media.** { *; }

# Keep Hive database classes
-keep class hive.** { *; }
-keep class **$HiveFieldAdapter { *; }

# Keep Dio HTTP client classes
-keep class dio.** { *; }

# Keep media kit classes
-keep class media_kit.** { *; }

# Keep GetX classes
-keep class get.** { *; }

# Keep JNI classes
-keep class com.github.dart_lang.jni.** { *; }

# General Android optimizations
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove logging calls
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}
