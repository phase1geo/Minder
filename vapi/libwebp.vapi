[CCode (cheader_filename = "webp/encode.h")]
namespace WebP {

  [CCode (cname = "WebPEncodeLosslessRGB")]
  public extern size_t encode_lossless_rgb(
    uint8* rgb,
    int width,
    int height,
    int stride,
    out uint8* output_buffer
  );

  [CCode (cname = "WebPEncodeLosslessRGBA")]
  public extern size_t encode_lossless_rgba(
    uint8* rgb,
    int width,
    int height,
    int stride,
    out uint8* output_buffer
  );

  [CCode (cname = "WebPFree")]
  public extern void free(void* ptr);

}
