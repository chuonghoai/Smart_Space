allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials(HttpHeaderCredentials::class) {
                name = "Authorization"
                var sdkToken = project.findProperty("SDK_REGISTRY_TOKEN")?.toString() ?: ""
                if (sdkToken.isEmpty()) {
                    val localProps = java.util.Properties()
                    val localPropsFile = project.rootProject.file("local.properties")
                    if (localPropsFile.exists()) {
                        localProps.load(java.io.FileInputStream(localPropsFile))
                        sdkToken = localProps.getProperty("SDK_REGISTRY_TOKEN") ?: ""
                    }
                }
                value = "Bearer $sdkToken"
            }
            authentication {
                create<HttpHeaderAuthentication>("basic")
            }
        }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
