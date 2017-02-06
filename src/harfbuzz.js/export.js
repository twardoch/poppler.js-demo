;(function () {
  var text = 'Hello, world?'

  function ptr (string) {
    return allocate(intArrayFromString(string), 'i8', ALLOC_NORMAL)
  }

  var measure_text = Module.cwrap('measure_text', 'number', ['number', 'number', 'number']);
  var load_font = Module.cwrap('load_font', 'number', ['number', 'number']);
  var unload_font = Module.cwrap('unload_font', 'number', ['number']);
  window.measureText = function (font, string) {
    var text = ptr(string);
    var value = measure_text(font, text, string.length);
    Module._free(text);
    return value;
  }

  fetch("/fonts/comic-sans.ttf").then(function (data) { return data.arrayBuffer() }).then(function (buffer) {
    var size = buffer.byteLength
    var dataPtr = Module._malloc(size)
    var dataHeap = new Uint8Array(Module.HEAPU8.buffer, dataPtr, size);
    dataHeap.set(new Uint8Array(buffer));
    window.comic_sans = load_font(size, dataHeap.byteOffset);
    Module._free(dataHeap.byteOffset);
  })
})();
