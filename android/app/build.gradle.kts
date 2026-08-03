import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// إعدادات مفتاح التوقيع تُقرأ من android/key.properties وهو **مستثنى من git**
// حتى لا تُرفع كلمة المرور. إن لم يوجد الملف يُبنى بمفتاح التصحيح تلقائياً
// فلا يتعطّل البناء على أي جهاز أو في CI.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mawkibzahra.mawkib_zahra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mawkibzahra.mawkib_zahra"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // العربية هي لغة التطبيق الوحيدة — يقلّص حجم موارد الترجمة
        resourceConfigurations += listOf("ar")
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 معطّل بقرار مقصود: في تطبيق Flutter معظم الحجم مكتبات
            // أصلية (libflutter و libapp)، فلا يوفّر R8 إلا ميغابايت أو
            // اثنين من طبقة Java، لكنه قد يقطع حزماً تستخدم الانعكاس مثل
            // local_auth و flutter_secure_storage فينهار التطبيق عند
            // التشغيل. حماية الكود مضمونة أصلاً بـ --obfuscate على مستوى
            // Dart وهو المكان الذي يوجد فيه منطق التطبيق كله.
            // لتفعيله لاحقاً: اجعل القيمتين true واختبر على جهاز حقيقي.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
