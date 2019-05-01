#!/bin/bash
#
# Build all KMyMoney's dependencies on MacOS High Sierra.

set -eux

# Switch directory in order to put all build files in the right place
cd $CMAKE_BUILD_PREFIX

# Build ninja from source in order to avoid lenghty "brew install ninja"
cd $CMAKE_BUILD_PREFIX
NINJA_EXECUTABLE=$DEPS_INSTALL_PREFIX/bin/ninja
if [ ! -f $NINJA_EXECUTABLE ] ||
   [ $(tr . 0 <<< $($NINJA_EXECUTABLE --version)) -lt $(tr . 0 <<< "1.9.0") ] ; then
  rm -fr ninja
  git clone --single-branch -b release --depth 1 git://github.com/ninja-build/ninja.git
  cd ninja
  python3 configure.py --bootstrap
  mkdir -p $DEPS_INSTALL_PREFIX/bin
  install -vm755 ninja $DEPS_INSTALL_PREFIX/bin
  cd ..
  rm -fr ninja
fi


# Configure the dependencies for building
cmake -GNinja \
      $KMYMONEY_SOURCES/3rdparty \
      -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_PREFIX \
      -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=10.12 \
      -DDARWIN_KERNEL_VERSION=16.0.0 \
      -DEXT_DOWNLOAD_DIR=$DOWNLOADS_DIR

bash -c "for i in {1..5};do sleep 540; echo \"Still building\"; done;" & #MacOS accepts only seconds
# Now start building everything we need, in the appropriate order
pip3 install meson
cmake --build . --target ext_xml -- -j${CPU_COUNT}
cmake --build . --target ext_gettext -- -j${CPU_COUNT}
cmake --build . --target ext_bison -- -j${CPU_COUNT} # required by solid
cmake --build . --target ext_flex -- -j${CPU_COUNT}
cmake --build . --target ext_xslt -- -j${CPU_COUNT}
cmake --build . --target ext_png -- -j${CPU_COUNT}
cmake --build . --target ext_jpeg -- -j${CPU_COUNT} #this causes build failures in Qt 5.10
# cmake --build . --target ext_qt -- -j${CPU_COUNT}
cmake --build . --target ext_qtbase -- -j${CPU_COUNT}
cmake --build . --target ext_qttools -- -j${CPU_COUNT}
cmake --build . --target ext_qtdeclarative -- -j${CPU_COUNT}
cmake --build . --target ext_qtmacextras -- -j${CPU_COUNT}
cmake --build . --target ext_qtwebchannel -- -j${CPU_COUNT}
# cmake --build . --target ext_qtwebengine -- -j${CPU_COUNT}
cmake --build . --target ext_boost -- -j${CPU_COUNT}
cmake --build . --target ext_breezeicons -- -j${CPU_COUNT}
cmake --build . --target ext_kcmutils -- -j${CPU_COUNT}
cmake --build . --target ext_kactivities -- -j${CPU_COUNT}
cmake --build . --target ext_kitemmodels -- -j${CPU_COUNT}
cmake --build . --target ext_kitemviews -- -j${CPU_COUNT}
cmake --build . --target ext_gmp -- -j${CPU_COUNT}
# cmake --build . --target ext_kholidays -- -j${CPU_COUNT}
# cmake --build . --target ext_kidentitymanagement -- -j${CPU_COUNT}
# cmake --build . --target ext_kcontacts -- -j${CPU_COUNT}
# cmake --build . --target ext_akonadi -- -j${CPU_COUNT}
# cmake --build . --target ext_alkimia -- -j${CPU_COUNT}
# cmake --build . --target ext_kdiagram -- -j${CPU_COUNT}
# cmake --build . --target ext_aqbanking -- -j${CPU_COUNT}
# cmake --build . --target ext_gpgme -- -j${CPU_COUNT}
# cmake --build . --target ext_sqlcipher -- -j${CPU_COUNT}
# cmake --build . --target ext_ofx -- -j${CPU_COUNT}
# cmake --build . --target ext_ical -- -j${CPU_COUNT}
