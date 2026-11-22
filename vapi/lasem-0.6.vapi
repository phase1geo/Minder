[CCode (cheader_filename = "lsm.h,lsmmathml.h,lsmmathmlview.h,lsmmathmldocument.h,lsmdomview.h")]
namespace Lsm {
  [CCode (cname = "LsmMathmlDocument", type_id = "lsm_mathml_document_get_type ()")]
  public class MathmlDocument : GLib.Object {
    [CCode (cname = "lsm_mathml_document_new_from_itex")]
    public static MathmlDocument? from_itex (string itex, ssize_t size = -1) throws GLib.Error;
  }
  [CCode (cname = "LsmDomView", type_id = "lsm_dom_view_get_type ()")]
  public abstract class DomView : GLib.Object {
    [CCode (cname = "lsm_dom_view_set_resolution")]
    public void set_resolution (double ppi);
    [CCode (cname = "lsm_dom_view_get_size")]
    public void get_size (out double width, out double height, out double baseline);
    [CCode (cname = "lsm_dom_view_render")]
    public void render (Cairo.Context cr, double x, double y);
  }
  [CCode (cname = "LsmMathmlView", type_id = "lsm_mathml_view_get_type ()")]
  public class MathmlView : DomView {
    [CCode (cname = "lsm_mathml_view_new")]
    public MathmlView (MathmlDocument doc);
  }
}
