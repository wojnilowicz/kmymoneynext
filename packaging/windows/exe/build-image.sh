#  *
#  * Copyright 2020  Łukasz Wojniłowicz <lukasz.wojnilowicz@gmail.com>
#  *
#  * This program is free software; you can redistribute it and/or
#  * modify it under the terms of the GNU General Public License as
#  * published by the Free Software Foundation; either version 2 of
#  * the License, or (at your option) any later version.
#  *
#  * This program is distributed in the hope that it will be useful,
#  * but WITHOUT ANY WARRANTY; without even the implied warranty of
#  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  * GNU General Public License for more details.
#  *
#  * You should have received a copy of the GNU General Public License
#  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
#  *

#!/bin/bash
#
# Build DmgImage of KMyMoney on MS Windows 7.

# Halt on errors and be verbose about what we are doing
set -eu

IMAGE_BUILD_PREFIX=${CMAKE_BUILD_PREFIX}

sourceLibPaths=(
$DEPS_INSTALL_PREFIX/bin
/c/msys64/mingw64/bin
/mingw64/bin
)

# Function expects to be started from bin directory
function find_needed_libs () {
  echo "Analizing libraries with ldd..." >&2
  local needed_libs=() # input lib_lists founded
  local libFiles=(${@})

  for libFile in ${libFiles[@]}; do
    echo ${libFile} >&2
    needed_libs+=($(ldd ${libFile} | awk '{print $3}'))
  done

  if [ ${#needed_libs[@]} -gt 0 ]; then
    echo ${needed_libs[@]}
  fi
}

function find_missing_libs (){
  echo "Searching for missing libs on deployment folders…" >&2
  local missing_libs=()
  # filter out libraies that are already in the appdir or are system ones
  local needed_libs=($(printf '%s\n' "${@}" |
      sort -u |
      sed '/image-build/d' |
      sed '/system32/d' |
      sed '/System32/d' |
      sed '/SYSTEM32/d' |
      sed '/WinSxS/d'
      ))

  for lib in ${needed_libs[@]:0}; do
    for souceLibPath in ${sourceLibPaths[@]}; do
      if [ "${lib:0:${#souceLibPath}}" == "${souceLibPath}" ]; then
        echo "Adding ${lib##*/} to missing libraries." >&2
        missing_libs+=("${lib}")
        break
      else
        echo "Library from unexpected source ${lib}." >&2
      fi
    done
  done

  if [ ${#missing_libs[@]} -gt 0 ]; then
    echo ${missing_libs[@]}
  fi
}

function copy_missing_libs () {
  for lib in ${@}; do
    echo "copying ${lib##*/} to bin dir" >&2
    cp -pvu ${lib} ${IMAGE_BUILD_PREFIX}/bin
  done
}

function kmymoney_findmissinglibs() {
  echo "Starting search for missing libraries"
  local needed_libs=()
  local missing_libs=()
  local missing_libs_partial=()
  # Must be invoked from bin, otherwise libraries appear as "??? -> ???"
  cd $IMAGE_BUILD_PREFIX/bin
  local libFiles=$(find .. -type f \( -name "*.exe" -or -name "*.dll" \))
  while [ true ]; do

    needed_libs=($(find_needed_libs ${libFiles[@]}))
    missing_libs_partial=($(find_missing_libs ${needed_libs[@]}))
    # break only if there is no missing libraries left
    if [ ${#missing_libs_partial[@]} -eq 0 ]; then
      break
    else
      missing_libs+=(${missing_libs_partial[@]})
      libFiles=(${missing_libs_partial[@]}) # see if missing libraries also have some missing libraries
    fi
  done

  if [ ${#missing_libs[@]} -gt 0 ]; then
    echo "Found missing libs!"
    missing_libs=($(printf '%s\n' "${missing_libs[@]}" | sort -u))
    copy_missing_libs ${missing_libs[@]}
  else
    echo "No missing libraries found."
  fi

  echo "Done!"
}

createNSIS () {
  # $1 installer base name
  cd ${IMAGE_BUILD_PREFIX}

  # Extract KMymoney's components
  # QIF
  mkdir -p qif/plugin
  mkdir -p qif/service

  if [ -f bin/kmymoney/qifexporter.dll ]; then
    mv bin/kmymoney/*qif* qif/plugin
    mv bin/data/kservices5/*qif* qif/service
  fi

  # QFX
  mkdir -p ofx/plugin
  mkdir -p ofx/libs

  if [ -f bin/kmymoney/ofximporter.dll ]; then
    mv bin/kmymoney/ofx* ofx/plugin
    mv bin/libofx* ofx/libs
    mv bin/libosp* ofx/libs
  fi

  # Online banking
  mkdir -p onlinebanking/plugin
  mkdir -p onlinebanking/libs
  mkdir -p onlinebanking/data

  if [ -d bin/aqbanking ]; then
    mv bin/kmymoney/kbanking* onlinebanking/plugin
    mv bin/kmymoney/onlinejoboutboxview* onlinebanking/plugin

    mv bin/aqbanking onlinebanking/libs
    mv bin/gwenhywfar onlinebanking/libs
    mv bin/libaq* onlinebanking/libs
    mv bin/libgwen* onlinebanking/libs
    mv bin/libgnutls* onlinebanking/libs
    mv bin/libxmlsec* onlinebanking/libs
    mv bin/libnettle* onlinebanking/libs
    mv bin/libhogweed* onlinebanking/libs

    mv bin/data/aqbanking onlinebanking/data
    mv bin/data/gwenhywfar onlinebanking/data
    mv bin/data/kbanking onlinebanking/data
  fi

  cp -v $KMYMONEY_SOURCES/packaging/windows/exe/NullsoftInstaller.nsi .
  cp -v $KMYMONEY_SOURCES/COPYING .

  appName="KMyMoneyNEXT"
  installerBaseName="$1"
  IMAGE_BUILD_DIR_WINPATH=$(echo "$IMAGE_BUILD_PREFIX" | sed -e 's/^\///' -e 's/\//\\\\/g' -e 's/^./\0:/')

  iconName="kmymoney.ico"
  iconFilePath="${IMAGE_BUILD_DIR_WINPATH}\\\\${iconName}"
  licenseFilePath="${IMAGE_BUILD_DIR_WINPATH}\\\\COPYING"
  png2ico ${iconName} "${KMYMONEY_INSTALL_PREFIX}/bin/data/icons/hicolor/64x64/apps/kmymoney.png"

  declare -A defines

  defines=(
  ["appName"]=${appName}
  ["outFile"]=${installerBaseName}.exe
  ["company"]="KDE"
  ["iconName"]=${iconName}
  ["iconFile"]=${iconFilePath}
  ["publisher"]="Lukasz Wojnilowicz"
  ["version"]="${VERSION}"
  ["website"]="https://wojnilowicz.github.io/kmymoneynext"
  ["licenseFile"]="${licenseFilePath}"
  )

  for key in "${!defines[@]}"; do
    sed -i "s|@{${key}}|${defines[$key]}|g" NullsoftInstaller.nsi
  done

  makensis.exe NullsoftInstaller.nsi

  echo "Done!" >&2
}

# Copy installed KMyMoney to adjust its file locations
rm -fr $IMAGE_BUILD_PREFIX
cp -r $KMYMONEY_INSTALL_PREFIX $IMAGE_BUILD_PREFIX
cd $IMAGE_BUILD_PREFIX

echo "Copying libs..."
cp -v $DEPS_INSTALL_PREFIX/bin/libphonon4qt5* bin
cp -v $DEPS_INSTALL_PREFIX/bin/libassuan*.dll bin
cp -v $DEPS_INSTALL_PREFIX/bin/libgpg-* bin
cp -v $DEPS_INSTALL_PREFIX/bin/libKF5Crash.dll bin
cp -v $DEPS_INSTALL_PREFIX/bin/libKChart.dll bin
cp -v $DEPS_INSTALL_PREFIX/bin/libKF5Solid.dll bin
cp -v $DEPS_INSTALL_PREFIX/bin/libKF5GlobalAccel.dll bin
cp -v $DEPS_INSTALL_PREFIX/bin/libKF5Bookmarks.dll bin
cp -v $DEPS_INSTALL_PREFIX/bin/libKF5KIOFileWidgets.dll bin
cp -v $DEPS_INSTALL_PREFIX/bin/libKF5KIONTLM.dll bin

if [ -f $DEPS_INSTALL_PREFIX/bin/libjpeg-62.dll ]; then
  cp -v $DEPS_INSTALL_PREFIX/bin/libjpeg* bin
fi

if [ -f $DEPS_INSTALL_PREFIX/bin/libgif-7.dll ]; then
  cp -v $DEPS_INSTALL_PREFIX/bin/libgif* bin
fi

echo "Copying shares..."
if [ -f $DEPS_INSTALL_PREFIX/bin/data/icons/breeze/breeze-icons.rcc ]; then
  cp -v $DEPS_INSTALL_PREFIX/bin/data/icons/breeze/breeze-icons.rcc bin/data/icontheme.rcc
fi

cp -v $DEPS_INSTALL_PREFIX/bin/data/kservicetypes5/kcmodule* bin/data/kservicetypes5

if [ -d $DEPS_INSTALL_PREFIX/share/libofx ]; then
  echo "Copying libofx..."
  cp -rv $DEPS_INSTALL_PREFIX/share/libofx $KMYMONEY_INSTALL_PREFIX/share
fi

echo "Copying plugins..."
cp -r $DEPS_INSTALL_PREFIX/plugins/sqldrivers bin
mkdir -p bin/kmymoney
mv -v lib/plugins/kmymoney/* bin/kmymoney

if [ -d lib/plugins/sqldrivers ]; then
  echo "Copying SQLCipher..."
  mv -v lib/plugins/sqldrivers/* bin/sqldrivers
fi

if [ -f $DEPS_INSTALL_PREFIX/bin/gpgme-config ]; then
  echo "Copying GPGME..."
  cp -v $DEPS_INSTALL_PREFIX/bin/libgpgme* bin
  cp -v $DEPS_INSTALL_PREFIX/bin/gpgme-w32spawn.exe bin
fi

if [ -f $DEPS_INSTALL_PREFIX/bin/libmariadb.dll ]; then
  echo "Copying MariaDB..."
  cp -v $DEPS_INSTALL_PREFIX/bin/libmariadb.dll bin
  cp -r $DEPS_INSTALL_PREFIX/bin/mariadb bin
fi

# needed only on Travis
if [ -f $DEPS_INSTALL_PREFIX/bin/libosp-5.dll ]; then
  echo "Copying OFX..."
  cp -v $DEPS_INSTALL_PREFIX/bin/libofx* bin
  cp -v $DEPS_INSTALL_PREFIX/bin/libosp* bin
fi

if [ -f $DEPS_INSTALL_PREFIX/bin/libKF5Wallet.dll ]; then
  echo "Copying KWallet..."
  cp -fv $DEPS_INSTALL_PREFIX/bin/libKF5Wallet.dll bin
  cp -fv $DEPS_INSTALL_PREFIX/bin/libkwalletbackend5.dll bin
  cp -fv $DEPS_INSTALL_PREFIX/bin/kwallet* bin
  cp -v $DEPS_INSTALL_PREFIX/bin/data/kservices5/kwallet* bin/data/kservices5
fi

if [ -f $DEPS_INSTALL_PREFIX/bin/libKF5KHtml.dll ]; then
  echo "Copying KF5KHtml..."
  cp -v $DEPS_INSTALL_PREFIX/bin/libKF5KHtml.dll bin
  cp -v $DEPS_INSTALL_PREFIX/bin/libKF5JS.dll bin
  cp -v $DEPS_INSTALL_PREFIX/bin/libKF5Parts.dll bin
  cp -v $DEPS_INSTALL_PREFIX/bin/libpcre-1.dll bin
  cp -v $DEPS_INSTALL_PREFIX/bin/libpcreposix-0.dll bin
  mkdir -p bin/data/kf5
  cp -r $DEPS_INSTALL_PREFIX/bin/data/kf5/khtml bin/data/kf5
  cp -v $DEPS_INSTALL_PREFIX/bin/data/kservicetypes5/qimageio* bin/data/kservicetypes5
fi

if [ -d $DEPS_INSTALL_PREFIX/bin/data/dbus-1 ]; then
  echo "Copying DBus..."
  cp -fv $DEPS_INSTALL_PREFIX/bin/dbus* bin
  cp -fvr $DEPS_INSTALL_PREFIX/bin/data/dbus-1 bin/data
  cp -fv $DEPS_INSTALL_PREFIX/bin/libexpat* bin
  cp -fv  $DEPS_INSTALL_PREFIX/bin/kioslave* bin
  cp -fv  $DEPS_INSTALL_PREFIX/bin/klauncher* bin
  cp -fv  $DEPS_INSTALL_PREFIX/bin/kdeinit* bin
fi

if [ -f $DEPS_INSTALL_PREFIX/bin/libical.dll ]; then
  echo "Copying ical..."
  cp -v $DEPS_INSTALL_PREFIX/bin/libical.dll bin
fi

mkdir -p bin/kf5/kio
cp -v $DEPS_INSTALL_PREFIX/plugins/kf5/kio/file.dll bin/kf5/kio
cp -v $DEPS_INSTALL_PREFIX/plugins/kf5/kio/http.dll bin/kf5/kio

if [ -d $DEPS_INSTALL_PREFIX/share/aqbanking ]; then
  echo "Copying aqbanking and gwenhywfar..."
  cp -v $DEPS_INSTALL_PREFIX/bin/libgwen* bin
  cp -rv $DEPS_INSTALL_PREFIX/share/aqbanking bin/data
  cp -rv $DEPS_INSTALL_PREFIX/share/gwenhywfar bin/data
  mkdir -p bin/aqbanking
  mkdir -p bin/gwenhywfar
  cp -rv $DEPS_INSTALL_PREFIX/lib/aqbanking/plugins/44/* bin/aqbanking
  cp -rv $DEPS_INSTALL_PREFIX/lib/gwenhywfar/plugins/79/* bin/gwenhywfar
fi

windeployqt $IMAGE_BUILD_PREFIX/bin/kmymoney.exe \
  --verbose=2 \
  --release \
  --qml \
  --quick \
  --qmldir=${KMYMONEY_SOURCES} \
  --qmlimport=${DEPS_INSTALL_PREFIX}/qml \
  --no-translations \
  --compiler-runtime

kmymoney_findmissinglibs

# Remove redundant files and directories
cd $IMAGE_BUILD_PREFIX
rm -fr include
rm -fr lib/plugins
rm -fr bin/qmltooling
rm -fr bin/data/kmymoney/icons/oxygen
rm -fr bin/data/kmymoney/icons/Tango
find . -type f \( -name *.dll.a -or -name *.la \) -exec rm {} \;

# Strip libraries
find . -type f \( -name *.dll -or -name *.exe \) -exec strip {} \;

cd $KMYMONEY_SOURCES
KMYMONEY_VERSION=$(grep 'set(RELEASE_SERVICE_VERSION_' CMakeLists.txt | cut -d'"' -f 2 | tr '\n' '.' | sed -e 's/\.$//')

# Also find out the revision of Git we built
# Then use that to generate a combined name we'll distribute
if [ -d .git ]; then
GIT_REVISION=$(git rev-parse --short HEAD)
export VERSION=$KMYMONEY_VERSION-${GIT_REVISION:0:7}
else
export VERSION=$KMYMONEY_VERSION
fi

installerBaseName="KMyMoneyNEXT-${VERSION}-x86_64"
createNSIS "${installerBaseName}"

# upload on GitHub
bash $KMYMONEY_SOURCES/packaging/common/upload.sh "KMyMoneyNEXT%20for%20Windows" "${installerBaseName}.exe"

# TODO Get that out of here
# cd "/c/kmymoney-build"
# ctest -V -E reports-chart-test