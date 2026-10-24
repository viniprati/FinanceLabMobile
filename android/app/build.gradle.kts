import org.gradle.api.Action
import org.gradle.api.execution.TaskExecutionGraph
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.isFile) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

val requiredSigningProperties = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
)
val missingSigningProperties = requiredSigningProperties.filter {
    keystoreProperties.getProperty(it).isNullOrBlank()
}
val signingStoreFile = keystoreProperties.getProperty("storeFile")?.let(::file)
val releaseSigningIssue = when {
    missingSigningProperties.isNotEmpty() ->
        "faltam as propriedades ${missingSigningProperties.joinToString()} em android/key.properties"
    signingStoreFile?.isFile != true ->
        "o arquivo definido por storeFile não existe ou não é legível"
    else -> null
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.viniprati.financelab_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.viniprati.financelab_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseSigningIssue == null) {
                storeFile = signingStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

gradle.taskGraph.whenReady(
    object : Action<TaskExecutionGraph> {
        override fun execute(graph: TaskExecutionGraph) {
            val releaseTaskRequested = graph.allTasks.any { task ->
                task.name.contains("release", ignoreCase = true)
            }
            if (releaseTaskRequested && releaseSigningIssue != null) {
                throw GradleException(
                    "A build de release exige uma assinatura de produção: $releaseSigningIssue. " +
                        "Crie android/key.properties conforme o README. A chave de debug nunca é usada em release.",
                )
            }
        }
    },
)

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
