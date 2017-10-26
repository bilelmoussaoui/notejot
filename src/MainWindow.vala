/*
* Copyright (c) 2017 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Notejot {
    public class MainWindow : Gtk.Window {
        private Gtk.Button clear_button;
        private Gtk.SourceView view = new Gtk.SourceView ();
        private int default_color = 4;
        private int uid;
        private static int uid_counter = 0;
        private static string[] code_color = {(_("White")), (_("Slate")), (_("Red")), (_("Orange")), (_("Yellow")), (_("Green")), (_("Blue")), (_("Indigo")), (_("Violet"))};
        private static string[] value_color = {"#fafafa", "#a5b3bc", "#ff9c92", "#ffc27d", "#fff394", "#d1ff82", "#8cd5ff", "#aca9fd", "#e29ffc"};
        public int color = 4;
        public string content = "";

        public MainWindow (Gtk.Application app, Storage? storage) {
            Object (application: app,
                    resizable: false,
                    title: "Notejot",
                    height_request: 500,
                    width_request: 500);

            if (storage != null) {
                init_from_storage(storage);
            }

            this.get_style_context().add_class("mainwindow-%d".printf(uid));
            this.get_style_context().add_class("rounded");

            this.uid = uid_counter++;

            update_theme();

            var new_button = new Gtk.Button.from_icon_name("list-add-symbolic");
            new_button.clicked.connect (create_new_note);
            new_button.has_tooltip = true;
            new_button.tooltip_text = (_("New note"));

            clear_button = new Gtk.Button.from_icon_name("edit-delete-symbolic");
            clear_button.clicked.connect(delete_note);
            clear_button.has_tooltip = true;
            clear_button.tooltip_text = (_("Clear note"));

            Gtk.MenuButton app_button = create_app_menu();
            app_button.has_tooltip = true;
            app_button.tooltip_text = (_("Change color"));

            var header = new Gtk.HeaderBar();
            header.has_subtitle = false;
            header.pack_end(app_button);
            header.pack_end(clear_button);
            header.pack_start (new_button);
            header.set_show_close_button (true);
            header.set_title("Notejot");
            this.set_titlebar(header);

            Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
            this.add (scrolled);

            view.bottom_margin = 10;
            view.buffer.text = this.content;
            view.expand = false;
            view.left_margin = 10;
            view.margin = 2;
            view.right_margin = 10;
            view.set_wrap_mode (Gtk.WrapMode.WORD);
            view.top_margin = 10;
            scrolled.add (view);
            this.show_all();

            focus_out_event.connect (() => {
                update_storage ();
                return false;
            });
        }

        private void update_storage () {
            get_storage_note();
            ((Application)this.application).update_storage(this);
        }

        private void update_theme() {
            var css_provider = new Gtk.CssProvider();
            this.get_style_context().add_class("window-%d".printf(uid));

            string style = null;
            string selected_color = this.color == -1 ? value_color[default_color] : value_color[color];
            if (Gtk.get_minor_version() < 20) {
                style = (N_("@define-color textColorPrimary #1a1a1a; .mainwindow-%d {background-color: %s; text-shadow: transparent; icon-shadow: 0 1px transparent; box-shadow: transparent;} .window-%d GtkTextView,.window-%d GtkHeaderBar {background-color: %s; background-image: none; border-bottom-color: %s; text-shadow: 0 1px transparent; icon-shadow: 0 1px transparent; box-shadow: none;} .window-%d GtkTextView.view {color: @textColorPrimary; font-size: 11px} .window-%d GtkTextView.view:selected {color: #FFFFFF; background-color: #3d9bda; font-size: 11px} .window-%d GtkTextView.view text{margin : 10px}")).printf(uid, selected_color, uid, uid, selected_color, selected_color, uid, uid, uid);
            } else {
                style = (N_("@define-color textColorPrimary #1a1a1a; .mainwindow-%d {background-color: %s; text-shadow: transparent; -gtk-icon-shadow: 0 1px transparent; box-shadow: transparent;} .window-%d textview.view text,.window-%d headerbar {background-color: %s; background-image: none; border-bottom-color: %s; text-shadow: 0 1px transparent; -gtk-icon-shadow: 0 1px transparent; box-shadow: none;} .window-%d textview.view {color: @textColorPrimary; font-size: 14px} .window-%d textview.view:selected {color: #FFFFFF; background-color: #64baff; font-size: 11px} .window-%d textview.view text{margin : 10px}")).printf(uid, selected_color, uid, uid, selected_color, selected_color, uid, uid, uid);
            }

            try {
                css_provider.load_from_data(style, -1);
            } catch (GLib.Error e) {
                warning ("Failed to parse css style : %s", e.message);
            }

            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }

        private Gtk.MenuButton create_app_menu() {
            Gtk.Menu app_menu = new Gtk.Menu();
            foreach (string color in code_color) {
                var label = new Gtk.Label(color);

                Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
                box.add(label);

                var menu_item = new Gtk.MenuItem();
                menu_item.activate.connect(change_color_action);
                menu_item.add(box);
                menu_item.name = color;

                app_menu.add(menu_item);
            }
            app_menu.show_all();

            var app_button = new Gtk.MenuButton();
            app_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            app_button.set_popup(app_menu);

            return app_button;
        }

        private void init_from_storage(Storage storage) {
            this.color = storage.color;
            this.content = storage.content;
            this.move(storage.x, storage.y);
        }

        private void create_new_note(Gtk.Button new_button) {
            ((Application)this.application).create_note(null);
        }

        private void change_color_action(Gtk.MenuItem color_item) {
            this.color = index_color(color_item.name);
            update_theme();
            ((Application)this.application).update_storage(this);
        }

        private void delete_note(Gtk.Button clear_button) {
            view.buffer.text = "";
            this.color = 4;
            ((Application)this.application).update_storage(this);
            ((Application)this.application).remove_note(this);
            this.close ();
        }

        public Storage get_storage_note() {
            int x, y, color;
            Gtk.TextIter start,end;
            view.buffer.get_bounds (out start, out end);
            string content = view.buffer.get_text (start, end, true);

            this.get_position (out x, out y);
            color = this.color;

            return new Storage.from_storage(x, y, color, content);
        }

        public override bool delete_event (Gdk.EventAny event) {
            var settings = AppSettings.get_default ();
            int x, y;
            this.get_position (out x, out y);
            settings.window_x = x;
            settings.window_y = y;
            return false;
        }

        private int index_color(string icolor) {
            int index = 0;
            foreach (string color in code_color) {
                if (color == icolor) {
                    return index;
                }
                index++;
            }
            return -1;
        }
    }
}
