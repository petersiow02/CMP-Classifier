# Preserve all TensorFlow Lite classes
-keep class org.tensorflow.** { *; }

# Specifically preserve GPU Delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }

# Preserve any classes that might be accessed via reflection
-keep class * {
    @org.tensorflow.lite.support.annotation.Keep *;
}
