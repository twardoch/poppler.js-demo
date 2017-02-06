#!/usr/bin/env bash -ex
EMSDK="sdk-1.35.0-64bit"

mkdir -p emsdk
pushd emsdk
wget https://raw.githubusercontent.com/juj/emsdk/master/emsdk
chmod gou+x ./emsdk
./emsdk update
./emsdk list --old
./emsdk install $EMSDK
popd

