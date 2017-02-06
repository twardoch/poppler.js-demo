#!/usr/bin/env bash
set -e

EM_DIR=/usr/local/bin # $(grealpath emsdk/emscripten/1.35.0)
BASE_DIR=$(pwd)
SRC_DIR=$BASE_DIR/src
SRCVENDORS_DIR=$SRC_DIR/vendors
FONTCONFIG_DIR=$SRCVENDORS_DIR/fontconfig
UCDN_DIR=$SRCVENDORS_DIR/ucdn
FREETYPE_DIR=$SRCVENDORS_DIR/freetype
POPPLER_DIR=$SRCVENDORS_DIR/poppler
HARFBUZZ_DIR=$SRCVENDORS_DIR/harfbuzz
BUILD_DIR=$BASE_DIR/docs
VENDORS_DIR=$BUILD_DIR/vendors
POPPLER=poppler-0.51.0

make_ucdn () { 
  if [ ! -d $UCDN_DIR ]; then
      git clone https://github.com/grigorig/ucdn --depth=1 --branch master --single-branch $UCDN_DIR
  fi
  pushd $UCDN_DIR
  mkdir -p $VENDORS_DIR/ucdn
  $EM_DIR/emcc -o $VENDORS_DIR/ucdn/ucdn.js ucdn.c 
  popd
}

make_freetype () {
  if [ ! -d $FREETYPE_DIR ]; then
      git clone git://git.sv.gnu.org/freetype/freetype2.git --depth=1 --branch master --single-branch $FREETYPE_DIR
  fi 
  pushd $FREETYPE_DIR
  $EM_DIR/emconfigure ./autogen.sh
  cp ../modules.cfg modules.cfg
  cp ../exports.mk builds/exports.mk
  cp ../ftexport.sym objs/ftexport.sym

  CPPFLAGS="-Oz" \
  $EM_DIR/emconfigure ./configure \
      --enable-shared=yes \
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
      --without-ats

  $EM_DIR/emmake make -j8
  popd
}

make_harfbuzz () { 
  if [ ! -d $HARFBUZZ_DIR ]; then
      git clone https://github.com/behdad/harfbuzz --depth=1 --branch master --single-branch $HARFBUZZ_DIR
  fi 
  pushd $HARFBUZZ_DIR
  FONTCONFIG_CFLAGS="-I$FONTCONFIG_DIR" \
  FONTCONFIG_LIBS=" " \
  FREETYPE_CFLAGS="-I$FREETYPE_DIR/include" \
  FREETYPE_LIBS="-L$FREETYPE_DIR/objs/.libs" \
  CPPFLAGS="-Oz" \
  $EM_DIR/emconfigure ./autogen.sh \
          --enable-shared=yes \
          --enable-static=yes \
          --without-glib \
          --without-gobject \
          --without-cairo \
          --without-fontconfig \
          --with-ucdn \
          --without-icu \
          --without-graphite2 \
          --with-freetype \
          --without-uniscribe \
          --without-directwrite \
          --without-coretext
          #--host 386-linux

  $EM_DIR/emmake make all-recursive -j8
  popd
} 

make_poppler () {
  if [ ! -d $POPPLER_DIR ]; then
      #git clone https://anongit.freedesktop.org/git/poppler/poppler.git --depth=1 --branch master --single-branch $POPPLER_DIR
      pushd $SRCVENDORS_DIR
      wget https://poppler.freedesktop.org/$POPPLER.tar.xz
      tar -xJf $POPPLER.tar.xz
      rm $POPPLER.tar.xz
      mv $POPPLER poppler
      #cp -R $BASE_DIR/emsdk/emscripten/1.35.0/tests/poppler .
      popd
  fi 
  pushd $POPPLER_DIR
  FREETYPE_CFLAGS="-I$FREETYPE_DIR/include" \
  FREETYPE_LIBS="-L$FREETYPE_DIR/objs/.libs -llibfreetype" \
  FONTCONFIG_CFLAGS="-I$FONTCONFIG_DIR" \
  FONTCONFIG_LIBS=" " \
  FONTCONFIG="$FONTCONFIG_DIR" \
  FREETYPE="$FREETYPE_DIR/include" \
  $EM_DIR/emconfigure \
   ./configure \
    --enable-shared=yes \
    --enable-static=yes \
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
    --without-x 

  CFLAGS="-I$FREETYPE_DIR/include" \
  FREETYPE_CFLAGS="-I$FREETYPE_DIR/include" \
  FREETYPE_LIBS="-L$FREETYPE_DIR/objs/.libs -llibfreetype" \
  FONTCONFIG_CFLAGS="-I$FONTCONFIG_DIR" \
  FONTCONFIG_LIBS=" " \
  FONTCONFIG="$FONTCONFIG_DIR" \
  FREETYPE="$FREETYPE_DIR/include" \
  $EM_DIR/emmake make -j8
  popd
}

