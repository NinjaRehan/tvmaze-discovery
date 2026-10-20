pluginManagement {
    val local = java.util.Properties()
    file("local.properties").inputStream().use { local.load(it) }
    val flutterHome = requireNotNull(local.getProperty("flutter.sdk")) { "flutter.sdk missing; run flutter pub get" }
    includeBuild("$flutterHome/packages/flutter_tools/gradle")
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.2" apply false
    id("org.jetbrains.kotlin.android") version "2.3.0" apply false
}
include(":app")
