namespace Abacus {
	public class Application : He.Application {
		private const GLib.ActionEntry app_entries[] = {
		    { "quit", quit },
		};
		public Application () {
		    Object (application_id: Config.APP_ID);
		}
		public static int main (string[] args) {
			Intl.setlocale ();
			var app = new Application ();
			return app.run (args);
		}
		protected override void startup () {
			Gdk.RGBA accent_color = { 0 };
            accent_color.parse("#8C56BF");
            default_accent_color = He.Color.from_gdk_rgba(accent_color);
			resource_base_path = "/co/tauos/Abacus";
			add_action_entries (app_entries, this);
			base.startup ();
			new MainWindow (this);
		}
		protected override void activate () {
		    active_window?.present ();
		}
	}
}
