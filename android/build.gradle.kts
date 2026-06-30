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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// naver_login_flutter 3.0.3 의 build.gradle 은 `apply plugin: "kotlin-android"` 을
// `if (agpMajorVersion < 9)` 블록 안에 둔다. AGP 9 에서는 이 블록이 실행되지 않아
// kotlin-android 가 끝까지 적용되지 않고, 결과적으로 `kotlin { compilerOptions {} }`
// DSL 이 없어서 "Could not find method kotlin()" 로 빌드가 실패한다.
// (Flutter 툴체인은 빌드파일 텍스트에 `apply plugin: "kotlin-android"` 가 보이면
//  이미 KGP 를 적용한 것으로 판단해 자동 적용을 건너뛰므로 더더욱 누락된다.)
// 따라서 해당 서브프로젝트에만 kotlin-android 를 강제로 적용해 준다.
subprojects {
    if (name == "naver_login_flutter") {
        pluginManager.apply("kotlin-android")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
