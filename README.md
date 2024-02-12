# QtBuilder

[![Docker](https://github.com/YJBeetle/QtBuilder/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/YJBeetle/QtBuilder/actions/workflows/docker-publish.yml)

这是一个配置好的Qt编译环境docker镜像，我创建他是为了用于Gitlab CI，当然你也可以用于其他用途。

目前的编译目标主要是Android平台的Qt。

## Gitlab CI 示例

```
image: ghcr.io/yjbeetle/qtbuilder:Qt6.4.0-android_arm64_v8a

Debug-build:
  stage: build
  rules:
    - if: $CI_COMMIT_TAG != $CI_COMMIT_REF_NAME
  script:
    - cmake -B ./build -S .
          -DCMAKE_BUILD_TYPE:STRING=Debug
          -DCMAKE_TOOLCHAIN_FILE:PATH=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake
          -DCMAKE_FIND_ROOT_PATH:PATH=${QT_PATH}
          -DCMAKE_PREFIX_PATH:PATH=${QT_PATH}
          -DQT_HOST_PATH:PATH=${QT_HOST_PATH}
          -DANDROID_ABI:STRING=arm64-v8a
          -DANDROID_STL:STRING=c++_shared
          -DANDROID_SDK_ROOT:PATH=${ANDROID_SDK_ROOT}
          -DANDROID_NDK:PATH=${ANDROID_NDK_ROOT}
    - cmake --build ./build --config Debug -j $(cat /proc/cpuinfo | grep "processor" | wc -l)
    - cp build/android-build/build/outputs/apk/debug/android-build-debug.apk $CI_JOB_NAME.apk
  artifacts:
    name: "$CI_JOB_NAME-$CI_COMMIT_REF_NAME-$CI_COMMIT_SHORT_SHA"
    paths:
      - $CI_JOB_NAME.apk
    expire_in: 1 week
```