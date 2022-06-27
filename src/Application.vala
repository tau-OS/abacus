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
			resource_base_path = "/co/tauos/Abacus";
			base.startup ();
			add_action_entries (app_entries, this);
			new MainWindow (this);
		}
		protected override void activate () {
		    active_window?.present ();
		}
	}
}
