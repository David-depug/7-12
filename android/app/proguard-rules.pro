# ===============================
# General Keep Rules
# ===============================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.example.flutter_my_app_main.** { *; }

# ===============================
# Firebase
# ===============================
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ===============================
# javax.naming
# ===============================
-dontwarn javax.naming.**
-keep class javax.naming.** { *; }

# ===============================
# org.ietf.jgss
# ===============================
-dontwarn org.ietf.jgss.**
-keep class org.ietf.jgss.** { *; }

# ===============================
# joda convert
# ===============================
-dontwarn org.joda.convert.**
-keep class org.joda.convert.** { *; }

# ===============================
# Apache HttpClient
# ===============================
-dontwarn org.apache.http.**
-keep class org.apache.http.** { *; }

# ===============================
# Tink (Google crypto library)
# ===============================
-dontwarn com.google.crypto.tink.**
-keep class com.google.crypto.tink.** { *; }

# ===============================
# Optional: Keep annotations
# ===============================
-keepattributes *Annotation*

# ===============================
# Prevent obfuscation for main app components
# ===============================
-keepclassmembers class * {
    public <init>(...);
}
-keepclassmembers class * {
    public void *(...);
}
