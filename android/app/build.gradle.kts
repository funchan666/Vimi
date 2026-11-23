import java.util.Properties
import java.io.FileInputStream
import java.net.URI
import java.util.Base64

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingFile = rootProject.file("key.properties")
val signingProperties = Properties()
if (signingFile.exists()) signingProperties.load(FileInputStream(signingFile))

android {
    namespace = "com.vimistudio.covercrew"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "com.vimistudio.covercrew"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        if (signingFile.exists()) {
            create("release") {
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
                storeFile = file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
            }
        }
    }
    buildTypes {
        release {
            if (signingFile.exists()) signingConfig = signingConfigs.getByName("release")
        }
    }
}
// Preview builds remain available; a store release needs real public policies and upload signing.
val validatePlayRelease = tasks.register("validatePlayRelease") {
    doLast {
        val definitions = (project.findProperty("dart-defines")?.toString() ?: "")
            .split(',').filter { it.isNotBlank() }.map {
                String(Base64.getDecoder().decode(it), Charsets.UTF_8).split('=', limit = 2)
            }.filter { it.size == 2 }.associate { it[0] to it[1] }
        val missing = mutableListOf<String>()
        for (key in listOf("PRIVACY_URL", "TERMS_URL", "CHILD_SAFETY_URL", "DELETE_ACCOUNT_URL", "SUPABASE_URL")) {
            val uri = runCatching { URI(definitions[key] ?: "") }.getOrNull()
            val host = uri?.host ?: ""
            if (uri?.scheme != "https" || host.isEmpty() || host == "localhost" || host.endsWith(".invalid") || host == "example.com") {
                missing.add("$key must be a real public HTTPS URL")
            }
        }
        for (key in listOf("SUPPORT_EMAIL", "CHILD_SAFETY_EMAIL")) {
            if (!Regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$").matches(definitions[key] ?: "")) {
                missing.add("$key must be configured")
            }
        }
        if (definitions["SUPABASE_PUBLISHABLE_KEY"].isNullOrBlank()) missing.add("SUPABASE_PUBLISHABLE_KEY is required")
        if (definitions.keys.any { it.contains("SERVICE_ROLE") || it.contains("SERVICE_ACCOUNT") } || definitions.values.any { it.startsWith("sb_secret_") }) {
            missing.add("Privileged server credentials must never be supplied as Dart defines")
        }
        if (!signingFile.exists() || listOf("keyAlias", "keyPassword", "storeFile", "storePassword").any { signingProperties.getProperty(it).isNullOrBlank() }) {
            missing.add("Configure the publisher's upload signing key in android/key.properties")
        } else {
            val uploadKey = file(signingProperties.getProperty("storeFile"))
            if (!uploadKey.isFile || uploadKey.name == "debug.keystore") missing.add("A real upload keystore is required")
        }
        if (missing.isNotEmpty()) throw GradleException("Google Play release configuration is incomplete:\n" + missing.joinToString("\n"))
    }
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach { dependsOn(validatePlayRelease) }
kotlin {
    compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 }
}
flutter { source = "../.." }
