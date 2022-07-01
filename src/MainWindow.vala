/*-
 * Copyright (C) 2022      Fyra Labs
 * Copyright (C) 2014      Marvin Beckers <beckersmarvin@gmail.com>
 *
 * The following code uses parts of the original work,
 * while keeping the original attribution.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

[GtkTemplate (ui = "/co/tauos/Abacus/window.ui")]
public class Abacus.MainWindow : He.ApplicationWindow {
	[GtkChild]
	private unowned Gtk.Button dot;
	[GtkChild]
	private unowned Gtk.Button eq;
	[GtkChild]
	private unowned Gtk.Entry entry;

	private Core.Evaluation eval;
    private int position;
    private int decimal_places;

	public const string ACTION_PREFIX = "win.";
	public const string ACTION_CLEAR = "action-clear";
    public const string ACTION_INSERT = "action-insert";
    public const string ACTION_ABOUT = "action-about";
    public const string ACTION_PREFS = "action-prefs";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_INSERT, action_insert, "s"},
		{ ACTION_CLEAR, action_clear },
        { ACTION_ABOUT, action_about},
		{ ACTION_PREFS, action_prefs }
    };

	public class MainWindow (He.Application app) {
		Object (
			application: app,
			resizable: false
		);
    }

    construct {
		add_action_entries (ACTION_ENTRIES, this);
		eval = new Core.Evaluation ();
		decimal_places = 2;

        var application_instance = (Gtk.Application) GLib.Application.get_default ();
        application_instance.set_accels_for_action (ACTION_PREFIX + ACTION_CLEAR, {"Escape"});

		entry.grab_focus ();
        entry.activate.connect (eq_clicked);
        entry.get_delegate ().insert_text.connect (replace_text);

		eq.clicked.connect (() => {eq_clicked ();});

        this.show ();
	}

    private void action_insert (SimpleAction action, Variant? variant) {
        var token = variant.get_string ();
        int new_position = entry.get_position ();
        int selection_start, selection_end, selection_length;
        bool is_text_selected = entry.get_selection_bounds (out selection_start, out selection_end);
        if (is_text_selected) {
            new_position = selection_end;
            entry.delete_selection ();
            selection_length = selection_end - selection_start;
            new_position -= selection_length;
        }

        var cursor_position = entry.cursor_position;
        entry.do_insert_text (token, -1, ref cursor_position);

        new_position += token.char_count ();
        entry.grab_focus ();
        entry.set_position (new_position);
    }

    private void eq_clicked () {
        position = entry.get_position ();
        if (entry.get_text () != "") {
			try {
                var output = eval.evaluate (entry.get_text (), decimal_places);
                if (entry.get_text () != output) {
                    entry.set_text (output);
                    position = output.length;
                }
            } catch (Core.OUT_ERROR e) {
            }
        } else {
        }

        entry.grab_focus ();
        entry.set_position (position);
    }

    private void action_clear () {
        position = 0;
        entry.set_text ("");
        set_focus (entry);

        entry.grab_focus ();
        entry.set_position (position);
    }

    private void action_about () {
        var about = new He.AboutWindow (
            this,
            "Abacus" + Config.NAME_SUFFIX,
            "co.tauos.Abacus",
            Config.VERSION,
            "co.tauos.Abacus",
            "https:/fyralabs.com",
            "https:/fyralabs.com",
            "https:/fyralabs.com",
            {},
            {"Lains"},
            2022,
            He.AboutWindow.Licenses.GPLv3,
            He.Colors.PURPLE
        );
        about.present ();
    }

    private void action_prefs () {
        // TODO: Preferences window
    }

    private void replace_text (string new_text, int new_text_length, ref int position) {
        var replacement_text = "";

        switch (new_text) {
            case ".":
            case ",":
                replacement_text = Posix.nl_langinfo (Posix.NLItem.RADIXCHAR);
                break;
            case "/":
                replacement_text = "÷";
                break;
            case "*":
                replacement_text = "×";
                break;
        }

        if (replacement_text != "" && replacement_text != new_text) {
            entry.do_insert_text (replacement_text, entry.cursor_position + replacement_text.char_count (), ref position);
            Signal.stop_emission_by_name ((void*) entry.get_delegate (), "insert-text");
        }
    }
}
