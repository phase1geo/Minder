icon_sizes = ['16','24','32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

custom_icons = [
  'minder-balance-symbolic',
  'minder-fold-completed-symbolic',
  'minder-layout-horizontal-symbolic',
  'minder-layout-right-symbolic',
  'minder-task-done-symbolic',
  'minder-detach-symbolic',
  'minder-layout-left-symbolic',
  'minder-layout-down-symbolic',
  'minder-layout-manual-symbolic',
  'minder-layout-up-symbolic',
  'minder-layout-vertical-symbolic',
  'minder-note-symbolic',
  'minder-task-todo-symbolic',
  'minder-title-symbolic',
  'minder-unfold-symbolic'
]

foreach i : custom_icons
    install_data(
        join_paths('icons', '16', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '16x16', 'apps')
    )
endforeach

install_data(
    meson.project_name() + '.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    meson.project_name() + '.appdata.xml',
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)
