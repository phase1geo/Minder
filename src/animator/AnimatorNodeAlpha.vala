/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using GLib;

//-------------------------------------------------------------
// Helper class to the Animator class. This class should not
// be accessed outside of this file.
public class AnimatorNodeAlpha : Object {

  private double _old_alpha;
  private double _new_alpha;
  private Node   _node;

  public double old_alpha {
    get {
      return( _old_alpha );
    }
  }
  public double new_alpha {
    get {
      return( _new_alpha );
    }
  }
  public Node node {
    get {
      return( _node );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public AnimatorNodeAlpha( DrawArea da, Node node, bool fade_out, bool deep ) {
    _old_alpha = fade_out ? node.alpha : 0.0;
    _node      = node;
  }

  //-------------------------------------------------------------
  // Gathers the new node positions for the stored nodes.
  public void gather_new_node_alpha( bool fade_out ) {
    _new_alpha = fade_out ? 0.0 : _node.alpha;
  }

}
