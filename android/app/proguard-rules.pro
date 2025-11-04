# Suppress R8 missing class warnings for optional TensorFlow Lite GPU delegate.
# The app does not bundle the GPU delegate; this prevents R8 from failing the build
# due to references from the tflite_flutter plugin.
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# (Optional) Keep TensorFlow Lite classes to avoid over-shrinking if used.
#-keep class org.tensorflow.lite.** { *; }
#-dontwarn org.tensorflow.lite.**

# Keep ONNX Runtime Java bindings and avoid warnings. Some plugins reference
# these classes reflectively; shrinking/obfuscation may cause runtime crashes.
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# Older artifacts may use the com.microsoft package name; keep as well just in case.
-keep class com.microsoft.onnxruntime.** { *; }
-dontwarn com.microsoft.onnxruntime.**

# Keep AndroidX Camera classes referenced by the camera plugin to be safe
# (camera plugin ships consumer rules, but this prevents accidental stripping).
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
