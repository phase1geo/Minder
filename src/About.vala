/*
* Copyright (c) 2019-2021 (https://github.com/phase1geo/Minder)
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

using Gtk;
using Gdk;

public class About {

  private AboutDialog _about;

  //-------------------------------------------------------------
  // Constructor
  public About( MainWindow win ) {

    var image = new Image.from_resource( "/com/github/phase1geo/minder/minder-logo.svg" );

    _about = new AboutDialog() {
      authors            = { "Trevor Williams" },
      program_name       = "Minder",
      comments           = _( "Mind-mapping application" ),
      copyright          = _( "Copyright © 2018-2024 Trevor Williams" ),
      version            = Minder.version,
      license_type       = License.GPL_3_0,
      website            = "https://appcenter.elementary.io/com.github.phase1geo.minder/",
      website_label      = _( "Minder in AppCenter" ),
      system_information = get_system_info(),
      logo               = image.get_paintable()
    };

   	_about.set_destroy_with_parent( true );
	  _about.set_transient_for( win);
	  _about.set_modal( true );

  }

  //-------------------------------------------------------------
  // Returns the system information about how this application was
  // built.
  private string get_system_info() {
    var runtime = Utils.get_flatpak_runtime();
    if( runtime != "" ) {
      return( _( "Flatpak Runtime: %s".printf( runtime ) ) );
    }
    return( "" );
  }

  //-------------------------------------------------------------
  // Displays the About window
  public void show() {
    _about.present();
  }

}


