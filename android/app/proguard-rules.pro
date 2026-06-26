# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ============================================================
# flutter_local_notifications
# Fixes: "Missing type parameter" PlatformException on release
# builds. R8 strips the generic type info that Gson needs to
# deserialize the scheduled-notifications cache, which crashes
# inside loadScheduledNotifications() when cancel() is called.
# ============================================================

# Keep Gson (used internally by the plugin to (de)serialize the cache)
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep the plugin's model classes that Gson reflects over.
# Without this, the generic <T> parameter is erased and the
# TypeToken lookup throws "Missing type parameter".
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.styles.** { *; }

# Keep generic signatures so TypeToken can read the type at runtime.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Prevent obfuscation of TypeToken subclasses
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Google Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Native JNI - libdartjni.so FindClass crash fix
-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations

# ffmpeg_kit_flutter_new
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }
-dontwarn com.arthenica.ffmpegkit.**
