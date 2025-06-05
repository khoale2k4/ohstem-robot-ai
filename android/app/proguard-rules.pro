## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Bluetooth libraries
-keep class com.polidea.rxandroidble2.** { *; }
-keep class com.polidea.rxandroidble.** { *; }

## Gson rules
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

## Keep your model classes
-keep class com.ohstem.robot_ai.** { *; } 