cc_harfbuzz () { 
  mkdir -p $VENDORS_DIR/harfbuzz
  $EM_DIR/emcc \
      -o $VENDORS_DIR/harfbuzz/harfbuzz.js \
      $HARFBUZZ_DIR/src/.libs/libharfbuzz.0.dylib \
      src/hb-ucdn/.libs/libhb-ucdn.a \
      --llvm-lto 1 \
      --memory-init-file 1 \
      -Oz \
      --closure 0 \
      --memory-init-file 1 \
      -s ALLOW_MEMORY_GROWTH=1 \
      -s USE_TYPED_ARRAYS=2 \
      -s ASM_JS=1 \
      -s RESERVED_FUNCTION_POINTERS=1024 \
      -s TOTAL_MEMORY=67108864 \
      -s EXPORTED_FUNCTIONS=['_hb_language_from_string','_hb_language_to_string','_hb_unicode_funcs_get_default','_hb_unicode_funcs_reference','_hb_buffer_create','_hb_buffer_reference','_hb_buffer_destroy','_hb_buffer_reset','_hb_buffer_get_empty','_hb_buffer_set_content_type','_hb_buffer_get_content_type','_hb_buffer_get_length','_hb_buffer_get_glyph_infos','_hb_buffer_get_glyph_positions','_hb_buffer_normalize_glyphs','_hb_buffer_add','_hb_buffer_add_utf8','_hb_buffer_add_utf16','_hb_buffer_add_utf32','_hb_buffer_get_length','_hb_buffer_guess_segment_properties','_hb_buffer_set_direction','_hb_buffer_get_direction','_hb_buffer_set_script','_hb_buffer_get_script','_hb_buffer_set_language','_hb_buffer_get_language','_hb_blob_create','_hb_blob_create_sub_blob','_hb_blob_get_empty','_hb_blob_reference','_hb_blob_destroy','_hb_feature_from_string','_hb_feature_to_string','_hb_shape_list_shapers','_hb_shape','_hb_shape_full','_hb_face_create','_hb_face_destroy','_hb_font_create','_hb_font_destroy','_hb_font_set_scale','_hb_font_get_face','_hb_font_funcs_create','_hb_font_funcs_destroy','_hb_font_set_funcs','_hb_font_funcs_set_glyph_func','_hb_font_funcs_set_glyph_h_advance_func','_hb_font_funcs_set_glyph_v_advance_func','_hb_font_funcs_set_glyph_h_origin_func','_hb_font_funcs_set_glyph_v_origin_func','_hb_font_funcs_set_glyph_h_kerning_func','_hb_font_funcs_set_glyph_v_kerning_func','_hb_font_funcs_set_glyph_extents_func','_hb_font_funcs_set_glyph_contour_point_func','_hb_font_funcs_set_glyph_name_func','_hb_font_funcs_set_glyph_from_name_func','_ucdn_get_unicode_version','_ucdn_get_combining_class','_ucdn_get_east_asian_width','_ucdn_get_general_category','_ucdn_get_bidi_class','_ucdn_get_script','_ucdn_get_mirrored','_ucdn_mirror','_ucdn_decompose','_ucdn_compose'] \
      -s DEAD_FUNCTIONS=['_mprotect']
}


cc_harfbuzz1 () {
  rm -rf dist
  mkdir dist
  CC=em++ emmake make

  rm -rf public/dist
  mkdir public/dist
  emcc dist/measure.o vendor/harfbuzz/src/.libs/libharfbuzz.0.dylib -o public/dist/measure.js -s EXPORTED_FUNCTIONS="['_measure_text', '_load_font', '_unload_font']" -s NO_EXIT_RUNTIME=1 --post-js src/export.js --pre-js src/setup.js
}

cc_poppler () {
mkdir -p $VENDORS_DIR/poppler
$EM_DIR/emcc \
    -Oz \
    --llvm-lto 1 \
    --memory-init-file 1 \
    -s EXPORTED_FUNCTIONS="['_PopplerJS_init', '_PopplerJS_Doc_new', '_PopplerJS_Doc_delete', '_PopplerJS_Doc_get_page_count', '_PopplerJS_Doc_get_page', '_PopplerJS_Page_get_width', '_PopplerJS_Page_get_height', '_PopplerJS_Page_get_bitmap', '_PopplerJS_Bitmap_get_buffer', '_PopplerJS_Bitmap_get_row_size', '_PopplerJS_Bitmap_destroy', '_PopplerJS_Page_destroy']" \
    -o $VENDORS_DIR/poppler/poppler.js \
    -I$POPPLER_DIR \
    -I$POPPLER_DIR/poppler \
    src/poppler.js/poppler.js.cc \
    $POPPLER_DIR/poppler/.libs/libpoppler.dylib \
    $FREETYPE_DIR/objs/.libs/libfreetype.dylib \

}

#make_ucdn
#make_freetype
#make_harfbuzz
make_poppler
#cc_poppler
# do_link



