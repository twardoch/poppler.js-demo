
#include <stdlib.h>
#include <stdio.h>

#include "../vendor/harfbuzz/src/hb.h"
#include "../vendor/harfbuzz/src/hb-ot.h"
// #include <emscripten.h>


hb_buffer_t *hb_buffer = hb_buffer_create();

struct FontPack {
  FontPack(hb_blob_t *blob) {
    face = hb_face_create(blob, 0);
    font = hb_font_create(face);
    hb_ot_font_set_funcs(font);
  }
  ~FontPack()
  {
      hb_face_destroy(face);
      hb_font_destroy(font);
  }
  hb_font_t *font;
  hb_face_t *face;
};

FontPack * makePack (hb_blob_t *blob) {
  auto *pack = new FontPack(blob);
  return pack;
}

int destroyPack (FontPack* pack) {
  delete pack;
  return 1;
}

hb_font_t* getFont (FontPack* pack) {
  return pack->font;
}

extern "C" {

FontPack* load_font (int font_size, char* font_data);
double measure_text (FontPack *pack, char *text, int text_length);

int main() 
{
  //EM_ASM( allReady() );
}

FontPack* load_font (int font_size, char* font_data) 
{
    printf ("Loading font file of size %d\n", font_size);
    hb_blob_t *font_blob;
    font_blob = hb_blob_create(font_data, font_size, HB_MEMORY_MODE_READONLY, NULL, NULL);
    FontPack *pack = makePack(font_blob);
    hb_blob_destroy(font_blob);

    return pack;
}

int unload_font (FontPack *pack)
{
  destroyPack(pack);
  return 1;
}

double measure_text (FontPack *pack, char *text, int text_length)
{

    hb_font_t *font = getFont(pack);

    hb_buffer_reset(hb_buffer);
    hb_buffer_add_utf8 (hb_buffer, text, text_length, 0, text_length);
    hb_buffer_guess_segment_properties (hb_buffer);
    
    hb_shape (font, hb_buffer, NULL, 0);

    unsigned int glyph_count;
    auto *info = hb_buffer_get_glyph_infos (hb_buffer, &glyph_count);
    auto *pos = hb_buffer_get_glyph_positions (hb_buffer, &glyph_count);

    double current_x = 0;
    //double current_y = 0;
    for (unsigned int i = 0; i < glyph_count; i++)
    {
        auto gid = info[i].codepoint;
        //double x_position = current_x + pos[i].x_offset;
        //double y_position = current_y + pos[i].y_offset;
        char glyphname[32];
        hb_font_get_glyph_name (font, gid, glyphname, sizeof(glyphname));

        current_x += pos[i].x_advance / 64;
        printf ("advance: %s %d\n", glyphname, pos[i].x_advance / 64);
        //current_y += pos[i].y_advance;
    }

    return current_x; 
}

}
