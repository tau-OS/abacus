# Non-code data for your application is handled here.
# Think icons, UI files, settings schemas, and other assets.
# For your convenience, we included the essentials. Make sure to rename them (and modify the contents) to use your actual app id.

subdir('icons')
subdir('ui')

# A desktop file provides basic information about the application to the shell.
# This allows the shell to display your application's name, icon, and other metadata.
# It's also required for visual launchers, such as the app drawer, to discover and launch your application.
# For more information about desktop files, see https://wiki.archlinux.org/title/desktop_entries and https://specifications.freedesktop.org/desktop-entry-spec/latest/

desktop_file = i18n.merge_file(
    input: configure_file(
        input: 'app.desktop.in.in',
        output: meson.project_name() + '.desktop.in',
        configuration: {
            'ICON_NAME': meson.project_name(),
            'COMMAND': meson.project_name(),
        },
    ),
    output: meson.project_name() + '.desktop',
    po_dir: meson.source_root() / 'po',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications',
)

desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
    test('validate-desktop', desktop_file_validate, args: [desktop_file])
endif

# GResources allow you to bundle and reference assets within your application.
# Resources are specified using a gresource file.
# For more information about GResources, see: https://docs.gtk.org/gio/struct.Resource.html

gresources = gnome.compile_resources(
    'resources',
    configure_file(
        input: 'gresource.xml.in',
        output: meson.project_name() + '.gresource.xml',
        configuration: {
            'APP_ID': meson.project_name(),
            'APP_PATH': path_identifier,
        },
    ),
    source_dir: meson.current_build_dir(),
    dependencies: blueprints,
    c_name: 'resources',
    install_dir: get_option('datadir') / meson.project_name(),
)

add_project_arguments(
    '--gresourcesdir',
    meson.current_build_dir(),
    language: ['vala'],
)