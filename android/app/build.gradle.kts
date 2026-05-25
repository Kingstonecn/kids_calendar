import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kidscalendar.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.kidscalendar.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// 复制 APK 输出文件
tasks.register("copyApk") {
    doLast {
        fileTree("${project.buildDir}/outputs/flutter-apk/").matching {
            include("app-*.apk")
        }.forEach { apk ->
            val newName = apk.name.replace("app-", "kids_calendar-")
            apk.copyTo(apk.parentFile.resolve(newName), overwrite = true)
            println("APK copied: ${apk.name} -> $newName")
        }
    }
}

tasks.matching { it.name.startsWith("assemble") }.configureEach {
    finalizedBy("copyApk")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
