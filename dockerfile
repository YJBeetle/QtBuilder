FROM debian:bullseye

# Setup Android SDK
RUN apt --quiet update --yes &&\
    apt --quiet install --yes wget unzip android-sdk &&\
    wget -nc -O /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip &&\
    unzip -o /tmp/commandlinetools.zip -d /usr/lib/android-sdk &&\
    rm /tmp/commandlinetools.zip &&\
    (yes | /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --licenses || true) &&\
    /usr/lib/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/usr/lib/android-sdk --install "cmdline-tools;latest" "platform-tools" "platforms;android-31" "build-tools;31.0.0" "ndk;22.1.7171670" &&\
    rm -rf /usr/lib/android-sdk/build-tools/debian

# Setup Qt
RUN apt --quiet update --yes &&\
    apt --quiet install --yes libglib2.0-0 python3-pip &&\
    pip install -U pip &&\
    pip install aqtinstall &&\
    aqt install-qt linux desktop 6.2.3 gcc_64 -m all -O /Qt &&\
    aqt install-qt linux android 6.2.3 android_arm64_v8a -m all -O /Qt

# Install toolchain
RUN echo "deb http://deb.debian.org/debian bullseye-backports main" >> /etc/apt/sources.list &&\
    apt --quiet update --yes &&\
    apt --quiet install --yes -t bullseye-backports cmake
