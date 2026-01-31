# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Auth
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Pigeon generated classes (Firebase uses these)
-keep class dev.flutter.pigeon.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }

# Keep Firestore classes
-keep class com.google.firebase.firestore.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}
