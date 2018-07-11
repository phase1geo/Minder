#!/usr/bin/env python3

import os
import subprocess

schemadir  = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')
hicolordir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'icons', 'hicolor')

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    subprocess.call(['glib-compile-schemas', schemadir], shell=False)

    # print('Updating icon cache...')
    # subprocess.call(['gtk-update-icon-cache', hicolordir], shell=False)
