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

  /* Constructor */
  public About( MainWindow win ) {

    _about = new AboutDialog();

   	_about.set_destroy_with_parent( true );
	  _about.set_transient_for( win);
	  _about.set_modal( true );

    _about.authors       = { "Trevor Williams" };
    _about.program_name  = "Minder";
    _about.comments      = _( "Mind-mapping application" );
    _about.copyright     = _( "Copyright © 2018-2024 Trevor Williams" );
    _about.version       = Minder.version;
    _about.license_type  = License.GPL_3_0;
    _about.website       = "https://appcenter.elementary.io/com.github.phase1geo.minder/";
    _about.website_label = _( "Minder in AppCenter" );

    var image = new Image.from_resource( "/com/github/phase1geo/minder/minder-logo.svg" );
    _about.logo = image.get_paintable();

  }

  //-------------------------------------------------------------
  // Displays the About window
  public void show() {
    _about.present();
  }

}


