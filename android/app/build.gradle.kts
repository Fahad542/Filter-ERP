import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun resolveApplicationIdFromAppEnvironment(): Map<String, String> {
    // Single control panel next to main.dart
    val envFile = rootProject.file("../lib/app_config.dart")
    if (!envFile.exists()) {
        throw GradleException("Missing ${envFile.path}")
    }
    val text = envFile.readText(Charsets.UTF_8)
    val envRegex =
        Regex(
            """(?m)^\s*static const AppRunEnvironment environment = AppRunEnvironment\.(sandbox|production|local|lan);""",
        )
    val envMatches = envRegex.findAll(text).toList()
    if (envMatches.size != 1) {
        throw GradleException(
            "Set exactly one AppConfig.environment line in lib/app_config.dart",
        )
    }
    val env = envMatches[0].groupValues[1]

    fun readConst(name: String, fallback: String): String {
        val m =
            Regex("""(?m)^\s*static const String $name = '([^']*)';""")
                .find(text)
        return m?.groupValues?.get(1) ?: fallback
    }

    val sandboxId = readConst("sandboxApplicationId", "com.filter_erp.app")
    val productionId = readConst("productionApplicationId", "com.filter.hub")
    val sandboxName = readConst("sandboxDisplayName", "Filter Hub Sandbox")
    val productionName = readConst("productionDisplayName", "Filter Hub")

    val applicationId =
        if (env == "production") productionId else sandboxId
    val appName =
        if (env == "production") productionName else sandboxName
    println(
        "Filter Hub applicationId=$applicationId appName=$appName " +
            "(app_config.dart=$env)",
    )
    return mapOf(
        "applicationId" to applicationId,
        "appName" to appName,
        "env" to env,
    )
}

val resolvedEnv = resolveApplicationIdFromAppEnvironment()

val buildingRelease =
    gradle.startParameter.taskNames.any {
        it.lowercase().contains("release") || it.lowercase().contains("bundle")
    }
if (buildingRelease && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "android/key.properties is missing — release builds must be signed " +
            "with the Filter Hub upload keystore.",
    )
}

android {
    namespace = "com.filter_erp.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = resolvedEnv.getValue("applicationId")
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = resolvedEnv.getValue("appName")
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Local fallback only — never ship this to Play Store.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
