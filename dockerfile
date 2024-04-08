FROM debian:bookworm

# APT install
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-dev pip \
        git cmake make ninja-build \
        gcc g++ \
        libglx-dev libgl1-mesa-dev libglib2.0-0 libfontconfig1 libxkbcommon0 libfreetype6 libdbus-1-3 \
        &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    rm -f /usr/lib/python*/EXTERNALLY-MANAGED

ENV QT_VERSION 6.4.0
ENV TARGET_ARCH gcc_64
ENV HOST_ARCH gcc_64

# Setup Qt
RUN pip install aqtinstall &&\
    aqt install-qt -b https://mirrors.dotsrc.org/qtproject linux desktop $QT_VERSION $HOST_ARCH -m qtshadertools qtquick3d -O /Qt &&\
    aqt install-qt -b https://mirrors.dotsrc.org/qtproject linux desktop $QT_VERSION $TARGET_ARCH -m qtcharts qtconnectivity qtpositioning qtshadertools qtquick3d qtquicktimeline -O /Qt

ENV QT_PATH /Qt/$QT_VERSION/$TARGET_ARCH/
ENV QT_HOST_PATH /Qt/$QT_VERSION/$HOST_ARCH/

# Test
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
        -DCMAKE_FIND_ROOT_PATH:PATH=${QT_PATH} \
        -DCMAKE_PREFIX_PATH:PATH=${QT_PATH} \
        -DQT_HOST_PATH:PATH=${QT_HOST_PATH} &&\
    cmake --build ./build --config Debug -j $(cat /proc/cpuinfo | grep "processor" | wc -l) &&\
    rm -r /tmp/g
