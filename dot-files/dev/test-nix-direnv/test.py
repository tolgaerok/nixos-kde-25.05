import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

class MyWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="My LinuxTweaks GTK3 Test")
        self.set_default_size(300, 150)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        vbox.set_border_width(15)
        self.add(vbox)

        label = Gtk.Label(label="Welcome to LinuxTweaks GTK3")
        vbox.pack_start(label, True, True, 0)

        button = Gtk.Button(label="Click me David")
        button.connect("clicked", self.on_button_clicked)
        vbox.pack_start(button, True, True, 0)

    def on_button_clicked(self, widget):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text="Button clicked",
        )
        dialog.format_secondary_text(
            "You just clicked my clit ... Nice!"
        )
        dialog.run()
        dialog.destroy()

if __name__ == "__main__":
    win = MyWindow()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
