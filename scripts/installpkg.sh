#!/bin/sh
#    Author: Eric Turgeon
# Copyright: 2014 GhostBSD
#
# Creates package for GhostBSD

set -e -u

if [ -z "${LOGFILE:-}" ]; then
  echo "This script can't run standalone."
  echo "Please use launch.sh to execute it."
  exit 1
fi

pkgfile="conf/packages"
pkgaddcmd="pkg install -y "

# Search main file package for include dependecies
# and build an depends file ( depends )
awk '/^deps/,/^"""/' packages/mate | grep -v '"""' | grep -v '#' > packages/depends

# Add to EXTRA plugins the needed plugin readed from settings section
# Readed plugin is added only if it isn't already in conf file
add_extra=$(cat packages/mate | grep -iF1 settings= | grep -v '"""')

# If exist an old .packages file removes it
if [ -f conf/packages ] ; then
  rm -f conf/packages
fi

# Reads packages from packages profile
awk '/^packages/,/^"""/' packages/mate > conf/package

# Reads depends file and search for packages entries in each file from depends
# list, then append all packages found in packages file
while read pkgs ; do
  awk '/^packages/,/^"""/' packages/packages.d/$pkgs  >> conf/package
done < packages/depends 

# Removes """ and # from temporary package file
cat conf/package | grep -v '"""' | grep -v '#' > conf/packages

# Removes temporary files
if [ -f conf/package ] ; then
  rm -f conf/package
  rm -f packages/depends
fi

echo "#!/bin/sh" > scripts/ports.sh
echo "portinstall -c" | tr "\n" " " >> scripts/ports.sh
cat conf/packages | tr "\n" " " >> scripts/ports.sh

# Installing pkg
while read pkgc; do
  if [ -n "${pkgc}" ]; then
    if [ "$(uname -p)" = "amd64" ]; then
      if [ "${pkgc}" = "xorg-minimal" ]; then
        echo "Pass $pkgc"
      elif [ "${pkgc}" = "xorg-drivers" ]; then
        echo "Pass $pkgc"
      else 
        $pkgaddcmd $pkgc
      fi
    else
      $pkgaddcmd $pkgc
    fi   
  fi
done < $pkgfile


#installing remaining pkg from ports.

sh scripts/ports.sh
