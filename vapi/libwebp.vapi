[CCode (cheader_filename = "webp/encode.h")]
namespace WebP {

  [CCode (cname = "WebPEncodeLosslessRGBA")]
  public extern size_t encode_lossless_rgba(
    uint8* rgb,
    int width,
    int height,
    int stride,
    out uint8* output_buffer
  );

  [CCode (cname = "WebPFree", cheader_filename = "webp/decode.h")]
  public extern void free(void* ptr);

}
