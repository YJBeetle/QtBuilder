FROM debian:bullseye-backports

ENV QT_VERSION 6.4.1
ENV NDK_VERSION 23.1.7779620
ENV TARGET_ARCH android_arm64_v8a
ENV HOST_ARCH gcc_64

# Setup Android SDK
# https://doc.qt.io/qt-6/android-getting-started.html
RUN apt --quiet update --yes &&\
    apt --quiet install --yes wget unzip android-sdk &&\
    wget -nc -O /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip &&\
    unzip -o /tmp/commandlinetools.zip -d /usr/lib/android-sdk &&\
    rm /tmp/commandlinetools.zip &&\
    (yes | /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --licenses || true) &&\
    /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --install "platform-tools" "platforms;android-31" "build-tools;31.0.0" "ndk;$NDK_VERSION" &&\
    rm -rf /usr/lib/android-sdk/build-tools/debian

ENV ANDROID_SDK_ROOT /usr/lib/android-sdk/
ENV ANDROID_NDK_ROOT /usr/lib/android-sdk/ndk/$NDK_VERSION/

# Setup Qt
RUN apt --quiet update --yes &&\
    apt --quiet install --yes libglib2.0-0 python3-pip &&\
    pip install -U pip &&\
    pip install aqtinstall &&\
    aqt install-qt -b https://mirrors.dotsrc.org/qtproject linux desktop $QT_VERSION $HOST_ARCH -m qtshadertools qtquick3d -O /Qt &&\
    aqt install-qt -b https://mirrors.dotsrc.org/qtproject linux android $QT_VERSION $TARGET_ARCH -m qtcharts qtconnectivity qtpositioning qtshadertools qtquick3d qtquicktimeline -O /Qt

ENV QT_PATH /Qt/$QT_VERSION/$TARGET_ARCH/
ENV QT_HOST_PATH /Qt/$QT_VERSION/$HOST_ARCH/

# Cache gradle 7.2
RUN mkdir -p /tmp/g && cd /tmp/g &&\
    gradle wrapper --gradle-version 7.2 --distribution-type=bin &&\
    (./gradlew tasks || true) &&\
    rm -r /tmp/g

# Install toolchain
RUN apt --quiet update --yes &&\
    apt --quiet install --yes git ninja-build &&\
    apt --quiet install --yes -t bullseye-backports cmake
