#!/usr/bin/env python3

import os
import subprocess

schemadir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    subprocess.call(['glib-compile-schemas', schemadir], shell=False)

# Make sure that the icons are properly installed
print('Updating icon cache...')
hicolor = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'icons', 'hicolor')
subprocess.call(['gtk-update-icon-cache', '-f', '-t', hicolor], shell=False)
