require 'gdk_pixbuf2'
require 'libglade2'
require 'gnome2'

require 'rbrss/ui/glade_base.rb'
require 'rbrss/ui/main.rb'

module RbRSS
module UI
    def self.main
        Gnome::Program.new(TITLE, VERSION)
        Icons.init
        MainApp.new
        Gtk.main
    end
end
end