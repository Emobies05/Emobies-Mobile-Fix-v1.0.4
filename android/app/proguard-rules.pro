# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Play Core (Flutter deferred components / split install)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Supabase / Gotrue / Realtime / Postgrest (uses reflection + JSON serialization)
-keep class io.supabase.** { *; }
-keep class ** extends io.supabase.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Gson / JSON serialization (used by supabase & many plugins)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# OkHttp / Okio (used by Supabase http client)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# local_auth (biometric plugin uses native platform channels)
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

# google_fonts (loads fonts dynamically at runtime)
-keep class com.google.fonts.** { *; }
-keep class androidx.core.provider.** { *; }

# Keep native methods (JNI bridges used across plugins)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations (common crash source when stripped)
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep enum values (reflection-based lookups break otherwise)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
