#!/bin/bash
set -e

EM_DIR=/usr/local/bin
BASE_DIR=`pwd`
#FREETYPE_DIR=$EM_DIR/tests/freetype
FREETYPE_DIR=$BASE_DIR/freetype2
POPPLER_DIR=$BASE_DIR/poppler

do_freetype () {
pushd $FREETYPE_DIR
CPPFLAGS="-Oz" \
$EM_DIR/emconfigure ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --disable-biarch-config \
    --without-zlib \
    --without-bzip2 \
    --without-png \
    --without-harfbuzz \
    --without-old-mac-fonts \
    --without-fsspec \
    --without-fsref \
    --without-quickdraw-toolbox \
    --without-quickdraw-carbon \
    --without-ats \

make -j8
#ugly hack
gcc -o objs/apinames src/tools/apinames.c
make -j8

popd
}

do_poppler () {
pushd $POPPLER_DIR
FONTCONFIG_CFLAGS="-I$BASE_DIR" \
FONTCONFIG_LIBS=' ' \
FREETYPE_CFLAGS="-I$EM_DIR/tests/freetype/include" \
FREETYPE_LIBS=' ' \
CPPFLAGS="-Oz" \
$EM_DIR/emconfigure ./configure \
    --enable-shared=no \
    --disable-xpdf-headers \
    --enable-single-precision \
    --disable-libopenjpeg \
    --disable-libtiff \
    --disable-largefile \
    --disable-zlib \
    --disable-libcurl \
    --disable-libjpeg \
    --disable-libpng \
    --enable-splash-output \
    --disable-cairo-output \
    --disable-poppler-glib \
    --enable-introspection=no \
    --disable-gtk-doc \
    --disable-gtk-doc-html \
    --disable-poppler-qt4 \
    --disable-poppler-qt5 \
    --disable-poppler-cpp \
    --disable-gtk-test \
    --enable-utils \
    --enable-cms=none \
    --without-x \

make -j8
popd
}


do_link () {
mkdir web || true
$EM_DIR/emcc \
    -Oz \
    --llvm-lto 1 \
    --memory-init-file 1 \
    -s EXPORTED_FUNCTIONS="['_PopplerJS_init', '_PopplerJS_Doc_new', '_PopplerJS_Doc_delete', '_PopplerJS_Doc_get_page_count', '_PopplerJS_Doc_get_page', '_PopplerJS_Page_get_width', '_PopplerJS_Page_get_height', '_PopplerJS_Page_get_bitmap', '_PopplerJS_Bitmap_get_buffer', '_PopplerJS_Bitmap_get_row_size', '_PopplerJS_Bitmap_destroy', '_PopplerJS_Page_destroy']" \
    -o web/poppler.js \
    -I$POPPLER_DIR \
    -I$POPPLER_DIR/poppler \
    poppler.js/poppler.js.cc \
    $POPPLER_DIR/poppler/.libs/libpoppler.a \
    $FREETYPE_DIR/objs/.libs/libfreetype.a \

}

#do_freetype
#do_poppler
do_link
