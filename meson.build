project('com.github.phase1geo.minder', ['vala', 'c'],
 version : '1.17.0',
license: 'GPL-3.0'
)

# Import modules
gnome = import('gnome')
i18n = import('i18n')

# Get dependencies early for version checks
gtk_dep = dependency('gtk+-3.0')
granite = dependency('granite', version: '>=6.0', required: false)
if not granite.found()
 granite = dependency('granite', required: true)
 message('Using older version of granite')
endif
libmarkdown = dependency('libmarkdown', required: true)
cc = meson.get_compiler('c')

# ALL add_project_arguments calls MUST come before any build targets
add_project_arguments([
'-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
 ],
language: 'c',
)

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# If the GTK version is higher than 3.22, add a define to indicate that
if gtk_dep.version().version_compare('>=3.22.0')
add_project_arguments(['--define=GTK322'], language: 'vala')
endif

# If the valac version is greater than or equal to 0.48, add a define for cross-compile purposes
if meson.get_compiler('vala').version().version_compare('>=0.48.0')
add_project_arguments(['--define=VALAC048'], language: 'vala')
message('Using VALAC048')
endif

# Check granite version and add define
if granite.found() and granite.version().version_compare('>=6.0')
add_project_arguments(['--define=GRANITE_6_OR_LATER'], language: 'vala')
endif

# Check libmarkdown version
if libmarkdown.version().version_compare('>=3.0')
add_project_arguments(['--define=MD30'], language: 'vala')
endif

add_project_arguments([
'--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
'--disable-warnings'
 ],
language: 'vala',
)

# Now we can define build targets
gresource = gnome.compile_resources(
'minder-resources', 'data/' + meson.project_name() + '.gresource.xml',
source_dir: 'data',
)

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
subdir('tests')

# Add the math library
math_dep = cc.find_library('m', required: false)

markdown_vapi = '/vapi/libmarkdown.vapi'

run_minder_exe = executable('run-minder',
'run-minder.c',
install: false
)

# Copy run-minder to the project root (builddir/..)
custom_target('copy-run-minder',
output: 'run-minder-copied',
input: run_minder_exe,
command: [
  find_program('cp', 'copy'),
  '@INPUT@',
  meson.project_build_root() + '/../run-minder' + (host_machine.system() == 'windows' ? '.exe' : '')
],
build_by_default: true,
depends: run_minder_exe
)

# Automatically compile GSettings schemas after build
custom_target('compile-schemas',
output: 'gschemas.compiled',
input: 'data/com.github.phase1geo.minder.gschema.xml',
command: ['glib-compile-schemas', meson.current_source_dir() + '/data'],
build_by_default: true
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
dependency('json-glib-1.0'),
 libmarkdown,
 math_dep
]

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

#test('tests', e, args : ['--run-tests'])

meson.add_install_script('meson/post_install.py')