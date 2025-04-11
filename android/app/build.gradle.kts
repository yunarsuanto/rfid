plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Pastikan plugin Flutter diterapkan setelah Android dan Kotlin
}

android {
    namespace = "com.example.rfid"

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
        applicationId = "com.example.rfid"
        minSdk = 21  // Sesuaikan dengan minSdkVersion yang diinginkan
        targetSdk = 33  // Sesuaikan dengan targetSdkVersion yang diinginkan
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Configure source sets
    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }
}

flutter {
    source = "../.." // Lokasi Flutter SDK
}

dependencies {
    implementation("androidx.annotation:annotation:1.3.0")
    implementation(files("libs/DeviceAPI_ver20250209_release.aar"))
}
