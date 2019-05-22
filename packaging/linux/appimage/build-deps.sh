#!/bin/bash
#
# Build all KMyMoney's dependencies on Ubuntu 16.04.
#
# Prerequisites: cmake git build-essential libxcb-keysyms1-dev plus all deps for Qt5
#
set -eux

# Switch directory in order to put all build files in the right place
cd $CMAKE_BUILD_PREFIX

# Those flags will be propageted to Autotools and CMake
export CXXFLAGS="-O2 -DNDEBUG"
export CFLAGS="-O2 -DNDEBUG"

# Configure the dependencies for building
cmake -G"Unix Makefiles" \
      $KMYMONEY_SOURCES/3rdparty \
      -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_PREFIX \
      -DCMAKE_BUILD_TYPE=None \
      -DEXT_DOWNLOAD_DIR=$DOWNLOADS_DIR

# Now start building everything we need, in the appropriate order
cmake --build . --target ext_iconv -- -j${CPU_COUNT}

if [ ! -f $DEPS_INSTALL_PREFIX/lib/libQt5Core.so ]; then
  if [ -v TRAVIS ]; then bash -c "for i in {1..4};do sleep 9m; echo \"Still building\"; done;" & fi;
  cmake --build . --target ext_qtbase -- -j${CPU_COUNT}
fi

if [ ! -f $DEPS_INSTALL_PREFIX/lib/libQt5Qml.so ]; then
  if [ -v TRAVIS ]; then bash -c "for i in {1..4};do sleep 9m; echo \"Still building\"; done;" & fi;
  cmake --build . --target ext_qtdeclarative -- -j${CPU_COUNT}
fi

cmake --build . --target ext_qttools -- -j${CPU_COUNT}
cmake --build . --target ext_qtspeech -- -j${CPU_COUNT}
cmake --build . --target ext_qtx11extras -- -j${CPU_COUNT}

cmake --build . --target ext_kitemviews -- -j${CPU_COUNT}
cmake --build . --target ext_kcmutils -- -j${CPU_COUNT}
cmake --build . --target ext_kactivities -- -j${CPU_COUNT}
cmake --build . --target ext_kitemmodels -- -j${CPU_COUNT}
cmake --build . --target ext_khtml -- -j${CPU_COUNT}
cmake --build . --target ext_kholidays -- -j${CPU_COUNT}
cmake --build . --target ext_kidentitymanagement -- -j${CPU_COUNT}
cmake --build . --target ext_kcontacts -- -j${CPU_COUNT}
# cmake --build . --target ext_akonadi -- -j${CPU_COUNT}
# cmake --build . --target ext_alkimia -- -j${CPU_COUNT}
cmake --build . --target ext_kdiagram -- -j${CPU_COUNT}
cmake --build . --target ext_aqbanking -- -j${CPU_COUNT}
cmake --build . --target ext_sqlcipher -- -j${CPU_COUNT}
cmake --build . --target ext_ofx -- -j${CPU_COUNT}
cmake --build . --target ext_ical -- -j${CPU_COUNT}
cmake --build . --target ext_patchelf -- -j${CPU_COUNT}