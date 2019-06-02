#!/bin/bash
#
# Build KMyMoney on MacOS High Sierra.

# Halt on errors and be verbose about what we are doing
set -eux

# Switch directory in order to put all build files in the right place
cd $CMAKE_BUILD_PREFIX

# Configure KMyMoney for building
cmake -G "Unix Makefiles" \
      $KMYMONEY_SOURCES \
      -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX \
      -DKDE_INSTALL_BUNDLEDIR=$CMAKE_INSTALL_PREFIX/Applications/KDE \
      -DCMAKE_PREFIX_PATH=$DEPS_INSTALL_PREFIX \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DBUILD_TESTING=TRUE \
      -DIS_APPIMAGE=FALSE \
      -DAPPLE_SUPPRESS_X11_WARNING=ON \
      -DCMAKE_MACOSX_RPATH=ON \
      -DKDE_SKIP_RPATH_SETTINGS=ON \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=10.12 \
      -DDARWIN_KERNEL_VERSION=16.0.0

# Build and Install KMyMoney (ready for the next phase)
cmake --build . --target install -- -j${CPU_COUNT}