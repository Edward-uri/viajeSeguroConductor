import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 1. Cargamos las propiedades del archivo key.properties de forma correcta en Kotlin (FUERA del bloque android)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.uriel.jala"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // 2. Definimos la configuración de firma "release" usando las llaves cargadas
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as? String ?: ""
            keyPassword = keystoreProperties["keyPassword"] as? String ?: ""
            storeFile = file(keystoreProperties["storeFile"] as? String ?: "dummy.jks")
            storePassword = keystoreProperties["storePassword"] as? String ?: ""
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.uriel.jala"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val mapboxToken = project.findProperty("MAPBOX_ACCESS_TOKEN") ?: ""
        manifestPlaceholders["MAPBOX_ACCESS_TOKEN"] = mapboxToken
    }

    buildTypes {
        release {
            // Usamos la configuración de firma "release" que creamos arriba
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
} // Se corrigieron las llaves duplicadas que tenías aquí

flutter {
    source = "../.."
}