# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / PostgREST / GoTrue / Realtime
-keep class com.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }

# Hive
-keep class com.hivedb.** { *; }
-keep class io.hive.** { *; }

# JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep models (if you use json_serializable or reflection-based libs)
-keep class com.example.tailorsbook.models.** { *; }
