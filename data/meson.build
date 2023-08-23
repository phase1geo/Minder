icon_sizes = ['16','24','32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    meson.project_name() + '.xml',
    install_dir: join_paths(get_option('datadir'), 'mime', 'packages')
)

install_data(
    join_paths('styles', meson.project_name() + '.xml'),
    install_dir: join_paths(get_option('datadir'), 'minder', 'gtksourceview-4', 'styles')
)

install_data(
    join_paths('language-specs', meson.project_name() + '-markdown.lang'),
    install_dir: join_paths(get_option('datadir'), 'minder', 'gtksourceview-4', 'language-specs')
)
