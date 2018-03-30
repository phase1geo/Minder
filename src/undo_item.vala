using GLib;

public class UndoItem : GLib.Object {

  /* Default constructor */
  public UndoItem() {}
  
  /* Causes the stored item to be put into the before state */
  public virtual void undo( Object o ) {}
  
  /* Causes the stored item to be put into the after state */
  public virtual void redo( Object o ) {}
  
}