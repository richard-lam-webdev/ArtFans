import java.util.Properties
import java.io.FileInputStream

plugins {
  id("com.android.application")
  id("kotlin-android")
  id("dev.flutter.flutter-gradle-plugin")
}

android {
  namespace = "fr.ddasilva.artfans"
  compileSdk = flutter.compileSdkVersion
  ndkVersion = "27.0.12077973"

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
  }
  kotlinOptions {
    jvmTarget = JavaVersion.VERSION_11.toString()
  }

  defaultConfig {
    applicationId = "fr.ddasilva.artfans"
    minSdk        = flutter.minSdkVersion
    targetSdk     = flutter.targetSdkVersion
    versionCode   = flutter.versionCode
    versionName   = flutter.versionName
  }

  signingConfigs {
    create("release") {
      val propsFile = rootProject.file("../key.properties")
      val props = Properties().apply {
        load(FileInputStream(propsFile))
      }
      storeFile     = file(props["storeFile"] as String)
      storePassword = props["storePassword"] as String
      keyAlias      = props["keyAlias"] as String
      keyPassword   = props["keyPassword"] as String
    }
  }

  buildTypes {
    getByName("release") {
      isMinifyEnabled = true
      proguardFiles(
        getDefaultProguardFile("proguard-android.txt"),
        "proguard-rules.pro"
      )
      signingConfig = signingConfigs.getByName("release")
    }
    getByName("debug") {
      isMinifyEnabled = false
    }
  }
}

flutter {
  source = "../.."
}
