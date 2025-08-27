project('com.github.phase1geo.minder', ['vala', 'c'],
    version : '2.0.0',
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

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

sources = files()

subdir('data')
subdir('po')
subdir('src')

# Add the math and Markdown libraries
cc = meson.get_compiler('c')
math_dep = cc.find_library('m', required: false)

# Check libmarkdown2 dependency
libmarkdown = dependency('libmarkdown', required: true)
markdown_vapi = '/vapi/libmarkdown.vapi'
if libmarkdown.version().version_compare('>=3.0')
  add_project_arguments(['--define=MD30'], language: 'vala')
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
    dependency('granite-7'),
    dependency('gtk4'),
    dependency('libxml-2.0'),
    dependency('libarchive'),
    dependency('gtksourceview-5'),
    dependency('json-glib-1.0'),
    libmarkdown,
    math_dep
]

subdir('tests')

e = executable('com.github.phase1geo.minder',
    sources,
    config_file,
    gresource,
    dependencies: dependencies,
    vala_args: [
        meson.source_root() + markdown_vapi
    ],
    install : true
)

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true
)
