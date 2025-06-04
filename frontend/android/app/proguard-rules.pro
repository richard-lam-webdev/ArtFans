# --------------------------------------------------------------------------------
# ProGuard / R8 rules pour flutter_secure_storage
# --------------------------------------------------------------------------------

-keep class io.flutter.plugins.securestorage.** { *; }
-keepclassmembers class java.security.KeyStore { *; }
-keep class java.security.KeyStore { *; }
-keep class javax.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.* { *; }

# Si vous utilisez flutter_dotenv (optionnel)
-keep class io.flutter.plugins.flutter_dotenv.** { *; }
