[CCode (cheader_filename = "webp/encode.h")]
public extern size_t WebPEncodeLosslessRGBA(
  uint8* rgb,
  int width,
  int height,
  int stride,
  out uint8* output_buffer
);

[CCode (cheader_filename = "webp/decode.h")]
public extern void WebPFree(void* ptr);
