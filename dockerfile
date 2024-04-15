FROM debian:bookworm

# APT install
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget ca-certificates xz-utils\
        git cmake make ninja-build \
        gcc g++ \
        gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
        python3 \
        dpkg-dev \
        &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

ENV QT_VERSION 5.15.9
ENV QT_PATH /opt/qt

RUN cd /tmp/ &&\
    wget -nv https://mirrors.bfsu.edu.cn/qt/official_releases/qt/${QT_VERSION%.*}/$QT_VERSION/single/qt-everywhere-opensource-src-$QT_VERSION.tar.xz &&\
    tar xf qt-everywhere-opensource-src-$QT_VERSION.tar.xz &&\
    cd qt-everywhere-src-$QT_VERSION &&\
    ./configure -prefix ${QT_PATH} -release -opensource -confirm-license -nomake examples -nomake tests -no-compile-examples -no-qml-debug -no-opengl -xplatform linux-aarch64-gnu-g++ -device-option CROSS_COMPILE=aarch64-linux-gnu- &&\
    make -j $(cat /proc/cpuinfo | grep "processor" | wc -l) && \
    make install && \
    rm -rf cd /tmp/*

ENV QT_TOOLCHAIN_FILE /opt/qt/cmake_toolchain_arm64.cmake
RUN /usr/share/cmake/debtoolchainfilegen arm64 > ${QT_TOOLCHAIN_FILE}

# Test
RUN mkdir -p /tmp/g && cd /tmp/g &&\
    echo > CMakeLists.txt &&\
    echo "cmake_minimum_required(VERSION 3.16)" >> CMakeLists.txt &&\
    echo "project(Test)" >> CMakeLists.txt &&\
    echo "find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Quick)" >> CMakeLists.txt &&\
    echo "find_package(Qt\${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Quick)" >> CMakeLists.txt &&\
    echo "if(\${QT_VERSION_MAJOR} GREATER_EQUAL 6)" >> CMakeLists.txt &&\
    echo "  qt_add_executable(Test ./main.cpp)" >> CMakeLists.txt &&\
    echo "else()" >> CMakeLists.txt &&\
    echo "  add_executable(Test ./main.cpp)" >> CMakeLists.txt &&\
    echo "endif()" >> CMakeLists.txt &&\
    echo "target_link_libraries(Test PRIVATE Qt\${QT_VERSION_MAJOR}::Core Qt\${QT_VERSION_MAJOR}::Quick)" >> CMakeLists.txt &&\
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
        -DCMAKE_TOOLCHAIN_FILE:PATH=${QT_TOOLCHAIN_FILE} \
        -DCMAKE_FIND_ROOT_PATH:PATH=${QT_PATH} &&\
    cmake --build ./build --config Debug -j $(cat /proc/cpuinfo | grep "processor" | wc -l) &&\
    rm -r /tmp/g
