FROM debian:bookworm

# Install toolchain
RUN apt-get update && apt-get install -y --no-install-recommends git ninja-build cmake && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup Android SDK
# https://doc.qt.io/qt-6/android-getting-started.html
RUN apt-get update && apt-get install -y --no-install-recommends wget unzip android-sdk && apt-get clean && rm -rf /var/lib/apt/lists/* &&\
    wget -nc -O /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip &&\
    unzip -o /tmp/commandlinetools.zip -d /usr/lib/android-sdk &&\
    rm /tmp/commandlinetools.zip &&\
    (yes | /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --licenses || true) &&\
    /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --install "platform-tools" "platforms;android-31" &&\
    rm -rf /usr/lib/android-sdk/build-tools/debian
ENV BUILD_TOOLS_VERSION 31.0.0
ENV NDK_VERSION 23.1.7779620
RUN /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --install "build-tools;$BUILD_TOOLS_VERSION" "ndk;$NDK_VERSION"

ENV ANDROID_SDK_ROOT /usr/lib/android-sdk/
ENV ANDROID_NDK_ROOT /usr/lib/android-sdk/ndk/$NDK_VERSION/

# Setup Qt
RUN apt-get update && apt-get install -y --no-install-recommends libglib2.0-0 python3-pip && apt-get clean && rm -rf /var/lib/apt/lists/* &&\
    rm /usr/lib/python*/EXTERNALLY-MANAGED &&\
    pip install -U pip &&\
    pip install aqtinstall
ENV QT_VERSION 6.4.3
ENV TARGET_ARCH android_arm64_v8a
ENV HOST_ARCH gcc_64
RUN aqt install-qt -b https://mirrors.dotsrc.org/qtproject linux desktop $QT_VERSION $HOST_ARCH -m qtshadertools qtquick3d -O /Qt &&\
    aqt install-qt -b https://mirrors.dotsrc.org/qtproject linux android $QT_VERSION $TARGET_ARCH -m qtcharts qtconnectivity qtpositioning qtshadertools qtquick3d qtquicktimeline -O /Qt

ENV QT_PATH /Qt/$QT_VERSION/$TARGET_ARCH/
ENV QT_HOST_PATH /Qt/$QT_VERSION/$HOST_ARCH/

# Test and cache gradle
RUN mkdir -p /tmp/g && cd /tmp/g &&\
    echo "\
cmake_minimum_required(VERSION 3.16)\n\
project(Test)\n\
find_package(Qt6 REQUIRED COMPONENTS Core Quick)\n\
qt_add_executable(Test ./main.cpp)\n\
target_link_libraries(Test PRIVATE Qt6::Core Qt6::Quick)\n\
"> CMakeLists.txt &&\
    echo > main.cpp &&\
    echo '#include <QtGui/QGuiApplication>' >> main.cpp &&\
    echo '#include <QtQml/QQmlApplicationEngine>' >> main.cpp &&\
    echo 'int main(int argc, char *argv[]) {' >> main.cpp &&\
    echo '    QGuiApplication app(argc, argv);' >> main.cpp &&\
    echo '    QQmlApplicationEngine engine;' >> main.cpp &&\
    echo '    return app.exec();' >> main.cpp &&\
    echo '}' >> main.cpp &&\
    cmake -B ./build -S . \
        -G"Ninja" \
        -DCMAKE_BUILD_TYPE:STRING=Debug \
        -DANDROID_NDK:PATH=${ANDROID_NDK_ROOT} \
        -DCMAKE_TOOLCHAIN_FILE:PATH=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
        -DCMAKE_FIND_ROOT_PATH:PATH=${QT_PATH} \
        -DCMAKE_PREFIX_PATH:PATH=${QT_PATH} \
        -DQT_HOST_PATH:PATH=${QT_HOST_PATH} \
        -DANDROID_ABI:STRING=arm64-v8a \
        -DANDROID_STL:STRING=c++_shared \
        -DANDROID_SDK_ROOT:PATH=${ANDROID_SDK_ROOT} &&\
    cmake --build ./build --config Debug -j $(cat /proc/cpuinfo | grep "processor" | wc -l) &&\
    rm -r /tmp/g
