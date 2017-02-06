#!/usr/bin/env bash
set -e

EM_DIR=/usr/local/bin
BASE_DIR=`pwd`
#FREETYPE_DIR=$EM_DIR/tests/freetype
FREETYPE_DIR=$BASE_DIR/freetype2
POPPLER_DIR=$BASE_DIR/poppler
HARFBUZZ_DIR=$BASE_DIR/harfbuzz

do_harfbuzz () { 
pushd $HARFBUZZ_DIR
$EM_DIR/emconfigure ./autogen.sh \
        --enable-shared=no \
        --enable-static=yes \
        --without-glib \
        --without-gobject \
        --without-cairo \
        --without-fontconfig \
        --with-ucdn \
        --without-icu \
        --without-graphite2 \
        --without-freetype \
        --without-uniscribe \
        --without-directwrite \
        --without-coretext \
        --host 386-linux

$EM_DIR/emmake make all-recursive -j8

$EM_DIR/emcc \
    -o build/emcc/harfbuzz.js \
    src/.libs/libharfbuzz.so \
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

do_freetype () {
pushd $FREETYPE_DIR
./autogen.sh
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

do_harfbuzz
#do_freetype
#do_poppler
#do_link
