#!/usr/bin/env bash -ex
EMSDK="sdk-1.35.0-64bit"

pushd emsdk
./emsdk activate $EMSDK
./emsdk_env.sh
popd

