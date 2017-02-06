PKGS = harfbuzz freetype2

PKG_CONFIG_PATH = $(shell pwd)/vendor/harfbuzz/src:$(shell pwd)/vendor/emscripten/tests/freetype/builds/unix

CFLAGS = `pkg-config --cflags $(PKGS)`
LDFLAGS = `pkg-config --libs $(PKGS)` -lm

all: dist/measure.o
dist/%.o: src/%.cpp
	em++ -std=c++14 -o $@ $^ $(CFLAGS) $(LDFLAGS) -Wc++11-extensions
