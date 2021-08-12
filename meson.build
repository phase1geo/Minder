  project('com.github.phase1geo.minder', ['vala', 'c'],
    version : '1.13.1',
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
  '-include', 'config.h',
]

sources = files()

subdir('data')
subdir('po')
subdir('src')
subdir('tests')

# If the GTK version is higher than 3.22, add a define to indicate that
gtk_dep = dependency('gtk+-3.0')
if gtk_dep.version().version_compare('>=3.22.0')
  add_project_arguments(['--define=GTK322'], language: 'vala')
endif

# If the valac version is greater than or equal to 0.48, add a define for cross-compile purposes
if meson.get_compiler('vala').version().version_compare('>=0.48.0')
  add_project_arguments(['--define=VALAC048'], language: 'vala')
  message('Using VALAC048')
endif

# Add the math and Markdown libraries
cc = meson.get_compiler('c')
math_dep    = cc.find_library('m', required: false)
libmarkdown = cc.find_library('markdown', required: true)

# Check the granite dependency
granite = dependency('granite', version: '>=6.0', required: false)
if granite.found()
  add_project_arguments(['--define=GRANITE_6_OR_LATER'], language: 'vala')
else
  granite = dependency('granite', required: true)
  message('Using older version of granite')
endif

add_project_arguments([
        '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
        '--disable-warnings'
    ],
    language: 'vala',
)

dependencies = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('cairo'),
    dependency('gee-0.8'),
    granite,
    dependency('gtk+-3.0'),
    dependency('libxml-2.0'),
    dependency('libarchive'),
    dependency('gtksourceview-4'),
    dependency('libhandy-1'),
    libmarkdown,
    math_dep
]

e = executable('com.github.phase1geo.minder',
    sources,
    gresource,
    c_args: c_args,
    dependencies: dependencies,
    vala_args: [
        meson.source_root() + '/vapi/libmarkdown.vapi'
    ],
    install : true
)

#test('tests', e, args : ['--run-tests'])

meson.add_install_script('meson/post_install.py')
