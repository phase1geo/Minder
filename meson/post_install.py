#!/usr/bin/env python3

import os
import subprocess

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    schemadir  = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')
    subprocess.call(['glib-compile-schemas', schemadir], shell=False)

    print('Updating icon cache...')
    hicolordir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'icons', 'hicolor')
    subprocess.call(['gtk-update-icon-cache', hicolordir], shell=False)
