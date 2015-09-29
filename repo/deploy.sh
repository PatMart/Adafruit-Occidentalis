#!/usr/bin/env bash

NODE_DEB='node_0.12.6_armhf.deb'
IDE_DEB='adafruitwebide-0.3.10-Linux.deb'

# make sure user passed a path to the repo
if [ "$1" == "" ]; then
  echo "You must specify a path to your pi_bootstrap repo. i.e. /home/admin/pi_bootstrap"
  exit 1
fi

# confirm we are working with the right folder
if [ ! -f $1/finder.sh ]; then
  echo "Are you sure ${1} is the correct path to the repo? finder.sh check failed."
  exit 1
fi

# deploy latest finder shell script
cd /var/packages/bootstrap
rm index.txt
cp $1/finder.sh index.txt
chmod 644 index.txt

# deploy latest install shell script
mkdir -p /var/packages/install
cd /var/packages/install
rm index.txt
cp $1/install.sh index.txt
chmod 644 index.txt

# deploy latest addrepo shell script
mkdir -p /var/packages/add
cd /var/packages/add
rm index.txt
cp $1/addrepo.sh index.txt
chmod 644 index.txt

# deploy latest install shell script
mkdir -p /var/packages/add-pin
cd /var/packages/add-pin
cp $1/addrepo-pin.sh index.txt
chmod 644 index.txt

# deploy latest install shell script
mkdir -p /var/packages/install-pin
cd /var/packages/install-pin
cp $1/install-pin.sh index.txt
chmod 644 index.txt

# copy the packages to a temp folder, build them:
TEMP_DIR=`mktemp -d`
cp -r $1/packages/* $TEMP_DIR
mkdir $TEMP_DIR/build
cd $TEMP_DIR
make

# make the deb cache folder if it doesn't exist
mkdir -p ~/deb_cache

# cache the node deb
if [ ! -f ~/deb_cache/$NODE_DEB ]; then
  wget http://node-arm.herokuapp.com/node_latest_armhf.deb -O ~/deb_cache/$NODE_DEB
fi
# cache the webide deb
if [ ! -f ~/deb_cache/$IDE_DEB ]; then
  wget -P ~/deb_cache/ http://adafruit-download.s3.amazonaws.com/$IDE_DEB
fi

# copy all of the cached debs into the build dir
cp ~/deb_cache/*.deb $TEMP_DIR/build

# sign packages, and add them to the repo
dpkg-sig -k $GPG_KEY --sign builder $TEMP_DIR/build/*.deb
cd /var/packages/raspbian/

# this is a hack - TODO, investigate why these packages differ
reprepro -V remove wheezy node
reprepro -V remove wheezy occi
reprepro -V remove wheezy occidentalis
reprepro -V remove wheezy adafruitwebide
reprepro -V remove wheezy adafruit-pitft-helper
reprepro -V remove wheezy adafruit-pi-externalroot-helper
reprepro -V remove wheezy libraspberrypi-dev
reprepro -V remove wheezy libraspberrypi-doc
reprepro -V remove wheezy libraspberrypi-bin
reprepro -V remove wheezy libraspberrypi0
reprepro -V remove wheezy raspberrypi-bootloader
reprepro -V remove wheezy wiringpi
reprepro -V remove wheezy adafruit-ap
reprepro -V remove wheezy xinput-calibrator
reprepro -V remove wheezy adafruit-io-gif
reprepro -V remove wheezy raspberrypi-bootloader-adafruit-pitft
reprepro -V remove wheezy libraspberrypi-bin-adafruit-pitft
reprepro -V remove wheezy libraspberrypi-doc-adafruit-pitft
reprepro -V remove wheezy libraspberrypi0-adafruit-pitft 
reprepro -V remove wheezy libraspberrypi-dev-adafruit-pitft
reprepro -V remove wheezy avrdude
reprepro -V remove wheezy avrdude-doc

reprepro includedeb wheezy $TEMP_DIR/build/*.deb

# clean up
rm -r $TEMP_DIR
