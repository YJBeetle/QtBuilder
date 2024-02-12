FROM debian:bookworm

# APT install
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget unzip default-jdk-headless \
        pip \
        git cmake make ninja-build \
        &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    rm -f /usr/lib/python*/EXTERNALLY-MANAGED

# Install command line tools
RUN wget -nc -O /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip &&\
    unzip -o /tmp/commandlinetools.zip -d /usr/lib/android-sdk &&\
    rm /tmp/commandlinetools.zip &&\
    (yes | /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --licenses || true)

# Setup Android SDK
# https://doc.qt.io/qt-6/android-getting-started.html
ENV BUILD_TOOLS_VERSION 33.0.0
ENV NDK_VERSION 25.1.8937393
RUN /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --install "platform-tools" "platforms;android-31" "build-tools;$BUILD_TOOLS_VERSION" "ndk;$NDK_VERSION"

ENV ANDROID_SDK_ROOT /usr/lib/android-sdk/
ENV ANDROID_NDK_ROOT /usr/lib/android-sdk/ndk/$NDK_VERSION/

ENV QT_VERSION 6.5.0
ENV TARGET_ARCH android_arm64_v8a
ENV HOST_ARCH gcc_64

# Setup Qt
RUN pip install aqtinstall &&\
    aqt install-qt -b https://mirrors.dotsrc.org/qtproject linux desktop $QT_VERSION $HOST_ARCH -m qtshadertools qtquick3d -O /Qt &&\
    aqt install-qt -b https://mirrors.dotsrc.org/qtproject linux android $QT_VERSION $TARGET_ARCH -m qtcharts qtconnectivity qtpositioning qtshadertools qtquick3d qtquicktimeline -O /Qt

ENV QT_PATH /Qt/$QT_VERSION/$TARGET_ARCH/
ENV QT_HOST_PATH /Qt/$QT_VERSION/$HOST_ARCH/

# Test
ADD ./Test/ /Qt/Test
RUN cmake -S /Qt/Test -B /Qt/TestBuild \
        -DCMAKE_BUILD_TYPE:STRING=Debug \
        -DCMAKE_TOOLCHAIN_FILE:PATH=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
        -DCMAKE_FIND_ROOT_PATH:PATH=${QT_PATH} \
        -DCMAKE_PREFIX_PATH:PATH=${QT_PATH} \
        -DQT_HOST_PATH:PATH=${QT_HOST_PATH} \
        -DANDROID_ABI:STRING=arm64-v8a \
        -DANDROID_STL:STRING=c++_shared \
        -DANDROID_SDK_ROOT:PATH=${ANDROID_SDK_ROOT} \
        -DANDROID_NDK:PATH=${ANDROID_NDK_ROOT} \
        &&\
    cmake --build /Qt/TestBuild --target all &&\
    rm -rf /Qt/TestBuild