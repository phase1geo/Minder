project('com.github.phase1geo.minder', ['vala', 'c'],
    version : '1.0.0',
    license: 'GPL-3.0'
)

add_project_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)

gnome = import('gnome')
i18n = import('i18n')

gresource = gnome.compile_resources(
    'minder-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
)

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h'
]

sources = files()

subdir('data')
subdir('po')
subdir('src')
subdir('tests')

gtk_dep = dependency('gtk+-3.0')

if gtk_dep.version().version_compare('>=3.22.0')
  add_project_arguments(['--define=GTK322'], language: 'vala')
endif

dependencies = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('cairo'),
    dependency('gee-0.8'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('libxml-2.0'),
    dependency('libarchive')
]

e = executable('com.github.phase1geo.minder',
    sources,
    gresource,
    c_args: c_args,
    dependencies: dependencies,
    install : true
)

#test('tests', e, args : ['--run-tests'])

meson.add_install_script('meson/post_install.py')
