allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // ✅ ROOT CAUSE FIX: Align SDK and JVM Toolchains globally
    afterEvaluate {
        // 1. Force SDK 36 for all modules (resolves lStar)
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt is com.android.build.gradle.BaseExtension) {
                androidExt.compileSdkVersion(36)
                androidExt.defaultConfig {
                    minSdk = 26
                    targetSdk = 36
                }
                androidExt.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }

        // 2. ✅ DETERMINISTIC JVM ALIGNMENT: Force Java 17 for all compilers
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }

        // 3. ✅ DETERMINISTIC KOTLIN ALIGNMENT: Force JVM Target 17
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}